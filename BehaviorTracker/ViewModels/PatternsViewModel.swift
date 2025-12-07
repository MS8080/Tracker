import Foundation
import CoreData
import SwiftUI

@MainActor
class PatternsViewModel: ObservableObject {
    @Published var todayPatterns: [ExtractedPattern] = []
    @Published var todayCascades: [PatternCascade] = []
    @Published var todaySummary: String?
    @Published var dominantPatterns: [String] = []
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var isGeneratingSummary = false
    @Published var hasUnanalyzedEntries = false
    @Published var error: String?

    private let dataController = DataController.shared
    private let extractionService = PatternExtractionService.shared

    // Cache keys for daily summary (stored in UserDefaults)
    private let summaryDateKey = "patternsSummaryDate"
    private let summaryTextKey = "patternsSummaryText"
    private let summaryPatternCountKey = "patternsSummaryCount"
    private let dominantPatternsKey = "patternsDominantPatterns"

    var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    var averageIntensity: String {
        guard !todayPatterns.isEmpty else { return "0" }
        let total = todayPatterns.reduce(0) { $0 + Int($1.intensity) }
        let average = Double(total) / Double(todayPatterns.count)
        return String(format: "%.1f", average)
    }

    // MARK: - Load Data

    func loadTodayPatterns() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Fetch extracted patterns for today
        let fetchRequest: NSFetchRequest<ExtractedPattern> = ExtractedPattern.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractedPattern.timestamp, ascending: true)]

        do {
            let context = dataController.container.viewContext
            todayPatterns = try context.fetch(fetchRequest)

            // Collect cascades from patterns
            var cascades: [PatternCascade] = []
            for pattern in todayPatterns {
                if let fromCascades = pattern.cascadesFrom {
                    cascades.append(contentsOf: fromCascades)
                }
            }
            todayCascades = cascades

            // Check for unanalyzed entries
            await checkUnanalyzedEntries()

            // Load cached summary - NO API call here
            loadCachedSummary()

        } catch {
            self.error = "Failed to load patterns: \(error.localizedDescription)"
        }
    }

    // MARK: - Summary Caching

    /// Load summary from cache (no API call)
    private func loadCachedSummary() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())

        // Check if we have a cached summary for today with matching pattern count
        if let cachedDate = defaults.object(forKey: summaryDateKey) as? Date,
           Calendar.current.isDate(cachedDate, inSameDayAs: today),
           defaults.integer(forKey: summaryPatternCountKey) == todayPatterns.count {
            // Use cached summary
            todaySummary = defaults.string(forKey: summaryTextKey)
            dominantPatterns = defaults.stringArray(forKey: dominantPatternsKey) ?? []
        } else {
            // Cache is stale or missing - clear it but don't auto-regenerate
            todaySummary = nil
            dominantPatterns = []
        }
    }

    /// Save summary to cache
    private func cacheSummary(_ summary: String, patterns: [String]) {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: summaryDateKey)
        defaults.set(summary, forKey: summaryTextKey)
        defaults.set(todayPatterns.count, forKey: summaryPatternCountKey)
        defaults.set(patterns, forKey: dominantPatternsKey)
    }

    // MARK: - Generate Daily Summary

    /// Generate summary - only called explicitly by user action
    func generateDailySummary() async {
        guard !todayPatterns.isEmpty else {
            todaySummary = nil
            dominantPatterns = []
            return
        }

        guard extractionService.isConfigured else {
            return
        }

        isGeneratingSummary = true
        defer { isGeneratingSummary = false }

        do {
            let result = try await extractionService.generateDailySummary(patterns: todayPatterns)
            todaySummary = result.summary
            dominantPatterns = result.dominantPatterns

            // Cache the result
            cacheSummary(result.summary, patterns: result.dominantPatterns)
        } catch {
            // Fall back to no summary rather than showing error
            todaySummary = nil
        }
    }

    // MARK: - Check Unanalyzed

    func checkUnanalyzedEntries() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchRequest = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@ AND isAnalyzed == NO",
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        do {
            let context = dataController.container.viewContext
            let count = try context.count(for: fetchRequest)
            hasUnanalyzedEntries = count > 0
        } catch {
            hasUnanalyzedEntries = false
        }
    }

    // MARK: - Analyze Entries

    func analyzeUnanalyzedEntries() async {
        guard !isAnalyzing else {
            return
        }

        guard extractionService.isConfigured else {
            return
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Fetch unanalyzed entries - always check fresh from database
        let fetchRequest = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@ AND isAnalyzed == NO",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: true)]

        do {
            let context = dataController.container.viewContext
            let entries = try context.fetch(fetchRequest)

            guard !entries.isEmpty else {
                hasUnanalyzedEntries = false
                return
            }


            for entry in entries {
                await analyzeEntry(entry, context: context)
            }

            try context.save()

            // Reload patterns
            await loadTodayPatterns()

            // Generate summary since user explicitly analyzed (only if we have patterns)
            if !todayPatterns.isEmpty {
                await generateDailySummary()
            }

        } catch {
            self.error = "Failed to analyze entries: \(error.localizedDescription)"
        }
    }

    private func analyzeEntry(_ entry: JournalEntry, context: NSManagedObjectContext) async {
        // Debounce: skip if this entry was recently analyzed
        if GeminiService.shared.wasRecentlyAnalyzed(entryID: entry.id) {
            return
        }

        // Mark as being analyzed to prevent duplicates
        GeminiService.shared.markAsAnalyzed(entryID: entry.id)

        do {
            let result = try await extractionService.extractPatterns(from: entry.content)

            // Create ExtractedPattern entities
            var createdPatterns: [String: ExtractedPattern] = [:]

            for patternData in result.patterns {
                let pattern = ExtractedPattern(context: context)
                pattern.id = UUID()
                pattern.patternType = patternData.type
                pattern.category = patternData.category
                pattern.intensity = Int16(patternData.intensity)
                pattern.triggers = patternData.triggers ?? []
                pattern.timeOfDay = patternData.timeOfDay
                pattern.copingStrategies = patternData.copingUsed ?? []
                pattern.details = patternData.details
                pattern.confidence = result.confidence
                pattern.timestamp = entry.timestamp
                pattern.journalEntry = entry

                createdPatterns[patternData.type] = pattern
            }

            // Create cascade relationships
            for cascadeData in result.cascades {
                if let fromPattern = createdPatterns[cascadeData.from],
                   let toPattern = createdPatterns[cascadeData.to] {
                    let cascade = PatternCascade(context: context)
                    cascade.id = UUID()
                    cascade.confidence = cascadeData.confidence
                    cascade.descriptionText = cascadeData.description
                    cascade.timestamp = entry.timestamp
                    cascade.fromPattern = fromPattern
                    cascade.toPattern = toPattern
                }
            }

            // Update journal entry
            entry.isAnalyzed = true
            entry.analysisConfidence = result.confidence
            entry.analysisSummary = result.summary
            entry.overallIntensity = Int16(result.overallIntensity)

        } catch {
            // Don't mark as analyzed if it failed
        }
    }
}

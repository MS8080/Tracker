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

    // Cache key for daily summary to avoid regenerating
    private var lastSummaryPatternCount: Int = 0
    private var lastSummaryDate: Date?

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

            // Generate daily summary only if:
            // 1. We have patterns
            // 2. Either no summary exists, OR pattern count changed, OR it's a new day
            let today = Calendar.current.startOfDay(for: Date())
            let needsNewSummary = todaySummary == nil ||
                                  lastSummaryPatternCount != todayPatterns.count ||
                                  lastSummaryDate != today

            if !todayPatterns.isEmpty && needsNewSummary {
                await generateDailySummary()
                lastSummaryPatternCount = todayPatterns.count
                lastSummaryDate = today
            }

        } catch {
            self.error = "Failed to load patterns: \(error.localizedDescription)"
        }
    }

    // MARK: - Generate Daily Summary

    func generateDailySummary() async {
        guard !todayPatterns.isEmpty else {
            todaySummary = nil
            dominantPatterns = []
            return
        }

        guard extractionService.isConfigured else {
            print("[PatternsViewModel] Cannot generate summary - no API key")
            return
        }

        isGeneratingSummary = true
        defer { isGeneratingSummary = false }

        do {
            let result = try await extractionService.generateDailySummary(patterns: todayPatterns)
            todaySummary = result.summary
            dominantPatterns = result.dominantPatterns
            print("[PatternsViewModel] Generated daily summary: \(result.summary)")
        } catch {
            print("[PatternsViewModel] Failed to generate daily summary: \(error.localizedDescription)")
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
            print("[PatternsViewModel] Already analyzing, skipping")
            return
        }

        guard extractionService.isConfigured else {
            print("[PatternsViewModel] Extraction service not configured (no API key)")
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
                print("[PatternsViewModel] No entries to analyze")
                hasUnanalyzedEntries = false
                return
            }

            print("[PatternsViewModel] Found \(entries.count) unanalyzed entries")

            for entry in entries {
                print("[PatternsViewModel] Analyzing entry: \(entry.timestamp)")
                await analyzeEntry(entry, context: context)
            }

            try context.save()
            print("[PatternsViewModel] Saved analyzed entries")

            // Reload patterns and regenerate daily summary
            todaySummary = nil  // Clear so it regenerates
            await loadTodayPatterns()

        } catch {
            print("[PatternsViewModel] Error: \(error.localizedDescription)")
            self.error = "Failed to analyze entries: \(error.localizedDescription)"
        }
    }

    private func analyzeEntry(_ entry: JournalEntry, context: NSManagedObjectContext) async {
        do {
            print("[PatternsViewModel] Calling extractPatterns for entry...")
            let result = try await extractionService.extractPatterns(from: entry.content)
            print("[PatternsViewModel] Got \(result.patterns.count) patterns from extraction")

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
            print("Failed to analyze entry: \(error.localizedDescription)")
            // Don't mark as analyzed if it failed
        }
    }
}

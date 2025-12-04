import Foundation
import CoreData
import SwiftUI

@MainActor
class PatternsViewModel: ObservableObject {
    @Published var todayPatterns: [ExtractedPattern] = []
    @Published var todayCascades: [PatternCascade] = []
    @Published var todaySummary: String?
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var hasUnanalyzedEntries = false
    @Published var error: String?

    private let dataController = DataController.shared
    private let extractionService = PatternExtractionService.shared

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

            // Get summary from most recent analyzed journal entry
            let journalFetch = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
            journalFetch.predicate = NSPredicate(
                format: "timestamp >= %@ AND timestamp < %@ AND isAnalyzed == YES",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            journalFetch.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]
            journalFetch.fetchLimit = 1

            let analyzedEntries = try context.fetch(journalFetch)
            todaySummary = analyzedEntries.first?.analysisSummary

            // Check for unanalyzed entries
            await checkUnanalyzedEntries()

        } catch {
            self.error = "Failed to load patterns: \(error.localizedDescription)"
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
        guard !isAnalyzing else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Fetch unanalyzed entries
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

            for entry in entries {
                await analyzeEntry(entry, context: context)
            }

            try context.save()

            // Reload patterns
            await loadTodayPatterns()

        } catch {
            self.error = "Failed to analyze entries: \(error.localizedDescription)"
        }
    }

    private func analyzeEntry(_ entry: JournalEntry, context: NSManagedObjectContext) async {
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
            print("Failed to analyze entry: \(error.localizedDescription)")
            // Don't mark as analyzed if it failed
        }
    }
}

import SwiftUI
import CoreData

@MainActor
class JournalViewModel: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                loadJournalEntries()
            } else {
                searchEntries()
            }
        }
    }
    @Published var showFavoritesOnly: Bool = false {
        didSet {
            loadJournalEntries()
        }
    }
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let dataController = DataController.shared
    private let extractionService = PatternExtractionService.shared

    init() {
        loadJournalEntries()
    }

    func loadJournalEntries() {
        Task {
            isLoading = true
            journalEntries = await dataController.fetchJournalEntries(favoritesOnly: showFavoritesOnly)
            isLoading = false
        }
    }

    func searchEntries() {
        Task {
            isLoading = true
            journalEntries = await dataController.searchJournalEntries(query: searchQuery)
            isLoading = false
        }
    }

    func createEntry(
        title: String? = nil,
        content: String,
        mood: Int16 = 0,
        audioFileName: String? = nil,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) -> Bool {
        do {
            let entry = try dataController.createJournalEntry(
                title: title,
                content: content,
                mood: mood,
                audioFileName: audioFileName,
                relatedPatternEntry: relatedPatternEntry,
                relatedMedicationLog: relatedMedicationLog
            )
            loadJournalEntries()

            // Auto-analyze the new entry for patterns in background
            Task {
                await analyzeEntry(entry)
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    // MARK: - Pattern Extraction

    /// Analyze a journal entry to extract patterns
    func analyzeEntry(_ entry: JournalEntry) async {
        guard !entry.isAnalyzed else { return }
        guard extractionService.isConfigured else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let result = try await extractionService.extractPatterns(from: entry.content)
            let context = dataController.container.viewContext

            // Create ExtractedPattern entities
            var createdPatterns: [String: ExtractedPattern] = [:]

            for patternData in result.patterns {
                let pattern = ExtractedPattern(context: context)
                pattern.id = UUID()
                pattern.patternType = patternData.type
                pattern.category = patternData.category
                pattern.intensity = Int16(patternData.intensity)
                pattern.triggers = patternData.triggers ?? []
                pattern.timeOfDay = patternData.timeOfDay ?? result.context.timeOfDay
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

            try context.save()
            loadJournalEntries()

        } catch {
            print("Failed to analyze entry: \(error.localizedDescription)")
        }
    }

    func updateEntry(_ entry: JournalEntry, reanalyze: Bool = true) {
        dataController.updateJournalEntry(entry)
        loadJournalEntries()

        // Re-analyze if content was changed
        if reanalyze && entry.isAnalyzed {
            // Clear old analysis to trigger re-analysis
            Task {
                await clearAndReanalyze(entry)
            }
        }
    }

    /// Clear existing patterns and re-analyze the entry
    private func clearAndReanalyze(_ entry: JournalEntry) async {
        let context = dataController.container.viewContext

        // Delete existing patterns for this entry
        if let existingPatterns = entry.extractedPatterns as? Set<ExtractedPattern> {
            for pattern in existingPatterns {
                context.delete(pattern)
            }
        }

        // Mark as not analyzed
        entry.isAnalyzed = false
        entry.analysisSummary = nil
        entry.analysisConfidence = 0
        entry.overallIntensity = 0

        try? context.save()

        // Re-analyze
        await analyzeEntry(entry)
    }

    func deleteEntry(_ entry: JournalEntry) {
        // Remove from local array first to prevent SwiftUI from accessing deleted object
        let entryId = entry.id
        journalEntries.removeAll { $0.id == entryId }

        // Then delete from Core Data
        dataController.deleteJournalEntry(entry)
    }

    func toggleFavorite(_ entry: JournalEntry) {
        entry.isFavorite.toggle()
        dataController.updateJournalEntry(entry)
        loadJournalEntries()
    }

    func getEntriesByDateRange(startDate: Date, endDate: Date) async -> [JournalEntry] {
        return await dataController.fetchJournalEntries(startDate: startDate, endDate: endDate)
    }

    func getEntriesGroupedByDate() -> [Date: [JournalEntry]] {
        let calendar = Calendar.current
        var grouped: [Date: [JournalEntry]] = [:]

        for entry in journalEntries {
            let startOfDay = calendar.startOfDay(for: entry.timestamp)
            if grouped[startOfDay] != nil {
                grouped[startOfDay]?.append(entry)
            } else {
                grouped[startOfDay] = [entry]
            }
        }

        return grouped
    }
}

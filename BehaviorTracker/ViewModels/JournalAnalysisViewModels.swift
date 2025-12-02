import SwiftUI
import CoreData

// MARK: - Journal Analysis ViewModel

@MainActor
class JournalAnalysisViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: String?
    @Published var errorMessage: String?

    private let aiService = AIAnalysisService.shared

    func analyzeEntry(_ entry: JournalEntry, context: NSManagedObjectContext) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            // Fetch related data for context
            let recentJournals = fetchRecentJournals(excluding: entry, context: context)
            let recentPatterns = fetchRecentPatterns(context: context)

            // Build the prompt
            let prompt = buildAnalysisPrompt(entry: entry, journals: recentJournals, patterns: recentPatterns)

            // Call AI service
            let result = try await aiService.analyzeWithPrompt(prompt)
            analysisResult = result
        } catch {
            errorMessage = "Failed to analyze: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    private func fetchRecentJournals(excluding entry: JournalEntry, context: NSManagedObjectContext) -> [JournalEntry] {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        request.predicate = NSPredicate(format: "id != %@", entry.id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]
        request.fetchLimit = 20

        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    private func fetchRecentPatterns(context: NSManagedObjectContext) -> [PatternEntry] {
        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        request.predicate = NSPredicate(format: "timestamp >= %@", thirtyDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]
        request.fetchLimit = 50

        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    private func buildAnalysisPrompt(entry: JournalEntry, journals: [JournalEntry], patterns: [PatternEntry]) -> String {
        var prompt = """
        Analyze this journal entry in context of the user's recent data:

        ## Entry to Analyze
        Title: \(entry.title ?? "Untitled")
        Content: \(entry.content)
        Date: \(entry.formattedDate)

        """

        // Add recent journals for context
        if !journals.isEmpty {
            prompt += "\n## Recent Journal Entries (for context)\n"
            for journal in journals.prefix(10) {
                prompt += "- \(journal.title ?? "Untitled"): \(journal.preview)\n"
            }
        }

        // Add recent patterns
        if !patterns.isEmpty {
            prompt += "\n## Recent Logged Patterns (last 30 days)\n"
            let patternCounts = Dictionary(grouping: patterns) { $0.patternType }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            for (pattern, count) in patternCounts.prefix(10) {
                prompt += "- \(pattern): \(count) times\n"
            }
        }

        prompt += """

        ## Analysis Request
        Based on the entry above and the user's history:
        1. Identify any patterns or themes that connect to their logged behaviors
        2. Note any potential triggers or correlations
        3. Provide 2-3 actionable insights or suggestions
        4. Keep the response concise and supportive

        Focus on being helpful and constructive. Do not diagnose or provide medical advice.
        """

        return prompt
    }
}

// MARK: - Day Analysis ViewModel

@MainActor
class DayAnalysisViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: String?
    @Published var errorMessage: String?

    private let aiService = AIAnalysisService.shared

    func analyzeDay(entries: [JournalEntry], date: Date, context: NSManagedObjectContext) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            let recentPatterns = fetchRecentPatterns(context: context)
            let prompt = buildDayAnalysisPrompt(entries: entries, date: date, patterns: recentPatterns)
            let result = try await aiService.analyzeWithPrompt(prompt)
            analysisResult = result
        } catch {
            errorMessage = "Failed to analyze: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    private func fetchRecentPatterns(context: NSManagedObjectContext) -> [PatternEntry] {
        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        request.predicate = NSPredicate(format: "timestamp >= %@", thirtyDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]
        request.fetchLimit = 50

        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    private func buildDayAnalysisPrompt(entries: [JournalEntry], date: Date, patterns: [PatternEntry]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        let dateString = dateFormatter.string(from: date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        var prompt = """
        Analyze this day's journal entries and provide insights:

        ## Day: \(dateString)
        ## Number of entries: \(entries.count)

        ## Timeline of Entries:
        """

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let time = timeFormatter.string(from: entry.timestamp)
            prompt += "\n\n### \(time)"
            if let title = entry.title, !title.isEmpty {
                prompt += " - \(title)"
            }
            prompt += "\n\(entry.content)"
        }

        if !patterns.isEmpty {
            prompt += "\n\n## Recent Logged Patterns (last 30 days)\n"
            let patternCounts = Dictionary(grouping: patterns) { $0.patternType }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            for (pattern, count) in patternCounts.prefix(10) {
                prompt += "- \(pattern): \(count) times\n"
            }
        }

        prompt += """

        ## Analysis Request
        Based on the day's entries above:
        1. Identify the overall emotional arc or progression throughout the day
        2. Note any patterns, triggers, or significant moments
        3. Highlight connections between different entries
        4. Provide 2-3 actionable insights or observations
        5. Keep the response concise and supportive

        Focus on being helpful and constructive. Do not diagnose or provide medical advice.
        """

        return prompt
    }
}

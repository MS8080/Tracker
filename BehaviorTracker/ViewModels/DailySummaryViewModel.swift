import Foundation
import SwiftUI

// MARK: - Models

struct DaySummary: Identifiable {
    let id = UUID()
    let date: Date
    var entries: [EntrySummary]

    var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

struct EntrySummary: Identifiable {
    let id: UUID
    let originalEntry: JournalEntry?
    let timestamp: Date
    var summary: String
    var patterns: [String]
    var isGenerating: Bool

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - ViewModel

@MainActor
class DailySummaryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var daySummaries: [DaySummary] = []
    @Published var isLoading = false
    @Published var showPatterns = false
    @Published var shareItem: ShareItem?
    @Published var entryToShare: EntrySummary?

    // MARK: - Dependencies

    private let dataController = DataController.shared
    private let geminiService = GeminiService.shared
    private let knowledgeRepo = PersonalKnowledgeRepository.shared
    private let analysisCoordinator = AnalysisCoordinator.shared

    // MARK: - Loading

    func loadSummaries() async {
        isLoading = true

        // Fetch recent journal entries (last 7 days)
        let entries = fetchRecentEntries()

        // Group by day
        let grouped = groupEntriesByDay(entries)

        // Create day summaries - use saved summary if available, otherwise show preview and generate
        daySummaries = grouped.map { date, dayEntries in
            DaySummary(
                date: date,
                entries: dayEntries.map { entry in
                    let hasSummary = entry.analysisSummary != nil
                    return EntrySummary(
                        id: entry.id,
                        originalEntry: entry,
                        timestamp: entry.timestamp,
                        summary: entry.analysisSummary ?? entry.preview,
                        patterns: entry.patternsArray.map { $0.patternType },
                        isGenerating: !hasSummary
                    )
                }
            )
        }

        isLoading = false

        // Queue pattern extraction for unanalyzed entries
        for (_, dayEntries) in grouped {
            for entry in dayEntries where !entry.isAnalyzed {
                analysisCoordinator.queueAnalysis(for: entry)
            }
        }

        // Generate AI summaries for entries that need them
        await generateMissingSummaries()
    }

    func refresh() async {
        await loadSummaries()
    }

    // MARK: - Data Fetching

    private func fetchRecentEntries() -> [JournalEntry] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday

        return dataController.fetchJournalEntriesSync(
            startDate: sevenDaysAgo,
            endDate: Date()
        ).filter { !$0.isInsight } // Exclude saved insights
    }

    private func groupEntriesByDay(_ entries: [JournalEntry]) -> [(Date, [JournalEntry])] {
        let calendar = Calendar.current
        var grouped: [Date: [JournalEntry]] = [:]

        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.timestamp)
            if grouped[dayStart] == nil {
                grouped[dayStart] = []
            }
            grouped[dayStart]?.append(entry)
        }

        // Sort days (most recent first) and entries within each day
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, entries) in
                (date, entries.sorted { $0.timestamp > $1.timestamp })
            }
    }

    // MARK: - AI Summary Generation

    private func generateMissingSummaries() async {
        for dayIndex in daySummaries.indices {
            for entryIndex in daySummaries[dayIndex].entries.indices {
                let entry = daySummaries[dayIndex].entries[entryIndex]

                // Skip if already has a good summary
                if !entry.isGenerating { continue }

                guard let originalEntry = entry.originalEntry else { continue }

                // Generate summary
                do {
                    let summary = try await generateSummary(for: originalEntry)

                    // Save to Core Data so we don't regenerate next time
                    saveSummary(summary, for: originalEntry)

                    // Update the view
                    daySummaries[dayIndex].entries[entryIndex].summary = summary
                    daySummaries[dayIndex].entries[entryIndex].isGenerating = false

                } catch {
                    // Fallback to preview
                    daySummaries[dayIndex].entries[entryIndex].summary = originalEntry.preview
                    daySummaries[dayIndex].entries[entryIndex].isGenerating = false
                }
            }
        }
    }

    private func saveSummary(_ summary: String, for entry: JournalEntry) {
        entry.analysisSummary = summary
        dataController.save()
    }

    private func generateSummary(for entry: JournalEntry) async throws -> String {
        let patterns = entry.patternsArray.map { $0.patternType }.joined(separator: ", ")
        let patternsContext = patterns.isEmpty ? "" : "Patterns: \(patterns). "

        // Get user's personal context from "Teach AI About Me"
        let userContext = knowledgeRepo.getCombinedContext()
        let contextSection = userContext.map { """
        About the person:
        \($0)

        """
        } ?? ""

        let prompt = """
        \(contextSection)Summarize this journal entry in 1-2 short sentences.
        Rules:
        - Use second person ("You felt...", "You were...", "You needed...")
        - NEVER use "the user", "they", or third person
        - Use clear, everyday language
        - Focus on feelings and what happened
        - Use the context above to better understand their experiences
        \(patternsContext)

        Entry: \(entry.content)

        Summary:
        """

        var response = try await geminiService.generateContent(prompt: prompt)
        response = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Fallback: replace any third-person references the AI might have used
        response = response
            .replacingOccurrences(of: "The user ", with: "You ")
            .replacingOccurrences(of: "the user ", with: "you ")
            .replacingOccurrences(of: "The user's ", with: "Your ")
            .replacingOccurrences(of: "the user's ", with: "your ")

        return response
    }

    // MARK: - Copy Actions

    func copyEntrySummary(_ entry: EntrySummary) {
        UIPasteboard.general.string = entry.summary
        HapticFeedback.success.trigger()
    }

    // MARK: - Share Actions

    func showShareOptions(for entry: EntrySummary) {
        entryToShare = entry
    }

    func shareText(_ text: String) {
        shareItem = ShareItem(text: text)
    }
}

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
    private let userProfileRepo = UserProfileRepository.shared

    // Cache for generated summaries
    private var summaryCache: [UUID: String] = [:]

    // MARK: - Loading

    func loadSummaries() async {
        isLoading = true

        // Fetch recent journal entries (last 7 days)
        let entries = fetchRecentEntries()

        // Group by day
        let grouped = groupEntriesByDay(entries)

        // Create day summaries with placeholders
        daySummaries = grouped.map { date, dayEntries in
            DaySummary(
                date: date,
                entries: dayEntries.map { entry in
                    EntrySummary(
                        id: entry.id,
                        originalEntry: entry,
                        timestamp: entry.timestamp,
                        summary: summaryCache[entry.id] ?? entry.analysisSummary ?? entry.preview,
                        patterns: entry.patternsArray.map { $0.patternType },
                        isGenerating: summaryCache[entry.id] == nil && entry.analysisSummary == nil
                    )
                }
            )
        }

        isLoading = false

        // Generate AI summaries for entries that need them
        await generateMissingSummaries()
    }

    func refresh() async {
        summaryCache.removeAll()
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
        // Get user context for AI
        let userContext = getUserContext()

        for dayIndex in daySummaries.indices {
            for entryIndex in daySummaries[dayIndex].entries.indices {
                let entry = daySummaries[dayIndex].entries[entryIndex]

                // Skip if already has a good summary
                if !entry.isGenerating { continue }

                guard let originalEntry = entry.originalEntry else { continue }

                // Generate summary
                do {
                    let summary = try await generateSummary(
                        for: originalEntry,
                        userContext: userContext
                    )

                    // Cache and update
                    summaryCache[entry.id] = summary

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

    private func getUserContext() -> String {
        let profile = userProfileRepo.getCurrentProfile()
        let name = profile?.name ?? "the user"

        return """
        Context: \(name) is autistic and uses this app to track their daily experiences, \
        energy levels, sensory states, and patterns. They want summaries that are clear, \
        simple, and easy to understand - both for themselves and to share with others \
        who may not be familiar with autism.
        """
    }

    private func generateSummary(for entry: JournalEntry, userContext: String) async throws -> String {
        let patterns = entry.patternsArray.map { $0.patternType }.joined(separator: ", ")
        let patternsContext = patterns.isEmpty ? "" : "Patterns detected: \(patterns). "

        let prompt = """
        \(userContext)

        Summarize this journal entry in 1-2 short sentences. Use clear, everyday language. \
        Focus on what happened and how they felt. Don't use clinical terms. \
        \(patternsContext)

        Entry:
        \(entry.content)

        Summary (1-2 sentences only):
        """

        let response = try await geminiService.generateContent(prompt: prompt)
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
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

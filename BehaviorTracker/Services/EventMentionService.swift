import Foundation

/// Service for handling @event mentions in journal entries
class EventMentionService {
    static let shared = EventMentionService()

    private let calendarService = CalendarEventService.shared

    private init() {}

    // MARK: - Mention Pattern

    /// Pattern to match @mentions: @[Event Title](eventID)
    private let mentionPattern = #"@\[([^\]]+)\]\(([^)]+)\)"#

    /// Pattern to detect incomplete @mention (user is typing)
    private let typingPattern = #"@(\w*)$"#

    // MARK: - Search Events

    /// Search for events matching query (for autocomplete)
    func searchEvents(query: String, around date: Date = Date()) -> [CalendarEvent] {
        guard calendarService.isAuthorized else { return [] }

        // Get events from past week to next 2 weeks
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: date) ?? date
        let endDate = calendar.date(byAdding: .day, value: 14, to: date) ?? date

        let allEvents = calendarService.fetchEvents(from: startDate, to: endDate)

        // Filter by query
        if query.isEmpty {
            // Return upcoming events first, sorted by proximity to now
            return Array(allEvents.sorted { event1, event2 in
                abs(event1.startDate.timeIntervalSince(date)) < abs(event2.startDate.timeIntervalSince(date))
            }.prefix(10))
        }

        let lowercaseQuery = query.lowercased()
        return allEvents.filter { event in
            event.title.lowercased().contains(lowercaseQuery)
        }.sorted { event1, event2 in
            // Sort by relevance (starts with query first) then by date proximity
            let starts1 = event1.title.lowercased().hasPrefix(lowercaseQuery)
            let starts2 = event2.title.lowercased().hasPrefix(lowercaseQuery)
            if starts1 != starts2 {
                return starts1
            }
            return abs(event1.startDate.timeIntervalSince(date)) < abs(event2.startDate.timeIntervalSince(date))
        }
    }

    // MARK: - Mention Formatting

    /// Create a mention string for an event
    func createMention(for event: CalendarEvent) -> String {
        return "@[\(event.title)](\(event.id))"
    }

    /// Extract the typing query from text (what user is typing after @)
    func extractTypingQuery(from text: String, cursorPosition: Int) -> String? {
        guard cursorPosition > 0, cursorPosition <= text.count else { return nil }

        let textBeforeCursor = String(text.prefix(cursorPosition))

        // Find the last @ symbol
        guard let atRange = textBeforeCursor.range(of: "@", options: .backwards) else {
            return nil
        }

        let queryStart = atRange.upperBound
        let query = String(textBeforeCursor[queryStart...])

        // Check if query contains spaces or special characters that would end the mention
        if query.contains(" ") || query.contains("\n") || query.contains("[") {
            return nil
        }

        return query
    }

    /// Get the range of the current @mention being typed
    func getTypingMentionRange(from text: String, cursorPosition: Int) -> Range<String.Index>? {
        guard cursorPosition > 0, cursorPosition <= text.count else { return nil }

        let textBeforeCursor = String(text.prefix(cursorPosition))

        guard let atRange = textBeforeCursor.range(of: "@", options: .backwards) else {
            return nil
        }

        let queryStart = atRange.upperBound
        let query = String(textBeforeCursor[queryStart...])

        // Check if query contains spaces or special characters
        if query.contains(" ") || query.contains("\n") || query.contains("[") {
            return nil
        }

        // Return range from @ to cursor
        let startIndex = text.index(text.startIndex, offsetBy: textBeforeCursor.distance(from: textBeforeCursor.startIndex, to: atRange.lowerBound))
        let endIndex = text.index(text.startIndex, offsetBy: cursorPosition)

        return startIndex..<endIndex
    }

    // MARK: - Parse Mentions

    /// Extract all event mentions from text
    func extractMentions(from text: String) -> [EventMention] {
        guard let regex = try? NSRegularExpression(pattern: mentionPattern) else {
            return []
        }

        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: nsRange)

        return matches.compactMap { match in
            guard match.numberOfRanges >= 3,
                  let titleRange = Range(match.range(at: 1), in: text),
                  let idRange = Range(match.range(at: 2), in: text),
                  let fullRange = Range(match.range(at: 0), in: text) else {
                return nil
            }

            return EventMention(
                title: String(text[titleRange]),
                eventID: String(text[idRange]),
                range: fullRange
            )
        }
    }

    /// Get display text with mentions formatted for display (just show event title with @ prefix)
    func displayText(from text: String) -> String {
        var result = text
        let mentions = extractMentions(from: text)

        // Replace in reverse order to maintain ranges
        for mention in mentions.reversed() {
            result.replaceSubrange(mention.range, with: "@\(mention.title)")
        }

        return result
    }

    /// Look up event details for a mention
    func lookupEvent(for mention: EventMention, around date: Date = Date()) -> CalendarEvent? {
        guard calendarService.isAuthorized else { return nil }

        // Search in a wider range to find the event
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -1, to: date) ?? date
        let endDate = calendar.date(byAdding: .month, value: 1, to: date) ?? date

        let events = calendarService.fetchEvents(from: startDate, to: endDate)
        return events.first { $0.id == mention.eventID }
    }
}

// MARK: - Event Mention Model

struct EventMention: Identifiable {
    let id = UUID()
    let title: String
    let eventID: String
    let range: Range<String.Index>
}

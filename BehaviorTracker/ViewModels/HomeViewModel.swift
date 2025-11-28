import SwiftUI
import CoreData

// MARK: - Models

struct RecentContext {
    let icon: String
    let color: Color
    let message: String
    let timeAgo: String?
}

struct Memory: Identifiable {
    let id = UUID()
    let timeframe: String
    let description: String
}

struct DaySummarySlide: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let detail: String
}

struct AIGeneratedSlide: Codable {
    let icon: String
    let colorName: String
    let title: String
    let message: String
}

// MARK: - ViewModel

@MainActor
class HomeViewModel: ObservableObject {
    @Published var userFirstName: String?
    @Published var recentContext: RecentContext?
    @Published var memories: [Memory] = []
    @Published var todaySlides: [DaySummarySlide] = []
    @Published var hasTodayEntries: Bool = false
    @Published var isGeneratingSlides: Bool = false
    @Published var slidesError: String?

    private let dataController = DataController.shared
    private let geminiService = GeminiService.shared

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    func loadData() {
        loadUserName()
        loadRecentContext()
        loadMemories()
        loadTodaySlides()
    }

    func refresh() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        loadData()
    }

    func saveSpecialNote(_ note: String) {
        // Save to journal with "from Home" tag
        _ = try? dataController.createJournalEntry(
            title: "From Home",
            content: note,
            mood: 3, // Neutral mood
            audioFileName: nil
        )
    }

    // MARK: - Private Methods

    private func loadUserName() {
        if let profile = dataController.getCurrentUserProfile() {
            let fullName = profile.name
            // Extract first name only
            if !fullName.isEmpty {
                userFirstName = fullName.components(separatedBy: " ").first
            }
        }
    }

    private func loadRecentContext() {
        // Get most recent entry
        let recentEntries = dataController.fetchPatternEntries(limit: 5)

        guard let mostRecent = recentEntries.first else {
            recentContext = nil
            return
        }

        let timeAgo = RelativeDateTimeFormatter().localizedString(for: mostRecent.timestamp, relativeTo: Date())

        // Create contextual message based on what was logged
        let patternType = mostRecent.patternType
        let category = mostRecent.patternCategoryEnum

        let message: String
        let icon: String
        let color: Color

        if let category = category {
            icon = category.icon
            color = category.color

            // Create natural language description
            switch category {
            case .sensory:
                message = "You noted some sensory experiences"
            case .executiveFunction:
                message = "You were managing tasks and focus"
            case .social:
                message = "You had some social interactions"
            case .energyRegulation:
                message = "You logged how your energy was feeling"
            case .routineChange:
                message = "Something happened with your routine"
            case .demandAvoidance:
                message = "You noticed some demand-related feelings"
            case .physicalWellbeing:
                message = "You took care of yourself"
            }
        } else {
            icon = "circle.fill"
            color = .gray
            message = "You logged: \(patternType)"
        }

        recentContext = RecentContext(
            icon: icon,
            color: color,
            message: message,
            timeAgo: timeAgo
        )
    }

    private func loadMemories() {
        var foundMemories: [Memory] = []
        let calendar = Calendar.current

        // Check last week same day - more personal
        if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) {
            let entries = fetchEntriesForDay(lastWeek)
            if !entries.isEmpty {
                let description = describeDay(entries, prefix: "Last week")
                foundMemories.append(Memory(
                    timeframe: "This time last week",
                    description: description
                ))
            }
        }

        // Find a time you overcame something difficult
        if let overcameMemory = findOvercomeMemory() {
            foundMemories.append(overcameMemory)
        }

        // Check last month same day
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) {
            let entries = fetchEntriesForDay(lastMonth)
            if !entries.isEmpty {
                let description = describeDay(entries, prefix: "Last month")
                foundMemories.append(Memory(
                    timeframe: "This time last month",
                    description: description
                ))
            }
        }

        // Check if there's a pattern at this time of day
        let currentHour = calendar.component(.hour, from: Date())
        let timeOfDayPattern = findTimeOfDayPattern(hour: currentHour)
        if let pattern = timeOfDayPattern {
            foundMemories.append(Memory(
                timeframe: "Around this time",
                description: pattern
            ))
        }

        memories = foundMemories
    }

    private func findOvercomeMemory() -> Memory? {
        // Look for high-intensity entries followed by recovery or self-care
        let calendar = Calendar.current
        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else {
            return nil
        }

        let entries = dataController.fetchPatternEntries(startDate: twoWeeksAgo, endDate: Date())

        // Find high intensity moments (4-5) followed by lower intensity or self-care
        for (index, entry) in entries.enumerated() where entry.intensity >= 4 {
            // Check if there was recovery afterward
            if index > 0 {
                let laterEntry = entries[index - 1] // entries are sorted newest first
                let category = laterEntry.patternCategoryEnum

                if category == .physicalWellbeing || laterEntry.intensity <= 2 {
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .full
                    let timeAgo = formatter.localizedString(for: entry.timestamp, relativeTo: Date())

                    return Memory(
                        timeframe: "You got through it",
                        description: "\(timeAgo), you felt overwhelmed by \(entry.patternType.lowercased()) — and you made it through."
                    )
                }
            }
        }

        return nil
    }

    private func describeDay(_ entries: [PatternEntry], prefix: String) -> String {
        // Get the most significant entry (highest intensity or most logged)
        if let significant = entries.max(by: { $0.intensity < $1.intensity }) {
            let pattern = significant.patternType.lowercased()
            if significant.intensity >= 4 {
                return "\(prefix), you were dealing with \(pattern). You got through it."
            } else if significant.intensity <= 2 {
                return "\(prefix) was a calmer day. You logged \(pattern)."
            } else {
                return "\(prefix), you noticed \(pattern)."
            }
        }
        return "\(prefix), you logged \(entries.count) things."
    }

    private func fetchEntriesForDay(_ date: Date) -> [PatternEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return dataController.fetchPatternEntries(startDate: startOfDay, endDate: endOfDay)
    }

    private func findTimeOfDayPattern(hour: Int) -> String? {
        // Look at the last 2 weeks of entries around this hour
        let calendar = Calendar.current
        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else {
            return nil
        }

        let entries = dataController.fetchPatternEntries(startDate: twoWeeksAgo, endDate: Date())

        // Filter to entries within 2 hours of current time
        let relevantEntries = entries.filter { entry in
            let entryHour = calendar.component(.hour, from: entry.timestamp)
            return abs(entryHour - hour) <= 2
        }

        guard relevantEntries.count >= 3 else { return nil }

        // Find most common pattern at this time
        var patterns: [String: Int] = [:]
        for entry in relevantEntries {
            patterns[entry.patternType, default: 0] += 1
        }

        if let mostCommon = patterns.max(by: { $0.value < $1.value }), mostCommon.value >= 3 {
            return "You often log \"\(mostCommon.key)\" around now"
        }

        return nil
    }

    private func loadTodaySlides() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            hasTodayEntries = false
            return
        }

        let todayPatterns = dataController.fetchPatternEntries(startDate: startOfDay, endDate: endOfDay)
        let todayJournals = dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)

        hasTodayEntries = !todayPatterns.isEmpty || !todayJournals.isEmpty
    }

    func generateAISlides() async {
        isGeneratingSlides = true
        slidesError = nil
        todaySlides = []

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            isGeneratingSlides = false
            return
        }

        let todayPatterns = dataController.fetchPatternEntries(startDate: startOfDay, endDate: endOfDay)
        let todayJournals = dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)

        guard !todayPatterns.isEmpty || !todayJournals.isEmpty else {
            isGeneratingSlides = false
            slidesError = "No entries today to summarize"
            return
        }

        // Build data summary for AI
        var dataSummary = "Today's data:\n\n"

        if !todayPatterns.isEmpty {
            dataSummary += "LOGGED PATTERNS:\n"
            for entry in todayPatterns {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let time = timeFormatter.string(from: entry.timestamp)
                dataSummary += "- [\(time)] \(entry.patternType) (intensity: \(entry.intensity)/5)"
                if let notes = entry.contextNotes, !notes.isEmpty {
                    dataSummary += " - \"\(notes)\""
                }
                dataSummary += "\n"
            }
            dataSummary += "\n"
        }

        if !todayJournals.isEmpty {
            dataSummary += "JOURNAL ENTRIES:\n"
            for entry in todayJournals {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let time = timeFormatter.string(from: entry.timestamp)
                let moodText = entry.mood > 0 ? " (mood: \(entry.mood)/5)" : ""
                let title = entry.title ?? ""
                dataSummary += "- [\(time)]\(title.isEmpty ? "" : " \(title)")\(moodText): \"\(entry.content)\"\n"
            }
        }

        let prompt = """
        You are analyzing behavioral tracking data for someone with autism/ADHD. Your job is to find CONNECTIONS and PATTERNS - NOT to list what was logged.

        \(dataSummary)

        CRITICAL RULES:
        1. DO NOT say "You logged X" or "You noted X" - that's just repeating data
        2. DO NOT list individual entries - find what they MEAN together
        3. DO find cause-effect relationships (e.g., sensory issues → energy drop)
        4. DO notice timing patterns (morning vs afternoon trends)
        5. DO identify the overall story of the day
        6. Be neutral and observational, not cheerful or judgmental

        GOOD examples:
        - "Sensory sensitivity peaked before the energy crash - possible connection"
        - "Morning was calmer, afternoon brought more challenges"
        - "Physical discomfort and focus issues appeared together today"

        BAD examples (NEVER do this):
        - "You logged bright lights at 10am" ❌
        - "Today you noted 3 sensory experiences" ❌
        - "You experienced task initiation difficulty" ❌

        Generate 2-3 analytical insights. Return ONLY valid JSON array:
        [{"icon": "SF Symbol", "colorName": "gray/blue/purple/orange/green/cyan", "title": "2-3 word title", "message": "Insight under 60 chars"}]

        Icons: brain.head.profile, arrow.triangle.branch, clock.fill, bolt.fill, eye.fill, ear.fill, figure.walk, moon.fill, sun.max.fill, leaf.fill, link, arrow.up.arrow.down
        """

        do {
            let response = try await geminiService.generateContent(prompt: prompt)

            // Parse JSON from response
            if let jsonStart = response.firstIndex(of: "["),
               let jsonEnd = response.lastIndex(of: "]") {
                let jsonString = String(response[jsonStart...jsonEnd])

                if let jsonData = jsonString.data(using: .utf8) {
                    let aiSlides = try JSONDecoder().decode([AIGeneratedSlide].self, from: jsonData)

                    todaySlides = aiSlides.map { slide in
                        DaySummarySlide(
                            icon: slide.icon,
                            color: colorFromName(slide.colorName),
                            title: slide.title,
                            detail: slide.message
                        )
                    }
                }
            }

            if todaySlides.isEmpty {
                slidesError = "Couldn't create summary"
            }
        } catch {
            slidesError = error.localizedDescription
        }

        isGeneratingSlides = false
    }

    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "gray": return .gray
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "green": return .green
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

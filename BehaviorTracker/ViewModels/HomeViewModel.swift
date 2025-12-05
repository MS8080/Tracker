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
    @Published var currentStreak: Int = 0

    private let dataController = DataController.shared
    private let geminiService = GeminiService.shared
    
    // PERFORMANCE: Cache to avoid redundant queries
    private var lastLoadDate: Date?
    private var memoriesCache: [Memory] = []
    private var recentContextCache: RecentContext?
    private let cacheValidityInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Cached Formatters (Performance Optimization)
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

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
        // Skip if data was loaded recently (within 30 seconds)
        if let lastLoad = lastLoadDate,
           Date().timeIntervalSince(lastLoad) < 30 {
            return
        }

        // Load lightweight data first for instant UI
        loadUserName()
        loadStreak()
        loadTodaySlides()

        // Defer heavy queries to background
        Task.detached(priority: .utility) {
            await self.loadHeavyData()
        }
    }

    /// Force reload ignoring cache (e.g., after new entry)
    func forceReload() {
        lastLoadDate = nil
        memoriesCache = []
        recentContextCache = nil
        loadData()
    }

    @MainActor
    private func loadHeavyData() async {
        // Load expensive queries on background thread
        await Task.yield() // Allow UI to render first
        loadRecentContext()
        loadMemories()

        // Mark load time after all data is loaded
        lastLoadDate = Date()
    }

    private func loadStreak() {
        let preferences = dataController.getUserPreferences()
        currentStreak = Int(preferences.streakCount)
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
        // Use cache if valid
        if let lastLoad = lastLoadDate,
           Date().timeIntervalSince(lastLoad) < cacheValidityInterval,
           let cached = recentContextCache {
            recentContext = cached
            return
        }
        
        let recentEntries = dataController.fetchPatternEntries(limit: 5)

        guard let mostRecent = recentEntries.first else {
            recentContext = nil
            return
        }

        let timeAgo = Self.relativeDateFormatter.localizedString(for: mostRecent.timestamp, relativeTo: Date())
        let patternType = mostRecent.patternType
        let category = mostRecent.patternCategoryEnum

        let message: String
        let icon: String
        let color: Color

        if let category = category {
            icon = category.icon
            color = category.color

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
        
        // Update cache
        recentContextCache = recentContext
        lastLoadDate = Date()
    }

    private func loadMemories() {
        // Use cache if valid
        if !memoriesCache.isEmpty {
            memories = memoriesCache
            return
        }

        var foundMemories: [Memory] = []
        let calendar = Calendar.current

        // Single fetch for last 2 weeks - reuse for multiple analyses
        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else {
            return
        }
        let recentEntries = dataController.fetchPatternEntries(startDate: twoWeeksAgo, endDate: Date())

        // Check last week same day
        if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) {
            let lastWeekEntries = filterEntriesForDay(recentEntries, date: lastWeek)
            if !lastWeekEntries.isEmpty {
                let description = describeDay(lastWeekEntries, prefix: "Last week")
                foundMemories.append(Memory(
                    timeframe: "This time last week",
                    description: description
                ))
            }
        }

        // Find overcome memory using already-fetched data
        if let overcameMemory = findOvercomeMemory(from: recentEntries) {
            foundMemories.append(overcameMemory)
        }

        // Check last month (needs separate fetch since it's outside 2-week window)
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) {
            let lastMonthEntries = dataController.fetchPatternEntries(
                startDate: calendar.startOfDay(for: lastMonth),
                endDate: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastMonth)) ?? lastMonth
            )
            if !lastMonthEntries.isEmpty {
                let description = describeDay(lastMonthEntries, prefix: "Last month")
                foundMemories.append(Memory(
                    timeframe: "This time last month",
                    description: description
                ))
            }
        }

        // Check time-of-day pattern using already-fetched data
        let currentHour = calendar.component(.hour, from: Date())
        if let pattern = findTimeOfDayPattern(from: recentEntries, hour: currentHour) {
            foundMemories.append(Memory(
                timeframe: "Around this time",
                description: pattern
            ))
        }

        memories = foundMemories
        memoriesCache = foundMemories
    }

    private func findOvercomeMemory(from entries: [PatternEntry]) -> Memory? {
        for (index, entry) in entries.enumerated() where entry.intensity >= 4 {
            if index > 0 {
                let laterEntry = entries[index - 1]
                let category = laterEntry.patternCategoryEnum

                if category == .physicalWellbeing || laterEntry.intensity <= 2 {
                    let timeAgo = Self.relativeDateFormatter.localizedString(for: entry.timestamp, relativeTo: Date())
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

    private func filterEntriesForDay(_ entries: [PatternEntry], date: Date) -> [PatternEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return entries.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
    }

    private func findTimeOfDayPattern(from entries: [PatternEntry], hour: Int) -> String? {
        let calendar = Calendar.current
        let relevantEntries = entries.filter { entry in
            let entryHour = calendar.component(.hour, from: entry.timestamp)
            return abs(entryHour - hour) <= 2
        }

        guard relevantEntries.count >= 3 else { return nil }

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
        Task {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                hasTodayEntries = false
                return
            }

            let todayPatterns = dataController.fetchPatternEntries(startDate: startOfDay, endDate: endOfDay)
            let todayJournals = await dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)

            hasTodayEntries = !todayPatterns.isEmpty || !todayJournals.isEmpty
        }
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
        let todayJournals = await dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)

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
                let time = Self.timeFormatter.string(from: entry.timestamp)
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
                let time = Self.timeFormatter.string(from: entry.timestamp)
                let moodText = entry.mood > 0 ? " (mood: \(entry.mood)/5)" : ""
                let title = entry.title ?? ""
                dataSummary += "- [\(time)]\(title.isEmpty ? "" : " \(title)")\(moodText): \"\(entry.content)\"\n"
            }
        }

        let prompt = """
        You are analyzing behavioral tracking data for someone with autism/ADHD. Provide a MEANINGFUL, INSIGHTFUL narrative summary - NOT a list of what was logged.

        \(dataSummary)

        CRITICAL RULES:
        1. DO NOT say "You logged X" or "You noted X" - that's just repeating data
        2. DO NOT list individual entries - find what they MEAN together
        3. DO find cause-effect relationships and correlations (e.g., "Sensory overload preceded the energy crash by 90 minutes - the brain may have been compensating")
        4. DO notice temporal patterns and transitions (e.g., "The day started calm but degraded after lunch - likely related to accumulated cognitive load")
        5. DO identify triggers, cycles, and environmental factors
        6. DO provide actionable observations for future days
        7. Be neutral, analytical, and specific - avoid vague platitudes
        8. Each insight should be 100-200 characters for depth

        GOOD examples:
        - "Sensory sensitivity spiked 60-90min before focus deteriorated. Your nervous system may benefit from sensory breaks before tasks."
        - "Morning clarity was consistent until 2pm when multiple stressors converged. Consider protecting afternoon executive function time."
        - "Lighting and sound sensitivities clustered together - possible shared underlying factor like arousal state or inflammation."

        BAD examples (NEVER do this):
        - "You logged bright lights at 10am" ❌
        - "Today you noted 3 sensory experiences" ❌
        - "You experienced task initiation difficulty" ❌

        Generate 3-5 deep analytical insights that help understand patterns. Return ONLY valid JSON array:
        [{"icon": "SF Symbol", "colorName": "gray/blue/purple/orange/green/cyan", "title": "Pattern title (3-5 words)", "message": "Detailed insight explaining the pattern, connection, or implication (100-200 chars)"}]

        Icons: brain.head.profile, arrow.triangle.branch, clock.fill, bolt.fill, eye.fill, ear.fill, figure.walk, moon.fill, sun.max.fill, leaf.fill, link, arrow.up.arrow.down, waveform.path.ecg, chart.line.uptrend.xyaxis, chart.xyaxis.line
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

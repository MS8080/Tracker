import SwiftUI
import CoreData

// MARK: - Models

struct RecentContext {
    let icon: String
    let color: Color
    let message: String
    let timeAgo: String?
    let journalPreview: String?
}

struct Memory: Identifiable {
    let id = UUID()
    let timeframe: String
    let description: String
}

struct DaySummarySlide: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let detail: String

    static func == (lhs: DaySummarySlide, rhs: DaySummarySlide) -> Bool {
        lhs.id == rhs.id
    }
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
    @Published var todayEntryCount: Int = 0
    @Published var isGeneratingSlides: Bool = false
    @Published var slidesError: String?
    @Published var currentStreak: Int = 0

    private let dataController = DataController.shared
    private let geminiService = GeminiService.shared
    private let localAnalysisService = LocalAnalysisService.shared

    // Track if we should offer local analysis fallback
    @Published var showLocalAnalysisFallback: Bool = false

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
        await loadRecentContext()
        await loadMemories()

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

    // MARK: - Recent Context (now uses ExtractedPattern + JournalEntry)

    private func loadRecentContext() async {
        // Use cache if valid
        if let lastLoad = lastLoadDate,
           Date().timeIntervalSince(lastLoad) < cacheValidityInterval,
           let cached = recentContextCache {
            recentContext = cached
            return
        }

        // Fetch recent journal entries with their extracted patterns
        let recentJournals = await dataController.fetchJournalEntries(startDate: nil, endDate: nil, favoritesOnly: false)
        let sortedJournals = recentJournals.sorted { $0.timestamp > $1.timestamp }

        // Find most recent journal with extracted patterns
        for journal in sortedJournals.prefix(5) {
            let patterns = journal.patternsArray
            if !patterns.isEmpty {
                // Use the highest intensity pattern from this journal
                if let mostSignificant = patterns.max(by: { $0.intensity < $1.intensity }) {
                    let timeAgo = Self.relativeDateFormatter.localizedString(for: journal.timestamp, relativeTo: Date())
                    let context = buildRecentContext(from: mostSignificant, journal: journal, timeAgo: timeAgo)
                    recentContext = context
                    recentContextCache = context
                    return
                }
            } else if journal.isAnalyzed, let summary = journal.analysisSummary {
                // Journal was analyzed but no patterns - use the summary
                let timeAgo = Self.relativeDateFormatter.localizedString(for: journal.timestamp, relativeTo: Date())
                recentContext = RecentContext(
                    icon: "doc.text.fill",
                    color: .blue,
                    message: summary,
                    timeAgo: timeAgo,
                    journalPreview: nil
                )
                recentContextCache = recentContext
                return
            }
        }

        // Fallback: show most recent journal even if not analyzed
        if let mostRecent = sortedJournals.first {
            let timeAgo = Self.relativeDateFormatter.localizedString(for: mostRecent.timestamp, relativeTo: Date())
            recentContext = RecentContext(
                icon: "square.and.pencil",
                color: .gray,
                message: "You wrote in your journal",
                timeAgo: timeAgo,
                journalPreview: mostRecent.preview
            )
            recentContextCache = recentContext
        } else {
            recentContext = nil
        }
    }

    private func buildRecentContext(from pattern: ExtractedPattern, journal: JournalEntry, timeAgo: String) -> RecentContext {
        let category = pattern.category
        let icon: String
        let color: Color
        let message: String
        let insight: String?

        // Build specific message based on pattern details
        let patternName = pattern.patternType.lowercased()
        let intensity = pattern.intensity

        switch category {
        case "Sensory":
            icon = "waveform.path"
            color = .red
            if intensity >= 7 {
                message = "The sensory world was intense - \(patternName) took a lot out of you"
                insight = "Your system was working hard to process everything"
            } else {
                message = "You noticed some sensory moments - \(patternName)"
                insight = "Tuning into what your senses need"
            }
        case "Executive Function":
            icon = "brain.head.profile"
            color = .orange
            if intensity >= 7 {
                message = "Focus was really hard today - \(patternName) made things difficult"
                insight = "When the brain struggles to organize, everything feels heavier"
            } else {
                message = "You were navigating how to focus and get things done"
                insight = nil
            }
        case "Social & Communication":
            icon = "person.2.fill"
            color = .blue
            if intensity >= 7 {
                message = "Social stuff took a lot of energy - \(patternName)"
                insight = "People interactions can be exhausting, especially when you're already stretched"
            } else {
                message = "You had some people moments to process"
                insight = nil
            }
        case "Energy & Regulation":
            icon = "battery.75"
            color = .purple
            if intensity >= 7 {
                message = "Your energy was really depleted - \(patternName)"
                insight = "Running on empty makes everything harder"
            } else {
                message = "You were managing your energy levels"
                insight = "Noticing what fills and drains you"
            }
        case "Routine & Change":
            icon = "arrow.triangle.2.circlepath"
            color = .yellow
            message = "Something shifted in your routine or expectations"
            insight = "Change can feel unsettling, even small changes"
        case "Demand Avoidance":
            icon = "hand.raised.fill"
            color = .pink
            if intensity >= 7 {
                message = "Demands felt really overwhelming - \(patternName)"
                insight = "When everything feels like a 'have to', the resistance makes sense"
            } else {
                message = "You noticed some resistance to demands today"
                insight = nil
            }
        case "Physical & Sleep":
            icon = "heart.fill"
            color = .green
            message = "Your body was telling you something"
            insight = "Physical sensations and sleep affect everything else"
        case "Special Interests":
            icon = "star.fill"
            color = .cyan
            message = "You got to engage with something you love"
            insight = "These moments refuel you"
        default:
            icon = "circle.fill"
            color = .gray
            message = "You experienced \(patternName)"
            insight = pattern.details
        }

        return RecentContext(
            icon: icon,
            color: color,
            message: message,
            timeAgo: timeAgo,
            journalPreview: insight ?? pattern.details
        )
    }

    // MARK: - Memories (now uses ExtractedPattern + JournalEntry)

    private func loadMemories() async {
        // Use cache if valid
        if !memoriesCache.isEmpty {
            memories = memoriesCache
            return
        }

        var foundMemories: [Memory] = []
        let calendar = Calendar.current

        // Fetch recent patterns for analysis
        let recentPatterns = await fetchExtractedPatterns(daysBack: 14)
        let lastMonthPatterns = await fetchExtractedPatterns(forDate: calendar.date(byAdding: .month, value: -1, to: Date()))

        // Check last week same day
        if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) {
            let lastWeekPatterns = filterPatternsForDay(recentPatterns, date: lastWeek)
            if !lastWeekPatterns.isEmpty {
                let description = describeDay(lastWeekPatterns, prefix: "Last week")
                foundMemories.append(Memory(
                    timeframe: "This time last week",
                    description: description
                ))
            }
        }

        // Find overcome memory using extracted patterns
        if let overcameMemory = findOvercomeMemory(from: recentPatterns) {
            foundMemories.append(overcameMemory)
        }

        // Check last month
        if !lastMonthPatterns.isEmpty {
            let description = describeDay(lastMonthPatterns, prefix: "Last month")
            foundMemories.append(Memory(
                timeframe: "This time last month",
                description: description
            ))
        }

        // Check time-of-day pattern
        let currentHour = calendar.component(.hour, from: Date())
        if let pattern = findTimeOfDayPattern(from: recentPatterns, hour: currentHour) {
            foundMemories.append(Memory(
                timeframe: "Around this time",
                description: pattern
            ))
        }

        memories = foundMemories
        memoriesCache = foundMemories
    }

    private func fetchExtractedPatterns(daysBack: Int) async -> [ExtractedPattern] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else {
            return []
        }

        let fetchRequest: NSFetchRequest<ExtractedPattern> = ExtractedPattern.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startDate as NSDate,
            Date() as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractedPattern.timestamp, ascending: false)]

        do {
            return try dataController.container.viewContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }

    private func fetchExtractedPatterns(forDate date: Date?) async -> [ExtractedPattern] {
        guard let date = date else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let fetchRequest: NSFetchRequest<ExtractedPattern> = ExtractedPattern.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractedPattern.timestamp, ascending: false)]

        do {
            return try dataController.container.viewContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }

    private func filterPatternsForDay(_ patterns: [ExtractedPattern], date: Date) -> [ExtractedPattern] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return patterns.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
    }

    private func findOvercomeMemory(from patterns: [ExtractedPattern]) -> Memory? {
        // Sort by timestamp descending (most recent first)
        let sorted = patterns.sorted { $0.timestamp > $1.timestamp }

        for (index, pattern) in sorted.enumerated() where pattern.intensity >= 7 {
            // Look for a later pattern (earlier in array) with lower intensity
            if index > 0 {
                let laterPattern = sorted[index - 1]

                // Check if they recovered (low intensity or positive pattern)
                let positivePatterns = ["Flow State Achieved", "Authenticity Moment", "Special Interest Engagement"]
                let isPositive = positivePatterns.contains(laterPattern.patternType)

                if laterPattern.intensity <= 3 || isPositive {
                    let timeAgo = Self.relativeDateFormatter.localizedString(for: pattern.timestamp, relativeTo: Date())
                    let patternName = pattern.patternType.lowercased()
                    return Memory(
                        timeframe: "You got through it",
                        description: "\(timeAgo), you felt overwhelmed by \(patternName) — and you made it through."
                    )
                }
            }
        }
        return nil
    }

    private func describeDay(_ patterns: [ExtractedPattern], prefix: String) -> String {
        if let significant = patterns.max(by: { $0.intensity < $1.intensity }) {
            let patternName = significant.patternType.lowercased()
            if significant.intensity >= 7 {
                return "\(prefix), you were dealing with \(patternName). You got through it."
            } else if significant.intensity <= 3 {
                return "\(prefix) was a calmer day. You noticed \(patternName)."
            } else {
                return "\(prefix), you experienced \(patternName)."
            }
        }
        return "\(prefix), you had \(patterns.count) moments recorded."
    }

    private func findTimeOfDayPattern(from patterns: [ExtractedPattern], hour: Int) -> String? {
        let calendar = Calendar.current
        let relevantPatterns = patterns.filter { pattern in
            let patternHour = calendar.component(.hour, from: pattern.timestamp)
            return abs(patternHour - hour) <= 2
        }

        guard relevantPatterns.count >= 3 else { return nil }

        var patternCounts: [String: Int] = [:]
        for pattern in relevantPatterns {
            patternCounts[pattern.patternType, default: 0] += 1
        }

        if let mostCommon = patternCounts.max(by: { $0.value < $1.value }), mostCommon.value >= 3 {
            return "You often experience \"\(mostCommon.key.lowercased())\" around now"
        }
        return nil
    }

    // MARK: - Today Slides (now uses ExtractedPattern)

    private func loadTodaySlides() {
        Task {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                hasTodayEntries = false
                return
            }

            // Fetch today's journals and their extracted patterns
            let todayJournals = await dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)

            // Count patterns from journals
            var patternCount = 0
            for journal in todayJournals {
                patternCount += journal.patternsArray.count
            }

            // Use journal count if no patterns extracted yet
            let totalCount = max(patternCount, todayJournals.count)
            hasTodayEntries = totalCount > 0 || !todayJournals.isEmpty
            todayEntryCount = todayJournals.count
        }
    }

    // MARK: - Generate AI Slides (now uses ExtractedPattern data)

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

        // Fetch today's journals with their extracted patterns
        let todayJournals = await dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)

        guard !todayJournals.isEmpty else {
            isGeneratingSlides = false
            slidesError = "Your day is just beginning. I'll be here."
            return
        }

        // Collect all extracted patterns from today's journals
        var allPatterns: [ExtractedPattern] = []
        var allCascades: [PatternCascade] = []

        for journal in todayJournals {
            let patterns = journal.patternsArray
            allPatterns.append(contentsOf: patterns)

            for pattern in patterns {
                if let cascades = pattern.cascadesFrom {
                    allCascades.append(contentsOf: cascades)
                }
            }
        }

        // Build structured data summary from already-extracted patterns
        var dataSummary = "Today's patterns (already analyzed from journal entries):\n\n"

        if !allPatterns.isEmpty {
            dataSummary += "EXTRACTED PATTERNS:\n"
            for pattern in allPatterns.sorted(by: { $0.timestamp < $1.timestamp }) {
                let time = Self.timeFormatter.string(from: pattern.timestamp)
                dataSummary += "- [\(time)] \(pattern.patternType) (\(pattern.category), intensity: \(pattern.intensity)/10)"
                if let details = pattern.details, !details.isEmpty {
                    dataSummary += "\n  Details: \"\(details)\""
                }
                if !pattern.triggers.isEmpty {
                    dataSummary += "\n  Triggers: \(pattern.triggers.joined(separator: ", "))"
                }
                dataSummary += "\n"
            }
            dataSummary += "\n"
        }

        if !allCascades.isEmpty {
            dataSummary += "PATTERN CASCADES (what led to what):\n"
            for cascade in allCascades {
                let from = cascade.fromPattern?.patternType ?? "Unknown"
                let to = cascade.toPattern?.patternType ?? "Unknown"
                dataSummary += "- \(from) → \(to)"
                if let desc = cascade.descriptionText {
                    dataSummary += ": \(desc)"
                }
                dataSummary += " (confidence: \(Int(cascade.confidence * 100))%)\n"
            }
            dataSummary += "\n"
        }

        // Add journal summaries for context
        dataSummary += "JOURNAL CONTEXT:\n"
        for journal in todayJournals.sorted(by: { $0.timestamp < $1.timestamp }) {
            let time = Self.timeFormatter.string(from: journal.timestamp)
            if let summary = journal.analysisSummary {
                dataSummary += "- [\(time)] \(summary)\n"
            } else {
                dataSummary += "- [\(time)] \(journal.preview)\n"
            }
        }

        // Add Life Goals context (Goals, Struggles, Wishlist)
        let lifeGoalsContext = buildLifeGoalsContext()
        if !lifeGoalsContext.isEmpty {
            dataSummary += "\nLIFE CONTEXT:\n\(lifeGoalsContext)"
        }

        // If no patterns were extracted, fall back to raw journal content
        if allPatterns.isEmpty {
            dataSummary = "Today's journal entries (not yet analyzed for patterns):\n\n"
            for journal in todayJournals {
                let time = Self.timeFormatter.string(from: journal.timestamp)
                let moodText = journal.mood > 0 ? " (mood: \(journal.mood)/5)" : ""
                dataSummary += "- [\(time)]\(moodText): \"\(journal.content)\"\n"
            }
        }

        let prompt = """
        You are a warm, caring companion who has been with someone throughout their day, witnessing their experiences. You're now gently reflecting back what you noticed - like a supportive friend who truly sees them.

        \(dataSummary)

        YOUR VOICE & TONE:
        - Speak as "I" - you are an active witness ("I noticed...", "I saw that...", "I see...")
        - Be warm, validating, and gently supportive - NOT clinical or analytical
        - Acknowledge difficulty with phrases like "that's real", "that makes sense", "I see it"
        - Focus on witnessing and understanding, not instructing or advising
        - Use everyday language, not clinical terminology
        - Show you understand the weight of what they're carrying
        - End with reassurance like "I'm tracking this for you" or "That's real and it makes sense"

        TITLE STYLE:
        - Short, warm titles (2-4 words)
        - Examples: "Time Pressure & Overwhelm", "Family & Emotional Weight", "Sensory Seeking & Regulation", "Emotional Load & Focus"
        - NOT clinical titles like "Executive Dysfunction" or "Sensory Processing Issues"

        MESSAGE STYLE EXAMPLES:
        GOOD (warm, witnessing):
        - "I noticed you've been feeling pressure about past missed stops and upcoming family visits. Time felt heavy today. That's real and it makes sense."
        - "The call with your mother brought up a lot. Family conversations can reactivate old feelings. I'm tracking this pattern for you."
        - "You've been adjusting your glasses a lot today - seeking that just-right feeling. This often connects to anxiety underneath. I see it."
        - "Family stress is taking up mental space. It's hard to focus on other things when emotions are this present. That's normal."

        BAD (clinical, instructing):
        - "Concerns about past 'missed stops' trigger feelings of pressure" (too clinical)
        - "Monitor communication triggers" (instructing)
        - "Address time perception distortions directly" (advising)
        - "Explore grounding techniques" (prescriptive)

        WHAT TO NOTICE:
        - Be specific about WHAT happened (not abstract categories)
        - Validate the difficulty - "that's hard", "that's a lot", "that makes sense"
        - Show you see the connection - "this often connects to...", "when X happens, Y makes sense"
        - End warmly - "I'm tracking this", "I see it", "That's real"

        Generate 3-4 warm, supportive observations. Each message should be 120-200 characters.
        Return ONLY valid JSON array:
        [{"icon": "SF Symbol", "colorName": "gray/blue/purple/orange/green/cyan", "title": "Short gentle title (2-4 words)", "message": "Warm observation that acknowledges what happened, validates it, and reassures"}]

        Icons: heart.fill, hand.raised.fill, sparkles, leaf.fill, sun.max.fill, moon.fill, cloud.fill, brain.head.profile, figure.mind.and.body, eyes, ear.fill, bolt.heart.fill, arrow.up.heart.fill, hands.sparkles.fill
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
                slidesError = "I'm here when you're ready to share"
            }
            showLocalAnalysisFallback = false
        } catch {
            // API failed - offer local analysis as fallback
            slidesError = error.localizedDescription
            showLocalAnalysisFallback = true
        }

        isGeneratingSlides = false
    }

    /// Generate slides using on-device analysis (no API required)
    func generateLocalSlides() async {
        isGeneratingSlides = true
        slidesError = nil
        showLocalAnalysisFallback = false

        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayJournals = await dataController.fetchJournalEntries(startDate: todayStart, endDate: Date())

        // Fetch today's extracted patterns
        let patterns = fetchTodayPatterns()

        // Generate slides using local analysis
        todaySlides = localAnalysisService.generateDaySummarySlides(from: todayJournals, patterns: patterns)

        if todaySlides.isEmpty {
            slidesError = "I'm here when you're ready to share"
        }

        isGeneratingSlides = false
    }

    private func fetchTodayPatterns() -> [ExtractedPattern] {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let request: NSFetchRequest<ExtractedPattern> = ExtractedPattern.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            todayStart as NSDate,
            Date() as NSDate
        )

        do {
            return try dataController.container.viewContext.fetch(request)
        } catch {
            return []
        }
    }

    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "gray": return .gray
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "green": return .green
        case "cyan": return .cyan
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .gray
        }
    }

    // MARK: - Life Goals Context for Day Summary

    private func buildLifeGoalsContext() -> String {
        var lines: [String] = []

        // Fetch data from repositories
        let goals = GoalRepository.shared.fetch(includeCompleted: false)
        let struggles = StruggleRepository.shared.fetch(activeOnly: true)
        let wishlistItems = WishlistRepository.shared.fetch(includeAcquired: false)

        // Active goals summary
        if !goals.isEmpty {
            let overdueGoals = goals.filter { $0.isOverdue }
            let dueSoonGoals = goals.filter { $0.isDueSoon }
            let pinnedGoals = goals.filter { $0.isPinned }

            lines.append("Active goals: \(goals.count)")
            if !overdueGoals.isEmpty {
                lines.append("- \(overdueGoals.count) overdue: \(overdueGoals.prefix(2).map { $0.title }.joined(separator: ", "))")
            }
            if !dueSoonGoals.isEmpty {
                lines.append("- \(dueSoonGoals.count) due soon: \(dueSoonGoals.prefix(2).map { $0.title }.joined(separator: ", "))")
            }
            if !pinnedGoals.isEmpty {
                lines.append("- Priority/pinned: \(pinnedGoals.prefix(3).map { $0.title }.joined(separator: ", "))")
            }
        }

        // Current struggles summary
        if !struggles.isEmpty {
            let severeStruggles = struggles.filter { $0.intensityLevel.rawValue >= Struggle.Intensity.severe.rawValue }

            lines.append("\nOngoing struggles: \(struggles.count)")
            if !severeStruggles.isEmpty {
                lines.append("- Severe/overwhelming: \(severeStruggles.prefix(2).map { "\($0.title) (\($0.intensityLevel.displayName))" }.joined(separator: ", "))")
            }
            // List top struggles by intensity
            let topStruggles = struggles.sorted { $0.intensity > $1.intensity }.prefix(3)
            for struggle in topStruggles {
                var line = "- \(struggle.title) [\(struggle.intensityLevel.displayName)]"
                if !struggle.triggersList.isEmpty {
                    line += " triggers: \(struggle.triggersList.prefix(2).joined(separator: ", "))"
                }
                lines.append(line)
            }
        }

        // Wishlist context (for positive reinforcement opportunities)
        if !wishlistItems.isEmpty {
            let highPriority = wishlistItems.filter { $0.priorityLevel == .high }
            lines.append("\nWishlist items: \(wishlistItems.count)")
            if !highPriority.isEmpty {
                lines.append("- High priority wishes: \(highPriority.prefix(2).map { $0.title }.joined(separator: ", "))")
            }
        }

        return lines.joined(separator: "\n")
    }
}

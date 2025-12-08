import SwiftUI
import CoreData
import Combine

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
    private let demoService = DemoModeService.shared
    private let memoriesGenerator = MemoriesGenerator()
    private let daySlidesGenerator = DaySlidesGenerator()
    private var cancellables = Set<AnyCancellable>()

    // Track if we should offer local analysis fallback
    @Published var showLocalAnalysisFallback: Bool = false

    // PERFORMANCE: Cache to avoid redundant queries
    private var lastLoadDate: Date?
    private var memoriesCache: [Memory] = []
    private var recentContextCache: RecentContext?
    private let cacheValidityInterval: TimeInterval = 300 // 5 minutes

    init() {
        observeDemoModeChanges()
    }

    private func observeDemoModeChanges() {
        NotificationCenter.default.publisher(for: .demoModeChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Clear cache so data reloads fresh
                self?.lastLoadDate = nil
                self?.loadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Cached Formatters (Performance Optimization)
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
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
        // Demo mode: load demo data instead
        if demoService.isEnabled {
            loadDemoData()
            return
        }

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
        Task.detached(priority: .utility) { [weak self] in
            await self?.loadHeavyData()
        }
    }

    // MARK: - Demo Mode

    private func loadDemoData() {
        // Demo user name
        userFirstName = demoService.demoUserProfile.name.components(separatedBy: " ").first

        // Demo streak and stats
        currentStreak = demoService.demoStats.streak
        hasTodayEntries = true
        todayEntryCount = demoService.demoStats.thisWeek

        // Demo recent context from most recent journal
        if let recentEntry = demoService.demoJournalEntries.first {
            recentContext = RecentContext(
                icon: "doc.text.fill",
                color: .blue,
                message: recentEntry.analysisSummary ?? "You wrote in your journal",
                timeAgo: Self.relativeDateFormatter.localizedString(for: recentEntry.timestamp, relativeTo: Date()),
                journalPreview: String(recentEntry.content.prefix(100))
            )
        }

        // Demo memories
        memories = [
            Memory(timeframe: "This time last week", description: "Last week, you dealt with sensory overload at the store. You got through it."),
            Memory(timeframe: "You got through it", description: "3 days ago, you felt overwhelmed by masking fatigue — and you made it through."),
            Memory(timeframe: "Around this time", description: "You often experience \"energy dips\" around now")
        ]

        // Demo day slides are loaded via generateAISlides in demo mode
        lastLoadDate = Date()
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

    // MARK: - Memories (now uses MemoriesGenerator)

    private func loadMemories() async {
        // Use cache if valid
        if !memoriesCache.isEmpty {
            memories = memoriesCache
            return
        }

        let calendar = Calendar.current

        // Fetch recent patterns for analysis
        let recentPatterns = await fetchExtractedPatterns(daysBack: 14)
        let lastMonthPatterns = await fetchExtractedPatterns(forDate: calendar.date(byAdding: .month, value: -1, to: Date()))

        // Use generator to create memories
        let foundMemories = memoriesGenerator.generateMemories(
            recentPatterns: recentPatterns,
            lastMonthPatterns: lastMonthPatterns
        )

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

    // MARK: - Today Slides (now uses ExtractedPattern)

    private func loadTodaySlides() {
        Task { [weak self] in
            guard let self else { return }
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

    // MARK: - Generate AI Slides (now uses DaySlidesGenerator)

    func generateAISlides() async {
        isGeneratingSlides = true
        slidesError = nil
        todaySlides = []

        // Demo mode: use preset slides
        if demoService.isEnabled {
            try? await Task.sleep(nanoseconds: 500_000_000) // Brief delay for UI effect
            todaySlides = demoService.demoDaySlides.map { demoSlide in
                DaySummarySlide(
                    icon: demoSlide.icon,
                    color: demoSlide.color,
                    title: demoSlide.title,
                    detail: demoSlide.detail
                )
            }
            isGeneratingSlides = false
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            isGeneratingSlides = false
            return
        }

        // Fetch today's journals
        let todayJournals = await dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)

        guard !todayJournals.isEmpty else {
            isGeneratingSlides = false
            slidesError = "Your day is just beginning. I'll be here."
            return
        }

        // Collect patterns and cascades using generator
        let (patterns, cascades) = daySlidesGenerator.collectPatternsAndCascades(from: todayJournals)

        // Build data summary and prompt using generator
        let dataSummary = daySlidesGenerator.buildDataSummary(patterns: patterns, cascades: cascades, journals: todayJournals)
        let prompt = daySlidesGenerator.buildAISlidesPrompt(dataSummary: dataSummary)

        do {
            let response = try await geminiService.generateContent(prompt: prompt)
            todaySlides = daySlidesGenerator.parseAISlidesResponse(response)

            if todaySlides.isEmpty {
                slidesError = "I'm here when you're ready to share"
            }
            showLocalAnalysisFallback = false
        } catch {
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

}

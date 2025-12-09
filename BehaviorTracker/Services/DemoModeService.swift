import Foundation
import SwiftUI
import Combine

/// Service that provides demo/showcase data when demo mode is enabled.
/// Used to demonstrate app features without revealing personal data.
final class DemoModeService: ObservableObject {
    static let shared = DemoModeService()

    /// Published property that triggers UI updates when demo mode changes
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "isDemoModeEnabled")
            // Post notification so all views can refresh
            NotificationCenter.default.post(name: .demoModeChanged, object: nil)
        }
    }

    private init() {
        // Load initial value from UserDefaults
        self.isEnabled = UserDefaults.standard.bool(forKey: "isDemoModeEnabled")
    }

    // MARK: - Demo User Profile

    var demoUserProfile: (name: String, email: String?) {
        ("User", "user@example.com")
    }

    // MARK: - Demo Journal Entries

    struct DemoJournalEntry {
        let id: UUID
        let title: String?
        let content: String
        let mood: Int16
        let timestamp: Date
        let isFavorite: Bool
        let isAnalyzed: Bool
        let analysisSummary: String?
        let overallIntensity: Int16
    }

    // Helper to safely create demo dates
    private func demoDate(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: date) ?? date
    }

    var demoJournalEntries: [DemoJournalEntry] {
        let now = Date()

        return [
            DemoJournalEntry(
                id: UUID(),
                title: "Morning Reflection",
                content: "Woke up feeling rested today. The new sleep schedule seems to be helping. Had some sensory sensitivity during breakfast - the kitchen lights felt too bright. Used my sunglasses inside which helped. Planning to work on my special interest project this afternoon.",
                mood: 4,
                timestamp: demoDate(byAdding: .hour, value: -2, to: now),
                isFavorite: true,
                isAnalyzed: true,
                analysisSummary: "Good energy with mild sensory sensitivity. Effective coping strategy used.",
                overallIntensity: 3
            ),
            DemoJournalEntry(
                id: UUID(),
                title: "Afternoon Update",
                content: "Had a video call that went longer than expected. Feeling drained from the social interaction. Need some quiet time to recharge. The masking was intense today - kept having to remind myself to make eye contact and respond at appropriate times.",
                mood: 2,
                timestamp: demoDate(byAdding: .hour, value: -5, to: now),
                isFavorite: false,
                isAnalyzed: true,
                analysisSummary: "Social fatigue from extended interaction. Masking took significant energy.",
                overallIntensity: 6
            ),
            DemoJournalEntry(
                id: UUID(),
                title: nil,
                content: "Spent 3 hours working on my coding project. Lost track of time completely - hyperfocus kicked in. Forgot to eat lunch but feeling accomplished. Need to set better reminders for meals when I'm in the zone.",
                mood: 5,
                timestamp: demoDate(byAdding: .day, value: -1, to: now),
                isFavorite: true,
                isAnalyzed: true,
                analysisSummary: "Productive hyperfocus session. Self-care reminder needed for meals.",
                overallIntensity: 4
            ),
            DemoJournalEntry(
                id: UUID(),
                title: "Difficult Day",
                content: "Everything felt overwhelming today. Too many unexpected changes to my routine. The construction noise outside made it impossible to focus. Had to use my noise-canceling headphones all day. Feeling exhausted but managed to get through.",
                mood: 1,
                timestamp: demoDate(byAdding: .day, value: -2, to: now),
                isFavorite: false,
                isAnalyzed: true,
                analysisSummary: "Sensory overload from environmental factors. Routine disruption increased stress.",
                overallIntensity: 8
            ),
            DemoJournalEntry(
                id: UUID(),
                title: "Weekend Plans",
                content: "Looking forward to a quiet weekend. Planning to visit the bookstore during off-peak hours to avoid crowds. Also want to try that new recipe I found - it has very specific steps which I like.",
                mood: 4,
                timestamp: demoDate(byAdding: .day, value: -3, to: now),
                isFavorite: false,
                isAnalyzed: true,
                analysisSummary: "Positive anticipation with sensory-aware planning.",
                overallIntensity: 2
            )
        ]
    }

    // MARK: - Demo Pattern Entries

    struct DemoPatternEntry {
        let id: UUID
        let patternType: String
        let category: String
        let intensity: Int16
        let duration: Int32
        let timestamp: Date
        let contextNotes: String?
    }

    var demoPatternEntries: [DemoPatternEntry] {
        let now = Date()

        return [
            DemoPatternEntry(
                id: UUID(),
                patternType: "Sensory State",
                category: "Sensory",
                intensity: 4,
                duration: 45,
                timestamp: demoDate(byAdding: .hour, value: -3, to: now),
                contextNotes: "Bright lights and loud environment at the store"
            ),
            DemoPatternEntry(
                id: UUID(),
                patternType: "Masking",
                category: "Social",
                intensity: 5,
                duration: 120,
                timestamp: demoDate(byAdding: .hour, value: -6, to: now),
                contextNotes: "Long meeting with unfamiliar people"
            ),
            DemoPatternEntry(
                id: UUID(),
                patternType: "Focus",
                category: "Executive Function",
                intensity: 5,
                duration: 180,
                timestamp: demoDate(byAdding: .day, value: -1, to: now),
                contextNotes: "Working on special interest project"
            ),
            DemoPatternEntry(
                id: UUID(),
                patternType: "Routine/Change",
                category: "Body & Routine",
                intensity: 4,
                duration: 0,
                timestamp: demoDate(byAdding: .day, value: -1, to: now),
                contextNotes: "Unexpected schedule change"
            ),
            DemoPatternEntry(
                id: UUID(),
                patternType: "Stimming",
                category: "Regulation",
                intensity: 4,
                duration: 30,
                timestamp: demoDate(byAdding: .day, value: -2, to: now),
                contextNotes: "Self-regulation during stressful moment"
            ),
            DemoPatternEntry(
                id: UUID(),
                patternType: "Social Recovery",
                category: "Social",
                intensity: 3,
                duration: 60,
                timestamp: demoDate(byAdding: .day, value: -2, to: now),
                contextNotes: "Needed alone time after family gathering"
            )
        ]
    }

    // MARK: - Demo Medications

    struct DemoMedication {
        let id: UUID
        let name: String
        let dosage: String?
        let frequency: String
        let takenToday: Bool
    }

    var demoMedications: [DemoMedication] {
        [
            DemoMedication(id: UUID(), name: "Vitamin D", dosage: "2000 IU", frequency: "Daily", takenToday: true),
            DemoMedication(id: UUID(), name: "Magnesium", dosage: "400mg", frequency: "Daily", takenToday: true),
            DemoMedication(id: UUID(), name: "Omega-3", dosage: "1000mg", frequency: "Daily", takenToday: false),
            DemoMedication(id: UUID(), name: "B-Complex", dosage: nil, frequency: "Daily", takenToday: true)
        ]
    }

    // MARK: - Demo Goals & Struggles

    struct DemoGoal {
        let id: UUID
        let title: String
        let priority: String
        let isCompleted: Bool
        let dueDate: Date?
    }

    var demoGoals: [DemoGoal] {
        let calendar = Calendar.current
        let now = Date()

        return [
            DemoGoal(id: UUID(), title: "Establish morning routine", priority: "high", isCompleted: false, dueDate: calendar.date(byAdding: .day, value: 7, to: now)),
            DemoGoal(id: UUID(), title: "Practice social scripts for work meetings", priority: "medium", isCompleted: false, dueDate: nil),
            DemoGoal(id: UUID(), title: "Create sensory-friendly workspace", priority: "high", isCompleted: true, dueDate: nil),
            DemoGoal(id: UUID(), title: "Learn 3 new coping strategies", priority: "medium", isCompleted: false, dueDate: calendar.date(byAdding: .month, value: 1, to: now))
        ]
    }

    // MARK: - Demo Statistics

    var demoStats: (streak: Int, totalEntries: Int, thisWeek: Int) {
        (streak: 12, totalEntries: 47, thisWeek: 8)
    }

    // MARK: - Demo Day Summary Slides

    struct DemoDaySlide {
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }

    var demoDaySlides: [DemoDaySlide] {
        [
            DemoDaySlide(
                icon: "sun.max.fill",
                color: .orange,
                title: "Morning Energy",
                detail: "I noticed you started the day with good energy. The rest helped."
            ),
            DemoDaySlide(
                icon: "person.2.fill",
                color: .blue,
                title: "Social Battery",
                detail: "That meeting took a lot out of you. The masking was real today."
            ),
            DemoDaySlide(
                icon: "sparkles",
                color: .purple,
                title: "Hyperfocus Win",
                detail: "You got into the zone with your project. Remember to set meal reminders."
            )
        ]
    }

    // MARK: - Demo Health Data

    var demoHealthData: (heartRate: Int, steps: Int, sleep: Double) {
        (heartRate: 72, steps: 6543, sleep: 7.5)
    }

    // MARK: - Demo Calendar Data

    struct DemoCalendarDay {
        let date: Date
        let journalCount: Int
        let patternCount: Int
        let medicationCount: Int
        let dominantCategory: String?
        let averageIntensity: Double?
    }

    /// Generate demo calendar data for the current month with some entries scattered across days
    var demoCalendarDays: [DemoCalendarDay] {
        let calendar = Calendar.current
        let now = Date()

        // Get dates from the past 30 days with various activity levels
        var days: [DemoCalendarDay] = []

        // Today - active day
        days.append(DemoCalendarDay(
            date: now,
            journalCount: 2,
            patternCount: 3,
            medicationCount: 4,
            dominantCategory: "Sensory",
            averageIntensity: 4.5
        ))

        // Yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
            days.append(DemoCalendarDay(
                date: yesterday,
                journalCount: 1,
                patternCount: 2,
                medicationCount: 4,
                dominantCategory: "Social",
                averageIntensity: 6.0
            ))
        }

        // 2 days ago
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) {
            days.append(DemoCalendarDay(
                date: twoDaysAgo,
                journalCount: 1,
                patternCount: 2,
                medicationCount: 3,
                dominantCategory: "Energy & Capacity",
                averageIntensity: 7.5
            ))
        }

        // 3 days ago
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now) {
            days.append(DemoCalendarDay(
                date: threeDaysAgo,
                journalCount: 1,
                patternCount: 1,
                medicationCount: 4,
                dominantCategory: "Executive Function",
                averageIntensity: 3.0
            ))
        }

        // 5 days ago
        if let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now) {
            days.append(DemoCalendarDay(
                date: fiveDaysAgo,
                journalCount: 2,
                patternCount: 4,
                medicationCount: 4,
                dominantCategory: "Sensory",
                averageIntensity: 5.5
            ))
        }

        // 7 days ago
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
            days.append(DemoCalendarDay(
                date: weekAgo,
                journalCount: 1,
                patternCount: 2,
                medicationCount: 4,
                dominantCategory: "Body & Routine",
                averageIntensity: 4.0
            ))
        }

        // 10 days ago
        if let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: now) {
            days.append(DemoCalendarDay(
                date: tenDaysAgo,
                journalCount: 3,
                patternCount: 5,
                medicationCount: 4,
                dominantCategory: "Social",
                averageIntensity: 6.5
            ))
        }

        // 14 days ago
        if let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) {
            days.append(DemoCalendarDay(
                date: twoWeeksAgo,
                journalCount: 1,
                patternCount: 3,
                medicationCount: 3,
                dominantCategory: "Demands & Autonomy",
                averageIntensity: 7.0
            ))
        }

        return days
    }

    /// Get demo calendar data as a dictionary keyed by date (start of day)
    var demoCalendarDataByDate: [Date: DemoCalendarDay] {
        let calendar = Calendar.current
        var result: [Date: DemoCalendarDay] = [:]
        for day in demoCalendarDays {
            let startOfDay = calendar.startOfDay(for: day.date)
            result[startOfDay] = day
        }
        return result
    }

    // MARK: - Demo Extracted Patterns (for Patterns Tab)

    struct DemoExtractedPattern: Identifiable {
        let id: UUID
        let patternType: String
        let category: String
        let intensity: Int16
        let triggers: [String]
        let timeOfDay: String?
        let copingStrategies: [String]
        let details: String?
        let confidence: Double
        let timestamp: Date
    }

    struct DemoPatternCascade: Identifiable {
        let id: UUID
        let fromPattern: String
        let toPattern: String
        let confidence: Double
        let description: String
    }

    var demoExtractedPatterns: [DemoExtractedPattern] {
        let now = Date()

        return [
            DemoExtractedPattern(
                id: UUID(),
                patternType: "Sensory State",
                category: "Sensory",
                intensity: 4,
                triggers: ["Bright lights", "Loud environment"],
                timeOfDay: "Morning",
                copingStrategies: ["Used sunglasses", "Found quiet space"],
                details: "Kitchen lights felt too bright during breakfast",
                confidence: 0.85,
                timestamp: demoDate(byAdding: .hour, value: -3, to: now)
            ),
            DemoExtractedPattern(
                id: UUID(),
                patternType: "Masking",
                category: "Social",
                intensity: 5,
                triggers: ["Extended social interaction", "Video call"],
                timeOfDay: "Afternoon",
                copingStrategies: ["Scheduled recovery time"],
                details: "Video call went longer than expected, intense masking required",
                confidence: 0.92,
                timestamp: demoDate(byAdding: .hour, value: -5, to: now)
            ),
            DemoExtractedPattern(
                id: UUID(),
                patternType: "Focus",
                category: "Executive Function",
                intensity: 5,
                triggers: ["Special interest project"],
                timeOfDay: "Afternoon",
                copingStrategies: [],
                details: "Lost track of time working on coding project",
                confidence: 0.88,
                timestamp: demoDate(byAdding: .hour, value: -6, to: now)
            ),
            DemoExtractedPattern(
                id: UUID(),
                patternType: "Energy Level",
                category: "Energy & Capacity",
                intensity: 2,
                triggers: ["Post-social fatigue", "Missed lunch"],
                timeOfDay: "Afternoon",
                copingStrategies: ["Rest", "Snack break"],
                details: "Feeling drained after social interaction",
                confidence: 0.80,
                timestamp: demoDate(byAdding: .hour, value: -4, to: now)
            )
        ]
    }

    var demoPatternCascades: [DemoPatternCascade] {
        [
            DemoPatternCascade(
                id: UUID(),
                fromPattern: "Sensory State",
                toPattern: "Energy Level",
                confidence: 0.78,
                description: "Sensory processing took energy reserves"
            ),
            DemoPatternCascade(
                id: UUID(),
                fromPattern: "Masking",
                toPattern: "Energy Level",
                confidence: 0.85,
                description: "Social masking depleted energy"
            )
        ]
    }

    var demoDailySummary: String {
        "Today you experienced sensory challenges in the morning but managed them well with coping strategies. The afternoon video call required significant masking energy. You found productive flow during your special interest project. Consider scheduling more recovery time after social interactions."
    }

    var demoDominantPatterns: [String] {
        ["Masking Fatigue", "Sensory Overload", "Hyperfocus Episode"]
    }

    // MARK: - Demo Reports Data

    // swiftlint:disable:next large_tuple
    var demoWeeklyReport: (
        totalEntries: Int,
        totalPatterns: Int,
        mostActiveDay: String,
        averagePerDay: Double,
        patternFrequency: [(key: String, value: Int)],
        categoryBreakdown: [String: Int],
        commonTriggers: [String],
        topCascades: [(from: String, to: String, count: Int)]
    ) {
        (
            totalEntries: 12,
            totalPatterns: 28,
            mostActiveDay: "Wednesday",
            averagePerDay: 4.0,
            patternFrequency: [
                (key: "Sensory Overload", value: 8),
                (key: "Masking Fatigue", value: 6),
                (key: "Hyperfocus Episode", value: 5),
                (key: "Energy Dip", value: 4),
                (key: "Routine Disruption", value: 3),
                (key: "Stimming", value: 2)
            ],
            categoryBreakdown: [
                "Sensory": 10,
                "Social": 8,
                "Executive Function": 5,
                "Energy & Capacity": 4,
                "Body & Routine": 1
            ],
            commonTriggers: [
                "Bright lights",
                "Loud environments",
                "Unexpected changes",
                "Social interactions",
                "Time pressure"
            ],
            topCascades: [
                (from: "Sensory Overload", to: "Energy Dip", count: 5),
                (from: "Masking Fatigue", to: "Need for Recovery", count: 4),
                (from: "Routine Disruption", to: "Anxiety Spike", count: 3)
            ]
        )
    }

    // swiftlint:disable:next large_tuple
    var demoMonthlyReport: (
        totalEntries: Int,
        totalPatterns: Int,
        mostActiveWeek: String,
        averagePerDay: Double,
        topPatterns: [(key: String, value: Int)],
        correlations: [String],
        bestDays: [String],
        challengingDays: [String]
    ) {
        (
            totalEntries: 47,
            totalPatterns: 112,
            mostActiveWeek: "Week 2",
            averagePerDay: 3.7,
            topPatterns: [
                (key: "Sensory Overload", value: 32),
                (key: "Masking Fatigue", value: 24),
                (key: "Hyperfocus Episode", value: 18),
                (key: "Energy Dip", value: 15),
                (key: "Social Recovery", value: 12),
                (key: "Routine Disruption", value: 11)
            ],
            correlations: [
                "Sensory overload tends to occur more in mornings",
                "Masking fatigue highest on meeting days",
                "Better sleep correlates with fewer energy dips",
                "Hyperfocus episodes more common on weekends"
            ],
            bestDays: ["Saturday", "Sunday"],
            challengingDays: ["Tuesday", "Wednesday"]
        )
    }

    // MARK: - Demo AI Insights

    var demoAIInsights: [String] {
        [
            "Your sensory sensitivity peaks in the morning hours. Consider a gradual wake-up routine with dimmed lights.",
            "Social interactions on video calls are particularly draining. Schedule recovery time immediately after.",
            "You show a strong pattern of hyperfocus during special interest activities. Use this productively but set meal reminders.",
            "Routine disruptions significantly impact your regulation. Visual schedules may help with transitions.",
            "Your coping strategies are effective - sunglasses and quiet spaces reduce overload episodes by 40%."
        ]
    }

    // MARK: - Demo Correlation Insights

    struct DemoCorrelation {
        let title: String
        let description: String
        let strength: Double // 0-1
        let icon: String
        let color: String
    }

    var demoCorrelations: [DemoCorrelation] {
        [
            DemoCorrelation(
                title: "Sleep & Sensory Sensitivity",
                description: "Poor sleep nights are followed by 60% more sensory overload episodes",
                strength: 0.75,
                icon: "bed.double.fill",
                color: "purple"
            ),
            DemoCorrelation(
                title: "Social Events & Recovery Need",
                description: "Social events longer than 2 hours require 3+ hours of recovery time",
                strength: 0.82,
                icon: "person.2.fill",
                color: "blue"
            ),
            DemoCorrelation(
                title: "Routine Consistency & Mood",
                description: "Days with consistent routines show 45% better mood scores",
                strength: 0.68,
                icon: "calendar.badge.clock",
                color: "green"
            ),
            DemoCorrelation(
                title: "Exercise & Energy Regulation",
                description: "Light morning exercise reduces afternoon energy dips by 35%",
                strength: 0.58,
                icon: "figure.walk",
                color: "orange"
            )
        ]
    }

    // MARK: - Demo Category Distribution

    var demoCategoryDistribution: [(category: String, percentage: Double, count: Int)] {
        [
            (category: "Sensory", percentage: 35.7, count: 40),
            (category: "Social", percentage: 25.0, count: 28),
            (category: "Executive Function", percentage: 16.1, count: 18),
            (category: "Energy & Capacity", percentage: 13.4, count: 15),
            (category: "Body & Routine", percentage: 9.8, count: 11)
        ]
    }

    // MARK: - Demo Life Goals Section (for Home Tab)

    struct DemoLifeGoal: Identifiable {
        let id: UUID
        let title: String
        let priority: String
        let progress: Double // 0-1
        let dueDate: Date?
    }

    struct DemoStruggle: Identifiable {
        let id: UUID
        let title: String
        let intensity: String
        let triggers: [String]
    }

    struct DemoWishlistItem: Identifiable {
        let id: UUID
        let title: String
        let category: String
        let isAcquired: Bool
    }

    var demoLifeGoals: [DemoLifeGoal] {
        let calendar = Calendar.current
        let now = Date()

        return [
            DemoLifeGoal(
                id: UUID(),
                title: "Establish consistent morning routine",
                priority: "high",
                progress: 0.6,
                dueDate: calendar.date(byAdding: .day, value: 14, to: now)
            ),
            DemoLifeGoal(
                id: UUID(),
                title: "Practice social scripts for meetings",
                priority: "medium",
                progress: 0.3,
                dueDate: nil
            ),
            DemoLifeGoal(
                id: UUID(),
                title: "Create sensory-friendly workspace",
                priority: "high",
                progress: 0.8,
                dueDate: calendar.date(byAdding: .day, value: 7, to: now)
            ),
            DemoLifeGoal(
                id: UUID(),
                title: "Learn 3 new coping strategies",
                priority: "medium",
                progress: 0.5,
                dueDate: calendar.date(byAdding: .month, value: 1, to: now)
            )
        ]
    }

    var demoLifeStruggles: [DemoStruggle] {
        [
            DemoStruggle(
                id: UUID(),
                title: "Transitioning between tasks",
                intensity: "Moderate",
                triggers: ["Unexpected changes", "Time pressure", "Interruptions"]
            ),
            DemoStruggle(
                id: UUID(),
                title: "Sensory sensitivity in public",
                intensity: "Significant",
                triggers: ["Loud noises", "Bright lights", "Crowds", "Strong smells"]
            ),
            DemoStruggle(
                id: UUID(),
                title: "Executive function challenges",
                intensity: "Moderate",
                triggers: ["Multiple deadlines", "Complex instructions", "Decision fatigue"]
            )
        ]
    }

    var demoWishlistItems: [DemoWishlistItem] {
        [
            DemoWishlistItem(
                id: UUID(),
                title: "Noise-canceling headphones",
                category: "Sensory Tools",
                isAcquired: true
            ),
            DemoWishlistItem(
                id: UUID(),
                title: "Weighted blanket",
                category: "Comfort Items",
                isAcquired: false
            ),
            DemoWishlistItem(
                id: UUID(),
                title: "Visual timer",
                category: "Organization",
                isAcquired: false
            ),
            DemoWishlistItem(
                id: UUID(),
                title: "Fidget tools set",
                category: "Regulation",
                isAcquired: true
            )
        ]
    }

    // MARK: - Demo Life Goals Summary (for Reports)

    // swiftlint:disable:next large_tuple
    var demoLifeGoalsSummary: (
        activeGoals: Int,
        completedGoals: Int,
        overdueGoals: Int,
        activeStruggles: Int,
        resolvedStruggles: Int,
        wishlistPending: Int,
        wishlistAcquired: Int
    ) {
        (
            activeGoals: 4,
            completedGoals: 2,
            overdueGoals: 0,
            activeStruggles: 3,
            resolvedStruggles: 1,
            wishlistPending: 2,
            wishlistAcquired: 2
        )
    }

    // MARK: - Demo Chat Messages

    struct DemoChatMessage: Identifiable {
        let id: UUID
        let content: String
        let isUser: Bool
        let timestamp: Date
    }

    var demoChatMessages: [DemoChatMessage] {
        let now = Date()

        return [
            DemoChatMessage(
                id: UUID(),
                content: "I've been feeling overwhelmed lately. Can you help me understand my patterns?",
                isUser: true,
                timestamp: demoDate(byAdding: .minute, value: -10, to: now)
            ),
            DemoChatMessage(
                id: UUID(),
                content: "Based on your recent entries, I notice you've been experiencing more sensory overload in the mornings. This often happens after nights with less than 7 hours of sleep. You've also had several back-to-back social commitments this week, which tends to deplete your energy reserves.\n\nA few suggestions:\n1. Try a gradual wake-up routine with dimmed lights\n2. Schedule buffer time between social events\n3. Use your noise-canceling headphones during commutes",
                isUser: false,
                timestamp: demoDate(byAdding: .minute, value: -9, to: now)
            ),
            DemoChatMessage(
                id: UUID(),
                content: "That makes sense. What about my hyperfocus sessions?",
                isUser: true,
                timestamp: demoDate(byAdding: .minute, value: -5, to: now)
            ),
            DemoChatMessage(
                id: UUID(),
                content: "Your hyperfocus is actually one of your strengths! You've logged several productive 3+ hour sessions on your coding projects. The pattern I see is that these work best in the afternoon when you're in a quiet environment.\n\nJust remember to set reminders for meals and breaks - you've mentioned forgetting to eat during these sessions.",
                isUser: false,
                timestamp: demoDate(byAdding: .minute, value: -4, to: now)
            )
        ]
    }

    // MARK: - Demo Personal Knowledge (Teach AI About Me)

    struct DemoPersonalKnowledge: Identifiable {
        let id: UUID
        let title: String?
        let content: String
        let isActive: Bool
    }

    var demoPersonalKnowledge: [DemoPersonalKnowledge] {
        [
            DemoPersonalKnowledge(
                id: UUID(),
                title: "Sensory sensitivities",
                content: "Bright fluorescent lights and loud sudden noises are overwhelming. I cope better with natural light and background white noise.",
                isActive: true
            ),
            DemoPersonalKnowledge(
                id: UUID(),
                title: "Social energy",
                content: "Video calls are more draining than in-person meetings. I need at least 30 minutes of alone time after any social interaction longer than an hour.",
                isActive: true
            ),
            DemoPersonalKnowledge(
                id: UUID(),
                title: "Best work times",
                content: "I'm most productive between 2-6pm. Mornings are for low-demand tasks while I warm up.",
                isActive: true
            ),
            DemoPersonalKnowledge(
                id: UUID(),
                title: "Food preferences",
                content: "I prefer foods with consistent textures. Mixed textures can be difficult.",
                isActive: true
            ),
            DemoPersonalKnowledge(
                id: UUID(),
                title: "Special interests",
                content: "Coding, especially iOS development. Also interested in astronomy and mechanical keyboards.",
                isActive: true
            )
        ]
    }

    /// Combined context string for demo AI prompts (mirrors PersonalKnowledgeRepository.getCombinedContext())
    var demoPersonalKnowledgeContext: String {
        demoPersonalKnowledge
            .filter { $0.isActive }
            .map { item in
                if let title = item.title {
                    return "- \(title): \(item.content)"
                }
                return "- \(item.content)"
            }
            .joined(separator: "\n")
    }
}

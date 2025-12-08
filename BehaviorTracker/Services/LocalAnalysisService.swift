import Foundation
import NaturalLanguage

/// On-device pattern analysis using Apple's Natural Language framework
/// Used as fallback when Gemini API is unavailable
class LocalAnalysisService {
    static let shared = LocalAnalysisService()

    private let tagger: NLTagger

    private init() {
        // Configure tagger for various analyses including sentiment
        tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .sentimentScore])
    }

    // MARK: - ASD-Specific Keywords

    private let sensoryKeywords = [
        "loud", "noise", "bright", "light", "texture", "smell", "taste", "touch",
        "overwhelming", "overstimulated", "sensitive", "buzzing", "humming",
        "scratchy", "itchy", "uncomfortable", "headphones", "sunglasses", "earplugs"
    ]

    private let emotionalKeywords = [
        "anxious", "anxiety", "stressed", "worried", "overwhelmed", "frustrated",
        "angry", "sad", "happy", "calm", "peaceful", "excited", "scared", "fear",
        "panic", "meltdown", "shutdown", "crying", "tears", "upset"
    ]

    private let socialKeywords = [
        "people", "crowd", "social", "conversation", "talking", "meeting",
        "party", "gathering", "alone", "isolated", "lonely", "friends", "family",
        "coworker", "stranger", "eye contact", "small talk", "exhausting"
    ]

    private let routineKeywords = [
        "routine", "schedule", "change", "unexpected", "surprise", "plan",
        "disruption", "different", "new", "transition", "switch", "adjustment"
    ]

    private let energyKeywords = [
        "tired", "exhausted", "fatigue", "energy", "drained", "burnout",
        "rested", "refreshed", "sleep", "nap", "awake", "alert", "sluggish"
    ]

    private let focusKeywords = [
        "focus", "concentrate", "distracted", "hyperfocus", "special interest",
        "obsessed", "absorbed", "lost track", "flow", "productive", "scattered"
    ]

    private let copingKeywords = [
        "stim", "stimming", "rocking", "flapping", "pacing", "fidget",
        "headphones", "quiet", "break", "escape", "hide", "retreat", "recharge"
    ]

    private let positiveKeywords = [
        "good", "great", "happy", "calm", "peaceful", "relaxed", "enjoyed",
        "fun", "comfortable", "safe", "proud", "accomplished", "connected"
    ]

    private let negativeKeywords = [
        "bad", "terrible", "awful", "horrible", "worst", "hate", "can't",
        "struggling", "difficult", "hard", "impossible", "failing"
    ]

    // MARK: - Main Analysis

    struct LocalAnalysisResult {
        let sentiment: Sentiment
        let intensity: Int // 1-10
        let categories: [PatternCategory]
        let insights: [Insight]
        let summary: String
    }

    enum Sentiment: String {
        case positive
        case negative
        case neutral
        case mixed
    }

    struct PatternCategory {
        let name: String
        let confidence: Double // 0-1
        let keywords: [String]
    }

    struct Insight {
        let icon: String
        let colorName: String
        let title: String
        let message: String
    }

    func analyze(text: String) -> LocalAnalysisResult {
        let lowercaseText = text.lowercased()
        let words = tokenize(text: lowercaseText)

        // Analyze sentiment
        let sentiment = analyzeSentiment(text: text)

        // Detect pattern categories
        let categories = detectCategories(words: words, text: lowercaseText)

        // Calculate intensity
        let intensity = calculateIntensity(text: lowercaseText, sentiment: sentiment, categories: categories)

        // Generate insights
        let insights = generateInsights(
            sentiment: sentiment,
            categories: categories,
            intensity: intensity,
            text: lowercaseText
        )

        // Generate summary
        let summary = generateSummary(sentiment: sentiment, categories: categories, intensity: intensity)

        return LocalAnalysisResult(
            sentiment: sentiment,
            intensity: intensity,
            categories: categories,
            insights: insights,
            summary: summary
        )
    }

    // MARK: - Tokenization

    private func tokenize(text: String) -> [String] {
        var words: [String] = []
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            words.append(String(text[range]))
            return true
        }

        return words
    }

    // MARK: - Sentiment Analysis

    private func analyzeSentiment(text: String) -> Sentiment {
        tagger.string = text

        var positiveCount = 0
        var negativeCount = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let tag = tag {
                let score = Double(tag.rawValue) ?? 0
                if score > 0.1 {
                    positiveCount += 1
                } else if score < -0.1 {
                    negativeCount += 1
                }
            }
            return true
        }

        // Also check keywords
        let lowercased = text.lowercased()
        for word in positiveKeywords where lowercased.contains(word) {
            positiveCount += 1
        }
        for word in negativeKeywords where lowercased.contains(word) {
            negativeCount += 1
        }

        if positiveCount > negativeCount * 2 {
            return .positive
        } else if negativeCount > positiveCount * 2 {
            return .negative
        } else if positiveCount > 0 && negativeCount > 0 {
            return .mixed
        } else {
            return .neutral
        }
    }

    // MARK: - Category Detection

    private func detectCategories(words: [String], text: String) -> [PatternCategory] {
        var categories: [PatternCategory] = []

        let categoryChecks: [(name: String, keywords: [String], icon: String)] = [
            ("Sensory", sensoryKeywords, "hand.raised.fingers.spread.fill"),
            ("Emotional", emotionalKeywords, "heart.fill"),
            ("Social", socialKeywords, "person.2.fill"),
            ("Routine", routineKeywords, "calendar"),
            ("Energy", energyKeywords, "bolt.fill"),
            ("Focus", focusKeywords, "brain.head.profile"),
            ("Coping", copingKeywords, "hands.sparkles.fill")
        ]

        for check in categoryChecks {
            let matches = check.keywords.filter { text.contains($0) }
            if !matches.isEmpty {
                let confidence = min(1.0, Double(matches.count) / 3.0)
                categories.append(PatternCategory(
                    name: check.name,
                    confidence: confidence,
                    keywords: matches
                ))
            }
        }

        // Sort by confidence
        return categories.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Intensity Calculation

    private func calculateIntensity(text: String, sentiment: Sentiment, categories: [PatternCategory]) -> Int {
        var intensity = 5 // Base intensity

        // Intensity modifiers based on language
        let intensifiers = ["very", "extremely", "so", "really", "completely", "totally", "absolutely"]
        let deintensifiers = ["slightly", "a bit", "somewhat", "kind of", "a little"]

        for word in intensifiers where text.contains(word) {
            intensity += 1
        }
        for word in deintensifiers where text.contains(word) {
            intensity -= 1
        }

        // Negative sentiment tends to be more intense
        if sentiment == .negative {
            intensity += 1
        }

        // Multiple categories suggest more complex situation
        if categories.count >= 3 {
            intensity += 1
        }

        // Check for crisis keywords
        let crisisKeywords = ["meltdown", "shutdown", "can't cope", "breaking down", "panic"]
        for keyword in crisisKeywords where text.contains(keyword) {
            intensity += 2
        }

        return max(1, min(10, intensity))
    }

    // MARK: - Insight Generation

    private func generateInsights(sentiment: Sentiment, categories: [PatternCategory], intensity: Int, text: String) -> [Insight] {
        var insights: [Insight] = []

        // Primary category insight
        if let primary = categories.first {
            let insight = generateCategoryInsight(category: primary, text: text)
            insights.append(insight)
        }

        // Sentiment insight
        let sentimentInsight = generateSentimentInsight(sentiment: sentiment, intensity: intensity)
        insights.append(sentimentInsight)

        // Secondary pattern if exists
        if categories.count >= 2 {
            let secondary = categories[1]
            if secondary.confidence > 0.3 {
                let connectionInsight = generateConnectionInsight(primary: categories[0], secondary: secondary)
                insights.append(connectionInsight)
            }
        }

        // Coping recognition
        if categories.contains(where: { $0.name == "Coping" }) {
            insights.append(Insight(
                icon: "hands.sparkles.fill",
                colorName: "green",
                title: "Self-care noticed",
                message: "You're using coping strategies. That's self-awareness in action."
            ))
        }

        return Array(insights.prefix(4))
    }

    private func generateCategoryInsight(category: PatternCategory, text: String) -> Insight {
        switch category.name {
        case "Sensory":
            return Insight(
                icon: "hand.raised.fingers.spread.fill",
                colorName: "purple",
                title: "Sensory experience",
                message: "Your environment seems to be affecting you. \(category.keywords.first.map { "Noticing '\($0)' sensations." } ?? "Your senses are picking up a lot.")"
            )
        case "Emotional":
            return Insight(
                icon: "heart.fill",
                colorName: "pink",
                title: "Emotions present",
                message: "You're experiencing strong feelings. \(category.keywords.first.map { "'\($0.capitalized)' is what I'm sensing." } ?? "That's valid.")"
            )
        case "Social":
            return Insight(
                icon: "person.2.fill",
                colorName: "blue",
                title: "Social dynamics",
                message: "Social situations are on your mind. Those can take extra energy to navigate."
            )
        case "Routine":
            return Insight(
                icon: "calendar",
                colorName: "orange",
                title: "Routine matters",
                message: "Changes or structure seem important right now. Predictability helps."
            )
        case "Energy":
            return Insight(
                icon: "bolt.fill",
                colorName: "yellow",
                title: "Energy levels",
                message: "Your body is telling you something about its energy needs."
            )
        case "Focus":
            return Insight(
                icon: "brain.head.profile",
                colorName: "cyan",
                title: "Focus patterns",
                message: "Your attention and focus are part of today's experience."
            )
        default:
            return Insight(
                icon: "sparkles",
                colorName: "gray",
                title: "Patterns noticed",
                message: "I'm tracking what you're sharing. Every detail matters."
            )
        }
    }

    private func generateSentimentInsight(sentiment: Sentiment, intensity: Int) -> Insight {
        switch sentiment {
        case .positive:
            return Insight(
                icon: "sun.max.fill",
                colorName: "yellow",
                title: "Positive moment",
                message: intensity > 6 ? "This feels like a genuinely good moment. Worth remembering." : "Some positive notes in your day."
            )
        case .negative:
            return Insight(
                icon: "cloud.fill",
                colorName: "gray",
                title: "Difficult time",
                message: intensity > 7 ? "This sounds really hard. You're doing your best." : "There's some heaviness here. That's okay."
            )
        case .mixed:
            return Insight(
                icon: "cloud.sun.fill",
                colorName: "orange",
                title: "Mixed feelings",
                message: "You're holding multiple feelings at once. That's complex but real."
            )
        case .neutral:
            return Insight(
                icon: "minus.circle.fill",
                colorName: "gray",
                title: "Steady state",
                message: "Things seem relatively neutral. Sometimes that's exactly right."
            )
        }
    }

    private func generateConnectionInsight(primary: PatternCategory, secondary: PatternCategory) -> Insight {
        return Insight(
            icon: "arrow.triangle.2.circlepath",
            colorName: "purple",
            title: "Pattern connection",
            message: "\(primary.name) and \(secondary.name) often go together. I see this pattern."
        )
    }

    // MARK: - Summary Generation

    private func generateSummary(sentiment: Sentiment, categories: [PatternCategory], intensity: Int) -> String {
        let categoryNames = categories.prefix(2).map { $0.name }.joined(separator: " and ")

        var summary = ""

        switch sentiment {
        case .positive:
            summary = "A generally positive entry"
        case .negative:
            summary = "Some challenges present"
        case .mixed:
            summary = "A mix of experiences"
        case .neutral:
            summary = "A reflective entry"
        }

        if !categoryNames.isEmpty {
            summary += " touching on \(categoryNames.lowercased())"
        }

        if intensity >= 7 {
            summary += ". Intensity is high."
        } else if intensity <= 3 {
            summary += ". Relatively mild."
        }

        return summary
    }

    // MARK: - Day Summary Generation (for Home View)

    func generateDaySummarySlides(from journals: [JournalEntry], patterns: [ExtractedPattern]) -> [DaySummarySlide] {
        var slides: [DaySummarySlide] = []

        // Combine all journal text
        let combinedText = journals.map { $0.content }.joined(separator: " ")

        if combinedText.isEmpty {
            return [DaySummarySlide(
                icon: "sun.max.fill",
                color: .orange,
                title: "New day",
                detail: "When you're ready, I'm here to listen."
            )]
        }

        // Analyze combined text
        let analysis = analyze(text: combinedText)

        // Convert insights to slides
        for insight in analysis.insights {
            slides.append(DaySummarySlide(
                icon: insight.icon,
                color: Color.fromName(insight.colorName),
                title: insight.title,
                detail: insight.message
            ))
        }

        // Add pattern-based insights if available
        if !patterns.isEmpty {
            let patternTypes = Set(patterns.map { $0.patternType })
            if patternTypes.count >= 2 {
                slides.append(DaySummarySlide(
                    icon: "chart.dots.scatter",
                    color: .cyan,
                    title: "Patterns tracked",
                    detail: "Noticed \(patternTypes.count) different patterns today. Building your picture."
                ))
            }
        }

        return Array(slides.prefix(4))
    }

}

// Need to import SwiftUI for Color
import SwiftUI

// MARK: - Types for AIInsightsView Integration

/// Insight type categories for AI Insights tab
enum LocalInsightType: String {
    case statistic
    case pattern
    case time
    case warning
    case factor
    case category
    case mood
    case trend
    case streak
    case medication
    case adherence
    case effectiveness
    case correlation
    case trigger
    case coping
    case cascade
    case suggestion
    case positive
}

/// Trend direction for insights
enum LocalInsightTrend {
    case positive
    case negative
    case neutral
}

/// Individual insight item
struct LocalInsightItem: Identifiable {
    let id = UUID()
    let type: LocalInsightType
    let title: String
    let description: String
    let value: String?
    let trend: LocalInsightTrend?

    init(type: LocalInsightType, title: String, description: String, value: String? = nil, trend: LocalInsightTrend? = nil) {
        self.type = type
        self.title = title
        self.description = description
        self.value = value
        self.trend = trend
    }
}

/// Section of insights
struct LocalInsightSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let insights: [LocalInsightItem]
}

/// Complete local insights result
struct LocalInsights {
    let sections: [LocalInsightSection]
    let generatedAt: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: generatedAt)
    }
}

// MARK: - LocalAnalysisService Extension for AI Insights Tab

extension LocalAnalysisService {

    /// Analysis preferences for the AI Insights tab
    struct AnalysisPreferences {
        let includePatterns: Bool
        let includeJournals: Bool
        let includeMedications: Bool
        let timeframeDays: Int
    }

    /// Analyze data based on preferences - used by AIInsightsTabViewModel
    func analyzeData(preferences: AnalysisPreferences) async -> LocalInsights {
        var sections: [LocalInsightSection] = []

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -preferences.timeframeDays, to: endDate) ?? endDate

        // Fetch data
        let patterns = preferences.includePatterns ? await fetchPatterns(from: startDate, to: endDate) : []
        let journals = preferences.includeJournals ? await fetchJournals(from: startDate, to: endDate) : []
        let medications = preferences.includeMedications ? await fetchMedications(from: startDate, to: endDate) : []

        // Generate pattern insights
        if !patterns.isEmpty {
            let patternInsights = generatePatternInsights(patterns: patterns)
            if !patternInsights.isEmpty {
                sections.append(LocalInsightSection(
                    title: "Pattern Analysis",
                    icon: "waveform.path.ecg",
                    insights: patternInsights
                ))
            }
        }

        // Generate journal insights
        if !journals.isEmpty {
            let journalInsights = generateJournalInsights(journals: journals)
            if !journalInsights.isEmpty {
                sections.append(LocalInsightSection(
                    title: "Journal Insights",
                    icon: "book.closed",
                    insights: journalInsights
                ))
            }
        }

        // Generate medication insights
        if !medications.isEmpty {
            let medInsights = generateMedicationInsights(medications: medications)
            if !medInsights.isEmpty {
                sections.append(LocalInsightSection(
                    title: "Medication Tracking",
                    icon: "pills",
                    insights: medInsights
                ))
            }
        }

        // Generate suggestions
        let suggestions = generateSuggestions(patterns: patterns, journals: journals, medications: medications)
        if !suggestions.isEmpty {
            sections.append(LocalInsightSection(
                title: "Suggestions",
                icon: "lightbulb",
                insights: suggestions
            ))
        }

        // If no data, provide a helpful message
        if sections.isEmpty {
            sections.append(LocalInsightSection(
                title: "Getting Started",
                icon: "star",
                insights: [
                    LocalInsightItem(
                        type: .suggestion,
                        title: "Start Tracking",
                        description: "Add some journal entries or log patterns to see personalized insights here."
                    )
                ]
            ))
        }

        return LocalInsights(sections: sections, generatedAt: Date())
    }

    // MARK: - Sendable Data Transfer Objects
    
    /// Lightweight, sendable version of PatternEntry for cross-actor use
    private struct PatternData: Sendable {
        let category: String
        let patternType: String
        let intensity: Int16
        let timestamp: Date
    }
    
    /// Lightweight, sendable version of JournalEntry for cross-actor use
    private struct JournalData: Sendable {
        let content: String
        let timestamp: Date
    }
    
    /// Lightweight, sendable version of MedicationLog for cross-actor use
    private struct MedicationData: Sendable {
        let taken: Bool
        let timestamp: Date
    }

    // MARK: - Data Fetching

    private func fetchPatterns(from startDate: Date, to endDate: Date) async -> [PatternData] {
        await MainActor.run {
            let patterns = DataController.shared.fetchPatternEntries(startDate: startDate, endDate: endDate)
            return patterns.map { pattern in
                PatternData(
                    category: pattern.category,
                    patternType: pattern.patternType,
                    intensity: pattern.intensity,
                    timestamp: pattern.timestamp
                )
            }
        }
    }

    private func fetchJournals(from startDate: Date, to endDate: Date) async -> [JournalData] {
        await MainActor.run {
            let journals = DataController.shared.fetchJournalEntriesSync(startDate: startDate, endDate: endDate)
            return journals.map { journal in
                JournalData(
                    content: journal.content,
                    timestamp: journal.timestamp
                )
            }
        }
    }

    private func fetchMedications(from startDate: Date, to endDate: Date) async -> [MedicationData] {
        await MainActor.run {
            let medications = DataController.shared.fetchMedicationLogs(startDate: startDate, endDate: endDate)
            return medications.map { medication in
                MedicationData(
                    taken: medication.taken,
                    timestamp: medication.timestamp
                )
            }
        }
    }

    // MARK: - Insight Generation for AI Insights Tab

    private func generatePatternInsights(patterns: [PatternData]) -> [LocalInsightItem] {
        var insights: [LocalInsightItem] = []

        // Count patterns by type
        var typeCounts: [String: Int] = [:]
        for pattern in patterns {
            let type = pattern.category.isEmpty ? "Unknown" : pattern.category
            typeCounts[type, default: 0] += 1
        }

        // Total patterns statistic
        insights.append(LocalInsightItem(
            type: .statistic,
            title: "Total Patterns Logged",
            description: "You've tracked \(patterns.count) pattern\(patterns.count == 1 ? "" : "s") in this period.",
            value: "\(patterns.count)"
        ))

        // Most common pattern
        if let mostCommon = typeCounts.max(by: { $0.value < $1.value }) {
            insights.append(LocalInsightItem(
                type: .category,
                title: "Most Frequent",
                description: "\(mostCommon.key) patterns appear most often (\(mostCommon.value) times).",
                value: mostCommon.key
            ))
        }

        // Pattern variety
        if typeCounts.count > 1 {
            insights.append(LocalInsightItem(
                type: .pattern,
                title: "Pattern Variety",
                description: "You're tracking \(typeCounts.count) different types of patterns.",
                value: "\(typeCounts.count) types"
            ))
        }

        // Analyze intensity if available
        let intensities = patterns.map { Int($0.intensity) }.filter { $0 > 0 }
        if !intensities.isEmpty {
            let avgIntensity = Double(intensities.reduce(0, +)) / Double(intensities.count)
            let trend: LocalInsightTrend = avgIntensity > 4 ? .negative : avgIntensity < 2 ? .positive : .neutral
            insights.append(LocalInsightItem(
                type: .trend,
                title: "Average Intensity",
                description: "Your patterns average \(String(format: "%.1f", avgIntensity)) intensity.",
                value: String(format: "%.1f", avgIntensity),
                trend: trend
            ))
        }

        return insights
    }

    private func generateJournalInsights(journals: [JournalData]) -> [LocalInsightItem] {
        var insights: [LocalInsightItem] = []

        // Journal count
        insights.append(LocalInsightItem(
            type: .statistic,
            title: "Journal Entries",
            description: "You've written \(journals.count) journal entr\(journals.count == 1 ? "y" : "ies").",
            value: "\(journals.count)"
        ))

        // Analyze sentiment across all entries
        let combinedText = journals.map { $0.content }.joined(separator: " ")
        if !combinedText.isEmpty {
            let sentiment = analyzeSentiment(text: combinedText)
            let sentimentDescription: String
            let trend: LocalInsightTrend

            switch sentiment {
            case .positive:
                sentimentDescription = "Your entries have a generally positive tone."
                trend = .positive
            case .negative:
                sentimentDescription = "Your entries reflect some challenges. That's valid."
                trend = .negative
            case .mixed:
                sentimentDescription = "Your entries show a mix of emotions - that's real life."
                trend = .neutral
            case .neutral:
                sentimentDescription = "Your entries have a balanced, neutral tone."
                trend = .neutral
            }

            insights.append(LocalInsightItem(
                type: .mood,
                title: "Overall Sentiment",
                description: sentimentDescription,
                value: sentiment.rawValue.capitalized,
                trend: trend
            ))
        }

        // Word count analysis
        let totalWords = journals.map { $0.content.split(separator: " ").count }.reduce(0, +)
        if totalWords > 0 {
            let avgWords = totalWords / max(1, journals.count)
            insights.append(LocalInsightItem(
                type: .statistic,
                title: "Writing Volume",
                description: "You've written approximately \(totalWords) words total (avg \(avgWords) per entry).",
                value: "\(totalWords) words"
            ))
        }

        return insights
    }

    private func generateMedicationInsights(medications: [MedicationData]) -> [LocalInsightItem] {
        var insights: [LocalInsightItem] = []

        // Medication log count
        insights.append(LocalInsightItem(
            type: .medication,
            title: "Medication Logs",
            description: "You've logged \(medications.count) medication entr\(medications.count == 1 ? "y" : "ies").",
            value: "\(medications.count)"
        ))

        // Check for taken vs skipped
        let takenCount = medications.filter { $0.taken }.count
        let skippedCount = medications.count - takenCount

        if !medications.isEmpty {
            let adherenceRate = Double(takenCount) / Double(medications.count) * 100
            let trend: LocalInsightTrend = adherenceRate >= 80 ? .positive : adherenceRate >= 50 ? .neutral : .negative

            insights.append(LocalInsightItem(
                type: .adherence,
                title: "Adherence Rate",
                description: "You've taken \(takenCount) of \(medications.count) logged medications (\(String(format: "%.0f", adherenceRate))%).",
                value: "\(String(format: "%.0f", adherenceRate))%",
                trend: trend
            ))

            if skippedCount > 0 {
                insights.append(LocalInsightItem(
                    type: .warning,
                    title: "Skipped Doses",
                    description: "You've skipped \(skippedCount) dose\(skippedCount == 1 ? "" : "s"). Review your schedule if needed.",
                    value: "\(skippedCount)"
                ))
            }
        }

        return insights
    }

    private func generateSuggestions(patterns: [PatternData], journals: [JournalData], medications: [MedicationData]) -> [LocalInsightItem] {
        var suggestions: [LocalInsightItem] = []

        // Suggest based on data availability
        if patterns.isEmpty {
            suggestions.append(LocalInsightItem(
                type: .suggestion,
                title: "Track Patterns",
                description: "Start logging patterns to discover trends in your behaviors and experiences."
            ))
        }

        if journals.isEmpty {
            suggestions.append(LocalInsightItem(
                type: .suggestion,
                title: "Journal Regularly",
                description: "Daily journaling helps identify emotional patterns and triggers."
            ))
        } else if journals.count < 7 {
            suggestions.append(LocalInsightItem(
                type: .positive,
                title: "Keep It Up",
                description: "You're building a journaling habit. Try to write a little each day."
            ))
        }

        if medications.isEmpty {
            suggestions.append(LocalInsightItem(
                type: .suggestion,
                title: "Log Medications",
                description: "If you take medications, tracking them helps monitor adherence and effects."
            ))
        }

        // Positive reinforcement if data is good
        if patterns.count >= 10 && journals.count >= 5 {
            suggestions.append(LocalInsightItem(
                type: .positive,
                title: "Great Progress",
                description: "You're consistently tracking. This data will reveal meaningful patterns over time."
            ))
        }

        return suggestions
    }
}

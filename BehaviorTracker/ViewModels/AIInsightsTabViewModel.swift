import SwiftUI
import Combine

// MARK: - Analysis Mode

enum AnalysisMode: String, CaseIterable {
    case local = "local"
    case ai = "ai"

    var displayName: String {
        switch self {
        case .local: return NSLocalizedString("insights.mode.local", comment: "Local Analysis")
        case .ai: return NSLocalizedString("insights.mode.ai", comment: "AI Analysis")
        }
    }

    var icon: String {
        switch self {
        case .local: return "cpu"
        case .ai: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .local: return NSLocalizedString("insights.mode.local.description", comment: "Analyze patterns locally on your device. No internet required, completely private.")
        case .ai: return NSLocalizedString("insights.mode.ai.description", comment: "Get personalized insights using Google Gemini AI. Requires internet and API key.")
        }
    }
}

// MARK: - ViewModel

@MainActor
class AIInsightsTabViewModel: ObservableObject {
    @Published var includePatterns = true
    @Published var includeJournals = true
    @Published var includeMedications = true
    @Published var timeframeDays = 30

    @Published var isAnalyzing = false
    @Published var insights: AIInsights?
    @Published var localInsights: LocalInsights?
    @Published var summaryInsights: SummaryInsights?
    @Published var errorMessage: String?

    @Published var apiKeyInput = ""
    @Published var showingSettings = false
    @Published var showCopiedFeedback = false

    // Analysis mode preference - stored in UserDefaults
    @Published var analysisMode: AnalysisMode {
        didSet {
            UserDefaults.standard.set(analysisMode.rawValue, forKey: "preferred_analysis_mode")
        }
    }

    private let geminiService = GeminiService.shared
    private let aiAnalysisService = AIAnalysisService.shared
    private let localAnalysisService = LocalAnalysisService.shared
    private let demoService = DemoModeService.shared
    private var cancellables = Set<AnyCancellable>()

    /// Whether we're currently in demo mode
    var isDemoMode: Bool {
        demoService.isEnabled
    }

    init() {
        // Load saved analysis mode preference
        if let savedMode = UserDefaults.standard.string(forKey: "preferred_analysis_mode"),
           let mode = AnalysisMode(rawValue: savedMode) {
            self.analysisMode = mode
        } else {
            // Default to local mode for privacy-first approach
            self.analysisMode = .local
        }
        apiKeyInput = geminiService.apiKey ?? ""
        observeDemoModeChanges()
    }

    private func observeDemoModeChanges() {
        NotificationCenter.default.publisher(for: .demoModeChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Clear results when mode changes
                self?.insights = nil
                self?.localInsights = nil
                self?.summaryInsights = nil
            }
            .store(in: &cancellables)
    }

    var hasAcknowledgedPrivacy: Bool {
        UserDefaults.standard.bool(forKey: "ai_privacy_acknowledged")
    }

    var isAPIKeyConfigured: Bool {
        // Service account credentials are built-in, always configured
        true
    }

    /// Returns true if the current mode can be used
    var canUseCurrentMode: Bool {
        switch analysisMode {
        case .local:
            return true // Local mode always available
        case .ai:
            return hasAcknowledgedPrivacy && isAPIKeyConfigured
        }
    }

    /// Returns true if AI mode is fully configured
    var isAIModeReady: Bool {
        hasAcknowledgedPrivacy && isAPIKeyConfigured
    }

    func acknowledgePrivacy() {
        UserDefaults.standard.set(true, forKey: "ai_privacy_acknowledged")
        objectWillChange.send()
    }

    func resetPrivacyAcknowledgment() {
        UserDefaults.standard.set(false, forKey: "ai_privacy_acknowledged")
        objectWillChange.send()
    }

    func saveAPIKey() {
        let trimmedKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate before saving
        guard !trimmedKey.isEmpty else {
            errorMessage = "Please enter an API key"
            return
        }

        // Store directly in UserDefaults (bypass overly strict validation)
        UserDefaults.standard.set(trimmedKey, forKey: "gemini_api_key")
        apiKeyInput = trimmedKey
        errorMessage = nil
        objectWillChange.send()
    }

    func removeAPIKey() {
        geminiService.apiKey = nil
        apiKeyInput = ""
        objectWillChange.send()
    }

    func analyze() async {
        isAnalyzing = true
        errorMessage = nil
        insights = nil
        localInsights = nil
        summaryInsights = nil

        // Demo mode: show demo insights
        if isDemoMode {
            await analyzeDemoMode()
            isAnalyzing = false
            return
        }

        switch analysisMode {
        case .local:
            await analyzeLocally()
        case .ai:
            await analyzeWithAI()
        }

        isAnalyzing = false
    }

    private func analyzeDemoMode() async {
        // Simulate a brief loading delay for demo
        try? await Task.sleep(nanoseconds: 800_000_000)

        let demoInsights = demoService.demoAIInsights

        // Create demo local insights with multiple sections
        let patternSection = LocalInsightSection(
            title: "Pattern Analysis",
            icon: "waveform.path.ecg",
            insights: [
                LocalInsightItem(
                    type: .pattern,
                    title: "Most Common Pattern",
                    description: "Sensory Overload occurs most frequently, especially in mornings",
                    value: "35%",
                    trend: .neutral
                ),
                LocalInsightItem(
                    type: .cascade,
                    title: "Pattern Cascade",
                    description: "Sensory Overload often leads to Energy Dip within 2 hours",
                    value: nil,
                    trend: nil
                ),
                LocalInsightItem(
                    type: .time,
                    title: "Peak Times",
                    description: "Most patterns logged between 9 AM and 11 AM",
                    value: nil,
                    trend: nil
                )
            ]
        )

        let moodSection = LocalInsightSection(
            title: "Mood & Energy",
            icon: "face.smiling",
            insights: [
                LocalInsightItem(
                    type: .mood,
                    title: "Average Mood",
                    description: "Your mood tends to be higher on weekends",
                    value: "3.8/5",
                    trend: .positive
                ),
                LocalInsightItem(
                    type: .trend,
                    title: "Energy Pattern",
                    description: "Energy levels dip after social interactions",
                    value: nil,
                    trend: .negative
                )
            ]
        )

        let suggestionsSection = LocalInsightSection(
            title: "Suggestions",
            icon: "lightbulb",
            insights: [
                LocalInsightItem(
                    type: .suggestion,
                    title: "Morning Routine",
                    description: demoInsights[0],
                    value: nil,
                    trend: nil
                ),
                LocalInsightItem(
                    type: .suggestion,
                    title: "Recovery Time",
                    description: demoInsights[1],
                    value: nil,
                    trend: nil
                ),
                LocalInsightItem(
                    type: .positive,
                    title: "Coping Success",
                    description: demoInsights[4],
                    value: nil,
                    trend: .positive
                )
            ]
        )

        localInsights = LocalInsights(
            sections: [patternSection, moodSection, suggestionsSection],
            generatedAt: Date()
        )

        summaryInsights = SummaryInsights(
            keyPatterns: "Sensory sensitivity peaks in morning hours with 35% of overload episodes",
            topRecommendation: demoInsights[0]
        )
    }

    private func analyzeLocally() async {
        let preferences = LocalAnalysisService.AnalysisPreferences(
            includePatterns: includePatterns,
            includeJournals: includeJournals,
            includeMedications: includeMedications,
            timeframeDays: timeframeDays
        )

        let result = await localAnalysisService.analyzeData(preferences: preferences)
        localInsights = result

        // Extract summary from local insights
        summaryInsights = extractLocalSummary(from: result)
    }

    private func analyzeWithAI() async {
        let preferences = AIAnalysisService.AnalysisPreferences(
            includePatterns: includePatterns,
            includeJournals: includeJournals,
            includeMedications: includeMedications,
            timeframeDays: timeframeDays
        )

        do {
            let result = try await aiAnalysisService.analyzeData(preferences: preferences)
            insights = result

            // Parse summary from the full report
            summaryInsights = extractSummary(from: result.content)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func extractLocalSummary(from insights: LocalInsights) -> SummaryInsights {
        var keyPattern = "Your data has been analyzed locally."
        var topRecommendation = "Continue tracking for more insights."

        // Find first pattern insight
        for section in insights.sections {
            for insight in section.insights {
                if insight.type == .pattern || insight.type == .statistic || insight.type == .category {
                    keyPattern = insight.description
                    break
                }
            }
            if keyPattern != "Your data has been analyzed locally." { break }
        }

        // Find first suggestion
        for section in insights.sections where section.title == "Suggestions" {
            if let firstSuggestion = section.insights.first {
                topRecommendation = firstSuggestion.description
            }
        }

        return SummaryInsights(keyPatterns: keyPattern, topRecommendation: topRecommendation)
    }

    private func extractSummary(from content: String) -> SummaryInsights {
        // Extract key patterns - look for pattern-related content
        var keyPatterns = "Based on your data, notable patterns have been identified in your tracked behaviors."
        var topRecommendation = "Continue tracking consistently for more personalized insights."

        let lines = content.components(separatedBy: "\n")
        var inPatternsSection = false
        var inRecommendationsSection = false

        for line in lines {
            let lowercased = line.lowercased()

            if lowercased.contains("pattern") || lowercased.contains("trend") || lowercased.contains("observation") {
                inPatternsSection = true
                inRecommendationsSection = false
            } else if lowercased.contains("recommend") || lowercased.contains("suggest") || lowercased.contains("advice") {
                inPatternsSection = false
                inRecommendationsSection = true
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if (trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ")) {
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                // Clean up markdown bold markers
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    if inPatternsSection && keyPatterns == "Based on your data, notable patterns have been identified in your tracked behaviors." {
                        keyPatterns = bullet
                    } else if inRecommendationsSection && topRecommendation == "Continue tracking consistently for more personalized insights." {
                        topRecommendation = bullet
                    }
                }
            }
        }

        return SummaryInsights(keyPatterns: keyPatterns, topRecommendation: topRecommendation)
    }
}

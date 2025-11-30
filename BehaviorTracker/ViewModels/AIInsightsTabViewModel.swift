import SwiftUI

// MARK: - ViewModel

@MainActor
class AIInsightsTabViewModel: ObservableObject {
    @Published var includePatterns = true
    @Published var includeJournals = true
    @Published var includeMedications = true
    @Published var timeframeDays = 30

    @Published var isAnalyzing = false
    @Published var insights: AIInsights?
    @Published var summaryInsights: SummaryInsights?
    @Published var errorMessage: String?

    @Published var apiKeyInput = ""
    @Published var showingSettings = false
    @Published var showCopiedFeedback = false

    private let geminiService = GeminiService.shared
    private let analysisService = AIAnalysisService.shared

    var hasAcknowledgedPrivacy: Bool {
        UserDefaults.standard.bool(forKey: "ai_privacy_acknowledged")
    }

    var isAPIKeyConfigured: Bool {
        geminiService.isConfigured
    }

    init() {
        apiKeyInput = geminiService.apiKey ?? ""
    }

    func acknowledgePrivacy() {
        UserDefaults.standard.set(true, forKey: "ai_privacy_acknowledged")
        objectWillChange.send()
    }

    func saveAPIKey() {
        geminiService.apiKey = apiKeyInput
        objectWillChange.send()
    }

    func analyze() async {
        isAnalyzing = true
        errorMessage = nil
        insights = nil
        summaryInsights = nil

        let preferences = AIAnalysisService.AnalysisPreferences(
            includePatterns: includePatterns,
            includeJournals: includeJournals,
            includeMedications: includeMedications,
            timeframeDays: timeframeDays
        )

        do {
            let result = try await analysisService.analyzeData(preferences: preferences)
            insights = result

            // Parse summary from the full report
            summaryInsights = extractSummary(from: result.content)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
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

import SwiftUI

// MARK: - ViewModel

@MainActor
class FeelingFinderViewModel: ObservableObject {
    @Published var data = FeelingFinderData()
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private let aiService = AIAnalysisService.shared

    func generateEntry() async {
        isGenerating = true
        errorMessage = nil

        let prompt = buildPrompt()

        do {
            let result = try await aiService.analyzeWithPrompt(prompt)
            data.generatedEntry = result
        } catch {
            errorMessage = "Couldn't generate entry. Please try again."
        }

        isGenerating = false
    }

    private func buildPrompt() -> String {
        var prompt = """
        You are an emotion identification assistant helping users understand their internal state.
        The user has difficulty recognizing and naming emotions.

        You will receive:
        - A general feeling category they selected
        - Contributing factors they identified
        - Specific details about those factors
        - Optionally, free text they wrote for more context

        Your task:
        Generate a first-person journal entry (4-5 lines) that:
        - Starts with "I am feeling..." or similar first-person phrasing
        - Connects their general feeling to the contributing factors
        - Mentions physical sensations if provided
        - Explains what their body/mind is likely responding to
        - Ends with a gentle insight or possible helpful action
        - Uses simple, clear, non-clinical language
        - Sounds like something they would write about themselves

        Do not:
        - Use second person ("you are feeling")
        - Be diagnostic or clinical
        - Exceed 5 lines
        - Use bullet points or lists
        - Add generic advice unrelated to their specific input

        ---

        """

        // General feeling
        if let feeling = data.generalFeeling {
            prompt += "General feeling: \(feeling.rawValue)\n\n"
        }

        // Contributing factors
        if !data.selectedFactors.isEmpty {
            prompt += "Contributing factors: \(data.selectedFactors.map { $0.rawValue }.joined(separator: ", "))\n\n"
        }

        // Details
        if !data.environmentDetails.isEmpty {
            prompt += "Environment details: \(data.environmentDetails.joined(separator: ", "))\n"
        }
        if !data.eventDetails.isEmpty {
            prompt += "Event details: \(data.eventDetails.joined(separator: ", "))\n"
        }
        if !data.healthDetails.isEmpty {
            prompt += "Body/health details: \(data.healthDetails.joined(separator: ", "))\n"
        }
        if !data.socialDetails.isEmpty {
            prompt += "Social details: \(data.socialDetails.joined(separator: ", "))\n"
        }
        if !data.demandDetails.isEmpty {
            prompt += "Demands/obligations details: \(data.demandDetails.joined(separator: ", "))\n"
        }

        // Additional text
        if !data.additionalText.isEmpty {
            prompt += "\nAdditional context from user: \(data.additionalText)\n"
        }

        prompt += "\n---\n\nWrite the first-person journal entry now:"

        return prompt
    }
}

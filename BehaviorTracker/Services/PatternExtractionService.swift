import Foundation

/// Service that extracts ASD/PDA patterns from journal entries using AI
class PatternExtractionService {
    static let shared = PatternExtractionService()

    private let geminiService = GeminiService.shared

    private init() {}

    // MARK: - Extraction Response Models

    struct ExtractionResult: Codable {
        let patterns: [ExtractedPatternData]
        let cascades: [CascadeData]
        let triggers: [String]
        let context: ContextData
        let overallIntensity: Int
        let confidence: Double
        let summary: String

        enum CodingKeys: String, CodingKey {
            case patterns, cascades, triggers, context
            case overallIntensity = "overall_intensity"
            case confidence, summary
        }
    }

    struct ExtractedPatternData: Codable {
        let type: String
        let category: String
        let intensity: Int
        let triggers: [String]?
        let timeOfDay: String?
        let copingUsed: [String]?
        let details: String?

        enum CodingKeys: String, CodingKey {
            case type, category, intensity, triggers
            case timeOfDay = "time_of_day"
            case copingUsed = "coping_used"
            case details
        }
    }

    struct CascadeData: Codable {
        let from: String
        let to: String
        let confidence: Double
        let description: String?
    }

    struct ContextData: Codable {
        let timeOfDay: String?
        let location: String?
        let socialContext: String?
        let sleepMentioned: Bool?
        let medicationMentioned: Bool?

        enum CodingKeys: String, CodingKey {
            case timeOfDay = "time_of_day"
            case location
            case socialContext = "social_context"
            case sleepMentioned = "sleep_mentioned"
            case medicationMentioned = "medication_mentioned"
        }
    }

    // MARK: - Main Extraction Function

    /// Analyze a journal entry and extract patterns
    func extractPatterns(from entry: String) async throws -> ExtractionResult {
        guard geminiService.isConfigured else {
            throw ExtractionError.noAPIKey
        }

        // Build the full prompt
        let fullPrompt = """
        \(PatternBank.prompt)

        ---

        JOURNAL ENTRY TO ANALYZE:

        \(entry)
        """

        // Call Gemini
        let response = try await geminiService.generateContent(prompt: fullPrompt)

        // Parse JSON response
        return try parseResponse(response)
    }

    /// Analyze multiple entries and find cross-entry cascades
    func analyzeEntriesForCascades(entries: [(text: String, timestamp: Date)]) async throws -> [CascadeData] {
        guard geminiService.isConfigured else {
            throw ExtractionError.noAPIKey
        }

        // Format entries with timestamps
        let formattedEntries = entries.enumerated().map { index, entry in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "[\(formatter.string(from: entry.timestamp))]\n\(entry.text)"
        }.joined(separator: "\n\n---\n\n")

        let cascadePrompt = """
        \(PatternBank.prompt)

        ---

        SPECIAL INSTRUCTION: Analyze these MULTIPLE journal entries in chronological order.
        Look for CASCADES that span across entries - patterns from earlier entries that led to patterns in later entries.

        ENTRIES:

        \(formattedEntries)

        ---

        Return JSON with emphasis on cross-entry cascades:
        {
          "cascades": [
            {
              "from": "Pattern Type",
              "to": "Pattern Type",
              "confidence": 0.8,
              "description": "Explanation including time relationship"
            }
          ]
        }
        """

        let response = try await geminiService.generateContent(prompt: cascadePrompt)

        // Parse cascades only
        guard response.data(using: .utf8) != nil else {
            throw ExtractionError.invalidResponse
        }

        struct CascadeResponse: Codable {
            let cascades: [CascadeData]
        }

        let cleaned = cleanJSONResponse(response)
        guard let cleanedData = cleaned.data(using: .utf8) else {
            throw ExtractionError.invalidResponse
        }

        let result = try JSONDecoder().decode(CascadeResponse.self, from: cleanedData)
        return result.cascades
    }

    // MARK: - Response Parsing

    private func parseResponse(_ response: String) throws -> ExtractionResult {
        // Clean the response - remove markdown code blocks if present
        let cleaned = cleanJSONResponse(response)

        guard let data = cleaned.data(using: .utf8) else {
            throw ExtractionError.invalidResponse
        }

        do {
            let result = try JSONDecoder().decode(ExtractionResult.self, from: data)
            return result
        } catch {
            // Try to extract partial data if full parsing fails
            throw ExtractionError.parsingFailed(error.localizedDescription)
        }
    }

    private func cleanJSONResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Validation

    /// Validate extracted patterns against known pattern types
    func validatePatterns(_ patterns: [ExtractedPatternData]) -> [ExtractedPatternData] {
        return patterns.filter { pattern in
            PatternBank.validPatternNames.contains(pattern.type)
        }
    }

    /// Convert extracted pattern to PatternType enum
    func toPatternType(_ extracted: ExtractedPatternData) -> PatternType? {
        return PatternBank.patternType(from: extracted.type)
    }
}

// MARK: - Errors

enum ExtractionError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case parsingFailed(String)
    case noPatterns

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Gemini API key configured"
        case .invalidResponse:
            return "Invalid response from AI"
        case .parsingFailed(let detail):
            return "Failed to parse AI response: \(detail)"
        case .noPatterns:
            return "No patterns found in entry"
        }
    }
}

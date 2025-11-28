import Foundation

class GeminiService {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    private init() {}

    var apiKey: String? {
        get { UserDefaults.standard.string(forKey: "gemini_api_key") }
        set {
            // Validate API key before storing
            if let key = newValue {
                do {
                    try validateAPIKey(key)
                    UserDefaults.standard.set(key, forKey: "gemini_api_key")
                } catch {
                    // Invalid key, don't store it
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "gemini_api_key")
            }
        }
    }

    var isConfigured: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    private func validateAPIKey(_ key: String) throws {
        try Validator(key, fieldName: "API key")
            .notEmpty()
            .minLength(20, message: "API key is too short")
            .maxLength(200, message: "API key is too long")
            .matches(pattern: "^[A-Za-z0-9_-]+$", message: "API key contains invalid characters")
    }

    func generateContent(prompt: String) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        // Validate API key format before using
        try validateAPIKey(apiKey)

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        if httpResponse.statusCode == 400 {
            throw GeminiError.invalidAPIKey
        }

        if httpResponse.statusCode != 200 {
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.noContent
        }

        return text
    }
}

// MARK: - Response Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
}

struct GeminiPart: Codable {
    let text: String?
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case invalidAPIKey
    case httpError(Int)
    case noContent

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your Gemini API key in Settings."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidAPIKey:
            return "Invalid API key. Please check your Gemini API key in Settings."
        case .httpError(let code):
            return "Server error (HTTP \(code)). Please try again."
        case .noContent:
            return "No response content from AI."
        }
    }
}

import Foundation

/// Service for interacting with Claude on Vertex AI
class ClaudeService {
    static let shared = ClaudeService()

    // Vertex AI configuration for Claude
    private let projectID = "gen-lang-client-0564188419"
    private let region = "us-east5"  // Claude is available in us-east5
    private let model = "claude-opus-4@20250514"

    private var baseURL: String {
        "https://\(region)-aiplatform.googleapis.com/v1/projects/\(projectID)/locations/\(region)/publishers/anthropic/models/\(model):rawPredict"
    }

    /// Maximum number of retry attempts
    private let maxRetries = 3
    private let baseRetryDelay: Double = 2.0

    /// Track last request time for rate limiting
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0

    private init() {}

    var isConfigured: Bool {
        true  // Service account is built-in
    }

    func generateContent(prompt: String) async throws -> String {
        // Rate limiting
        await enforceMinRequestInterval()

        // Get OAuth token from GoogleAuthService
        let accessToken: String
        do {
            accessToken = try await GoogleAuthService.shared.getAccessToken()
        } catch {
            throw ClaudeError.authenticationFailed(error.localizedDescription)
        }

        guard let url = URL(string: baseURL) else {
            throw ClaudeError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Claude uses different request format
        let requestPayload = ClaudeRequestPayload(
            anthropic_version: "vertex-2023-10-16",
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ],
            max_tokens: 4096
        )

        let jsonData = try JSONEncoder().encode(requestPayload)

        #if DEBUG
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            AppLogger.ai.debug("Claude request: \(jsonString.prefix(200))")
        }
        #endif

        request.httpBody = jsonData

        // Attempt request with retry
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                lastRequestTime = Date()
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ClaudeError.invalidResponse
                }

                AppLogger.ai.debug("Claude response status: \(httpResponse.statusCode)")

                switch httpResponse.statusCode {
                case 200:
                    let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
                    guard let text = claudeResponse.content.first?.text else {
                        throw ClaudeError.noContent
                    }
                    return text

                case 400:
                    var errorDetail = "Bad request"
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        errorDetail = message
                    }
                    throw ClaudeError.httpError(400, errorDetail)

                case 401, 403:
                    throw ClaudeError.authenticationFailed("Invalid credentials")

                case 429:
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = ClaudeError.rateLimited
                    continue

                case 500, 502, 503, 504:
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = ClaudeError.httpError(httpResponse.statusCode, "")
                    continue

                default:
                    var errorDetail = ""
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        errorDetail = message
                    }
                    throw ClaudeError.httpError(httpResponse.statusCode, errorDetail)
                }

            } catch let error as ClaudeError {
                throw error
            } catch {
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = error
                    continue
                }
                throw error
            }
        }

        if let lastError = lastError as? ClaudeError {
            throw lastError
        }
        throw ClaudeError.rateLimited
    }

    private func enforceMinRequestInterval() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minRequestInterval {
                let waitTime = minRequestInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
    }
}

// MARK: - Request Models

struct ClaudeRequestPayload: Encodable {
    let anthropic_version: String
    let messages: [ClaudeMessage]
    let max_tokens: Int
}

struct ClaudeMessage: Encodable {
    let role: String
    let content: String
}

// MARK: - Response Models

struct ClaudeResponse: Decodable {
    let content: [ClaudeContentBlock]
}

struct ClaudeContentBlock: Decodable {
    let type: String
    let text: String?
}

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case noContent
    case rateLimited
    case authenticationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Claude API URL."
        case .invalidResponse:
            return "Invalid response from Claude."
        case .httpError(let code, let detail):
            if detail.isEmpty {
                return "Claude error (HTTP \(code))."
            }
            return "Claude error \(code): \(detail)"
        case .noContent:
            return "No response from Claude."
        case .rateLimited:
            return "Claude rate limited. Please wait."
        case .authenticationFailed(let detail):
            return "Claude auth failed: \(detail)"
        }
    }
}

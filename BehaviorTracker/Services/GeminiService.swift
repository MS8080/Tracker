import Foundation

/// Simple async semaphore to serialize API requests
actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int) {
        self.count = value
    }

    func wait() async {
        if count > 0 {
            count -= 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            count += 1
        }
    }
}

class GeminiService {
    static let shared = GeminiService()

    // Vertex AI configuration with API key
    private let model = "gemini-2.5-flash-lite"
    private let vertexAPIKey = "AQ.Ab8RN6J3LRWEVCcTHY_FmzsdW90R27P2YIRGulK2pcUMrxeVaw"

    private var baseURL: String {
        "https://aiplatform.googleapis.com/v1/publishers/google/models/\(model):generateContent?key=\(vertexAPIKey)"
    }

    /// Maximum number of retry attempts for rate-limited requests
    private let maxRetries = 3

    /// Base delay for exponential backoff (in seconds)
    private let baseRetryDelay: Double = 2.0

    /// Track last request time to implement client-side rate limiting
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 2.0 // Minimum 2 seconds between requests

    /// Serial queue to prevent concurrent API requests
    private let requestQueue = DispatchQueue(label: "com.behaviortracker.gemini.queue")
    private var isRequestInProgress = false

    /// Semaphore to serialize async requests
    private let requestSemaphore = AsyncSemaphore(value: 1)

    /// Track recently analyzed entry IDs to prevent duplicate analysis
    private var recentlyAnalyzedEntries: [UUID: Date] = [:]
    private let analysisCooldown: TimeInterval = 60.0 // 60 seconds cooldown per entry

    private init() {}

    // MARK: - Entry Analysis Deduplication

    /// Check if an entry was recently analyzed (within cooldown period)
    func wasRecentlyAnalyzed(entryID: UUID) -> Bool {
        guard let lastAnalyzed = recentlyAnalyzedEntries[entryID] else {
            return false
        }
        let elapsed = Date().timeIntervalSince(lastAnalyzed)
        if elapsed > analysisCooldown {
            recentlyAnalyzedEntries.removeValue(forKey: entryID)
            return false
        }
        return true
    }

    /// Mark an entry as analyzed
    func markAsAnalyzed(entryID: UUID) {
        recentlyAnalyzedEntries[entryID] = Date()
        // Clean up old entries periodically
        cleanupOldEntries()
    }

    private func cleanupOldEntries() {
        let now = Date()
        recentlyAnalyzedEntries = recentlyAnalyzedEntries.filter { _, date in
            now.timeIntervalSince(date) < analysisCooldown * 2
        }
    }

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
        // Service account credentials are built-in, so always configured
        return true
    }

    private func validateAPIKey(_ key: String) throws {
        try Validator(key, fieldName: "API key")
            .notEmpty()
            .minLength(10, message: "API key is too short")
            .maxLength(500, message: "API key is too long")
    }

    func generateContent(prompt: String) async throws -> String {
        // Serialize requests - only one at a time
        await requestSemaphore.wait()
        defer { Task { await requestSemaphore.signal() } }

        // Client-side rate limiting - wait if we made a request too recently
        await enforceMinRequestInterval()

        let urlString = baseURL
        print("🔵 Gemini API URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Use Codable structs for proper JSON encoding
        let requestPayload = GeminiRequestPayload(
            contents: [
                GeminiRequestContent(
                    role: "user",
                    parts: [GeminiRequestPart(text: prompt)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 2048
            )
        )

        let jsonData = try JSONEncoder().encode(requestPayload)

        // Debug: print the JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("🔵 Request JSON: \(jsonString)")
        }

        request.httpBody = jsonData

        // Attempt request with retry logic for rate limiting
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                lastRequestTime = Date()
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GeminiError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200:
                    let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
                        throw GeminiError.noContent
                    }
                    return text

                case 400:
                    // Parse error details
                    var errorDetail = ""
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        errorDetail = message
                    }
                    throw GeminiError.httpError(400, errorDetail.isEmpty ? "Bad request" : errorDetail)

                case 429:
                    // Rate limited - check if it's quota exhausted or temporary rate limit
                    // Try to parse error response for more details
                    var errorDetail = ""
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        errorDetail = message

                        // Check if it's a quota issue (not retryable)
                        if message.lowercased().contains("quota") || message.lowercased().contains("exhausted") {
                            throw GeminiError.quotaExhausted(errorDetail)
                        }
                    }

                    // Temporary rate limit - apply exponential backoff and retry
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = GeminiError.rateLimited
                    continue

                case 500, 502, 503, 504:
                    // Server error - retry with backoff
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = GeminiError.httpError(httpResponse.statusCode, "")
                    continue

                default:
                    // Parse error details for better debugging
                    var errorDetail = ""
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        errorDetail = message
                    }
                    throw GeminiError.httpError(httpResponse.statusCode, errorDetail)
                }

            } catch let error as GeminiError {
                throw error
            } catch {
                // Network error - retry with backoff
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    lastError = error
                    continue
                }
                throw error
            }
        }

        // All retries exhausted
        if lastError is GeminiError {
            throw lastError!
        }
        throw GeminiError.rateLimited
    }

    /// Enforce minimum interval between requests to avoid rate limiting
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

// MARK: - Request Models

struct GeminiRequestPayload: Encodable {
    let contents: [GeminiRequestContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiRequestContent: Encodable {
    let role: String
    let parts: [GeminiRequestPart]
}

struct GeminiRequestPart: Encodable {
    let text: String
}

struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let maxOutputTokens: Int
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case invalidAPIKey
    case httpError(Int, String = "")
    case noContent
    case rateLimited
    case quotaExhausted(String)
    case authenticationFailed(String)

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
        case .httpError(let code, let detail):
            if detail.isEmpty {
                return "Server error (HTTP \(code)). Please try again."
            }
            return "Error \(code): \(detail)"
        case .noContent:
            return "No response content from AI."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .quotaExhausted(let detail):
            if detail.isEmpty {
                return "Daily API quota exhausted. Try again tomorrow or upgrade your API plan."
            }
            return "API quota issue: \(detail)"
        case .authenticationFailed(let detail):
            return "Authentication failed: \(detail)"
        }
    }
}

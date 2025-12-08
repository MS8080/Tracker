import Foundation
import Security

// MARK: - Keychain Service (embedded for secure API key storage)

/// Secure storage service using iOS Keychain
private final class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.behaviortracker.credentials"

    private init() {}

    enum Key: String {
        case vertexAPIKey = "vertex_api_key"
    }

    func save(_ value: String, for key: Key) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try? delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    func delete(_ key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    func exists(_ key: Key) -> Bool {
        return get(key) != nil
    }
}

private enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode value for Keychain storage."
        case .saveFailed(let status):
            return "Failed to save to Keychain (error: \(status))."
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (error: \(status))."
        }
    }
}

// MARK: - Async Semaphore

/// Simple async semaphore to serialize API requests
actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int) {
        self.count = value
    }

    func wait() async {
        if count > 0 { // swiftlint:disable:this empty_count
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

/// Service for communicating with Google's Gemini AI via Vertex AI.
///
/// Handles API authentication, request serialization, rate limiting, and error handling
/// for Gemini API requests. Implements automatic retry with exponential backoff for
/// transient errors.
///
/// ## Configuration
/// ```swift
/// // Configure with API key (stored securely in Keychain)
/// try GeminiService.shared.configure(apiKey: "your-api-key")
///
/// // Check if configured
/// if GeminiService.shared.isConfigured {
///     let response = try await GeminiService.shared.generateContent(prompt: "Hello")
/// }
/// ```
///
/// ## Rate Limiting
/// The service implements:
/// - Minimum 2-second interval between requests
/// - Automatic retry with exponential backoff on 429 errors
/// - Per-entry cooldown to prevent duplicate analysis
///
/// ## Error Handling
/// All errors are thrown as `GeminiError` with descriptive messages suitable
/// for display to users.
class GeminiService {
    /// Shared singleton instance
    static let shared = GeminiService()

    // Vertex AI configuration
    private let model = "gemini-2.5-flash-lite"
    private let region = "europe-west1" // Belgium (better model availability)

    private var baseURL: String? {
        guard let apiKey = KeychainService.shared.get(.vertexAPIKey) else {
            return nil
        }
        return "https://\(region)-aiplatform.googleapis.com/v1/publishers/google/models/\(model):generateContent?key=\(apiKey)"
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

    /// Get or set the Vertex AI API key (stored securely in Keychain)
    var apiKey: String? {
        get { KeychainService.shared.get(.vertexAPIKey) }
        set {
            if let key = newValue {
                do {
                    try validateAPIKey(key)
                    try KeychainService.shared.save(key, for: .vertexAPIKey)
                } catch {
                    print("Failed to save API key: \(error)")
                }
            } else {
                try? KeychainService.shared.delete(.vertexAPIKey)
            }
        }
    }

    /// Check if the service is configured with a valid API key
    var isConfigured: Bool {
        return KeychainService.shared.exists(.vertexAPIKey)
    }

    /// Configure the service with an API key
    func configure(apiKey: String) throws {
        try validateAPIKey(apiKey)
        try KeychainService.shared.save(apiKey, for: .vertexAPIKey)
    }

    private func validateAPIKey(_ key: String) throws {
        try Validator(key, fieldName: "API key")
            .notEmpty()
            .minLength(10, message: "API key is too short")
            .maxLength(500, message: "API key is too long")
    }

    /// Sends a prompt to Gemini and returns the generated response.
    ///
    /// Automatically handles rate limiting, retries on transient errors,
    /// and serializes concurrent requests.
    ///
    /// - Parameter prompt: The text prompt to send to the AI
    /// - Returns: The AI-generated response text
    /// - Throws: `GeminiError` on configuration, network, or API errors
    func generateContent(prompt: String) async throws -> String {
        // Serialize requests - only one at a time
        await requestSemaphore.wait()
        defer { Task { await requestSemaphore.signal() } }

        // Check if API key is configured
        guard let urlString = baseURL else {
            throw GeminiError.noAPIKey
        }

        // Client-side rate limiting - wait if we made a request too recently
        await enforceMinRequestInterval()

        print("🔵 Gemini API URL: [configured]") // Don't log the actual URL with key

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
        if let error = lastError as? GeminiError {
            throw error
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

/// Errors that can occur during Gemini API operations.
///
/// All cases provide localized error descriptions suitable for displaying to users.
enum GeminiError: LocalizedError {
    /// No API key has been configured
    case noAPIKey
    /// The constructed API URL was invalid
    case invalidURL
    /// Server returned an unparseable response
    case invalidResponse
    /// The provided API key is invalid
    case invalidAPIKey
    /// HTTP error with status code and optional detail message
    case httpError(Int, String = "")
    /// AI returned empty response content
    case noContent
    /// Request was rate limited (429) - typically temporary
    case rateLimited
    /// Daily API quota has been exhausted
    case quotaExhausted(String)
    /// Authentication failed with the API
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

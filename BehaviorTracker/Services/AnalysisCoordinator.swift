import Foundation
import CoreData
import Combine

/// Centralized coordinator for journal entry analysis
/// Single source of truth for all analysis operations
@MainActor
final class AnalysisCoordinator: ObservableObject {
    static let shared = AnalysisCoordinator()

    // MARK: - Published State

    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var lastError: String?

    // MARK: - Private Properties

    private let extractionService = PatternExtractionService.shared
    private let patternRepository = PatternRepository.shared
    private let geminiService = GeminiService.shared

    private var pendingEntryIDs: Set<UUID> = []
    private var failedEntries: [UUID: Int] = [:] // ID -> retry count
    private let maxRetries = 3

    private var processingTask: Task<Void, Never>?

    private init() {}

    // MARK: - Public API

    /// Queue entry for background analysis (non-blocking, fire-and-forget)
    /// - Parameter entry: The journal entry to analyze
    func queueAnalysis(for entry: JournalEntry) {
        // Skip if already analyzed
        guard !entry.isAnalyzed else { return }

        // Skip if already pending
        guard !pendingEntryIDs.contains(entry.id) else { return }

        // Skip if recently analyzed (deduplication)
        guard !geminiService.wasRecentlyAnalyzed(entryID: entry.id) else { return }

        // Skip if not configured
        guard extractionService.isConfigured else { return }

        pendingEntryIDs.insert(entry.id)
        pendingCount = pendingEntryIDs.count

        // Launch background task
        Task.detached(priority: .utility) { [weak self] in
            await self?.processEntry(entry)
        }
    }

    /// Analyze immediately and wait for result (blocking)
    /// - Parameter entry: The journal entry to analyze
    /// - Throws: If analysis fails
    func analyzeNow(_ entry: JournalEntry) async throws {
        // Mark as processing
        isProcessing = true
        lastError = nil

        defer {
            isProcessing = false
        }

        // Mark to prevent duplicates
        geminiService.markAsAnalyzed(entryID: entry.id)

        try await performAnalysis(entry)
    }

    /// Retry all failed entries
    func retryFailed() {
        let failedIDs = Array(failedEntries.keys)
        failedEntries.removeAll()

        for entryID in failedIDs {
            if let entry = fetchEntry(id: entryID) {
                queueAnalysis(for: entry)
            }
        }
    }

    /// Process any unanalyzed entries (call on app launch or when coming online)
    func processUnanalyzedEntries() {
        let unanalyzed = patternRepository.fetchUnanalyzedEntries()

        for entry in unanalyzed.prefix(10) { // Limit to prevent overload
            queueAnalysis(for: entry)
        }
    }

    /// Clear error state
    func clearError() {
        lastError = nil
    }

    /// Check if an entry is pending analysis
    func isPending(_ entryID: UUID) -> Bool {
        pendingEntryIDs.contains(entryID)
    }

    /// Get count of failed entries
    var failedCount: Int {
        failedEntries.count
    }

    // MARK: - Private Methods

    private func processEntry(_ entry: JournalEntry) async {
        do {
            try await performAnalysis(entry)

            // Success - remove from pending and failed
            await MainActor.run {
                pendingEntryIDs.remove(entry.id)
                failedEntries.removeValue(forKey: entry.id)
                pendingCount = pendingEntryIDs.count
            }
        } catch {
            await handleFailure(entry: entry, error: error)
        }
    }

    private func performAnalysis(_ entry: JournalEntry) async throws {
        // 1. Extract patterns via AI
        let result = try await extractionService.extractPatterns(from: entry.content)

        // 2. Persist to Core Data via repository
        try await patternRepository.saveExtractionResult(result, for: entry)
    }

    private func handleFailure(entry: JournalEntry, error: Error) async {
        let retryCount = (failedEntries[entry.id] ?? 0) + 1

        await MainActor.run {
            pendingEntryIDs.remove(entry.id)
            pendingCount = pendingEntryIDs.count

            if retryCount < maxRetries {
                failedEntries[entry.id] = retryCount

                // Schedule retry with exponential backoff
                let delay = Double(retryCount * retryCount) * 2.0

                Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await self.processEntry(entry)
                }
            } else {
                // Max retries exceeded
                failedEntries[entry.id] = retryCount
                lastError = "Analysis failed after \(maxRetries) attempts: \(error.localizedDescription)"
            }
        }
    }

    private func fetchEntry(id: UUID) -> JournalEntry? {
        let context = DataController.shared.container.viewContext
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

// MARK: - Convenience Extension

extension AnalysisCoordinator {
    /// Quick check if analysis is available
    var isConfigured: Bool {
        extractionService.isConfigured
    }

    /// Status summary for UI
    var statusSummary: String {
        if isProcessing {
            return "Analyzing..."
        } else if pendingCount > 0 {
            return "Analyzing \(pendingCount) entries..."
        } else if failedCount > 0 {
            return "\(failedCount) failed"
        } else {
            return ""
        }
    }
}

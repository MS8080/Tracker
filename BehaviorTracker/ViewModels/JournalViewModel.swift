import SwiftUI
import CoreData
import Combine

/// Wrapper struct to display demo journal entries without CoreData
struct DemoJournalEntryWrapper: Identifiable {
    let id: UUID
    let title: String?
    let content: String
    let mood: Int16
    let timestamp: Date
    let isFavorite: Bool
    let isAnalyzed: Bool
    let analysisSummary: String?
    let overallIntensity: Int16

    init(from demo: DemoModeService.DemoJournalEntry) {
        self.id = demo.id
        self.title = demo.title
        self.content = demo.content
        self.mood = demo.mood
        self.timestamp = demo.timestamp
        self.isFavorite = demo.isFavorite
        self.isAnalyzed = demo.isAnalyzed
        self.analysisSummary = demo.analysisSummary
        self.overallIntensity = demo.overallIntensity
    }

    var preview: String {
        String(content.prefix(100))
    }
}

@MainActor
class JournalViewModel: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var demoEntries: [DemoJournalEntryWrapper] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isAnalyzing = false
    @Published var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                resetAndLoad()
            } else {
                searchEntries()
            }
        }
    }
    @Published var showFavoritesOnly: Bool = false {
        didSet {
            resetAndLoad()
        }
    }
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var hasMoreEntries: Bool = true
    @Published var totalEntryCount: Int = 0

    private let dataController = DataController.shared
    private let analysisCoordinator = AnalysisCoordinator.shared
    private let demoService = DemoModeService.shared
    private var cancellables = Set<AnyCancellable>()

    // Pagination settings
    private let pageSize = 30
    private var currentOffset = 0

    /// Whether we're currently in demo mode
    var isDemoMode: Bool {
        demoService.isEnabled
    }

    init() {
        loadJournalEntries()
        observeDemoModeChanges()
        observeJournalChanges()
    }

    private func observeDemoModeChanges() {
        NotificationCenter.default.publisher(for: .demoModeChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetAndLoad()
            }
            .store(in: &cancellables)
    }

    private func observeJournalChanges() {
        // Observe when journal entries are created
        NotificationCenter.default.publisher(for: .journalEntryCreated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetAndLoad()
            }
            .store(in: &cancellables)
        
        // Observe when journal entries are updated
        NotificationCenter.default.publisher(for: .journalEntryUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadJournalEntries()
            }
            .store(in: &cancellables)
        
        // Observe when journal entries are deleted
        NotificationCenter.default.publisher(for: .journalEntryDeleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadJournalEntries()
            }
            .store(in: &cancellables)
    }

    /// Reset pagination and load fresh
    func resetAndLoad() {
        currentOffset = 0
        hasMoreEntries = true
        journalEntries = []
        loadJournalEntries()
    }

    func loadJournalEntries() {
        // Demo mode: load demo entries
        if demoService.isEnabled {
            loadDemoEntries()
            return
        }

        Task { [weak self] in
            guard let self else { return }
            isLoading = currentOffset == 0
            isLoadingMore = currentOffset > 0

            // Get total count for UI
            if currentOffset == 0 {
                totalEntryCount = await dataController.countJournalEntries(favoritesOnly: showFavoritesOnly)
            }

            let newEntries = await dataController.fetchJournalEntries(
                favoritesOnly: showFavoritesOnly,
                limit: pageSize,
                offset: currentOffset
            )

            if currentOffset == 0 {
                journalEntries = newEntries
            } else {
                journalEntries.append(contentsOf: newEntries)
            }

            // Check if there are more entries to load
            hasMoreEntries = newEntries.count == pageSize

            isLoading = false
            isLoadingMore = false
        }
    }

    private func loadDemoEntries() {
        isLoading = true

        var entries = demoService.demoJournalEntries
        if showFavoritesOnly {
            entries = entries.filter { $0.isFavorite }
        }
        if !searchQuery.isEmpty {
            entries = entries.filter {
                $0.content.localizedCaseInsensitiveContains(searchQuery) ||
                ($0.title?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        demoEntries = entries.map { DemoJournalEntryWrapper(from: $0) }
        journalEntries = [] // Clear real entries
        totalEntryCount = demoEntries.count
        hasMoreEntries = false

        isLoading = false
    }

    /// Load next page of entries
    func loadMoreIfNeeded(currentEntry: JournalEntry) {
        // Trigger load when reaching the last 5 entries
        guard let index = journalEntries.firstIndex(where: { $0.id == currentEntry.id }) else { return }

        if index >= journalEntries.count - 5 && hasMoreEntries && !isLoadingMore && !isLoading {
            currentOffset += pageSize
            loadJournalEntries()
        }
    }

    func searchEntries() {
        Task { [weak self] in
            guard let self else { return }
            isLoading = true
            hasMoreEntries = false // Search doesn't paginate
            journalEntries = await dataController.searchJournalEntries(query: searchQuery)
            isLoading = false
        }
    }

    /// Refresh entries (pull-to-refresh)
    func refresh() async {
        currentOffset = 0
        hasMoreEntries = true
        totalEntryCount = await dataController.countJournalEntries(favoritesOnly: showFavoritesOnly)
        journalEntries = await dataController.fetchJournalEntries(
            favoritesOnly: showFavoritesOnly,
            limit: pageSize,
            offset: 0
        )
        hasMoreEntries = journalEntries.count == pageSize
    }

    func createEntry(
        title: String? = nil,
        content: String,
        mood: Int16 = 0,
        audioFileName: String? = nil,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) -> Bool {
        do {
            let entry = try dataController.createJournalEntry(
                title: title,
                content: content,
                mood: mood,
                audioFileName: audioFileName,
                relatedPatternEntry: relatedPatternEntry,
                relatedMedicationLog: relatedMedicationLog
            )

            // Reset pagination and reload to show new entry at top
            resetAndLoad()

            // Queue for background analysis via coordinator
            analysisCoordinator.queueAnalysis(for: entry)

            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    // MARK: - Pattern Extraction

    /// Analyze a journal entry to extract patterns (via coordinator)
    func analyzeEntry(_ entry: JournalEntry) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            try await analysisCoordinator.analyzeNow(entry)
            loadJournalEntries()
        } catch {
            print("Failed to analyze journal entry: \(error.localizedDescription)")
        }
    }

    func updateEntry(_ entry: JournalEntry, reanalyze: Bool = true) {
        dataController.updateJournalEntry(entry)
        
        // Notify observers
        NotificationCenter.default.post(name: .journalEntryUpdated, object: entry)
        
        loadJournalEntries()

        // Re-analyze if content was changed
        if reanalyze && entry.isAnalyzed {
            Task { [weak self] in
                await self?.clearAndReanalyze(entry)
            }
        }
    }

    /// Clear existing patterns and re-analyze the entry
    private func clearAndReanalyze(_ entry: JournalEntry) async {
        do {
            // Clear analysis via repository
            try PatternRepository.shared.clearAnalysis(for: entry)

            // Re-analyze via coordinator
            try await analysisCoordinator.analyzeNow(entry)
            loadJournalEntries()
        } catch {
            print("Failed to re-analyze entry: \(error.localizedDescription)")
        }
    }

    func deleteEntry(_ entry: JournalEntry) {
        // Remove from local array first to prevent SwiftUI from accessing deleted object
        let entryId = entry.id
        journalEntries.removeAll { $0.id == entryId }

        // Then delete from Core Data
        dataController.deleteJournalEntry(entry)
        
        // Notify observers
        NotificationCenter.default.post(name: .journalEntryDeleted, object: nil)
    }

    func toggleFavorite(_ entry: JournalEntry) {
        entry.isFavorite.toggle()
        dataController.updateJournalEntry(entry)
        
        // Notify observers
        NotificationCenter.default.post(name: .journalEntryUpdated, object: entry)
        
        loadJournalEntries()
    }

    func getEntriesByDateRange(startDate: Date, endDate: Date) async -> [JournalEntry] {
        return await dataController.fetchJournalEntries(startDate: startDate, endDate: endDate)
    }

    func getEntriesGroupedByDate() -> [Date: [JournalEntry]] {
        let calendar = Calendar.current
        var grouped: [Date: [JournalEntry]] = [:]

        for entry in journalEntries {
            let startOfDay = calendar.startOfDay(for: entry.timestamp)
            if grouped[startOfDay] != nil {
                grouped[startOfDay]?.append(entry)
            } else {
                grouped[startOfDay] = [entry]
            }
        }

        return grouped
    }
}

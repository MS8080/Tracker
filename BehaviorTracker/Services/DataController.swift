@preconcurrency import CoreData
import Foundation
import WidgetKit

/// Core Data stack manager and primary data persistence layer.
///
/// Manages the Core Data persistent container, handles iCloud sync configuration,
/// and provides fetch/save operations for all entities. Entity-specific operations
/// are delegated to specialized repositories.
///
/// ## Usage
/// ```swift
/// // Access the shared instance
/// let controller = DataController.shared
///
/// // Save changes
/// controller.save()
///
/// // Fetch pattern entries
/// let entries = await controller.fetchPatternEntriesAsync(
///     startDate: startDate,
///     endDate: endDate
/// )
/// ```
///
/// ## Testing
/// For unit tests, create an in-memory instance to avoid persisting test data:
/// ```swift
/// let testController = DataController(inMemory: true)
/// DataController.shared = testController
/// ```
///
/// ## Repositories
/// Most CRUD operations should go through specialized repositories:
/// - `JournalRepository` for journal entries
/// - `GoalRepository` for life goals
/// - `StruggleRepository` for struggles
/// - `WishlistRepository` for wishlist items
class DataController: ObservableObject, @unchecked Sendable {
    /// Shared singleton instance. Can be replaced for testing.
    static var shared = DataController()

    // MARK: - iCloud Sync Configuration
    static let iCloudSyncEnabled = false

    let container: NSPersistentContainer

    @Published var hasCriticalError = false
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .localOnly

    enum SyncStatus {
        case localOnly
        case syncing
        case synced
        case error(String)
    }

    var isSyncEnabled: Bool {
        DataController.iCloudSyncEnabled
    }

    // MARK: - Error Types

    enum DataError: LocalizedError {
        case saveFailed(Error)
        case fetchFailed(Error)
        case entityNotFound(String)

        var errorDescription: String? {
            switch self {
            case .saveFailed(let error):
                return "Failed to save data: \(error.localizedDescription)"
            case .fetchFailed(let error):
                return "Failed to load data: \(error.localizedDescription)"
            case .entityNotFound(let name):
                return "Could not find \(name)"
            }
        }
    }

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        if DataController.iCloudSyncEnabled {
            container = NSPersistentCloudKitContainer(name: "BehaviorTrackerModel")
        } else {
            container = NSPersistentContainer(name: "BehaviorTrackerModel")
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let description = container.persistentStoreDescriptions.first {
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true

                if DataController.iCloudSyncEnabled {
                    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.com.behaviortracker.BehaviorTracker"
                    )
                    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                }
            }
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self?.hasCriticalError = true
                    self?.errorMessage = "Failed to load data storage: \(error.localizedDescription)"
                    self?.syncStatus = .error(error.localizedDescription)
                }
            } else {
                DispatchQueue.main.async {
                    self?.syncStatus = DataController.iCloudSyncEnabled ? .synced : .localOnly
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        if DataController.iCloudSyncEnabled {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRemoteChange),
                name: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator
            )
        }
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.syncStatus = .synced
        }
    }

    // MARK: - Save

    func saveOrThrow() throws {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw DataError.saveFailed(error)
            }
        }
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Pattern Entry (delegates to PatternRepository)

    func createPatternEntry(
        patternType: PatternType,
        intensity: Int16 = 0,
        duration: Int32 = 0,
        contextNotes: String? = nil,
        specificDetails: String? = nil,
        contributingFactors: [ContributingFactor] = []
    ) async throws -> PatternEntry {
        try await PatternRepository.shared.create(
            patternType: patternType,
            intensity: intensity,
            duration: duration,
            contextNotes: contextNotes,
            specificDetails: specificDetails,
            contributingFactors: contributingFactors
        )
    }

    func deletePatternEntry(_ entry: PatternEntry) {
        PatternRepository.shared.delete(entry)
    }

    @MainActor
    func fetchPatternEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) -> [PatternEntry] {
        PatternRepository.shared.fetchSync(startDate: startDate, endDate: endDate, category: category, limit: limit)
    }

    @MainActor
    func fetchPatternEntriesAsync(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) async -> [PatternEntry] {
        await PatternRepository.shared.fetch(startDate: startDate, endDate: endDate, category: category, limit: limit)
    }

    func fetchPatternEntriesOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) throws -> [PatternEntry] {
        try PatternRepository.shared.fetchOrThrow(startDate: startDate, endDate: endDate, category: category, limit: limit)
    }

    // MARK: - User Preferences (delegates to UserProfileRepository)

    func getUserPreferences() -> UserPreferences {
        UserProfileRepository.shared.getPreferences()
    }

    func updateStreak() {
        UserProfileRepository.shared.updateStreak()
    }

    // MARK: - Medication (delegates to MedicationRepository)

    func createMedication(
        name: String,
        dosage: String? = nil,
        frequency: String,
        notes: String? = nil
    ) throws -> Medication {
        try MedicationRepository.shared.createMedication(name: name, dosage: dosage, frequency: frequency, notes: notes)
    }

    func fetchMedications(activeOnly: Bool = true) -> [Medication] {
        MedicationRepository.shared.fetchMedications(activeOnly: activeOnly)
    }

    func fetchMedicationsOrThrow(activeOnly: Bool = true) throws -> [Medication] {
        try MedicationRepository.shared.fetchMedicationsOrThrow(activeOnly: activeOnly)
    }

    func updateMedication(_ medication: Medication) {
        MedicationRepository.shared.updateMedication(medication)
    }

    func deleteMedication(_ medication: Medication) {
        MedicationRepository.shared.deleteMedication(medication)
    }

    // MARK: - Medication Log (delegates to MedicationRepository)

    func createMedicationLog(
        medication: Medication,
        taken: Bool = true,
        skippedReason: String? = nil,
        sideEffects: String? = nil,
        effectiveness: Int16 = 0,
        mood: Int16 = 0,
        energyLevel: Int16 = 0,
        notes: String? = nil
    ) throws -> MedicationLog {
        try MedicationRepository.shared.createLog(
            medication: medication,
            taken: taken,
            skippedReason: skippedReason,
            sideEffects: sideEffects,
            effectiveness: effectiveness,
            mood: mood,
            energyLevel: energyLevel,
            notes: notes
        )
    }

    func fetchMedicationLogs(
        startDate: Date? = nil,
        endDate: Date? = nil,
        medication: Medication? = nil
    ) -> [MedicationLog] {
        MedicationRepository.shared.fetchLogs(startDate: startDate, endDate: endDate, medication: medication)
    }

    func fetchMedicationLogsOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        medication: Medication? = nil
    ) throws -> [MedicationLog] {
        try MedicationRepository.shared.fetchLogsOrThrow(startDate: startDate, endDate: endDate, medication: medication)
    }

    func deleteMedicationLog(_ log: MedicationLog) {
        MedicationRepository.shared.deleteLog(log)
    }

    func getTodaysMedicationLogs() -> [MedicationLog] {
        MedicationRepository.shared.getTodaysLogs()
    }

    // MARK: - Journal Entry (delegates to JournalRepository)

    func createJournalEntry(
        title: String? = nil,
        content: String,
        mood: Int16 = 0,
        audioFileName: String? = nil,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) throws -> JournalEntry {
        try JournalRepository.shared.create(
            title: title,
            content: content,
            mood: mood,
            audioFileName: audioFileName,
            relatedPatternEntry: relatedPatternEntry,
            relatedMedicationLog: relatedMedicationLog
        )
    }

    @MainActor
    func fetchJournalEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false,
        limit: Int? = nil,
        offset: Int = 0
    ) async -> [JournalEntry] {
        await JournalRepository.shared.fetch(
            startDate: startDate,
            endDate: endDate,
            favoritesOnly: favoritesOnly,
            limit: limit,
            offset: offset
        )
    }

    @MainActor
    func countJournalEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) async -> Int {
        await JournalRepository.shared.count(startDate: startDate, endDate: endDate, favoritesOnly: favoritesOnly)
    }

    @MainActor
    func fetchJournalEntriesSync(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) -> [JournalEntry] {
        JournalRepository.shared.fetchSync(startDate: startDate, endDate: endDate, favoritesOnly: favoritesOnly)
    }

    func updateJournalEntry(_ entry: JournalEntry) {
        JournalRepository.shared.update(entry)
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        JournalRepository.shared.delete(entry)
    }

    @MainActor
    func searchJournalEntries(query: String) async -> [JournalEntry] {
        await JournalRepository.shared.search(query: query)
    }

    @MainActor
    func searchJournalEntriesSync(query: String) -> [JournalEntry] {
        JournalRepository.shared.searchSync(query: query)
    }

    // MARK: - User Profile (delegates to UserProfileRepository)

    func createUserProfile(
        name: String,
        email: String? = nil,
        dateOfBirth: Date? = nil
    ) -> UserProfile {
        UserProfileRepository.shared.createProfile(name: name, email: email, dateOfBirth: dateOfBirth)
    }

    func fetchUserProfiles() -> [UserProfile] {
        UserProfileRepository.shared.fetchProfiles()
    }

    func fetchUserProfilesOrThrow() throws -> [UserProfile] {
        try UserProfileRepository.shared.fetchProfilesOrThrow()
    }

    func getCurrentUserProfile() -> UserProfile? {
        UserProfileRepository.shared.getCurrentProfile()
    }

    func getCurrentUserProfileOrThrow() throws -> UserProfile? {
        try UserProfileRepository.shared.getCurrentProfileOrThrow()
    }

    func getOrCreateUserProfile() -> UserProfile {
        UserProfileRepository.shared.getOrCreateProfile()
    }

    func updateUserProfile(_ profile: UserProfile) {
        UserProfileRepository.shared.updateProfile(profile)
    }

    func deleteUserProfile(_ profile: UserProfile) {
        UserProfileRepository.shared.deleteProfile(profile)
    }

    // MARK: - Setup Items (delegates to SetupItemRepository)

    func createSetupItem(
        name: String,
        category: SetupItemCategory,
        effectTags: [String] = [],
        icon: String? = nil,
        notes: String? = nil,
        startDate: Date? = nil
    ) throws -> SetupItem {
        try SetupItemRepository.shared.create(
            name: name,
            category: category,
            effectTags: effectTags,
            icon: icon,
            notes: notes,
            startDate: startDate
        )
    }

    func fetchSetupItems(activeOnly: Bool = true, category: SetupItemCategory? = nil) -> [SetupItem] {
        SetupItemRepository.shared.fetch(activeOnly: activeOnly, category: category)
    }

    func fetchSetupItemsOrThrow(activeOnly: Bool = true, category: SetupItemCategory? = nil) throws -> [SetupItem] {
        try SetupItemRepository.shared.fetchOrThrow(activeOnly: activeOnly, category: category)
    }

    func updateSetupItem(_ item: SetupItem) {
        SetupItemRepository.shared.update(item)
    }

    func deleteSetupItem(_ item: SetupItem) {
        SetupItemRepository.shared.delete(item)
    }

    func toggleSetupItemActive(_ item: SetupItem) {
        SetupItemRepository.shared.toggleActive(item)
    }

    func fetchSetupItemsGrouped(activeOnly: Bool = true) -> [SetupItemCategory: [SetupItem]] {
        SetupItemRepository.shared.fetchGrouped(activeOnly: activeOnly)
    }

    // MARK: - Widget Integration

    private let appGroupIdentifier = "group.com.behaviortracker.shared"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    @MainActor
    func syncWidgetData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            return
        }

        let todayEntries = fetchPatternEntries(startDate: today, endDate: tomorrow)
        let todayCount = todayEntries.count

        let preferences = getUserPreferences()
        let streakCount = Int(preferences.streakCount)

        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) else {
            return
        }
        let recentEntries = fetchPatternEntries(startDate: thirtyDaysAgo)
        let patternCounts = Dictionary(grouping: recentEntries) { $0.patternType }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        var quickPatterns: [[String: String]] = []
        for (patternType, _) in patternCounts.prefix(6) {
            if let patternTypeEnum = PatternType(rawValue: patternType) {
                let pattern: [String: String] = [
                    "name": patternType,
                    "patternType": patternType,
                    "category": patternTypeEnum.category.rawValue,
                    "icon": patternTypeEnum.category.icon,
                    "colorHex": patternTypeEnum.category.color.toHex() ?? "AF52DE"
                ]
                quickPatterns.append(pattern)
            }
        }

        if quickPatterns.isEmpty {
            quickPatterns = [
                ["name": "Sensory State", "patternType": "Sensory State", "category": "Sensory", "icon": "eye", "colorHex": "AF52DE"],
                ["name": "Overwhelm", "patternType": "Overwhelm", "category": "Regulation", "icon": "waveform.path", "colorHex": "FF3B30"],
                ["name": "Stimming", "patternType": "Stimming", "category": "Regulation", "icon": "hands.sparkles", "colorHex": "FF9500"],
                ["name": "Masking", "patternType": "Masking", "category": "Social", "icon": "theatermasks", "colorHex": "34C759"]
            ]
        }

        sharedDefaults?.set(todayCount, forKey: "todayLogCount")
        sharedDefaults?.set(today, forKey: "todayLogDate")
        sharedDefaults?.set(streakCount, forKey: "streakCount")

        if let patternsData = try? JSONSerialization.data(withJSONObject: quickPatterns) {
            sharedDefaults?.set(patternsData, forKey: "quickLogPatterns")
        }

        sharedDefaults?.set(Date(), forKey: "lastUpdateDate")
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    func processPendingWidgetLogs() async {
        guard let data = sharedDefaults?.data(forKey: "pendingPatternLogs"),
              let logs = try? JSONDecoder().decode([PendingPatternLog].self, from: data),
              !logs.isEmpty else {
            return
        }

        for log in logs {
            if let patternType = PatternType(rawValue: log.patternType) {
                do {
                    _ = try await createPatternEntry(
                        patternType: patternType,
                        intensity: 3,
                        contextNotes: "Logged from widget"
                    )
                } catch {
                    AppLogger.data.error("Failed to create pattern entry from widget", error: error)
                }
            }
        }

        sharedDefaults?.removeObject(forKey: "pendingPatternLogs")
        updateStreak()
        syncWidgetData()
    }

    private struct PendingPatternLog: Codable {
        let id: String
        let patternName: String
        let patternType: String
        let category: String
        let timestamp: Date
    }
}

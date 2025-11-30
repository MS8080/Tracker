import CoreData
import Foundation
import WidgetKit

class DataController: ObservableObject {
    static let shared = DataController()

    // MARK: - iCloud Sync Configuration
    // Set this to true when you have an Apple Developer Program membership ($99/year)
    // Then enable iCloud capability in Xcode for both iOS and macOS targets
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

    init(inMemory: Bool = false) {
        // Use CloudKit container only if sync is enabled
        if DataController.iCloudSyncEnabled {
            container = NSPersistentCloudKitContainer(name: "BehaviorTrackerModel")
        } else {
            container = NSPersistentContainer(name: "BehaviorTrackerModel")
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if let description = container.persistentStoreDescriptions.first {
                // Enable lightweight migration
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true

                // Configure CloudKit sync only if enabled
                if DataController.iCloudSyncEnabled {
                    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.com.behaviortracker.BehaviorTracker"
                    )
                    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                }
            }
        }

        container.loadPersistentStores { [weak self] storeDescription, error in
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

        // Listen for remote changes only if sync is enabled
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

    /// Save with error propagation - use when caller needs to know about failures
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

    /// Save silently - logs error but doesn't throw (for non-critical updates)
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Log error for debugging but don't crash
                print("DataController save error: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }


    func createPatternEntry(
        patternType: PatternType,
        intensity: Int16 = 0,
        duration: Int32 = 0,
        contextNotes: String? = nil,
        specificDetails: String? = nil,
        contributingFactors: [ContributingFactor] = []
    ) throws -> PatternEntry {
        // Validate intensity
        try Validator(intensity, fieldName: "Intensity")
            .inRange(0...5)

        // Validate duration (in minutes, reasonable max is 24 hours = 1440 minutes)
        try Validator(duration, fieldName: "Duration")
            .inRange(0...1440)

        // Validate context notes if provided
        try Validator(contextNotes, fieldName: "Context notes")
            .ifPresent { validator in
                try validator.maxLength(1000)
            }

        // Validate specific details if provided
        try Validator(specificDetails, fieldName: "Specific details")
            .ifPresent { validator in
                try validator.maxLength(1000)
            }

        // Validate contributing factors count
        try Validator(contributingFactors, fieldName: "Contributing factors")
            .maxCount(20, message: "You can select up to 20 contributing factors")

        let entry = NSEntityDescription.insertNewObject(forEntityName: "PatternEntry", into: container.viewContext) as! PatternEntry
        entry.configure(
            patternType: patternType,
            intensity: intensity,
            duration: duration,
            contextNotes: contextNotes?.trimmingCharacters(in: .whitespacesAndNewlines),
            specificDetails: specificDetails?.trimmingCharacters(in: .whitespacesAndNewlines),
            contributingFactors: contributingFactors
        )
        save()

        // Update widget data after logging
        syncWidgetData()

        return entry
    }

    func deletePatternEntry(_ entry: PatternEntry) {
        container.viewContext.delete(entry)
        save()
    }

    func fetchPatternEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) -> [PatternEntry] {
        do {
            return try fetchPatternEntriesOrThrow(startDate: startDate, endDate: endDate, category: category, limit: limit)
        } catch {
            print("Failed to fetch pattern entries: \(error.localizedDescription)")
            return []
        }
    }

    func fetchPatternEntriesOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) throws -> [PatternEntry] {
        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        var predicates: [NSPredicate] = []

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        if let limit = limit {
            request.fetchLimit = limit
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    func getUserPreferences() -> UserPreferences {
        let request = NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
        request.fetchLimit = 1

        do {
            let results = try container.viewContext.fetch(request)
            if let preferences = results.first {
                return preferences
            } else {
                let newPreferences = NSEntityDescription.insertNewObject(forEntityName: "UserPreferences", into: container.viewContext) as! UserPreferences
                save()
                return newPreferences
            }
        } catch {
            print("Failed to fetch preferences: \(error.localizedDescription)")
            let newPreferences = NSEntityDescription.insertNewObject(forEntityName: "UserPreferences", into: container.viewContext) as! UserPreferences
            save()
            return newPreferences
        }
    }

    func updateStreak() {
        let preferences = getUserPreferences()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]
        request.fetchLimit = 1

        do {
            let results = try container.viewContext.fetch(request)
            if let lastEntry = results.first {
                let lastEntryDate = calendar.startOfDay(for: lastEntry.timestamp)
                let daysDifference = calendar.dateComponents([.day], from: lastEntryDate, to: today).day ?? 0

                if daysDifference == 0 {
                    return
                } else if daysDifference == 1 {
                    preferences.streakCount += 1
                } else {
                    preferences.streakCount = 1
                }
            } else {
                preferences.streakCount = 1
            }
            save()
        } catch {
            print("Failed to update streak: \(error.localizedDescription)")
        }
    }

    // MARK: - Medication Management

    func createMedication(
        name: String,
        dosage: String? = nil,
        frequency: String,
        notes: String? = nil
    ) throws -> Medication {
        // Validate medication name
        try Validator(name, fieldName: "Medication name")
            .notEmpty()
            .maxLength(100)

        // Validate dosage if provided
        try Validator(dosage, fieldName: "Dosage")
            .ifPresent { validator in
                try validator.maxLength(50)
            }

        // Validate frequency
        try Validator(frequency, fieldName: "Frequency")
            .notEmpty()
            .maxLength(50)

        // Validate notes if provided
        try Validator(notes, fieldName: "Notes")
            .ifPresent { validator in
                try validator.maxLength(500)
            }

        let medication = NSEntityDescription.insertNewObject(forEntityName: "Medication", into: container.viewContext) as! Medication
        medication.configure(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage: dosage?.trimmingCharacters(in: .whitespacesAndNewlines),
            frequency: frequency.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        save()
        return medication
    }

    func fetchMedications(activeOnly: Bool = true) -> [Medication] {
        do {
            return try fetchMedicationsOrThrow(activeOnly: activeOnly)
        } catch {
            print("Failed to fetch medications: \(error.localizedDescription)")
            return []
        }
    }

    func fetchMedicationsOrThrow(activeOnly: Bool = true) throws -> [Medication] {
        let request = NSFetchRequest<Medication>(entityName: "Medication")

        if activeOnly {
            request.predicate = NSPredicate(format: "isActive == true")
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.name, ascending: true)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    func updateMedication(_ medication: Medication) {
        save()
    }

    func deleteMedication(_ medication: Medication) {
        container.viewContext.delete(medication)
        save()
    }

    // MARK: - Medication Log Management

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
        // Validate effectiveness
        try Validator(effectiveness, fieldName: "Effectiveness")
            .inRange(0...5)

        // Validate mood
        try Validator(mood, fieldName: "Mood")
            .inRange(0...5)

        // Validate energy level
        try Validator(energyLevel, fieldName: "Energy level")
            .inRange(0...5)

        // Validate optional fields
        try Validator(skippedReason, fieldName: "Skipped reason")
            .ifPresent { try $0.maxLength(200) }

        try Validator(sideEffects, fieldName: "Side effects")
            .ifPresent { try $0.maxLength(500) }

        try Validator(notes, fieldName: "Notes")
            .ifPresent { try $0.maxLength(500) }

        let log = NSEntityDescription.insertNewObject(forEntityName: "MedicationLog", into: container.viewContext) as! MedicationLog
        log.configure(
            medication: medication,
            taken: taken,
            skippedReason: skippedReason?.trimmingCharacters(in: .whitespacesAndNewlines),
            sideEffects: sideEffects?.trimmingCharacters(in: .whitespacesAndNewlines),
            effectiveness: effectiveness,
            mood: mood,
            energyLevel: energyLevel,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        save()
        return log
    }

    func fetchMedicationLogs(
        startDate: Date? = nil,
        endDate: Date? = nil,
        medication: Medication? = nil
    ) -> [MedicationLog] {
        do {
            return try fetchMedicationLogsOrThrow(startDate: startDate, endDate: endDate, medication: medication)
        } catch {
            print("Failed to fetch medication logs: \(error.localizedDescription)")
            return []
        }
    }

    func fetchMedicationLogsOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        medication: Medication? = nil
    ) throws -> [MedicationLog] {
        let request = NSFetchRequest<MedicationLog>(entityName: "MedicationLog")
        var predicates: [NSPredicate] = []

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        if let medication = medication {
            predicates.append(NSPredicate(format: "medication == %@", medication))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationLog.timestamp, ascending: false)]

        // Prefetch the medication relationship to avoid faulting issues
        request.relationshipKeyPathsForPrefetching = ["medication"]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    func deleteMedicationLog(_ log: MedicationLog) {
        container.viewContext.delete(log)
        save()
    }

    func getTodaysMedicationLogs() -> [MedicationLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return fetchMedicationLogs(startDate: startOfDay, endDate: endOfDay)
    }

    // MARK: - Journal Entry Management

    func createJournalEntry(
        title: String? = nil,
        content: String,
        mood: Int16 = 0,
        audioFileName: String? = nil,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) throws -> JournalEntry {
        // Validate content
        try Validator(content, fieldName: "Journal content")
            .notEmpty()
            .maxLength(50000)

        // Validate title if provided
        try Validator(title, fieldName: "Journal title")
            .ifPresent { validator in
                try validator.maxLength(200)
                try validator.noSpecialCharacters()
            }

        // Validate mood
        try Validator(mood, fieldName: "Mood")
            .inRange(0...5)

        // Validate audio file name if provided
        try Validator(audioFileName, fieldName: "Audio file name")
            .ifPresent { validator in
                try validator.maxLength(255)
                try validator.matches(pattern: "^[a-zA-Z0-9_.-]+$", message: "Audio file name contains invalid characters")
            }

        let entry = NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: container.viewContext) as! JournalEntry
        entry.configure(
            title: title?.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: mood,
            relatedPatternEntry: relatedPatternEntry,
            relatedMedicationLog: relatedMedicationLog
        )
        entry.audioFileName = audioFileName
        save()
        return entry
    }

    func fetchJournalEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) -> [JournalEntry] {
        do {
            return try fetchJournalEntriesOrThrow(startDate: startDate, endDate: endDate, favoritesOnly: favoritesOnly)
        } catch {
            print("Failed to fetch journal entries: \(error.localizedDescription)")
            return []
        }
    }

    func fetchJournalEntriesOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) throws -> [JournalEntry] {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        var predicates: [NSPredicate] = []

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        if favoritesOnly {
            predicates.append(NSPredicate(format: "isFavorite == true"))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    func updateJournalEntry(_ entry: JournalEntry) {
        save()
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        container.viewContext.delete(entry)
        save()
    }

    func searchJournalEntries(query: String) -> [JournalEntry] {
        do {
            return try searchJournalEntriesOrThrow(query: query)
        } catch {
            print("Failed to search journal entries: \(error.localizedDescription)")
            return []
        }
    }

    func searchJournalEntriesOrThrow(query: String) throws -> [JournalEntry] {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")

        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", query)

        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    // MARK: - User Profile Management

    func createUserProfile(
        name: String,
        email: String? = nil,
        dateOfBirth: Date? = nil
    ) -> UserProfile {
        let profile = NSEntityDescription.insertNewObject(forEntityName: "UserProfile", into: container.viewContext) as! UserProfile
        profile.name = name
        profile.email = email
        profile.dateOfBirth = dateOfBirth
        save()
        return profile
    }

    func fetchUserProfiles() -> [UserProfile] {
        do {
            return try fetchUserProfilesOrThrow()
        } catch {
            print("Failed to fetch user profiles: \(error.localizedDescription)")
            return []
        }
    }

    func fetchUserProfilesOrThrow() throws -> [UserProfile] {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.name, ascending: true)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    func getCurrentUserProfile() -> UserProfile? {
        do {
            return try getCurrentUserProfileOrThrow()
        } catch {
            print("Failed to fetch current user profile: \(error.localizedDescription)")
            return nil
        }
    }

    func getCurrentUserProfileOrThrow() throws -> UserProfile? {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: true)]

        do {
            return try container.viewContext.fetch(request).first
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    func getOrCreateUserProfile() -> UserProfile {
        if let existing = getCurrentUserProfile() {
            return existing
        }
        return createUserProfile(name: "User")
    }

    func updateUserProfile(_ profile: UserProfile) {
        profile.updatedAt = Date()
        save()
    }

    func deleteUserProfile(_ profile: UserProfile) {
        container.viewContext.delete(profile)
        save()
    }

    // MARK: - Widget Integration

    /// App Group identifier for sharing data with widgets
    private let appGroupIdentifier = "group.com.behaviortracker.shared"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    /// Sync data to widget after any changes
    func syncWidgetData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Get today's entry count
        let todayEntries = fetchPatternEntries(startDate: today, endDate: tomorrow)
        let todayCount = todayEntries.count

        // Get streak
        let preferences = getUserPreferences()
        let streakCount = Int(preferences.streakCount)

        // Get favorite patterns (most logged in last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recentEntries = fetchPatternEntries(startDate: thirtyDaysAgo)
        let patternCounts = Dictionary(grouping: recentEntries) { $0.patternType }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        // Create QuickLogPattern array for top patterns
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

        // If no recent patterns, use defaults
        if quickPatterns.isEmpty {
            quickPatterns = [
                ["name": "Sensory Overload", "patternType": "Sensory Overload", "category": "Sensory", "icon": "eye.circle", "colorHex": "AF52DE"],
                ["name": "Meltdown", "patternType": "Meltdown", "category": "Energy & Regulation", "icon": "bolt.circle", "colorHex": "FF3B30"],
                ["name": "Stimming", "patternType": "Stimming", "category": "Energy & Regulation", "icon": "hands.sparkles", "colorHex": "FF9500"],
                ["name": "Masking Fatigue", "patternType": "Masking Fatigue", "category": "Social & Communication", "icon": "theatermasks", "colorHex": "34C759"]
            ]
        }

        // Save to shared UserDefaults
        sharedDefaults?.set(todayCount, forKey: "todayLogCount")
        sharedDefaults?.set(today, forKey: "todayLogDate")
        sharedDefaults?.set(streakCount, forKey: "streakCount")

        // Save quick log patterns as JSON
        if let patternsData = try? JSONSerialization.data(withJSONObject: quickPatterns) {
            sharedDefaults?.set(patternsData, forKey: "quickLogPatterns")
        }

        sharedDefaults?.set(Date(), forKey: "lastUpdateDate")

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Process any pending pattern logs from widget
    func processPendingWidgetLogs() {
        guard let data = sharedDefaults?.data(forKey: "pendingPatternLogs"),
              let logs = try? JSONDecoder().decode([PendingPatternLog].self, from: data),
              !logs.isEmpty else {
            return
        }

        for log in logs {
            // Try to find matching PatternType
            if let patternType = PatternType(rawValue: log.patternType) {
                do {
                    _ = try createPatternEntry(
                        patternType: patternType,
                        intensity: 3, // Default moderate intensity for quick logs
                        contextNotes: "Logged from widget"
                    )
                } catch {
                    print("Failed to create pattern entry from widget: \(error)")
                }
            }
        }

        // Clear pending logs
        sharedDefaults?.removeObject(forKey: "pendingPatternLogs")

        // Update streak
        updateStreak()

        // Sync updated data back to widget
        syncWidgetData()
    }

    /// Pending pattern log structure (matches SharedDataManager)
    private struct PendingPatternLog: Codable {
        let id: String
        let patternName: String
        let patternType: String
        let category: String
        let timestamp: Date
    }

    // MARK: - Setup Item Management

    func createSetupItem(
        name: String,
        category: SetupItemCategory,
        effectTags: [String] = [],
        icon: String? = nil,
        notes: String? = nil,
        startDate: Date? = nil
    ) throws -> SetupItem {
        try Validator(name, fieldName: "Item name")
            .notEmpty()
            .maxLength(100)

        let item = SetupItem(context: container.viewContext)
        item.id = UUID()
        item.name = name
        item.category = category.rawValue
        item.setEffectTags(effectTags)
        item.icon = icon
        item.notes = notes
        item.isActive = true
        item.startDate = startDate ?? Date()
        item.sortOrder = Int16(fetchSetupItems(category: category).count)

        save()
        return item
    }

    func fetchSetupItems(activeOnly: Bool = true, category: SetupItemCategory? = nil) -> [SetupItem] {
        do {
            return try fetchSetupItemsOrThrow(activeOnly: activeOnly, category: category)
        } catch {
            print("Failed to fetch setup items: \(error)")
            return []
        }
    }

    func fetchSetupItemsOrThrow(activeOnly: Bool = true, category: SetupItemCategory? = nil) throws -> [SetupItem] {
        let request = NSFetchRequest<SetupItem>(entityName: "SetupItem")

        var predicates: [NSPredicate] = []
        if activeOnly {
            predicates.append(NSPredicate(format: "isActive == YES"))
        }
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SetupItem.category, ascending: true),
            NSSortDescriptor(keyPath: \SetupItem.sortOrder, ascending: true)
        ]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            throw DataError.fetchFailed(error)
        }
    }

    func updateSetupItem(_ item: SetupItem) {
        save()
    }

    func deleteSetupItem(_ item: SetupItem) {
        container.viewContext.delete(item)
        save()
    }

    func toggleSetupItemActive(_ item: SetupItem) {
        item.isActive.toggle()
        save()
    }

    /// Get setup items grouped by category
    func fetchSetupItemsGrouped(activeOnly: Bool = true) -> [SetupItemCategory: [SetupItem]] {
        let items = fetchSetupItems(activeOnly: activeOnly)
        return Dictionary(grouping: items) { item in
            item.categoryEnum ?? .medication
        }
    }
}

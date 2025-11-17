import Foundation

/// Manages data sharing between the main app and widget extensions using App Groups
class SharedDataManager {
    static let shared = SharedDataManager()

    // MARK: - App Group Configuration
    // TODO: Replace with your actual App Group identifier
    // To create an App Group:
    // 1. In Xcode, select your target
    // 2. Go to "Signing & Capabilities"
    // 3. Click "+ Capability" and add "App Groups"
    // 4. Create a new app group (e.g., group.com.yourcompany.behaviortracker)
    // 5. Add the same app group to both the main app and widget extension targets
    private let appGroupIdentifier = "group.com.behaviortracker.shared"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Keys
    private enum Keys {
        static let favoritePatterns = "favoritePatterns"
        static let todayLogCount = "todayLogCount"
        static let streakCount = "streakCount"
        static let todayMedications = "todayMedications"
        static let medicationAdherence = "medicationAdherence"
        static let lastUpdateDate = "lastUpdateDate"
    }

    // MARK: - Pattern Logging Data

    func saveFavoritePatterns(_ patterns: [String]) {
        sharedDefaults?.set(patterns, forKey: Keys.favoritePatterns)
        updateLastModified()
    }

    func getFavoritePatterns() -> [String] {
        return sharedDefaults?.stringArray(forKey: Keys.favoritePatterns) ?? []
    }

    func saveTodayLogCount(_ count: Int) {
        sharedDefaults?.set(count, forKey: Keys.todayLogCount)
        updateLastModified()
    }

    func getTodayLogCount() -> Int {
        return sharedDefaults?.integer(forKey: Keys.todayLogCount) ?? 0
    }

    func saveStreakCount(_ count: Int) {
        sharedDefaults?.set(count, forKey: Keys.streakCount)
        updateLastModified()
    }

    func getStreakCount() -> Int {
        return sharedDefaults?.integer(forKey: Keys.streakCount) ?? 0
    }

    // MARK: - Medication Data

    func saveMedicationAdherence(_ adherence: Double) {
        sharedDefaults?.set(adherence, forKey: Keys.medicationAdherence)
        updateLastModified()
    }

    func getMedicationAdherence() -> Double {
        return sharedDefaults?.double(forKey: Keys.medicationAdherence)
    }

    func saveTodayMedications(_ medications: [[String: Any]]) {
        sharedDefaults?.set(medications, forKey: Keys.todayMedications)
        updateLastModified()
    }

    func getTodayMedications() -> [[String: Any]] {
        return sharedDefaults?.array(forKey: Keys.todayMedications) as? [[String: Any]] ?? []
    }

    // MARK: - Helpers

    private func updateLastModified() {
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdateDate)
    }

    func getLastUpdateDate() -> Date? {
        return sharedDefaults?.object(forKey: Keys.lastUpdateDate) as? Date
    }

    // MARK: - Widget Refresh

    #if canImport(WidgetKit)
    import WidgetKit

    func reloadWidgets() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func reloadWidget(ofKind kind: String) {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }
    #endif
}

// MARK: - Widget Integration Extensions

extension SharedDataManager {
    /// Call this method after logging a pattern to update widget data
    func updateAfterPatternLog(todayCount: Int, streak: Int, favoritePatterns: [String]) {
        saveTodayLogCount(todayCount)
        saveStreakCount(streak)
        saveFavoritePatterns(favoritePatterns)

        #if canImport(WidgetKit)
        reloadWidget(ofKind: "QuickLogWidget")
        #endif
    }

    /// Call this method after medication log to update widget data
    func updateAfterMedicationLog(medications: [[String: Any]], adherence: Double) {
        saveTodayMedications(medications)
        saveMedicationAdherence(adherence)

        #if canImport(WidgetKit)
        reloadWidget(ofKind: "MedicationReminderWidget")
        #endif
    }
}

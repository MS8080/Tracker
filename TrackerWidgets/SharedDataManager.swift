import Foundation
import WidgetKit

/// Manages data sharing between the main app and widget extensions using App Groups
class SharedDataManager {
    static let shared = SharedDataManager()


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
        static let pendingPatternLogs = "pendingPatternLogs"
        static let deepLinkCategory = "deepLinkCategory"
        static let quickLogPatterns = "quickLogPatterns"
        static let todayLogDate = "todayLogDate"
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
        return sharedDefaults?.double(forKey: Keys.medicationAdherence) ?? 0.0
    }

    func saveTodayMedications(_ medications: [[String: Any]]) {
        sharedDefaults?.set(medications, forKey: Keys.todayMedications)
        updateLastModified()
    }

    func getTodayMedications() -> [[String: Any]] {
        return sharedDefaults?.array(forKey: Keys.todayMedications) as? [[String: Any]] ?? []
    }

    // MARK: - Quick Log Patterns (for widget buttons)

    struct QuickLogPattern: Codable {
        let name: String
        let patternType: String
        let category: String
        let icon: String
        let colorHex: String
    }

    func saveQuickLogPatterns(_ patterns: [QuickLogPattern]) {
        if let data = try? JSONEncoder().encode(patterns) {
            sharedDefaults?.set(data, forKey: Keys.quickLogPatterns)
        }
        updateLastModified()
    }

    func getQuickLogPatterns() -> [QuickLogPattern] {
        guard let data = sharedDefaults?.data(forKey: Keys.quickLogPatterns),
              let patterns = try? JSONDecoder().decode([QuickLogPattern].self, from: data) else {
            return defaultQuickLogPatterns
        }
        return patterns
    }

    private var defaultQuickLogPatterns: [QuickLogPattern] {
        [
            QuickLogPattern(name: "Sensory Overload", patternType: "Sensory Overload", category: "Sensory", icon: "eye.circle", colorHex: "AF52DE"),
            QuickLogPattern(name: "Meltdown", patternType: "Meltdown", category: "Energy & Regulation", icon: "bolt.circle", colorHex: "FF3B30"),
            QuickLogPattern(name: "Stimming", patternType: "Stimming", category: "Energy & Regulation", icon: "hands.sparkles", colorHex: "FF9500"),
            QuickLogPattern(name: "Masking", patternType: "Masking Fatigue", category: "Social & Communication", icon: "theatermasks", colorHex: "34C759")
        ]
    }

    // MARK: - Pending Pattern Logs (widget -> main app)

    struct PendingPatternLog: Codable {
        let id: String
        let patternName: String
        let patternType: String
        let category: String
        let timestamp: Date
    }

    func addPendingPatternLog(patternName: String, patternType: String, category: String, timestamp: Date) {
        var pending = getPendingPatternLogs()
        let log = PendingPatternLog(
            id: UUID().uuidString,
            patternName: patternName,
            patternType: patternType,
            category: category,
            timestamp: timestamp
        )
        pending.append(log)

        if let data = try? JSONEncoder().encode(pending) {
            sharedDefaults?.set(data, forKey: Keys.pendingPatternLogs)
        }
        updateLastModified()
    }

    func getPendingPatternLogs() -> [PendingPatternLog] {
        guard let data = sharedDefaults?.data(forKey: Keys.pendingPatternLogs),
              let logs = try? JSONDecoder().decode([PendingPatternLog].self, from: data) else {
            return []
        }
        return logs
    }

    func clearPendingPatternLogs() {
        sharedDefaults?.removeObject(forKey: Keys.pendingPatternLogs)
        updateLastModified()
    }

    func removePendingPatternLog(id: String) {
        var pending = getPendingPatternLogs()
        pending.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(pending) {
            sharedDefaults?.set(data, forKey: Keys.pendingPatternLogs)
        }
        updateLastModified()
    }

    // MARK: - Deep Link Category

    func setDeepLinkCategory(_ category: String) {
        sharedDefaults?.set(category, forKey: Keys.deepLinkCategory)
    }

    func getDeepLinkCategory() -> String? {
        let category = sharedDefaults?.string(forKey: Keys.deepLinkCategory)
        // Clear after reading
        sharedDefaults?.removeObject(forKey: Keys.deepLinkCategory)
        return category
    }

    // MARK: - Today Log Count with Date Check

    func getTodayLogCountWithDateCheck() -> Int {
        let storedDate = sharedDefaults?.object(forKey: Keys.todayLogDate) as? Date
        let today = Calendar.current.startOfDay(for: Date())

        if let storedDate = storedDate, Calendar.current.isDate(storedDate, inSameDayAs: today) {
            return sharedDefaults?.integer(forKey: Keys.todayLogCount) ?? 0
        } else {
            // Reset count for new day
            sharedDefaults?.set(0, forKey: Keys.todayLogCount)
            sharedDefaults?.set(today, forKey: Keys.todayLogDate)
            return 0
        }
    }

    func incrementTodayLogCount() {
        let current = getTodayLogCountWithDateCheck()
        sharedDefaults?.set(current + 1, forKey: Keys.todayLogCount)
        sharedDefaults?.set(Calendar.current.startOfDay(for: Date()), forKey: Keys.todayLogDate)
        updateLastModified()
    }

    // MARK: - Helpers

    private func updateLastModified() {
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdateDate)
    }

    func getLastUpdateDate() -> Date? {
        return sharedDefaults?.object(forKey: Keys.lastUpdateDate) as? Date
    }

    // MARK: - Widget Refresh

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func reloadWidget(ofKind kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

// MARK: - Widget Integration Extensions

extension SharedDataManager {
    /// Call this method after logging a pattern to update widget data
    func updateAfterPatternLog(todayCount: Int, streak: Int, favoritePatterns: [String]) {
        saveTodayLogCount(todayCount)
        saveStreakCount(streak)
        saveFavoritePatterns(favoritePatterns)
        reloadWidget(ofKind: "QuickLogWidget")
    }

    /// Call this method after medication log to update widget data
    func updateAfterMedicationLog(medications: [[String: Any]], adherence: Double) {
        saveTodayMedications(medications)
        saveMedicationAdherence(adherence)
        reloadWidget(ofKind: "MedicationReminderWidget")
    }
}

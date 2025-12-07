import SwiftUI
import CoreData
import UserNotifications

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = false {
        didSet {
            savePreferences()
            if notificationsEnabled {
                requestNotificationPermission()
            }
        }
    }

    @Published var notificationTime: Date = Date() {
        didSet {
            savePreferences()
            if notificationsEnabled {
                scheduleNotification()
            }
        }
    }

    @Published var favoritePatterns: [String] = []

    private let dataController = DataController.shared

    init() {
        loadPreferences()
    }

    func loadPreferences() {
        let preferences = dataController.getUserPreferences()
        notificationsEnabled = preferences.notificationEnabled
        notificationTime = preferences.notificationTime ?? Date()
        favoritePatterns = preferences.favoritePatterns
    }

    func savePreferences() {
        let preferences = dataController.getUserPreferences()
        preferences.notificationEnabled = notificationsEnabled
        preferences.notificationTime = notificationTime
        preferences.favoritePatterns = favoritePatterns
        dataController.save()
    }

    func toggleFavorite(patternType: PatternType) {
        if let index = favoritePatterns.firstIndex(of: patternType.rawValue) {
            favoritePatterns.remove(at: index)
        } else {
            favoritePatterns.append(patternType.rawValue)
        }
        savePreferences()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            if granted {
                Task { @MainActor in
                    self?.scheduleNotification()
                }
            }
        }
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "Time to log your behavioral patterns for today"
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

        center.add(request)
    }

    func exportDataAsJSON() -> String {
        let entries = dataController.fetchPatternEntries()

        let exportData = entries.map { entry in
            [
                "id": entry.id.uuidString,
                "timestamp": ISO8601DateFormatter().string(from: entry.timestamp),
                "category": entry.category,
                "patternType": entry.patternType,
                "intensity": entry.intensity,
                "duration": entry.duration,
                "contextNotes": entry.contextNotes ?? "",
                "specificDetails": entry.specificDetails ?? ""
            ]
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "[]"
    }

    func exportDataAsCSV() -> String {
        let entries = dataController.fetchPatternEntries()

        var csv = "ID,Timestamp,Category,Pattern Type,Intensity,Duration (min),Context Notes,Specific Details\n"

        for entry in entries {
            let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
            let contextNotes = escapeCSVField(entry.contextNotes ?? "")
            let specificDetails = escapeCSVField(entry.specificDetails ?? "")
            let category = escapeCSVField(entry.category)
            let patternType = escapeCSVField(entry.patternType)

            csv += "\(entry.id.uuidString),\(timestamp),\(category),\(patternType),\(entry.intensity),\(entry.duration),\(contextNotes),\(specificDetails)\n"
        }

        return csv
    }

    /// Properly escape a field for CSV format
    private func escapeCSVField(_ field: String) -> String {
        // If field contains comma, quote, or newline, wrap in quotes and escape quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

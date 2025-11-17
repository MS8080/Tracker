import SwiftUI
import CoreData

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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                self.scheduleNotification()
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

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
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
            let contextNotes = (entry.contextNotes ?? "").replacingOccurrences(of: ",", with: ";")
            let specificDetails = (entry.specificDetails ?? "").replacingOccurrences(of: ",", with: ";")

            csv += "\(entry.id.uuidString),\(timestamp),\(entry.category),\(entry.patternType),\(entry.intensity),\(entry.duration),\(contextNotes),\(specificDetails)\n"
        }

        return csv
    }
}

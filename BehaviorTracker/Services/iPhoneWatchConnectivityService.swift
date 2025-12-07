import Foundation
import WatchConnectivity

class iPhoneWatchConnectivityService: NSObject, ObservableObject {
    static let shared = iPhoneWatchConnectivityService()

    private let dataController = DataController.shared

    private override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Send Updates to Watch

    func sendUpdateToWatch() {
        guard WCSession.default.isReachable else {
            return
        }

        let preferences = dataController.getUserPreferences()
        let todayEntries = dataController.fetchPatternEntries(
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Date()
        )
        let todayMeds = dataController.getTodaysMedicationLogs()

        let medications = todayMeds.map { log -> [String: Any] in
            return [
                "name": log.medication?.name ?? "",
                "dosage": log.medication?.dosage ?? "",
                "taken": log.taken,
                "timestamp": log.timestamp
            ]
        }

        let message: [String: Any] = [
            "favoritePatterns": preferences.favoritePatterns,
            "todayLogCount": todayEntries.count,
            "streakCount": preferences.streakCount,
            "upcomingMedications": medications
        ]

        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("⌚️ Failed to send message to Watch: \(error.localizedDescription)")
        })
    }

    func sendUpdateViaApplicationContext() {
        let preferences = dataController.getUserPreferences()
        let todayEntries = dataController.fetchPatternEntries(
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Date()
        )

        let context: [String: Any] = [
            "favoritePatterns": preferences.favoritePatterns,
            "todayLogCount": todayEntries.count,
            "streakCount": preferences.streakCount
        ]

        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            print("⌚️ Failed to update Watch application context: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Watch Requests

    private func handleLogPattern(message: [String: Any]) -> [String: Any] {
        guard let patternTypeString = message["patternType"] as? String,
              let patternType = PatternType(rawValue: patternTypeString) else {
            return ["success": false, "error": "Invalid pattern type"]
        }

        let intensity = message["intensity"] as? Int16 ?? 3
        let notes = message["notes"] as? String

        Task {
            do {
                _ = try await dataController.createPatternEntry(
                    patternType: patternType,
                    intensity: intensity,
                    duration: 0,
                    contextNotes: notes,
                    specificDetails: nil
                )
                dataController.updateStreak()
                sendUpdateToWatch()
            } catch {
                print("⌚️ Failed to log pattern from Watch: \(error.localizedDescription)")
            }
        }

        return [
            "success": true,
            "message": "Pattern logged successfully"
        ]
    }

    private func handleMarkMedicationTaken(message: [String: Any]) -> [String: Any] {
        guard let medicationName = message["medicationName"] as? String else {
            return ["success": false, "error": "Invalid medication name"]
        }

        // Find the medication
        let medications = dataController.fetchMedications()
        guard let medication = medications.first(where: { $0.name == medicationName }) else {
            return ["success": false, "error": "Medication not found"]
        }

        // Check if already logged today
        let todayLogs = dataController.getTodaysMedicationLogs()
        let alreadyLogged = todayLogs.contains { log in
            log.medication?.name == medicationName && log.taken
        }

        if !alreadyLogged {
            let _ = dataController.createMedicationLog(
                medication: medication,
                taken: true,
                skippedReason: nil,
                sideEffects: nil,
                effectiveness: 0,
                mood: 0,
                energyLevel: 0,
                notes: "Logged from Apple Watch"
            )
        }

        // Send updated data back
        sendUpdateToWatch()

        return [
            "success": true,
            "message": "Medication marked as taken"
        ]
    }

    private func handleCreateJournalEntry(message: [String: Any]) -> [String: Any] {
        guard let content = message["content"] as? String else {
            return ["success": false, "error": "Invalid content"]
        }

        let mood = message["mood"] as? Int16 ?? 0

        let _ = dataController.createJournalEntry(
            title: "Watch Entry",
            content: content,
            mood: mood
        )

        return [
            "success": true,
            "message": "Journal entry created"
        ]
    }

    private func handleRequestUpdate() -> [String: Any] {
        let preferences = dataController.getUserPreferences()
        let todayEntries = dataController.fetchPatternEntries(
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Date()
        )
        let todayMeds = dataController.getTodaysMedicationLogs()

        let medications = todayMeds.map { log -> [String: Any] in
            return [
                "name": log.medication?.name ?? "",
                "dosage": log.medication?.dosage ?? "",
                "taken": log.taken,
                "timestamp": log.timestamp
            ]
        }

        return [
            "favoritePatterns": preferences.favoritePatterns,
            "todayLogCount": todayEntries.count,
            "streakCount": preferences.streakCount,
            "upcomingMedications": medications
        ]
    }
}

// MARK: - WCSessionDelegate

extension iPhoneWatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            sendUpdateViaApplicationContext()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let action = message["action"] as? String else {
            replyHandler(["success": false, "error": "No action specified"])
            return
        }

        let reply: [String: Any]

        switch action {
        case "logPattern":
            reply = handleLogPattern(message: message)
        case "markMedicationTaken":
            reply = handleMarkMedicationTaken(message: message)
        case "createJournalEntry":
            reply = handleCreateJournalEntry(message: message)
        case "requestUpdate":
            reply = handleRequestUpdate()
        default:
            reply = ["success": false, "error": "Unknown action"]
        }

        replyHandler(reply)
    }
}

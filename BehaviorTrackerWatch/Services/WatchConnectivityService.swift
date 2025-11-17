import Foundation
import WatchConnectivity

class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var isReachable = false
    @Published var favoritePatterns: [String] = []
    @Published var todayLogCount: Int = 0
    @Published var streakCount: Int = 0
    @Published var upcomingMedications: [[String: Any]] = []

    private override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Send Data to iPhone

    func logPattern(patternType: String, intensity: Int, notes: String?) {
        guard WCSession.default.isReachable else {
            print("iPhone not reachable")
            return
        }

        let message: [String: Any] = [
            "action": "logPattern",
            "patternType": patternType,
            "intensity": intensity,
            "notes": notes ?? "",
            "timestamp": Date()
        ]

        WCSession.default.sendMessage(message, replyHandler: { reply in
            print("Pattern logged successfully: \(reply)")
            self.requestUpdate()
        }, errorHandler: { error in
            print("Error logging pattern: \(error.localizedDescription)")
        })
    }

    func markMedicationTaken(medicationName: String) {
        guard WCSession.default.isReachable else {
            print("iPhone not reachable")
            return
        }

        let message: [String: Any] = [
            "action": "markMedicationTaken",
            "medicationName": medicationName,
            "timestamp": Date()
        ]

        WCSession.default.sendMessage(message, replyHandler: { reply in
            print("Medication marked as taken: \(reply)")
            self.requestUpdate()
        }, errorHandler: { error in
            print("Error marking medication: \(error.localizedDescription)")
        })
    }

    func createJournalEntry(content: String, mood: Int) {
        guard WCSession.default.isReachable else {
            print("iPhone not reachable")
            return
        }

        let message: [String: Any] = [
            "action": "createJournalEntry",
            "content": content,
            "mood": mood,
            "timestamp": Date()
        ]

        WCSession.default.sendMessage(message, replyHandler: { reply in
            print("Journal entry created: \(reply)")
        }, errorHandler: { error in
            print("Error creating journal entry: \(error.localizedDescription)")
        })
    }

    // MARK: - Request Data from iPhone

    func requestUpdate() {
        guard WCSession.default.isReachable else {
            print("iPhone not reachable")
            return
        }

        let message = ["action": "requestUpdate"]

        WCSession.default.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                self.handleUpdateReply(reply)
            }
        }, errorHandler: { error in
            print("Error requesting update: \(error.localizedDescription)")
        })
    }

    private func handleUpdateReply(_ reply: [String: Any]) {
        if let patterns = reply["favoritePatterns"] as? [String] {
            self.favoritePatterns = patterns
        }

        if let count = reply["todayLogCount"] as? Int {
            self.todayLogCount = count
        }

        if let streak = reply["streakCount"] as? Int {
            self.streakCount = streak
        }

        if let medications = reply["upcomingMedications"] as? [[String: Any]] {
            self.upcomingMedications = medications
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if activationState == .activated {
            requestUpdate()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if session.isReachable {
            requestUpdate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleUpdateReply(message)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleUpdateReply(applicationContext)
        }
    }
}

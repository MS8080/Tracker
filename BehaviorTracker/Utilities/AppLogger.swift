import Foundation
import os.log

/// Centralized logging utility for the app.
/// Uses OSLog for structured logging that integrates with Console.app and Xcode.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.behaviortracker"

    // MARK: - Category Loggers

    static let general = Logger(subsystem: subsystem, category: "general")
    static let ai = Logger(subsystem: subsystem, category: "ai")
    static let watch = Logger(subsystem: subsystem, category: "watch")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let sync = Logger(subsystem: subsystem, category: "sync")
    static let audio = Logger(subsystem: subsystem, category: "audio")
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log an error with context
    func error(_ message: String, error: Error? = nil) {
        if let error = error {
            self.error("\(message): \(error.localizedDescription)")
        } else {
            self.error("\(message)")
        }
    }

    /// Log a warning
    func warning(_ message: String) {
        self.warning("\(message)")
    }

    /// Log debug info (only in debug builds)
    func debug(_ message: String) {
        #if DEBUG
        self.debug("\(message)")
        #endif
    }
}

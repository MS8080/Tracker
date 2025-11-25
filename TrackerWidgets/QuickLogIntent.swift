import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Quick Log Pattern Intent (iOS 17+)

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct QuickLogPatternIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Pattern"
    static var description = IntentDescription("Quickly log a behavior pattern")

    @Parameter(title: "Pattern Name")
    var patternName: String

    @Parameter(title: "Pattern Type")
    var patternType: String

    @Parameter(title: "Category")
    var category: String

    init() {
        self.patternName = ""
        self.patternType = ""
        self.category = ""
    }

    init(patternName: String, patternType: String, category: String) {
        self.patternName = patternName
        self.patternType = patternType
        self.category = category
    }

    func perform() async throws -> some IntentResult {
        // Log the pattern via SharedDataManager
        let manager = SharedDataManager.shared

        // Store pending log for main app to process
        manager.addPendingPatternLog(
            patternName: patternName,
            patternType: patternType,
            category: category,
            timestamp: Date()
        )

        // Update today count
        let currentCount = manager.getTodayLogCount()
        manager.saveTodayLogCount(currentCount + 1)

        // Reload widget
        WidgetCenter.shared.reloadTimelines(ofKind: "QuickLogWidget")

        return .result()
    }
}

// MARK: - Open App Intent

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Behavior Tracker"
    static var description = IntentDescription("Open the Behavior Tracker app")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Open Logging Intent

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct OpenLoggingIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Logging"
    static var description = IntentDescription("Open the logging screen")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Category")
    var category: String?

    init() {}

    init(category: String? = nil) {
        self.category = category
    }

    func perform() async throws -> some IntentResult {
        // Store the category to open when app launches
        if let category = category {
            SharedDataManager.shared.setDeepLinkCategory(category)
        }
        return .result()
    }
}

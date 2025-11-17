import Foundation
import SwiftUI

struct AccessibilityLabels {
    // Dashboard
    static let dashboardTab = "Dashboard tab"
    static let loggingTab = "Logging tab"
    static let reportsTab = "Reports tab"
    static let settingsTab = "Settings tab"

    static let streakCard = "Current streak information"
    static let todayEntryCount = "Number of entries logged today"

    // Logging
    static func categoryButton(_ category: String) -> String {
        "Log \(category) pattern"
    }

    static func quickLogButton(_ pattern: String) -> String {
        "Quick log \(pattern)"
    }

    static func intensitySlider(_ level: Int) -> String {
        "Intensity level \(level) out of 5"
    }

    static func durationPicker(hours: Int, minutes: Int) -> String {
        if hours > 0 && minutes > 0 {
            return "Duration \(hours) hours and \(minutes) minutes"
        } else if hours > 0 {
            return "Duration \(hours) hours"
        } else {
            return "Duration \(minutes) minutes"
        }
    }

    // Reports
    static let weeklyReport = "Weekly report showing patterns from the last 7 days"
    static let monthlyReport = "Monthly report showing patterns from the last 30 days"

    static func patternFrequencyChart(_ count: Int) -> String {
        "\(count) occurrences of this pattern"
    }

    // History
    static func entryRow(pattern: String, time: String) -> String {
        "\(pattern) logged at \(time)"
    }

    static func deleteEntry(_ pattern: String) -> String {
        "Delete \(pattern) entry"
    }

    // Settings
    static let notificationToggle = "Enable or disable daily reminders"
    static let favoritePatternToggle = "Add or remove from favorites"
    static let exportData = "Export all your data"

    // Hints
    static let categoryButtonHint = "Double tap to see specific patterns in this category"
    static let quickLogHint = "Double tap to quickly log this pattern with default values"
    static let deleteEntryHint = "Swipe left to delete this entry"
    static let favoriteToggleHint = "Add to favorites for quick access on the logging screen"
}

struct AccessibilityTraits {
    static let statisticCard: String = "Statistical information"
    static let chartElement: String = "Chart"
}

extension View {
    func accessibilityElement(
        label: String,
        hint: String? = nil,
        traits: [String] = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .modifier(OptionalAccessibilityHint(hint: hint))
    }
}

struct OptionalAccessibilityHint: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        if let hint = hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

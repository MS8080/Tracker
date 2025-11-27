import SwiftUI

// MARK: - App Appearance

enum AppAppearance: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

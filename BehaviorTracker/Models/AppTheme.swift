import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case purple = "Purple Dream"
    case burgundy = "Burgundy Elegance"
    case navy = "Deep Navy"
    case skyBlue = "Sky Blue"
    case grey = "Modern Grey"
    case cream = "Warm Cream"

    var id: String { rawValue }

    var gradient: LinearGradient {
        switch self {
        case .purple:
            return LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.6),
                    Color(red: 0.5, green: 0.3, blue: 0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .burgundy:
            return LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.1, blue: 0.2),
                    Color(red: 0.6, green: 0.2, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .navy:
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.15, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .skyBlue:
            return LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.7, blue: 0.9),
                    Color(red: 0.5, green: 0.8, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .grey:
            return LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.3, blue: 0.35),
                    Color(red: 0.4, green: 0.4, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cream:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.92, blue: 0.85),
                    Color(red: 0.98, green: 0.95, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var previewColor: Color {
        switch self {
        case .purple: return Color(red: 0.45, green: 0.25, blue: 0.65)
        case .burgundy: return Color(red: 0.55, green: 0.15, blue: 0.25)
        case .navy: return Color(red: 0.12, green: 0.17, blue: 0.35)
        case .skyBlue: return Color(red: 0.45, green: 0.75, blue: 0.92)
        case .grey: return Color(red: 0.35, green: 0.35, blue: 0.4)
        case .cream: return Color(red: 0.97, green: 0.93, blue: 0.87)
        }
    }

    var textColor: Color {
        switch self {
        case .purple, .burgundy, .navy, .grey:
            return .white
        case .skyBlue:
            return Color(white: 0.1)
        case .cream:
            return Color(red: 0.2, green: 0.2, blue: 0.25)
        }
    }

    var secondaryTextColor: Color {
        textColor.opacity(0.7)
    }

    var cardBackground: Color {
        switch self {
        case .purple, .burgundy, .navy, .grey:
            return Color.white.opacity(0.15)
        case .skyBlue:
            return Color.white.opacity(0.5)
        case .cream:
            return Color.white.opacity(0.6)
        }
    }
}

import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case purple = "Purple"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case burgundy = "Burgundy"
    case grey = "Grey"

    var id: String { rawValue }

    var primaryColor: Color {
        switch self {
        case .purple: return Color(red: 0.55, green: 0.35, blue: 0.75)
        case .blue: return Color(red: 0.3, green: 0.5, blue: 0.8)
        case .green: return Color(red: 0.3, green: 0.6, blue: 0.45)
        case .orange: return Color(red: 0.8, green: 0.5, blue: 0.3)
        case .burgundy: return Color(red: 0.6, green: 0.25, blue: 0.35)
        case .grey: return Color(red: 0.45, green: 0.45, blue: 0.50)
        }
    }

    /// Gradient: color accent at top ~40% like Apple Health app
    /// Now with diagonal direction for more visual interest and brighter middle colors
    var gradient: LinearGradient {
        switch self {
        case .purple:
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.35, blue: 0.70),  // Brighter top
                    Color(red: 0.38, green: 0.25, blue: 0.50),  // Brighter middle
                    Color(red: 0.22, green: 0.18, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.6, y: 0.40)  // Extends to 40%, diagonal
            )
        case .blue:
            return LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.48, blue: 0.68),  // Brighter top
                    Color(red: 0.22, green: 0.34, blue: 0.48),  // Brighter middle
                    Color(red: 0.15, green: 0.18, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.6, y: 0.40)
            )
        case .green:
            return LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.52, blue: 0.40),  // Brighter top
                    Color(red: 0.20, green: 0.36, blue: 0.30),  // Brighter middle
                    Color(red: 0.14, green: 0.22, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.6, y: 0.40)
            )
        case .orange:
            return LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.48, blue: 0.26),  // Brighter top
                    Color(red: 0.48, green: 0.34, blue: 0.22),  // Brighter middle
                    Color(red: 0.25, green: 0.20, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.6, y: 0.40)
            )
        case .burgundy:
            return LinearGradient(
                colors: [
                    Color(red: 0.62, green: 0.22, blue: 0.35),  // Brighter top
                    Color(red: 0.45, green: 0.20, blue: 0.28),  // Brighter middle
                    Color(red: 0.26, green: 0.16, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.6, y: 0.40)
            )
        case .grey:
            return LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.45, blue: 0.48),  // Brighter top
                    Color(red: 0.34, green: 0.34, blue: 0.38),  // Brighter middle
                    Color(red: 0.20, green: 0.20, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.6, y: 0.40)
            )
        }
    }

    /// Brighter accent color for timeline elements
    var timelineColor: Color {
        switch self {
        case .purple: return Color(red: 0.60, green: 0.45, blue: 0.75)
        case .blue: return Color(red: 0.45, green: 0.60, blue: 0.80)
        case .green: return Color(red: 0.45, green: 0.70, blue: 0.55)
        case .orange: return Color(red: 0.80, green: 0.60, blue: 0.40)
        case .burgundy: return Color(red: 0.80, green: 0.50, blue: 0.55)
        case .grey: return Color(red: 0.60, green: 0.60, blue: 0.65)
        }
    }

    /// Card/tile background - dark with subtle theme tint for cohesion
    var cardBackground: Color {
        switch self {
        case .purple:
            return Color(red: 0.20, green: 0.18, blue: 0.25).opacity(0.65)
        case .blue:
            return Color(red: 0.16, green: 0.20, blue: 0.28).opacity(0.65)
        case .green:
            return Color(red: 0.16, green: 0.22, blue: 0.20).opacity(0.65)
        case .orange:
            return Color(red: 0.25, green: 0.20, blue: 0.18).opacity(0.65)
        case .burgundy:
            return Color(red: 0.24, green: 0.18, blue: 0.20).opacity(0.65)
        case .grey:
            return Color(red: 0.20, green: 0.20, blue: 0.22).opacity(0.65)
        }
    }

    /// Alias for consistency (same as cardBackground)
    var journalCardBackground: Color {
        return cardBackground
    }

    /// Subtle border color for card edges - slightly brighter for better definition
    var cardBorderColor: Color {
        return Color.white.opacity(0.15)
    }

    /// Card shadow color
    var cardShadowColor: Color {
        return Color.black.opacity(0.25)
    }
}

// MARK: - Themed Background Modifier

struct ThemedBackgroundModifier: ViewModifier {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    func body(content: Content) -> some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            content
        }
    }
}

// MARK: - Blue Light Filter Modifier

struct BlueLightFilterModifier: ViewModifier {
    @AppStorage("blueLightFilterEnabled") private var blueLightFilterEnabled: Bool = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if blueLightFilterEnabled {
                Color.orange
                    .opacity(0.10)  // Subtle but effective - reduces blue light without being intrusive
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }

    func blueLightFilter() -> some View {
        modifier(BlueLightFilterModifier())
    }

    /// Standard card style - use for main content cards
    func cardStyle(theme: AppTheme, cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 6, y: 3)
    }

    /// Compact card style - use for list items, nested cards
    func compactCardStyle(theme: AppTheme) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 4, y: 2)
    }
}


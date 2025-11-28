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

    /// Vibrant primary color - more saturated for better visibility
    var primaryColor: Color {
        switch self {
        case .purple: return Color(red: 0.65, green: 0.40, blue: 0.90)
        case .blue: return Color(red: 0.35, green: 0.55, blue: 0.95)
        case .green: return Color(red: 0.30, green: 0.75, blue: 0.55)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.25)
        case .burgundy: return Color(red: 0.75, green: 0.30, blue: 0.40)
        case .grey: return Color(red: 0.55, green: 0.55, blue: 0.60)
        }
    }

    /// Secondary color for accents - complementary to primary
    var secondaryColor: Color {
        switch self {
        case .purple: return Color(red: 0.45, green: 0.30, blue: 0.70)
        case .blue: return Color(red: 0.25, green: 0.40, blue: 0.75)
        case .green: return Color(red: 0.20, green: 0.55, blue: 0.40)
        case .orange: return Color(red: 0.75, green: 0.40, blue: 0.20)
        case .burgundy: return Color(red: 0.55, green: 0.20, blue: 0.30)
        case .grey: return Color(red: 0.40, green: 0.40, blue: 0.45)
        }
    }

    /// Rich gradient background with theme personality
    var gradient: LinearGradient {
        let darkBase = Color(red: 0.12, green: 0.12, blue: 0.14)

        return LinearGradient(
            colors: [
                primaryColor.opacity(0.45),
                secondaryColor.opacity(0.25),
                darkBase
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Brighter accent color for timeline elements
    var timelineColor: Color {
        switch self {
        case .purple: return Color(red: 0.75, green: 0.55, blue: 0.95)
        case .blue: return Color(red: 0.50, green: 0.70, blue: 1.0)
        case .green: return Color(red: 0.45, green: 0.85, blue: 0.65)
        case .orange: return Color(red: 1.0, green: 0.65, blue: 0.35)
        case .burgundy: return Color(red: 0.90, green: 0.50, blue: 0.55)
        case .grey: return Color(red: 0.70, green: 0.70, blue: 0.75)
        }
    }

    /// Card background - tinted with theme color for personalization
    var cardBackground: Color {
        switch self {
        case .purple: return Color(red: 0.18, green: 0.15, blue: 0.22)
        case .blue: return Color(red: 0.14, green: 0.17, blue: 0.22)
        case .green: return Color(red: 0.14, green: 0.19, blue: 0.17)
        case .orange: return Color(red: 0.20, green: 0.16, blue: 0.14)
        case .burgundy: return Color(red: 0.20, green: 0.14, blue: 0.16)
        case .grey: return Color(red: 0.17, green: 0.17, blue: 0.18)
        }
    }

    /// Subtle border color - theme tinted
    var cardBorderColor: Color {
        primaryColor.opacity(0.20)
    }

    /// Card shadow color
    var cardShadowColor: Color {
        Color.black.opacity(0.35)
    }

    /// Light accent color for backgrounds
    var accentLight: Color {
        primaryColor.opacity(0.20)
    }

    /// Medium accent color for borders and overlays
    var accentMedium: Color {
        primaryColor.opacity(0.45)
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
                    .stroke(theme.cardBorderColor, lineWidth: 1)
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
                    .stroke(theme.cardBorderColor, lineWidth: 1)
            )
            .shadow(color: theme.cardShadowColor, radius: 4, y: 2)
    }
}


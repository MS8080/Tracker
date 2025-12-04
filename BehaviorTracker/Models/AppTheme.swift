import SwiftUI

// MARK: - Color Science Utilities

/// HSL color representation for consistent luminance calculations
private struct HSLColor {
    let hue: Double        // 0-360
    let saturation: Double // 0-1
    let lightness: Double  // 0-1

    /// Convert HSL to SwiftUI Color
    func toColor() -> Color {
        let c = (1 - abs(2 * lightness - 1)) * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - c / 2

        var r, g, b: Double
        switch hue {
        case 0..<60:    (r, g, b) = (c, x, 0)
        case 60..<120:  (r, g, b) = (x, c, 0)
        case 120..<180: (r, g, b) = (0, c, x)
        case 180..<240: (r, g, b) = (0, x, c)
        case 240..<300: (r, g, b) = (x, 0, c)
        default:        (r, g, b) = (c, 0, x)
        }

        return Color(red: r + m, green: g + m, blue: b + m)
    }
}

// MARK: - Theme Color Definitions

/// Semantic color tokens for consistent theming
private enum ThemeColorToken {
    /// Base hue values for each theme (in degrees)
    static func baseHue(for theme: AppTheme) -> Double {
        switch theme {
        case .purple:   return 270
        case .blue:     return 220
        case .green:    return 155  // Warmer green, less teal
        case .amber:    return 40
        case .burgundy: return 350  // More red, less purple
        case .grey:     return 240
        }
    }

    /// Base saturation (grey is desaturated)
    static func baseSaturation(for theme: AppTheme) -> Double {
        theme == .grey ? 0.15 : 0.65
    }

    /// Primary color - consistent luminance at 0.55
    static func primary(for theme: AppTheme) -> HSLColor {
        HSLColor(
            hue: baseHue(for: theme),
            saturation: baseSaturation(for: theme),
            lightness: 0.55
        )
    }

    /// Timeline/accent color - brighter variant
    static func timeline(for theme: AppTheme) -> HSLColor {
        if theme == .blue {
            return HSLColor(hue: 200, saturation: 0.85, lightness: 0.65)
        }
        return HSLColor(
            hue: baseHue(for: theme),
            saturation: min(1.0, baseSaturation(for: theme) + 0.15),
            lightness: 0.65
        )
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case purple = "Purple"
    case blue = "Blue"
    case green = "Green"
    case amber = "Amber"
    case burgundy = "Burgundy"
    case grey = "Grey"

    var id: String { rawValue }

    /// Primary color with consistent luminance across all themes
    var primaryColor: Color {
        ThemeColorToken.primary(for: self).toColor()
    }

    /// Brighter accent color for timeline elements
    var timelineColor: Color {
        ThemeColorToken.timeline(for: self).toColor()
    }

    /// Simple soft gradient - theme color fading smoothly to dark
    var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: primaryColor.opacity(0.55), location: 0.0),
                .init(color: primaryColor.opacity(0.35), location: 0.10),
                .init(color: primaryColor.opacity(0.20), location: 0.18),
                .init(color: primaryColor.opacity(0.20), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Light accent color for backgrounds
    var accentLight: Color {
        primaryColor.opacity(0.15)
    }

    /// Medium accent color for borders and overlays
    var accentMedium: Color {
        primaryColor.opacity(0.40)
    }

    /// Card/tile background - transparent for integrated look
    var cardBackground: Color {
        return Color.white.opacity(0.06)
    }

    /// Border color for card edges (theme-colored outer border)
    var cardBorderColor: Color {
        return primaryColor.opacity(0.35)
    }

    /// Shadow color for cards
    var cardShadowColor: Color {
        return Color.black.opacity(0.3)
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
            // Simple linear gradient - no mesh or radial gradients
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
                    .opacity(0.10)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}



// MARK: - Simplified Card Modifiers (Performance Optimized)

struct TrueLiquidGlassCardModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat
    let isInteractive: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

struct TrueLiquidGlassCompactModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

struct TrueLiquidGlassFocusableModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isFocused ? theme.primaryColor.opacity(0.4) : Color.white.opacity(0.1), lineWidth: isFocused ? 1.5 : 0.5)
            )
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

    /// True Liquid Glass card style - uses real blur and interactive effects
    func cardStyle(theme: AppTheme, cornerRadius: CGFloat = CornerRadius.lg, interactive: Bool = false) -> some View {
        modifier(TrueLiquidGlassCardModifier(theme: theme, cornerRadius: cornerRadius, isInteractive: interactive))
    }

    /// Compact Liquid Glass style - simplified for list items
    func compactCardStyle(theme: AppTheme) -> some View {
        modifier(TrueLiquidGlassCompactModifier(theme: theme))
    }
    
    /// Focusable Liquid Glass card style - dynamic appearance based on focus state
    func focusableCardStyle(theme: AppTheme, cornerRadius: CGFloat = CornerRadius.lg, isFocused: Bool = false) -> some View {
        modifier(TrueLiquidGlassFocusableModifier(theme: theme, cornerRadius: cornerRadius, isFocused: isFocused))
    }
}

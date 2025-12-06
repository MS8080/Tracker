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
/// Inspired by iPhone Pro colors - darker, more sophisticated, muted tones
private enum ThemeColorToken {
    /// Base hue values for each theme (in degrees)
    static func baseHue(for theme: AppTheme) -> Double {
        switch theme {
        case .purple:   return 270  // Deep purple like iPhone 14 Pro
        case .blue:     return 215  // Titanium blue undertone
        case .green:    return 160  // Dark titanium green
        case .amber:    return 35   // Natural titanium warm
        case .burgundy: return 350  // Deep wine, almost black-cherry
        case .grey:     return 220  // Space black with blue undertone
        }
    }

    /// Base saturation - refined, professional but visible
    static func baseSaturation(for theme: AppTheme) -> Double {
        switch theme {
        case .grey:     return 0.08  // Nearly neutral
        case .amber:    return 0.45  // Warm but not loud
        default:        return 0.50  // Visible but refined
        }
    }

    /// Primary color - balanced between dark and visible
    static func primary(for theme: AppTheme) -> HSLColor {
        HSLColor(
            hue: baseHue(for: theme),
            saturation: baseSaturation(for: theme),
            lightness: 0.48  // Visible but not bright
        )
    }

    /// Timeline/accent color - slightly lifted
    static func timeline(for theme: AppTheme) -> HSLColor {
        HSLColor(
            hue: baseHue(for: theme),
            saturation: min(0.60, baseSaturation(for: theme) + 0.10),
            lightness: 0.55
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

    /// Professional gradient - visible but refined
    var gradient: LinearGradient {
        LinearGradient(
            stops: [
                // Top: visible color presence
                .init(color: primaryColor.opacity(0.38), location: 0.0),
                .init(color: primaryColor.opacity(0.32), location: 0.15),
                .init(color: primaryColor.opacity(0.27), location: 0.35),
                // Middle: steady tone
                .init(color: primaryColor.opacity(0.24), location: 0.55),
                .init(color: primaryColor.opacity(0.21), location: 0.75),
                // Bottom: grounded
                .init(color: primaryColor.opacity(0.18), location: 0.90),
                .init(color: primaryColor.opacity(0.15), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Light accent color for backgrounds
    var accentLight: Color {
        primaryColor.opacity(0.12)
    }

    /// Medium accent color for borders and overlays
    var accentMedium: Color {
        primaryColor.opacity(0.30)
    }

    /// Card/tile background - visible but subtle
    var cardBackground: Color {
        return Color.white.opacity(0.08)
    }

    /// Border color for card edges
    var cardBorderColor: Color {
        return primaryColor.opacity(0.25)
    }

    /// Shadow color for cards
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
        content
            .overlay {
                if blueLightFilterEnabled {
                    Color.orange
                        .opacity(0.15)
                        .ignoresSafeArea(.all)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.3), value: blueLightFilterEnabled)
                }
            }
    }
}



// MARK: - Hybrid Card Modifiers (glassEffect on iOS 26+, ultraThinMaterial fallback)

struct TrueLiquidGlassCardModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat
    let isInteractive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.primaryColor.opacity(0.07))
                }
                .glassEffect(
                    isInteractive ? .regular.interactive() : .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(
                    ZStack {
                        theme.primaryColor.opacity(0.10)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(theme.primaryColor.opacity(0.20), lineWidth: 0.5)
                )
        }
    }
}

struct TrueLiquidGlassCompactModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(theme.primaryColor.opacity(0.06))
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        } else {
            content
                .background(
                    ZStack {
                        theme.primaryColor.opacity(0.08)
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(theme.primaryColor.opacity(0.18), lineWidth: 0.5)
                )
        }
    }
}

struct TrueLiquidGlassFocusableModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat
    let isFocused: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.primaryColor.opacity(isFocused ? 0.08 : 0.05))
                }
                .glassEffect(
                    isFocused ? .regular.interactive() : .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(isFocused ? theme.primaryColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
        } else {
            content
                .background(
                    ZStack {
                        theme.primaryColor.opacity(isFocused ? 0.12 : 0.08)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(isFocused ? theme.primaryColor.opacity(0.4) : theme.primaryColor.opacity(0.15), lineWidth: isFocused ? 1.5 : 0.5)
                )
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

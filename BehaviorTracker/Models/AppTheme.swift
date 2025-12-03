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

    /// Create a darker variant with consistent luminance reduction
    func darker(by amount: Double) -> HSLColor {
        HSLColor(hue: hue, saturation: saturation, lightness: max(0, lightness - amount))
    }

    /// Create a lighter variant
    func lighter(by amount: Double) -> HSLColor {
        HSLColor(hue: hue, saturation: saturation, lightness: min(1, lightness + amount))
    }

    /// Create a less saturated variant
    func desaturated(by amount: Double) -> HSLColor {
        HSLColor(hue: hue, saturation: max(0, saturation - amount), lightness: lightness)
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

    /// Secondary color - darker, slightly desaturated
    static func secondary(for theme: AppTheme) -> HSLColor {
        primary(for: theme).darker(by: 0.15).desaturated(by: 0.1)
    }

    /// Timeline/accent color - brighter variant
    static func timeline(for theme: AppTheme) -> HSLColor {
        // Sky blue for blue theme
        if theme == .blue {
            return HSLColor(hue: 200, saturation: 0.85, lightness: 0.65)
        }
        return HSLColor(
            hue: baseHue(for: theme),
            saturation: min(1.0, baseSaturation(for: theme) + 0.15),
            lightness: 0.65
        )
    }

    /// Gradient top color - softer, less vibrant
    static func gradientTop(for theme: AppTheme) -> HSLColor {
        HSLColor(
            hue: baseHue(for: theme),
            saturation: baseSaturation(for: theme) * 0.45, // Reduced from 0.75
            lightness: 0.30 // Darker
        )
    }

    /// Gradient upper-mid color
    static func gradientUpperMid(for theme: AppTheme) -> HSLColor {
        // Shift hue slightly toward purple for depth
        let hueShift = theme == .burgundy ? -8.0 : (theme == .purple ? 5.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.5, // Reduced from 0.8
            lightness: 0.24 // Darker
        )
    }

    /// Gradient middle color - softer mid-tone
    static func gradientMid(for theme: AppTheme) -> HSLColor {
        // Deeper saturation in the middle
        let hueShift = theme == .burgundy ? -12.0 : (theme == .purple ? 8.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.55, // Reduced from 0.85
            lightness: 0.18 // Darker
        )
    }

    /// Gradient lower-mid color - softer transition
    static func gradientLowerMid(for theme: AppTheme) -> HSLColor {
        // Shift toward burgundy/plum
        let hueShift = theme == .burgundy ? -15.0 : (theme == .purple ? 12.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.45, // Reduced from 0.75
            lightness: 0.14 // Darker
        )
    }

    /// Gradient bottom color - brighter for text readability
    static func gradientBottom(for theme: AppTheme) -> HSLColor {
        // Brighter bottom for better text visibility
        let hueShift = theme == .burgundy ? -18.0 : (theme == .purple ? 15.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.45, // Increased from 0.35
            lightness: 0.20 // Brighter from 0.12 for better readability
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

    /// Secondary color for gradient mid-tones
    var secondaryColor: Color {
        ThemeColorToken.secondary(for: self).toColor()
    }

    /// Brighter accent color for timeline elements
    var timelineColor: Color {
        ThemeColorToken.timeline(for: self).toColor()
    }

    /// Rich gradient background - multi-tone liquid depth effect
    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                ThemeColorToken.gradientTop(for: self).toColor(),
                ThemeColorToken.gradientUpperMid(for: self).toColor(),
                ThemeColorToken.gradientMid(for: self).toColor(),
                ThemeColorToken.gradientLowerMid(for: self).toColor(),
                ThemeColorToken.gradientBottom(for: self).toColor()
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Liquid depth background colors - richer, more saturated for "pooled liquid" effect
    var liquidDepthColors: [Color] {
        let baseHue = ThemeColorToken.baseHue(for: self)
        let baseSat = ThemeColorToken.baseSaturation(for: self)

        // Hue shifts for purple/burgundy themes to create depth variation
        let topShift = self == .purple ? 5.0 : (self == .burgundy ? -5.0 : 0.0)
        let midShift = self == .purple ? 12.0 : (self == .burgundy ? -12.0 : 0.0)
        let bottomShift = self == .purple ? 18.0 : (self == .burgundy ? -18.0 : 0.0)

        // Richer, deeper colors for liquid effect
        return [
            // Lighter pool (top area glow)
            HSLColor(
                hue: (baseHue + topShift + 360).truncatingRemainder(dividingBy: 360),
                saturation: baseSat * 0.85,
                lightness: 0.35
            ).toColor(),
            // Mid-tone pool with hue shift toward plum
            HSLColor(
                hue: (baseHue + midShift + 360).truncatingRemainder(dividingBy: 360),
                saturation: baseSat * 0.9,
                lightness: 0.22
            ).toColor(),
            // Deep burgundy/plum pool (bottom depth)
            HSLColor(
                hue: (baseHue + bottomShift + 360).truncatingRemainder(dividingBy: 360),
                saturation: baseSat * 0.7,
                lightness: 0.12
            ).toColor(),
            // Extra deep accent for vignette
            HSLColor(
                hue: (baseHue + bottomShift + 5 + 360).truncatingRemainder(dividingBy: 360),
                saturation: baseSat * 0.5,
                lightness: 0.08
            ).toColor()
        ]
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

    /// Theme-tinted glass overlay for depth
    var cardGlassTint: Color {
        // Subtle tint matching the theme's primary color
        return primaryColor.opacity(0.05)
    }

    /// Border color for card edges (theme-colored outer border)
    var cardBorderColor: Color {
        return primaryColor.opacity(0.35)
    }

    /// Glow color for top and partial side edges
    var cardGlowColor: Color {
        return Color.white.opacity(0.65)
    }

    /// Shadow color for cards
    var cardShadowColor: Color {
        return Color.black.opacity(0.3)
    }

    /// Mesh color configuration per theme
    private var meshConfig: (lightnesses: [Double], satMultipliers: [Double], hueOffsets: [Double]) {
        // Common saturation multiplier patterns
        let standardSatMult = [0.80, 0.78, 0.76, 0.82, 0.80, 0.78, 0.72, 0.68, 0.60]
        let standardHueOffsets = [-8.0, 0, 8, -5, 0, 5, -3, 0, 3]

        switch self {
        case .purple:
            return (
                [0.36, 0.34, 0.32, 0.28, 0.25, 0.23, 0.20, 0.18, 0.16],  // Brighter bottom row
                [0.80, 0.82, 0.78, 0.85, 0.88, 0.85, 0.75, 0.70, 0.60],
                [-5, 0, 5, 8, 12, 10, 15, 18, 20]  // Shift toward plum at bottom
            )
        case .burgundy:
            return (
                [0.34, 0.32, 0.30, 0.26, 0.23, 0.21, 0.18, 0.16, 0.14],  // Brighter bottom row
                [0.78, 0.80, 0.76, 0.82, 0.85, 0.82, 0.70, 0.65, 0.55],
                [5, 0, -5, -8, -12, -10, -15, -18, -20]  // Shift toward wine at bottom
            )
        case .amber:
            return (
                [0.38, 0.35, 0.32, 0.30, 0.28, 0.26, 0.24, 0.22, 0.20],  // Brighter bottom row
                [0.85, 0.82, 0.80, 0.88, 0.85, 0.82, 0.80, 0.78, 0.75],
                [-5, 0, 5, -3, 0, 3, -2, 0, 2]
            )
        case .green:
            return (
                [0.35, 0.33, 0.31, 0.28, 0.26, 0.24, 0.21, 0.19, 0.17],  // Brighter bottom row
                standardSatMult,
                standardHueOffsets
            )
        default:  // Blue/Grey
            return (
                [0.38, 0.35, 0.32, 0.30, 0.28, 0.26, 0.24, 0.22, 0.20],  // Brighter bottom row
                [0.80, 0.78, 0.76, 0.82, 0.80, 0.78, 0.76, 0.74, 0.70],
                [-5, 0, 5, -3, 0, 3, -2, 0, 2]
            )
        }
    }

    /// Generate 9 mesh colors for gradient background - rich liquid depth
    var meshColors: [Color] {
        let baseHue = ThemeColorToken.baseHue(for: self)
        let baseSat = ThemeColorToken.baseSaturation(for: self)
        let config = meshConfig

        return (0..<9).map { index in
            HSLColor(
                hue: (baseHue + config.hueOffsets[index] + 360).truncatingRemainder(dividingBy: 360),
                saturation: baseSat * config.satMultipliers[index],
                lightness: config.lightnesses[index]
            ).toColor()
        }
    }
}

// MARK: - Animated Mesh Gradient Background

struct MeshGradientBackground: View {
    let theme: AppTheme
    @State private var isVisible = true

    var body: some View {
        if #available(iOS 18.0, *) {
            // Layered liquid depth background
            ZStack {
                // Base layer: Deep rich animated mesh gradient (OPTIMIZED: 10 FPS instead of 20)
                TimelineView(.animation(minimumInterval: 1/10, paused: !isVisible)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: meshPoints(time: time),
                        colors: theme.meshColors
                    )
                }
                .drawingGroup() // GPU acceleration for mesh gradient

                // Layer 2: Top-left lighter pool (creates depth illusion) - REDUCED
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[0].opacity(0.30),
                        theme.liquidDepthColors[0].opacity(0.10),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.15, y: 0.1),
                    startRadius: 0,
                    endRadius: 380
                )

                // Layer 3: Mid-right pool with plum tones - REDUCED
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[1].opacity(0.25),
                        theme.liquidDepthColors[1].opacity(0.08),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.85, y: 0.35),
                    startRadius: 0,
                    endRadius: 320
                )

                // Layer 4: Center-left mid-depth pool - REDUCED
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[1].opacity(0.20),
                        theme.liquidDepthColors[2].opacity(0.10),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.25, y: 0.55),
                    startRadius: 0,
                    endRadius: 280
                )

                // Layer 5: Deep bottom pool (burgundy/plum depth) - REDUCED
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[2].opacity(0.40),
                        theme.liquidDepthColors[3].opacity(0.25),
                        theme.liquidDepthColors[3].opacity(0.10),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 1.15),
                    startRadius: 0,
                    endRadius: 550
                )

                // Layer 6: Bottom corners - extra depth - REDUCED
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[3].opacity(0.30),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.0, y: 1.0),
                    startRadius: 0,
                    endRadius: 350
                )

                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[3].opacity(0.30),
                        Color.clear
                    ],
                    center: UnitPoint(x: 1.0, y: 1.0),
                    startRadius: 0,
                    endRadius: 350
                )

                // Layer 7: Edge vignette - VERY SOFT for text readability
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.18)
                    ],
                    center: .center,
                    startRadius: 180,
                    endRadius: 600
                )

                // Layer 8: Corner shadows for bezel blend - MUCH LIGHTER
                Rectangle()
                    .fill(
                        EllipticalGradient(
                            colors: [Color.clear, Color.black.opacity(0.10)],
                            center: .center,
                            startRadiusFraction: 0.4,
                            endRadiusFraction: 0.85
                        )
                    )
            }
            .onAppear { isVisible = true }
            .onDisappear { isVisible = false }
        } else {
            // iOS 17 fallback with layered liquid effect
            LiquidDepthFallback(theme: theme)
        }
    }

    /// Generate animated mesh points with liquid motion
    private func meshPoints(time: Double) -> [SIMD2<Float>] {
        let t = Float(time)
        let amplitude: Float = 0.06  // Subtle liquid movement

        return [
            // Top row - corners fixed
            SIMD2(0.0, 0.0),
            SIMD2(0.5 + amplitude * sin(t * 0.32), amplitude * cos(t * 0.41)),
            SIMD2(1.0, 0.0),
            // Middle row - gentle movement with organic variation
            SIMD2(amplitude * sin(t * 0.37), 0.5 + amplitude * cos(t * 0.29)),
            SIMD2(0.5 + amplitude * cos(t * 0.26), 0.5 + amplitude * sin(t * 0.31)),
            SIMD2(1.0 - amplitude * sin(t * 0.34), 0.5 + amplitude * cos(t * 0.38)),
            // Bottom row - corners fixed
            SIMD2(0.0, 1.0),
            SIMD2(0.5 + amplitude * cos(t * 0.30), 1.0 - amplitude * sin(t * 0.33)),
            SIMD2(1.0, 1.0)
        ]
    }
}

// MARK: - iOS 17 Liquid Depth Fallback

private struct LiquidDepthFallback: View {
    let theme: AppTheme
    @State private var animationPhase: Double = 0
    @State private var isVisible = true

    var body: some View {
        ZStack {
            // Base layer: Rich multi-tone gradient background
            theme.gradient

            // Layer 2: Top-left lighter pool - REDUCED
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[0].opacity(0.30),
                    theme.liquidDepthColors[0].opacity(0.12),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.15 + 0.08 * sin(animationPhase * 0.5),
                    y: 0.1 + 0.04 * cos(animationPhase * 0.4)
                ),
                startRadius: 0,
                endRadius: 380
            )

            // Layer 3: Mid-right plum pool - REDUCED
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[1].opacity(0.25),
                    theme.liquidDepthColors[1].opacity(0.08),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.85 + 0.06 * cos(animationPhase * 0.45),
                    y: 0.35 + 0.05 * sin(animationPhase * 0.5)
                ),
                startRadius: 0,
                endRadius: 320
            )

            // Layer 4: Center-left depth - REDUCED
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[1].opacity(0.20),
                    theme.liquidDepthColors[2].opacity(0.10),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.25 + 0.07 * sin(animationPhase * 0.38),
                    y: 0.55 + 0.05 * cos(animationPhase * 0.42)
                ),
                startRadius: 0,
                endRadius: 280
            )

            // Layer 5: Deep bottom pool (burgundy/plum) - REDUCED
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[2].opacity(0.40),
                    theme.liquidDepthColors[3].opacity(0.22),
                    theme.liquidDepthColors[3].opacity(0.08),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.5 + 0.1 * sin(animationPhase * 0.35),
                    y: 1.15 + 0.06 * cos(animationPhase * 0.4)
                ),
                startRadius: 0,
                endRadius: 550
            )

            // Layer 6: Bottom corners depth - REDUCED
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[3].opacity(0.28),
                    .clear
                ],
                center: UnitPoint(x: 0.0, y: 1.0),
                startRadius: 0,
                endRadius: 350
            )

            RadialGradient(
                colors: [
                    theme.liquidDepthColors[3].opacity(0.28),
                    .clear
                ],
                center: UnitPoint(x: 1.0, y: 1.0),
                startRadius: 0,
                endRadius: 350
            )

            // Layer 7: Edge vignette - VERY SOFT for text readability
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.18)
                ],
                center: .center,
                startRadius: 180,
                endRadius: 600
            )

            // Layer 8: Corner shadows for bezel blend - MUCH LIGHTER
            Rectangle()
                .fill(
                    EllipticalGradient(
                        colors: [Color.clear, Color.black.opacity(0.10)],
                        center: .center,
                        startRadiusFraction: 0.4,
                        endRadiusFraction: 0.85
                    )
                )
        }
        .onAppear {
            isVisible = true
            startAnimation()
        }
        .onDisappear {
            isVisible = false
        }
    }

    private func startAnimation() {
        guard isVisible else { return }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
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
            MeshGradientBackground(theme: theme)
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

// MARK: - Liquid Glass Card Modifier

struct LiquidGlassCardModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(cardStyle)
            .shadow(color: theme.primaryColor.opacity(0.2), radius: 15, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var cardStyle: some View {
        ZStack {
            // Subtle tinted background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.cardGlassTint.opacity(0.12))

            // Glass overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.cardBackground)
        }
    }
}

// MARK: - Compact Liquid Glass Card Modifier

struct CompactLiquidGlassCardModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .background(cardStyle)
            .shadow(color: theme.primaryColor.opacity(0.15), radius: 12, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var cardStyle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(theme.cardGlassTint.opacity(0.08))

            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(theme.cardBackground)
        }
    }
}

// MARK: - Focusable Liquid Glass Card Modifier

struct FocusableLiquidGlassCardModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .background(cardStyle)
            .shadow(
                color: isFocused ? theme.primaryColor.opacity(0.35) : theme.primaryColor.opacity(0.15),
                radius: isFocused ? 20 : 12,
                x: 0,
                y: isFocused ? 6 : 4
            )
            .scaleEffect(isFocused ? 1.0 : 0.98)
    }
    
    @ViewBuilder
    private var cardStyle: some View {
        ZStack {
            // More tint when focused
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.cardGlassTint.opacity(isFocused ? 0.18 : 0.12))

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.cardBackground)
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

    /// Standard card style - liquid glass with theme integration
    func cardStyle(theme: AppTheme, cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        modifier(LiquidGlassCardModifier(theme: theme, cornerRadius: cornerRadius))
    }

    /// Compact card style - simplified liquid glass for list items
    func compactCardStyle(theme: AppTheme) -> some View {
        modifier(CompactLiquidGlassCardModifier(theme: theme))
    }
    
    /// Focusable card style - dynamic appearance based on focus state
    func focusableCardStyle(theme: AppTheme, cornerRadius: CGFloat = CornerRadius.lg, isFocused: Bool = false) -> some View {
        modifier(FocusableLiquidGlassCardModifier(theme: theme, cornerRadius: cornerRadius, isFocused: isFocused))
    }
}

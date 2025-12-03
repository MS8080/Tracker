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

    /// Simple soft gradient - theme color fading smoothly to dark
    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                primaryColor.opacity(0.50),
                primaryColor.opacity(0.40),
                primaryColor.opacity(0.30),
                primaryColor.opacity(0.20),
                primaryColor.opacity(0.12),
                primaryColor.opacity(0.06),
                primaryColor.opacity(0.03),
                primaryColor.opacity(0.01)
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

    var body: some View {
        if #available(iOS 18.0, *) {
            // Layered liquid depth background
            ZStack {
                // Base layer: Static mesh gradient (no animation for better performance)
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: staticMeshPoints(),
                    colors: theme.meshColors
                )
                .drawingGroup() // GPU acceleration for mesh gradient

                // REDUCED LAYERS: Only 3 radial gradients instead of 7
                // Layer 2: Top accent glow
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[0].opacity(0.25),
                        theme.liquidDepthColors[0].opacity(0.08),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.15, y: 0.1),
                    startRadius: 0,
                    endRadius: 400
                )

                // Layer 3: Bottom depth pool
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[2].opacity(0.35),
                        theme.liquidDepthColors[3].opacity(0.20),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 1.2),
                    startRadius: 0,
                    endRadius: 600
                )

                // Layer 4: Subtle edge vignette
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [Color.clear, Color.black.opacity(0.15)],
                            center: .center,
                            startRadius: 200,
                            endRadius: 650
                        )
                    )
            }
        } else {
            // iOS 17 fallback with layered liquid effect
            LiquidDepthFallback(theme: theme)
        }
    }

    /// Generate static mesh points for consistent gradient shape
    private func staticMeshPoints() -> [SIMD2<Float>] {
        return [
            // Top row
            SIMD2(0.0, 0.0),
            SIMD2(0.5, 0.0),
            SIMD2(1.0, 0.0),
            // Middle row - slight organic variation for visual interest
            SIMD2(0.0, 0.5),
            SIMD2(0.5, 0.5),
            SIMD2(1.0, 0.5),
            // Bottom row
            SIMD2(0.0, 1.0),
            SIMD2(0.5, 1.0),
            SIMD2(1.0, 1.0)
        ]
    }
}

// MARK: - iOS 17 Liquid Depth Fallback

private struct LiquidDepthFallback: View {
    let theme: AppTheme
    @State private var animationPhase: Double = 0
    @State private var isVisible = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Base layer: Rich multi-tone gradient background
            theme.gradient

            // REDUCED LAYERS: Only 3 animated gradients instead of 7
            // Layer 2: Top accent (animated)
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[0].opacity(0.25),
                    theme.liquidDepthColors[0].opacity(0.10),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.15 + 0.06 * sin(animationPhase * 0.4),
                    y: 0.1 + 0.03 * cos(animationPhase * 0.3)
                ),
                startRadius: 0,
                endRadius: 400
            )

            // Layer 3: Bottom depth (animated)
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[2].opacity(0.35),
                    theme.liquidDepthColors[3].opacity(0.18),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.5 + 0.08 * sin(animationPhase * 0.35),
                    y: 1.15 + 0.05 * cos(animationPhase * 0.4)
                ),
                startRadius: 0,
                endRadius: 600
            )

            // Layer 4: Subtle vignette (static)
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(0.15)],
                        center: .center,
                        startRadius: 200,
                        endRadius: 650
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isVisible {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        guard isVisible && scenePhase == .active else { return }
        // Slower animation: 16 seconds instead of 12
        withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
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



// MARK: - True Liquid Glass Card Modifiers

struct TrueLiquidGlassCardModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat
    let isInteractive: Bool
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // True blur background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Theme-tinted overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.primaryColor.opacity(0.15))
                        .blendMode(.plusLighter)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.25 : 0.15),
                                Color.white.opacity(isPressed ? 0.12 : 0.08),
                                theme.primaryColor.opacity(0.05),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isPressed ? 0.2 : 0.1),
                radius: isPressed ? 8 : 4,
                x: 0,
                y: isPressed ? 4 : 2
            )
            .scaleEffect(isPressed && isInteractive ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                isInteractive ?
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
                : nil
            )
    }
}

struct TrueLiquidGlassCompactModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(theme.primaryColor.opacity(0.12))
                        .blendMode(.plusLighter)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.06),
                                theme.primaryColor.opacity(0.04),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct TrueLiquidGlassFocusableModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat
    let isFocused: Bool
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.primaryColor.opacity(isFocused ? 0.25 : 0.15))
                        .blendMode(.plusLighter)
                    
                    // Extra glow when focused
                    if isFocused {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        theme.primaryColor.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 200
                                )
                            )
                            .blendMode(.screen)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isFocused ? 0.3 : 0.15),
                                Color.white.opacity(isFocused ? 0.15 : 0.08),
                                theme.primaryColor.opacity(isFocused ? 0.08 : 0.05),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isFocused ? 0.15 : 0.1),
                radius: isFocused ? 10 : 4,
                x: 0,
                y: isFocused ? 4 : 2
            )
            .scaleEffect(isFocused ? 1.02 : 0.98)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
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

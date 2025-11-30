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
        HSLColor(
            hue: baseHue(for: theme),
            saturation: min(1.0, baseSaturation(for: theme) + 0.15),
            lightness: 0.65
        )
    }

    /// Gradient top color - lighter, more vibrant
    static func gradientTop(for theme: AppTheme) -> HSLColor {
        HSLColor(
            hue: baseHue(for: theme),
            saturation: baseSaturation(for: theme) * 0.75,
            lightness: 0.38
        )
    }

    /// Gradient upper-mid color
    static func gradientUpperMid(for theme: AppTheme) -> HSLColor {
        // Shift hue slightly toward purple for depth
        let hueShift = theme == .burgundy ? -8.0 : (theme == .purple ? 5.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.8,
            lightness: 0.30
        )
    }

    /// Gradient middle color - rich mid-tone
    static func gradientMid(for theme: AppTheme) -> HSLColor {
        // Deeper saturation in the middle
        let hueShift = theme == .burgundy ? -12.0 : (theme == .purple ? 8.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.85,
            lightness: 0.22
        )
    }

    /// Gradient lower-mid color - transitioning to deep
    static func gradientLowerMid(for theme: AppTheme) -> HSLColor {
        // Shift toward burgundy/plum
        let hueShift = theme == .burgundy ? -15.0 : (theme == .purple ? 12.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.75,
            lightness: 0.16
        )
    }

    /// Gradient bottom color - deep burgundy/plum base
    static func gradientBottom(for theme: AppTheme) -> HSLColor {
        // Deep, rich bottom - shift toward red/burgundy for depth
        let hueShift = theme == .burgundy ? -18.0 : (theme == .purple ? 15.0 : 0.0)
        return HSLColor(
            hue: (baseHue(for: theme) + hueShift + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseSaturation(for: theme) * 0.6,
            lightness: 0.10
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

    /// Card/tile background - frosted glass effect
    var cardBackground: Color {
        return Color.white.opacity(0.15)
    }

    /// Border color for card edges
    var cardBorderColor: Color {
        return Color.white.opacity(0.25)
    }

    /// Shadow color for cards
    var cardShadowColor: Color {
        return Color.black.opacity(0.25)
    }

    /// Generate 9 mesh colors for gradient background - rich liquid depth
    var meshColors: [Color] {
        let baseHue = ThemeColorToken.baseHue(for: self)
        let baseSat = ThemeColorToken.baseSaturation(for: self)

        // Theme-specific adjustments for deep liquid effect
        let (lightnesses, saturations, hueOffsets): ([Double], [Double], [Double])

        switch self {
        case .purple:
            // Purple: Shift toward burgundy/plum at bottom for depth
            lightnesses = [
                0.36, 0.34, 0.32,  // Top row - lighter purple
                0.28, 0.24, 0.22,  // Middle row - transitioning
                0.16, 0.13, 0.10   // Bottom row - deep plum/burgundy
            ]
            saturations = [
                baseSat * 0.80, baseSat * 0.82, baseSat * 0.78,
                baseSat * 0.85, baseSat * 0.88, baseSat * 0.85,
                baseSat * 0.75, baseSat * 0.70, baseSat * 0.60
            ]
            hueOffsets = [
                -5, 0, 5,          // Top row - subtle variation
                8, 12, 10,         // Middle row - shift toward plum
                15, 18, 20         // Bottom row - burgundy/plum territory
            ]
        case .burgundy:
            // Burgundy: Deep wine tones, shift toward purple at top
            lightnesses = [
                0.34, 0.32, 0.30,  // Top row
                0.26, 0.22, 0.20,  // Middle row
                0.14, 0.11, 0.09   // Bottom row - very deep
            ]
            saturations = [
                baseSat * 0.78, baseSat * 0.80, baseSat * 0.76,
                baseSat * 0.82, baseSat * 0.85, baseSat * 0.82,
                baseSat * 0.70, baseSat * 0.65, baseSat * 0.55
            ]
            hueOffsets = [
                5, 0, -5,          // Top row - hint of purple
                -8, -12, -10,      // Middle row - deeper burgundy
                -15, -18, -20      // Bottom row - deep wine
            ]
        case .amber:
            // Amber: Darker and more saturated
            lightnesses = [
                0.34, 0.32, 0.30,
                0.28, 0.25, 0.22,
                0.18, 0.15, 0.12
            ]
            saturations = [
                baseSat * 0.82, baseSat * 0.80, baseSat * 0.78,
                baseSat * 0.85, baseSat * 0.82, baseSat * 0.80,
                baseSat * 0.72, baseSat * 0.68, baseSat * 0.60
            ]
            hueOffsets = [
                -5, 0, 5,
                -8, 0, 8,
                -10, 0, 10
            ]
        case .green:
            // Green: Rich forest tones
            lightnesses = [
                0.35, 0.33, 0.31,
                0.28, 0.25, 0.22,
                0.17, 0.14, 0.11
            ]
            saturations = [
                baseSat * 0.80, baseSat * 0.78, baseSat * 0.76,
                baseSat * 0.82, baseSat * 0.80, baseSat * 0.78,
                baseSat * 0.72, baseSat * 0.68, baseSat * 0.60
            ]
            hueOffsets = [
                -8, 0, 8,
                -5, 0, 5,
                -3, 0, 3
            ]
        default:
            // Blue/Grey: Standard with depth
            lightnesses = [
                0.35, 0.33, 0.31,  // Top row
                0.27, 0.24, 0.21,  // Middle row
                0.16, 0.13, 0.10   // Bottom row - deep
            ]
            saturations = [
                baseSat * 0.75, baseSat * 0.72, baseSat * 0.70,
                baseSat * 0.78, baseSat * 0.75, baseSat * 0.72,
                baseSat * 0.65, baseSat * 0.60, baseSat * 0.50
            ]
            hueOffsets = [
                -8, 0, 8,
                -5, 0, 5,
                -3, 0, 3
            ]
        }

        return (0..<9).map { index in
            HSLColor(
                hue: (baseHue + hueOffsets[index] + 360).truncatingRemainder(dividingBy: 360),
                saturation: saturations[index],
                lightness: lightnesses[index]
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
                // Base layer: Deep rich animated mesh gradient
                TimelineView(.animation(minimumInterval: 1/20, paused: !isVisible)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: meshPoints(time: time),
                        colors: theme.meshColors
                    )
                }

                // Layer 2: Top-left lighter pool (creates depth illusion)
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[0].opacity(0.45),
                        theme.liquidDepthColors[0].opacity(0.15),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.15, y: 0.1),
                    startRadius: 0,
                    endRadius: 380
                )

                // Layer 3: Mid-right pool with plum tones
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[1].opacity(0.4),
                        theme.liquidDepthColors[1].opacity(0.12),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.85, y: 0.35),
                    startRadius: 0,
                    endRadius: 320
                )

                // Layer 4: Center-left mid-depth pool
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[1].opacity(0.3),
                        theme.liquidDepthColors[2].opacity(0.15),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.25, y: 0.55),
                    startRadius: 0,
                    endRadius: 280
                )

                // Layer 5: Deep bottom pool (burgundy/plum depth)
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[2].opacity(0.6),
                        theme.liquidDepthColors[3].opacity(0.4),
                        theme.liquidDepthColors[3].opacity(0.15),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 1.15),
                    startRadius: 0,
                    endRadius: 550
                )

                // Layer 6: Bottom corners - extra depth
                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[3].opacity(0.5),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.0, y: 1.0),
                    startRadius: 0,
                    endRadius: 350
                )

                RadialGradient(
                    colors: [
                        theme.liquidDepthColors[3].opacity(0.5),
                        Color.clear
                    ],
                    center: UnitPoint(x: 1.0, y: 1.0),
                    startRadius: 0,
                    endRadius: 350
                )

                // Layer 7: Subtle vignette for additional depth
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.2)
                    ],
                    center: .center,
                    startRadius: 250,
                    endRadius: 650
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

            // Layer 2: Top-left lighter pool
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[0].opacity(0.5),
                    theme.liquidDepthColors[0].opacity(0.2),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.15 + 0.08 * sin(animationPhase * 0.5),
                    y: 0.1 + 0.04 * cos(animationPhase * 0.4)
                ),
                startRadius: 0,
                endRadius: 380
            )

            // Layer 3: Mid-right plum pool
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[1].opacity(0.4),
                    theme.liquidDepthColors[1].opacity(0.12),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.85 + 0.06 * cos(animationPhase * 0.45),
                    y: 0.35 + 0.05 * sin(animationPhase * 0.5)
                ),
                startRadius: 0,
                endRadius: 320
            )

            // Layer 4: Center-left depth
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[1].opacity(0.3),
                    theme.liquidDepthColors[2].opacity(0.15),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.25 + 0.07 * sin(animationPhase * 0.38),
                    y: 0.55 + 0.05 * cos(animationPhase * 0.42)
                ),
                startRadius: 0,
                endRadius: 280
            )

            // Layer 5: Deep bottom pool (burgundy/plum)
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[2].opacity(0.6),
                    theme.liquidDepthColors[3].opacity(0.35),
                    theme.liquidDepthColors[3].opacity(0.1),
                    .clear
                ],
                center: UnitPoint(
                    x: 0.5 + 0.1 * sin(animationPhase * 0.35),
                    y: 1.15 + 0.06 * cos(animationPhase * 0.4)
                ),
                startRadius: 0,
                endRadius: 550
            )

            // Layer 6: Bottom corners depth
            RadialGradient(
                colors: [
                    theme.liquidDepthColors[3].opacity(0.45),
                    .clear
                ],
                center: UnitPoint(x: 0.0, y: 1.0),
                startRadius: 0,
                endRadius: 350
            )

            RadialGradient(
                colors: [
                    theme.liquidDepthColors[3].opacity(0.45),
                    .clear
                ],
                center: UnitPoint(x: 1.0, y: 1.0),
                startRadius: 0,
                endRadius: 350
            )

            // Layer 7: Vignette for depth
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.2)
                ],
                center: .center,
                startRadius: 250,
                endRadius: 650
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
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
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
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }
}

// MARK: - Compact Liquid Glass Card Modifier

struct CompactLiquidGlassCardModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
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
}

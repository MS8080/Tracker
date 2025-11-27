import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingProfile = false
    @AppStorage("appearance") private var appearance: AppAppearance = .dark
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    @AppStorage("fontSizeScale") private var fontSizeScale: Double = 1.0
    @AppStorage("blueLightFilterEnabled") private var blueLightFilterEnabled: Bool = false

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    private var dynamicTypeSize: DynamicTypeSize {
        switch fontSizeScale {
        case ..<0.85: return .xSmall
        case 0.85..<0.95: return .small
        case 0.95..<1.05: return .medium
        case 1.05..<1.15: return .large
        case 1.15..<1.25: return .xLarge
        case 1.25..<1.35: return .xxLarge
        default: return .xxxLarge
        }
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.dashboard", comment: ""), systemImage: "house.fill")
                    }
                    .tag(0)

                LoggingView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.log", comment: ""), systemImage: "plus.circle.fill")
                    }
                    .tag(1)

                JournalListView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.journal", comment: ""), systemImage: "book.fill")
                    }
                    .tag(2)

                ReportsView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.reports", comment: ""), systemImage: "chart.bar.doc.horizontal")
                    }
                    .tag(3)

                AIInsightsTabView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label("Analyze", systemImage: "sparkles")
                    }
                    .tag(4)
            }

            // Blue light filter overlay
            if blueLightFilterEnabled {
                Color.orange
                    .opacity(0.08)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .tint(theme.primaryColor)
        .preferredColorScheme(appearance.colorScheme)
        .dynamicTypeSize(dynamicTypeSize)
        .sheet(isPresented: $showingProfile) {
            ZStack {
                ProfileContainerView()
                    .themedBackground()
                    .dynamicTypeSize(dynamicTypeSize)

                // Blue light filter for sheet too
                if blueLightFilterEnabled {
                    Color.orange
                        .opacity(0.08)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// AppTheme enum for gradient backgrounds
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

    /// Gradient: colored accent at top fading to dark at bottom
    var gradient: LinearGradient {
        switch self {
        case .purple:
            return LinearGradient(
                colors: [
                    Color(red: 0.32, green: 0.20, blue: 0.45),
                    Color(red: 0.22, green: 0.16, blue: 0.32),
                    Color(red: 0.16, green: 0.14, blue: 0.20),
                    Color(red: 0.12, green: 0.12, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .blue:
            return LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.24, blue: 0.42),
                    Color(red: 0.14, green: 0.18, blue: 0.30),
                    Color(red: 0.12, green: 0.14, blue: 0.20),
                    Color(red: 0.12, green: 0.12, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .green:
            return LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.30, blue: 0.22),
                    Color(red: 0.12, green: 0.22, blue: 0.18),
                    Color(red: 0.12, green: 0.16, blue: 0.14),
                    Color(red: 0.12, green: 0.12, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .orange:
            return LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.28, blue: 0.16),
                    Color(red: 0.30, green: 0.22, blue: 0.16),
                    Color(red: 0.18, green: 0.16, blue: 0.14),
                    Color(red: 0.12, green: 0.12, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .burgundy:
            return LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.16, blue: 0.24),
                    Color(red: 0.30, green: 0.16, blue: 0.20),
                    Color(red: 0.18, green: 0.14, blue: 0.16),
                    Color(red: 0.12, green: 0.12, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .grey:
            return LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.28, blue: 0.32),
                    Color(red: 0.22, green: 0.22, blue: 0.26),
                    Color(red: 0.16, green: 0.16, blue: 0.18),
                    Color(red: 0.12, green: 0.12, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var previewColor: Color {
        switch self {
        case .purple: return Color(red: 0.50, green: 0.27, blue: 0.70)
        case .blue: return Color(red: 0.20, green: 0.35, blue: 0.55)
        case .green: return Color(red: 0.20, green: 0.40, blue: 0.30)
        case .orange: return Color(red: 0.55, green: 0.35, blue: 0.20)
        case .burgundy: return Color(red: 0.50, green: 0.20, blue: 0.28)
        case .grey: return Color(red: 0.40, green: 0.40, blue: 0.45)
        }
    }

    var textColor: Color {
        return .white
    }

    var secondaryTextColor: Color {
        textColor.opacity(0.7)
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

    /// Card/tile background - darker for better text visibility
    var cardBackground: Color {
        return Color.black.opacity(0.25)
    }

    /// Alias for consistency (same as cardBackground)
    var journalCardBackground: Color {
        return cardBackground
    }
}

// AppAppearance enum must be accessible here
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

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}

#Preview {
    ContentView()
}

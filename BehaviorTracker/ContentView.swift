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

                CalendarView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.calendar", comment: ""), systemImage: "calendar")
                    }
                    .tag(1)

                LoggingView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.log", comment: ""), systemImage: "plus.circle.fill")
                    }
                    .tag(2)

                JournalListView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.journal", comment: ""), systemImage: "book.fill")
                    }
                    .tag(3)

                ReportsView(showingProfile: $showingProfile)
                    .themedBackground()
                    .tabItem {
                        Label(NSLocalizedString("tab.reports", comment: ""), systemImage: "chart.bar.doc.horizontal")
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
enum AppTheme: String, CaseIterable {
    case purple = "Purple"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case pink = "Pink"

    var primaryColor: Color {
        switch self {
        case .purple: return .purple
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .purple:
            return LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.1, blue: 0.4),
                    Color(red: 0.15, green: 0.1, blue: 0.35),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blue:
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.05, green: 0.15, blue: 0.35),
                    Color(red: 0.05, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.3, blue: 0.2),
                    Color(red: 0.05, green: 0.2, blue: 0.15),
                    Color(red: 0.05, green: 0.15, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.1),
                    Color(red: 0.3, green: 0.15, blue: 0.05),
                    Color(red: 0.2, green: 0.1, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.1, blue: 0.25),
                    Color(red: 0.3, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// AppAppearance enum must be accessible here
enum AppAppearance: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"

    var displayName: String {
        rawValue
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

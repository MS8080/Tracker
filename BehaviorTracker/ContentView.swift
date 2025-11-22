import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingProfile = false
    @AppStorage("appearance") private var appearance: AppAppearance = .system
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DashboardView(showingProfile: $showingProfile)
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)

                LoggingView(showingProfile: $showingProfile)
                    .tabItem {
                        Label("Log", systemImage: "plus.circle.fill")
                    }
                    .tag(1)

                JournalListView(showingProfile: $showingProfile)
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }
                    .tag(2)

                ReportsView(showingProfile: $showingProfile)
                    .tabItem {
                        Label("Reports", systemImage: "chart.bar.doc.horizontal")
                    }
                    .tag(3)
            }
            .preferredColorScheme(appearance.colorScheme)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileContainerView()
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
    
    var gradient: LinearGradient {
        switch self {
        case .purple:
            return LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blue:
            return LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// AppAppearance enum must be accessible here
enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#Preview {
    ContentView()
}

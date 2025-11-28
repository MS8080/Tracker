import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingProfile = false
    @AppStorage("appearance") private var appearance: AppAppearance = .dark
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    @AppStorage("fontSizeScale") private var fontSizeScale: Double = 1.0

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
        TabView(selection: $selectedTab) {
            HomeView(showingProfile: $showingProfile)
                .themedBackground()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
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
        }
        .blueLightFilter()
        .tint(theme.primaryColor)  // Match the selected theme!
        .preferredColorScheme(appearance.colorScheme)
        .dynamicTypeSize(dynamicTypeSize)
        .sheet(isPresented: $showingProfile) {
            ProfileContainerView()
                .themedBackground()
                .blueLightFilter()
                .dynamicTypeSize(dynamicTypeSize)
        }
    }
}

#Preview {
    ContentView()
}

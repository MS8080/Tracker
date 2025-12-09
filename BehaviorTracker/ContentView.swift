import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingProfile = false
    @AppStorage("appearance") private var appearance: AppAppearance = .dark
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    @AppStorage("fontSizeScale") private var fontSizeScale: Double = 1.0
    @StateObject private var networkMonitor = NetworkMonitor.shared

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

            DynamicJournalView(showingProfile: $showingProfile)
                .themedBackground()
                .tabItem {
                    Label(NSLocalizedString("tab.journal", comment: ""), systemImage: "book.fill")
                }
                .tag(1)

            InsightsView(showingProfile: $showingProfile)
                .themedBackground()
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
                .tag(2)

            ReportsView(showingProfile: $showingProfile)
                .themedBackground()
                .tabItem {
                    Label(NSLocalizedString("tab.reports", comment: ""), systemImage: "chart.bar.doc.horizontal")
                }
                .tag(3)
        }
        .onAppear {
            configureTabBarAppearance()
        }
        .blueLightFilter()
        .tint(theme.accentColor)  // Use brighter accent color for tabs
        .preferredColorScheme(appearance.colorScheme)
        .dynamicTypeSize(dynamicTypeSize)
        .sheet(isPresented: $showingProfile) {
            // Lazy wrapper to defer ProfileContainerView construction
            LazyProfileSheet()
        }
        .overlay(alignment: .top) {
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Darker, more opaque background for better contrast
        appearance.backgroundColor = UIColor.black.withAlphaComponent(TabBarStyle.backgroundOpacity)

        // Stronger blur effect
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        // Enhance unselected item appearance
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(TabBarStyle.unselectedItemOpacity)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(TabBarStyle.unselectedItemOpacity)
        ]
        
        // Selected items will use the tint color (theme.accentColor)
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Lazy Profile Sheet Wrapper

/// Wrapper for ProfileContainerView
private struct LazyProfileSheet: View {
    var body: some View {
        ProfileContainerView()
            .presentationDragIndicator(.visible)
            .presentationDetents([.large])
            .presentationContentInteraction(.scrolls)
    }
}

// MARK: - Offline Banner

private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
            Text("No Internet Connection")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.orange.gradient, in: Capsule())
        .padding(.top, 50) // Account for safe area
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

#Preview {
    ContentView()
}

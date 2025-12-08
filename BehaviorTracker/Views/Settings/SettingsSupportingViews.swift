import SwiftUI

// MARK: - Favorite Patterns View

struct FavoritePatternsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedPatterns: Set<String> = []

    var body: some View {
        List {
            ForEach(PatternCategory.allCases, id: \.self) { category in
                Section(category.rawValue) {
                    ForEach(patternsInCategory(category), id: \.self) { patternType in
                        Button {
                            toggleFavorite(patternType)
                        } label: {
                            HStack {
                                Text(patternType.rawValue)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if viewModel.favoritePatterns.contains(patternType.rawValue) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                } else {
                                    Image(systemName: "star")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorite Patterns")
        .navigationBarTitleDisplayModeInline()
    }

    private func patternsInCategory(_ category: PatternCategory) -> [PatternType] {
        PatternType.allCases.filter { $0.category == category }
    }

    private func toggleFavorite(_ patternType: PatternType) {
        viewModel.toggleFavorite(patternType: patternType)
    }
}

// MARK: - Enhanced Data Privacy View

struct EnhancedDataPrivacyView: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    InfoBox(
                        icon: "lock.shield.fill",
                        title: "Local Storage Only",
                        message: "All your data is stored exclusively on your device. Nothing is sent to external servers.",
                        color: .blue
                    )

                    InfoBox(
                        icon: "eye.slash.fill",
                        title: "No Tracking",
                        message: "This app does not collect any analytics, usage data, or personal information.",
                        color: .purple
                    )

                    InfoBox(
                        icon: "cloud.fill",
                        title: "Optional iCloud Sync",
                        message: "iCloud sync is disabled by default. You can enable it in iOS Settings to sync across your devices.",
                        color: .cyan
                    )

                    InfoBox(
                        icon: "shield.checkmark.fill",
                        title: "Your Data, Your Control",
                        message: "You can export or delete your data at any time. The app works completely offline.",
                        color: .green
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About View

struct AboutView: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Infinity Logo
                Image("InfinityLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 75)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    .padding(.top, 40)

                Text("Cortex")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(appVersion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("A comprehensive tool for tracking behavioral patterns and generating insightful analytical reports.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

                // Features Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Features")
                        .font(.headline)
                        .padding(.bottom, 4)

                    FeatureGroup(title: "Dashboard", features: [
                        "Personalized daily greeting",
                        "Quick notes for what's special today",
                        "Upcoming calendar events",
                        "Logging streak tracking",
                        "Daily entry slideshow",
                        "Memories from past years",
                        "Current setup overview",
                        "Life goals tracking"
                    ])

                    FeatureGroup(title: "Journal", features: [
                        "Voice recording with AI transcription",
                        "Dynamic day-by-day view",
                        "AI-powered entry analysis",
                        "Day summaries and insights",
                        "Rich text entry editing"
                    ])

                    FeatureGroup(title: "Pattern Tracking", features: [
                        "Category-based behavior logging",
                        "Favorite patterns for quick access",
                        "Feeling Finder guided logging",
                        "HealthKit integration",
                        "Searchable categories"
                    ])

                    FeatureGroup(title: "Reports & Insights", features: [
                        "Weekly and monthly reports",
                        "AI-powered analysis (Gemini)",
                        "ASD-focused insights",
                        "Pattern correlation analysis",
                        "Visual charts and trends",
                        "Data export (JSON/CSV)"
                    ])

                    FeatureGroup(title: "Medications", features: [
                        "Medication tracking",
                        "Dose logging",
                        "Import medications list"
                    ])

                    FeatureGroup(title: "Personalization", features: [
                        "Multiple color themes",
                        "Light and dark mode",
                        "Adjustable font sizes",
                        "Blue light filter",
                        "Haptic feedback"
                    ])

                    FeatureGroup(title: "Privacy & Security", features: [
                        "All data stored locally",
                        "Secure Keychain for API keys",
                        "No tracking or analytics",
                        "Optional iCloud sync"
                    ])
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer(minLength: 40)

                Text("Created by MS")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Group Component

private struct FeatureGroup: View {
    let title: String
    let features: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.top, 2)
                    Text(feature)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Previews

#Preview("FavoritePatternsView") {
    NavigationStack {
        FavoritePatternsView(viewModel: SettingsViewModel())
    }
}

#Preview("EnhancedDataPrivacyView") {
    NavigationStack {
        EnhancedDataPrivacyView(theme: .purple)
    }
}

#Preview("AboutView") {
    NavigationStack {
        AboutView()
    }
}

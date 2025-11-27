import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingExportSheet = false
    @AppStorage("appearance") private var appearance: AppAppearance = .dark

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $appearance) {
                        ForEach(AppAppearance.allCases, id: \.self) { option in
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.displayName)
                            }
                            .tag(option)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundStyle(.purple)
                            Text("Appearance")
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Theme")
                }

                Section {
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.blue)
                            Text("Daily Reminders")
                        }
                    }

                    if viewModel.notificationsEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $viewModel.notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Notifications")
                }

                Section {
                    NavigationLink {
                        FavoritePatternsView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Manage Favorites")
                            Spacer()
                            Text("\(viewModel.favoritePatterns.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Quick Logging")
                }

                Section {
                    Button {
                        showingExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.green)
                            Text("Export Data")
                        }
                    }

                    NavigationLink {
                        DataPrivacyView()
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(.blue)
                            Text("Privacy & Security")
                        }
                    }
                } header: {
                    Text("Data")
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.purple)
                            Text("About")
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(viewModel: viewModel)
            }
        }
    }
}

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

struct DataPrivacyView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                privacySection(
                    icon: "lock.fill",
                    color: .blue,
                    title: "Local Storage Only",
                    description: "All your data is stored exclusively on your device. Nothing is sent to external servers."
                )

                privacySection(
                    icon: "eye.slash.fill",
                    color: .purple,
                    title: "No Tracking",
                    description: "This app does not collect any analytics, usage data, or personal information."
                )

                privacySection(
                    icon: "cloud.fill",
                    color: .cyan,
                    title: "Optional iCloud Sync",
                    description: "iCloud sync is disabled by default. You can enable it in iOS Settings to sync across your devices."
                )

                privacySection(
                    icon: "shield.fill",
                    color: .green,
                    title: "Your Data, Your Control",
                    description: "You can export or delete your data at any time. The app works completely offline."
                )
            }
            .padding()
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayModeInline()
    }

    private func privacySection(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
        )
    }
}

struct AboutView: View {
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

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("A comprehensive tool for tracking behavioral patterns and generating insightful analytical reports.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

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

#Preview {
    SettingsView()
}

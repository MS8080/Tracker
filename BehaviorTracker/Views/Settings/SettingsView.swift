import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingExportSheet = false
    @AppStorage("appearance") private var appearance: AppAppearance = .dark
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Theme Section
                        themeSection

                        // Notifications Section
                        notificationsSection

                        // Quick Logging Section
                        quickLoggingSection

                        // Data Section
                        dataSection

                        // About Section
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(viewModel: viewModel)
            }
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Theme", icon: "paintbrush.fill")
            
            Picker(selection: $appearance) {
                ForEach(AppAppearance.allCases, id: \.self) { option in
                    HStack {
                        Image(systemName: option.icon)
                        Text(option.displayName)
                    }
                    .tag(option)
                }
            } label: {
                HStack(spacing: 14) {
                    ThemedIcon(
                        systemName: "paintbrush.fill",
                        color: .purple,
                        size: 40,
                        backgroundStyle: .roundedSquare
                    )
                    
                    Text("Appearance")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(CardText.body)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .pickerStyle(.menu)
            .cardStyle(theme: theme, cornerRadius: 14)
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Notifications", icon: "bell.fill")
            
            VStack(spacing: 0) {
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    HStack(spacing: 14) {
                        ThemedIcon(
                            systemName: "bell.fill",
                            color: .blue,
                            size: 40,
                            backgroundStyle: .roundedSquare
                        )
                        
                        Text("Daily Reminders")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(CardText.body)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .tint(theme.primaryColor)
                
                if viewModel.notificationsEnabled {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    DatePicker(
                        "Reminder Time",
                        selection: $viewModel.notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .tint(theme.primaryColor)
                }
            }
            .cardStyle(theme: theme, cornerRadius: 14)
        }
    }

    private var quickLoggingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Quick Logging", icon: "bolt.fill")
            
            NavigationLink {
                FavoritePatternsView(viewModel: viewModel)
            } label: {
                HStack(spacing: 14) {
                    ThemedIcon(
                        systemName: "star.fill",
                        color: .yellow,
                        size: 40,
                        backgroundStyle: .roundedSquare
                    )
                    
                    Text("Manage Favorites")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(CardText.body)

                    Spacer()

                    BadgeView(
                        text: "\(viewModel.favoritePatterns.count)",
                        color: theme.primaryColor
                    )

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(CardText.muted)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .cardStyle(theme: theme, cornerRadius: 14)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Data", icon: "externaldrive.fill")
            
            VStack(spacing: 8) {
                Button {
                    showingExportSheet = true
                } label: {
                    SettingsRow(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        color: .green,
                        theme: theme,
                        action: { showingExportSheet = true }
                    )
                }
                
                NavigationLink {
                    EnhancedDataPrivacyView(theme: theme)
                } label: {
                    HStack(spacing: 14) {
                        ThemedIcon(
                            systemName: "lock.shield.fill",
                            color: .blue,
                            size: 40,
                            backgroundStyle: .roundedSquare
                        )
                        
                        Text("Privacy & Security")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(CardText.body)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(CardText.muted)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .cardStyle(theme: theme, cornerRadius: 14)
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "About", icon: "info.circle.fill")
            
            VStack(spacing: 8) {
                HStack(spacing: 14) {
                    ThemedIcon(
                        systemName: "info.circle.fill",
                        color: .blue,
                        size: 40,
                        backgroundStyle: .roundedSquare
                    )
                    
                    Text("Version")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(CardText.body)

                    Spacer()
                    Text("1.0.0")
                        .font(.callout)
                        .foregroundStyle(CardText.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .cardStyle(theme: theme, cornerRadius: 14)

                NavigationLink {
                    AboutView()
                } label: {
                    HStack(spacing: 14) {
                        ThemedIcon(
                            systemName: "doc.text.fill",
                            color: .purple,
                            size: 40,
                            backgroundStyle: .roundedSquare
                        )

                        Text("About")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(CardText.body)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(CardText.muted)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .cardStyle(theme: theme, cornerRadius: 14)
                }
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

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

#Preview {
    SettingsView()
}

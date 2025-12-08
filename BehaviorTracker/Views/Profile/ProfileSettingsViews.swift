import SwiftUI

// MARK: - Settings Section

struct ProfileSettingsSection: View {
    @Binding var isExpanded: Bool
    @ObservedObject var settingsViewModel: SettingsViewModel

    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.gray)
                    .font(.title3)
                Text("Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.bottom, isExpanded ? 16 : 0)

            if isExpanded {
                SettingsExpandedContent(settingsViewModel: settingsViewModel)
            }
        }
        .padding()
        .cardStyle(theme: theme)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Settings Expanded Content

struct SettingsExpandedContent: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject private var demoMode = DemoModeService.shared

    enum SettingsDestination: Hashable {
        case appearance
        case notifications
        case exportData
        case about
    }

    var body: some View {
        VStack(spacing: 12) {
            // Demo Mode Toggle
            DemoModeToggleRow(isEnabled: $demoMode.isEnabled)

            Divider()
                .background(.white.opacity(0.1))

            NavigationLink(value: SettingsDestination.appearance) {
                ModernSettingsRow(
                    icon: "paintbrush.fill",
                    iconColor: .purple,
                    iconBackground: .purple.opacity(0.15),
                    title: "Appearance",
                    subtitle: "Theme & display"
                )
            }

            NavigationLink(value: SettingsDestination.notifications) {
                ModernSettingsRow(
                    icon: "bell.badge.fill",
                    iconColor: .red,
                    iconBackground: .red.opacity(0.15),
                    title: "Notifications",
                    subtitle: "Reminders & alerts"
                )
            }

            NavigationLink(value: SettingsDestination.exportData) {
                ModernSettingsRow(
                    icon: "square.and.arrow.up.fill",
                    iconColor: .green,
                    iconBackground: .green.opacity(0.15),
                    title: "Export Data",
                    subtitle: "Backup your data"
                )
            }

            NavigationLink(value: SettingsDestination.about) {
                ModernSettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .cyan,
                    iconBackground: .cyan.opacity(0.15),
                    title: "About",
                    subtitle: "Version & info"
                )
            }
        }
        .navigationDestination(for: SettingsDestination.self) { destination in
            switch destination {
            case .appearance:
                AppearanceSettingsView(viewModel: settingsViewModel)
            case .notifications:
                NotificationSettingsView(viewModel: settingsViewModel)
            case .exportData:
                ExportDataView(viewModel: settingsViewModel)
            case .about:
                AboutView()
            }
        }
    }
}

// MARK: - Demo Mode Toggle Row

struct DemoModeToggleRow: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon with background
            Image(systemName: "play.rectangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Demo Mode")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(isEnabled ? "Showing sample data" : "Show sample data for demos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(.orange)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Modern Settings Row

struct ModernSettingsRow: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon with simple tinted background
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                )

            // Title and subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Previews

#Preview("ModernSettingsRow") {
    ModernSettingsRow(
        icon: "paintbrush.fill",
        iconColor: .purple,
        iconBackground: .purple.opacity(0.15),
        title: "Appearance",
        subtitle: "Theme & display"
    )
    .padding()
    .background(Color.black)
}

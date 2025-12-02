import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @ThemeWrapper var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                dailyRemindersSection
                infoCard
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Daily Reminders Section

    private var dailyRemindersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                Text("Daily Reminders")
                    .font(.headline)
            }

            // Toggle card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Reminders")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Get notified to log your patterns")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
                    .tint(.blue)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.05))
            )

            if viewModel.notificationsEnabled {
                timePickerCard
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
        .animation(.spring(response: 0.15, dampingFraction: 0.7), value: viewModel.notificationsEnabled)
    }

    // MARK: - Time Picker Card

    private var timePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                Text("Reminder Time")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            DatePicker(
                "",
                selection: $viewModel.notificationTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.05))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("About Notifications")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("Daily reminders help you build a consistent tracking habit. You can change the time or disable them anytime.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.blue.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(viewModel: SettingsViewModel())
    }
}

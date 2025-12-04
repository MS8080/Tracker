import SwiftUI

// MARK: - Profile Toolbar Controls

struct ProfileToolbarControls: View {
    @Binding var fontSizeScale: Double
    @Binding var blueLightFilterEnabled: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Font size controls pill
            HStack(spacing: 0) {
                Button {
                    if fontSizeScale > 0.8 {
                        fontSizeScale -= 0.1
                        HapticFeedback.light.trigger()
                    }
                } label: {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(fontSizeScale <= 0.8 ? .white.opacity(0.4) : .white)
                        .frame(width: 32, height: 32)
                }
                .disabled(fontSizeScale <= 0.8)

                Divider()
                    .frame(height: 18)
                    .opacity(0.5)

                Button {
                    if fontSizeScale < 1.4 {
                        fontSizeScale += 0.1
                        HapticFeedback.light.trigger()
                    }
                } label: {
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(fontSizeScale >= 1.4 ? .white.opacity(0.4) : .white)
                        .frame(width: 32, height: 32)
                }
                .disabled(fontSizeScale >= 1.4)
            }
            .background(.ultraThinMaterial, in: Capsule())

            // Blue light filter circle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    blueLightFilterEnabled.toggle()
                }
                HapticFeedback.light.trigger()
            } label: {
                Image(systemName: blueLightFilterEnabled ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        blueLightFilterEnabled ? Color.orange.opacity(0.5) : Color.white.opacity(0.1),
                        in: Circle()
                    )
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }
}

// MARK: - Profile Header Section

struct ProfileHeaderSection: View {
    let profile: UserProfile?
    let onEditTapped: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if let profileImage = profile?.profileImage {
                    #if os(iOS)
                    Image(uiImage: profileImage)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    #elseif os(macOS)
                    Image(nsImage: profileImage)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    #endif
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(profile?.initials ?? "?")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                }

                Circle()
                    .fill(.blue)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 36, y: 36)
            }
            .onTapGesture { onEditTapped() }

            VStack(spacing: 6) {
                Text(profile?.name ?? "User")
                    .font(.title)
                    .fontWeight(.bold)

                if let email = profile?.email, !email.isEmpty {
                    Text(email)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                if let age = profile?.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Health Data Section

struct ProfileHealthDataSection: View {
    let healthSummary: HealthDataSummary?
    let isAuthorized: Bool
    let isLoading: Bool
    let onRefresh: () -> Void
    let onConnect: () async -> Void

    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("Health Data")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        onRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }

            if !isAuthorized {
                VStack(spacing: 12) {
                    Text("Connect to Apple Health to see your health data")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Connect Apple Health") {
                        Task {
                            await onConnect()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let summary = healthSummary {
                HealthDataGrid(summary: summary)
            } else {
                Text("No health data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .cardStyle(theme: theme)
    }
}

// MARK: - Health Data Grid

struct HealthDataGrid: View {
    let summary: HealthDataSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let steps = summary.steps {
                HealthStatCard(icon: "figure.walk", title: "Steps", value: "\(Int(steps))", color: .green)
            }
            if let heartRate = summary.heartRate {
                HealthStatCard(icon: "heart.fill", title: "Heart Rate", value: "\(Int(heartRate)) bpm", color: .red)
            }
            if let sleepHours = summary.sleepHours {
                HealthStatCard(icon: "bed.double.fill", title: "Sleep", value: String(format: "%.1f hrs", sleepHours), color: .purple)
            }
            if let energy = summary.activeEnergy {
                HealthStatCard(icon: "flame.fill", title: "Active Energy", value: "\(Int(energy)) kcal", color: .orange)
            }
            if let exercise = summary.exerciseMinutes {
                HealthStatCard(icon: "figure.run", title: "Exercise", value: "\(Int(exercise)) min", color: .cyan)
            }
            if let weight = summary.weight {
                HealthStatCard(icon: "scalemass.fill", title: "Weight", value: String(format: "%.1f kg", weight), color: .blue)
            }
            if let water = summary.waterIntake {
                HealthStatCard(icon: "drop.fill", title: "Water", value: String(format: "%.1f L", water), color: .blue)
            }
        }
    }
}

// MARK: - Medications Section

struct ProfileMedicationsSection: View {
    let medications: [Medication]
    @Binding var isExpanded: Bool
    let hasTakenToday: (Medication) -> Bool
    let onAddTapped: () -> Void
    let onImportTapped: () -> Void
    @ObservedObject var medicationViewModel: MedicationViewModel

    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Medications")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if !medications.isEmpty {
                    Text("\(medications.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.white.opacity(0.12)))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.bottom, isExpanded ? 12 : 0)

            if isExpanded {
                MedicationsExpandedContent(
                    medications: medications,
                    hasTakenToday: hasTakenToday,
                    onAddTapped: onAddTapped,
                    onImportTapped: onImportTapped,
                    medicationViewModel: medicationViewModel
                )
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

// MARK: - Medications Expanded Content

struct MedicationsExpandedContent: View {
    let medications: [Medication]
    let hasTakenToday: (Medication) -> Bool
    let onAddTapped: () -> Void
    let onImportTapped: () -> Void
    @ObservedObject var medicationViewModel: MedicationViewModel

    var body: some View {
        VStack(spacing: 12) {
            if medications.isEmpty {
                VStack(spacing: 12) {
                    Text("No medications added")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 8) {
                        Button {
                            onImportTapped()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import from Health")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.green.opacity(0.8)))
                        }
                        .buttonStyle(.plain)

                        Button {
                            onAddTapped()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Manually")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.cyan.opacity(0.8)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(medications) { medication in
                    NavigationLink {
                        MedicationDetailView(medication: medication, viewModel: medicationViewModel)
                    } label: {
                        ProfileMedicationRowView(
                            medication: medication,
                            hasTakenToday: hasTakenToday(medication)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button {
                    onAddTapped()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.cyan)
                        Text("Add Medication")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

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

    enum SettingsDestination: Hashable {
        case appearance
        case notifications
        case exportData
        case about
    }

    var body: some View {
        VStack(spacing: 12) {
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

// MARK: - Health Stat Card

struct HealthStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    @ThemeWrapper var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .compactCardStyle(theme: theme)
    }
}

// MARK: - Profile Medication Row View

struct ProfileMedicationRowView: View {
    let medication: Medication
    let hasTakenToday: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if let dosage = medication.dosage {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if hasTakenToday {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
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

#Preview("HealthStatCard") {
    HealthStatCard(
        icon: "figure.walk",
        title: "Steps",
        value: "8,432",
        color: .green
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}

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

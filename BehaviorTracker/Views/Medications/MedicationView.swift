import SwiftUI

struct MedicationView: View {
    @StateObject private var viewModel = MedicationViewModel()
    @State private var showingAddMedication = false
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        NavigationView {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Demo mode indicator
                        if viewModel.isDemoMode {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Demo Mode - Sample Data")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.2), in: Capsule())
                        }

                        if viewModel.isDemoMode {
                            demoMedicationsSection
                        } else {
                            allMedicationsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Medications")
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadMedications()
                viewModel.loadTodaysLogs()
            }
        }
    }

    // MARK: - Demo Medications Section

    private var demoMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(
                title: "My Medications",
                icon: "pills.fill",
                actionTitle: nil,
                action: nil
            )

            VStack(spacing: 12) {
                ForEach(viewModel.demoMedications) { medication in
                    DemoMedicationCard(medication: medication, theme: theme)
                }
            }
        }
    }

    private var allMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(
                title: "My Medications",
                icon: "pills.fill",
                actionTitle: viewModel.medications.isEmpty ? nil : "Add",
                action: viewModel.medications.isEmpty ? nil : { showingAddMedication = true }
            )

            if viewModel.medications.isEmpty {
                EmptyStateView(
                    icon: "pills.circle.fill",
                    title: "No Medications Yet",
                    message: "Start tracking your medications to monitor adherence and effectiveness",
                    actionTitle: "Add Your First Medication",
                    action: { showingAddMedication = true }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.medications) { medication in
                        NavigationLink(destination: MedicationDetailView(medication: medication, viewModel: viewModel)) {
                            EnhancedMedicationCard(medication: medication, viewModel: viewModel, theme: theme)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Add Medication button at bottom
                Button {
                    showingAddMedication = true
                } label: {
                    HStack(spacing: 12) {
                        ThemedIcon(
                            systemName: "plus",
                            color: theme.primaryColor,
                            size: 36,
                            backgroundStyle: .circle
                        )
                        
                        Text("Add Medication")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(theme.accentLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                                    .foregroundStyle(theme.accentMedium)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 8)
            }
        }
    }
}

struct EnhancedMedicationCard: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 16) {
            // Icon with adherence indicator
            ZStack(alignment: .bottomTrailing) {
                ThemedIcon(
                    systemName: "pills.fill",
                    color: theme.primaryColor,
                    size: 56,
                    backgroundStyle: .roundedSquare
                )
                
                // Adherence indicator dot
                let adherence = viewModel.getAdherenceRate(for: medication, days: 7)
                Circle()
                    .fill(adherenceColor(adherence))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2.5)
                    )
                    .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(medication.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let dosage = medication.dosage {
                    HStack(spacing: 6) {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .font(.caption2)
                            .foregroundStyle(theme.primaryColor)
                        Text(dosage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Frequency badge
                BadgeView(
                    text: medication.frequency,
                    color: theme.primaryColor,
                    icon: "clock"
                )
            }

            Spacer()

            // Adherence stat
            VStack(alignment: .trailing, spacing: 4) {
                let adherence = viewModel.getAdherenceRate(for: medication, days: 7)
                Text("\(Int(adherence))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(adherenceColor(adherence))

                Text("adherence")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.quaternary)
        }
        .padding(16)
        .compactCardStyle(theme: theme)
    }

    private func adherenceColor(_ rate: Double) -> Color {
        if rate >= 80 {
            return .green
        } else if rate >= 60 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Demo Medication Card

struct DemoMedicationCard: View {
    let medication: DemoMedicationWrapper
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 16) {
            // Icon with status indicator
            ZStack(alignment: .bottomTrailing) {
                ThemedIcon(
                    systemName: "pills.fill",
                    color: theme.primaryColor,
                    size: 56,
                    backgroundStyle: .roundedSquare
                )

                // Taken today indicator
                Circle()
                    .fill(medication.takenToday ? .green : .orange)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2.5)
                    )
                    .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(medication.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let dosage = medication.dosage {
                    HStack(spacing: 6) {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .font(.caption2)
                            .foregroundStyle(theme.primaryColor)
                        Text(dosage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Frequency badge
                BadgeView(
                    text: medication.frequency,
                    color: theme.primaryColor,
                    icon: "clock"
                )
            }

            Spacer()

            // Status
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: medication.takenToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(medication.takenToday ? .green : .secondary)

                Text(medication.takenToday ? "Taken" : "Pending")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .compactCardStyle(theme: theme)
    }
}

#Preview {
    MedicationView()
}

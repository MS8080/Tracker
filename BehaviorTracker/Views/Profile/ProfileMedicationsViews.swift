import SwiftUI

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

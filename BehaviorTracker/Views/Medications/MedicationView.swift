import SwiftUI

struct MedicationView: View {
    @StateObject private var viewModel = MedicationViewModel()
    @State private var showingAddMedication = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(PlatformColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // All Medications Section (shows all, not just today's)
                        allMedicationsSection
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

    private var todaysMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Medications")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.medications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No medications added yet")
                        .foregroundColor(.secondary)
                    Button("Add Your First Medication") {
                        showingAddMedication = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(PlatformColor.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ForEach(viewModel.medications) { medication in
                    MedicationDailyCard(medication: medication, viewModel: viewModel)
                }
                .padding(.horizontal)
            }
        }
    }

    private var allMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Medications")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.medications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No medications added yet")
                        .foregroundColor(.secondary)
                    Button("Add Your First Medication") {
                        showingAddMedication = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(PlatformColor.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ForEach(viewModel.medications) { medication in
                    NavigationLink(destination: MedicationDetailView(medication: medication, viewModel: viewModel)) {
                        MedicationListCard(medication: medication, viewModel: viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }

                // Add Medication button at bottom
                Button(action: {
                    showingAddMedication = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Medication")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
}

struct MedicationDailyCard: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel
    @State private var showingLogSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                    if let dosage = medication.dosage {
                        Text(dosage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if viewModel.hasTakenToday(medication: medication) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Button(action: {
                        showingLogSheet = true
                    }) {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }

            if let log = viewModel.getTodaysLog(for: medication) {
                if log.taken {
                    HStack(spacing: 16) {
                        if log.effectiveness > 0 {
                            StatBadge(icon: "star.fill", value: "\(log.effectiveness)/5", label: "Effect")
                        }
                        if log.mood > 0 {
                            StatBadge(icon: "face.smiling", value: "\(log.mood)/5", label: "Mood")
                        }
                        if log.energyLevel > 0 {
                            StatBadge(icon: "bolt.fill", value: "\(log.energyLevel)/5", label: "Energy")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(PlatformColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingLogSheet) {
            LogMedicationView(medication: medication, viewModel: viewModel)
        }
    }
}

struct MedicationListCard: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Pill icon
            Image(systemName: "pills.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let dosage = medication.dosage {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(medication.frequency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                let adherence = viewModel.getAdherenceRate(for: medication, days: 7)
                Text("\(Int(adherence))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(adherenceColor(adherence))

                Text("adherence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Chevron to indicate tappable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(PlatformColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle()) // Makes entire card tappable
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

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(PlatformColor.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    MedicationView()
}

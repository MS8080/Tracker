import SwiftUI

struct MedicationsView: View {
    @EnvironmentObject var connectivity: WatchConnectivityService
    @State private var showingConfirmation = false
    @State private var confirmedMedication = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Medications")
                    .font(.title3)
                    .fontWeight(.bold)

                if connectivity.upcomingMedications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)

                        Text("All caught up!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("No upcoming medications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(Array(connectivity.upcomingMedications.enumerated()), id: \.offset) { index, med in
                        if let name = med["name"] as? String,
                           let dosage = med["dosage"] as? String,
                           let taken = med["taken"] as? Bool {
                            MedicationRow(
                                name: name,
                                dosage: dosage,
                                taken: taken,
                                onTap: {
                                    markAsTaken(name)
                                }
                            )
                        }
                    }
                }

                if !connectivity.isReachable {
                    Text("Connect iPhone to update")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top)
                }
            }
            .padding()
        }
        .alert("Marked as Taken", isPresented: $showingConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(confirmedMedication) logged successfully")
        }
    }

    private func markAsTaken(_ medicationName: String) {
        connectivity.markMedicationTaken(medicationName: medicationName)
        confirmedMedication = medicationName
        showingConfirmation = true
    }
}

struct MedicationRow: View {
    let name: String
    let dosage: String
    let taken: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: taken ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(taken ? .green : .gray)
                    .font(.title3)
                    .accessibilityLabel(taken ? "Taken" : "Not taken")

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(dosage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !taken {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(taken)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(dosage), \(taken ? "already taken" : "mark as taken")")
    }
}

#Preview {
    MedicationsView()
        .environmentObject(WatchConnectivityService.shared)
}

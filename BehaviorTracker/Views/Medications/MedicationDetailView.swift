import SwiftUI
import Charts

struct MedicationDetailView: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedDays = 7

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Info
                medicationHeader

                // Statistics
                statisticsSection

                // Charts
                chartsSection

                // Recent Logs
                recentLogsSection

                // Delete button at bottom
                deleteSection
            }
            .padding()
        }
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayModeLarge()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        showingLogSheet = true
                    }) {
                        Label("Log Medication", systemImage: "plus.circle")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete Medication", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(.plain)
            }
            .hideSharedBackground()
        }
        .sheet(isPresented: $showingLogSheet) {
            LogMedicationView(medication: medication, viewModel: viewModel)
        }
        .alert("Delete Medication", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteMedication(medication)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(medication.name)? This will also delete all logs associated with this medication.")
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive, action: {
            showingDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash")
                Text("Delete Medication")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(12)
        }
        .padding(.top, 20)
    }

    private var medicationHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(medication.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let dosage = medication.dosage {
                        Text(dosage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            HStack {
                Label(medication.frequency, systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Since \(medication.prescribedDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let notes = medication.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics (Last \(selectedDays) days)")
                    .font(.headline)

                Spacer()

                Picker("Days", selection: $selectedDays) {
                    Text("7d").tag(7)
                    Text("30d").tag(30)
                    Text("90d").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            HStack(spacing: 12) {
                MedicationStatCard(
                    title: "Adherence",
                    value: "\(Int(viewModel.getAdherenceRate(for: medication, days: selectedDays)))%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                MedicationStatCard(
                    title: "Avg Effect",
                    value: String(format: "%.1f/5", viewModel.getAverageEffectiveness(for: medication, days: selectedDays)),
                    icon: "star.fill",
                    color: .yellow
                )

                MedicationStatCard(
                    title: "Avg Mood",
                    value: String(format: "%.1f/5", viewModel.getAverageMood(for: medication, days: selectedDays)),
                    icon: "face.smiling.fill",
                    color: .blue
                )
            }
        }
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.headline)

            let logs = viewModel.getMedicationLogs(for: medication, days: selectedDays)

            if !logs.isEmpty {
                VStack(spacing: 16) {
                    // Effectiveness over time
                    VStack(alignment: .leading) {
                        Text("Effectiveness")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Chart {
                            ForEach(logs.filter { $0.taken && $0.effectiveness > 0 }) { log in
                                LineMark(
                                    x: .value("Date", log.timestamp),
                                    y: .value("Rating", log.effectiveness)
                                )
                                .foregroundStyle(.yellow)
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Mood over time
                    VStack(alignment: .leading) {
                        Text("Mood")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Chart {
                            ForEach(logs.filter { $0.taken && $0.mood > 0 }) { log in
                                LineMark(
                                    x: .value("Date", log.timestamp),
                                    y: .value("Rating", log.mood)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            } else {
                Text("No data available for the selected period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Logs")
                .font(.headline)

            let recentLogs = viewModel.getMedicationLogs(for: medication, days: 14)

            if recentLogs.isEmpty {
                Text("No logs yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            } else {
                ForEach(recentLogs) { log in
                    MedicationLogRow(log: log)
                }
            }
        }
    }
}

struct MedicationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct MedicationLogRow: View {
    let log: MedicationLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(log.timestamp, style: .date)
                    .font(.headline)

                Spacer()

                if log.taken {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }

            if log.taken {
                HStack(spacing: 16) {
                    if log.effectiveness > 0 {
                        Label("\(log.effectiveness)/5", systemImage: "star.fill")
                            .font(.caption)
                    }
                    if log.mood > 0 {
                        Label("\(log.mood)/5", systemImage: "face.smiling.fill")
                            .font(.caption)
                    }
                    if log.energyLevel > 0 {
                        Label("\(log.energyLevel)/5", systemImage: "bolt.fill")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)

                if let sideEffects = log.sideEffects, !sideEffects.isEmpty {
                    Text("Side effects: \(sideEffects)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else if let reason = log.skippedReason {
                Text("Skipped: \(reason)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let notes = log.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        MedicationDetailView(
            medication: Medication(),
            viewModel: MedicationViewModel()
        )
    }
}

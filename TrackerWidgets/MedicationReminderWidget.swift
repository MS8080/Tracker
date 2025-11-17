import WidgetKit
import SwiftUI
import Intents

// MARK: - Medication Data
struct MedicationInfo: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let time: Date
    let taken: Bool
}

// MARK: - Timeline Entry
struct MedicationEntry: TimelineEntry {
    let date: Date
    let medications: [MedicationInfo]
    let todayAdherence: Double // 0.0 to 1.0
}

// MARK: - Timeline Provider
struct MedicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> MedicationEntry {
        MedicationEntry(
            date: Date(),
            medications: [
                MedicationInfo(name: "Medication A", dosage: "10mg", time: Date(), taken: false),
                MedicationInfo(name: "Medication B", dosage: "5mg", time: Date(), taken: true)
            ],
            todayAdherence: 0.75
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicationEntry) -> ()) {
        let entry = MedicationEntry(
            date: Date(),
            medications: getTodayMedications(),
            todayAdherence: calculateAdherence()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicationEntry>) -> ()) {
        let currentDate = Date()
        let medications = getTodayMedications()
        let entry = MedicationEntry(
            date: currentDate,
            medications: medications,
            todayAdherence: calculateAdherence()
        )

        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Helper Methods
    private func getTodayMedications() -> [MedicationInfo] {
        // This would read from shared App Group data
        // For now, return sample data
        return [
            MedicationInfo(name: "Medication A", dosage: "10mg", time: Date(), taken: false),
            MedicationInfo(name: "Medication B", dosage: "5mg", time: Date(), taken: true)
        ]
    }

    private func calculateAdherence() -> Double {
        // Calculate from shared data
        return 0.75
    }
}

// MARK: - Widget View
struct MedicationWidgetView: View {
    var entry: MedicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .accessoryCircular:
            circularLockScreenWidget
        case .accessoryRectangular:
            rectangularLockScreenWidget
        case .accessoryInline:
            inlineLockScreenWidget
        default:
            smallWidgetView
        }
    }

    // MARK: - Home Screen Widgets

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                Text("Medications")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Medication reminder widget")

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                // Adherence Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: entry.todayAdherence)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.todayAdherence * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .accessibilityLabel("Today's medication adherence: \(Int(entry.todayAdherence * 100)) percent")

                Text("\(upcomingMedicationCount) upcoming")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("\(upcomingMedicationCount) medications upcoming")
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                Text("Today's Medications")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                // Adherence badge
                Text("\(Int(entry.todayAdherence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(adherenceColor.opacity(0.2))
                    .foregroundColor(adherenceColor)
                    .cornerRadius(8)
                    .accessibilityLabel("Adherence: \(Int(entry.todayAdherence * 100)) percent")
            }

            Divider()

            if entry.medications.isEmpty {
                VStack {
                    Spacer()
                    Text("No medications scheduled")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("No medications scheduled for today")
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.medications.prefix(3)) { med in
                        medicationRow(med)
                    }

                    if entry.medications.count > 3 {
                        Text("+\(entry.medications.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(entry.medications.count - 3) more medications")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Lock Screen Widgets (iOS 16+)

    private var circularLockScreenWidget: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)

            Circle()
                .trim(from: 0, to: entry.todayAdherence)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 16))
                Text("\(upcomingMedicationCount)")
                    .font(.system(size: 14, weight: .bold))
            }
        }
        .accessibilityLabel("Medications: \(upcomingMedicationCount) upcoming, \(Int(entry.todayAdherence * 100))% adherence")
    }

    private var rectangularLockScreenWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.caption)
                Text("Medications")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            if let nextMed = upcomingMedications.first {
                HStack {
                    Text(nextMed.name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Text(nextMed.dosage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("All taken")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("\(Int(entry.todayAdherence * 100))% adherence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if upcomingMedicationCount > 1 {
                    Text("+\(upcomingMedicationCount - 1) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Medications: \(upcomingMedicationCount) upcoming, \(Int(entry.todayAdherence * 100))% adherence")
    }

    private var inlineLockScreenWidget: some View {
        HStack(spacing: 4) {
            Image(systemName: "pills.fill")
            Text("\(upcomingMedicationCount) medications")
            if upcomingMedicationCount > 0 {
                Text("•")
                Text("\(Int(entry.todayAdherence * 100))%")
            }
        }
        .accessibilityLabel("\(upcomingMedicationCount) medications upcoming, \(Int(entry.todayAdherence * 100))% adherence")
    }

    // MARK: - Helper Views

    private func medicationRow(_ medication: MedicationInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: medication.taken ? "checkmark.circle.fill" : "circle")
                .foregroundColor(medication.taken ? .green : .gray)
                .font(.body)
                .accessibilityLabel(medication.taken ? "Taken" : "Not taken")

            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(medication.dosage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(timeFormatter.string(from: medication.time))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(medication.name), \(medication.dosage), \(medication.taken ? "taken" : "not taken")")
    }

    // MARK: - Computed Properties

    private var upcomingMedications: [MedicationInfo] {
        entry.medications.filter { !$0.taken }
    }

    private var upcomingMedicationCount: Int {
        upcomingMedications.count
    }

    private var adherenceColor: Color {
        if entry.todayAdherence >= 0.8 {
            return .green
        } else if entry.todayAdherence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Widget Configuration
struct MedicationReminderWidget: Widget {
    let kind: String = "MedicationReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MedicationProvider()) { entry in
            MedicationWidgetView(entry: entry)
        }
        .configurationDisplayName("Medication Reminder")
        .description("Track your medication schedule and adherence")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    MedicationReminderWidget()
} timeline: {
    MedicationEntry(
        date: Date(),
        medications: [
            MedicationInfo(name: "Medication A", dosage: "10mg", time: Date(), taken: false),
            MedicationInfo(name: "Medication B", dosage: "5mg", time: Date(), taken: true)
        ],
        todayAdherence: 0.75
    )
}

#Preview(as: .systemMedium) {
    MedicationReminderWidget()
} timeline: {
    MedicationEntry(
        date: Date(),
        medications: [
            MedicationInfo(name: "Medication A", dosage: "10mg", time: Date(), taken: false),
            MedicationInfo(name: "Medication B", dosage: "5mg", time: Date(), taken: true),
            MedicationInfo(name: "Medication C", dosage: "20mg", time: Date(), taken: false)
        ],
        todayAdherence: 0.75
    )
}

#Preview(as: .accessoryCircular) {
    MedicationReminderWidget()
} timeline: {
    MedicationEntry(
        date: Date(),
        medications: [
            MedicationInfo(name: "Medication A", dosage: "10mg", time: Date(), taken: false)
        ],
        todayAdherence: 0.75
    )
}

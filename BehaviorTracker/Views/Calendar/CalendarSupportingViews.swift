import SwiftUI

// MARK: - Summary Stat View

struct SummaryStatView: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Intensity Indicator

struct IntensityIndicator: View {
    let intensity: Double

    private var intensityColor: Color {
        switch intensity {
        case 0..<2: return .green
        case 2..<3: return .yellow
        case 3..<4: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%.1f", intensity))
                .font(.headline)
                .foregroundStyle(intensityColor)

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(Double(level) <= intensity ? intensityColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Pattern Entry Row

struct PatternEntryRow: View {
    let entry: PatternEntry

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            if let category = entry.patternCategoryEnum {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.patternType)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if entry.duration > 0 {
                        Text("\(entry.duration)min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let notes = entry.contextNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if entry.intensity > 0 {
                Text("\(entry.intensity)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(intensityColor(for: entry.intensity))
                    )
            }
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }

    private func intensityColor(for intensity: Int16) -> Color {
        switch intensity {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }
}

// MARK: - Calendar Medication Log Row

struct CalendarMedicationLogRow: View {
    let log: MedicationLog

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.taken ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(log.taken ? .green : .red)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(log.medication?.name ?? "Unknown Medication")
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(log.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dosage = log.medication?.dosage {
                        Text(dosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !log.taken, let reason = log.skippedReason, !reason.isEmpty {
                    Text("Skipped: \(reason)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if log.effectiveness > 0 {
                VStack(spacing: 2) {
                    Text("\(log.effectiveness)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("eff")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }
}

// MARK: - Calendar Journal Entry Row

struct CalendarJournalEntryRow: View {
    let entry: JournalEntry

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            if entry.mood > 0 {
                Text(moodEmoji(for: entry.mood))
                    .font(.title2)
                    .frame(width: 36)
            } else {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                }

                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }

    private func moodEmoji(for mood: Int16) -> String {
        switch mood {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "📝"
        }
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: CalendarEvent

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                if event.isAllDay {
                    Image(systemName: "sun.max.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                } else {
                    Text(event.timeString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.cyan)
                }
            }
            .frame(width: 50)

            // Color bar from calendar
            RoundedRectangle(cornerRadius: 2)
                .fill(calendarColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if !event.isAllDay {
                        Text(event.durationString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let calendarTitle = event.calendarTitle {
                        Text(calendarTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }

    private var calendarColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .cyan
    }
}

// MARK: - Previews

#Preview("SummaryStatView") {
    HStack {
        SummaryStatView(icon: "figure.walk", color: .green, value: "10", label: "Patterns")
        SummaryStatView(icon: "pills.fill", color: .blue, value: "3", label: "Meds")
    }
    .padding()
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: PatternCategory
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(category.color.opacity(0.2))
        )
        .foregroundStyle(category.color)
    }
}

// MARK: - Previews

#Preview("SummaryStatView") {
    HStack {
        SummaryStatView(icon: "figure.walk", color: .green, value: "10", label: "Patterns")
        SummaryStatView(icon: "pills.fill", color: .blue, value: "3", label: "Meds")
    }
    .padding()
}

#Preview("IntensityIndicator") {
    VStack {
        IntensityIndicator(intensity: 1.5)
        IntensityIndicator(intensity: 2.5)
        IntensityIndicator(intensity: 3.5)
        IntensityIndicator(intensity: 4.5)
    }
    .padding()
}

#Preview("CategoryPill") {
    HStack {
        CategoryPill(category: .sensory, count: 3)
        CategoryPill(category: .social, count: 2)
    }
    .padding()
}

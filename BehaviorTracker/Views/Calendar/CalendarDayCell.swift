import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let entryCount: Int
    let dominantCategory: PatternCategory?
    let averageIntensity: Double?
    let hasMedication: Bool
    let hasJournal: Bool
    var hasCalendarEvents: Bool = false
    var calendarEventCount: Int = 0

    private let calendar = Calendar.current

    private var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    /// Color-coded intensity: higher intensity = more saturated color
    private var intensityColor: Color {
        guard let intensity = averageIntensity else {
            return .clear
        }

        let baseColor = dominantCategory?.color ?? .blue

        // Scale saturation based on intensity (1-5)
        // Low intensity (1-2): 20-40% opacity
        // Medium intensity (3): 50% opacity
        // High intensity (4-5): 60-80% opacity
        let saturation: Double
        switch intensity {
        case 0..<2:
            saturation = 0.2
        case 2..<3:
            saturation = 0.35
        case 3..<4:
            saturation = 0.5
        case 4..<5:
            saturation = 0.65
        default:
            saturation = 0.8
        }

        return baseColor.opacity(saturation)
    }

    var body: some View {
        VStack(spacing: 2) {
            // Day number
            Text(dayNumber)
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundStyle(textColor)

            // Activity indicators
            if entryCount > 0 || hasMedication || hasJournal || hasCalendarEvents {
                HStack(spacing: 2) {
                    if hasCalendarEvents {
                        Circle()
                            .fill(.cyan)
                            .frame(width: 6, height: 6)
                    }
                    if entryCount > 0 {
                        Circle()
                            .fill(dominantCategory?.color ?? .blue)
                            .frame(width: 6, height: 6)
                    }
                    if hasMedication {
                        Circle()
                            .fill(.green)
                            .frame(width: 4, height: 4)
                    }
                    if hasJournal {
                        Circle()
                            .fill(.orange)
                            .frame(width: 4, height: 4)
                    }
                }
            } else {
                // Placeholder to maintain consistent height
                Color.clear
                    .frame(height: 6)
            }

            // Intensity bar (if entries exist)
            if let intensity = averageIntensity {
                IntensityBar(intensity: intensity)
            } else {
                Color.clear
                    .frame(height: 3)
            }
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        .opacity(isCurrentMonth ? 1.0 : 0.4)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Accessibility description for VoiceOver
    private var accessibilityDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var desc = formatter.string(from: date)

        if isToday { desc += ", today" }
        if entryCount > 0 { desc += ", \(entryCount) entries" }
        if let intensity = averageIntensity {
            desc += ", intensity \(String(format: "%.1f", intensity))"
        }
        if hasMedication { desc += ", medication logged" }
        if hasJournal { desc += ", journal entry" }

        return desc
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue)
        } else if isToday {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.15))
        } else if entryCount > 0 {
            // Use intensity-based color coding
            RoundedRectangle(cornerRadius: 8)
                .fill(intensityColor)
        } else {
            Color.clear
        }
    }

    private var borderColor: Color {
        if isToday && !isSelected {
            return .blue
        }
        return .clear
    }

    private var borderWidth: CGFloat {
        isToday && !isSelected ? 2 : 0
    }
}

// MARK: - Intensity Bar

struct IntensityBar: View {
    let intensity: Double // 1-5 scale

    private var fillPercentage: CGFloat {
        CGFloat(intensity / 5.0)
    }

    private var barColor: Color {
        switch intensity {
        case 0..<2:
            return .green
        case 2..<3:
            return .yellow
        case 3..<4:
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor)
                    .frame(width: geometry.size.width * fillPercentage, height: 3)
            }
        }
        .frame(height: 3)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 4) {
            CalendarDayCell(
                date: Date(),
                isCurrentMonth: true,
                isToday: true,
                isSelected: false,
                entryCount: 3,
                dominantCategory: .sensory,
                averageIntensity: 3.5,
                hasMedication: true,
                hasJournal: false
            )

            CalendarDayCell(
                date: Date(),
                isCurrentMonth: true,
                isToday: false,
                isSelected: true,
                entryCount: 5,
                dominantCategory: .energyRegulation,
                averageIntensity: 4.2,
                hasMedication: false,
                hasJournal: true
            )

            CalendarDayCell(
                date: Date(),
                isCurrentMonth: true,
                isToday: false,
                isSelected: false,
                entryCount: 0,
                dominantCategory: nil,
                averageIntensity: nil,
                hasMedication: false,
                hasJournal: false
            )

            CalendarDayCell(
                date: Date(),
                isCurrentMonth: false,
                isToday: false,
                isSelected: false,
                entryCount: 2,
                dominantCategory: .social,
                averageIntensity: 2.0,
                hasMedication: true,
                hasJournal: true
            )
        }
        .padding()
    }
    .background(Color.black)
}

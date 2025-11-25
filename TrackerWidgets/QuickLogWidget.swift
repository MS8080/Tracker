import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry
struct QuickLogEntry: TimelineEntry {
    let date: Date
    let quickLogPatterns: [SharedDataManager.QuickLogPattern]
    let todayCount: Int
    let streakCount: Int
}

// MARK: - Timeline Provider
struct QuickLogProvider: TimelineProvider {
    private let sharedManager = SharedDataManager.shared

    func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry(
            date: Date(),
            quickLogPatterns: sharedManager.getQuickLogPatterns(),
            todayCount: 3,
            streakCount: 7
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> ()) {
        let entry = QuickLogEntry(
            date: Date(),
            quickLogPatterns: sharedManager.getQuickLogPatterns(),
            todayCount: sharedManager.getTodayLogCountWithDateCheck(),
            streakCount: sharedManager.getStreakCount()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> ()) {
        let currentDate = Date()
        let entry = QuickLogEntry(
            date: currentDate,
            quickLogPatterns: sharedManager.getQuickLogPatterns(),
            todayCount: sharedManager.getTodayLogCountWithDateCheck(),
            streakCount: sharedManager.getStreakCount()
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct QuickLogWidgetView: View {
    var entry: QuickLogEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .systemLarge:
            largeWidgetView
        default:
            smallWidgetView
        }
    }

    // MARK: - Small Widget (Stats + Tap to Open)
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(.purple)
                Text("Quick Log")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Quick behavior log widget")

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(entry.todayCount) entries logged today")

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("\(entry.streakCount) day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("\(entry.streakCount) day logging streak")
            }

            Spacer()

            Text("Tap to log")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Widget (Stats + 4 Quick Log Buttons)
    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            // Left side - Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.purple)
                    Text("Quick Log")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(entry.todayCount)")
                            .font(.system(size: 28, weight: .bold))
                        Text("today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("\(entry.streakCount) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .padding(.vertical, 4)

            // Right side - Quick Log Buttons (2x2 grid)
            if #available(iOS 17.0, *) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(entry.quickLogPatterns.prefix(4), id: \.name) { pattern in
                        Button(intent: QuickLogPatternIntent(
                            patternName: pattern.name,
                            patternType: pattern.patternType,
                            category: pattern.category
                        )) {
                            QuickLogButtonContent(pattern: pattern)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                // Fallback for older iOS
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(entry.quickLogPatterns.prefix(4), id: \.name) { pattern in
                        QuickLogButtonContent(pattern: pattern)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Large Widget (Stats + 6 Quick Log Buttons + Recent)
    private var largeWidgetView: some View {
        VStack(spacing: 16) {
            // Top - Header with stats
            HStack {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("Quick Log")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                HStack(spacing: 16) {
                    VStack(alignment: .trailing) {
                        Text("\(entry.todayCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .trailing) {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("\(entry.streakCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Text("streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Middle - Quick Log Buttons (2x3 grid)
            if #available(iOS 17.0, *) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(entry.quickLogPatterns.prefix(6), id: \.name) { pattern in
                        Button(intent: QuickLogPatternIntent(
                            patternName: pattern.name,
                            patternType: pattern.patternType,
                            category: pattern.category
                        )) {
                            QuickLogButtonLarge(pattern: pattern)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(entry.quickLogPatterns.prefix(6), id: \.name) { pattern in
                        QuickLogButtonLarge(pattern: pattern)
                    }
                }
            }

            Spacer()

            // Bottom - Tap to open full app
            Text("Tap a button to log instantly")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Quick Log Button (Compact for Medium Widget)
struct QuickLogButtonContent: View {
    let pattern: SharedDataManager.QuickLogPattern

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: pattern.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: pattern.colorHex))

            Text(pattern.name)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: pattern.colorHex).opacity(0.15))
        )
        .accessibilityLabel("Log \(pattern.name)")
    }
}

// MARK: - Quick Log Button (Large for Large Widget)
struct QuickLogButtonLarge: View {
    let pattern: SharedDataManager.QuickLogPattern

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: pattern.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: pattern.colorHex))
                .frame(width: 32)

            Text(pattern.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.body)
                .foregroundStyle(Color(hex: pattern.colorHex).opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: pattern.colorHex).opacity(0.12))
        )
        .accessibilityLabel("Log \(pattern.name)")
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Configuration
struct QuickLogWidget: Widget {
    let kind: String = "QuickLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLogProvider()) { entry in
            QuickLogWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Log")
        .description("Quickly log behavior patterns with one tap")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    QuickLogWidget()
} timeline: {
    QuickLogEntry(
        date: Date(),
        quickLogPatterns: [
            SharedDataManager.QuickLogPattern(name: "Sensory Overload", patternType: "Sensory Overload", category: "Sensory", icon: "eye.circle", colorHex: "AF52DE"),
            SharedDataManager.QuickLogPattern(name: "Meltdown", patternType: "Meltdown", category: "Energy & Regulation", icon: "bolt.circle", colorHex: "FF3B30"),
            SharedDataManager.QuickLogPattern(name: "Stimming", patternType: "Stimming", category: "Energy & Regulation", icon: "hands.sparkles", colorHex: "FF9500"),
            SharedDataManager.QuickLogPattern(name: "Masking", patternType: "Masking Fatigue", category: "Social & Communication", icon: "theatermasks", colorHex: "34C759")
        ],
        todayCount: 5,
        streakCount: 7
    )
}

#Preview(as: .systemMedium) {
    QuickLogWidget()
} timeline: {
    QuickLogEntry(
        date: Date(),
        quickLogPatterns: [
            SharedDataManager.QuickLogPattern(name: "Sensory Overload", patternType: "Sensory Overload", category: "Sensory", icon: "eye.circle", colorHex: "AF52DE"),
            SharedDataManager.QuickLogPattern(name: "Meltdown", patternType: "Meltdown", category: "Energy & Regulation", icon: "bolt.circle", colorHex: "FF3B30"),
            SharedDataManager.QuickLogPattern(name: "Stimming", patternType: "Stimming", category: "Energy & Regulation", icon: "hands.sparkles", colorHex: "FF9500"),
            SharedDataManager.QuickLogPattern(name: "Masking", patternType: "Masking Fatigue", category: "Social & Communication", icon: "theatermasks", colorHex: "34C759")
        ],
        todayCount: 5,
        streakCount: 7
    )
}

#Preview(as: .systemLarge) {
    QuickLogWidget()
} timeline: {
    QuickLogEntry(
        date: Date(),
        quickLogPatterns: [
            SharedDataManager.QuickLogPattern(name: "Sensory Overload", patternType: "Sensory Overload", category: "Sensory", icon: "eye.circle", colorHex: "AF52DE"),
            SharedDataManager.QuickLogPattern(name: "Meltdown", patternType: "Meltdown", category: "Energy & Regulation", icon: "bolt.circle", colorHex: "FF3B30"),
            SharedDataManager.QuickLogPattern(name: "Stimming", patternType: "Stimming", category: "Energy & Regulation", icon: "hands.sparkles", colorHex: "FF9500"),
            SharedDataManager.QuickLogPattern(name: "Masking", patternType: "Masking Fatigue", category: "Social & Communication", icon: "theatermasks", colorHex: "34C759"),
            SharedDataManager.QuickLogPattern(name: "Shutdown", patternType: "Shutdown", category: "Energy & Regulation", icon: "moon.circle", colorHex: "5856D6"),
            SharedDataManager.QuickLogPattern(name: "Anxiety", patternType: "Anxiety", category: "Sensory", icon: "exclamationmark.triangle", colorHex: "FF2D55")
        ],
        todayCount: 5,
        streakCount: 7
    )
}

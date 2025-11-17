import WidgetKit
import SwiftUI
import Intents

// MARK: - Timeline Entry
struct QuickLogEntry: TimelineEntry {
    let date: Date
    let favoritePatterns: [String]
    let todayCount: Int
    let streakCount: Int
}

// MARK: - Timeline Provider
struct QuickLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry(
            date: Date(),
            favoritePatterns: ["Hand Flapping", "Rocking", "Spinning"],
            todayCount: 5,
            streakCount: 7
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> ()) {
        let entry = QuickLogEntry(
            date: Date(),
            favoritePatterns: getFavoritePatterns(),
            todayCount: getTodayLogCount(),
            streakCount: getStreakCount()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> ()) {
        let currentDate = Date()
        let entry = QuickLogEntry(
            date: currentDate,
            favoritePatterns: getFavoritePatterns(),
            todayCount: getTodayLogCount(),
            streakCount: getStreakCount()
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Helper Methods
    private func getFavoritePatterns() -> [String] {
        // This would read from shared UserDefaults/App Group
        // For now, return sample data
        return ["Hand Flapping", "Rocking", "Spinning"]
    }

    private func getTodayLogCount() -> Int {
        // Read from shared data source
        return 0
    }

    private func getStreakCount() -> Int {
        // Read from shared data source
        return 0
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
        default:
            smallWidgetView
        }
    }

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.purple)
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
                        .foregroundColor(.primary)
                    Text("today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(entry.todayCount) entries logged today")

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(entry.streakCount) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("\(entry.streakCount) day logging streak")
            }

            Spacer()

            Text("Tap to log")
                .font(.caption2)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            // Stats Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.purple)
                    Text("Quick Log")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Quick behavior log widget")

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(entry.todayCount)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        Text("entries today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.todayCount) entries logged today")

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.streakCount) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("\(entry.streakCount) day logging streak")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Favorites Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Favorites")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)

                ForEach(entry.favoritePatterns.prefix(3), id: \.self) { pattern in
                    HStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 6, height: 6)
                        Text(pattern)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .accessibilityLabel("Favorite pattern: \(pattern)")
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
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
        .description("Quickly view and log behavior patterns")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    QuickLogWidget()
} timeline: {
    QuickLogEntry(
        date: Date(),
        favoritePatterns: ["Hand Flapping", "Rocking", "Spinning"],
        todayCount: 5,
        streakCount: 7
    )
}

#Preview(as: .systemMedium) {
    QuickLogWidget()
} timeline: {
    QuickLogEntry(
        date: Date(),
        favoritePatterns: ["Hand Flapping", "Rocking", "Spinning"],
        todayCount: 5,
        streakCount: 7
    )
}

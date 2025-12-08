import Foundation
import CoreData

/// Generates "memories" - reflective insights from past patterns
struct MemoriesGenerator {

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    /// Generate memories from recent extracted patterns
    func generateMemories(
        recentPatterns: [ExtractedPattern],
        lastMonthPatterns: [ExtractedPattern]
    ) -> [Memory] {
        var memories: [Memory] = []
        let calendar = Calendar.current

        // Check last week same day
        if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) {
            let lastWeekPatterns = filterPatternsForDay(recentPatterns, date: lastWeek)
            if !lastWeekPatterns.isEmpty {
                let description = describeDay(lastWeekPatterns, prefix: "Last week")
                memories.append(Memory(
                    timeframe: "This time last week",
                    description: description
                ))
            }
        }

        // Find overcome memory
        if let overcameMemory = findOvercomeMemory(from: recentPatterns) {
            memories.append(overcameMemory)
        }

        // Check last month
        if !lastMonthPatterns.isEmpty {
            let description = describeDay(lastMonthPatterns, prefix: "Last month")
            memories.append(Memory(
                timeframe: "This time last month",
                description: description
            ))
        }

        // Check time-of-day pattern
        let currentHour = calendar.component(.hour, from: Date())
        if let pattern = findTimeOfDayPattern(from: recentPatterns, hour: currentHour) {
            memories.append(Memory(
                timeframe: "Around this time",
                description: pattern
            ))
        }

        return memories
    }

    // MARK: - Private Helpers

    private func filterPatternsForDay(_ patterns: [ExtractedPattern], date: Date) -> [ExtractedPattern] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return patterns.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
    }

    private func findOvercomeMemory(from patterns: [ExtractedPattern]) -> Memory? {
        let sorted = patterns.sorted { $0.timestamp > $1.timestamp }

        for (index, pattern) in sorted.enumerated() where pattern.intensity >= 7 {
            if index > 0 {
                let laterPattern = sorted[index - 1]
                let positivePatterns = ["Flow State Achieved", "Authenticity Moment", "Special Interest Engagement"]
                let isPositive = positivePatterns.contains(laterPattern.patternType)

                if laterPattern.intensity <= 3 || isPositive {
                    let timeAgo = Self.relativeDateFormatter.localizedString(for: pattern.timestamp, relativeTo: Date())
                    let patternName = pattern.patternType.lowercased()
                    return Memory(
                        timeframe: "You got through it",
                        description: "\(timeAgo), you felt overwhelmed by \(patternName) — and you made it through."
                    )
                }
            }
        }
        return nil
    }

    private func describeDay(_ patterns: [ExtractedPattern], prefix: String) -> String {
        if let significant = patterns.max(by: { $0.intensity < $1.intensity }) {
            let patternName = significant.patternType.lowercased()
            if significant.intensity >= 7 {
                return "\(prefix), you were dealing with \(patternName). You got through it."
            } else if significant.intensity <= 3 {
                return "\(prefix) was a calmer day. You noticed \(patternName)."
            } else {
                return "\(prefix), you experienced \(patternName)."
            }
        }
        return "\(prefix), you had \(patterns.count) moments recorded."
    }

    private func findTimeOfDayPattern(from patterns: [ExtractedPattern], hour: Int) -> String? {
        let calendar = Calendar.current
        let relevantPatterns = patterns.filter { pattern in
            let patternHour = calendar.component(.hour, from: pattern.timestamp)
            return abs(patternHour - hour) <= 2
        }

        guard relevantPatterns.count >= 3 else { return nil }

        var patternCounts: [String: Int] = [:]
        for pattern in relevantPatterns {
            patternCounts[pattern.patternType, default: 0] += 1
        }

        if let mostCommon = patternCounts.max(by: { $0.value < $1.value }), mostCommon.value >= 3 {
            return "You often experience \"\(mostCommon.key.lowercased())\" around now"
        }
        return nil
    }
}

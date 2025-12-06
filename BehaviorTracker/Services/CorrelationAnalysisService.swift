import Foundation
import CoreData

// MARK: - Correlation Insight Model

struct CorrelationInsight: Identifiable {
    let id = UUID()
    let type: CorrelationType
    let title: String
    let description: String
    let strength: Double // 0.0 to 1.0
    let confidence: ConfidenceLevel
    let sampleSize: Int

    enum CorrelationType {
        case medicationPattern
        case timePattern
        case factorPattern
        case moodPattern
    }

    enum ConfidenceLevel {
        case low      // < 10 samples
        case medium   // 10-30 samples
        case high     // > 30 samples

        var displayName: String {
            switch self {
            case .low: return NSLocalizedString("correlation.confidence.low", comment: "Low confidence")
            case .medium: return NSLocalizedString("correlation.confidence.medium", comment: "Medium confidence")
            case .high: return NSLocalizedString("correlation.confidence.high", comment: "High confidence")
            }
        }

        var color: String {
            switch self {
            case .low: return "orange"
            case .medium: return "yellow"
            case .high: return "green"
            }
        }
    }
}

// MARK: - Correlation Analysis Service

class CorrelationAnalysisService {
    static let shared = CorrelationAnalysisService()
    private let dataController = DataController.shared

    private init() {}

    // MARK: - Main Analysis Function

    func generateInsights(days: Int = 30) async -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []

        // Fetch data from the last N days
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let patterns = await fetchPatterns(since: startDate)
        let medicationLogs = fetchMedicationLogs(since: startDate)

        // Generate different types of correlations
        insights.append(contentsOf: analyzeMedicationPatternCorrelations(patterns: patterns, medicationLogs: medicationLogs))
        insights.append(contentsOf: analyzeTimePatternCorrelations(patterns: patterns))
        insights.append(contentsOf: analyzeFactorPatternCorrelations(patterns: patterns))
        insights.append(contentsOf: await analyzeMoodPatternCorrelations(patterns: patterns))

        // Sort by strength (strongest correlations first)
        return insights.sorted { $0.strength > $1.strength }
    }

    // MARK: - Medication-Pattern Correlations

    private func analyzeMedicationPatternCorrelations(patterns: [PatternEntry], medicationLogs: [MedicationLog]) -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []

        // Group medication logs by medication name
        let medicationGroups = Dictionary(grouping: medicationLogs) { log -> String in
            log.medication?.name ?? "Unknown"
        }

        for (medicationName, logs) in medicationGroups where medicationName != "Unknown" {
            // For each medication, analyze patterns that occur on days when it's taken vs not taken
            let takenDates = Set(logs.map { Calendar.current.startOfDay(for: $0.timestamp) })

            // Group patterns by type
            let patternGroups = Dictionary(grouping: patterns) { $0.patternType }

            for (patternType, patternEntries) in patternGroups {
                let patternsOnMedicationDays = patternEntries.filter { entry in
                    takenDates.contains(Calendar.current.startOfDay(for: entry.timestamp))
                }

                let patternsOffMedicationDays = patternEntries.filter { entry in
                    !takenDates.contains(Calendar.current.startOfDay(for: entry.timestamp))
                }

                guard !patternsOffMedicationDays.isEmpty else { continue }

                // Calculate average intensity on medication days vs off
                let avgIntensityOn = patternsOnMedicationDays.isEmpty ? 0.0 :
                    Double(patternsOnMedicationDays.reduce(0) { $0 + Int($1.intensity) }) / Double(patternsOnMedicationDays.count)

                let avgIntensityOff = Double(patternsOffMedicationDays.reduce(0) { $0 + Int($1.intensity) }) / Double(patternsOffMedicationDays.count)

                let percentChange = avgIntensityOff == 0 ? 0 : ((avgIntensityOn - avgIntensityOff) / avgIntensityOff) * 100

                // Only report significant correlations (> 20% change)
                if abs(percentChange) > 20 {
                    let sampleSize = patternsOnMedicationDays.count + patternsOffMedicationDays.count
                    let confidence = getConfidenceLevel(sampleSize: sampleSize)
                    let strength = min(abs(percentChange) / 100.0, 1.0)

                    let direction = percentChange > 0 ? "increases" : "decreases"
                    let title = "\(medicationName) → \(patternType)"
                    let description = "When taking \(medicationName), \(patternType) \(direction) by \(Int(abs(percentChange)))%"

                    insights.append(CorrelationInsight(
                        type: .medicationPattern,
                        title: title,
                        description: description,
                        strength: strength,
                        confidence: confidence,
                        sampleSize: sampleSize
                    ))
                }
            }
        }

        return insights
    }

    // MARK: - Time-Pattern Correlations

    private func analyzeTimePatternCorrelations(patterns: [PatternEntry]) -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []

        // Group patterns by type
        let patternGroups = Dictionary(grouping: patterns) { $0.patternType }

        for (patternType, entries) in patternGroups {
            // Analyze by time of day
            let morningEntries = entries.filter { entry in
                let hour = Calendar.current.component(.hour, from: entry.timestamp)
                return hour >= 6 && hour < 12
            }

            let afternoonEntries = entries.filter { entry in
                let hour = Calendar.current.component(.hour, from: entry.timestamp)
                return hour >= 12 && hour < 18
            }

            let eveningEntries = entries.filter { entry in
                let hour = Calendar.current.component(.hour, from: entry.timestamp)
                return hour >= 18 || hour < 6
            }

            // Find the time period with highest occurrence
            let periods = [
                ("morning", morningEntries.count),
                ("afternoon", afternoonEntries.count),
                ("evening", eveningEntries.count)
            ]

            guard let maxPeriod = periods.max(by: { $0.1 < $1.1 }), maxPeriod.1 > 0 else { continue }

            let totalCount = entries.count
            let percentage = (Double(maxPeriod.1) / Double(totalCount)) * 100

            // Only report if > 50% occur in a specific time
            if percentage > 50 {
                let confidence = getConfidenceLevel(sampleSize: totalCount)
                let strength = min(percentage / 100.0, 1.0)

                let title = "\(patternType) peaks in \(maxPeriod.0)"
                let description = "\(Int(percentage))% of \(patternType) patterns occur in the \(maxPeriod.0)"

                insights.append(CorrelationInsight(
                    type: .timePattern,
                    title: title,
                    description: description,
                    strength: strength,
                    confidence: confidence,
                    sampleSize: totalCount
                ))
            }
        }

        return insights
    }

    // MARK: - Factor-Pattern Correlations

    private func analyzeFactorPatternCorrelations(patterns: [PatternEntry]) -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []

        // Collect all contributing factors across all patterns
        var factorOccurrences: [String: [PatternEntry]] = [:]

        for pattern in patterns {
            let factors = pattern.contributingFactors
            for factor in factors {
                factorOccurrences[factor.rawValue, default: []].append(pattern)
            }
        }

        // Analyze each factor's correlation with pattern intensity
        for (factorName, entriesWithFactor) in factorOccurrences where entriesWithFactor.count >= 3 {
            let avgIntensityWith = Double(entriesWithFactor.reduce(0) { $0 + Int($1.intensity) }) / Double(entriesWithFactor.count)

            // Compare with overall average
            let allEntries = patterns
            let overallAvg = Double(allEntries.reduce(0) { $0 + Int($1.intensity) }) / Double(allEntries.count)

            let percentDiff = ((avgIntensityWith - overallAvg) / overallAvg) * 100

            if abs(percentDiff) > 15 {
                let confidence = getConfidenceLevel(sampleSize: entriesWithFactor.count)
                let strength = min(abs(percentDiff) / 100.0, 1.0)

                let direction = percentDiff > 0 ? "higher" : "lower"
                let title = "\(factorName) affects intensity"
                let description = "Patterns with '\(factorName)' factor are \(Int(abs(percentDiff)))% \(direction) intensity"

                insights.append(CorrelationInsight(
                    type: .factorPattern,
                    title: title,
                    description: description,
                    strength: strength,
                    confidence: confidence,
                    sampleSize: entriesWithFactor.count
                ))
            }
        }

        return insights
    }

    // MARK: - Mood-Pattern Correlations

    private func analyzeMoodPatternCorrelations(patterns: [PatternEntry]) async -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []

        // Get journal entries to correlate mood with patterns
        let journalEntries = await dataController.fetchJournalEntries()

        // Group patterns by type
        let patternGroups = Dictionary(grouping: patterns) { $0.patternType }

        for (patternType, entries) in patternGroups {
            // For each pattern, find journal entries on the same day and average mood
            var moodsOnPatternDays: [Int16] = []

            for entry in entries {
                let patternDay = Calendar.current.startOfDay(for: entry.timestamp)
                let journalsOnSameDay = journalEntries.filter {
                    Calendar.current.startOfDay(for: $0.timestamp) == patternDay && $0.mood > 0
                }

                if !journalsOnSameDay.isEmpty {
                    let avgMood = journalsOnSameDay.reduce(0) { $0 + Int($1.mood) } / journalsOnSameDay.count
                    moodsOnPatternDays.append(Int16(avgMood))
                }
            }

            guard moodsOnPatternDays.count >= 5 else { continue }

            let avgMood = Double(moodsOnPatternDays.reduce(0) { $0 + Int($1) }) / Double(moodsOnPatternDays.count)

            // Interpret mood correlation
            let moodLevel: String
            if avgMood < 2.5 {
                moodLevel = "low mood"
            } else if avgMood < 3.5 {
                moodLevel = "neutral mood"
            } else {
                moodLevel = "good mood"
            }

            let confidence = getConfidenceLevel(sampleSize: moodsOnPatternDays.count)
            let strength = abs(avgMood - 3.0) / 2.0 // Distance from neutral (3)

            let title = "\(patternType) correlates with \(moodLevel)"
            let description = "Days with \(patternType) patterns show \(moodLevel) (avg: \(String(format: "%.1f", avgMood))/5)"

            insights.append(CorrelationInsight(
                type: .moodPattern,
                title: title,
                description: description,
                strength: strength,
                confidence: confidence,
                sampleSize: moodsOnPatternDays.count
            ))
        }

        return insights
    }

    // MARK: - Helper Functions

    private func fetchPatterns(since date: Date) async -> [PatternEntry] {
        return await dataController.fetchPatternEntriesAsync(startDate: date, endDate: Date())
    }

    private func fetchMedicationLogs(since date: Date) -> [MedicationLog] {
        let request = NSFetchRequest<MedicationLog>(entityName: "MedicationLog")
        request.predicate = NSPredicate(format: "timestamp >= %@", date as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationLog.timestamp, ascending: false)]

        do {
            return try dataController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching medication logs: \(error)")
            return []
        }
    }

    private func getConfidenceLevel(sampleSize: Int) -> CorrelationInsight.ConfidenceLevel {
        switch sampleSize {
        case 0..<10:
            return .low
        case 10..<30:
            return .medium
        default:
            return .high
        }
    }
}

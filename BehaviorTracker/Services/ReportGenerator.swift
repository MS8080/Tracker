import Foundation
import CoreData

struct MedicationInsight {
    var medicationName: String
    var adherenceRate: Double
    var averageEffectiveness: Double
    var averageMood: Double
    var averageEnergy: Double
    var sideEffectsReported: Int
    var correlationNotes: [String] = []
}

struct WeeklyReport {
    var totalEntries: Int = 0
    var mostActiveDay: String = "N/A"
    var averagePerDay: Double = 0.0
    var patternFrequency: [(key: String, value: Int)] = []
    var categoryBreakdown: [PatternCategory: Int] = [:]
    var energyTrend: [DataPoint] = []
    var commonTriggers: [String] = []
    var medicationInsights: [MedicationInsight] = []
}

struct MonthlyReport {
    var totalEntries: Int = 0
    var mostActiveWeek: String = "N/A"
    var averagePerDay: Double = 0.0
    var topPatterns: [(key: String, value: Int)] = []
    var categoryTrends: [PatternCategory: [DataPoint]] = [:]
    var correlations: [String] = []
    var bestDays: [String] = []
    var challengingDays: [String] = []
    var behaviorChanges: [String] = []
    var medicationInsights: [MedicationInsight] = []
}

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

class ReportGenerator {
    private let dataController = DataController.shared

    func generateWeeklyReport() -> WeeklyReport {
        var report = WeeklyReport()

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let entries = dataController.fetchPatternEntries(startDate: weekAgo, endDate: Date())

        report.totalEntries = entries.count
        report.averagePerDay = Double(entries.count) / 7.0

        var dailyCounts: [String: Int] = [:]
        var patternCounts: [String: Int] = [:]
        var categoryCounts: [PatternCategory: Int] = [:]
        var energyByDay: [Date: [Int16]] = [:]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"

        for entry in entries {
            let dayName = dateFormatter.string(from: entry.timestamp)
            dailyCounts[dayName, default: 0] += 1

            patternCounts[entry.patternType, default: 0] += 1

            if let category = entry.patternCategoryEnum {
                categoryCounts[category, default: 0] += 1
            }

            if entry.patternType == PatternType.energyLevel.rawValue && entry.intensity > 0 {
                let startOfDay = calendar.startOfDay(for: entry.timestamp)
                energyByDay[startOfDay, default: []].append(entry.intensity)
            }
        }

        if let mostActive = dailyCounts.max(by: { $0.value < $1.value }) {
            report.mostActiveDay = mostActive.key
        }

        report.patternFrequency = patternCounts.sorted { $0.value > $1.value }
        report.categoryBreakdown = categoryCounts

        report.energyTrend = energyByDay.map { date, intensities in
            let average = Double(intensities.reduce(0, +)) / Double(intensities.count)
            return DataPoint(date: date, value: average)
        }.sorted { $0.date < $1.date }

        report.medicationInsights = generateMedicationInsights(days: 7)

        return report
    }

    func generateMonthlyReport() -> MonthlyReport {
        var report = MonthlyReport()

        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        let entries = dataController.fetchPatternEntries(startDate: monthAgo, endDate: Date())

        report.totalEntries = entries.count
        report.averagePerDay = Double(entries.count) / 30.0

        var weekCounts: [Int: Int] = [:]
        var patternCounts: [String: Int] = [:]
        var dailyEntries: [Date: [PatternEntry]] = [:]

        for entry in entries {
            let weekOfYear = calendar.component(.weekOfYear, from: entry.timestamp)
            weekCounts[weekOfYear, default: 0] += 1

            patternCounts[entry.patternType, default: 0] += 1

            let startOfDay = calendar.startOfDay(for: entry.timestamp)
            dailyEntries[startOfDay, default: []].append(entry)
        }

        if let mostActiveWeek = weekCounts.max(by: { $0.value < $1.value }) {
            report.mostActiveWeek = "Week \(mostActiveWeek.key)"
        }

        report.topPatterns = patternCounts.sorted { $0.value > $1.value }

        report.correlations = findCorrelations(entries: entries)

        let (best, challenging) = analyzeDays(dailyEntries: dailyEntries)
        report.bestDays = best
        report.challengingDays = challenging

        report.medicationInsights = generateMedicationInsights(days: 30)

        return report
    }

    private func findCorrelations(entries: [PatternEntry]) -> [String] {
        var correlations: [String] = []
        let calendar = Calendar.current

        var sleepQualityByDay: [Date: Int16] = [:]
        var nextDayOverload: [Date: Int] = [:]

        for entry in entries {
            let startOfDay = calendar.startOfDay(for: entry.timestamp)

            if entry.patternType == PatternType.sleepQuality.rawValue {
                sleepQualityByDay[startOfDay] = entry.intensity
            }

            if entry.patternType == PatternType.sensoryOverload.rawValue {
                nextDayOverload[startOfDay, default: 0] += 1
            }
        }

        var poorSleepToOverload = 0
        var totalPoorSleep = 0

        for (sleepDate, quality) in sleepQualityByDay where quality <= 2 {
            totalPoorSleep += 1
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: sleepDate),
               let overloadCount = nextDayOverload[nextDay], overloadCount > 0 {
                poorSleepToOverload += 1
            }
        }

        if totalPoorSleep > 3 && Double(poorSleepToOverload) / Double(totalPoorSleep) > 0.6 {
            correlations.append("Poor sleep quality often correlates with sensory overload the next day")
        }

        return correlations
    }

    private func analyzeDays(dailyEntries: [Date: [PatternEntry]]) -> ([String], [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var dayScores: [(Date, Double)] = []

        for (date, entries) in dailyEntries {
            var score: Double = 0.0

            let overloadCount = entries.filter {
                $0.patternType == PatternType.sensoryOverload.rawValue ||
                $0.patternType == PatternType.meltdown.rawValue ||
                $0.patternType == PatternType.shutdown.rawValue
            }.count

            let positiveCount = entries.filter {
                $0.patternType == PatternType.hyperfocus.rawValue ||
                $0.patternType == PatternType.specialInterest.rawValue
            }.count

            score = Double(positiveCount) - Double(overloadCount)

            dayScores.append((date, score))
        }

        let sorted = dayScores.sorted { $0.1 > $1.1 }

        let bestDays = sorted.prefix(3).map { dateFormatter.string(from: $0.0) }
        let challengingDays = sorted.suffix(3).reversed().map { dateFormatter.string(from: $0.0) }

        return (bestDays, challengingDays)
    }

    private func generateMedicationInsights(days: Int) -> [MedicationInsight] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let medications = dataController.fetchMedications(activeOnly: true)

        var insights: [MedicationInsight] = []

        for medication in medications {
            let logs = dataController.fetchMedicationLogs(
                startDate: startDate,
                endDate: Date(),
                medication: medication
            )

            guard !logs.isEmpty else { continue }

            let takenLogs = logs.filter { $0.taken }
            let adherenceRate = (Double(takenLogs.count) / Double(logs.count)) * 100

            let effectivenessList = takenLogs.compactMap { log -> Int16? in
                log.effectiveness > 0 ? log.effectiveness : nil
            }
            let averageEffectiveness = effectivenessList.isEmpty ? 0 :
                Double(effectivenessList.reduce(0, +)) / Double(effectivenessList.count)

            let moodList = takenLogs.compactMap { log -> Int16? in
                log.mood > 0 ? log.mood : nil
            }
            let averageMood = moodList.isEmpty ? 0 :
                Double(moodList.reduce(0, +)) / Double(moodList.count)

            let energyList = takenLogs.compactMap { log -> Int16? in
                log.energyLevel > 0 ? log.energyLevel : nil
            }
            let averageEnergy = energyList.isEmpty ? 0 :
                Double(energyList.reduce(0, +)) / Double(energyList.count)

            let sideEffectsCount = takenLogs.filter { log in
                log.sideEffects != nil && !log.sideEffects!.isEmpty
            }.count

            var correlationNotes: [String] = []

            // Analyze medication-behavior correlations
            let patternEntries = dataController.fetchPatternEntries(startDate: startDate, endDate: Date())
            correlationNotes.append(contentsOf: analyzeMedicationBehaviorCorrelations(
                medicationLogs: takenLogs,
                patternEntries: patternEntries
            ))

            let insight = MedicationInsight(
                medicationName: medication.name,
                adherenceRate: adherenceRate,
                averageEffectiveness: averageEffectiveness,
                averageMood: averageMood,
                averageEnergy: averageEnergy,
                sideEffectsReported: sideEffectsCount,
                correlationNotes: correlationNotes
            )

            insights.append(insight)
        }

        return insights
    }

    private func analyzeMedicationBehaviorCorrelations(
        medicationLogs: [MedicationLog],
        patternEntries: [PatternEntry]
    ) -> [String] {
        var correlations: [String] = []
        let calendar = Calendar.current

        // Group patterns by day
        var patternsByDay: [Date: [PatternEntry]] = [:]
        for entry in patternEntries {
            let startOfDay = calendar.startOfDay(for: entry.timestamp)
            patternsByDay[startOfDay, default: []].append(entry)
        }

        // Group medication logs by day
        var medLogsByDay: [Date: [MedicationLog]] = [:]
        for log in medicationLogs {
            let startOfDay = calendar.startOfDay(for: log.timestamp)
            medLogsByDay[startOfDay, default: []].append(log)
        }

        // Find days with high medication effectiveness
        let highEffectivenessDays = medLogsByDay.filter { _, logs in
            guard !logs.isEmpty else { return false }
            let effectivenessValues = logs.map { Double($0.effectiveness) }
            let sum = effectivenessValues.reduce(0, +)
            let avgEffectiveness = sum / Double(logs.count)
            return avgEffectiveness >= 4.0
        }.keys

        // Check for correlations with positive patterns on high effectiveness days
        var positivePatternCount = 0
        var negativePatternCount = 0

        for day in highEffectivenessDays {
            if let patterns = patternsByDay[day] {
                let positives = patterns.filter {
                    $0.patternType == PatternType.hyperfocus.rawValue ||
                    $0.patternType == PatternType.specialInterest.rawValue
                }.count

                let negatives = patterns.filter {
                    $0.patternType == PatternType.sensoryOverload.rawValue ||
                    $0.patternType == PatternType.meltdown.rawValue ||
                    $0.patternType == PatternType.shutdown.rawValue
                }.count

                positivePatternCount += positives
                negativePatternCount += negatives
            }
        }

        if !highEffectivenessDays.isEmpty {
            if positivePatternCount > negativePatternCount * 2 {
                correlations.append("High medication effectiveness correlates with increased positive behavioral patterns")
            }
            if negativePatternCount < highEffectivenessDays.count {
                correlations.append("Fewer challenging behaviors on days with high medication effectiveness")
            }
        }

        // Check for mood improvements
        let highMoodDays = medLogsByDay.filter { _, logs in
            guard !logs.isEmpty else { return false }
            let moodValues = logs.map { Double($0.mood) }
            let sum = moodValues.reduce(0, +)
            let avgMood = sum / Double(logs.count)
            return avgMood >= 4.0
        }.keys.count

        let totalDays = medLogsByDay.count
        if totalDays > 0 {
            let highMoodRatio = Double(highMoodDays) / Double(totalDays)
            if highMoodRatio > 0.6 {
                correlations.append("Medication appears to support improved mood regulation")
            }
        }

        return correlations
    }
}

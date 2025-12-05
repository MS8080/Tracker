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
    var totalPatterns: Int = 0
    var mostActiveDay: String = "N/A"
    var averagePerDay: Double = 0.0
    var patternFrequency: [(key: String, value: Int)] = []
    var categoryBreakdown: [String: Int] = [:]
    var intensityTrend: [DataPoint] = []
    var commonTriggers: [String] = []
    var topCascades: [(from: String, to: String, count: Int)] = []
    var medicationInsights: [MedicationInsight] = []
}

struct MonthlyReport {
    var totalEntries: Int = 0
    var totalPatterns: Int = 0
    var mostActiveWeek: String = "N/A"
    var averagePerDay: Double = 0.0
    var topPatterns: [(key: String, value: Int)] = []
    var categoryTrends: [String: [DataPoint]] = [:]
    var correlations: [String] = []
    var bestDays: [String] = []
    var challengingDays: [String] = []
    var behaviorChanges: [String] = []
    var cascadeInsights: [String] = []
    var medicationInsights: [MedicationInsight] = []
}

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

class ReportGenerator {
    private let dataController = DataController.shared

    // MARK: - Weekly Report (uses ExtractedPattern)

    func generateWeeklyReport() -> WeeklyReport {
        var report = WeeklyReport()

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        // Fetch ExtractedPatterns instead of PatternEntry
        let patterns = fetchExtractedPatterns(startDate: weekAgo, endDate: Date())
        let journals = fetchJournalEntries(startDate: weekAgo, endDate: Date())

        report.totalEntries = journals.count
        report.totalPatterns = patterns.count
        report.averagePerDay = Double(patterns.count) / 7.0

        var dailyCounts: [String: Int] = [:]
        var patternCounts: [String: Int] = [:]
        var categoryCounts: [String: Int] = [:]
        var intensityByDay: [Date: [Int16]] = [:]
        var allTriggers: [String: Int] = [:]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"

        for pattern in patterns {
            let dayName = dateFormatter.string(from: pattern.timestamp)
            dailyCounts[dayName, default: 0] += 1

            patternCounts[pattern.patternType, default: 0] += 1
            categoryCounts[pattern.category, default: 0] += 1

            // Track intensity trend
            let startOfDay = calendar.startOfDay(for: pattern.timestamp)
            intensityByDay[startOfDay, default: []].append(pattern.intensity)

            // Collect triggers
            for trigger in pattern.triggers {
                allTriggers[trigger, default: 0] += 1
            }
        }

        if let mostActive = dailyCounts.max(by: { $0.value < $1.value }) {
            report.mostActiveDay = mostActive.key
        }

        report.patternFrequency = patternCounts.sorted { $0.value > $1.value }
        report.categoryBreakdown = categoryCounts

        report.intensityTrend = intensityByDay.map { date, intensities in
            let average = Double(intensities.reduce(0, +)) / Double(intensities.count)
            return DataPoint(date: date, value: average)
        }.sorted { $0.date < $1.date }

        // Top triggers
        report.commonTriggers = allTriggers
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }

        // Analyze cascades
        report.topCascades = analyzeCascades(from: patterns)

        report.medicationInsights = generateMedicationInsights(days: 7, patterns: patterns)

        return report
    }

    // MARK: - Monthly Report (uses ExtractedPattern)

    func generateMonthlyReport() -> MonthlyReport {
        var report = MonthlyReport()

        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!

        // Fetch ExtractedPatterns instead of PatternEntry
        let patterns = fetchExtractedPatterns(startDate: monthAgo, endDate: Date())
        let journals = fetchJournalEntries(startDate: monthAgo, endDate: Date())

        report.totalEntries = journals.count
        report.totalPatterns = patterns.count
        report.averagePerDay = Double(patterns.count) / 30.0

        var weekCounts: [Int: Int] = [:]
        var patternCounts: [String: Int] = [:]
        var dailyPatterns: [Date: [ExtractedPattern]] = [:]
        var categoryByDay: [String: [Date: [Int16]]] = [:]

        for pattern in patterns {
            let weekOfYear = calendar.component(.weekOfYear, from: pattern.timestamp)
            weekCounts[weekOfYear, default: 0] += 1

            patternCounts[pattern.patternType, default: 0] += 1

            let startOfDay = calendar.startOfDay(for: pattern.timestamp)
            dailyPatterns[startOfDay, default: []].append(pattern)

            // Track category trends over time
            if categoryByDay[pattern.category] == nil {
                categoryByDay[pattern.category] = [:]
            }
            categoryByDay[pattern.category]![startOfDay, default: []].append(pattern.intensity)
        }

        if let mostActiveWeek = weekCounts.max(by: { $0.value < $1.value }) {
            report.mostActiveWeek = "Week \(mostActiveWeek.key)"
        }

        report.topPatterns = patternCounts.sorted { $0.value > $1.value }

        // Build category trends
        for (category, dayData) in categoryByDay {
            report.categoryTrends[category] = dayData.map { date, intensities in
                let avg = Double(intensities.reduce(0, +)) / Double(intensities.count)
                return DataPoint(date: date, value: avg)
            }.sorted { $0.date < $1.date }
        }

        report.correlations = findCorrelations(patterns: patterns)
        report.cascadeInsights = findCascadeInsights(patterns: patterns)

        let (best, challenging) = analyzeDays(dailyPatterns: dailyPatterns)
        report.bestDays = best
        report.challengingDays = challenging

        report.medicationInsights = generateMedicationInsights(days: 30, patterns: patterns)

        return report
    }

    // MARK: - Fetch ExtractedPatterns

    private func fetchExtractedPatterns(startDate: Date, endDate: Date) -> [ExtractedPattern] {
        let fetchRequest: NSFetchRequest<ExtractedPattern> = ExtractedPattern.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractedPattern.timestamp, ascending: true)]

        do {
            return try dataController.container.viewContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }

    private func fetchJournalEntries(startDate: Date, endDate: Date) -> [JournalEntry] {
        let fetchRequest: NSFetchRequest<JournalEntry> = NSFetchRequest(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: true)]

        do {
            return try dataController.container.viewContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }

    // MARK: - Cascade Analysis

    private func analyzeCascades(from patterns: [ExtractedPattern]) -> [(from: String, to: String, count: Int)] {
        var cascadeCounts: [String: Int] = [:]

        for pattern in patterns {
            if let cascades = pattern.cascadesFrom {
                for cascade in cascades {
                    if let from = cascade.fromPattern?.patternType,
                       let to = cascade.toPattern?.patternType {
                        let key = "\(from) → \(to)"
                        cascadeCounts[key, default: 0] += 1
                    }
                }
            }
        }

        return cascadeCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { key, count in
                let parts = key.components(separatedBy: " → ")
                return (from: parts.first ?? "", to: parts.last ?? "", count: count)
            }
    }

    private func findCascadeInsights(patterns: [ExtractedPattern]) -> [String] {
        var insights: [String] = []
        var cascadeCounts: [String: Int] = [:]

        for pattern in patterns {
            if let cascades = pattern.cascadesFrom {
                for cascade in cascades {
                    if let from = cascade.fromPattern?.patternType,
                       let to = cascade.toPattern?.patternType {
                        let key = "\(from) → \(to)"
                        cascadeCounts[key, default: 0] += 1
                    }
                }
            }
        }

        // Find most common cascades
        let sorted = cascadeCounts.sorted { $0.value > $1.value }
        if let top = sorted.first, top.value >= 3 {
            insights.append("\"\(top.key)\" happened \(top.value) times this month")
        }

        // Check for concerning cascades
        let concerningPatterns = ["Meltdown", "Shutdown", "Burnout Indicator"]
        for (cascade, count) in cascadeCounts where count >= 2 {
            let parts = cascade.components(separatedBy: " → ")
            if let to = parts.last, concerningPatterns.contains(to) {
                if let from = parts.first {
                    insights.append("\(from) often led to \(to.lowercased()) (\(count) times)")
                }
            }
        }

        return insights
    }

    // MARK: - Correlations (using ExtractedPattern)

    private func findCorrelations(patterns: [ExtractedPattern]) -> [String] {
        var correlations: [String] = []
        let calendar = Calendar.current

        var sleepQualityByDay: [Date: Int16] = [:]
        var nextDayOverload: [Date: Int] = [:]
        var maskingByDay: [Date: Int16] = [:]
        var burnoutByDay: [Date: Bool] = [:]

        for pattern in patterns {
            let startOfDay = calendar.startOfDay(for: pattern.timestamp)

            if pattern.patternType == "Sleep Quality" {
                sleepQualityByDay[startOfDay] = pattern.intensity
            }

            if pattern.patternType == "Sensory Overload" {
                nextDayOverload[startOfDay, default: 0] += 1
            }

            if pattern.patternType == "Masking Intensity" {
                maskingByDay[startOfDay] = max(maskingByDay[startOfDay] ?? 0, pattern.intensity)
            }

            if pattern.patternType == "Burnout Indicator" {
                burnoutByDay[startOfDay] = true
            }
        }

        // Sleep → Sensory Overload correlation
        var poorSleepToOverload = 0
        var totalPoorSleep = 0

        for (sleepDate, quality) in sleepQualityByDay where quality <= 3 {
            totalPoorSleep += 1
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: sleepDate),
               let overloadCount = nextDayOverload[nextDay], overloadCount > 0 {
                poorSleepToOverload += 1
            }
        }

        if totalPoorSleep >= 3 && Double(poorSleepToOverload) / Double(totalPoorSleep) > 0.5 {
            correlations.append("Poor sleep often precedes sensory overload the next day")
        }

        // High masking → Burnout correlation
        var highMaskingToBurnout = 0
        var totalHighMasking = 0

        for (maskDate, intensity) in maskingByDay where intensity >= 7 {
            totalHighMasking += 1
            // Check next 1-2 days for burnout
            for dayOffset in 1...2 {
                if let checkDay = calendar.date(byAdding: .day, value: dayOffset, to: maskDate),
                   burnoutByDay[checkDay] == true {
                    highMaskingToBurnout += 1
                    break
                }
            }
        }

        if totalHighMasking >= 3 && Double(highMaskingToBurnout) / Double(totalHighMasking) > 0.4 {
            correlations.append("High masking intensity often precedes burnout within 1-2 days")
        }

        // Intensity patterns
        let highIntensityPatterns = patterns.filter { $0.intensity >= 7 }
        let lowIntensityPatterns = patterns.filter { $0.intensity <= 3 }

        if highIntensityPatterns.count > lowIntensityPatterns.count * 2 {
            correlations.append("This period had significantly more high-intensity experiences")
        } else if lowIntensityPatterns.count > highIntensityPatterns.count * 2 {
            correlations.append("This period was relatively calmer with lower intensity experiences")
        }

        return correlations
    }

    // MARK: - Day Analysis (using ExtractedPattern)

    private func analyzeDays(dailyPatterns: [Date: [ExtractedPattern]]) -> ([String], [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var dayScores: [(Date, Double)] = []

        let positivePatternTypes = [
            "Flow State Achieved",
            "Authenticity Moment",
            "Special Interest Engagement",
            "Hyperfocus Session"
        ]

        let challengingPatternTypes = [
            "Sensory Overload",
            "Meltdown",
            "Shutdown",
            "Burnout Indicator",
            "Emotional Overwhelm"
        ]

        for (date, patterns) in dailyPatterns {
            var score: Double = 0.0

            let challengingCount = patterns.filter {
                challengingPatternTypes.contains($0.patternType)
            }.count

            let positiveCount = patterns.filter {
                positivePatternTypes.contains($0.patternType)
            }.count

            // Also factor in intensity
            let avgIntensity = patterns.isEmpty ? 0 :
                Double(patterns.map { Int($0.intensity) }.reduce(0, +)) / Double(patterns.count)

            // Higher intensity = more challenging (unless positive patterns)
            let intensityFactor = positiveCount > challengingCount ? (10 - avgIntensity) / 10 : -avgIntensity / 10

            score = Double(positiveCount) - Double(challengingCount) + intensityFactor

            dayScores.append((date, score))
        }

        let sorted = dayScores.sorted { $0.1 > $1.1 }

        let bestDays = sorted.prefix(3).map { dateFormatter.string(from: $0.0) }
        let challengingDays = sorted.suffix(3).reversed().map { dateFormatter.string(from: $0.0) }

        return (bestDays, challengingDays)
    }

    // MARK: - Medication Insights (using ExtractedPattern)

    private func generateMedicationInsights(days: Int, patterns: [ExtractedPattern]) -> [MedicationInsight] {
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

            // Analyze medication-behavior correlations using ExtractedPattern
            correlationNotes.append(contentsOf: analyzeMedicationBehaviorCorrelations(
                medicationLogs: takenLogs,
                patterns: patterns
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
        patterns: [ExtractedPattern]
    ) -> [String] {
        var correlations: [String] = []
        let calendar = Calendar.current

        let positivePatternTypes = [
            "Flow State Achieved",
            "Authenticity Moment",
            "Special Interest Engagement",
            "Hyperfocus Session"
        ]

        let challengingPatternTypes = [
            "Sensory Overload",
            "Meltdown",
            "Shutdown",
            "Burnout Indicator",
            "Emotional Overwhelm"
        ]

        // Group patterns by day
        var patternsByDay: [Date: [ExtractedPattern]] = [:]
        for pattern in patterns {
            let startOfDay = calendar.startOfDay(for: pattern.timestamp)
            patternsByDay[startOfDay, default: []].append(pattern)
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
            if let dayPatterns = patternsByDay[day] {
                let positives = dayPatterns.filter {
                    positivePatternTypes.contains($0.patternType)
                }.count

                let negatives = dayPatterns.filter {
                    challengingPatternTypes.contains($0.patternType)
                }.count

                positivePatternCount += positives
                negativePatternCount += negatives
            }
        }

        if !highEffectivenessDays.isEmpty {
            if positivePatternCount > negativePatternCount * 2 {
                correlations.append("High medication effectiveness correlates with more positive experiences")
            }
            if negativePatternCount < highEffectivenessDays.count {
                correlations.append("Fewer challenging patterns on days with high medication effectiveness")
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

        // Check average intensity on medication days vs overall
        var medDayIntensities: [Int16] = []
        for day in medLogsByDay.keys {
            if let dayPatterns = patternsByDay[day] {
                medDayIntensities.append(contentsOf: dayPatterns.map { $0.intensity })
            }
        }

        if !medDayIntensities.isEmpty {
            let avgMedDayIntensity = Double(medDayIntensities.reduce(0, +)) / Double(medDayIntensities.count)
            let overallAvg = patterns.isEmpty ? 0 :
                Double(patterns.map { Int($0.intensity) }.reduce(0, +)) / Double(patterns.count)

            if avgMedDayIntensity < overallAvg - 1 {
                correlations.append("Pattern intensity tends to be lower on medication days")
            }
        }

        return correlations
    }
}

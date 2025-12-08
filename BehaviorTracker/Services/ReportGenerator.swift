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

struct LifeGoalsSummary {
    var activeGoals: Int = 0
    var completedGoals: Int = 0
    var overdueGoals: Int = 0
    var activeStruggles: Int = 0
    var resolvedStruggles: Int = 0
    var severeStruggles: Int = 0
    var wishlistPending: Int = 0
    var wishlistAcquired: Int = 0
    var topGoals: [String] = []
    var topStruggles: [(name: String, intensity: String)] = []
    var recentlyAcquired: [String] = []
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
    var lifeGoalsSummary: LifeGoalsSummary = LifeGoalsSummary()
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
    var lifeGoalsSummary: LifeGoalsSummary = LifeGoalsSummary()
}

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ReportSummary {
    var tldr: String = ""
    var recommendations: [String] = []
    var moodTrend: String = ""
    var topPattern: String = ""
    var dataSource: String = "" // "journal", "manual", or "combined"
}

class ReportGenerator {
    private var dataController: DataController { DataController.shared }
    private let calendarService = CalendarEventService.shared
    private let healthManager = HealthKitManager.shared

    // MARK: - Summary Generation

    func generateSummary() async -> ReportSummary {
        var summary = ReportSummary()

        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return ReportSummary()
        }

        // Gather data from all sources
        let patterns = fetchExtractedPatterns(startDate: weekAgo, endDate: Date())
        let journals = fetchJournalEntries(startDate: weekAgo, endDate: Date())
        let setupItems = SetupItemRepository.shared.fetch(activeOnly: true)
        let events = calendarService.fetchEvents(from: weekAgo, to: Date())
        let healthSummary = await healthManager.fetchHealthSummary()

        // Analyze patterns
        let challengingPatterns = ["Sensory Overload", "Meltdown", "Shutdown", "Burnout Indicator", "Emotional Overwhelm"]
        let positivePatterns = ["Flow State Achieved", "Authenticity Moment", "Special Interest Engagement"]

        let challengingCount = patterns.filter { challengingPatterns.contains($0.patternType) }.count
        let positiveCount = patterns.filter { positivePatterns.contains($0.patternType) }.count
        let avgIntensity = patterns.isEmpty ? 0.0 :
            Double(patterns.map { Int($0.intensity) }.reduce(0, +)) / Double(patterns.count)

        // Calculate mood from journals
        let avgMood = journals.isEmpty ? 0.0 :
            Double(journals.compactMap { $0.mood }.reduce(0, +)) / Double(journals.count)

        // Determine data sources used
        var sources: [String] = []
        if !patterns.isEmpty { sources.append("journal") }
        if !events.isEmpty { sources.append("calendar") }
        if healthSummary.sleepDuration != nil || healthSummary.steps != nil { sources.append("health") }
        if !setupItems.isEmpty { sources.append("setup") }
        summary.dataSource = sources.joined(separator: ", ")

        // Generate TL;DR
        summary.tldr = generateTLDR(
            patterns: patterns,
            journals: journals,
            challengingCount: challengingCount,
            positiveCount: positiveCount,
            avgMood: avgMood,
            avgIntensity: avgIntensity,
            events: events,
            healthSummary: healthSummary
        )

        // Generate recommendations
        summary.recommendations = generateRecommendations(
            patterns: patterns,
            challengingCount: challengingCount,
            positiveCount: positiveCount,
            avgIntensity: avgIntensity,
            setupItems: setupItems,
            events: events,
            healthSummary: healthSummary
        )

        // Set top pattern
        let patternCounts = Dictionary(grouping: patterns, by: { $0.patternType })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        summary.topPattern = patternCounts.first?.key ?? ""

        // Set mood trend
        if avgMood >= 4 {
            summary.moodTrend = "positive"
        } else if avgMood >= 3 {
            summary.moodTrend = "stable"
        } else if avgMood > 0 {
            summary.moodTrend = "challenging"
        } else {
            summary.moodTrend = "unknown"
        }

        return summary
    }

    private func generateTLDR(
        patterns: [ExtractedPattern],
        journals: [JournalEntry],
        challengingCount: Int,
        positiveCount: Int,
        avgMood: Double,
        avgIntensity: Double,
        events: [CalendarEvent],
        healthSummary: HealthDataSummary
    ) -> String {
        var sentences: [String] = []

        // Overall state based on pattern balance
        if patterns.isEmpty && journals.isEmpty {
            return "No data recorded this week. Start journaling to get personalized insights about your patterns and experiences."
        }

        // Opening sentence about overall week
        if positiveCount > challengingCount * 2 {
            sentences.append("This has been a great week with mostly positive experiences and good regulation.")
        } else if challengingCount > positiveCount * 2 {
            sentences.append("This week has been challenging with more difficult moments than usual.")
        } else if positiveCount > 0 || challengingCount > 0 {
            sentences.append("This week has been a mix of ups and downs, with both positive and challenging moments.")
        } else {
            sentences.append("This has been a relatively quiet week with steady patterns.")
        }

        // Pattern details
        if !patterns.isEmpty {
            let patternCounts = Dictionary(grouping: patterns, by: { $0.patternType })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if let topPattern = patternCounts.first {
                sentences.append("Your most frequent pattern was \(topPattern.key) (\(topPattern.value) times).")
            }

            // Category breakdown
            let categoryCounts = Dictionary(grouping: patterns, by: { $0.category })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if let topCategory = categoryCounts.first, categoryCounts.count > 1 {
                sentences.append("\(topCategory.key) patterns were most common this week.")
            }
        }

        // Journal engagement
        if !journals.isEmpty {
            sentences.append("You wrote \(journals.count) journal \(journals.count == 1 ? "entry" : "entries").")
        }

        // Sleep context
        if let sleepHours = healthSummary.sleepHours {
            if sleepHours < 6 {
                sentences.append("Sleep has been below optimal at around \(String(format: "%.1f", sleepHours)) hours average.")
            } else if sleepHours >= 8 {
                sentences.append("Sleep has been good with \(String(format: "%.1f", sleepHours)) hours average.")
            } else {
                sentences.append("Sleep averaged \(String(format: "%.1f", sleepHours)) hours.")
            }
        }

        // Calendar busyness
        if events.count > 20 {
            sentences.append("Your calendar was very busy with \(events.count) events.")
        } else if events.count > 10 {
            sentences.append("You had a moderately busy schedule with \(events.count) events.")
        }

        // Intensity note
        if avgIntensity > 7 {
            sentences.append("Overall intensity was high this week, averaging \(String(format: "%.1f", avgIntensity))/10.")
        } else if avgIntensity > 4 && !patterns.isEmpty {
            sentences.append("Average intensity was moderate at \(String(format: "%.1f", avgIntensity))/10.")
        }

        return sentences.joined(separator: " ")
    }

    private func generateRecommendations(
        patterns: [ExtractedPattern],
        challengingCount: Int,
        positiveCount: Int,
        avgIntensity: Double,
        setupItems: [SetupItem],
        events: [CalendarEvent],
        healthSummary: HealthDataSummary
    ) -> [String] {
        var recommendations: [String] = []

        // Sleep-based recommendation
        if let sleepHours = healthSummary.sleepHours, sleepHours < 7 {
            recommendations.append("Prioritize sleep - aim for 7-8 hours to support regulation")
        }

        // Pattern-based recommendations
        if challengingCount > positiveCount {
            recommendations.append("Schedule recovery time - you've had more challenging moments than positive ones")
        }

        if avgIntensity > 7 {
            recommendations.append("Consider reducing sensory input - intensity has been high")
        }

        // Calendar-based recommendation
        if let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) {
            let upcomingEvents = CalendarEventService.shared.fetchEvents(
                from: Date(),
                to: futureDate
            )
            if upcomingEvents.count > 8 {
                recommendations.append("Busy days ahead - plan buffer time between activities")
            }
        }

        // Setup-based recommendations
        let medications = setupItems.filter { $0.categoryEnum == .medication }
        let activities = setupItems.filter { $0.categoryEnum == .activity }

        if medications.isEmpty && challengingCount > 2 {
            recommendations.append("Track your medications/supplements to find what helps")
        }

        if activities.isEmpty {
            recommendations.append("Add a calming activity to your routine")
        }

        // Positive reinforcement
        if positiveCount > challengingCount && recommendations.count < 3 {
            recommendations.append("Keep doing what's working - more positive patterns than challenging ones")
        }

        // Pattern-specific
        let triggers = patterns.flatMap { $0.triggers }
        let triggerCounts = Dictionary(grouping: triggers, by: { $0 }).mapValues { $0.count }
        if let topTrigger = triggerCounts.max(by: { $0.value < $1.value }), topTrigger.value >= 3 {
            recommendations.append("Watch out for '\(topTrigger.key)' - it's been a frequent trigger")
        }

        // Ensure we have exactly 3 recommendations
        if recommendations.isEmpty {
            recommendations.append("Keep journaling to build more personalized insights")
        }

        // Default fillers if needed
        let defaults = [
            "Take breaks when you notice rising intensity",
            "Use your coping strategies early when triggers appear",
            "Celebrate small wins - they add up"
        ]

        while recommendations.count < 3 {
            if let next = defaults.first(where: { !recommendations.contains($0) }) {
                recommendations.append(next)
            } else {
                break
            }
        }

        return Array(recommendations.prefix(3))
    }

    // MARK: - Weekly Report (uses ExtractedPattern)

    func generateWeeklyReport() -> WeeklyReport {
        var report = WeeklyReport()

        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return WeeklyReport()
        }

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
            // Normalize category name to handle legacy data
            let normalizedCategory = PatternCategory.normalizedName(pattern.category)
            categoryCounts[normalizedCategory, default: 0] += 1

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

        // Add life goals summary
        report.lifeGoalsSummary = generateLifeGoalsSummary()

        return report
    }

    // MARK: - Monthly Report (uses ExtractedPattern)

    func generateMonthlyReport() -> MonthlyReport {
        var report = MonthlyReport()

        let calendar = Calendar.current
        guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return MonthlyReport()
        }

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
            if categoryByDay[pattern.category] != nil {
                categoryByDay[pattern.category]?[startOfDay, default: []].append(pattern.intensity)
            }
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

        // Add life goals summary
        report.lifeGoalsSummary = generateLifeGoalsSummary()

        return report
    }

    // MARK: - Life Goals Summary

    private func generateLifeGoalsSummary() -> LifeGoalsSummary {
        var summary = LifeGoalsSummary()

        // Fetch data from repositories
        let allGoals = GoalRepository.shared.fetch(includeCompleted: true)
        let allStruggles = StruggleRepository.shared.fetch(activeOnly: false)
        let allWishlistItems = WishlistRepository.shared.fetch(includeAcquired: true)

        // Goals stats
        let activeGoals = allGoals.filter { !$0.isCompleted }
        let completedGoals = allGoals.filter { $0.isCompleted }
        let overdueGoals = allGoals.filter { $0.isOverdue }

        summary.activeGoals = activeGoals.count
        summary.completedGoals = completedGoals.count
        summary.overdueGoals = overdueGoals.count
        summary.topGoals = activeGoals.sorted { $0.priority > $1.priority }.prefix(3).map { $0.title }

        // Struggles stats
        let activeStruggles = allStruggles.filter { $0.isActive }
        let resolvedStruggles = allStruggles.filter { !$0.isActive }
        let severeStruggles = activeStruggles.filter { $0.intensityLevel.rawValue >= Struggle.Intensity.severe.rawValue }

        summary.activeStruggles = activeStruggles.count
        summary.resolvedStruggles = resolvedStruggles.count
        summary.severeStruggles = severeStruggles.count
        summary.topStruggles = activeStruggles
            .sorted { $0.intensity > $1.intensity }
            .prefix(3)
            .map { (name: $0.title, intensity: $0.intensityLevel.displayName) }

        // Wishlist stats
        let pendingWishlist = allWishlistItems.filter { !$0.isAcquired }
        let acquiredWishlist = allWishlistItems.filter { $0.isAcquired }

        summary.wishlistPending = pendingWishlist.count
        summary.wishlistAcquired = acquiredWishlist.count
        summary.recentlyAcquired = acquiredWishlist
            .sorted { ($0.acquiredAt ?? .distantPast) > ($1.acquiredAt ?? .distantPast) }
            .prefix(3)
            .map { $0.title }

        return summary
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
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
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
                guard let effects = log.sideEffects else { return false }
                return !effects.isEmpty
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

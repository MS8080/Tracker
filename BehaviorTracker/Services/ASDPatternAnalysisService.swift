import Foundation
import CoreData
import SwiftUI

// MARK: - ASD Insight Models

struct ASDInsight: Identifiable {
    let id = UUID()
    let type: ASDInsightType
    let title: String
    let message: String
    let severity: Severity
    let icon: String
    let color: Color
    let actionSuggestion: String?
    let relatedPatterns: [String]
    let dataPoints: Int

    enum Severity: Comparable {
        case info
        case attention
        case warning
        case urgent

        var priority: Int {
            switch self {
            case .info: return 0
            case .attention: return 1
            case .warning: return 2
            case .urgent: return 3
            }
        }

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.priority < rhs.priority
        }
    }
}

enum ASDInsightType: String {
    case meltdownRisk = "Meltdown Risk"
    case sensoryLoad = "Sensory Load"
    case maskingFatigue = "Masking Fatigue"
    case socialBattery = "Social Battery"
    case routineDisruption = "Routine Disruption"
    case triggerPattern = "Trigger Pattern"
    case recoveryNeeded = "Recovery Needed"
    case burnoutWarning = "Burnout Warning"
    case positivePattern = "Positive Pattern"
    case sleepImpact = "Sleep Impact"
}

struct DailyLoad: Identifiable {
    let id = UUID()
    let date: Date
    let sensoryLoad: Double
    let socialLoad: Double
    let demandLoad: Double
    let overallLoad: Double
    let hadMeltdownOrShutdown: Bool
}

struct TriggerChain: Identifiable {
    let id = UUID()
    let triggers: [String]
    let outcome: String
    let occurrences: Int
    let averageIntensity: Double
}

// MARK: - ASD Pattern Analysis Service

@MainActor
class ASDPatternAnalysisService: ObservableObject {
    static let shared = ASDPatternAnalysisService()

    @Published var currentInsights: [ASDInsight] = []
    @Published var dailyLoads: [DailyLoad] = []
    @Published var triggerChains: [TriggerChain] = []
    @Published var isAnalyzing = false

    private let dataController = DataController.shared

    private init() {}

    // MARK: - Helper Methods

    /// Filter patterns by category for a given date
    private func patternsForCategory(_ patterns: [PatternEntry], category: PatternCategory, on date: Date? = nil) -> [PatternEntry] {
        let calendar = Calendar.current
        return patterns.filter {
            let categoryMatch = PatternType(rawValue: $0.patternType)?.category == category
            if let date = date {
                return categoryMatch && calendar.isDate($0.timestamp, inSameDayAs: date)
            }
            return categoryMatch
        }
    }

    /// Filter patterns by type
    private func patternsOfType(_ patterns: [PatternEntry], type: PatternType, on date: Date? = nil) -> [PatternEntry] {
        let calendar = Calendar.current
        return patterns.filter {
            let typeMatch = $0.patternType == type.rawValue
            if let date = date {
                return typeMatch && calendar.isDate($0.timestamp, inSameDayAs: date)
            }
            return typeMatch
        }
    }

    /// Calculate average intensity for patterns
    private func averageIntensity(_ patterns: [PatternEntry]) -> Double {
        guard !patterns.isEmpty else { return 0 }
        return Double(patterns.reduce(0) { $0 + Int($1.intensity) }) / Double(patterns.count)
    }

    /// Get today's patterns from a collection
    private func todayPatterns(from patterns: [PatternEntry]) -> [PatternEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return patterns.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }

    // MARK: - Main Analysis

    func analyzePatterns(days: Int = 14) async {
        isAnalyzing = true

        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            isAnalyzing = false
            return
        }

        let patterns = dataController.fetchPatternEntries(startDate: startDate, endDate: Date())
        let journalEntries = dataController.fetchJournalEntries(startDate: startDate, endDate: Date())

        var insights: [ASDInsight] = []

        // Run all analyses
        insights.append(contentsOf: analyzeMeltdownRisk(patterns: patterns, days: days))
        insights.append(contentsOf: analyzeSensoryLoad(patterns: patterns))
        insights.append(contentsOf: analyzeMaskingFatigue(patterns: patterns))
        insights.append(contentsOf: analyzeSocialBattery(patterns: patterns))
        insights.append(contentsOf: analyzeRoutineDisruption(patterns: patterns, days: days))
        insights.append(contentsOf: analyzeTriggerPatterns(patterns: patterns))
        insights.append(contentsOf: analyzeBurnoutIndicators(patterns: patterns, journals: journalEntries))
        insights.append(contentsOf: analyzeSleepImpact(patterns: patterns))
        insights.append(contentsOf: findPositivePatterns(patterns: patterns))

        // Calculate daily loads for visualization
        dailyLoads = calculateDailyLoads(patterns: patterns, days: days)

        // Find trigger chains
        triggerChains = findTriggerChains(patterns: patterns)

        // Sort by severity (urgent first)
        currentInsights = insights.sorted { $0.severity > $1.severity }

        isAnalyzing = false
    }

    // MARK: - Meltdown Risk Analysis

    private func analyzeMeltdownRisk(patterns: [PatternEntry], days: Int) -> [ASDInsight] {
        var insights: [ASDInsight] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todaysPatterns = todayPatterns(from: patterns)

        // Calculate cumulative stress factors
        var riskScore: Double = 0
        var riskFactors: [String] = []

        // Check for high-intensity sensory patterns today
        let sensoryPatterns = patternsForCategory(todaysPatterns, category: .sensory)
        let avgSensoryIntensity = averageIntensity(sensoryPatterns)

        if avgSensoryIntensity >= 4 {
            riskScore += 25
            riskFactors.append("High sensory load")
        } else if avgSensoryIntensity >= 3 {
            riskScore += 15
        }

        // Check for masking
        let maskingPatterns = patternsOfType(todaysPatterns, type: .maskingIntensity)
        let avgMaskingIntensity = averageIntensity(maskingPatterns)

        if avgMaskingIntensity >= 4 {
            riskScore += 20
            riskFactors.append("Extended masking")
        } else if avgMaskingIntensity >= 3 {
            riskScore += 10
        }

        // Check for emotional overwhelm
        let overwhelmPatterns = patternsOfType(todaysPatterns, type: .emotionalOverwhelm)
        if !overwhelmPatterns.isEmpty {
            riskScore += averageIntensity(overwhelmPatterns) * 6
            riskFactors.append("Emotional overwhelm")
        }

        // Check for routine disruption
        let routinePatterns = patternsForCategory(todaysPatterns, category: .routineChange)
        if !routinePatterns.isEmpty {
            riskScore += averageIntensity(routinePatterns) * 4
            riskFactors.append("Routine disruption")
        }

        // Check for demand overload
        let demandPatterns = patternsForCategory(todaysPatterns, category: .demandAvoidance)
        if demandPatterns.count >= 2 {
            riskScore += 15
            riskFactors.append("Multiple demands")
        }

        // Check sleep from yesterday/today
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: today)!
        let recentPatterns = patterns.filter { $0.timestamp >= yesterdayStart }
        let sleepPatterns = patternsOfType(recentPatterns, type: .sleepQuality)
        if let lastSleep = sleepPatterns.first, lastSleep.intensity <= 2 {
            riskScore += 15
            riskFactors.append("Poor sleep")
        }

        // Generate insight based on risk score
        if riskScore >= 60 {
            insights.append(ASDInsight(
                type: .meltdownRisk,
                title: "High Meltdown Risk",
                message: "Multiple stress factors accumulating. Consider taking preventive action now.",
                severity: .urgent,
                icon: "exclamationmark.triangle.fill",
                color: .red,
                actionSuggestion: "Take a sensory break, reduce demands, and allow recovery time",
                relatedPatterns: riskFactors,
                dataPoints: todaysPatterns.count
            ))
        } else if riskScore >= 40 {
            insights.append(ASDInsight(
                type: .meltdownRisk,
                title: "Elevated Stress Load",
                message: "Stress factors building up: \(riskFactors.joined(separator: ", "))",
                severity: .warning,
                icon: "exclamationmark.circle.fill",
                color: .orange,
                actionSuggestion: "Consider a short break or reducing upcoming demands",
                relatedPatterns: riskFactors,
                dataPoints: todaysPatterns.count
            ))
        } else if riskScore >= 25 {
            insights.append(ASDInsight(
                type: .meltdownRisk,
                title: "Moderate Load",
                message: "Some stress present but manageable",
                severity: .attention,
                icon: "gauge.medium",
                color: .yellow,
                actionSuggestion: "Monitor and take breaks as needed",
                relatedPatterns: riskFactors,
                dataPoints: todaysPatterns.count
            ))
        }

        return insights
    }

    // MARK: - Sensory Load Analysis

    private func analyzeSensoryLoad(patterns: [PatternEntry]) -> [ASDInsight] {
        var insights: [ASDInsight] = []

        let todaySensory = patternsForCategory(todayPatterns(from: patterns), category: .sensory)
        guard !todaySensory.isEmpty else { return insights }

        let avgIntensity = averageIntensity(todaySensory)
        let recoveryLogged = todaySensory.contains { $0.patternType == PatternType.sensoryRecovery.rawValue }

        if avgIntensity >= 4 && !recoveryLogged {
            insights.append(ASDInsight(
                type: .sensoryLoad,
                title: "Sensory Overload Building",
                message: "High sensory input today with no recovery logged",
                severity: .warning,
                icon: "waveform.path.ecg",
                color: .purple,
                actionSuggestion: "Find a quiet, low-stimulation space for recovery",
                relatedPatterns: todaySensory.map { $0.patternType },
                dataPoints: todaySensory.count
            ))
        } else if avgIntensity >= 3 && todaySensory.count >= 3 {
            insights.append(ASDInsight(
                type: .sensoryLoad,
                title: "Elevated Sensory Load",
                message: "\(todaySensory.count) sensory events logged today",
                severity: .attention,
                icon: "ear.trianglebadge.exclamationmark",
                color: .purple,
                actionSuggestion: "Consider wearing ear protection or reducing visual stimulation",
                relatedPatterns: todaySensory.map { $0.patternType },
                dataPoints: todaySensory.count
            ))
        }

        return insights
    }

    // MARK: - Masking Fatigue Analysis

    private func analyzeMaskingFatigue(patterns: [PatternEntry]) -> [ASDInsight] {
        var insights: [ASDInsight] = []
        let calendar = Calendar.current

        // Look at last 3 days of masking
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let recentMasking = patterns.filter {
            $0.timestamp >= threeDaysAgo &&
            $0.patternType == PatternType.maskingIntensity.rawValue
        }

        guard !recentMasking.isEmpty else { return insights }

        let avgMasking = averageIntensity(recentMasking)

        // Check for consecutive high masking days
        var consecutiveHighDays = 0
        for dayOffset in 0..<3 {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let dayMasking = recentMasking.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            if averageIntensity(dayMasking) >= 3 {
                consecutiveHighDays += 1
            }
        }

        if consecutiveHighDays >= 3 {
            insights.append(ASDInsight(
                type: .maskingFatigue,
                title: "Masking Burnout Risk",
                message: "High masking for \(consecutiveHighDays) consecutive days",
                severity: .urgent,
                icon: "theatermasks.fill",
                color: .green,
                actionSuggestion: "Schedule unmasked time with safe people or alone",
                relatedPatterns: ["Masking Intensity"],
                dataPoints: recentMasking.count
            ))
        } else if avgMasking >= 4 {
            insights.append(ASDInsight(
                type: .maskingFatigue,
                title: "High Masking Load",
                message: "Average masking intensity: \(String(format: "%.1f", avgMasking))/5",
                severity: .warning,
                icon: "theatermasks",
                color: .green,
                actionSuggestion: "Plan for recovery time after social demands",
                relatedPatterns: ["Masking Intensity"],
                dataPoints: recentMasking.count
            ))
        }

        return insights
    }

    // MARK: - Social Battery Analysis

    private func analyzeSocialBattery(patterns: [PatternEntry]) -> [ASDInsight] {
        var insights: [ASDInsight] = []

        let todaySocial = patternsForCategory(todayPatterns(from: patterns), category: .social)

        // Calculate social drain vs recovery
        let interactions = patternsOfType(todaySocial, type: .socialInteraction)
        let recoveries = patternsOfType(todaySocial, type: .socialRecovery)

        let drainTotal = interactions.reduce(0) { $0 + Int($1.intensity) }
        let recoveryTotal = recoveries.reduce(0) { $0 + Int($1.intensity) }

        let balance = recoveryTotal - drainTotal

        if balance < -8 && interactions.count >= 2 {
            insights.append(ASDInsight(
                type: .socialBattery,
                title: "Social Battery Depleted",
                message: "Multiple social interactions without adequate recovery",
                severity: .warning,
                icon: "battery.25percent",
                color: .cyan,
                actionSuggestion: "Prioritize alone time and avoid additional social commitments",
                relatedPatterns: ["Social Interaction", "Social Recovery"],
                dataPoints: todaySocial.count
            ))
        } else if balance < -4 {
            insights.append(ASDInsight(
                type: .socialBattery,
                title: "Social Energy Low",
                message: "More social output than recovery today",
                severity: .attention,
                icon: "battery.50percent",
                color: .cyan,
                actionSuggestion: "Schedule some quiet recovery time",
                relatedPatterns: ["Social Interaction", "Social Recovery"],
                dataPoints: todaySocial.count
            ))
        }

        return insights
    }

    // MARK: - Routine Disruption Analysis

    private func analyzeRoutineDisruption(patterns: [PatternEntry], days: Int) -> [ASDInsight] {
        var insights: [ASDInsight] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayRoutine = patternsForCategory(todayPatterns(from: patterns), category: .routineChange)

        if !todayRoutine.isEmpty {
            let avgIntensity = averageIntensity(todayRoutine)

            if avgIntensity >= 4 || todayRoutine.count >= 2 {
                insights.append(ASDInsight(
                    type: .routineDisruption,
                    title: "Significant Routine Disruption",
                    message: "\(todayRoutine.count) routine changes logged",
                    severity: .warning,
                    icon: "arrow.triangle.2.circlepath",
                    color: .cyan,
                    actionSuggestion: "Anchor to familiar activities when possible",
                    relatedPatterns: todayRoutine.map { $0.patternType },
                    dataPoints: todayRoutine.count
                ))
            }
        }

        // Analyze for missing expected patterns (routine deviation)
        // Look at what patterns typically occur by this time of day
        let currentHour = calendar.component(.hour, from: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let historicalPatterns = patterns.filter {
            $0.timestamp >= weekAgo && !calendar.isDate($0.timestamp, inSameDayAs: today)
        }

        // Group by pattern type and time
        var typicalMorningPatterns: Set<String> = []
        for pattern in historicalPatterns {
            let hour = calendar.component(.hour, from: pattern.timestamp)
            if hour >= 6 && hour < 12 && currentHour >= 12 {
                typicalMorningPatterns.insert(pattern.patternType)
            }
        }

        // Compare with today - analyze missing patterns
        let todaysPatterns = todayPatterns(from: patterns)
        let todayTypes = Set(todaysPatterns.map { $0.patternType })

        // Check if expected morning patterns are missing
        let missingPatterns = typicalMorningPatterns.subtracting(todayTypes)
        if missingPatterns.count >= 2 && typicalMorningPatterns.count >= 3 {
            insights.append(ASDInsight(
                type: .routineDisruption,
                title: "Routine Deviation",
                message: "Some typical morning activities not logged yet",
                severity: .info,
                icon: "clock.badge.questionmark",
                color: .cyan,
                actionSuggestion: "Check if your routine has been disrupted",
                relatedPatterns: Array(missingPatterns.prefix(3)),
                dataPoints: missingPatterns.count
            ))
        }

        return insights
    }

    // MARK: - Trigger Pattern Analysis

    private func analyzeTriggerPatterns(patterns: [PatternEntry]) -> [ASDInsight] {
        var insights: [ASDInsight] = []

        // Find patterns that frequently precede meltdowns/shutdowns
        let meltdownShutdownPatterns = patterns.filter {
            $0.patternType == PatternType.meltdown.rawValue ||
            $0.patternType == PatternType.shutdown.rawValue
        }

        guard meltdownShutdownPatterns.count >= 2 else { return insights }

        var precedingPatternCounts: [String: Int] = [:]
        let calendar = Calendar.current

        for crisis in meltdownShutdownPatterns {
            // Look at patterns in the 4 hours before
            let fourHoursBefore = calendar.date(byAdding: .hour, value: -4, to: crisis.timestamp)!

            let precedingPatterns = patterns.filter {
                $0.timestamp >= fourHoursBefore &&
                $0.timestamp < crisis.timestamp &&
                $0.patternType != crisis.patternType
            }

            for pattern in precedingPatterns {
                precedingPatternCounts[pattern.patternType, default: 0] += 1
            }
        }

        // Find most common preceding patterns
        let sortedTriggers = precedingPatternCounts.sorted { $0.value > $1.value }

        if let topTrigger = sortedTriggers.first, topTrigger.value >= 2 {
            let percentage = (Double(topTrigger.value) / Double(meltdownShutdownPatterns.count)) * 100

            if percentage >= 50 {
                insights.append(ASDInsight(
                    type: .triggerPattern,
                    title: "Common Trigger Identified",
                    message: "\"\(topTrigger.key)\" preceded \(Int(percentage))% of meltdowns/shutdowns",
                    severity: .attention,
                    icon: "arrow.right.circle",
                    color: .orange,
                    actionSuggestion: "Watch for this pattern as an early warning sign",
                    relatedPatterns: [topTrigger.key, PatternType.meltdown.rawValue],
                    dataPoints: topTrigger.value
                ))
            }
        }

        return insights
    }

    // MARK: - Burnout Analysis

    private func analyzeBurnoutIndicators(patterns: [PatternEntry], journals: [JournalEntry]) -> [ASDInsight] {
        var insights: [ASDInsight] = []
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let recentPatterns = patterns.filter { $0.timestamp >= weekAgo }

        // Check for burnout indicator patterns
        let burnoutPatterns = patternsOfType(recentPatterns, type: .burnoutIndicator)

        if !burnoutPatterns.isEmpty {
            let avgIntensity = averageIntensity(burnoutPatterns)

            if avgIntensity >= 4 || burnoutPatterns.count >= 3 {
                insights.append(ASDInsight(
                    type: .burnoutWarning,
                    title: "Autistic Burnout Warning",
                    message: "Multiple burnout indicators logged this week",
                    severity: .urgent,
                    icon: "flame.fill",
                    color: .red,
                    actionSuggestion: "Reduce all non-essential demands and prioritize rest",
                    relatedPatterns: ["Burnout Indicator"],
                    dataPoints: burnoutPatterns.count
                ))
            } else {
                insights.append(ASDInsight(
                    type: .burnoutWarning,
                    title: "Burnout Risk Elevated",
                    message: "Burnout symptoms appearing",
                    severity: .warning,
                    icon: "flame",
                    color: .orange,
                    actionSuggestion: "Consider reducing commitments this week",
                    relatedPatterns: ["Burnout Indicator"],
                    dataPoints: burnoutPatterns.count
                ))
            }
        }

        // Check for executive function degradation (increasing task avoidance)
        let taskAvoidance = patternsOfType(recentPatterns, type: .taskAvoidance)

        if taskAvoidance.count >= 5 {
            let avgIntensity = averageIntensity(taskAvoidance)
            if avgIntensity >= 3 {
                insights.append(ASDInsight(
                    type: .burnoutWarning,
                    title: "Executive Function Strain",
                    message: "Frequent task avoidance may indicate overload",
                    severity: .attention,
                    icon: "brain.head.profile",
                    color: .orange,
                    actionSuggestion: "Break tasks into smaller steps or defer non-urgent items",
                    relatedPatterns: ["Task Avoidance"],
                    dataPoints: taskAvoidance.count
                ))
            }
        }

        return insights
    }

    // MARK: - Sleep Impact Analysis

    private func analyzeSleepImpact(patterns: [PatternEntry]) -> [ASDInsight] {
        var insights: [ASDInsight] = []
        let calendar = Calendar.current

        // Get last 7 days of sleep data
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let recentPatterns = patterns.filter { $0.timestamp >= weekAgo }
        let sleepPatterns = patternsOfType(recentPatterns, type: .sleepQuality)

        guard sleepPatterns.count >= 3 else { return insights }

        let avgSleep = averageIntensity(sleepPatterns)

        // Count poor sleep days
        let poorSleepDays = sleepPatterns.filter { $0.intensity <= 2 }.count

        if poorSleepDays >= 3 {
            insights.append(ASDInsight(
                type: .sleepImpact,
                title: "Sleep Pattern Concern",
                message: "\(poorSleepDays) poor sleep nights this week",
                severity: .warning,
                icon: "moon.zzz.fill",
                color: .indigo,
                actionSuggestion: "Review sleep routine and reduce evening stimulation",
                relatedPatterns: ["Sleep Quality"],
                dataPoints: sleepPatterns.count
            ))
        } else if avgSleep <= 2.5 {
            insights.append(ASDInsight(
                type: .sleepImpact,
                title: "Below Average Sleep",
                message: "Sleep quality averaging \(String(format: "%.1f", avgSleep))/5",
                severity: .attention,
                icon: "moon.fill",
                color: .indigo,
                actionSuggestion: "Consider adjusting bedtime routine",
                relatedPatterns: ["Sleep Quality"],
                dataPoints: sleepPatterns.count
            ))
        }

        return insights
    }

    // MARK: - Positive Pattern Analysis

    private func findPositivePatterns(patterns: [PatternEntry]) -> [ASDInsight] {
        var insights: [ASDInsight] = []
        let todaysPatterns = todayPatterns(from: patterns)

        // Positive pattern definitions
        let positiveTypes: [(type: PatternType, title: String, message: String, icon: String, color: Color)] = [
            (.flowState, "Flow State Achieved", "You found your flow today", "sparkles", .blue),
            (.specialInterest, "Special Interest Time", "You engaged with something you love", "star.fill", .yellow),
            (.authenticityMoment, "Authenticity Moment", "You were your true self", "heart.fill", .pink)
        ]

        for positive in positiveTypes {
            let matches = patternsOfType(todaysPatterns, type: positive.type)
            if !matches.isEmpty {
                insights.append(ASDInsight(
                    type: .positivePattern,
                    title: positive.title,
                    message: positive.message,
                    severity: .info,
                    icon: positive.icon,
                    color: positive.color,
                    actionSuggestion: nil,
                    relatedPatterns: [positive.type.rawValue],
                    dataPoints: matches.count
                ))
            }
        }

        return insights
    }

    // MARK: - Daily Load Calculation

    /// Calculate load for a category (sum of intensities / 5.0)
    private func loadForCategory(_ patterns: [PatternEntry], category: PatternCategory) -> Double {
        let categoryPatterns = patternsForCategory(patterns, category: category)
        guard !categoryPatterns.isEmpty else { return 0 }
        return Double(categoryPatterns.reduce(0) { $0 + Int($1.intensity) }) / 5.0
    }

    private func calculateDailyLoads(patterns: [PatternEntry], days: Int) -> [DailyLoad] {
        var loads: [DailyLoad] = []
        let calendar = Calendar.current

        for dayOffset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: day)) else { continue }

            let dayStart = calendar.startOfDay(for: day)
            let dayPatterns = patterns.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }

            let sensoryLoad = loadForCategory(dayPatterns, category: .sensory)
            let socialLoad = loadForCategory(dayPatterns, category: .social)
            let demandLoad = loadForCategory(dayPatterns, category: .demandAvoidance)

            let hadCrisis = !patternsOfType(dayPatterns, type: .meltdown).isEmpty ||
                           !patternsOfType(dayPatterns, type: .shutdown).isEmpty

            loads.append(DailyLoad(
                date: dayStart,
                sensoryLoad: sensoryLoad,
                socialLoad: socialLoad,
                demandLoad: demandLoad,
                overallLoad: (sensoryLoad + socialLoad + demandLoad) / 3.0,
                hadMeltdownOrShutdown: hadCrisis
            ))
        }

        return loads.reversed()
    }

    // MARK: - Trigger Chain Analysis

    private func findTriggerChains(patterns: [PatternEntry]) -> [TriggerChain] {
        var chains: [TriggerChain] = []
        let calendar = Calendar.current

        // Find all meltdowns/shutdowns
        let crisisEvents = patterns.filter {
            $0.patternType == PatternType.meltdown.rawValue ||
            $0.patternType == PatternType.shutdown.rawValue
        }

        var chainCounts: [String: (triggers: [String], count: Int, totalIntensity: Int)] = [:]

        for crisis in crisisEvents {
            // Get patterns in the 2 hours before
            let twoHoursBefore = calendar.date(byAdding: .hour, value: -2, to: crisis.timestamp)!

            let precedingPatterns = patterns.filter {
                $0.timestamp >= twoHoursBefore &&
                $0.timestamp < crisis.timestamp
            }
            .sorted { $0.timestamp < $1.timestamp }

            if precedingPatterns.count >= 2 {
                let triggerTypes = precedingPatterns.map { $0.patternType }
                let key = triggerTypes.joined(separator: " → ")

                if let existing = chainCounts[key] {
                    chainCounts[key] = (existing.triggers, existing.count + 1, existing.totalIntensity + Int(crisis.intensity))
                } else {
                    chainCounts[key] = (triggerTypes, 1, Int(crisis.intensity))
                }
            }
        }

        // Convert to TriggerChain objects
        for (_, data) in chainCounts where data.count >= 2 {
            chains.append(TriggerChain(
                triggers: data.triggers,
                outcome: "Meltdown/Shutdown",
                occurrences: data.count,
                averageIntensity: Double(data.totalIntensity) / Double(data.count)
            ))
        }

        return chains.sorted { $0.occurrences > $1.occurrences }
    }

    // MARK: - Quick Risk Assessment

    func getCurrentRiskLevel() -> (level: String, color: Color, score: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let patterns = dataController.fetchPatternEntries(startDate: today, endDate: Date())

        var riskScore = 0

        // Sensory load
        let sensory = patternsForCategory(patterns, category: .sensory)
        riskScore += Int(averageIntensity(sensory)) * 4

        // Masking
        let masking = patternsOfType(patterns, type: .maskingIntensity)
        riskScore += Int(averageIntensity(masking)) * 5

        // Emotional overwhelm
        if !patternsOfType(patterns, type: .emotionalOverwhelm).isEmpty {
            riskScore += 20
        }

        // Routine disruption
        riskScore += patternsForCategory(patterns, category: .routineChange).count * 5

        // Already had meltdown/shutdown
        if !patternsOfType(patterns, type: .meltdown).isEmpty ||
           !patternsOfType(patterns, type: .shutdown).isEmpty {
            riskScore += 30
        }

        switch riskScore {
        case 60...: return ("High", .red, riskScore)
        case 35...: return ("Elevated", .orange, riskScore)
        case 15...: return ("Moderate", .yellow, riskScore)
        default: return ("Low", .green, riskScore)
        }
    }
}

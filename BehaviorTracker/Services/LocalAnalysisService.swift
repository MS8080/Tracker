import Foundation
import CoreData

/// Local analysis service that provides insights without requiring AI/internet access.
/// Uses pattern matching, statistical analysis, and rule-based insights.
class LocalAnalysisService {
    static let shared = LocalAnalysisService()

    private let dataController = DataController.shared

    private init() {}

    // MARK: - Analysis Preferences (same as AI service for compatibility)

    struct AnalysisPreferences {
        var includePatterns: Bool = true
        var includeJournals: Bool = true
        var includeMedications: Bool = true
        var includeExtractedPatterns: Bool = true
        var includeCascades: Bool = true
        var timeframeDays: Int = 30
    }

    // MARK: - Main Analysis Function

    func analyzeData(preferences: AnalysisPreferences = AnalysisPreferences()) async -> LocalInsights {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -preferences.timeframeDays, to: endDate)!

        var sections: [LocalInsightSection] = []

        // Gather all data
        let patterns = preferences.includePatterns ? await fetchPatterns(startDate: startDate, endDate: endDate) : []
        let journals = preferences.includeJournals ? await fetchJournals(startDate: startDate, endDate: endDate) : []
        let medications = preferences.includeMedications ? fetchMedications() : []
        let medicationLogs = preferences.includeMedications ? fetchMedicationLogs(startDate: startDate, endDate: endDate) : []
        let extractedPatterns = preferences.includeExtractedPatterns ? fetchExtractedPatterns(startDate: startDate, endDate: endDate) : []
        let cascades = preferences.includeCascades ? fetchCascades(startDate: startDate, endDate: endDate) : []

        // Generate insights from each data source
        if !patterns.isEmpty {
            sections.append(contentsOf: analyzePatterns(patterns))
        }

        if !journals.isEmpty {
            sections.append(contentsOf: analyzeJournals(journals))
        }

        if !medications.isEmpty || !medicationLogs.isEmpty {
            sections.append(contentsOf: analyzeMedications(medications: medications, logs: medicationLogs, patterns: patterns))
        }

        if !extractedPatterns.isEmpty {
            sections.append(contentsOf: analyzeExtractedPatterns(extractedPatterns))
        }

        if !cascades.isEmpty {
            sections.append(contentsOf: analyzeCascades(cascades))
        }

        // Generate actionable suggestions
        let suggestions = generateSuggestions(
            patterns: patterns,
            journals: journals,
            medicationLogs: medicationLogs,
            extractedPatterns: extractedPatterns
        )

        if !suggestions.isEmpty {
            sections.append(LocalInsightSection(
                title: "Suggestions",
                icon: "lightbulb.fill",
                insights: suggestions
            ))
        }

        return LocalInsights(
            generatedAt: Date(),
            timeframeDays: preferences.timeframeDays,
            sections: sections
        )
    }

    // MARK: - Pattern Analysis

    private func analyzePatterns(_ patterns: [PatternEntry]) -> [LocalInsightSection] {
        var sections: [LocalInsightSection] = []
        var insights: [LocalInsightItem] = []

        // Overall stats
        let totalCount = patterns.count
        let avgIntensity = patterns.isEmpty ? 0 : Double(patterns.reduce(0) { $0 + Int($1.intensity) }) / Double(patterns.count)

        insights.append(LocalInsightItem(
            type: .statistic,
            title: "Total Patterns Logged",
            description: "\(totalCount) patterns over this period",
            value: "\(totalCount)",
            trend: nil
        ))

        insights.append(LocalInsightItem(
            type: .statistic,
            title: "Average Intensity",
            description: "Across all pattern types",
            value: String(format: "%.1f/5", avgIntensity),
            trend: avgIntensity > 3 ? .negative : (avgIntensity < 2.5 ? .positive : .neutral)
        ))

        // Top patterns by frequency
        let patternCounts = Dictionary(grouping: patterns, by: { $0.patternType })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        if let topPattern = patternCounts.first {
            insights.append(LocalInsightItem(
                type: .pattern,
                title: "Most Frequent Pattern",
                description: "\(topPattern.key) occurred \(topPattern.value) times",
                value: topPattern.key,
                trend: nil
            ))
        }

        // Time of day analysis
        let timeAnalysis = analyzeTimeOfDay(patterns)
        if let peakTime = timeAnalysis.max(by: { $0.value < $1.value }), peakTime.value > 0 {
            insights.append(LocalInsightItem(
                type: .time,
                title: "Peak Activity Time",
                description: "Most patterns logged during the \(peakTime.key.lowercased())",
                value: peakTime.key,
                trend: nil
            ))
        }

        // High intensity patterns
        let highIntensity = patterns.filter { $0.intensity >= 4 }
        if !highIntensity.isEmpty {
            let percentage = Int((Double(highIntensity.count) / Double(patterns.count)) * 100)
            insights.append(LocalInsightItem(
                type: .warning,
                title: "High Intensity Events",
                description: "\(highIntensity.count) events (\(percentage)%) were high intensity (4-5)",
                value: "\(highIntensity.count)",
                trend: percentage > 30 ? .negative : .neutral
            ))
        }

        // Contributing factors
        var factorCounts: [String: Int] = [:]
        for pattern in patterns {
            for factor in pattern.contributingFactors {
                factorCounts[factor.rawValue, default: 0] += 1
            }
        }

        let topFactors = factorCounts.sorted { $0.value > $1.value }.prefix(3)
        if !topFactors.isEmpty {
            let factorList = topFactors.map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
            insights.append(LocalInsightItem(
                type: .factor,
                title: "Top Contributing Factors",
                description: factorList,
                value: nil,
                trend: nil
            ))
        }

        sections.append(LocalInsightSection(
            title: "Pattern Analysis",
            icon: "brain.head.profile",
            insights: insights
        ))

        // Category breakdown
        var categoryInsights: [LocalInsightItem] = []
        let categoryGroups = Dictionary(grouping: patterns, by: { $0.category })

        for (category, categoryPatterns) in categoryGroups.sorted(by: { $0.value.count > $1.value.count }) {
            let categoryAvg = Double(categoryPatterns.reduce(0) { $0 + Int($1.intensity) }) / Double(categoryPatterns.count)
            categoryInsights.append(LocalInsightItem(
                type: .category,
                title: category,
                description: "\(categoryPatterns.count) patterns, avg intensity \(String(format: "%.1f", categoryAvg))/5",
                value: "\(categoryPatterns.count)",
                trend: categoryAvg > 3.5 ? .negative : (categoryAvg < 2.5 ? .positive : .neutral)
            ))
        }

        if !categoryInsights.isEmpty {
            sections.append(LocalInsightSection(
                title: "By Category",
                icon: "folder.fill",
                insights: categoryInsights
            ))
        }

        return sections
    }

    private func analyzeTimeOfDay(_ patterns: [PatternEntry]) -> [String: Int] {
        var timeCounts: [String: Int] = ["Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0]
        let calendar = Calendar.current

        for pattern in patterns {
            let hour = calendar.component(.hour, from: pattern.timestamp)
            switch hour {
            case 6..<12: timeCounts["Morning", default: 0] += 1
            case 12..<17: timeCounts["Afternoon", default: 0] += 1
            case 17..<21: timeCounts["Evening", default: 0] += 1
            default: timeCounts["Night", default: 0] += 1
            }
        }

        return timeCounts
    }

    // MARK: - Journal Analysis

    private func analyzeJournals(_ journals: [JournalEntry]) -> [LocalInsightSection] {
        var insights: [LocalInsightItem] = []

        insights.append(LocalInsightItem(
            type: .statistic,
            title: "Journal Entries",
            description: "\(journals.count) entries in this period",
            value: "\(journals.count)",
            trend: nil
        ))

        // Mood analysis
        let entriesWithMood = journals.filter { $0.mood > 0 }
        if !entriesWithMood.isEmpty {
            let avgMood = Double(entriesWithMood.reduce(0) { $0 + Int($1.mood) }) / Double(entriesWithMood.count)

            insights.append(LocalInsightItem(
                type: .mood,
                title: "Average Mood",
                description: moodDescription(avgMood),
                value: String(format: "%.1f/5", avgMood),
                trend: avgMood >= 3.5 ? .positive : (avgMood < 2.5 ? .negative : .neutral)
            ))

            // Mood trend (compare first half to second half)
            if entriesWithMood.count >= 4 {
                let sorted = entriesWithMood.sorted { $0.timestamp < $1.timestamp }
                let midpoint = sorted.count / 2
                let firstHalf = Array(sorted.prefix(midpoint))
                let secondHalf = Array(sorted.suffix(sorted.count - midpoint))

                let firstAvg = Double(firstHalf.reduce(0) { $0 + Int($1.mood) }) / Double(firstHalf.count)
                let secondAvg = Double(secondHalf.reduce(0) { $0 + Int($1.mood) }) / Double(secondHalf.count)

                let change = secondAvg - firstAvg
                if abs(change) >= 0.5 {
                    insights.append(LocalInsightItem(
                        type: .trend,
                        title: "Mood Trend",
                        description: change > 0 ? "Your mood has been improving" : "Your mood has been declining",
                        value: change > 0 ? "+\(String(format: "%.1f", change))" : String(format: "%.1f", change),
                        trend: change > 0 ? .positive : .negative
                    ))
                }
            }
        }

        // Journaling consistency
        let calendar = Calendar.current
        let uniqueDays = Set(journals.map { calendar.startOfDay(for: $0.timestamp) })
        let daysCovered = uniqueDays.count

        insights.append(LocalInsightItem(
            type: .streak,
            title: "Days Journaled",
            description: "\(daysCovered) unique days with journal entries",
            value: "\(daysCovered)",
            trend: nil
        ))

        return [LocalInsightSection(
            title: "Journal Insights",
            icon: "book.fill",
            insights: insights
        )]
    }

    private func moodDescription(_ mood: Double) -> String {
        switch mood {
        case 0..<1.5: return "Very low mood overall"
        case 1.5..<2.5: return "Generally low mood"
        case 2.5..<3.5: return "Neutral mood overall"
        case 3.5..<4.5: return "Generally good mood"
        default: return "Excellent mood overall"
        }
    }

    // MARK: - Medication Analysis

    private func analyzeMedications(medications: [Medication], logs: [MedicationLog], patterns: [PatternEntry]) -> [LocalInsightSection] {
        guard !medications.isEmpty else { return [] }

        var insights: [LocalInsightItem] = []

        insights.append(LocalInsightItem(
            type: .medication,
            title: "Active Medications",
            description: "\(medications.count) medications being tracked",
            value: "\(medications.count)",
            trend: nil
        ))

        // Adherence analysis
        if !logs.isEmpty {
            let takenLogs = logs.filter { $0.taken }
            let adherenceRate = Double(takenLogs.count) / Double(logs.count) * 100

            insights.append(LocalInsightItem(
                type: .adherence,
                title: "Overall Adherence",
                description: "\(takenLogs.count) of \(logs.count) logged doses taken",
                value: String(format: "%.0f%%", adherenceRate),
                trend: adherenceRate >= 80 ? .positive : (adherenceRate < 60 ? .negative : .neutral)
            ))

            // Effectiveness when reported
            let effectivenessLogs = takenLogs.filter { $0.effectiveness > 0 }
            if !effectivenessLogs.isEmpty {
                let avgEffectiveness = Double(effectivenessLogs.reduce(0) { $0 + Int($1.effectiveness) }) / Double(effectivenessLogs.count)
                insights.append(LocalInsightItem(
                    type: .effectiveness,
                    title: "Average Effectiveness",
                    description: "Based on \(effectivenessLogs.count) reports",
                    value: String(format: "%.1f/5", avgEffectiveness),
                    trend: avgEffectiveness >= 3.5 ? .positive : (avgEffectiveness < 2.5 ? .negative : .neutral)
                ))
            }

            // Medication-pattern correlation (simplified)
            for medication in medications {
                let medLogs = logs.filter { $0.medication?.id == medication.id && $0.taken }
                guard medLogs.count >= 3 else { continue }

                let takenDates = Set(medLogs.map { Calendar.current.startOfDay(for: $0.timestamp) })

                // Check patterns on medication days vs off days
                let patternsOnMedDays = patterns.filter { takenDates.contains(Calendar.current.startOfDay(for: $0.timestamp)) }
                let patternsOffMedDays = patterns.filter { !takenDates.contains(Calendar.current.startOfDay(for: $0.timestamp)) }

                if !patternsOnMedDays.isEmpty && !patternsOffMedDays.isEmpty {
                    let avgOnMed = Double(patternsOnMedDays.reduce(0) { $0 + Int($1.intensity) }) / Double(patternsOnMedDays.count)
                    let avgOffMed = Double(patternsOffMedDays.reduce(0) { $0 + Int($1.intensity) }) / Double(patternsOffMedDays.count)

                    let percentChange = avgOffMed > 0 ? ((avgOnMed - avgOffMed) / avgOffMed) * 100 : 0

                    if abs(percentChange) > 15 {
                        let direction = percentChange < 0 ? "lower" : "higher"
                        insights.append(LocalInsightItem(
                            type: .correlation,
                            title: "\(medication.name) Correlation",
                            description: "Pattern intensity is \(Int(abs(percentChange)))% \(direction) on days taking \(medication.name)",
                            value: percentChange < 0 ? "Better" : "Worse",
                            trend: percentChange < 0 ? .positive : .negative
                        ))
                    }
                }
            }
        }

        return [LocalInsightSection(
            title: "Medication Insights",
            icon: "pills.fill",
            insights: insights
        )]
    }

    // MARK: - Extracted Patterns Analysis

    private func analyzeExtractedPatterns(_ patterns: [ExtractedPattern]) -> [LocalInsightSection] {
        var insights: [LocalInsightItem] = []

        insights.append(LocalInsightItem(
            type: .statistic,
            title: "AI-Extracted Patterns",
            description: "\(patterns.count) patterns identified from journals",
            value: "\(patterns.count)",
            trend: nil
        ))

        // High intensity extracted patterns
        let highIntensity = patterns.filter { $0.intensity >= 7 }
        if !highIntensity.isEmpty {
            let topTypes = Dictionary(grouping: highIntensity, by: { $0.patternType })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(3)

            let typeList = topTypes.map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
            insights.append(LocalInsightItem(
                type: .warning,
                title: "High Intensity Patterns",
                description: "\(highIntensity.count) patterns at 7+/10: \(typeList)",
                value: "\(highIntensity.count)",
                trend: .negative
            ))
        }

        // Common triggers
        var triggerCounts: [String: Int] = [:]
        for pattern in patterns {
            for trigger in pattern.triggers {
                triggerCounts[trigger, default: 0] += 1
            }
        }

        let topTriggers = triggerCounts.sorted { $0.value > $1.value }.prefix(5)
        if !topTriggers.isEmpty {
            let triggerList = topTriggers.map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
            insights.append(LocalInsightItem(
                type: .trigger,
                title: "Common Triggers",
                description: triggerList,
                value: nil,
                trend: nil
            ))
        }

        // Coping strategies
        var copingCounts: [String: Int] = [:]
        for pattern in patterns {
            for strategy in pattern.copingStrategies {
                copingCounts[strategy, default: 0] += 1
            }
        }

        let topCoping = copingCounts.sorted { $0.value > $1.value }.prefix(3)
        if !topCoping.isEmpty {
            let copingList = topCoping.map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
            insights.append(LocalInsightItem(
                type: .coping,
                title: "Coping Strategies Used",
                description: copingList,
                value: nil,
                trend: .positive
            ))
        }

        return [LocalInsightSection(
            title: "Journal Pattern Analysis",
            icon: "sparkles",
            insights: insights
        )]
    }

    // MARK: - Cascade Analysis

    private func analyzeCascades(_ cascades: [PatternCascade]) -> [LocalInsightSection] {
        var insights: [LocalInsightItem] = []

        // Group cascades by from -> to
        var cascadeFrequency: [String: Int] = [:]

        for cascade in cascades {
            guard let fromPattern = cascade.fromPattern,
                  let toPattern = cascade.toPattern else { continue }

            let key = "\(fromPattern.patternType) → \(toPattern.patternType)"
            cascadeFrequency[key, default: 0] += 1
        }

        let topCascades = cascadeFrequency.sorted { $0.value > $1.value }.prefix(5)

        for (cascade, count) in topCascades {
            insights.append(LocalInsightItem(
                type: .cascade,
                title: cascade,
                description: "This pattern chain occurred \(count) times",
                value: "\(count)x",
                trend: nil
            ))
        }

        if insights.isEmpty {
            return []
        }

        return [LocalInsightSection(
            title: "Pattern Chains",
            icon: "arrow.triangle.branch",
            insights: insights
        )]
    }

    // MARK: - Suggestions Generator

    private func generateSuggestions(
        patterns: [PatternEntry],
        journals: [JournalEntry],
        medicationLogs: [MedicationLog],
        extractedPatterns: [ExtractedPattern]
    ) -> [LocalInsightItem] {
        var suggestions: [LocalInsightItem] = []

        // Suggestion based on high intensity patterns
        let highIntensity = patterns.filter { $0.intensity >= 4 }
        if !highIntensity.isEmpty {
            let timeAnalysis = analyzeTimeOfDay(highIntensity)
            if let peakTime = timeAnalysis.max(by: { $0.value < $1.value }), peakTime.value >= 2 {
                suggestions.append(LocalInsightItem(
                    type: .suggestion,
                    title: "Manage \(peakTime.key) Challenges",
                    description: "Most high-intensity events occur in the \(peakTime.key.lowercased()). Consider building in extra support or breaks during this time.",
                    value: nil,
                    trend: nil
                ))
            }
        }

        // Suggestion based on contributing factors
        var factorCounts: [String: Int] = [:]
        for pattern in highIntensity {
            for factor in pattern.contributingFactors {
                factorCounts[factor.rawValue, default: 0] += 1
            }
        }

        if let topFactor = factorCounts.max(by: { $0.value < $1.value }), topFactor.value >= 3 {
            suggestions.append(LocalInsightItem(
                type: .suggestion,
                title: "Address \(topFactor.key)",
                description: "'\(topFactor.key)' appears in \(topFactor.value) high-intensity events. Finding strategies to manage this factor could help.",
                value: nil,
                trend: nil
            ))
        }

        // Suggestion based on journaling frequency
        let calendar = Calendar.current
        let journalDays = Set(journals.map { calendar.startOfDay(for: $0.timestamp) })
        if journalDays.count < 7 && journals.count > 0 {
            suggestions.append(LocalInsightItem(
                type: .suggestion,
                title: "Journal More Frequently",
                description: "Regular journaling helps identify patterns. Try to write a brief entry each day, even just a few sentences.",
                value: nil,
                trend: nil
            ))
        }

        // Suggestion based on medication adherence
        if !medicationLogs.isEmpty {
            let takenLogs = medicationLogs.filter { $0.taken }
            let adherenceRate = Double(takenLogs.count) / Double(medicationLogs.count) * 100

            if adherenceRate < 80 {
                suggestions.append(LocalInsightItem(
                    type: .suggestion,
                    title: "Improve Medication Consistency",
                    description: "Your adherence is at \(Int(adherenceRate))%. Setting reminders or keeping medications visible can help maintain consistency.",
                    value: nil,
                    trend: nil
                ))
            }
        }

        // Suggestion based on coping strategies
        var copingCounts: [String: Int] = [:]
        for pattern in extractedPatterns {
            for strategy in pattern.copingStrategies {
                copingCounts[strategy, default: 0] += 1
            }
        }

        if let topCoping = copingCounts.max(by: { $0.value < $1.value }), topCoping.value >= 2 {
            suggestions.append(LocalInsightItem(
                type: .suggestion,
                title: "Keep Using \(topCoping.key)",
                description: "You've used '\(topCoping.key)' successfully \(topCoping.value) times. This seems to be an effective strategy for you.",
                value: nil,
                trend: .positive
            ))
        }

        // Positive reinforcement if things are going well
        let avgIntensity = patterns.isEmpty ? 0 : Double(patterns.reduce(0) { $0 + Int($1.intensity) }) / Double(patterns.count)
        if avgIntensity <= 2.5 && patterns.count >= 5 {
            suggestions.append(LocalInsightItem(
                type: .positive,
                title: "You're Doing Well",
                description: "Your average pattern intensity is low. Whatever you're doing seems to be working - keep it up!",
                value: nil,
                trend: .positive
            ))
        }

        return suggestions
    }

    // MARK: - Data Fetching

    @MainActor
    private func fetchPatterns(startDate: Date, endDate: Date) async -> [PatternEntry] {
        await dataController.fetchPatternEntriesAsync(startDate: startDate, endDate: endDate)
    }

    @MainActor
    private func fetchJournals(startDate: Date, endDate: Date) async -> [JournalEntry] {
        await dataController.fetchJournalEntries(startDate: startDate, endDate: endDate)
    }

    private func fetchMedications() -> [Medication] {
        dataController.fetchMedications(activeOnly: true)
    }

    private func fetchMedicationLogs(startDate: Date, endDate: Date) -> [MedicationLog] {
        dataController.fetchMedicationLogs(startDate: startDate, endDate: endDate)
    }

    private func fetchExtractedPatterns(startDate: Date, endDate: Date) -> [ExtractedPattern] {
        let context = dataController.container.viewContext
        let fetchRequest: NSFetchRequest<ExtractedPattern> = ExtractedPattern.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractedPattern.timestamp, ascending: false)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching extracted patterns: \(error)")
            return []
        }
    }

    private func fetchCascades(startDate: Date, endDate: Date) -> [PatternCascade] {
        let context = dataController.container.viewContext
        let fetchRequest: NSFetchRequest<PatternCascade> = PatternCascade.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PatternCascade.timestamp, ascending: false)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching cascades: \(error)")
            return []
        }
    }
}

// MARK: - Local Insights Models

struct LocalInsights: Equatable {
    let generatedAt: Date
    let timeframeDays: Int
    let sections: [LocalInsightSection]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: generatedAt)
    }

    static func == (lhs: LocalInsights, rhs: LocalInsights) -> Bool {
        lhs.generatedAt == rhs.generatedAt && lhs.sections == rhs.sections
    }
}

struct LocalInsightSection: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let insights: [LocalInsightItem]

    static func == (lhs: LocalInsightSection, rhs: LocalInsightSection) -> Bool {
        lhs.title == rhs.title && lhs.insights == rhs.insights
    }
}

struct LocalInsightItem: Equatable, Identifiable {
    let id = UUID()
    let type: LocalInsightType
    let title: String
    let description: String
    let value: String?
    let trend: LocalInsightTrend?

    static func == (lhs: LocalInsightItem, rhs: LocalInsightItem) -> Bool {
        lhs.title == rhs.title && lhs.description == rhs.description
    }
}

enum LocalInsightType {
    case statistic
    case pattern
    case time
    case warning
    case factor
    case category
    case mood
    case trend
    case streak
    case medication
    case adherence
    case effectiveness
    case correlation
    case trigger
    case coping
    case cascade
    case suggestion
    case positive
}

enum LocalInsightTrend {
    case positive
    case negative
    case neutral
}

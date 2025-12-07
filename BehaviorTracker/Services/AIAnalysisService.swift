import Foundation
import CoreData

/// Available AI models for analysis
enum AIModel: String, CaseIterable {
    case gemini = "Gemini"
    // Claude requires additional Vertex AI setup - disabled for now
    // case claude = "Claude"

    var displayName: String {
        switch self {
        case .gemini: return "Gemini 2.5 Flash"
        // case .claude: return "Claude Opus 4"
        }
    }

    var icon: String {
        switch self {
        case .gemini: return "sparkles"
        // case .claude: return "brain.head.profile"
        }
    }
}

class AIAnalysisService {
    static let shared = AIAnalysisService()

    private let dataController = DataController.shared
    private let geminiService = GeminiService.shared

    /// Currently selected AI model (stored in UserDefaults)
    var selectedModel: AIModel {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: "selected_ai_model"),
               let model = AIModel(rawValue: rawValue) {
                return model
            }
            return .gemini  // Default to Gemini
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selected_ai_model")
        }
    }

    private init() {}

    // MARK: - Analysis Preferences

    struct AnalysisPreferences {
        var includePatterns: Bool = true
        var includeJournals: Bool = true
        var includeMedications: Bool = true
        var includeExtractedPatterns: Bool = true  // AI-extracted patterns from journals
        var includeCascades: Bool = true           // Pattern cascade connections
        var includeLifeGoals: Bool = true          // Goals, Struggles, Wishlist
        var timeframeDays: Int = 30
    }

    // MARK: - Main Analysis Function

    func analyzeData(preferences: AnalysisPreferences = AnalysisPreferences()) async throws -> AIInsights {
        let prompt = await buildPrompt(preferences: preferences)
        let response = try await generateContent(prompt: prompt)

        return AIInsights(
            generatedAt: Date(),
            timeframeDays: preferences.timeframeDays,
            content: response
        )
    }

    /// Analyze with a custom prompt (for journal entry analysis)
    func analyzeWithPrompt(_ prompt: String) async throws -> String {
        return try await generateContent(prompt: prompt)
    }

    /// Generate content using the selected AI model
    private func generateContent(prompt: String) async throws -> String {
        // Currently only Gemini is available
        // Claude requires additional Vertex AI Model Garden setup
        return try await geminiService.generateContent(prompt: prompt)
    }

    // MARK: - Build Prompt

    private func buildPrompt(preferences: AnalysisPreferences) async -> String {
        var sections: [String] = []

        // System instruction
        sections.append("""
        You are a supportive assistant helping someone understand their autism-related behavioral patterns.
        Analyze the following tracking data and provide helpful, compassionate insights.

        Be specific and reference the actual data. Focus on:
        1. Patterns and correlations you notice
        2. Potential triggers to be aware of
        3. What seems to be helping
        4. Practical, actionable suggestions

        Keep your tone warm and supportive. Avoid clinical language.
        Format your response with clear sections using **bold headers**.
        """)

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -preferences.timeframeDays, to: endDate)!

        // Pattern data
        if preferences.includePatterns {
            let patternSummary = await gatherPatternData(startDate: startDate, endDate: endDate)
            if !patternSummary.isEmpty {
                sections.append("BEHAVIORAL PATTERNS (Last \(preferences.timeframeDays) days):\n\(patternSummary)")
            }
        }

        // Journal data
        if preferences.includeJournals {
            let journalSummary = await gatherJournalData(startDate: startDate, endDate: endDate)
            if !journalSummary.isEmpty {
                sections.append("JOURNAL ENTRIES (Last \(preferences.timeframeDays) days):\n\(journalSummary)")
            }
        }

        // Medication data
        if preferences.includeMedications {
            let medicationSummary = gatherMedicationData(startDate: startDate, endDate: endDate)
            if !medicationSummary.isEmpty {
                sections.append("MEDICATIONS & LOGS (Last \(preferences.timeframeDays) days):\n\(medicationSummary)")
            }
        }

        // AI-extracted patterns from journal entries
        if preferences.includeExtractedPatterns {
            let extractedSummary = gatherExtractedPatternData(startDate: startDate, endDate: endDate)
            if !extractedSummary.isEmpty {
                sections.append("AI-EXTRACTED PATTERNS FROM JOURNALS (Last \(preferences.timeframeDays) days):\n\(extractedSummary)")
            }
        }

        // Pattern cascades (connections between patterns)
        if preferences.includeCascades {
            let cascadeSummary = gatherCascadeData(startDate: startDate, endDate: endDate)
            if !cascadeSummary.isEmpty {
                sections.append("PATTERN CASCADES & CONNECTIONS (Last \(preferences.timeframeDays) days):\n\(cascadeSummary)")
            }
        }

        // Life Goals (Goals, Struggles, Wishlist)
        if preferences.includeLifeGoals {
            let lifeGoalsSummary = gatherLifeGoalsData()
            if !lifeGoalsSummary.isEmpty {
                sections.append("LIFE GOALS, STRUGGLES & WISHLIST:\n\(lifeGoalsSummary)")
            }
        }

        // Trends
        let trends = await gatherTrends(startDate: startDate, endDate: endDate)
        if !trends.isEmpty {
            sections.append("OBSERVED TRENDS:\n\(trends)")
        }

        sections.append("""
        Based on this data, provide your analysis with these sections:
        1. **Key Patterns** - What patterns do you see?
        2. **Potential Triggers** - What might be causing difficulties?
        3. **What's Helping** - What positive patterns do you notice?
        4. **Suggestions** - 2-3 specific, actionable ideas
        """)

        return sections.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Data Gathering

    @MainActor
    private func gatherPatternData(startDate: Date, endDate: Date) async -> String {
        let entries = await dataController.fetchPatternEntriesAsync(startDate: startDate, endDate: endDate)

        guard !entries.isEmpty else {
            return "No pattern entries logged in this period."
        }

        // Group by category
        var categoryStats: [String: (count: Int, totalIntensity: Int, types: [String: Int])] = [:]
        var contributingFactorCounts: [String: Int] = [:]
        var timeOfDayCounts: [String: Int] = ["Morning (6-12)": 0, "Afternoon (12-17)": 0, "Evening (17-21)": 0, "Night (21-6)": 0]

        let calendar = Calendar.current

        for entry in entries {
            let category = entry.category
            let patternType = entry.patternType
            let intensity = Int(entry.intensity)

            // Category stats
            if var stats = categoryStats[category] {
                stats.count += 1
                stats.totalIntensity += intensity
                stats.types[patternType, default: 0] += 1
                categoryStats[category] = stats
            } else {
                categoryStats[category] = (1, intensity, [patternType: 1])
            }

            // Contributing factors
            let factors = entry.contributingFactors
            for factor in factors {
                contributingFactorCounts[factor.rawValue, default: 0] += 1
            }

            // Time of day
            let hour = calendar.component(.hour, from: entry.timestamp)
            switch hour {
            case 6..<12: timeOfDayCounts["Morning (6-12)", default: 0] += 1
            case 12..<17: timeOfDayCounts["Afternoon (12-17)", default: 0] += 1
            case 17..<21: timeOfDayCounts["Evening (17-21)", default: 0] += 1
            default: timeOfDayCounts["Night (21-6)", default: 0] += 1
            }
        }

        var lines: [String] = []
        lines.append("Total entries: \(entries.count)")

        // Category breakdown
        for (category, stats) in categoryStats.sorted(by: { $0.value.count > $1.value.count }) {
            let avgIntensity = stats.count > 0 ? Double(stats.totalIntensity) / Double(stats.count) : 0
            let topTypes = stats.types.sorted { $0.value > $1.value }.prefix(3).map { "\($0.key) (\($0.value)x)" }
            lines.append("- \(category): \(stats.count) entries, avg intensity \(String(format: "%.1f", avgIntensity))/5")
            if !topTypes.isEmpty {
                lines.append("  Types: \(topTypes.joined(separator: ", "))")
            }
        }

        // Top contributing factors
        let topFactors = contributingFactorCounts.sorted { $0.value > $1.value }.prefix(5)
        if !topFactors.isEmpty {
            lines.append("\nTop contributing factors:")
            for (factor, count) in topFactors {
                lines.append("- \(factor): \(count)x")
            }
        }

        // Time of day distribution
        let activeTimeSlots = timeOfDayCounts.filter { $0.value > 0 }.sorted { $0.value > $1.value }
        if !activeTimeSlots.isEmpty {
            lines.append("\nTime of day distribution:")
            for (time, count) in activeTimeSlots {
                lines.append("- \(time): \(count) entries")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func gatherJournalData(startDate: Date, endDate: Date) async -> String {
        let allEntries = await dataController.fetchJournalEntries(startDate: startDate, endDate: endDate)

        // Filter out insight entries (saved AI insights shouldn't be re-analyzed)
        let entries = allEntries.filter { !$0.isInsight }

        guard !entries.isEmpty else {
            return "No journal entries in this period."
        }

        var lines: [String] = []
        lines.append("Total journal entries: \(entries.count)")

        // Mood stats
        let entriesWithMood = entries.filter { $0.mood > 0 }
        if !entriesWithMood.isEmpty {
            let avgMood = Double(entriesWithMood.reduce(0) { $0 + Int($1.mood) }) / Double(entriesWithMood.count)
            lines.append("Average mood rating: \(String(format: "%.1f", avgMood))/5")
        }

        // Include recent journal excerpts (anonymized - no specific names/places)
        lines.append("\nRecent journal themes:")
        for entry in entries.prefix(5) {
            let content = entry.content
            // Truncate long entries
            let excerpt = content.count > 200 ? String(content.prefix(200)) + "..." : content
            let moodText = entry.mood > 0 ? " (mood: \(entry.mood)/5)" : ""
            lines.append("- \"\(excerpt)\"\(moodText)")
        }

        return lines.joined(separator: "\n")
    }

    private func gatherMedicationData(startDate: Date, endDate: Date) -> String {
        let medications = dataController.fetchMedications(activeOnly: true)
        let logs = dataController.fetchMedicationLogs(startDate: startDate, endDate: endDate)

        guard !medications.isEmpty else {
            return "No medications being tracked."
        }

        var lines: [String] = []
        lines.append("Active medications: \(medications.count)")

        for medication in medications {
            let medLogs = logs.filter { $0.medication?.id == medication.id }
            let takenLogs = medLogs.filter { $0.taken }
            let skippedLogs = medLogs.filter { !$0.taken }

            var medLine = "- \(medication.name)"
            if let dosage = medication.dosage, !dosage.isEmpty {
                medLine += " (\(dosage))"
            }
            medLine += ", \(medication.frequency)"
            lines.append(medLine)

            if !medLogs.isEmpty {
                let adherenceRate = Double(takenLogs.count) / Double(medLogs.count) * 100
                lines.append("  Adherence: \(String(format: "%.0f", adherenceRate))% (\(takenLogs.count)/\(medLogs.count) logged doses)")

                // Effectiveness
                let effectivenessLogs = takenLogs.filter { $0.effectiveness > 0 }
                if !effectivenessLogs.isEmpty {
                    let avgEffectiveness = Double(effectivenessLogs.reduce(0) { $0 + Int($1.effectiveness) }) / Double(effectivenessLogs.count)
                    lines.append("  Avg effectiveness: \(String(format: "%.1f", avgEffectiveness))/5")
                }

                // Mood correlation
                let moodLogs = takenLogs.filter { $0.mood > 0 }
                if !moodLogs.isEmpty {
                    let avgMood = Double(moodLogs.reduce(0) { $0 + Int($1.mood) }) / Double(moodLogs.count)
                    lines.append("  Avg mood when taken: \(String(format: "%.1f", avgMood))/5")
                }

                // Energy correlation
                let energyLogs = takenLogs.filter { $0.energyLevel > 0 }
                if !energyLogs.isEmpty {
                    let avgEnergy = Double(energyLogs.reduce(0) { $0 + Int($1.energyLevel) }) / Double(energyLogs.count)
                    lines.append("  Avg energy when taken: \(String(format: "%.1f", avgEnergy))/5")
                }

                // Side effects
                let sideEffectLogs = takenLogs.compactMap { $0.sideEffects }.filter { !$0.isEmpty }
                if !sideEffectLogs.isEmpty {
                    lines.append("  Side effects reported: \(sideEffectLogs.count) times")
                }

                // Skipped reasons
                if !skippedLogs.isEmpty {
                    let reasons = skippedLogs.compactMap { $0.skippedReason }.filter { !$0.isEmpty }
                    if !reasons.isEmpty {
                        lines.append("  Skipped \(skippedLogs.count) times. Reasons: \(reasons.prefix(3).joined(separator: ", "))")
                    }
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Extracted Patterns (AI-extracted from journals)

    private func gatherExtractedPatternData(startDate: Date, endDate: Date) -> String {
        let context = dataController.container.viewContext

        let fetchRequest: NSFetchRequest<ExtractedPattern> = ExtractedPattern.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractedPattern.timestamp, ascending: false)]

        do {
            let patterns = try context.fetch(fetchRequest)

            guard !patterns.isEmpty else {
                return "No AI-extracted patterns in this period."
            }

            var lines: [String] = []
            lines.append("Total extracted patterns: \(patterns.count)")

            // Group by category
            var categoryStats: [String: (count: Int, totalIntensity: Int, types: [String: Int], triggers: [String: Int])] = [:]

            for pattern in patterns {
                let category = pattern.category
                let patternType = pattern.patternType
                let intensity = Int(pattern.intensity)

                if var stats = categoryStats[category] {
                    stats.count += 1
                    stats.totalIntensity += intensity
                    stats.types[patternType, default: 0] += 1
                    for trigger in pattern.triggers {
                        stats.triggers[trigger, default: 0] += 1
                    }
                    categoryStats[category] = stats
                } else {
                    var triggerCounts: [String: Int] = [:]
                    for trigger in pattern.triggers {
                        triggerCounts[trigger, default: 0] += 1
                    }
                    categoryStats[category] = (1, intensity, [patternType: 1], triggerCounts)
                }
            }

            // Category breakdown
            lines.append("\nBy Category:")
            for (category, stats) in categoryStats.sorted(by: { $0.value.count > $1.value.count }) {
                let avgIntensity = stats.count > 0 ? Double(stats.totalIntensity) / Double(stats.count) : 0
                lines.append("- \(category): \(stats.count) patterns, avg intensity \(String(format: "%.1f", avgIntensity))/10")

                // Top types in this category
                let topTypes = stats.types.sorted { $0.value > $1.value }.prefix(3)
                if !topTypes.isEmpty {
                    let typesStr = topTypes.map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
                    lines.append("  Top types: \(typesStr)")
                }

                // Top triggers in this category
                let topTriggers = stats.triggers.sorted { $0.value > $1.value }.prefix(3)
                if !topTriggers.isEmpty {
                    let triggersStr = topTriggers.map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
                    lines.append("  Common triggers: \(triggersStr)")
                }
            }

            // High intensity patterns (7+/10)
            let highIntensity = patterns.filter { $0.intensity >= 7 }
            if !highIntensity.isEmpty {
                lines.append("\nHigh intensity patterns (7+/10): \(highIntensity.count)")
                let highTypes = Dictionary(grouping: highIntensity, by: { $0.patternType })
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }
                    .prefix(5)
                for (type, count) in highTypes {
                    lines.append("  - \(type): \(count)x")
                }
            }

            // Coping strategies used
            var allCoping: [String: Int] = [:]
            for pattern in patterns {
                for strategy in pattern.copingStrategies {
                    allCoping[strategy, default: 0] += 1
                }
            }
            if !allCoping.isEmpty {
                lines.append("\nCoping strategies observed:")
                for (strategy, count) in allCoping.sorted(by: { $0.value > $1.value }).prefix(5) {
                    lines.append("  - \(strategy): \(count)x")
                }
            }

            // Time of day distribution
            var timeOfDayCounts: [String: Int] = [:]
            for pattern in patterns {
                if let timeOfDay = pattern.timeOfDay, !timeOfDay.isEmpty, timeOfDay.lowercased() != "unknown" {
                    timeOfDayCounts[timeOfDay, default: 0] += 1
                }
            }
            if !timeOfDayCounts.isEmpty {
                lines.append("\nTime of day distribution:")
                for (time, count) in timeOfDayCounts.sorted(by: { $0.value > $1.value }) {
                    lines.append("  - \(time.capitalized): \(count) patterns")
                }
            }

            return lines.joined(separator: "\n")

        } catch {
            return "Error fetching extracted patterns: \(error.localizedDescription)"
        }
    }

    // MARK: - Pattern Cascades

    private func gatherCascadeData(startDate: Date, endDate: Date) -> String {
        let context = dataController.container.viewContext

        let fetchRequest: NSFetchRequest<PatternCascade> = PatternCascade.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PatternCascade.timestamp, ascending: false)]

        do {
            let cascades = try context.fetch(fetchRequest)

            guard !cascades.isEmpty else {
                return "No pattern cascades detected in this period."
            }

            var lines: [String] = []
            lines.append("Total cascade connections: \(cascades.count)")

            // Group cascades by from -> to
            var cascadeFrequency: [String: (count: Int, avgConfidence: Double, descriptions: [String])] = [:]

            for cascade in cascades {
                guard let fromPattern = cascade.fromPattern,
                      let toPattern = cascade.toPattern else { continue }

                let key = "\(fromPattern.patternType) → \(toPattern.patternType)"

                if var stats = cascadeFrequency[key] {
                    stats.count += 1
                    stats.avgConfidence = (stats.avgConfidence * Double(stats.count - 1) + cascade.confidence) / Double(stats.count)
                    if let desc = cascade.descriptionText, !desc.isEmpty {
                        stats.descriptions.append(desc)
                    }
                    cascadeFrequency[key] = stats
                } else {
                    var descriptions: [String] = []
                    if let desc = cascade.descriptionText, !desc.isEmpty {
                        descriptions.append(desc)
                    }
                    cascadeFrequency[key] = (1, cascade.confidence, descriptions)
                }
            }

            // Most common cascades
            lines.append("\nMost common pattern chains:")
            for (cascade, stats) in cascadeFrequency.sorted(by: { $0.value.count > $1.value.count }).prefix(10) {
                lines.append("- \(cascade): \(stats.count)x (confidence: \(String(format: "%.0f", stats.avgConfidence * 100))%)")
                if let firstDesc = stats.descriptions.first {
                    lines.append("  Example: \(firstDesc)")
                }
            }

            // High-confidence cascades
            let highConfidence = cascades.filter { $0.confidence >= 0.7 }
            if !highConfidence.isEmpty && highConfidence.count != cascades.count {
                lines.append("\nHigh-confidence connections (70%+): \(highConfidence.count)")
            }

            return lines.joined(separator: "\n")

        } catch {
            return "Error fetching cascade data: \(error.localizedDescription)"
        }
    }

    // MARK: - Life Goals Data (Goals, Struggles, Wishlist)

    private func gatherLifeGoalsData() -> String {
        var lines: [String] = []

        // Fetch data from repositories
        let goals = GoalRepository.shared.fetch(includeCompleted: true)
        let struggles = StruggleRepository.shared.fetch(activeOnly: false)
        let wishlistItems = WishlistRepository.shared.fetch(includeAcquired: true)

        // Goals Summary
        if !goals.isEmpty {
            let activeGoals = goals.filter { !$0.isCompleted }
            let completedGoals = goals.filter { $0.isCompleted }
            let overdueGoals = goals.filter { $0.isOverdue }
            let pinnedGoals = goals.filter { $0.isPinned }

            lines.append("GOALS:")
            lines.append("- Total: \(goals.count) (\(activeGoals.count) active, \(completedGoals.count) completed)")

            if !overdueGoals.isEmpty {
                lines.append("- Overdue goals: \(overdueGoals.count)")
            }

            if !pinnedGoals.isEmpty {
                lines.append("- Pinned/priority goals: \(pinnedGoals.count)")
            }

            // Goal categories
            let categoryCounts = Dictionary(grouping: goals, by: { $0.categoryType?.rawValue ?? "Uncategorized" })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if categoryCounts.count > 1 {
                lines.append("- By category: \(categoryCounts.map { "\($0.key) (\($0.value))" }.joined(separator: ", "))")
            }

            // List active goals
            if !activeGoals.isEmpty {
                lines.append("\nActive goals:")
                for goal in activeGoals.prefix(5) {
                    var goalLine = "  - \(goal.title)"
                    if goal.progress > 0 {
                        goalLine += " (\(goal.progressPercentage)% complete)"
                    }
                    if goal.isOverdue {
                        goalLine += " [OVERDUE]"
                    } else if goal.isDueSoon {
                        goalLine += " [Due soon]"
                    }
                    if goal.isPinned {
                        goalLine += " [Pinned]"
                    }
                    lines.append(goalLine)
                }
            }
        }

        // Struggles Summary
        if !struggles.isEmpty {
            let activeStruggles = struggles.filter { $0.isActive }
            let resolvedStruggles = struggles.filter { !$0.isActive }
            let severeStruggles = struggles.filter { $0.intensityLevel.rawValue >= Struggle.Intensity.severe.rawValue }
            let pinnedStruggles = struggles.filter { $0.isPinned }

            lines.append("\nSTRUGGLES:")
            lines.append("- Total: \(struggles.count) (\(activeStruggles.count) active, \(resolvedStruggles.count) resolved)")

            if !severeStruggles.isEmpty {
                lines.append("- Severe/overwhelming struggles: \(severeStruggles.count)")
            }

            if !pinnedStruggles.isEmpty {
                lines.append("- Pinned struggles: \(pinnedStruggles.count)")
            }

            // Struggle categories
            let categoryCounts = Dictionary(grouping: activeStruggles, by: { $0.categoryType?.rawValue ?? "Uncategorized" })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if categoryCounts.count > 1 {
                lines.append("- By category: \(categoryCounts.map { "\($0.key) (\($0.value))" }.joined(separator: ", "))")
            }

            // Intensity distribution
            let intensityCounts = Dictionary(grouping: activeStruggles, by: { $0.intensityLevel.displayName })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if !intensityCounts.isEmpty {
                lines.append("- Intensity breakdown: \(intensityCounts.map { "\($0.key) (\($0.value))" }.joined(separator: ", "))")
            }

            // List active struggles
            if !activeStruggles.isEmpty {
                lines.append("\nActive struggles:")
                for struggle in activeStruggles.prefix(5) {
                    var struggleLine = "  - \(struggle.title) [\(struggle.intensityLevel.displayName)]"
                    if !struggle.triggersList.isEmpty {
                        struggleLine += " Triggers: \(struggle.triggersList.prefix(2).joined(separator: ", "))"
                    }
                    if !struggle.copingStrategiesList.isEmpty {
                        struggleLine += " Coping: \(struggle.copingStrategiesList.prefix(2).joined(separator: ", "))"
                    }
                    if struggle.isPinned {
                        struggleLine += " [Pinned]"
                    }
                    lines.append(struggleLine)
                }
            }
        }

        // Wishlist Summary
        if !wishlistItems.isEmpty {
            let pendingItems = wishlistItems.filter { !$0.isAcquired }
            let acquiredItems = wishlistItems.filter { $0.isAcquired }
            let highPriorityItems = wishlistItems.filter { $0.priorityLevel == .high && !$0.isAcquired }
            let pinnedItems = wishlistItems.filter { $0.isPinned }

            lines.append("\nWISHLIST:")
            lines.append("- Total: \(wishlistItems.count) (\(pendingItems.count) wanted, \(acquiredItems.count) acquired)")

            if !highPriorityItems.isEmpty {
                lines.append("- High priority wishes: \(highPriorityItems.count)")
            }

            if !pinnedItems.isEmpty {
                lines.append("- Pinned wishes: \(pinnedItems.count)")
            }

            // Wishlist categories
            let categoryCounts = Dictionary(grouping: pendingItems, by: { $0.categoryType?.rawValue ?? "Other" })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            if categoryCounts.count > 1 {
                lines.append("- By category: \(categoryCounts.map { "\($0.key) (\($0.value))" }.joined(separator: ", "))")
            }

            // List pending wishlist items
            if !pendingItems.isEmpty {
                lines.append("\nWishlist items:")
                for item in pendingItems.prefix(5) {
                    var itemLine = "  - \(item.title)"
                    if let category = item.categoryType {
                        itemLine += " (\(category.rawValue))"
                    }
                    itemLine += " [\(item.priorityLevel.displayName)]"
                    if item.isPinned {
                        itemLine += " [Pinned]"
                    }
                    lines.append(itemLine)
                }
            }

            // Recently acquired
            if !acquiredItems.isEmpty {
                let recent = acquiredItems.sorted { ($0.acquiredAt ?? .distantPast) > ($1.acquiredAt ?? .distantPast) }.prefix(3)
                lines.append("\nRecently acquired:")
                for item in recent {
                    lines.append("  - \(item.title)")
                }
            }
        }

        return lines.isEmpty ? "" : lines.joined(separator: "\n")
    }

    @MainActor
    private func gatherTrends(startDate: Date, endDate: Date) async -> String {
        let entries = await dataController.fetchPatternEntriesAsync(startDate: startDate, endDate: endDate)

        guard !entries.isEmpty else {
            return "Not enough data for trend analysis."
        }

        let calendar = Calendar.current
        var dayOfWeekCounts: [Int: Int] = [:]

        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.timestamp)
            dayOfWeekCounts[weekday, default: 0] += 1
        }

        var lines: [String] = []

        // Day of week patterns
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let sortedDays = dayOfWeekCounts.sorted { $0.value > $1.value }
        if let busiestDay = sortedDays.first {
            lines.append("- Most active logging day: \(dayNames[busiestDay.key]) (\(busiestDay.value) entries)")
        }
        if let quietestDay = sortedDays.last, sortedDays.count > 1 {
            lines.append("- Quietest day: \(dayNames[quietestDay.key]) (\(quietestDay.value) entries)")
        }

        // Streak info
        let preferences = dataController.getUserPreferences()
        if preferences.streakCount > 0 {
            lines.append("- Current logging streak: \(preferences.streakCount) days")
        }

        // High intensity patterns
        let highIntensityEntries = entries.filter { $0.intensity >= 4 }
        if !highIntensityEntries.isEmpty {
            lines.append("- High intensity events (4-5): \(highIntensityEntries.count) occurrences")

            // When do they happen?
            var highIntensityTimes: [String: Int] = [:]
            for entry in highIntensityEntries {
                let hour = calendar.component(.hour, from: entry.timestamp)
                let timeSlot: String
                switch hour {
                case 6..<12: timeSlot = "morning"
                case 12..<17: timeSlot = "afternoon"
                case 17..<21: timeSlot = "evening"
                default: timeSlot = "night"
                }
                highIntensityTimes[timeSlot, default: 0] += 1
            }
            if let peakTime = highIntensityTimes.max(by: { $0.value < $1.value }) {
                lines.append("  Most high-intensity events occur in the \(peakTime.key)")
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - AI Insights Model

struct AIInsights: Equatable {
    let generatedAt: Date
    let timeframeDays: Int
    let content: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: generatedAt)
    }

    static func == (lhs: AIInsights, rhs: AIInsights) -> Bool {
        lhs.generatedAt == rhs.generatedAt && lhs.content == rhs.content
    }
}

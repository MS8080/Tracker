import Foundation

class AIAnalysisService {
    static let shared = AIAnalysisService()

    private let dataController = DataController.shared
    private let geminiService = GeminiService.shared

    private init() {}

    // MARK: - Analysis Preferences

    struct AnalysisPreferences {
        var includePatterns: Bool = true
        var includeJournals: Bool = true
        var includeMedications: Bool = true
        var timeframeDays: Int = 30
    }

    // MARK: - Main Analysis Function

    func analyzeData(preferences: AnalysisPreferences = AnalysisPreferences()) async throws -> AIInsights {
        let prompt = buildPrompt(preferences: preferences)
        let response = try await geminiService.generateContent(prompt: prompt)

        return AIInsights(
            generatedAt: Date(),
            timeframeDays: preferences.timeframeDays,
            content: response
        )
    }

    // MARK: - Build Prompt

    private func buildPrompt(preferences: AnalysisPreferences) -> String {
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
            let patternSummary = gatherPatternData(startDate: startDate, endDate: endDate)
            if !patternSummary.isEmpty {
                sections.append("BEHAVIORAL PATTERNS (Last \(preferences.timeframeDays) days):\n\(patternSummary)")
            }
        }

        // Journal data
        if preferences.includeJournals {
            let journalSummary = gatherJournalData(startDate: startDate, endDate: endDate)
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

        // Trends
        let trends = gatherTrends(startDate: startDate, endDate: endDate)
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

    private func gatherPatternData(startDate: Date, endDate: Date) -> String {
        let entries = dataController.fetchPatternEntries(startDate: startDate, endDate: endDate)

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

    private func gatherJournalData(startDate: Date, endDate: Date) -> String {
        let entries = dataController.fetchJournalEntries(startDate: startDate, endDate: endDate)

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

    private func gatherTrends(startDate: Date, endDate: Date) -> String {
        let entries = dataController.fetchPatternEntries(startDate: startDate, endDate: endDate)

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

struct AIInsights {
    let generatedAt: Date
    let timeframeDays: Int
    let content: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: generatedAt)
    }
}

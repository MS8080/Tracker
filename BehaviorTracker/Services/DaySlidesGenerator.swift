import SwiftUI
import CoreData

/// Generates day summary slides using AI or local analysis
struct DaySlidesGenerator {

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Pattern & Cascade Collection

    /// Collect patterns and cascades from journal entries
    func collectPatternsAndCascades(from journals: [JournalEntry]) -> (patterns: [ExtractedPattern], cascades: [PatternCascade]) {
        var allPatterns: [ExtractedPattern] = []
        var allCascades: [PatternCascade] = []

        for journal in journals {
            let patterns = journal.patternsArray
            allPatterns.append(contentsOf: patterns)

            for pattern in patterns {
                if let cascades = pattern.cascadesFrom {
                    allCascades.append(contentsOf: cascades)
                }
            }
        }

        return (allPatterns, allCascades)
    }

    // MARK: - Data Summary Building

    /// Build structured data summary from patterns and journals
    func buildDataSummary(patterns: [ExtractedPattern], cascades: [PatternCascade], journals: [JournalEntry]) -> String {
        guard !patterns.isEmpty else {
            return buildRawJournalSummary(journals: journals)
        }

        var summary = "Today's patterns (already analyzed from journal entries):\n\n"

        // Add extracted patterns
        summary += "EXTRACTED PATTERNS:\n"
        for pattern in patterns.sorted(by: { $0.timestamp < $1.timestamp }) {
            let time = Self.timeFormatter.string(from: pattern.timestamp)
            summary += "- [\(time)] \(pattern.patternType) (\(pattern.category), intensity: \(pattern.intensity)/10)"
            if let details = pattern.details, !details.isEmpty {
                summary += "\n  Details: \"\(details)\""
            }
            if !pattern.triggers.isEmpty {
                summary += "\n  Triggers: \(pattern.triggers.joined(separator: ", "))"
            }
            summary += "\n"
        }
        summary += "\n"

        // Add cascades if present
        if !cascades.isEmpty {
            summary += "PATTERN CASCADES (what led to what):\n"
            for cascade in cascades {
                let from = cascade.fromPattern?.patternType ?? "Unknown"
                let to = cascade.toPattern?.patternType ?? "Unknown"
                summary += "- \(from) → \(to)"
                if let desc = cascade.descriptionText {
                    summary += ": \(desc)"
                }
                summary += " (confidence: \(Int(cascade.confidence * 100))%)\n"
            }
            summary += "\n"
        }

        // Add journal summaries for context
        summary += "JOURNAL CONTEXT:\n"
        for journal in journals.sorted(by: { $0.timestamp < $1.timestamp }) {
            let time = Self.timeFormatter.string(from: journal.timestamp)
            if let analysisSummary = journal.analysisSummary {
                summary += "- [\(time)] \(analysisSummary)\n"
            } else {
                summary += "- [\(time)] \(journal.preview)\n"
            }
        }

        // Add Life Goals context
        let lifeGoalsContext = buildLifeGoalsContext()
        if !lifeGoalsContext.isEmpty {
            summary += "\nLIFE CONTEXT:\n\(lifeGoalsContext)"
        }

        return summary
    }

    private func buildRawJournalSummary(journals: [JournalEntry]) -> String {
        var summary = "Today's journal entries (not yet analyzed for patterns):\n\n"
        for journal in journals {
            let time = Self.timeFormatter.string(from: journal.timestamp)
            let moodText = journal.mood > 0 ? " (mood: \(journal.mood)/5)" : ""
            summary += "- [\(time)]\(moodText): \"\(journal.content)\"\n"
        }
        return summary
    }

    // MARK: - AI Prompt

    /// Build the AI prompt for slide generation
    func buildAISlidesPrompt(dataSummary: String) -> String {
        """
        You are a warm, caring companion who has been with someone throughout their day, witnessing their experiences. You're now gently reflecting back what you noticed - like a supportive friend who truly sees them.

        \(dataSummary)

        YOUR VOICE & TONE:
        - Speak as "I" - you are an active witness ("I noticed...", "I saw that...", "I see...")
        - Be warm, validating, and gently supportive - NOT clinical or analytical
        - Acknowledge difficulty with phrases like "that's real", "that makes sense", "I see it"
        - Focus on witnessing and understanding, not instructing or advising
        - Use everyday language, not clinical terminology
        - Show you understand the weight of what they're carrying
        - End with reassurance like "I'm tracking this for you" or "That's real and it makes sense"

        TITLE STYLE:
        - Short, warm titles (2-4 words)
        - Examples: "Time Pressure & Overwhelm", "Family & Emotional Weight", "Sensory Seeking & Regulation", "Emotional Load & Focus"
        - NOT clinical titles like "Executive Dysfunction" or "Sensory Processing Issues"

        MESSAGE STYLE EXAMPLES:
        GOOD (warm, witnessing):
        - "I noticed you've been feeling pressure about past missed stops and upcoming family visits. Time felt heavy today. That's real and it makes sense."
        - "The call with your mother brought up a lot. Family conversations can reactivate old feelings. I'm tracking this pattern for you."
        - "You've been adjusting your glasses a lot today - seeking that just-right feeling. This often connects to anxiety underneath. I see it."
        - "Family stress is taking up mental space. It's hard to focus on other things when emotions are this present. That's normal."

        BAD (clinical, instructing):
        - "Concerns about past 'missed stops' trigger feelings of pressure" (too clinical)
        - "Monitor communication triggers" (instructing)
        - "Address time perception distortions directly" (advising)
        - "Explore grounding techniques" (prescriptive)

        WHAT TO NOTICE:
        - Be specific about WHAT happened (not abstract categories)
        - Validate the difficulty - "that's hard", "that's a lot", "that makes sense"
        - Show you see the connection - "this often connects to...", "when X happens, Y makes sense"
        - End warmly - "I'm tracking this", "I see it", "That's real"

        Generate 3-4 warm, supportive observations. Each message should be 120-200 characters.
        Return ONLY valid JSON array:
        [{"icon": "SF Symbol", "colorName": "gray/blue/purple/orange/green/cyan", "title": "Short gentle title (2-4 words)", "message": "Warm observation that acknowledges what happened, validates it, and reassures"}]

        Icons: heart.fill, hand.raised.fill, sparkles, leaf.fill, sun.max.fill, moon.fill, cloud.fill, brain.head.profile, figure.mind.and.body, eyes, ear.fill, bolt.heart.fill, arrow.up.heart.fill, hands.sparkles.fill
        """
    }

    // MARK: - Response Parsing

    /// Parse AI response JSON into DaySummarySlides
    func parseAISlidesResponse(_ response: String) -> [DaySummarySlide] {
        guard let jsonStart = response.firstIndex(of: "["),
              let jsonEnd = response.lastIndex(of: "]") else {
            return []
        }

        let jsonString = String(response[jsonStart...jsonEnd])

        guard let jsonData = jsonString.data(using: .utf8),
              let aiSlides = try? JSONDecoder().decode([AIGeneratedSlide].self, from: jsonData) else {
            return []
        }

        return aiSlides.map { slide in
            DaySummarySlide(
                icon: slide.icon,
                color: Color.fromName(slide.colorName),
                title: slide.title,
                detail: slide.message
            )
        }
    }

    // MARK: - Life Goals Context

    private func buildLifeGoalsContext() -> String {
        var lines: [String] = []

        let goals = GoalRepository.shared.fetch(includeCompleted: false)
        let struggles = StruggleRepository.shared.fetch(activeOnly: true)
        let wishlistItems = WishlistRepository.shared.fetch(includeAcquired: false)

        if !goals.isEmpty {
            let overdueGoals = goals.filter { $0.isOverdue }
            let dueSoonGoals = goals.filter { $0.isDueSoon }
            let pinnedGoals = goals.filter { $0.isPinned }

            lines.append("Active goals: \(goals.count)")
            if !overdueGoals.isEmpty {
                lines.append("- \(overdueGoals.count) overdue: \(overdueGoals.prefix(2).map { $0.title }.joined(separator: ", "))")
            }
            if !dueSoonGoals.isEmpty {
                lines.append("- \(dueSoonGoals.count) due soon: \(dueSoonGoals.prefix(2).map { $0.title }.joined(separator: ", "))")
            }
            if !pinnedGoals.isEmpty {
                lines.append("- Priority/pinned: \(pinnedGoals.prefix(3).map { $0.title }.joined(separator: ", "))")
            }
        }

        if !struggles.isEmpty {
            let severeStruggles = struggles.filter { $0.intensityLevel.rawValue >= Struggle.Intensity.severe.rawValue }

            lines.append("\nOngoing struggles: \(struggles.count)")
            if !severeStruggles.isEmpty {
                lines.append("- Severe/overwhelming: \(severeStruggles.prefix(2).map { "\($0.title) (\($0.intensityLevel.displayName))" }.joined(separator: ", "))")
            }
            let topStruggles = struggles.sorted { $0.intensity > $1.intensity }.prefix(3)
            for struggle in topStruggles {
                var line = "- \(struggle.title) [\(struggle.intensityLevel.displayName)]"
                if !struggle.triggersList.isEmpty {
                    line += " triggers: \(struggle.triggersList.prefix(2).joined(separator: ", "))"
                }
                lines.append(line)
            }
        }

        if !wishlistItems.isEmpty {
            let highPriority = wishlistItems.filter { $0.priorityLevel == .high }
            lines.append("\nWishlist items: \(wishlistItems.count)")
            if !highPriority.isEmpty {
                lines.append("- High priority wishes: \(highPriority.prefix(2).map { $0.title }.joined(separator: ", "))")
            }
        }

        return lines.joined(separator: "\n")
    }
}

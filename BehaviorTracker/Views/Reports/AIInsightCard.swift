import SwiftUI

// MARK: - AI Insight Card Model

struct AIInsightCard: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let bullets: [String]
    let icon: String
    let color: Color

    static func parse(from markdown: String) -> [AIInsightCard] {
        var cards: [AIInsightCard] = []
        let lines = markdown.components(separatedBy: "\n")
        var currentTitle = ""
        var currentContent: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("###") || trimmed.hasPrefix("##") || trimmed.hasPrefix("#") {
                if !currentTitle.isEmpty && !currentContent.isEmpty {
                    cards.append(createCard(title: currentTitle, lines: currentContent))
                }
                currentTitle = trimmed
                    .replacingOccurrences(of: "###", with: "")
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentContent = []
            } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && !trimmed.contains(":") {
                if !currentTitle.isEmpty && !currentContent.isEmpty {
                    cards.append(createCard(title: currentTitle, lines: currentContent))
                }
                currentTitle = trimmed.replacingOccurrences(of: "**", with: "")
                currentContent = []
            } else if !trimmed.isEmpty && trimmed != "---" {
                currentContent.append(line)
            }
        }

        if !currentTitle.isEmpty && !currentContent.isEmpty {
            cards.append(createCard(title: currentTitle, lines: currentContent))
        }

        if cards.isEmpty && !markdown.isEmpty {
            cards.append(AIInsightCard(
                title: "Insights",
                content: cleanMarkdownText(markdown),
                bullets: [],
                icon: "sparkles",
                color: .purple
            ))
        }

        return cards
    }

    private static func createCard(title: String, lines: [String]) -> AIInsightCard {
        let lowercased = title.lowercased()
        let icon: String
        let color: Color

        if lowercased.contains("pattern") {
            icon = "waveform.path.ecg"
            color = .blue
        } else if lowercased.contains("trigger") {
            icon = "bolt.fill"
            color = .orange
        } else if lowercased.contains("help") || lowercased.contains("positive") || lowercased.contains("working") {
            icon = "hand.thumbsup.fill"
            color = .green
        } else if lowercased.contains("suggest") || lowercased.contains("recommend") || lowercased.contains("tip") {
            icon = "lightbulb.fill"
            color = .yellow
        } else if lowercased.contains("warning") || lowercased.contains("concern") {
            icon = "exclamationmark.triangle.fill"
            color = .red
        } else {
            icon = "sparkles"
            color = .purple
        }

        var bullets: [String] = []
        var paragraphs: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                let bulletText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                bullets.append(cleanMarkdownText(bulletText))
            } else if let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                // Handle numbered lists (1. 2. 3. etc)
                let bulletText = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                bullets.append(cleanMarkdownText(bulletText))
            } else if !trimmed.isEmpty {
                paragraphs.append(cleanMarkdownText(trimmed))
            }
        }

        return AIInsightCard(
            title: title,
            content: paragraphs.joined(separator: " "),
            bullets: bullets,
            icon: icon,
            color: color
        )
    }

    static func cleanMarkdownText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var fullText: String {
        var text = title + "\n\n"
        if !content.isEmpty {
            text += content + "\n\n"
        }
        for bullet in bullets {
            text += "• " + bullet + "\n"
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

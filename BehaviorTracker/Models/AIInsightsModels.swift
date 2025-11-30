import SwiftUI

// MARK: - Supporting Types

struct InsightSection {
    let title: String
    let bullets: [String]
    let paragraph: String

    var icon: String {
        let lowercased = title.lowercased()
        if lowercased.contains("pattern") || lowercased.contains("trend") {
            return "chart.line.uptrend.xyaxis"
        } else if lowercased.contains("recommend") || lowercased.contains("suggest") || lowercased.contains("advice") {
            return "lightbulb.fill"
        } else if lowercased.contains("mood") || lowercased.contains("emotion") {
            return "heart.fill"
        } else if lowercased.contains("sleep") {
            return "moon.fill"
        } else if lowercased.contains("medication") || lowercased.contains("medicine") {
            return "pills.fill"
        } else if lowercased.contains("correlation") || lowercased.contains("connection") {
            return "link"
        } else if lowercased.contains("summary") || lowercased.contains("overview") {
            return "doc.text"
        } else if lowercased.contains("warning") || lowercased.contains("concern") {
            return "exclamationmark.triangle.fill"
        } else {
            return "sparkle"
        }
    }

    var color: Color {
        let lowercased = title.lowercased()
        if lowercased.contains("pattern") || lowercased.contains("trend") {
            return .blue
        } else if lowercased.contains("recommend") || lowercased.contains("suggest") {
            return .yellow
        } else if lowercased.contains("mood") || lowercased.contains("emotion") {
            return .pink
        } else if lowercased.contains("sleep") {
            return .indigo
        } else if lowercased.contains("medication") {
            return .purple
        } else if lowercased.contains("correlation") {
            return .cyan
        } else if lowercased.contains("warning") || lowercased.contains("concern") {
            return .orange
        } else {
            return .green
        }
    }
}

struct SummaryInsights {
    let keyPatterns: String
    let topRecommendation: String
}

// MARK: - Flying Tile Animation Info

struct FlyingTileInfo: Equatable {
    let title: String
    let content: String
    let icon: String
    let color: Color
    let startFrame: CGRect

    static func == (lhs: FlyingTileInfo, rhs: FlyingTileInfo) -> Bool {
        lhs.title == rhs.title && lhs.startFrame == rhs.startFrame
    }
}

// MARK: - Markdown Parser

enum MarkdownParser {
    static func parseMarkdownSections(_ content: String) -> [InsightSection] {
        var sections: [InsightSection] = []
        let lines = content.components(separatedBy: "\n")

        var currentTitle = ""
        var currentBullets: [String] = []
        var currentParagraph = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("##") || trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
                    sections.append(InsightSection(
                        title: currentTitle,
                        bullets: currentBullets,
                        paragraph: currentParagraph
                    ))
                }

                currentTitle = trimmed
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentBullets = []
                currentParagraph = ""

            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    currentBullets.append(bullet)
                }
            } else if !trimmed.isEmpty {
                let cleanedLine = trimmed.replacingOccurrences(of: "**", with: "")
                if currentParagraph.isEmpty {
                    currentParagraph = cleanedLine
                } else {
                    currentParagraph += " " + cleanedLine
                }
            }
        }

        if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
            sections.append(InsightSection(
                title: currentTitle,
                bullets: currentBullets,
                paragraph: currentParagraph.replacingOccurrences(of: "**", with: "")
            ))
        }

        return sections
    }
}

import XCTest
import SwiftUI
@testable import BehaviorTracker

final class AIInsightsModelsTests: XCTestCase {

    // MARK: - InsightSection Icon Tests

    func testInsightSectionIconForPatterns() {
        let section = InsightSection(title: "Pattern Analysis", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "chart.line.uptrend.xyaxis")
    }

    func testInsightSectionIconForTrends() {
        let section = InsightSection(title: "Key Trends", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "chart.line.uptrend.xyaxis")
    }

    func testInsightSectionIconForRecommendations() {
        let section = InsightSection(title: "Recommendations", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "lightbulb.fill")
    }

    func testInsightSectionIconForSuggestions() {
        let section = InsightSection(title: "Suggested Actions", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "lightbulb.fill")
    }

    func testInsightSectionIconForMood() {
        let section = InsightSection(title: "Mood Overview", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "heart.fill")
    }

    func testInsightSectionIconForSleep() {
        let section = InsightSection(title: "Sleep Patterns", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "moon.fill")
    }

    func testInsightSectionIconForMedication() {
        let section = InsightSection(title: "Medication Effects", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "pills.fill")
    }

    func testInsightSectionIconForCorrelation() {
        let section = InsightSection(title: "Correlation Found", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "link")
    }

    func testInsightSectionIconForSummary() {
        let section = InsightSection(title: "Summary", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "doc.text")
    }

    func testInsightSectionIconForWarning() {
        let section = InsightSection(title: "Warning Signs", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "exclamationmark.triangle.fill")
    }

    func testInsightSectionIconDefault() {
        let section = InsightSection(title: "Other Info", bullets: [], paragraph: "")
        XCTAssertEqual(section.icon, "sparkle")
    }

    // MARK: - InsightSection Color Tests

    func testInsightSectionColorForPatterns() {
        let section = InsightSection(title: "Pattern Analysis", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .blue)
    }

    func testInsightSectionColorForRecommendations() {
        let section = InsightSection(title: "Recommendations", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .yellow)
    }

    func testInsightSectionColorForMood() {
        let section = InsightSection(title: "Mood Overview", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .pink)
    }

    func testInsightSectionColorForSleep() {
        let section = InsightSection(title: "Sleep Patterns", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .indigo)
    }

    func testInsightSectionColorForMedication() {
        let section = InsightSection(title: "Medication Effects", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .purple)
    }

    func testInsightSectionColorForCorrelation() {
        let section = InsightSection(title: "Correlation Found", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .cyan)
    }

    func testInsightSectionColorForWarning() {
        let section = InsightSection(title: "Warning Signs", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .orange)
    }

    func testInsightSectionColorDefault() {
        let section = InsightSection(title: "Other Info", bullets: [], paragraph: "")
        XCTAssertEqual(section.color, .green)
    }

    // MARK: - MarkdownParser Tests

    func testParseMarkdownSectionsBasic() {
        let markdown = """
        ## Section One
        - Bullet one
        - Bullet two

        ## Section Two
        Some paragraph text here.
        """

        let sections = MarkdownParser.parseMarkdownSections(markdown)

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].title, "Section One")
        XCTAssertEqual(sections[0].bullets.count, 2)
        XCTAssertEqual(sections[1].title, "Section Two")
        XCTAssertFalse(sections[1].paragraph.isEmpty)
    }

    func testParseMarkdownSectionsWithBoldHeaders() {
        let markdown = """
        **Bold Header**
        - Item one
        - Item two
        """

        let sections = MarkdownParser.parseMarkdownSections(markdown)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title, "Bold Header")
        XCTAssertEqual(sections[0].bullets.count, 2)
    }

    func testParseMarkdownSectionsCleansBoldMarkers() {
        let markdown = """
        ## Test Section
        - **Bold bullet** text
        - Regular bullet
        """

        let sections = MarkdownParser.parseMarkdownSections(markdown)

        XCTAssertEqual(sections[0].bullets[0], "Bold bullet text")
    }

    func testParseMarkdownSectionsDifferentBulletStyles() {
        let markdown = """
        ## Bullets
        - Dash bullet
        * Asterisk bullet
        • Dot bullet
        """

        let sections = MarkdownParser.parseMarkdownSections(markdown)

        XCTAssertEqual(sections[0].bullets.count, 3)
    }

    func testParseMarkdownSectionsEmptyContent() {
        let markdown = ""
        let sections = MarkdownParser.parseMarkdownSections(markdown)

        XCTAssertTrue(sections.isEmpty)
    }

    func testParseMarkdownSectionsNoBullets() {
        let markdown = """
        ## Overview
        This is just a paragraph without any bullets.
        It continues on multiple lines.
        """

        let sections = MarkdownParser.parseMarkdownSections(markdown)

        XCTAssertEqual(sections.count, 1)
        XCTAssertTrue(sections[0].bullets.isEmpty)
        XCTAssertFalse(sections[0].paragraph.isEmpty)
    }

    // MARK: - SummaryInsights Tests

    func testSummaryInsightsInitialization() {
        let summary = SummaryInsights(
            keyPatterns: "You tend to have sensory overload in the afternoon",
            topRecommendation: "Try taking breaks every 2 hours"
        )

        XCTAssertEqual(summary.keyPatterns, "You tend to have sensory overload in the afternoon")
        XCTAssertEqual(summary.topRecommendation, "Try taking breaks every 2 hours")
    }

    // MARK: - FlyingTileInfo Tests

    func testFlyingTileInfoEquality() {
        let frame1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let frame2 = CGRect(x: 50, y: 50, width: 100, height: 100)

        let info1 = FlyingTileInfo(title: "Test", content: "Content", icon: "star", color: .blue, startFrame: frame1)
        let info2 = FlyingTileInfo(title: "Test", content: "Different", icon: "moon", color: .red, startFrame: frame1)
        let info3 = FlyingTileInfo(title: "Test", content: "Content", icon: "star", color: .blue, startFrame: frame2)
        let info4 = FlyingTileInfo(title: "Different", content: "Content", icon: "star", color: .blue, startFrame: frame1)

        // Same title and frame should be equal
        XCTAssertEqual(info1, info2)

        // Different frame should not be equal
        XCTAssertNotEqual(info1, info3)

        // Different title should not be equal
        XCTAssertNotEqual(info1, info4)
    }
}

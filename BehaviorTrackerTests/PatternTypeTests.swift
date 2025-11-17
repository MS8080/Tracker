import XCTest
@testable import BehaviorTracker

final class PatternTypeTests: XCTestCase {

    func testPatternTypeCategories() throws {
        XCTAssertEqual(PatternType.sensoryOverload.category, .sensory)
        XCTAssertEqual(PatternType.hyperfocusEpisode.category, .behavioral)
        XCTAssertEqual(PatternType.socialInteraction.category, .socialCommunication)
        XCTAssertEqual(PatternType.decisionFatigue.category, .executiveFunction)
        XCTAssertEqual(PatternType.energyLevel.category, .energyCapacity)
        XCTAssertEqual(PatternType.meltdownTrigger.category, .emotionalRegulation)
        XCTAssertEqual(PatternType.routineAdherence.category, .routineStructure)
        XCTAssertEqual(PatternType.movementNeeds.category, .physical)
        XCTAssertEqual(PatternType.academicWorkPerformance.category, .contextual)
    }

    func testIntensityScale() throws {
        XCTAssertTrue(PatternType.energyLevel.hasIntensityScale)
        XCTAssertTrue(PatternType.socialInteraction.hasIntensityScale)
        XCTAssertTrue(PatternType.anxietySpike.hasIntensityScale)

        XCTAssertFalse(PatternType.hyperfocusEpisode.hasIntensityScale)
        XCTAssertFalse(PatternType.sensoryOverload.hasIntensityScale)
    }

    func testDuration() throws {
        XCTAssertTrue(PatternType.hyperfocusEpisode.hasDuration)
        XCTAssertTrue(PatternType.socialInteraction.hasDuration)
        XCTAssertTrue(PatternType.meltdownTrigger.hasDuration)

        XCTAssertFalse(PatternType.energyLevel.hasDuration)
        XCTAssertFalse(PatternType.decisionFatigue.hasDuration)
    }

    func testAllCategoriesHavePatterns() throws {
        for category in PatternCategory.allCases {
            let patternsInCategory = PatternType.allCases.filter { $0.category == category }
            XCTAssertFalse(patternsInCategory.isEmpty, "Category \(category.rawValue) has no patterns")
        }
    }
}

import XCTest
@testable import BehaviorTracker

final class PatternTypeTests: XCTestCase {

    func testPatternTypeCategories() throws {
        XCTAssertEqual(PatternType.sensoryOverload.category, .sensory)
        XCTAssertEqual(PatternType.hyperfocus.category, .executiveFunction)
        XCTAssertEqual(PatternType.socialInteraction.category, .social)
        XCTAssertEqual(PatternType.decisionFatigue.category, .executiveFunction)
        XCTAssertEqual(PatternType.energyLevel.category, .energyRegulation)
        XCTAssertEqual(PatternType.meltdown.category, .energyRegulation)
        XCTAssertEqual(PatternType.routineDisruption.category, .routineChange)
        XCTAssertEqual(PatternType.sleepQuality.category, .physicalWellbeing)
        XCTAssertEqual(PatternType.taskAvoidance.category, .demandAvoidance)
    }

    func testIntensityScale() throws {
        XCTAssertTrue(PatternType.energyLevel.hasIntensityScale)
        XCTAssertTrue(PatternType.socialInteraction.hasIntensityScale)
        XCTAssertTrue(PatternType.emotionalOverwhelm.hasIntensityScale)

        XCTAssertFalse(PatternType.hyperfocus.hasIntensityScale)
        XCTAssertFalse(PatternType.taskInitiation.hasIntensityScale)
    }

    func testDuration() throws {
        XCTAssertTrue(PatternType.hyperfocus.hasDuration)
        XCTAssertTrue(PatternType.socialInteraction.hasDuration)
        XCTAssertTrue(PatternType.meltdown.hasDuration)

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

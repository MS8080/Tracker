import XCTest
import SwiftUI
@testable import BehaviorTracker

final class FeelingFinderModelsTests: XCTestCase {

    // MARK: - GeneralFeeling Tests

    func testGeneralFeelingAllCases() {
        XCTAssertEqual(GeneralFeeling.allCases.count, 7)
    }

    func testGeneralFeelingIcons() {
        XCTAssertEqual(GeneralFeeling.irritated.icon, "flame")
        XCTAssertEqual(GeneralFeeling.sad.icon, "cloud.rain")
        XCTAssertEqual(GeneralFeeling.anxious.icon, "bolt.heart")
        XCTAssertEqual(GeneralFeeling.overwhelmed.icon, "tornado")
        XCTAssertEqual(GeneralFeeling.empty.icon, "circle.dashed")
        XCTAssertEqual(GeneralFeeling.mixed.icon, "arrow.triangle.2.circlepath")
        XCTAssertEqual(GeneralFeeling.other.icon, "questionmark")
    }

    func testGeneralFeelingColors() {
        XCTAssertEqual(GeneralFeeling.irritated.color, .red)
        XCTAssertEqual(GeneralFeeling.sad.color, .blue)
        XCTAssertEqual(GeneralFeeling.anxious.color, .orange)
        XCTAssertEqual(GeneralFeeling.overwhelmed.color, .purple)
        XCTAssertEqual(GeneralFeeling.empty.color, .gray)
        XCTAssertEqual(GeneralFeeling.mixed.color, .cyan)
    }

    func testGeneralFeelingRawValues() {
        XCTAssertEqual(GeneralFeeling.irritated.rawValue, "Irritated / Agitated")
        XCTAssertEqual(GeneralFeeling.sad.rawValue, "Sad / Down")
        XCTAssertEqual(GeneralFeeling.anxious.rawValue, "Anxious / On edge")
        XCTAssertEqual(GeneralFeeling.overwhelmed.rawValue, "Overwhelmed / Too much")
        XCTAssertEqual(GeneralFeeling.empty.rawValue, "Empty / Numb")
        XCTAssertEqual(GeneralFeeling.mixed.rawValue, "Mixed / Confused")
        XCTAssertEqual(GeneralFeeling.other.rawValue, "Something else I can't name")
    }

    func testGeneralFeelingIdentifiable() {
        let feeling = GeneralFeeling.anxious
        XCTAssertEqual(feeling.id, feeling.rawValue)
    }

    // MARK: - GuidedFactor Tests

    func testGuidedFactorAllCases() {
        XCTAssertEqual(GuidedFactor.allCases.count, 6)
    }

    func testGuidedFactorIcons() {
        XCTAssertEqual(GuidedFactor.environment.icon, "building.2")
        XCTAssertEqual(GuidedFactor.event.icon, "calendar.badge.exclamationmark")
        XCTAssertEqual(GuidedFactor.health.icon, "heart.text.square")
        XCTAssertEqual(GuidedFactor.social.icon, "person.2")
        XCTAssertEqual(GuidedFactor.demands.icon, "checklist")
        XCTAssertEqual(GuidedFactor.notSure.icon, "questionmark.circle")
    }

    func testGuidedFactorColors() {
        XCTAssertEqual(GuidedFactor.environment.color, .cyan)
        XCTAssertEqual(GuidedFactor.event.color, .orange)
        XCTAssertEqual(GuidedFactor.health.color, .green)
        XCTAssertEqual(GuidedFactor.social.color, .purple)
        XCTAssertEqual(GuidedFactor.demands.color, .red)
        XCTAssertEqual(GuidedFactor.notSure.color, .gray)
    }

    func testGuidedFactorRelatedCategories() {
        XCTAssertEqual(GuidedFactor.environment.relatedCategories, [.sensory])
        XCTAssertEqual(GuidedFactor.event.relatedCategories, [.routineChange, .energyRegulation])
        XCTAssertEqual(GuidedFactor.health.relatedCategories, [.physicalWellbeing, .energyRegulation])
        XCTAssertEqual(GuidedFactor.social.relatedCategories, [.social])
        XCTAssertEqual(GuidedFactor.demands.relatedCategories, [.demandAvoidance, .executiveFunction])
        XCTAssertTrue(GuidedFactor.notSure.relatedCategories.isEmpty)
    }

    func testGuidedFactorIdentifiable() {
        let factor = GuidedFactor.environment
        XCTAssertEqual(factor.id, factor.rawValue)
    }

    // MARK: - DetailOptions Tests

    func testDetailOptionsEnvironment() {
        XCTAssertFalse(DetailOptions.environment.isEmpty)
        XCTAssertTrue(DetailOptions.environment.contains("Bright or harsh lighting"))
        XCTAssertTrue(DetailOptions.environment.contains("Noise level"))
        XCTAssertTrue(DetailOptions.environment.contains("Temperature uncomfortable"))
    }

    func testDetailOptionsEvent() {
        XCTAssertFalse(DetailOptions.event.isEmpty)
        XCTAssertTrue(DetailOptions.event.contains("Upcoming exam or test"))
        XCTAssertTrue(DetailOptions.event.contains("Job interview"))
        XCTAssertTrue(DetailOptions.event.contains("Something unexpected happened"))
    }

    func testDetailOptionsHealth() {
        XCTAssertFalse(DetailOptions.health.isEmpty)
        XCTAssertTrue(DetailOptions.health.contains("Heart racing or pounding"))
        XCTAssertTrue(DetailOptions.health.contains("Fatigue or heaviness"))
        XCTAssertTrue(DetailOptions.health.contains("Haven't eaten or slept well"))
    }

    func testDetailOptionsSocial() {
        XCTAssertFalse(DetailOptions.social.isEmpty)
        XCTAssertTrue(DetailOptions.social.contains("Recent difficult conversation"))
        XCTAssertTrue(DetailOptions.social.contains("Had to mask or pretend"))
        XCTAssertTrue(DetailOptions.social.contains("Rejection or criticism"))
    }

    func testDetailOptionsDemands() {
        XCTAssertFalse(DetailOptions.demands.isEmpty)
        XCTAssertTrue(DetailOptions.demands.contains("Task I keep avoiding"))
        XCTAssertTrue(DetailOptions.demands.contains("Too many things to do"))
        XCTAssertTrue(DetailOptions.demands.contains("Responsibility I don't want"))
    }

    // MARK: - FeelingFinderData Tests

    func testFeelingFinderDataDefaultValues() {
        let data = FeelingFinderData()

        XCTAssertNil(data.generalFeeling)
        XCTAssertTrue(data.selectedFactors.isEmpty)
        XCTAssertTrue(data.environmentDetails.isEmpty)
        XCTAssertTrue(data.eventDetails.isEmpty)
        XCTAssertTrue(data.healthDetails.isEmpty)
        XCTAssertTrue(data.socialDetails.isEmpty)
        XCTAssertTrue(data.demandDetails.isEmpty)
        XCTAssertEqual(data.additionalText, "")
        XCTAssertEqual(data.generatedEntry, "")
    }

    func testFeelingFinderDataMutability() {
        var data = FeelingFinderData()

        data.generalFeeling = .anxious
        data.selectedFactors.insert(.health)
        data.selectedFactors.insert(.demands)
        data.healthDetails.insert("Heart racing or pounding")
        data.demandDetails.insert("Too many things to do")
        data.additionalText = "Feeling overwhelmed today"
        data.generatedEntry = "I am feeling anxious..."

        XCTAssertEqual(data.generalFeeling, .anxious)
        XCTAssertEqual(data.selectedFactors.count, 2)
        XCTAssertTrue(data.selectedFactors.contains(.health))
        XCTAssertTrue(data.selectedFactors.contains(.demands))
        XCTAssertEqual(data.healthDetails.count, 1)
        XCTAssertEqual(data.demandDetails.count, 1)
        XCTAssertEqual(data.additionalText, "Feeling overwhelmed today")
        XCTAssertEqual(data.generatedEntry, "I am feeling anxious...")
    }

    func testFeelingFinderDataSetOperations() {
        var data = FeelingFinderData()

        // Add factors
        data.selectedFactors.insert(.environment)
        data.selectedFactors.insert(.social)
        XCTAssertEqual(data.selectedFactors.count, 2)

        // Remove factor
        data.selectedFactors.remove(.environment)
        XCTAssertEqual(data.selectedFactors.count, 1)
        XCTAssertFalse(data.selectedFactors.contains(.environment))

        // Add details
        data.environmentDetails.insert("Noise level")
        data.environmentDetails.insert("Too many people around")
        XCTAssertEqual(data.environmentDetails.count, 2)

        // Clear all
        data.selectedFactors.removeAll()
        XCTAssertTrue(data.selectedFactors.isEmpty)
    }
}

import XCTest
import CoreData
@testable import BehaviorTracker

final class DataControllerTests: XCTestCase {
    var dataController: DataController!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
    }

    override func tearDownWithError() throws {
        dataController = nil
    }

    func testCreatePatternEntry() throws {
        let entry = dataController.createPatternEntry(
            patternType: .sensoryOverload,
            intensity: 4,
            duration: 30,
            contextNotes: "Test note",
            specificDetails: "Test details"
        )

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry.patternType, PatternType.sensoryOverload.rawValue)
        XCTAssertEqual(entry.intensity, 4)
        XCTAssertEqual(entry.duration, 30)
        XCTAssertEqual(entry.contextNotes, "Test note")
        XCTAssertEqual(entry.specificDetails, "Test details")
    }

    func testFetchPatternEntries() throws {
        _ = dataController.createPatternEntry(patternType: .hyperfocusEpisode)
        _ = dataController.createPatternEntry(patternType: .sensoryOverload)
        _ = dataController.createPatternEntry(patternType: .anxietySpike)

        let entries = dataController.fetchPatternEntries()
        XCTAssertEqual(entries.count, 3)
    }

    func testFetchPatternEntriesByCategory() throws {
        _ = dataController.createPatternEntry(patternType: .hyperfocusEpisode)
        _ = dataController.createPatternEntry(patternType: .sensoryOverload)
        _ = dataController.createPatternEntry(patternType: .anxietySpike)

        let behavioralEntries = dataController.fetchPatternEntries(category: .behavioral)
        XCTAssertEqual(behavioralEntries.count, 1)

        let sensoryEntries = dataController.fetchPatternEntries(category: .sensory)
        XCTAssertEqual(sensoryEntries.count, 1)
    }

    func testDeletePatternEntry() throws {
        let entry = dataController.createPatternEntry(patternType: .energyLevel)

        var entries = dataController.fetchPatternEntries()
        XCTAssertEqual(entries.count, 1)

        dataController.deletePatternEntry(entry)

        entries = dataController.fetchPatternEntries()
        XCTAssertEqual(entries.count, 0)
    }

    func testUserPreferences() throws {
        let preferences = dataController.getUserPreferences()

        XCTAssertNotNil(preferences)
        XCTAssertEqual(preferences.streakCount, 0)
        XCTAssertFalse(preferences.notificationEnabled)

        preferences.streakCount = 5
        preferences.notificationEnabled = true
        dataController.save()

        let updatedPreferences = dataController.getUserPreferences()
        XCTAssertEqual(updatedPreferences.streakCount, 5)
        XCTAssertTrue(updatedPreferences.notificationEnabled)
    }

    func testUpdateStreak() throws {
        dataController.updateStreak()
        let preferences = dataController.getUserPreferences()
        XCTAssertEqual(preferences.streakCount, 1)

        _ = dataController.createPatternEntry(patternType: .energyLevel)
        dataController.updateStreak()

        let updatedPreferences = dataController.getUserPreferences()
        XCTAssertEqual(updatedPreferences.streakCount, 1)
    }
}

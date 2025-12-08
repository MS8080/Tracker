import XCTest
import CoreData
@testable import BehaviorTracker

final class DataControllerTests: XCTestCase {
    var dataController: DataController!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        DataController.shared = dataController
    }

    override func tearDownWithError() throws {
        // Clean up all data
        let context = dataController.container.viewContext
        for entityName in ["PatternEntry", "UserPreferences", "JournalEntry"] {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
        }
        try? context.save()
        dataController = nil
    }

    @MainActor
    func testCreatePatternEntry() async throws {
        let entry = try await dataController.createPatternEntry(
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

    @MainActor
    func testFetchPatternEntries() async throws {
        _ = try await dataController.createPatternEntry(patternType: .hyperfocus)
        _ = try await dataController.createPatternEntry(patternType: .sensoryOverload)
        _ = try await dataController.createPatternEntry(patternType: .emotionalOverwhelm)

        let entries = dataController.fetchPatternEntries()
        XCTAssertEqual(entries.count, 3)
    }

    @MainActor
    func testFetchPatternEntriesByCategory() async throws {
        _ = try await dataController.createPatternEntry(patternType: .hyperfocus) // Executive Function
        _ = try await dataController.createPatternEntry(patternType: .sensoryOverload) // Sensory
        _ = try await dataController.createPatternEntry(patternType: .emotionalOverwhelm) // Energy & Regulation

        let executiveFunctionEntries = dataController.fetchPatternEntries(category: .executiveFunction)
        XCTAssertEqual(executiveFunctionEntries.count, 1)

        let sensoryEntries = dataController.fetchPatternEntries(category: .sensory)
        XCTAssertEqual(sensoryEntries.count, 1)
    }

    @MainActor
    func testDeletePatternEntry() async throws {
        let entry = try await dataController.createPatternEntry(patternType: .energyLevel)

        var entries = dataController.fetchPatternEntries()
        XCTAssertEqual(entries.count, 1)

        dataController.deletePatternEntry(entry)

        entries = dataController.fetchPatternEntries()
        XCTAssertEqual(entries.count, 0)
    }

    @MainActor
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

    @MainActor
    func testUpdateStreak() async throws {
        dataController.updateStreak()
        let preferences = dataController.getUserPreferences()
        XCTAssertEqual(preferences.streakCount, 1)

        _ = try await dataController.createPatternEntry(patternType: .energyLevel)
        dataController.updateStreak()

        let updatedPreferences = dataController.getUserPreferences()
        XCTAssertEqual(updatedPreferences.streakCount, 1)
    }
}

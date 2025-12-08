import XCTest
import CoreData
@testable import BehaviorTracker

final class PatternRepositoryTests: XCTestCase {
    var dataController: DataController!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
    }

    override func tearDownWithError() throws {
        dataController = nil
    }

    // MARK: - Create Tests

    @MainActor
    func testCreatePatternEntry() async throws {
        let entry = try await PatternRepository.shared.create(
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
    func testCreatePatternEntryWithDefaultValues() async throws {
        let entry = try await PatternRepository.shared.create(
            patternType: .hyperfocus
        )

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry.patternType, PatternType.hyperfocus.rawValue)
        XCTAssertEqual(entry.intensity, 0)
        XCTAssertEqual(entry.duration, 0)
        XCTAssertNil(entry.contextNotes)
        XCTAssertNil(entry.specificDetails)
    }

    @MainActor
    func testCreatePatternEntryWithContributingFactors() async throws {
        let factors: [ContributingFactor] = [.poorSleep, .socialDemands, .fatigue]

        let entry = try await PatternRepository.shared.create(
            patternType: .meltdown,
            intensity: 5,
            contributingFactors: factors
        )

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry.patternType, PatternType.meltdown.rawValue)
        XCTAssertEqual(entry.contributingFactors.count, 3)
        XCTAssertTrue(entry.contributingFactors.contains(.poorSleep))
        XCTAssertTrue(entry.contributingFactors.contains(.socialDemands))
        XCTAssertTrue(entry.contributingFactors.contains(.fatigue))
    }

    @MainActor
    func testCreatePatternEntryTrimsWhitespace() async throws {
        let entry = try await PatternRepository.shared.create(
            patternType: .emotionalOverwhelm,
            contextNotes: "   Note with spaces   ",
            specificDetails: "\n\tDetails with whitespace\n"
        )

        XCTAssertEqual(entry.contextNotes, "Note with spaces")
        XCTAssertEqual(entry.specificDetails, "Details with whitespace")
    }

    // MARK: - Validation Tests

    @MainActor
    func testCreatePatternEntryRejectsInvalidIntensity() async {
        do {
            _ = try await PatternRepository.shared.create(
                patternType: .sensoryOverload,
                intensity: 10 // Invalid: max is 5
            )
            XCTFail("Should throw validation error for invalid intensity")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    @MainActor
    func testCreatePatternEntryRejectsNegativeIntensity() async {
        do {
            _ = try await PatternRepository.shared.create(
                patternType: .sensoryOverload,
                intensity: -1
            )
            XCTFail("Should throw validation error for negative intensity")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    @MainActor
    func testCreatePatternEntryRejectsInvalidDuration() async {
        do {
            _ = try await PatternRepository.shared.create(
                patternType: .sensoryOverload,
                duration: 2000 // Invalid: max is 1440 (24 hours in minutes)
            )
            XCTFail("Should throw validation error for invalid duration")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    // MARK: - Fetch Tests

    @MainActor
    func testFetchPatternEntries() async throws {
        _ = try await PatternRepository.shared.create(patternType: .hyperfocus)
        _ = try await PatternRepository.shared.create(patternType: .sensoryOverload)
        _ = try await PatternRepository.shared.create(patternType: .emotionalOverwhelm)

        let entries = await PatternRepository.shared.fetch()
        XCTAssertEqual(entries.count, 3)
    }

    @MainActor
    func testFetchPatternEntriesByCategory() async throws {
        _ = try await PatternRepository.shared.create(patternType: .hyperfocus) // Executive Function
        _ = try await PatternRepository.shared.create(patternType: .sensoryOverload) // Sensory
        _ = try await PatternRepository.shared.create(patternType: .emotionalOverwhelm) // Energy & Regulation

        let sensoryEntries = await PatternRepository.shared.fetch(category: .sensory)
        XCTAssertEqual(sensoryEntries.count, 1)
        XCTAssertEqual(sensoryEntries.first?.patternType, PatternType.sensoryOverload.rawValue)
    }

    @MainActor
    func testFetchPatternEntriesWithDateRange() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        _ = try await PatternRepository.shared.create(patternType: .hyperfocus)
        _ = try await PatternRepository.shared.create(patternType: .sensoryOverload)

        let entries = await PatternRepository.shared.fetch(startDate: yesterday, endDate: tomorrow)
        XCTAssertEqual(entries.count, 2)
    }

    @MainActor
    func testFetchPatternEntriesWithLimit() async throws {
        _ = try await PatternRepository.shared.create(patternType: .hyperfocus)
        _ = try await PatternRepository.shared.create(patternType: .sensoryOverload)
        _ = try await PatternRepository.shared.create(patternType: .emotionalOverwhelm)
        _ = try await PatternRepository.shared.create(patternType: .energyLevel)
        _ = try await PatternRepository.shared.create(patternType: .meltdown)

        let entries = await PatternRepository.shared.fetch(limit: 3)
        XCTAssertEqual(entries.count, 3)
    }

    @MainActor
    func testFetchPatternEntriesReturnsDescendingOrder() async throws {
        let entry1 = try await PatternRepository.shared.create(patternType: .hyperfocus)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        let entry2 = try await PatternRepository.shared.create(patternType: .sensoryOverload)

        let entries = await PatternRepository.shared.fetch()

        XCTAssertEqual(entries.count, 2)
        // Most recent should be first
        XCTAssertEqual(entries.first?.id, entry2.id)
        XCTAssertEqual(entries.last?.id, entry1.id)
    }

    @MainActor
    func testFetchSyncReturnsEntries() async throws {
        _ = try await PatternRepository.shared.create(patternType: .hyperfocus)
        _ = try await PatternRepository.shared.create(patternType: .sensoryOverload)

        let entries = PatternRepository.shared.fetchSync()
        XCTAssertEqual(entries.count, 2)
    }

    @MainActor
    func testFetchOrThrowReturnsEntries() async throws {
        _ = try await PatternRepository.shared.create(patternType: .hyperfocus)

        let entries = try PatternRepository.shared.fetchOrThrow()
        XCTAssertEqual(entries.count, 1)
    }

    // MARK: - Delete Tests

    @MainActor
    func testDeletePatternEntry() async throws {
        let entry = try await PatternRepository.shared.create(patternType: .energyLevel)

        var entries = await PatternRepository.shared.fetch()
        XCTAssertEqual(entries.count, 1)

        PatternRepository.shared.delete(entry)

        entries = await PatternRepository.shared.fetch()
        XCTAssertEqual(entries.count, 0)
    }

    @MainActor
    func testDeleteSpecificEntry() async throws {
        let entry1 = try await PatternRepository.shared.create(patternType: .hyperfocus)
        let entry2 = try await PatternRepository.shared.create(patternType: .sensoryOverload)
        let entry3 = try await PatternRepository.shared.create(patternType: .emotionalOverwhelm)

        PatternRepository.shared.delete(entry2)

        let entries = await PatternRepository.shared.fetch()
        XCTAssertEqual(entries.count, 2)

        let patternTypes = entries.map { $0.patternType }
        XCTAssertTrue(patternTypes.contains(PatternType.hyperfocus.rawValue))
        XCTAssertTrue(patternTypes.contains(PatternType.emotionalOverwhelm.rawValue))
        XCTAssertFalse(patternTypes.contains(PatternType.sensoryOverload.rawValue))
    }

    // MARK: - Edge Cases

    @MainActor
    func testFetchWithNoEntries() async {
        let entries = await PatternRepository.shared.fetch()
        XCTAssertTrue(entries.isEmpty)
    }

    @MainActor
    func testFetchWithFutureDateRangeReturnsEmpty() async throws {
        _ = try await PatternRepository.shared.create(patternType: .hyperfocus)

        let futureStart = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let futureEnd = Calendar.current.date(byAdding: .day, value: 2, to: Date())!

        let entries = await PatternRepository.shared.fetch(startDate: futureStart, endDate: futureEnd)
        XCTAssertTrue(entries.isEmpty)
    }

    @MainActor
    func testFetchWithPastDateRangeReturnsEmpty() async throws {
        _ = try await PatternRepository.shared.create(patternType: .hyperfocus)

        let pastStart = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let pastEnd = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

        let entries = await PatternRepository.shared.fetch(startDate: pastStart, endDate: pastEnd)
        XCTAssertTrue(entries.isEmpty)
    }
}

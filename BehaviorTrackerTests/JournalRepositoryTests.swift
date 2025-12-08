import XCTest
import CoreData
@testable import BehaviorTracker

final class JournalRepositoryTests: XCTestCase {
    var dataController: DataController!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        DataController.shared = dataController
    }

    override func tearDownWithError() throws {
        // Clean up all data
        let context = dataController.container.viewContext
        for entityName in ["JournalEntry", "ExtractedPattern", "PatternCascade"] {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
        }
        try? context.save()
        dataController = nil
    }

    // MARK: - Create Tests

    @MainActor
    func testCreateJournalEntry() throws {
        let entry = try JournalRepository.shared.create(
            title: "Test Title",
            content: "Test content for journal entry",
            mood: 4
        )

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry.title, "Test Title")
        XCTAssertEqual(entry.content, "Test content for journal entry")
        XCTAssertEqual(entry.mood, 4)
        XCTAssertFalse(entry.isFavorite)
        XCTAssertFalse(entry.isAnalyzed)
    }

    @MainActor
    func testCreateJournalEntryWithoutTitle() throws {
        let entry = try JournalRepository.shared.create(
            content: "Content without title"
        )

        XCTAssertNotNil(entry)
        XCTAssertNil(entry.title)
        XCTAssertEqual(entry.content, "Content without title")
    }

    @MainActor
    func testCreateJournalEntryTrimsWhitespace() throws {
        let entry = try JournalRepository.shared.create(
            title: "   Padded Title   ",
            content: "\n\tContent with whitespace\n"
        )

        XCTAssertEqual(entry.title, "Padded Title")
        XCTAssertEqual(entry.content, "Content with whitespace")
    }

    @MainActor
    func testCreateJournalEntryWithAudioFileName() throws {
        let entry = try JournalRepository.shared.create(
            content: "Voice note entry",
            audioFileName: "recording_123.m4a"
        )

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry.audioFileName, "recording_123.m4a")
    }

    // MARK: - Validation Tests

    @MainActor
    func testCreateJournalEntryRejectsEmptyContent() {
        do {
            _ = try JournalRepository.shared.create(
                content: ""
            )
            XCTFail("Should throw validation error for empty content")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    @MainActor
    func testCreateJournalEntryRejectsWhitespaceOnlyContent() {
        do {
            _ = try JournalRepository.shared.create(
                content: "   \n\t   "
            )
            XCTFail("Should throw validation error for whitespace-only content")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    @MainActor
    func testCreateJournalEntryRejectsInvalidMood() {
        do {
            _ = try JournalRepository.shared.create(
                content: "Test content",
                mood: 10 // Invalid: max is 5
            )
            XCTFail("Should throw validation error for invalid mood")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    @MainActor
    func testCreateJournalEntryRejectsNegativeMood() {
        do {
            _ = try JournalRepository.shared.create(
                content: "Test content",
                mood: -1
            )
            XCTFail("Should throw validation error for negative mood")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    // MARK: - Fetch Tests

    @MainActor
    func testFetchJournalEntries() async throws {
        _ = try JournalRepository.shared.create(content: "Entry 1")
        _ = try JournalRepository.shared.create(content: "Entry 2")
        _ = try JournalRepository.shared.create(content: "Entry 3")

        let entries = await JournalRepository.shared.fetch()
        XCTAssertEqual(entries.count, 3)
    }

    @MainActor
    func testFetchJournalEntriesWithDateRange() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        _ = try JournalRepository.shared.create(content: "Entry 1")
        _ = try JournalRepository.shared.create(content: "Entry 2")

        let entries = await JournalRepository.shared.fetch(startDate: yesterday, endDate: tomorrow)
        XCTAssertEqual(entries.count, 2)
    }

    @MainActor
    func testFetchJournalEntriesFavoritesOnly() async throws {
        let entry1 = try JournalRepository.shared.create(content: "Entry 1")
        _ = try JournalRepository.shared.create(content: "Entry 2")
        let entry3 = try JournalRepository.shared.create(content: "Entry 3")

        // Mark some as favorites
        entry1.isFavorite = true
        entry3.isFavorite = true
        JournalRepository.shared.update(entry1)
        JournalRepository.shared.update(entry3)

        let favorites = await JournalRepository.shared.fetch(favoritesOnly: true)
        XCTAssertEqual(favorites.count, 2)
    }

    @MainActor
    func testFetchJournalEntriesWithLimit() async throws {
        _ = try JournalRepository.shared.create(content: "Entry 1")
        _ = try JournalRepository.shared.create(content: "Entry 2")
        _ = try JournalRepository.shared.create(content: "Entry 3")
        _ = try JournalRepository.shared.create(content: "Entry 4")
        _ = try JournalRepository.shared.create(content: "Entry 5")

        let entries = await JournalRepository.shared.fetch(limit: 3)
        XCTAssertEqual(entries.count, 3)
    }

    @MainActor
    func testFetchJournalEntriesWithOffset() async throws {
        _ = try JournalRepository.shared.create(content: "Entry 1")
        try await Task.sleep(nanoseconds: 50_000_000)
        _ = try JournalRepository.shared.create(content: "Entry 2")
        try await Task.sleep(nanoseconds: 50_000_000)
        _ = try JournalRepository.shared.create(content: "Entry 3")
        try await Task.sleep(nanoseconds: 50_000_000)
        _ = try JournalRepository.shared.create(content: "Entry 4")
        try await Task.sleep(nanoseconds: 50_000_000)
        _ = try JournalRepository.shared.create(content: "Entry 5")

        // Skip first 2 entries (most recent)
        let entries = await JournalRepository.shared.fetch(limit: 2, offset: 2)
        XCTAssertEqual(entries.count, 2)
    }

    @MainActor
    func testFetchReturnsDescendingOrder() async throws {
        let entry1 = try JournalRepository.shared.create(content: "First entry")
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        let entry2 = try JournalRepository.shared.create(content: "Second entry")

        let entries = await JournalRepository.shared.fetch()

        XCTAssertEqual(entries.count, 2)
        // Most recent should be first
        XCTAssertEqual(entries.first?.id, entry2.id)
        XCTAssertEqual(entries.last?.id, entry1.id)
    }

    @MainActor
    func testFetchSync() throws {
        _ = try JournalRepository.shared.create(content: "Entry 1")
        _ = try JournalRepository.shared.create(content: "Entry 2")

        let entries = JournalRepository.shared.fetchSync()
        XCTAssertEqual(entries.count, 2)
    }

    // MARK: - Count Tests

    @MainActor
    func testCountJournalEntries() async throws {
        _ = try JournalRepository.shared.create(content: "Entry 1")
        _ = try JournalRepository.shared.create(content: "Entry 2")
        _ = try JournalRepository.shared.create(content: "Entry 3")

        let count = await JournalRepository.shared.count()
        XCTAssertEqual(count, 3)
    }

    @MainActor
    func testCountFavoritesOnly() async throws {
        let entry1 = try JournalRepository.shared.create(content: "Entry 1")
        _ = try JournalRepository.shared.create(content: "Entry 2")
        let entry3 = try JournalRepository.shared.create(content: "Entry 3")

        entry1.isFavorite = true
        entry3.isFavorite = true
        JournalRepository.shared.update(entry1)
        JournalRepository.shared.update(entry3)

        let count = await JournalRepository.shared.count(favoritesOnly: true)
        XCTAssertEqual(count, 2)
    }

    // MARK: - Search Tests

    @MainActor
    func testSearchByContent() async throws {
        _ = try JournalRepository.shared.create(content: "Had a great day at the park")
        _ = try JournalRepository.shared.create(content: "Feeling anxious about work")
        _ = try JournalRepository.shared.create(content: "Another park visit")

        let results = await JournalRepository.shared.search(query: "park")
        XCTAssertEqual(results.count, 2)
    }

    @MainActor
    func testSearchByTitle() async throws {
        _ = try JournalRepository.shared.create(title: "Morning Thoughts", content: "Just woke up")
        _ = try JournalRepository.shared.create(title: "Evening Reflection", content: "End of day")
        _ = try JournalRepository.shared.create(title: "Morning Walk", content: "Exercise time")

        let results = await JournalRepository.shared.search(query: "Morning")
        XCTAssertEqual(results.count, 2)
    }

    @MainActor
    func testSearchIsCaseInsensitive() async throws {
        _ = try JournalRepository.shared.create(content: "EXCITED about the news")
        _ = try JournalRepository.shared.create(content: "excited to travel")
        _ = try JournalRepository.shared.create(content: "Not related")

        let results = await JournalRepository.shared.search(query: "excited")
        XCTAssertEqual(results.count, 2)
    }

    @MainActor
    func testSearchWithNoResults() async throws {
        _ = try JournalRepository.shared.create(content: "Regular entry")

        let results = await JournalRepository.shared.search(query: "nonexistent")
        XCTAssertTrue(results.isEmpty)
    }

    @MainActor
    func testSearchSync() throws {
        _ = try JournalRepository.shared.create(content: "Searchable content here")

        let results = JournalRepository.shared.searchSync(query: "Searchable")
        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Update Tests

    @MainActor
    func testUpdateJournalEntry() throws {
        let entry = try JournalRepository.shared.create(
            title: "Original Title",
            content: "Original content"
        )

        entry.title = "Updated Title"
        entry.content = "Updated content"
        entry.mood = 5
        JournalRepository.shared.update(entry)

        let entries = JournalRepository.shared.fetchSync()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.title, "Updated Title")
        XCTAssertEqual(entries.first?.content, "Updated content")
        XCTAssertEqual(entries.first?.mood, 5)
    }

    @MainActor
    func testToggleFavorite() throws {
        let entry = try JournalRepository.shared.create(content: "Test entry")
        XCTAssertFalse(entry.isFavorite)

        entry.isFavorite = true
        JournalRepository.shared.update(entry)

        let entries = JournalRepository.shared.fetchSync()
        XCTAssertTrue(entries.first?.isFavorite ?? false)
    }

    // MARK: - Delete Tests

    @MainActor
    func testDeleteJournalEntry() throws {
        let entry = try JournalRepository.shared.create(content: "To be deleted")

        var entries = JournalRepository.shared.fetchSync()
        XCTAssertEqual(entries.count, 1)

        JournalRepository.shared.delete(entry)

        entries = JournalRepository.shared.fetchSync()
        XCTAssertEqual(entries.count, 0)
    }

    @MainActor
    func testDeleteSpecificEntry() throws {
        let entry1 = try JournalRepository.shared.create(content: "Entry 1")
        let entry2 = try JournalRepository.shared.create(content: "Entry 2")
        let entry3 = try JournalRepository.shared.create(content: "Entry 3")

        JournalRepository.shared.delete(entry2)

        let entries = JournalRepository.shared.fetchSync()
        XCTAssertEqual(entries.count, 2)

        let contents = entries.map { $0.content }
        XCTAssertTrue(contents.contains("Entry 1"))
        XCTAssertTrue(contents.contains("Entry 3"))
        XCTAssertFalse(contents.contains("Entry 2"))
    }

    // MARK: - Edge Cases

    @MainActor
    func testFetchWithNoEntries() async {
        let entries = await JournalRepository.shared.fetch()
        XCTAssertTrue(entries.isEmpty)
    }

    @MainActor
    func testCountWithNoEntries() async {
        let count = await JournalRepository.shared.count()
        XCTAssertEqual(count, 0)
    }

    @MainActor
    func testFetchWithFutureDateRangeReturnsEmpty() async throws {
        _ = try JournalRepository.shared.create(content: "Today's entry")

        let futureStart = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let futureEnd = Calendar.current.date(byAdding: .day, value: 2, to: Date())!

        let entries = await JournalRepository.shared.fetch(startDate: futureStart, endDate: futureEnd)
        XCTAssertTrue(entries.isEmpty)
    }
}

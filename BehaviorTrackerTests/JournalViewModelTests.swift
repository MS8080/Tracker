import XCTest
import CoreData
@testable import BehaviorTracker

@MainActor
final class JournalViewModelTests: XCTestCase {
    var dataController: DataController!
    var viewModel: JournalViewModel!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        DataController.shared = dataController
        viewModel = JournalViewModel()
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
        viewModel = nil
    }

    // MARK: - Create Entry Tests

    func testCreateEntry() async throws {
        let success = viewModel.createEntry(
            title: "Test Entry",
            content: "This is test content"
        )
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.journalEntries.count, 1)
        XCTAssertEqual(viewModel.journalEntries.first?.title, "Test Entry")
        XCTAssertEqual(viewModel.journalEntries.first?.content, "This is test content")
    }

    func testCreateEntryWithMood() async throws {
        let success = viewModel.createEntry(
            title: "Mood Entry",
            content: "Feeling good today",
            mood: 4
        )
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.journalEntries.first?.mood, 4)
    }

    func testCreateEntryWithAudioFile() async throws {
        let success = viewModel.createEntry(
            content: "Voice note",
            audioFileName: "recording_001.m4a"
        )
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.journalEntries.first?.audioFileName, "recording_001.m4a")
    }

    // MARK: - Load Entry Tests

    func testLoadJournalEntries() async throws {
        _ = try dataController.createJournalEntry(title: "Entry 1", content: "Content 1")
        _ = try dataController.createJournalEntry(title: "Entry 2", content: "Content 2")
        _ = try dataController.createJournalEntry(title: "Entry 3", content: "Content 3")

        viewModel.loadJournalEntries()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.journalEntries.count, 3)
    }

    func testLoadJournalEntriesFavoritesOnly() async throws {
        _ = try dataController.createJournalEntry(title: "Regular", content: "Content")
        let entry2 = try dataController.createJournalEntry(title: "Favorite", content: "Content")
        entry2.isFavorite = true
        dataController.save()

        viewModel.showFavoritesOnly = true
        // Wait for async load to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.journalEntries.count, 1)
        XCTAssertEqual(viewModel.journalEntries.first?.title, "Favorite")
    }

    // MARK: - Search Tests

    func testSearchEntries() async throws {
        _ = try dataController.createJournalEntry(title: "Morning Routine", content: "Started the day well")
        _ = try dataController.createJournalEntry(title: "Afternoon Slump", content: "Feeling tired")
        _ = try dataController.createJournalEntry(title: "Evening Review", content: "Good evening routine")

        viewModel.searchQuery = "morning"
        // Wait for async load to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // After setting searchQuery, entries should be filtered
        XCTAssertTrue(viewModel.journalEntries.allSatisfy { entry in
            let title = entry.title ?? ""
            let content = entry.content ?? ""
            return title.lowercased().contains("morning") || content.lowercased().contains("morning")
        })
    }

    func testClearSearchQuery() async throws {
        _ = try dataController.createJournalEntry(title: "Entry 1", content: "Content 1")
        _ = try dataController.createJournalEntry(title: "Entry 2", content: "Content 2")

        viewModel.searchQuery = "Entry 1"
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.searchQuery = ""
        try await Task.sleep(nanoseconds: 100_000_000)

        // After clearing, all entries should be loaded
        XCTAssertEqual(viewModel.journalEntries.count, 2)
    }

    // MARK: - Delete Tests

    func testDeleteEntry() async throws {
        let entry = try dataController.createJournalEntry(title: "To Delete", content: "This will be deleted")
        viewModel.loadJournalEntries()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.journalEntries.count, 1)

        viewModel.deleteEntry(entry)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.journalEntries.count, 0)
    }

    // MARK: - Favorite Tests

    func testToggleFavorite() async throws {
        let entry = try dataController.createJournalEntry(title: "Toggle Me", content: "Content")
        viewModel.loadJournalEntries()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(entry.isFavorite)

        viewModel.toggleFavorite(entry)
        viewModel.loadJournalEntries()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(viewModel.journalEntries.first?.isFavorite ?? false)
    }

    // MARK: - Grouped By Date Tests

    func testGetEntriesGroupedByDate() async throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let entry1 = try dataController.createJournalEntry(title: "Today 1", content: "Content")
        entry1.timestamp = today

        let entry2 = try dataController.createJournalEntry(title: "Today 2", content: "Content")
        entry2.timestamp = today

        let entry3 = try dataController.createJournalEntry(title: "Yesterday", content: "Content")
        entry3.timestamp = yesterday

        dataController.save()
        viewModel.loadJournalEntries()
        try await Task.sleep(nanoseconds: 100_000_000)

        let grouped = viewModel.getEntriesGroupedByDate()

        XCTAssertEqual(grouped.keys.count, 2)
    }

    // MARK: - Date Range Tests

    func testGetEntriesByDateRange() async throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let entry1 = try dataController.createJournalEntry(title: "Today", content: "Content")
        entry1.timestamp = today

        let entry2 = try dataController.createJournalEntry(title: "Last Week", content: "Content")
        entry2.timestamp = lastWeek

        dataController.save()

        let entries = await viewModel.getEntriesByDateRange(startDate: yesterday, endDate: today)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.title, "Today")
    }
}

import XCTest
import CoreData
@testable import BehaviorTracker

final class ReportGeneratorTests: XCTestCase {
    var dataController: DataController!
    var reportGenerator: ReportGenerator!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        DataController.shared = dataController
        reportGenerator = ReportGenerator()
    }

    override func tearDownWithError() throws {
        // Clean up all data
        let context = dataController.container.viewContext
        for entityName in ["JournalEntry", "PatternEntry", "ExtractedPattern"] {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
        }
        try? context.save()
        dataController = nil
        reportGenerator = nil
    }

    @MainActor
    func testWeeklyReportGeneration() async throws {
        // Create journal entries (reports count these now)
        _ = try dataController.createJournalEntry(title: "Entry 1", content: "Test content 1")
        _ = try dataController.createJournalEntry(title: "Entry 2", content: "Test content 2")
        _ = try dataController.createJournalEntry(title: "Entry 3", content: "Test content 3")

        let report = reportGenerator.generateWeeklyReport()

        // totalEntries counts journals
        XCTAssertEqual(report.totalEntries, 3)
    }

    @MainActor
    func testMonthlyReportGeneration() async throws {
        // Create journal entries (reports count these now)
        _ = try dataController.createJournalEntry(title: "Entry 1", content: "Test content 1")
        _ = try dataController.createJournalEntry(title: "Entry 2", content: "Test content 2")
        _ = try dataController.createJournalEntry(title: "Entry 3", content: "Test content 3")

        let report = reportGenerator.generateMonthlyReport()

        // totalEntries counts journals
        XCTAssertEqual(report.totalEntries, 3)
    }

    func testEmptyReports() throws {
        let weeklyReport = reportGenerator.generateWeeklyReport()
        XCTAssertEqual(weeklyReport.totalEntries, 0)
        XCTAssertEqual(weeklyReport.averagePerDay, 0)

        let monthlyReport = reportGenerator.generateMonthlyReport()
        XCTAssertEqual(monthlyReport.totalEntries, 0)
        XCTAssertEqual(monthlyReport.averagePerDay, 0)
    }
}

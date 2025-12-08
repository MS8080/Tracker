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
        dataController = nil
        reportGenerator = nil
    }

    @MainActor
    func testWeeklyReportGeneration() async throws {
        _ = try await dataController.createPatternEntry(patternType: .sensoryOverload)
        _ = try await dataController.createPatternEntry(patternType: .hyperfocus)
        _ = try await dataController.createPatternEntry(patternType: .energyLevel, intensity: 4)

        let report = reportGenerator.generateWeeklyReport()

        // totalEntries counts journals, totalPatterns counts pattern entries
        XCTAssertEqual(report.totalPatterns, 3)
        XCTAssertFalse(report.patternFrequency.isEmpty)
    }

    @MainActor
    func testMonthlyReportGeneration() async throws {
        _ = try await dataController.createPatternEntry(patternType: .sensoryOverload)
        _ = try await dataController.createPatternEntry(patternType: .hyperfocus)
        _ = try await dataController.createPatternEntry(patternType: .socialInteraction, intensity: 3)

        let report = reportGenerator.generateMonthlyReport()

        // totalEntries counts journals, totalPatterns counts pattern entries
        XCTAssertEqual(report.totalPatterns, 3)
        XCTAssertFalse(report.topPatterns.isEmpty)
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

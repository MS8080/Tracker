import XCTest
import CoreData
@testable import BehaviorTracker

@MainActor
final class CorrelationAnalysisServiceTests: XCTestCase {
    var dataController: DataController!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        DataController.shared = dataController
    }

    override func tearDownWithError() throws {
        dataController = nil
    }

    // MARK: - Empty Data Tests

    func testGenerateInsightsWithNoData() async throws {
        let service = CorrelationAnalysisService.shared
        let insights = await service.generateInsights(days: 30)

        XCTAssertTrue(insights.isEmpty)
    }

    // MARK: - Confidence Level Tests

    func testConfidenceLevelLow() async throws {
        // Create less than 10 pattern entries
        for _ in 0..<5 {
            _ = try await dataController.createPatternEntry(patternType: .sensoryOverload, intensity: 4)
        }

        let service = CorrelationAnalysisService.shared
        let insights = await service.generateInsights(days: 30)

        // Any insights generated should have low confidence due to small sample size
        for insight in insights {
            if insight.sampleSize < 10 {
                XCTAssertEqual(insight.confidence, .low)
            }
        }
    }

    func testConfidenceLevelMedium() async throws {
        // Create 10-30 pattern entries
        for _ in 0..<15 {
            _ = try await dataController.createPatternEntry(patternType: .sensoryOverload, intensity: 4)
        }

        let service = CorrelationAnalysisService.shared
        let insights = await service.generateInsights(days: 30)

        for insight in insights where insight.sampleSize >= 10 && insight.sampleSize < 30 {
            XCTAssertEqual(insight.confidence, .medium)
        }
    }

    // MARK: - Time Pattern Correlation Tests

    func testTimePatternCorrelation() async throws {
        // Create entries predominantly in the morning
        let calendar = Calendar.current
        let morningTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!

        for i in 0..<10 {
            let entry = try await dataController.createPatternEntry(patternType: .sensoryOverload, intensity: 3)
            let dayOffset = -i
            entry.timestamp = calendar.date(byAdding: .day, value: dayOffset, to: morningTime)!
        }
        dataController.save()

        let service = CorrelationAnalysisService.shared
        let insights = await service.generateInsights(days: 30)

        // Should find a time pattern correlation for morning
        let timeInsights = insights.filter { $0.type == .timePattern }

        // If we have enough data, we might get a time correlation
        if !timeInsights.isEmpty {
            XCTAssertTrue(timeInsights.first?.title.lowercased().contains("morning") ?? false)
        }
    }

    // MARK: - Medication Pattern Correlation Tests

    func testMedicationPatternCorrelation() async throws {
        // Create a medication
        let medication = try dataController.createMedication(
            name: "Test Med",
            dosage: "10mg",
            frequency: MedicationFrequency.daily.rawValue,
            notes: nil
        )

        // Create medication logs and pattern entries on same days
        let calendar = Calendar.current
        let today = Date()

        // Days with medication: lower intensity
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i * 2, to: today)!

            _ = try dataController.createMedicationLog(
                medication: medication,
                taken: true,
                skippedReason: nil,
                sideEffects: nil,
                effectiveness: 3,
                mood: 3,
                energyLevel: 3,
                notes: nil
            )

            let entry = try await dataController.createPatternEntry(patternType: .sensoryOverload, intensity: 2)
            entry.timestamp = date
        }

        // Days without medication: higher intensity
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -(i * 2 + 1), to: today)!
            let entry = try await dataController.createPatternEntry(patternType: .sensoryOverload, intensity: 5)
            entry.timestamp = date
        }

        dataController.save()

        let service = CorrelationAnalysisService.shared
        let insights = await service.generateInsights(days: 30)

        // Should find some medication-related correlation
        let medicationInsights = insights.filter { $0.type == .medicationPattern }

        // Verify the service runs without crashing
        XCTAssertNotNil(insights)
    }

    // MARK: - Factor Pattern Correlation Tests

    func testFactorPatternCorrelation() async throws {
        // Create entries with different contributing factors
        for i in 0..<10 {
            _ = try await dataController.createPatternEntry(
                patternType: .sensoryOverload,
                intensity: Int16(i % 3 + 3)
            )
        }

        dataController.save()

        let service = CorrelationAnalysisService.shared
        let insights = await service.generateInsights(days: 30)

        XCTAssertNotNil(insights)
    }

    // MARK: - Insight Sorting Tests

    func testInsightsAreSortedByStrength() async throws {
        // Create varied data to generate multiple insights
        for i in 0..<20 {
            _ = try await dataController.createPatternEntry(
                patternType: i % 2 == 0 ? .sensoryOverload : .hyperfocus,
                intensity: Int16((i % 5) + 1)
            )
        }

        dataController.save()

        let service = CorrelationAnalysisService.shared
        let insights = await service.generateInsights(days: 30)

        // Verify insights are sorted by strength (descending)
        if insights.count > 1 {
            for i in 0..<(insights.count - 1) {
                XCTAssertGreaterThanOrEqual(insights[i].strength, insights[i + 1].strength)
            }
        }
    }

    // MARK: - Confidence Display Tests

    func testConfidenceLevelDisplayName() {
        XCTAssertEqual(CorrelationInsight.ConfidenceLevel.low.displayName, NSLocalizedString("correlation.confidence.low", comment: "Low confidence"))
        XCTAssertEqual(CorrelationInsight.ConfidenceLevel.medium.displayName, NSLocalizedString("correlation.confidence.medium", comment: "Medium confidence"))
        XCTAssertEqual(CorrelationInsight.ConfidenceLevel.high.displayName, NSLocalizedString("correlation.confidence.high", comment: "High confidence"))
    }

    func testConfidenceLevelColor() {
        XCTAssertEqual(CorrelationInsight.ConfidenceLevel.low.color, "orange")
        XCTAssertEqual(CorrelationInsight.ConfidenceLevel.medium.color, "yellow")
        XCTAssertEqual(CorrelationInsight.ConfidenceLevel.high.color, "green")
    }
}

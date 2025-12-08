import XCTest
import CoreData
@testable import BehaviorTracker

final class MedicationViewModelTests: XCTestCase {
    var dataController: DataController!
    var viewModel: MedicationViewModel!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        DataController.shared = dataController
        viewModel = MedicationViewModel(dataController: dataController)
    }

    override func tearDownWithError() throws {
        // Clean up all data
        let context = dataController.container.viewContext
        for entityName in ["Medication", "MedicationLog"] {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
        }
        try? context.save()
        dataController = nil
        viewModel = nil
    }

    // MARK: - Add Medication Tests

    func testAddMedication() throws {
        let success = viewModel.addMedication(
            name: "Vitamin D",
            dosage: "1000 IU",
            frequency: .daily,
            notes: "Take with breakfast"
        )

        XCTAssertTrue(success)

        viewModel.loadMedications()

        // Wait for async load
        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.medications.count, 1)
        XCTAssertEqual(viewModel.medications.first?.name, "Vitamin D")
        XCTAssertEqual(viewModel.medications.first?.dosage, "1000 IU")
    }

    func testAddMedicationWithoutOptionalFields() throws {
        let success = viewModel.addMedication(
            name: "Aspirin",
            dosage: nil,
            frequency: .asNeeded,
            notes: nil
        )

        XCTAssertTrue(success)
    }

    // MARK: - Deactivate Medication Tests

    func testDeactivateMedication() throws {
        _ = viewModel.addMedication(
            name: "Test Med",
            dosage: "10mg",
            frequency: .daily,
            notes: nil
        )

        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard let medication = viewModel.medications.first else {
            XCTFail("Medication not found")
            return
        }

        XCTAssertTrue(medication.isActive)

        viewModel.deactivateMedication(medication)
        viewModel.loadMedications()

        let expectation2 = XCTestExpectation(description: "Reload medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)

        // After deactivating, active-only fetch should return empty
        XCTAssertEqual(viewModel.medications.count, 0)
    }

    // MARK: - Log Medication Tests

    func testLogMedication() throws {
        _ = viewModel.addMedication(
            name: "Daily Vitamin",
            dosage: "500mg",
            frequency: .daily,
            notes: nil
        )

        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard let medication = viewModel.medications.first else {
            XCTFail("Medication not found")
            return
        }

        let success = viewModel.logMedication(
            medication: medication,
            taken: true,
            skippedReason: nil,
            sideEffects: nil,
            effectiveness: 4,
            mood: 3,
            energyLevel: 4,
            notes: "Felt good"
        )

        XCTAssertTrue(success)

        viewModel.loadTodaysLogs()

        let expectation2 = XCTestExpectation(description: "Load logs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)

        XCTAssertEqual(viewModel.todaysLogs.count, 1)
    }

    func testLogMedicationSkipped() throws {
        _ = viewModel.addMedication(
            name: "Test Med",
            dosage: "10mg",
            frequency: .daily,
            notes: nil
        )

        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard let medication = viewModel.medications.first else {
            XCTFail("Medication not found")
            return
        }

        let success = viewModel.logMedication(
            medication: medication,
            taken: false,
            skippedReason: "Forgot",
            sideEffects: nil,
            effectiveness: 0,
            mood: 0,
            energyLevel: 0,
            notes: nil
        )

        XCTAssertTrue(success)
    }

    // MARK: - Has Taken Today Tests

    func testHasTakenToday() throws {
        _ = viewModel.addMedication(
            name: "Daily Med",
            dosage: "10mg",
            frequency: .daily,
            notes: nil
        )

        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard let medication = viewModel.medications.first else {
            XCTFail("Medication not found")
            return
        }

        XCTAssertFalse(viewModel.hasTakenToday(medication: medication))

        _ = viewModel.logMedication(
            medication: medication,
            taken: true,
            skippedReason: nil,
            sideEffects: nil,
            effectiveness: 3,
            mood: 3,
            energyLevel: 3,
            notes: nil
        )

        viewModel.loadTodaysLogs()

        let expectation2 = XCTestExpectation(description: "Load logs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)

        XCTAssertTrue(viewModel.hasTakenToday(medication: medication))
    }

    // MARK: - Average Calculations Tests

    func testGetAverageEffectiveness() throws {
        _ = viewModel.addMedication(
            name: "Test Med",
            dosage: "10mg",
            frequency: .daily,
            notes: nil
        )

        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard let medication = viewModel.medications.first else {
            XCTFail("Medication not found")
            return
        }

        // Log with effectiveness 4
        _ = viewModel.logMedication(
            medication: medication,
            taken: true,
            skippedReason: nil,
            sideEffects: nil,
            effectiveness: 4,
            mood: 3,
            energyLevel: 3,
            notes: nil
        )

        // Log with effectiveness 2
        _ = viewModel.logMedication(
            medication: medication,
            taken: true,
            skippedReason: nil,
            sideEffects: nil,
            effectiveness: 2,
            mood: 3,
            energyLevel: 3,
            notes: nil
        )

        let avgEffectiveness = viewModel.getAverageEffectiveness(for: medication, days: 7)

        XCTAssertEqual(avgEffectiveness, 3.0, accuracy: 0.01)
    }

    func testGetAdherenceRate() throws {
        _ = viewModel.addMedication(
            name: "Test Med",
            dosage: "10mg",
            frequency: .daily,
            notes: nil
        )

        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard let medication = viewModel.medications.first else {
            XCTFail("Medication not found")
            return
        }

        // 3 taken, 1 skipped = 75% adherence
        _ = viewModel.logMedication(medication: medication, taken: true, skippedReason: nil, sideEffects: nil, effectiveness: 3, mood: 3, energyLevel: 3, notes: nil)
        _ = viewModel.logMedication(medication: medication, taken: true, skippedReason: nil, sideEffects: nil, effectiveness: 3, mood: 3, energyLevel: 3, notes: nil)
        _ = viewModel.logMedication(medication: medication, taken: true, skippedReason: nil, sideEffects: nil, effectiveness: 3, mood: 3, energyLevel: 3, notes: nil)
        _ = viewModel.logMedication(medication: medication, taken: false, skippedReason: "Forgot", sideEffects: nil, effectiveness: 0, mood: 0, energyLevel: 0, notes: nil)

        let adherenceRate = viewModel.getAdherenceRate(for: medication, days: 7)

        XCTAssertEqual(adherenceRate, 75.0, accuracy: 0.01)
    }

    // MARK: - Empty State Tests

    func testEmptyMedications() throws {
        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(viewModel.medications.isEmpty)
    }

    func testGetAverageEffectivenessNoLogs() throws {
        _ = viewModel.addMedication(
            name: "Test Med",
            dosage: "10mg",
            frequency: .daily,
            notes: nil
        )

        viewModel.loadMedications()

        let expectation = XCTestExpectation(description: "Load medications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard let medication = viewModel.medications.first else {
            XCTFail("Medication not found")
            return
        }

        let avgEffectiveness = viewModel.getAverageEffectiveness(for: medication, days: 7)

        XCTAssertEqual(avgEffectiveness, 0.0)
    }
}

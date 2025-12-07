import XCTest
import CoreData
@testable import BehaviorTracker

final class MedicationRepositoryTests: XCTestCase {
    var dataController: DataController!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
    }

    override func tearDownWithError() throws {
        dataController = nil
    }

    // MARK: - Medication Create Tests

    func testCreateMedication() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Ibuprofen",
            dosage: "200mg",
            frequency: "Twice daily",
            notes: "Take with food"
        )

        XCTAssertNotNil(medication)
        XCTAssertEqual(medication.name, "Ibuprofen")
        XCTAssertEqual(medication.dosage, "200mg")
        XCTAssertEqual(medication.frequency, "Twice daily")
        XCTAssertEqual(medication.notes, "Take with food")
        XCTAssertTrue(medication.isActive)
    }

    func testCreateMedicationWithoutOptionalFields() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Vitamin D",
            frequency: "Daily"
        )

        XCTAssertNotNil(medication)
        XCTAssertEqual(medication.name, "Vitamin D")
        XCTAssertNil(medication.dosage)
        XCTAssertEqual(medication.frequency, "Daily")
        XCTAssertNil(medication.notes)
    }

    func testCreateMedicationTrimsWhitespace() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "   Aspirin   ",
            dosage: "  100mg  ",
            frequency: " Daily ",
            notes: "\n  Notes here  \n"
        )

        XCTAssertEqual(medication.name, "Aspirin")
        XCTAssertEqual(medication.dosage, "100mg")
        XCTAssertEqual(medication.frequency, "Daily")
        XCTAssertEqual(medication.notes, "Notes here")
    }

    // MARK: - Medication Validation Tests

    func testCreateMedicationRejectsEmptyName() {
        do {
            _ = try MedicationRepository.shared.createMedication(
                name: "",
                frequency: "Daily"
            )
            XCTFail("Should throw validation error for empty name")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    func testCreateMedicationRejectsEmptyFrequency() {
        do {
            _ = try MedicationRepository.shared.createMedication(
                name: "Test Med",
                frequency: ""
            )
            XCTFail("Should throw validation error for empty frequency")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    func testCreateMedicationRejectsTooLongName() {
        let longName = String(repeating: "a", count: 101)
        do {
            _ = try MedicationRepository.shared.createMedication(
                name: longName,
                frequency: "Daily"
            )
            XCTFail("Should throw validation error for too long name")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    // MARK: - Medication Fetch Tests

    func testFetchMedications() throws {
        _ = try MedicationRepository.shared.createMedication(name: "Med 1", frequency: "Daily")
        _ = try MedicationRepository.shared.createMedication(name: "Med 2", frequency: "Weekly")
        _ = try MedicationRepository.shared.createMedication(name: "Med 3", frequency: "As needed")

        let medications = MedicationRepository.shared.fetchMedications()
        XCTAssertEqual(medications.count, 3)
    }

    func testFetchMedicationsActiveOnly() throws {
        let med1 = try MedicationRepository.shared.createMedication(name: "Active Med", frequency: "Daily")
        let med2 = try MedicationRepository.shared.createMedication(name: "Inactive Med", frequency: "Daily")

        med2.isActive = false
        MedicationRepository.shared.updateMedication(med2)

        let activeMedications = MedicationRepository.shared.fetchMedications(activeOnly: true)
        XCTAssertEqual(activeMedications.count, 1)
        XCTAssertEqual(activeMedications.first?.name, "Active Med")

        let allMedications = MedicationRepository.shared.fetchMedications(activeOnly: false)
        XCTAssertEqual(allMedications.count, 2)
    }

    func testFetchMedicationsSortedByName() throws {
        _ = try MedicationRepository.shared.createMedication(name: "Zyrtec", frequency: "Daily")
        _ = try MedicationRepository.shared.createMedication(name: "Advil", frequency: "Daily")
        _ = try MedicationRepository.shared.createMedication(name: "Motrin", frequency: "Daily")

        let medications = MedicationRepository.shared.fetchMedications()

        XCTAssertEqual(medications.count, 3)
        XCTAssertEqual(medications[0].name, "Advil")
        XCTAssertEqual(medications[1].name, "Motrin")
        XCTAssertEqual(medications[2].name, "Zyrtec")
    }

    // MARK: - Medication Update/Delete Tests

    func testUpdateMedication() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Original Name",
            frequency: "Daily"
        )

        medication.name = "Updated Name"
        medication.dosage = "New Dosage"
        MedicationRepository.shared.updateMedication(medication)

        let medications = MedicationRepository.shared.fetchMedications()
        XCTAssertEqual(medications.count, 1)
        XCTAssertEqual(medications.first?.name, "Updated Name")
        XCTAssertEqual(medications.first?.dosage, "New Dosage")
    }

    func testDeleteMedication() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "To Delete",
            frequency: "Daily"
        )

        var medications = MedicationRepository.shared.fetchMedications()
        XCTAssertEqual(medications.count, 1)

        MedicationRepository.shared.deleteMedication(medication)

        medications = MedicationRepository.shared.fetchMedications(activeOnly: false)
        XCTAssertEqual(medications.count, 0)
    }

    // MARK: - MedicationLog Create Tests

    func testCreateMedicationLog() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Test Med",
            frequency: "Daily"
        )

        let log = try MedicationRepository.shared.createLog(
            medication: medication,
            taken: true,
            effectiveness: 4,
            mood: 3,
            energyLevel: 4,
            notes: "Felt good"
        )

        XCTAssertNotNil(log)
        XCTAssertEqual(log.medication?.name, "Test Med")
        XCTAssertTrue(log.taken)
        XCTAssertEqual(log.effectiveness, 4)
        XCTAssertEqual(log.mood, 3)
        XCTAssertEqual(log.energyLevel, 4)
        XCTAssertEqual(log.notes, "Felt good")
    }

    func testCreateMedicationLogSkipped() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Skipped Med",
            frequency: "Daily"
        )

        let log = try MedicationRepository.shared.createLog(
            medication: medication,
            taken: false,
            skippedReason: "Forgot to take it"
        )

        XCTAssertNotNil(log)
        XCTAssertFalse(log.taken)
        XCTAssertEqual(log.skippedReason, "Forgot to take it")
    }

    func testCreateMedicationLogWithSideEffects() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Med With Effects",
            frequency: "Daily"
        )

        let log = try MedicationRepository.shared.createLog(
            medication: medication,
            taken: true,
            sideEffects: "Mild nausea, drowsiness"
        )

        XCTAssertNotNil(log)
        XCTAssertEqual(log.sideEffects, "Mild nausea, drowsiness")
    }

    // MARK: - MedicationLog Validation Tests

    func testCreateLogRejectsInvalidEffectiveness() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Test",
            frequency: "Daily"
        )

        do {
            _ = try MedicationRepository.shared.createLog(
                medication: medication,
                effectiveness: 10 // Invalid: max is 5
            )
            XCTFail("Should throw validation error for invalid effectiveness")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    func testCreateLogRejectsInvalidMood() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Test",
            frequency: "Daily"
        )

        do {
            _ = try MedicationRepository.shared.createLog(
                medication: medication,
                mood: -1 // Invalid: min is 0
            )
            XCTFail("Should throw validation error for invalid mood")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }

    // MARK: - MedicationLog Fetch Tests

    func testFetchLogs() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Test Med",
            frequency: "Daily"
        )

        _ = try MedicationRepository.shared.createLog(medication: medication)
        _ = try MedicationRepository.shared.createLog(medication: medication)
        _ = try MedicationRepository.shared.createLog(medication: medication)

        let logs = MedicationRepository.shared.fetchLogs()
        XCTAssertEqual(logs.count, 3)
    }

    func testFetchLogsWithDateRange() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Test Med",
            frequency: "Daily"
        )

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        _ = try MedicationRepository.shared.createLog(medication: medication)

        let logs = MedicationRepository.shared.fetchLogs(startDate: yesterday, endDate: tomorrow)
        XCTAssertEqual(logs.count, 1)
    }

    func testFetchLogsForSpecificMedication() throws {
        let med1 = try MedicationRepository.shared.createMedication(name: "Med 1", frequency: "Daily")
        let med2 = try MedicationRepository.shared.createMedication(name: "Med 2", frequency: "Daily")

        _ = try MedicationRepository.shared.createLog(medication: med1)
        _ = try MedicationRepository.shared.createLog(medication: med1)
        _ = try MedicationRepository.shared.createLog(medication: med2)

        let med1Logs = MedicationRepository.shared.fetchLogs(medication: med1)
        XCTAssertEqual(med1Logs.count, 2)

        let med2Logs = MedicationRepository.shared.fetchLogs(medication: med2)
        XCTAssertEqual(med2Logs.count, 1)
    }

    func testGetTodaysLogs() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Today's Med",
            frequency: "Daily"
        )

        _ = try MedicationRepository.shared.createLog(medication: medication)
        _ = try MedicationRepository.shared.createLog(medication: medication)

        let todaysLogs = MedicationRepository.shared.getTodaysLogs()
        XCTAssertEqual(todaysLogs.count, 2)
    }

    // MARK: - MedicationLog Delete Tests

    func testDeleteLog() throws {
        let medication = try MedicationRepository.shared.createMedication(
            name: "Test Med",
            frequency: "Daily"
        )

        let log = try MedicationRepository.shared.createLog(medication: medication)

        var logs = MedicationRepository.shared.fetchLogs()
        XCTAssertEqual(logs.count, 1)

        MedicationRepository.shared.deleteLog(log)

        logs = MedicationRepository.shared.fetchLogs()
        XCTAssertEqual(logs.count, 0)
    }

    // MARK: - Edge Cases

    func testFetchLogsWithNoLogs() {
        let logs = MedicationRepository.shared.fetchLogs()
        XCTAssertTrue(logs.isEmpty)
    }

    func testFetchMedicationsWithNoMedications() {
        let medications = MedicationRepository.shared.fetchMedications()
        XCTAssertTrue(medications.isEmpty)
    }

    func testGetTodaysLogsWithNoLogs() {
        let todaysLogs = MedicationRepository.shared.getTodaysLogs()
        XCTAssertTrue(todaysLogs.isEmpty)
    }
}

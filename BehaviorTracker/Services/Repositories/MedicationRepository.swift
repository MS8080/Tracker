import CoreData
import Foundation

/// Repository for Medication and MedicationLog CRUD operations
final class MedicationRepository {
    static let shared = MedicationRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Medication Create

    func createMedication(
        name: String,
        dosage: String? = nil,
        frequency: String,
        notes: String? = nil
    ) throws -> Medication {
        try Validator(name, fieldName: "Medication name")
            .notEmpty()
            .maxLength(100)

        try Validator(dosage, fieldName: "Dosage")
            .ifPresent { try $0.maxLength(50) }

        try Validator(frequency, fieldName: "Frequency")
            .notEmpty()
            .maxLength(50)

        try Validator(notes, fieldName: "Notes")
            .ifPresent { try $0.maxLength(500) }

        let medication = Medication(context: viewContext)
        medication.configure(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage: dosage?.trimmingCharacters(in: .whitespacesAndNewlines),
            frequency: frequency.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        DataController.shared.save()
        return medication
    }

    // MARK: - Medication Read

    func fetchMedications(activeOnly: Bool = true) -> [Medication] {
        do {
            return try fetchMedicationsOrThrow(activeOnly: activeOnly)
        } catch {
            return []
        }
    }

    func fetchMedicationsOrThrow(activeOnly: Bool = true) throws -> [Medication] {
        let request = NSFetchRequest<Medication>(entityName: "Medication")

        if activeOnly {
            request.predicate = NSPredicate(format: "isActive == true")
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.name, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    // MARK: - Medication Update/Delete

    func updateMedication(_ medication: Medication) {
        DataController.shared.save()
    }

    func deleteMedication(_ medication: Medication) {
        viewContext.delete(medication)
        DataController.shared.save()
    }

    // MARK: - MedicationLog Create

    func createLog(
        medication: Medication,
        taken: Bool = true,
        skippedReason: String? = nil,
        sideEffects: String? = nil,
        effectiveness: Int16 = 0,
        mood: Int16 = 0,
        energyLevel: Int16 = 0,
        notes: String? = nil
    ) throws -> MedicationLog {
        try Validator(effectiveness, fieldName: "Effectiveness")
            .inRange(0...5)

        try Validator(mood, fieldName: "Mood")
            .inRange(0...5)

        try Validator(energyLevel, fieldName: "Energy level")
            .inRange(0...5)

        try Validator(skippedReason, fieldName: "Skipped reason")
            .ifPresent { try $0.maxLength(200) }

        try Validator(sideEffects, fieldName: "Side effects")
            .ifPresent { try $0.maxLength(500) }

        try Validator(notes, fieldName: "Notes")
            .ifPresent { try $0.maxLength(500) }

        let log = MedicationLog(context: viewContext)
        log.configure(
            medication: medication,
            taken: taken,
            skippedReason: skippedReason?.trimmingCharacters(in: .whitespacesAndNewlines),
            sideEffects: sideEffects?.trimmingCharacters(in: .whitespacesAndNewlines),
            effectiveness: effectiveness,
            mood: mood,
            energyLevel: energyLevel,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        DataController.shared.save()
        return log
    }

    // MARK: - MedicationLog Read

    func fetchLogs(
        startDate: Date? = nil,
        endDate: Date? = nil,
        medication: Medication? = nil
    ) -> [MedicationLog] {
        do {
            return try fetchLogsOrThrow(startDate: startDate, endDate: endDate, medication: medication)
        } catch {
            return []
        }
    }

    func fetchLogsOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        medication: Medication? = nil
    ) throws -> [MedicationLog] {
        let request = NSFetchRequest<MedicationLog>(entityName: "MedicationLog")
        var predicates: [NSPredicate] = []

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        if let medication = medication {
            predicates.append(NSPredicate(format: "medication == %@", medication))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationLog.timestamp, ascending: false)]
        request.relationshipKeyPathsForPrefetching = ["medication"]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    func getTodaysLogs() -> [MedicationLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        return fetchLogs(startDate: startOfDay, endDate: endOfDay)
    }

    // MARK: - MedicationLog Delete

    func deleteLog(_ log: MedicationLog) {
        viewContext.delete(log)
        DataController.shared.save()
    }
}

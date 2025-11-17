import Foundation
import CoreData

@objc(Medication)
public class Medication: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dosage: String?
    @NSManaged public var frequency: String // daily, twice_daily, as_needed, etc.
    @NSManaged public var prescribedDate: Date
    @NSManaged public var isActive: Bool
    @NSManaged public var notes: String?
    @NSManaged public var logs: NSSet?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.prescribedDate = Date()
        self.isActive = true
    }

    func configure(name: String,
                   dosage: String? = nil,
                   frequency: String,
                   notes: String? = nil) {
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.notes = notes
    }
}

extension Medication {
    @objc(addLogsObject:)
    @NSManaged public func addToLogs(_ value: MedicationLog)

    @objc(removeLogsObject:)
    @NSManaged public func removeFromLogs(_ value: MedicationLog)

    @objc(addLogs:)
    @NSManaged public func addToLogs(_ values: NSSet)

    @objc(removeLogs:)
    @NSManaged public func removeFromLogs(_ values: NSSet)
}

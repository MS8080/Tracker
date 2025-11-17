import Foundation
import CoreData

@objc(Medication)
public class Medication: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dosage: String?
    @NSManaged public var frequency: String
    @NSManaged public var notes: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdDate: Date
    @NSManaged public var logs: NSSet?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.isActive = true
        self.createdDate = Date()
    }
    
    func configure(
        name: String,
        dosage: String? = nil,
        frequency: String,
        notes: String? = nil
    ) {
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.notes = notes
    }
}

// MARK: - Generated accessors for logs
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

import Foundation
import CoreData

@objc(MedicationLog)
public class MedicationLog: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var taken: Bool
    @NSManaged public var skippedReason: String?
    @NSManaged public var sideEffects: String?
    @NSManaged public var effectiveness: Int16 // 1-5 scale
    @NSManaged public var mood: Int16 // 1-5 scale
    @NSManaged public var energyLevel: Int16 // 1-5 scale
    @NSManaged public var notes: String?
    @NSManaged public var medication: Medication?
    @NSManaged public var journalEntries: NSSet?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.timestamp = Date()
        self.taken = true
        self.effectiveness = 0
        self.mood = 0
        self.energyLevel = 0
    }

    func configure(medication: Medication,
                   taken: Bool = true,
                   skippedReason: String? = nil,
                   sideEffects: String? = nil,
                   effectiveness: Int16 = 0,
                   mood: Int16 = 0,
                   energyLevel: Int16 = 0,
                   notes: String? = nil) {
        self.medication = medication
        self.taken = taken
        self.skippedReason = skippedReason
        self.sideEffects = sideEffects
        self.effectiveness = effectiveness
        self.mood = mood
        self.energyLevel = energyLevel
        self.notes = notes
    }
}

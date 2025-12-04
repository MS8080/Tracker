import Foundation
import CoreData

@objc(ExtractedPattern)
public class ExtractedPattern: NSManagedObject {

    /// Convert triggersData string to array
    var triggers: [String] {
        get {
            guard let data = triggersData else { return [] }
            return data.components(separatedBy: "|||")
        }
        set {
            triggersData = newValue.joined(separator: "|||")
        }
    }

    /// Convert copingUsed string to array
    var copingStrategies: [String] {
        get {
            guard let data = copingUsed else { return [] }
            return data.components(separatedBy: "|||")
        }
        set {
            copingUsed = newValue.joined(separator: "|||")
        }
    }

    /// Get PatternType enum from stored string
    var patternTypeEnum: PatternType? {
        return PatternBank.patternType(from: patternType)
    }

    /// Get category color
    var categoryColor: String {
        switch category {
        case "Sensory": return "red"
        case "Executive Function": return "orange"
        case "Energy & Regulation": return "purple"
        case "Social & Communication": return "blue"
        case "Routine & Change": return "yellow"
        case "Demand Avoidance": return "pink"
        case "Physical & Sleep": return "green"
        case "Special Interests": return "cyan"
        default: return "gray"
        }
    }
}

// MARK: - Identifiable
extension ExtractedPattern: Identifiable {}

// MARK: - Fetch Requests
extension ExtractedPattern {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExtractedPattern> {
        return NSFetchRequest<ExtractedPattern>(entityName: "ExtractedPattern")
    }

    @NSManaged public var id: UUID
    @NSManaged public var patternType: String
    @NSManaged public var category: String
    @NSManaged public var intensity: Int16
    @NSManaged public var triggersData: String?
    @NSManaged public var timeOfDay: String?
    @NSManaged public var copingUsed: String?
    @NSManaged public var details: String?
    @NSManaged public var confidence: Double
    @NSManaged public var timestamp: Date
    @NSManaged public var journalEntry: JournalEntry?
    @NSManaged public var cascadesFrom: Set<PatternCascade>?
    @NSManaged public var cascadesTo: Set<PatternCascade>?
}

// MARK: - Cascade Accessors
extension ExtractedPattern {

    @objc(addCascadesFromObject:)
    @NSManaged public func addToCascadesFrom(_ value: PatternCascade)

    @objc(removeCascadesFromObject:)
    @NSManaged public func removeFromCascadesFrom(_ value: PatternCascade)

    @objc(addCascadesFrom:)
    @NSManaged public func addToCascadesFrom(_ values: NSSet)

    @objc(removeCascadesFrom:)
    @NSManaged public func removeFromCascadesFrom(_ values: NSSet)

    @objc(addCascadesToObject:)
    @NSManaged public func addToCascadesTo(_ value: PatternCascade)

    @objc(removeCascadesToObject:)
    @NSManaged public func removeFromCascadesTo(_ value: PatternCascade)

    @objc(addCascadesTo:)
    @NSManaged public func addToCascadesTo(_ values: NSSet)

    @objc(removeCascadesTo:)
    @NSManaged public func removeFromCascadesTo(_ values: NSSet)
}

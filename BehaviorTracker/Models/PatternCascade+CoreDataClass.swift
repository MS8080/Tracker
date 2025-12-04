import Foundation
import CoreData

@objc(PatternCascade)
public class PatternCascade: NSManagedObject {

    /// Human-readable description of the cascade
    var displayDescription: String {
        guard let from = fromPattern, let to = toPattern else {
            return descriptionText ?? "Unknown cascade"
        }
        return "\(from.patternType) → \(to.patternType)"
    }

    /// Confidence as percentage string
    var confidencePercent: String {
        return "\(Int(confidence * 100))%"
    }
}

// MARK: - Identifiable
extension PatternCascade: Identifiable {}

// MARK: - Fetch Requests
extension PatternCascade {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PatternCascade> {
        return NSFetchRequest<PatternCascade>(entityName: "PatternCascade")
    }

    @NSManaged public var id: UUID
    @NSManaged public var confidence: Double
    @NSManaged public var descriptionText: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var fromPattern: ExtractedPattern?
    @NSManaged public var toPattern: ExtractedPattern?
}

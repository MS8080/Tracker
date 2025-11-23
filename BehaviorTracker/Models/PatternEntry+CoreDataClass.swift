import Foundation
import CoreData

@objc(PatternEntry)
public class PatternEntry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var category: String
    @NSManaged public var patternType: String
    @NSManaged public var intensity: Int16
    @NSManaged public var duration: Int32
    @NSManaged public var contextNotes: String?
    @NSManaged public var specificDetails: String?
    @NSManaged public var customPatternName: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var tags: NSSet?
    @NSManaged public var journalEntries: NSSet?
    @NSManaged private var contributingFactorsData: Data?

    var patternCategoryEnum: PatternCategory? {
        PatternCategory(rawValue: category)
    }
    
    /// Get or set contributing factors as an array
    var contributingFactors: [ContributingFactor] {
        get {
            guard let data = contributingFactorsData else { return [] }
            let decoder = JSONDecoder()
            return (try? decoder.decode([ContributingFactor].self, from: data)) ?? []
        }
        set {
            let encoder = JSONEncoder()
            contributingFactorsData = try? encoder.encode(newValue)
        }
    }

    var patternTypeEnum: PatternType? {
        PatternType(rawValue: patternType)
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.timestamp = Date()
        self.isFavorite = false
    }
    
    /// Valid intensity range (0 = not set, 1-5 = intensity scale)
    static let validIntensityRange: ClosedRange<Int16> = 0...5

    func configure(patternType: PatternType,
                   intensity: Int16 = 0,
                   duration: Int32 = 0,
                   contextNotes: String? = nil,
                   specificDetails: String? = nil,
                   contributingFactors: [ContributingFactor] = []) {
        self.category = patternType.category.rawValue
        self.patternType = patternType.rawValue
        // Clamp intensity to valid range
        self.intensity = max(Self.validIntensityRange.lowerBound, min(intensity, Self.validIntensityRange.upperBound))
        self.duration = max(0, duration)
        self.contextNotes = contextNotes
        self.specificDetails = specificDetails
        self.contributingFactors = contributingFactors
    }
}

extension PatternEntry {
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}

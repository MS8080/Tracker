import Foundation
import CoreData

@objc(JournalEntry)
public class JournalEntry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var title: String?
    @NSManaged public var content: String
    @NSManaged public var mood: Int16
    @NSManaged public var isFavorite: Bool
    @NSManaged public var audioFileName: String?
    @NSManaged public var tags: NSSet?
    @NSManaged public var relatedPatternEntry: PatternEntry?
    @NSManaged public var relatedMedicationLog: MedicationLog?

    // AI Analysis fields
    @NSManaged public var isAnalyzed: Bool
    @NSManaged public var analysisConfidence: Double
    @NSManaged public var analysisSummary: String?
    @NSManaged public var overallIntensity: Int16
    @NSManaged public var extractedPatterns: NSSet?

    var hasVoiceNote: Bool {
        guard let fileName = audioFileName, !fileName.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: audioFileURL?.path ?? "")
    }

    var audioFileURL: URL? {
        guard let fileName = audioFileName, !fileName.isEmpty else { return nil }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("VoiceNotes").appendingPathComponent(fileName)
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.timestamp = Date()
        self.isFavorite = false
        self.mood = 0
    }

    func configure(title: String? = nil,
                   content: String,
                   mood: Int16 = 0,
                   relatedPatternEntry: PatternEntry? = nil,
                   relatedMedicationLog: MedicationLog? = nil) {
        self.title = title
        self.content = content
        self.mood = mood
        self.relatedPatternEntry = relatedPatternEntry
        self.relatedMedicationLog = relatedMedicationLog
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var preview: String {
        // Strip markdown formatting for clean preview
        let cleanContent = content
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "---", with: "")
            .replacingOccurrences(of: "\n\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let maxLength = 100
        if cleanContent.count > maxLength {
            return String(cleanContent.prefix(maxLength)) + "..."
        }
        return cleanContent
    }

    /// Check if this entry is a saved insight (has "Insights" tag)
    /// These entries should not be analyzed by pattern extraction
    var isInsight: Bool {
        guard let tagSet = tags as? Set<Tag> else { return false }
        return tagSet.contains { $0.name == "Insights" }
    }

    /// Get all tag names as array
    var tagNames: [String] {
        guard let tagSet = tags as? Set<Tag> else { return [] }
        return tagSet.compactMap { $0.name }.sorted()
    }
}

extension JournalEntry {
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

    // Extracted patterns accessors
    @objc(addExtractedPatternsObject:)
    @NSManaged public func addToExtractedPatterns(_ value: ExtractedPattern)

    @objc(removeExtractedPatternsObject:)
    @NSManaged public func removeFromExtractedPatterns(_ value: ExtractedPattern)

    @objc(addExtractedPatterns:)
    @NSManaged public func addToExtractedPatterns(_ values: NSSet)

    @objc(removeExtractedPatterns:)
    @NSManaged public func removeFromExtractedPatterns(_ values: NSSet)

    /// Get extracted patterns as array
    var patternsArray: [ExtractedPattern] {
        let set = extractedPatterns as? Set<ExtractedPattern> ?? []
        return Array(set).sorted { $0.timestamp < $1.timestamp }
    }

    /// Check if entry has any cascades
    var hasCascades: Bool {
        return patternsArray.contains { pattern in
            !(pattern.cascadesFrom?.isEmpty ?? true) || !(pattern.cascadesTo?.isEmpty ?? true)
        }
    }
}

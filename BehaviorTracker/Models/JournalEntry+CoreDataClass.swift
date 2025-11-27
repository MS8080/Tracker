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
}

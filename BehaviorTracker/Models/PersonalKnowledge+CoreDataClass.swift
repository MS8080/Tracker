import Foundation
import CoreData

@objc(PersonalKnowledge)
public class PersonalKnowledge: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension PersonalKnowledge {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersonalKnowledge> {
        return NSFetchRequest<PersonalKnowledge>(entityName: "PersonalKnowledge")
    }

    /// Fetch all active knowledge items
    static func fetchAllActive(in context: NSManagedObjectContext) -> [PersonalKnowledge] {
        let request: NSFetchRequest<PersonalKnowledge> = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PersonalKnowledge.createdAt, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch personal knowledge: \(error)")
            return []
        }
    }

    /// Get combined context string for AI prompts
    static func getCombinedContext(in context: NSManagedObjectContext) -> String? {
        let items = fetchAllActive(in: context)
        guard !items.isEmpty else { return nil }

        let snippets = items.compactMap { item -> String? in
            guard let content = item.content, !content.isEmpty else { return nil }
            if let title = item.title, !title.isEmpty {
                return "- \(title): \(content)"
            }
            return "- \(content)"
        }

        guard !snippets.isEmpty else { return nil }

        return """
        Personal context about the user:
        \(snippets.joined(separator: "\n"))
        """
    }
}

import CoreData
import Foundation

/// Repository for PersonalKnowledge CRUD operations
final class PersonalKnowledgeRepository: @unchecked Sendable {
    static let shared = PersonalKnowledgeRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Create

    func create(title: String?, content: String) throws -> PersonalKnowledge {
        try Validator(content, fieldName: "Knowledge content")
            .notEmpty()
            .maxLength(5000)

        let knowledge = PersonalKnowledge(context: viewContext)
        knowledge.id = UUID()
        knowledge.title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        knowledge.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        knowledge.isActive = true
        knowledge.createdAt = Date()
        knowledge.updatedAt = Date()

        DataController.shared.save()
        return knowledge
    }

    // MARK: - Read

    func fetchAll() -> [PersonalKnowledge] {
        let request = NSFetchRequest<PersonalKnowledge>(entityName: "PersonalKnowledge")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PersonalKnowledge.createdAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            AppLogger.data.error("Failed to fetch personal knowledge", error: error)
            return []
        }
    }

    func fetchActive() -> [PersonalKnowledge] {
        let request = NSFetchRequest<PersonalKnowledge>(entityName: "PersonalKnowledge")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PersonalKnowledge.createdAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            AppLogger.data.error("Failed to fetch active personal knowledge", error: error)
            return []
        }
    }

    /// Get combined context string for AI prompts
    func getCombinedContext() -> String? {
        let items = fetchActive()
        guard !items.isEmpty else { return nil }

        let snippets = items.compactMap { item -> String? in
            guard let content = item.content, !content.isEmpty else { return nil }
            if let title = item.title, !title.isEmpty {
                return "- \(title): \(content)"
            }
            return "- \(content)"
        }

        guard !snippets.isEmpty else { return nil }

        return snippets.joined(separator: "\n")
    }

    // MARK: - Update

    func update(_ knowledge: PersonalKnowledge, title: String?, content: String) throws {
        try Validator(content, fieldName: "Knowledge content")
            .notEmpty()
            .maxLength(5000)

        knowledge.title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        knowledge.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        knowledge.updatedAt = Date()

        DataController.shared.save()
    }

    func toggleActive(_ knowledge: PersonalKnowledge) {
        knowledge.isActive.toggle()
        knowledge.updatedAt = Date()
        DataController.shared.save()
    }

    // MARK: - Delete

    func delete(_ knowledge: PersonalKnowledge) {
        viewContext.delete(knowledge)
        DataController.shared.save()
    }

    func deleteAll() {
        let items = fetchAll()
        for item in items {
            viewContext.delete(item)
        }
        DataController.shared.save()
    }
}

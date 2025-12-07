import CoreData
import Foundation

/// Repository for SetupItem CRUD operations
final class SetupItemRepository {
    static let shared = SetupItemRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Create

    func create(
        name: String,
        category: SetupItemCategory,
        effectTags: [String] = [],
        icon: String? = nil,
        notes: String? = nil,
        startDate: Date? = nil
    ) throws -> SetupItem {
        try Validator(name, fieldName: "Item name")
            .notEmpty()
            .maxLength(100)

        let item = SetupItem(context: viewContext)
        item.id = UUID()
        item.name = name
        item.category = category.rawValue
        item.setEffectTags(effectTags)
        item.icon = icon
        item.notes = notes
        item.isActive = true
        item.startDate = startDate ?? Date()
        item.sortOrder = Int16(fetch(category: category).count)

        DataController.shared.save()
        return item
    }

    // MARK: - Read

    func fetch(activeOnly: Bool = true, category: SetupItemCategory? = nil) -> [SetupItem] {
        do {
            return try fetchOrThrow(activeOnly: activeOnly, category: category)
        } catch {
            return []
        }
    }

    func fetchOrThrow(activeOnly: Bool = true, category: SetupItemCategory? = nil) throws -> [SetupItem] {
        let request = NSFetchRequest<SetupItem>(entityName: "SetupItem")

        var predicates: [NSPredicate] = []
        if activeOnly {
            predicates.append(NSPredicate(format: "isActive == YES"))
        }
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SetupItem.category, ascending: true),
            NSSortDescriptor(keyPath: \SetupItem.sortOrder, ascending: true)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    func fetchGrouped(activeOnly: Bool = true) -> [SetupItemCategory: [SetupItem]] {
        let items = fetch(activeOnly: activeOnly)
        return Dictionary(grouping: items) { item in
            item.categoryEnum ?? .medication
        }
    }

    // MARK: - Update

    func update(_ item: SetupItem) {
        DataController.shared.save()
    }

    func toggleActive(_ item: SetupItem) {
        item.isActive.toggle()
        DataController.shared.save()
    }

    // MARK: - Delete

    func delete(_ item: SetupItem) {
        viewContext.delete(item)
        DataController.shared.save()
    }
}

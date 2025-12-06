import CoreData
import Foundation

/// Repository for WishlistItem CRUD operations
final class WishlistRepository {
    static let shared = WishlistRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Create

    func create(
        title: String,
        category: WishlistItem.Category? = nil,
        priority: WishlistItem.Priority = .medium,
        notes: String? = nil,
        icon: String? = nil
    ) throws -> WishlistItem {
        try Validator(title, fieldName: "Wishlist item title")
            .notEmpty()
            .maxLength(200)

        let item = WishlistItem(context: viewContext)
        item.id = UUID()
        item.title = title
        item.category = category?.rawValue
        item.priority = priority.rawValue
        item.notes = notes
        item.icon = icon ?? category?.icon
        item.isAcquired = false
        item.createdAt = Date()

        DataController.shared.save()
        return item
    }

    // MARK: - Read

    func fetch(includeAcquired: Bool = false) -> [WishlistItem] {
        do {
            return try fetchOrThrow(includeAcquired: includeAcquired)
        } catch {
            print("Failed to fetch wishlist items: \(error)")
            return []
        }
    }

    func fetchOrThrow(includeAcquired: Bool = false) throws -> [WishlistItem] {
        let request = NSFetchRequest<WishlistItem>(entityName: "WishlistItem")

        if !includeAcquired {
            request.predicate = NSPredicate(format: "isAcquired == NO")
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.priority, ascending: false),
            NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    func fetchByCategory(_ category: WishlistItem.Category) -> [WishlistItem] {
        let request = NSFetchRequest<WishlistItem>(entityName: "WishlistItem")
        request.predicate = NSPredicate(format: "category == %@ AND isAcquired == NO", category.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.priority, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch wishlist items by category: \(error)")
            return []
        }
    }

    func fetchAcquired() -> [WishlistItem] {
        let request = NSFetchRequest<WishlistItem>(entityName: "WishlistItem")
        request.predicate = NSPredicate(format: "isAcquired == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch acquired wishlist items: \(error)")
            return []
        }
    }

    // MARK: - Update

    func update(_ item: WishlistItem) {
        DataController.shared.save()
    }

    func markAcquired(_ item: WishlistItem) {
        item.markAcquired()
        DataController.shared.save()
    }

    func markNotAcquired(_ item: WishlistItem) {
        item.markNotAcquired()
        DataController.shared.save()
    }

    // MARK: - Delete

    func delete(_ item: WishlistItem) {
        viewContext.delete(item)
        DataController.shared.save()
    }
}

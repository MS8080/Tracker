import CoreData
import Foundation

/// Repository for Struggle CRUD operations
final class StruggleRepository {
    static let shared = StruggleRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Create

    func create(
        title: String,
        category: Struggle.Category? = nil,
        intensity: Struggle.Intensity = .moderate,
        triggers: [String] = [],
        copingStrategies: [String] = [],
        notes: String? = nil,
        icon: String? = nil
    ) throws -> Struggle {
        try Validator(title, fieldName: "Struggle title")
            .notEmpty()
            .maxLength(200)

        let struggle = Struggle(context: viewContext)
        struggle.id = UUID()
        struggle.title = title
        struggle.category = category?.rawValue
        struggle.intensity = intensity.rawValue
        struggle.triggersList = triggers
        struggle.copingStrategiesList = copingStrategies
        struggle.notes = notes
        struggle.icon = icon ?? category?.icon
        struggle.isActive = true
        struggle.createdAt = Date()

        DataController.shared.save()
        return struggle
    }

    // MARK: - Read

    func fetch(activeOnly: Bool = true) -> [Struggle] {
        do {
            return try fetchOrThrow(activeOnly: activeOnly)
        } catch {
            return []
        }
    }

    func fetchOrThrow(activeOnly: Bool = true) throws -> [Struggle] {
        let request = NSFetchRequest<Struggle>(entityName: "Struggle")

        if activeOnly {
            request.predicate = NSPredicate(format: "isActive == YES")
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Struggle.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \Struggle.intensity, ascending: false),
            NSSortDescriptor(keyPath: \Struggle.createdAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    func fetchByCategory(_ category: Struggle.Category) -> [Struggle] {
        let request = NSFetchRequest<Struggle>(entityName: "Struggle")
        request.predicate = NSPredicate(format: "category == %@ AND isActive == YES", category.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Struggle.intensity, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    func fetchByIntensity(_ intensity: Struggle.Intensity) -> [Struggle] {
        let request = NSFetchRequest<Struggle>(entityName: "Struggle")
        request.predicate = NSPredicate(format: "intensity == %d AND isActive == YES", intensity.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Struggle.createdAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    func fetchResolved() -> [Struggle] {
        let request = NSFetchRequest<Struggle>(entityName: "Struggle")
        request.predicate = NSPredicate(format: "isActive == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Struggle.resolvedAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    func fetchHighIntensity() -> [Struggle] {
        let request = NSFetchRequest<Struggle>(entityName: "Struggle")
        request.predicate = NSPredicate(format: "isActive == YES AND intensity >= %d", Struggle.Intensity.severe.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Struggle.intensity, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    // MARK: - Update

    func update(_ struggle: Struggle) {
        DataController.shared.save()
    }

    func updateIntensity(_ struggle: Struggle, intensity: Struggle.Intensity) {
        struggle.intensityLevel = intensity
        DataController.shared.save()
    }

    func markResolved(_ struggle: Struggle) {
        struggle.markResolved()
        DataController.shared.save()
    }

    func reactivate(_ struggle: Struggle) {
        struggle.reactivate()
        DataController.shared.save()
    }

    func addTrigger(_ struggle: Struggle, trigger: String) {
        struggle.addTrigger(trigger)
        DataController.shared.save()
    }

    func addCopingStrategy(_ struggle: Struggle, strategy: String) {
        struggle.addCopingStrategy(strategy)
        DataController.shared.save()
    }

    func togglePin(_ struggle: Struggle) {
        struggle.togglePin()
        DataController.shared.save()
    }

    // MARK: - Delete

    func delete(_ struggle: Struggle) {
        viewContext.delete(struggle)
        DataController.shared.save()
    }
}

import CoreData
import Foundation

/// Repository for Goal CRUD operations
final class GoalRepository {
    static let shared = GoalRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Create

    func create(
        title: String,
        category: Goal.Category? = nil,
        priority: Goal.Priority = .medium,
        notes: String? = nil,
        icon: String? = nil,
        dueDate: Date? = nil
    ) throws -> Goal {
        try Validator(title, fieldName: "Goal title")
            .notEmpty()
            .maxLength(200)

        let goal = Goal(context: viewContext)
        goal.id = UUID()
        goal.title = title
        goal.category = category?.rawValue
        goal.priority = priority.rawValue
        goal.notes = notes
        goal.icon = icon ?? category?.icon
        goal.dueDate = dueDate
        goal.progress = 0.0
        goal.isCompleted = false
        goal.createdAt = Date()

        DataController.shared.save()
        return goal
    }

    // MARK: - Read

    func fetch(includeCompleted: Bool = false) -> [Goal] {
        do {
            return try fetchOrThrow(includeCompleted: includeCompleted)
        } catch {
            return []
        }
    }

    func fetchOrThrow(includeCompleted: Bool = false) throws -> [Goal] {
        let request = NSFetchRequest<Goal>(entityName: "Goal")

        if !includeCompleted {
            request.predicate = NSPredicate(format: "isCompleted == NO")
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Goal.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \Goal.priority, ascending: false),
            NSSortDescriptor(keyPath: \Goal.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Goal.createdAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    func fetchByCategory(_ category: Goal.Category) -> [Goal] {
        let request = NSFetchRequest<Goal>(entityName: "Goal")
        request.predicate = NSPredicate(format: "category == %@ AND isCompleted == NO", category.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Goal.priority, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    func fetchCompleted() -> [Goal] {
        let request = NSFetchRequest<Goal>(entityName: "Goal")
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Goal.completedAt, ascending: false)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    func fetchOverdue() -> [Goal] {
        let request = NSFetchRequest<Goal>(entityName: "Goal")
        request.predicate = NSPredicate(
            format: "isCompleted == NO AND dueDate != nil AND dueDate < %@",
            Date() as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Goal.dueDate, ascending: true)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    // MARK: - Update

    func update(_ goal: Goal) {
        DataController.shared.save()
    }

    func updateProgress(_ goal: Goal, progress: Double) {
        goal.updateProgress(progress)
        DataController.shared.save()
    }

    func markComplete(_ goal: Goal) {
        goal.markComplete()
        DataController.shared.save()
    }

    func markIncomplete(_ goal: Goal) {
        goal.markIncomplete()
        DataController.shared.save()
    }

    func togglePin(_ goal: Goal) {
        goal.togglePin()
        DataController.shared.save()
    }

    // MARK: - Delete

    func delete(_ goal: Goal) {
        viewContext.delete(goal)
        DataController.shared.save()
    }
}

import Foundation
import CoreData

@objc(Goal)
public class Goal: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String?
    @NSManaged public var category: String?
    @NSManaged public var icon: String?
    @NSManaged public var priority: Int16
    @NSManaged public var progress: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isPinned: Bool
    @NSManaged public var dueDate: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var completedAt: Date?

    // MARK: - Priority Level

    public enum Priority: Int16, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }

    // MARK: - Computed Properties

    public var priorityLevel: Priority {
        get { Priority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }

    public var displayIcon: String {
        icon ?? "flag.fill"
    }

    public var progressPercentage: Int {
        Int(progress * 100)
    }

    public var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    public var isDueSoon: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return dueDate <= threeDaysFromNow && dueDate >= Date()
    }

    public var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.title = ""
        self.priority = Priority.medium.rawValue
        self.progress = 0.0
        self.isCompleted = false
        self.isPinned = false
        self.createdAt = Date()
    }

    // MARK: - Pin Methods

    public func togglePin() {
        isPinned.toggle()
    }

    // MARK: - Methods

    public func markComplete() {
        isCompleted = true
        progress = 1.0
        completedAt = Date()
    }

    public func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }

    public func updateProgress(_ newProgress: Double) {
        progress = min(max(newProgress, 0.0), 1.0)
        if progress >= 1.0 {
            markComplete()
        }
    }
}

// MARK: - Goal Categories

extension Goal {
    public enum Category: String, CaseIterable {
        case personal = "Personal"
        case health = "Health"
        case social = "Social"
        case work = "Work/School"
        case skills = "Skills"
        case selfCare = "Self-Care"
        case routine = "Routine"
        case other = "Other"

        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .health: return "heart.fill"
            case .social: return "person.2.fill"
            case .work: return "briefcase.fill"
            case .skills: return "star.fill"
            case .selfCare: return "leaf.fill"
            case .routine: return "calendar"
            case .other: return "flag.fill"
            }
        }
    }

    public var categoryType: Category? {
        guard let category = category else { return nil }
        return Category(rawValue: category)
    }
}

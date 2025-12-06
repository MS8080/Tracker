import Foundation
import CoreData

@objc(WishlistItem)
public class WishlistItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String?
    @NSManaged public var category: String?
    @NSManaged public var icon: String?
    @NSManaged public var priority: Int16
    @NSManaged public var isAcquired: Bool
    @NSManaged public var createdAt: Date

    // MARK: - Priority Level

    public enum Priority: Int16, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3

        var displayName: String {
            switch self {
            case .low: return "Nice to Have"
            case .medium: return "Want"
            case .high: return "Really Want"
            }
        }

        var icon: String {
            switch self {
            case .low: return "star"
            case .medium: return "star.leadinghalf.filled"
            case .high: return "star.fill"
            }
        }
    }

    // MARK: - Computed Properties

    public var priorityLevel: Priority {
        get { Priority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }

    public var displayIcon: String {
        icon ?? "gift.fill"
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.title = ""
        self.priority = Priority.medium.rawValue
        self.isAcquired = false
        self.createdAt = Date()
    }

    // MARK: - Methods

    public func markAcquired() {
        isAcquired = true
    }

    public func markNotAcquired() {
        isAcquired = false
    }
}

// MARK: - Wishlist Categories

extension WishlistItem {
    public enum Category: String, CaseIterable {
        case sensory = "Sensory Items"
        case comfort = "Comfort Items"
        case hobby = "Hobby/Interest"
        case tech = "Technology"
        case books = "Books/Media"
        case clothing = "Clothing"
        case experience = "Experience"
        case other = "Other"

        var icon: String {
            switch self {
            case .sensory: return "hand.raised.fingers.spread.fill"
            case .comfort: return "house.fill"
            case .hobby: return "paintpalette.fill"
            case .tech: return "desktopcomputer"
            case .books: return "book.fill"
            case .clothing: return "tshirt.fill"
            case .experience: return "sparkles"
            case .other: return "gift.fill"
            }
        }
    }

    public var categoryType: Category? {
        guard let category = category else { return nil }
        return Category(rawValue: category)
    }
}

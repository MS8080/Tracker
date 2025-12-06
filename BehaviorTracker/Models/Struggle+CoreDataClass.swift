import Foundation
import CoreData

@objc(Struggle)
public class Struggle: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String?
    @NSManaged public var category: String?
    @NSManaged public var icon: String?
    @NSManaged public var intensity: Int16
    @NSManaged public var triggers: String?
    @NSManaged public var copingStrategies: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var isPinned: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var resolvedAt: Date?

    // MARK: - Intensity Level

    public enum Intensity: Int16, CaseIterable {
        case mild = 1
        case moderate = 2
        case significant = 3
        case severe = 4
        case overwhelming = 5

        var displayName: String {
            switch self {
            case .mild: return "Mild"
            case .moderate: return "Moderate"
            case .significant: return "Significant"
            case .severe: return "Severe"
            case .overwhelming: return "Overwhelming"
            }
        }

        var color: String {
            switch self {
            case .mild: return "green"
            case .moderate: return "yellow"
            case .significant: return "orange"
            case .severe: return "red"
            case .overwhelming: return "purple"
            }
        }
    }

    // MARK: - Computed Properties

    public var intensityLevel: Intensity {
        get { Intensity(rawValue: intensity) ?? .moderate }
        set { intensity = newValue.rawValue }
    }

    public var displayIcon: String {
        icon ?? "exclamationmark.triangle.fill"
    }

    public var triggersList: [String] {
        get {
            guard let triggers = triggers, !triggers.isEmpty else { return [] }
            return triggers.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            triggers = newValue.joined(separator: ", ")
        }
    }

    public var copingStrategiesList: [String] {
        get {
            guard let strategies = copingStrategies, !strategies.isEmpty else { return [] }
            return strategies.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            copingStrategies = newValue.joined(separator: ", ")
        }
    }

    public var durationSinceCreated: String {
        let components = Calendar.current.dateComponents([.day, .month], from: createdAt, to: Date())
        if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else if let days = components.day {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        return "Today"
    }

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.title = ""
        self.intensity = Intensity.moderate.rawValue
        self.isActive = true
        self.isPinned = false
        self.createdAt = Date()
    }

    // MARK: - Pin Methods

    public func togglePin() {
        isPinned.toggle()
    }

    // MARK: - Methods

    public func markResolved() {
        isActive = false
        resolvedAt = Date()
    }

    public func reactivate() {
        isActive = true
        resolvedAt = nil
    }

    public func addTrigger(_ trigger: String) {
        var list = triggersList
        if !list.contains(trigger) {
            list.append(trigger)
            triggersList = list
        }
    }

    public func addCopingStrategy(_ strategy: String) {
        var list = copingStrategiesList
        if !list.contains(strategy) {
            list.append(strategy)
            copingStrategiesList = list
        }
    }
}

// MARK: - Struggle Categories

extension Struggle {
    public enum Category: String, CaseIterable {
        case sensory = "Sensory"
        case social = "Social"
        case communication = "Communication"
        case executive = "Executive Function"
        case emotional = "Emotional Regulation"
        case routine = "Routine/Change"
        case overwhelm = "Overwhelm"
        case anxiety = "Anxiety"
        case physical = "Physical"
        case other = "Other"

        var icon: String {
            switch self {
            case .sensory: return "hand.raised.fingers.spread.fill"
            case .social: return "person.2.fill"
            case .communication: return "bubble.left.and.bubble.right.fill"
            case .executive: return "brain.head.profile"
            case .emotional: return "heart.fill"
            case .routine: return "arrow.triangle.2.circlepath"
            case .overwhelm: return "waveform.path.ecg"
            case .anxiety: return "bolt.heart.fill"
            case .physical: return "figure.walk"
            case .other: return "exclamationmark.triangle.fill"
            }
        }

        var description: String {
            switch self {
            case .sensory: return "Difficulties with sensory input (sounds, lights, textures)"
            case .social: return "Challenges in social situations and interactions"
            case .communication: return "Difficulties expressing or understanding communication"
            case .executive: return "Challenges with planning, organizing, and task management"
            case .emotional: return "Difficulties managing emotions and reactions"
            case .routine: return "Struggles with changes to routine or expectations"
            case .overwhelm: return "Feeling overwhelmed by stimuli or demands"
            case .anxiety: return "Anxiety-related challenges"
            case .physical: return "Physical symptoms or challenges"
            case .other: return "Other struggles not categorized above"
            }
        }
    }

    public var categoryType: Category? {
        guard let category = category else { return nil }
        return Category(rawValue: category)
    }
}

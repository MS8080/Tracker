import Foundation
import CoreData
import SwiftUI

// MARK: - Liquid Glass Support

extension SetupItemCategory {
    /// Glass tint color for Liquid Glass effects
    var glassTintColor: Color {
        switch self {
        case .medication: return .blue.opacity(0.3)
        case .supplement: return .green.opacity(0.3)
        case .activity: return .orange.opacity(0.3)
        case .accommodation: return .purple.opacity(0.3)
        }
    }
    
    /// Corner radius for glass effects
    var glassCornerRadius: CGFloat {
        return 16.0
    }
}

extension EffectTag {
    /// Glass tint color for effect tag badges
    var glassTintColor: Color {
        switch self {
        case .focus, .memory, .clarity, .neuroplasticity, .creativity:
            return .blue.opacity(0.2)
        case .energy, .motivation:
            return .orange.opacity(0.2)
        case .calmness, .mood, .stress:
            return .green.opacity(0.2)
        case .sleep, .recovery:
            return .indigo.opacity(0.2)
        case .inflammation, .immune, .digestion:
            return .pink.opacity(0.2)
        case .adhd, .anxiety, .sensory, .executive, .regulation:
            return .purple.opacity(0.2)
        }
    }
}

// MARK: - Setup Item Category

enum SetupItemCategory: String, CaseIterable, Codable, Identifiable {
    case medication = "Medication"
    case supplement = "Supplement"
    case activity = "Activity"
    case accommodation = "Accommodation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .medication: return "pills.fill"
        case .supplement: return "leaf.fill"
        case .activity: return "figure.run"
        case .accommodation: return "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .medication: return .blue
        case .supplement: return .green
        case .activity: return .orange
        case .accommodation: return .purple
        }
    }

    var description: String {
        switch self {
        case .medication: return "Prescription & OTC medications"
        case .supplement: return "Vitamins, minerals, herbal supplements"
        case .activity: return "Physical activity, cold showers, routines"
        case .accommodation: return "Environmental & sensory accommodations"
        }
    }
}

// MARK: - Common Effect Tags

enum EffectTag: String, CaseIterable {
    // Cognitive
    case focus = "Focus"
    case memory = "Memory"
    case clarity = "Clarity"
    case neuroplasticity = "Neuroplasticity"
    case creativity = "Creativity"

    // Energy & Mood
    case energy = "Energy"
    case calmness = "Calmness"
    case mood = "Mood"
    case motivation = "Motivation"
    case stress = "Stress Relief"

    // Physical
    case sleep = "Sleep"
    case recovery = "Recovery"
    case inflammation = "Inflammation"
    case immune = "Immune"
    case digestion = "Digestion"

    // Neurodivergent-specific
    case adhd = "ADHD"
    case anxiety = "Anxiety"
    case sensory = "Sensory"
    case executive = "Executive Function"
    case regulation = "Regulation"

    var icon: String {
        switch self {
        case .focus: return "eye"
        case .memory: return "brain"
        case .clarity: return "sparkles"
        case .neuroplasticity: return "arrow.triangle.branch"
        case .creativity: return "paintbrush"
        case .energy: return "bolt.fill"
        case .calmness: return "leaf"
        case .mood: return "face.smiling"
        case .motivation: return "flame"
        case .stress: return "wind"
        case .sleep: return "moon.fill"
        case .recovery: return "arrow.counterclockwise"
        case .inflammation: return "cross"
        case .immune: return "shield"
        case .digestion: return "stomach"
        case .adhd: return "brain.head.profile"
        case .anxiety: return "heart.circle"
        case .sensory: return "waveform"
        case .executive: return "list.bullet.clipboard"
        case .regulation: return "dial.low"
        }
    }

    var color: Color {
        switch self {
        case .focus, .memory, .clarity, .neuroplasticity, .creativity:
            return .blue
        case .energy, .motivation:
            return .orange
        case .calmness, .mood, .stress:
            return .green
        case .sleep, .recovery:
            return .indigo
        case .inflammation, .immune, .digestion:
            return .pink
        case .adhd, .anxiety, .sensory, .executive, .regulation:
            return .purple
        }
    }
}

// MARK: - SetupItem Extension

@objc(SetupItem)
public class SetupItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var category: String
    @NSManaged public var effectTags: String?
    @NSManaged public var icon: String?
    @NSManaged public var notes: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var startDate: Date?
}

extension SetupItem {
    var categoryEnum: SetupItemCategory? {
        SetupItemCategory(rawValue: category)
    }

    var displayIcon: String {
        icon ?? categoryEnum?.icon ?? "circle.fill"
    }

    var displayColor: Color {
        categoryEnum?.color ?? .gray
    }

    /// Get effect tags as array
    var effectTagsArray: [String] {
        guard let tags = effectTags, !tags.isEmpty else { return [] }
        return tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Set effect tags from array
    func setEffectTags(_ tags: [String]) {
        effectTags = tags.joined(separator: ", ")
    }

    /// Get formatted effect tags for display
    var formattedEffectTags: [String] {
        effectTagsArray
    }
}

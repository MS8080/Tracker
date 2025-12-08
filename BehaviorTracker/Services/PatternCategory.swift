import Foundation
import SwiftUI

/// Core categories for pattern tracking
/// Simplified to 7 meaningful categories
enum PatternCategory: String, CaseIterable, Codable {
    case energy = "Energy & Capacity"
    case sensory = "Sensory"
    case regulation = "Regulation"
    case social = "Social"
    case executive = "Executive Function"
    case demands = "Demands & Autonomy"
    case body = "Body & Routine"

    var icon: String {
        switch self {
        case .energy:
            return "battery.75percent"
        case .sensory:
            return "eye"
        case .regulation:
            return "waveform.path"
        case .social:
            return "person.2"
        case .executive:
            return "brain.head.profile"
        case .demands:
            return "hand.raised"
        case .body:
            return "figure.mind.and.body"
        }
    }

    var color: Color {
        switch self {
        case .energy:
            return .orange
        case .sensory:
            return .purple
        case .regulation:
            return .red
        case .social:
            return .green
        case .executive:
            return .blue
        case .demands:
            return .yellow
        case .body:
            return .cyan
        }
    }

    var description: String {
        switch self {
        case .energy:
            return "Spoons, burnout, recovery, capacity"
        case .sensory:
            return "Overload, comfort, seeking"
        case .regulation:
            return "Overwhelm, calm, stimming"
        case .social:
            return "Connection, masking, recovery"
        case .executive:
            return "Focus, time, decisions, tasks"
        case .demands:
            return "Internal, external, autonomy"
        case .body:
            return "Sleep, interoception, routine, physical"
        }
    }

    /// Maps old category names to new PatternCategory
    /// Used for backward compatibility with stored data
    static func from(legacyName: String) -> PatternCategory? {
        // First try direct match with rawValue
        if let direct = PatternCategory(rawValue: legacyName) {
            return direct
        }

        // Map old category names to new ones
        switch legacyName {
        case "Energy & Regulation", "Energy":
            return .energy
        case "Sensory":
            return .sensory
        case "Emotional Regulation", "Emotional":
            return .regulation
        case "Social & Communication", "Social":
            return .social
        case "Executive Function", "Focus & Attention":
            return .executive
        case "Demand Avoidance", "Demands":
            return .demands
        case "Physical & Sleep", "Body", "Routine & Change":
            return .body
        default:
            return nil
        }
    }

    /// Normalized category name for display (maps legacy to current)
    static func normalizedName(_ categoryName: String) -> String {
        if let category = from(legacyName: categoryName) {
            return category.rawValue
        }
        return categoryName
    }
}

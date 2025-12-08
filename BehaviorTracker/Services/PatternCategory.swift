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
}

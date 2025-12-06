import Foundation
import SwiftUI

/// Represents the main categories of patterns tracked
/// Simplified to 7 core categories for quick logging
enum PatternCategory: String, CaseIterable, Codable {
    case sensory = "Sensory"
    case executiveFunction = "Executive Function"
    case energyRegulation = "Energy & Regulation"
    case social = "Social & Communication"
    case routineChange = "Routine & Change"
    case demandAvoidance = "Demand Avoidance"
    case physicalWellbeing = "Physical & Sleep"
    case positiveCoping = "Positive & Coping"

    var icon: String {
        switch self {
        case .sensory:
            return "eye.circle"
        case .executiveFunction:
            return "brain.head.profile"
        case .energyRegulation:
            return "bolt.circle"
        case .social:
            return "person.2.circle"
        case .routineChange:
            return "calendar.circle"
        case .demandAvoidance:
            return "hand.raised.circle"
        case .physicalWellbeing:
            return "heart.circle"
        case .positiveCoping:
            return "sun.max.circle"
        }
    }

    var color: Color {
        switch self {
        case .sensory:
            return .purple
        case .executiveFunction:
            return .orange
        case .energyRegulation:
            return .red
        case .social:
            return .green
        case .routineChange:
            return .cyan
        case .demandAvoidance:
            return .yellow
        case .physicalWellbeing:
            return .indigo
        case .positiveCoping:
            return .mint
        }
    }

    var description: String {
        switch self {
        case .sensory:
            return "Overload, seeking, triggers, recovery"
        case .executiveFunction:
            return "Task struggles, hyperfocus, time blindness"
        case .energyRegulation:
            return "Masking, burnout, meltdowns, spoons"
        case .social:
            return "Interaction quality, masking level, recovery"
        case .routineChange:
            return "Disruptions, transitions, unexpected changes"
        case .demandAvoidance:
            return "Avoided tasks, autonomy needs"
        case .physicalWellbeing:
            return "Sleep, appetite, tension, digestion"
        case .positiveCoping:
            return "Wins, joy, calm, connection, progress"
        }
    }
}

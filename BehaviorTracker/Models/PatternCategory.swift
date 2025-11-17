import Foundation
import SwiftUI

/// Represents the main categories of behavioral patterns tracked
enum PatternCategory: String, CaseIterable, Codable {
    case behavioral = "Behavioral"
    case sensory = "Sensory"
    case socialCommunication = "Social/Communication"
    case executiveFunction = "Executive Function"
    case energyCapacity = "Energy/Capacity"
    case emotionalRegulation = "Emotional Regulation"
    case routineStructure = "Routine/Structure"
    case physical = "Physical"
    case contextual = "Contextual"

    var icon: String {
        switch self {
        case .behavioral:
            return "repeat.circle"
        case .sensory:
            return "eye.circle"
        case .socialCommunication:
            return "person.2.circle"
        case .executiveFunction:
            return "brain.head.profile"
        case .energyCapacity:
            return "bolt.circle"
        case .emotionalRegulation:
            return "heart.circle"
        case .routineStructure:
            return "calendar.circle"
        case .physical:
            return "figure.walk.circle"
        case .contextual:
            return "mappin.circle"
        }
    }

    var color: Color {
        switch self {
        case .behavioral:
            return .blue
        case .sensory:
            return .purple
        case .socialCommunication:
            return .green
        case .executiveFunction:
            return .orange
        case .energyCapacity:
            return .yellow
        case .emotionalRegulation:
            return .red
        case .routineStructure:
            return .cyan
        case .physical:
            return .indigo
        case .contextual:
            return .mint
        }
    }
}

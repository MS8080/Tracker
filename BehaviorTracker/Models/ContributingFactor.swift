import Foundation
import SwiftUI

/// Contributing factors that can accompany or worsen pattern experiences
enum ContributingFactor: String, CaseIterable, Codable {
    // Demand Avoidance
    case pda = "PDA (Pathological Demand Avoidance)"
    
    // Environmental
    case noise = "Noise"
    case lighting = "Lighting"
    case temperature = "Temperature"
    case crowding = "Crowding"
    case unfamiliarEnvironment = "Unfamiliar Environment"
    
    // Physical State
    case hunger = "Hunger"
    case thirst = "Thirst"
    case fatigue = "Fatigue"
    case pain = "Pain/Discomfort"
    case illness = "Illness"
    case poorSleep = "Poor Sleep"
    
    // Cognitive/Emotional
    case anxiety = "Anxiety"
    case stress = "Stress"
    case uncertainty = "Uncertainty"
    case timePressure = "Time Pressure"
    case decisionOverload = "Too Many Decisions"
    case informationOverload = "Information Overload"
    case alexithymia = "Can't Identify Feeling"
    case rejectionSensitivity = "Rejection Sensitivity"
    
    // Social
    case socialDemands = "Social Demands"
    case unexpectedInteraction = "Unexpected Interaction"
    case conflictTension = "Conflict/Tension"
    case masking = "Extended Masking"
    
    // Routine Disruption
    case routineChange = "Routine Change"
    case unexpectedChange = "Unexpected Change"
    case transitions = "Transitions"
    case waitingUncertainty = "Waiting/Uncertainty"
    
    // Other
    case medication = "Medication Effects"
    case hormonal = "Hormonal Changes"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .pda:
            return "exclamationmark.triangle"
        case .noise, .lighting, .temperature, .crowding, .unfamiliarEnvironment:
            return "sparkles"
        case .hunger, .thirst, .fatigue, .pain, .illness, .poorSleep:
            return "figure.stand"
        case .anxiety, .stress, .uncertainty, .timePressure, .decisionOverload, .informationOverload, .alexithymia, .rejectionSensitivity:
            return "brain"
        case .socialDemands, .unexpectedInteraction, .conflictTension, .masking:
            return "person.2"
        case .routineChange, .unexpectedChange, .transitions, .waitingUncertainty:
            return "arrow.triangle.2.circlepath"
        case .medication, .hormonal:
            return "pill"
        case .other:
            return "ellipsis.circle"
        }
    }
    
    var category: String {
        switch self {
        case .pda:
            return "Demand Avoidance"
        case .noise, .lighting, .temperature, .crowding, .unfamiliarEnvironment:
            return "Environmental"
        case .hunger, .thirst, .fatigue, .pain, .illness, .poorSleep:
            return "Physical State"
        case .anxiety, .stress, .uncertainty, .timePressure, .decisionOverload, .informationOverload, .alexithymia, .rejectionSensitivity:
            return "Cognitive/Emotional"
        case .socialDemands, .unexpectedInteraction, .conflictTension, .masking:
            return "Social"
        case .routineChange, .unexpectedChange, .transitions, .waitingUncertainty:
            return "Routine Disruption"
        case .medication, .hormonal, .other:
            return "Other"
        }
    }
    
    /// Group factors by their category for display
    static var groupedByCategory: [(category: String, factors: [ContributingFactor])] {
        let categories = ["Demand Avoidance", "Environmental", "Physical State", "Cognitive/Emotional", "Social", "Routine Disruption", "Other"]
        return categories.map { category in
            (category: category, factors: allCases.filter { $0.category == category })
        }
    }
}

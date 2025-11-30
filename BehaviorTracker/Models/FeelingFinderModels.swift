import SwiftUI

// MARK: - Data Models

struct FeelingFinderData {
    var generalFeeling: GeneralFeeling?
    var selectedFactors: Set<GuidedFactor> = []
    var environmentDetails: Set<String> = []
    var eventDetails: Set<String> = []
    var healthDetails: Set<String> = []
    var socialDetails: Set<String> = []
    var demandDetails: Set<String> = []
    var additionalText: String = ""
    var generatedEntry: String = ""
}

enum GeneralFeeling: String, CaseIterable, Identifiable {
    case irritated = "Irritated / Agitated"
    case sad = "Sad / Down"
    case anxious = "Anxious / On edge"
    case overwhelmed = "Overwhelmed / Too much"
    case empty = "Empty / Numb"
    case mixed = "Mixed / Confused"
    case other = "Something else I can't name"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .irritated: return "flame"
        case .sad: return "cloud.rain"
        case .anxious: return "bolt.heart"
        case .overwhelmed: return "tornado"
        case .empty: return "circle.dashed"
        case .mixed: return "arrow.triangle.2.circlepath"
        case .other: return "questionmark"
        }
    }

    var color: Color {
        switch self {
        case .irritated: return .red
        case .sad: return .blue
        case .anxious: return .orange
        case .overwhelmed: return .purple
        case .empty: return .gray
        case .mixed: return .cyan
        case .other: return .secondary
        }
    }
}

enum GuidedFactor: String, CaseIterable, Identifiable {
    case environment = "Environment"
    case event = "Specific event"
    case health = "Health / Body"
    case social = "Social / People"
    case demands = "Demands / Obligations"
    case notSure = "Not sure"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .environment: return "building.2"
        case .event: return "calendar.badge.exclamationmark"
        case .health: return "heart.text.square"
        case .social: return "person.2"
        case .demands: return "checklist"
        case .notSure: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .environment: return .cyan
        case .event: return .orange
        case .health: return .green
        case .social: return .purple
        case .demands: return .red
        case .notSure: return .gray
        }
    }

    /// Maps to the app's main logging categories
    var relatedCategories: [PatternCategory] {
        switch self {
        case .environment:
            return [.sensory]
        case .event:
            return [.routineChange, .energyRegulation]
        case .health:
            return [.physicalWellbeing, .energyRegulation]
        case .social:
            return [.social]
        case .demands:
            return [.demandAvoidance, .executiveFunction]
        case .notSure:
            return []
        }
    }
}

// MARK: - Detail Options

struct DetailOptions {
    static let environment = [
        "Bright or harsh lighting",
        "Noise level",
        "Too many people around",
        "Crowded or cluttered space",
        "Temperature uncomfortable",
        "Smells",
        "Been in same place too long"
    ]

    static let event = [
        "Upcoming exam or test",
        "Job interview",
        "Social invitation or gathering",
        "Family event or obligation",
        "Medical appointment",
        "Travel plans",
        "Deadline at work or school",
        "Public speaking or presentation",
        "Holiday or national event",
        "Anniversary or significant date",
        "Conflict or argument that happened",
        "Bad news received",
        "Waiting for results or answer",
        "Something unexpected happened"
    ]

    static let health = [
        "Heart racing or pounding",
        "Dizziness or lightheaded",
        "Nausea or stomach upset",
        "Muscle tension",
        "Headache or pressure",
        "Fatigue or heaviness",
        "Restlessness",
        "Sensory sensitivity",
        "Breathing feels off",
        "Haven't eaten or slept well"
    ]

    static let social = [
        "Recent difficult conversation",
        "Anticipating social interaction",
        "Feeling isolated or lonely",
        "Someone is upset with me",
        "I'm upset with someone",
        "Had to mask or pretend",
        "Feeling misunderstood",
        "Rejection or criticism"
    ]

    static let demands = [
        "Task I keep avoiding",
        "Too many things to do",
        "Someone expecting something from me",
        "Decision I need to make",
        "Pressure to be productive",
        "Responsibility I don't want"
    ]
}

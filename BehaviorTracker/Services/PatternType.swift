import Foundation

/// Specific pattern types within each category
enum PatternType: String, CaseIterable, Codable {
    
    // MARK: - Sensory
    case sensoryOverload = "Sensory Overload"
    case sensorySeeking = "Sensory Seeking/Stimming"
    case environmentalSensitivity = "Environmental Sensitivity"
    case sensoryRecovery = "Sensory Recovery Time"
    
    // MARK: - Executive Function
    case taskInitiation = "Task Initiation Difficulty"
    case taskSwitching = "Task Switching Challenge"
    case timeBlindness = "Time Blindness"
    case decisionFatigue = "Decision Fatigue"
    case hyperfocus = "Hyperfocus Session"
    
    // MARK: - Energy & Regulation
    case energyLevel = "Energy/Spoon Level"
    case maskingIntensity = "Masking Intensity"
    case burnoutIndicator = "Burnout Indicator"
    case meltdown = "Meltdown"
    case shutdown = "Shutdown"
    case regulatoryStimming = "Regulatory Stimming"
    
    // MARK: - Social & Communication
    case socialInteraction = "Social Interaction"
    case socialRecovery = "Social Recovery Needed"
    case miscommunication = "Miscommunication"
    case communicationDifficulty = "Communication Difficulty"
    case processingTime = "Processing Time Needed"
    
    // MARK: - Routine & Change
    case routineDisruption = "Routine Disruption"
    case transitionDifficulty = "Transition Difficulty"
    case unexpectedChange = "Unexpected Change"
    case samenessNeed = "Need for Sameness"
    
    // MARK: - Demand Avoidance
    case taskAvoidance = "Task Avoidance"
    case internalDemand = "Internal Demand Struggle"
    case externalDemand = "External Demand Struggle"
    case autonomyNeed = "Autonomy Need"
    case avoidanceStrategy = "What Helped Complete Task"
    
    // MARK: - Physical & Sleep
    case sleepQuality = "Sleep Quality"
    case appetiteChange = "Appetite Change"
    case physicalTension = "Physical Tension/Pain"
    case digestiveIssue = "Digestive Issue"
    
    // MARK: - Special Interests (bonus - fits with regulation)
    case specialInterest = "Special Interest Engagement"
    case disengagementDifficulty = "Difficulty Disengaging"

    var category: PatternCategory {
        switch self {
        case .sensoryOverload, .sensorySeeking, .environmentalSensitivity, .sensoryRecovery:
            return .sensory
        case .taskInitiation, .taskSwitching, .timeBlindness, .decisionFatigue, .hyperfocus:
            return .executiveFunction
        case .energyLevel, .maskingIntensity, .burnoutIndicator, .meltdown, .shutdown, .regulatoryStimming:
            return .energyRegulation
        case .socialInteraction, .socialRecovery, .miscommunication, .communicationDifficulty, .processingTime:
            return .social
        case .routineDisruption, .transitionDifficulty, .unexpectedChange, .samenessNeed:
            return .routineChange
        case .taskAvoidance, .internalDemand, .externalDemand, .autonomyNeed, .avoidanceStrategy:
            return .demandAvoidance
        case .sleepQuality, .appetiteChange, .physicalTension, .digestiveIssue:
            return .physicalWellbeing
        case .specialInterest, .disengagementDifficulty:
            return .energyRegulation
        }
    }

    /// Whether this pattern should have an intensity scale (1-5)
    var hasIntensityScale: Bool {
        switch self {
        case .sensoryOverload, .environmentalSensitivity, .energyLevel, .maskingIntensity, 
             .burnoutIndicator, .meltdown, .shutdown, .socialInteraction, .socialRecovery,
             .routineDisruption, .unexpectedChange, .taskAvoidance, .internalDemand, 
             .externalDemand, .autonomyNeed, .sleepQuality, .physicalTension, .specialInterest,
             .decisionFatigue, .samenessNeed:
            return true
        default:
            return false
        }
    }

    /// Whether this pattern should track duration
    var hasDuration: Bool {
        switch self {
        case .sensoryRecovery, .hyperfocus, .meltdown, .shutdown, .socialInteraction,
             .socialRecovery, .processingTime, .specialInterest, .regulatoryStimming:
            return true
        default:
            return false
        }
    }
    
    /// Placeholder text for specific details field
    var detailsPlaceholder: String {
        switch self {
        case .sensoryOverload:
            return "What triggered it? (noise, lights, textures, smells)"
        case .sensorySeeking:
            return "Type of stimming or seeking behavior"
        case .environmentalSensitivity:
            return "What in the environment bothered you?"
        case .sensoryRecovery:
            return "What helped you recover?"
        case .taskInitiation:
            return "What task? What time of day?"
        case .taskSwitching:
            return "What tasks were you switching between?"
        case .timeBlindness:
            return "What were you doing? How much time passed?"
        case .decisionFatigue:
            return "What decisions were overwhelming?"
        case .hyperfocus:
            return "What triggered it? How did you exit?"
        case .energyLevel:
            return "Note what affected your energy"
        case .maskingIntensity:
            return "What social situation required masking?"
        case .burnoutIndicator:
            return "What exhaustion signs are you noticing?"
        case .meltdown, .shutdown:
            return "What were the precursors?"
        case .regulatoryStimming:
            return "What type of stimming? Did it help?"
        case .socialInteraction:
            return "Draining or energizing? With whom?"
        case .socialRecovery:
            return "What helped you recover?"
        case .miscommunication:
            return "What was misunderstood?"
        case .communicationDifficulty:
            return "Phone, email, in-person? What was hard?"
        case .processingTime:
            return "What conversation or information?"
        case .routineDisruption:
            return "What was disrupted? How did you respond?"
        case .transitionDifficulty:
            return "What transition was difficult?"
        case .unexpectedChange:
            return "What changed? How did it affect you?"
        case .samenessNeed:
            return "What did you need to stay the same?"
        case .taskAvoidance:
            return "What task? Why do you think you avoided it?"
        case .internalDemand:
            return "What internal expectation was difficult?"
        case .externalDemand:
            return "Who/what demanded something of you?"
        case .autonomyNeed:
            return "What autonomy did you need?"
        case .avoidanceStrategy:
            return "What finally helped you complete the task?"
        case .sleepQuality:
            return "Hours slept, quality, disturbances"
        case .appetiteChange:
            return "Eating more/less? Specific cravings?"
        case .physicalTension:
            return "Where? (jaw, shoulders, etc.)"
        case .digestiveIssue:
            return "What symptoms?"
        case .specialInterest:
            return "What interest? How did it affect your mood?"
        case .disengagementDifficulty:
            return "What couldn't you stop doing?"
        }
    }
    
    /// Quick-tap friendly patterns that are common daily logs
    static var quickLogPatterns: [PatternType] {
        [
            .energyLevel,
            .sensoryOverload,
            .maskingIntensity,
            .taskAvoidance,
            .sleepQuality,
            .socialInteraction
        ]
    }
}

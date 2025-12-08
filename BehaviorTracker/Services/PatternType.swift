import Foundation

/// Refined pattern types - bidirectional where possible
/// Reduced from 50 to 25 core patterns that capture the full autistic experience
enum PatternType: String, CaseIterable, Codable {

    // MARK: - Energy & Capacity (4)
    case energyLevel = "Energy Level"              // 1=depleted, 5=abundant
    case burnout = "Burnout Signs"                 // Exhaustion indicators
    case recovery = "Recovery"                     // Rest, recharge, what helped
    case capacity = "Capacity Check"               // How much can you handle today

    // MARK: - Sensory (3)
    case sensoryState = "Sensory State"            // 1=overloaded, 5=comfortable
    case sensorySeeking = "Sensory Seeking"        // Stimming, seeking input
    case sensoryEnvironment = "Environment"        // What's affecting you

    // MARK: - Regulation (4)
    case overwhelm = "Overwhelm"                   // Meltdown, shutdown, emotional flood
    case regulation = "Regulation State"           // 1=dysregulated, 5=grounded
    case stimming = "Stimming"                     // Regulatory movement/behavior
    case rumination = "Thought Loops"              // Repetitive thoughts, stuck thinking

    // MARK: - Social (4)
    case socialEnergy = "Social Energy"            // 1=drained, 5=connected
    case masking = "Masking"                       // How much you're performing
    case socialRecovery = "Social Recovery"        // Time/space needed after interaction
    case connection = "Connection"                 // Genuine moments of understanding

    // MARK: - Executive Function (4)
    case focus = "Focus"                           // Hyperfocus, scattered, flow state
    case taskInitiation = "Starting Tasks"         // Getting going difficulty
    case timeAwareness = "Time Awareness"          // Blindness, lost track, managed well
    case decisions = "Decision Making"             // Fatigue, clarity, overwhelm

    // MARK: - Demands & Autonomy (3)
    case demandResponse = "Demand Response"        // How demands feel/how you responded
    case autonomy = "Autonomy"                     // Need for control, choice
    case avoidance = "Avoidance"                   // What you're avoiding and why

    // MARK: - Body & Routine (3)
    case bodySignals = "Body Signals"              // Interoception - hunger, pain, needs
    case sleep = "Sleep"                           // Quality, duration, disturbances
    case routineChange = "Routine/Change"          // Disruption, transition, unexpected

    // MARK: - Category Mapping

    var category: PatternCategory {
        switch self {
        case .energyLevel, .burnout, .recovery, .capacity:
            return .energy
        case .sensoryState, .sensorySeeking, .sensoryEnvironment:
            return .sensory
        case .overwhelm, .regulation, .stimming, .rumination:
            return .regulation
        case .socialEnergy, .masking, .socialRecovery, .connection:
            return .social
        case .focus, .taskInitiation, .timeAwareness, .decisions:
            return .executive
        case .demandResponse, .autonomy, .avoidance:
            return .demands
        case .bodySignals, .sleep, .routineChange:
            return .body
        }
    }

    // MARK: - Bidirectional Patterns (use 1-5 scale both ways)

    /// Whether this pattern uses a bidirectional scale (1=struggle, 5=thriving)
    var isBidirectional: Bool {
        switch self {
        case .energyLevel, .sensoryState, .regulation, .socialEnergy, .focus, .timeAwareness:
            return true
        default:
            return false
        }
    }

    /// Scale labels for bidirectional patterns
    var scaleLabels: (low: String, high: String)? {
        switch self {
        case .energyLevel:
            return ("Depleted", "Abundant")
        case .sensoryState:
            return ("Overloaded", "Comfortable")
        case .regulation:
            return ("Dysregulated", "Grounded")
        case .socialEnergy:
            return ("Drained", "Connected")
        case .focus:
            return ("Scattered", "Flow")
        case .timeAwareness:
            return ("Lost", "Aware")
        default:
            return nil
        }
    }

    /// Whether this pattern should have an intensity scale (1-5)
    var hasIntensityScale: Bool {
        switch self {
        case .energyLevel, .sensoryState, .regulation, .socialEnergy, .focus,
             .timeAwareness, .burnout, .overwhelm, .masking, .decisions,
             .demandResponse, .avoidance, .sleep, .capacity:
            return true
        default:
            return false
        }
    }

    /// Whether this pattern should track duration
    var hasDuration: Bool {
        switch self {
        case .overwhelm, .recovery, .socialRecovery, .focus, .stimming, .rumination:
            return true
        default:
            return false
        }
    }

    /// Placeholder text for specific details field
    var detailsPlaceholder: String {
        switch self {
        // Energy
        case .energyLevel:
            return "What's affecting your energy?"
        case .burnout:
            return "What signs are you noticing?"
        case .recovery:
            return "What helped? How long did it take?"
        case .capacity:
            return "What can/can't you handle today?"

        // Sensory
        case .sensoryState:
            return "What's contributing to this state?"
        case .sensorySeeking:
            return "What input are you seeking? Does it help?"
        case .sensoryEnvironment:
            return "What in your environment is affecting you?"

        // Regulation
        case .overwhelm:
            return "Meltdown, shutdown, or emotional? What preceded it?"
        case .regulation:
            return "What's helping or hurting your regulation?"
        case .stimming:
            return "What type? Is it helping?"
        case .rumination:
            return "What thoughts are looping? What triggered it?"

        // Social
        case .socialEnergy:
            return "Who were you with? Draining or energizing?"
        case .masking:
            return "What situation? How exhausting was it?"
        case .socialRecovery:
            return "How much time/space do you need?"
        case .connection:
            return "What made this moment feel genuine?"

        // Executive
        case .focus:
            return "Hyperfocus, flow, or scattered? On what?"
        case .taskInitiation:
            return "What task? What's blocking you?"
        case .timeAwareness:
            return "Lost track? Or managed time well?"
        case .decisions:
            return "What decisions? Overwhelming or manageable?"

        // Demands
        case .demandResponse:
            return "Internal or external demand? How did you respond?"
        case .autonomy:
            return "What choice/control do you need?"
        case .avoidance:
            return "What are you avoiding? Why do you think?"

        // Body & Routine
        case .bodySignals:
            return "Missed hunger, pain, bathroom? Or tuned in?"
        case .sleep:
            return "Hours, quality, what affected it?"
        case .routineChange:
            return "What changed? Expected or unexpected?"
        }
    }

    /// Quick-tap patterns for daily logging
    static var quickLogPatterns: [PatternType] {
        [
            .energyLevel,
            .sensoryState,
            .regulation,
            .socialEnergy,
            .focus,
            .sleep
        ]
    }

    /// Patterns that indicate struggles (for analysis)
    static var strugglePatterns: [PatternType] {
        [.burnout, .overwhelm, .rumination, .avoidance]
    }

    /// Patterns that indicate wins (for analysis)
    static var positivePatterns: [PatternType] {
        [.recovery, .connection, .stimming]
    }
}

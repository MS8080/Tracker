import Foundation

/// Pattern bank definition for AI analysis
/// Refined to 25 core patterns that capture the full autistic experience
enum PatternBank {

    /// Full pattern bank prompt to embed in AI requests
    static let prompt = """
    You are an expert ASD/PDA pattern analyst. Analyze journal entries to extract behavioral patterns.

    PATTERN CATEGORIES AND TYPES (25 core patterns):

    === ENERGY & CAPACITY ===
    - Energy Level: overall energy/spoons (rate 1=depleted to 5=abundant)
    - Burnout Signs: prolonged exhaustion, loss of skills, everything harder
    - Recovery: rest, recharge, what helped restore energy
    - Capacity Check: how much can be handled today, limits awareness

    === SENSORY ===
    - Sensory State: overall sensory experience (rate 1=overloaded to 5=comfortable)
    - Sensory Seeking: stimming, seeking specific input, pressure/movement needs
    - Environment: environmental factors affecting wellbeing (noise, light, temp, smells)

    === REGULATION ===
    - Overwhelm: meltdown, shutdown, or emotional flooding (note which type)
    - Regulation State: emotional/nervous system state (rate 1=dysregulated to 5=grounded)
    - Stimming: regulatory movement/behavior, self-soothing
    - Thought Loops: rumination, repetitive thoughts, mental stuck points

    === SOCIAL ===
    - Social Energy: effect of social interaction (rate 1=drained to 5=connected)
    - Masking: performing neurotypical, hiding autistic traits, exhaustion from pretending
    - Social Recovery: time/space needed after interaction, alone time requirement
    - Connection: genuine moments of understanding, felt seen/heard

    === EXECUTIVE FUNCTION ===
    - Focus: attention state - scattered, hyperfocus, or flow (rate 1=scattered to 5=flow)
    - Starting Tasks: task initiation difficulty, paralysis, can't begin
    - Time Awareness: time perception (rate 1=lost track to 5=well managed)
    - Decision Making: choice overwhelm or clarity

    === DEMANDS & AUTONOMY ===
    - Demand Response: how demands (internal or external) feel and how responded
    - Autonomy: need for control, choice, resistance when autonomy threatened
    - Avoidance: what's being avoided and underlying reason

    === BODY & ROUTINE ===
    - Body Signals: interoception - noticing or missing hunger, pain, bathroom, temperature
    - Sleep: quality, duration, disturbances, factors affecting sleep
    - Routine/Change: routine disruption, transitions, unexpected changes

    ---

    ANALYSIS INSTRUCTIONS:

    CRITICAL RULES:
    - ONLY identify patterns that are EXPLICITLY described in the entry
    - DO NOT infer, assume, or speculate about patterns not clearly stated
    - For BIDIRECTIONAL patterns, note where on the spectrum (1-5)
    - Be CONSERVATIVE - fewer accurate patterns are better than many guessed ones
    - The entry describes ONE person's experience - understand their perspective

    BIDIRECTIONAL PATTERNS (capture both struggle AND thriving):
    These patterns use a 1-5 scale where both ends are meaningful:
    - Energy Level: 1=depleted ↔ 5=abundant
    - Sensory State: 1=overloaded ↔ 5=comfortable
    - Regulation State: 1=dysregulated ↔ 5=grounded
    - Social Energy: 1=drained ↔ 5=connected
    - Focus: 1=scattered ↔ 5=flow
    - Time Awareness: 1=lost ↔ 5=aware

    For these, a "5" is a WIN worth noting, not just absence of struggle.

    1. Read the journal entry carefully
    2. Identify patterns that are clearly present
    3. For bidirectional patterns, determine where on the 1-5 scale
    4. For other patterns, note intensity (1-10 scale)
    5. Only include triggers EXPLICITLY mentioned
    6. Note context only from what's stated

    DISTINGUISH USER INSIGHTS:
    When the user shows self-awareness ("I noticed", "I realized", "I think it's because"):
    - Mark is_user_insight=true
    - Capture their insight in user_insight_text
    - This builds on what user already understands

    DETAILS FORMAT:
    Write details in first-person observation style. Examples:
    - "Noticed feeling drained after the meeting"
    - "Experienced difficulty starting the task"
    - "Felt overwhelmed by the noise level"
    Do NOT use "User describes..." or "User reports..." - write as observations.

    ---

    RESPONSE FORMAT:

    Return ONLY valid JSON:

    {
      "patterns": [
        {
          "type": "Pattern Type Name",
          "category": "Category Name",
          "intensity": 7,
          "triggers": ["trigger1"],
          "time_of_day": "morning|afternoon|evening|night|unknown",
          "coping_used": ["strategy1"],
          "details": "brief first-person observation (e.g., 'Noticed feeling drained after...' or 'Experienced difficulty with...')",
          "is_user_insight": false,
          "user_insight_text": null
        }
      ],
      "cascades": [
        {
          "from": "Pattern Type Name",
          "to": "Pattern Type Name",
          "confidence": 0.85,
          "description": "how one led to the other"
        }
      ],
      "triggers": ["overall triggers"],
      "context": {
        "time_of_day": "morning|afternoon|evening|night|unknown",
        "location": "home|work|public|social|unknown",
        "social_context": "alone|with_family|with_friends|with_strangers|at_work|unknown",
        "sleep_mentioned": true|false,
        "medication_mentioned": true|false
      },
      "overall_intensity": 6,
      "confidence": 0.8,
      "summary": "One sentence summary"
    }

    VALID PATTERN NAMES (use exactly):
    Energy Level, Burnout Signs, Recovery, Capacity Check,
    Sensory State, Sensory Seeking, Environment,
    Overwhelm, Regulation State, Stimming, Thought Loops,
    Social Energy, Masking, Social Recovery, Connection,
    Focus, Starting Tasks, Time Awareness, Decision Making,
    Demand Response, Autonomy, Avoidance,
    Body Signals, Sleep, Routine/Change

    Always return valid JSON, nothing else.
    """

    /// Mapping from AI response pattern names to PatternType enum
    static let patternTypeMapping: [String: PatternType] = [
        // Energy & Capacity
        "Energy Level": .energyLevel,
        "Burnout Signs": .burnout,
        "Recovery": .recovery,
        "Capacity Check": .capacity,

        // Sensory
        "Sensory State": .sensoryState,
        "Sensory Seeking": .sensorySeeking,
        "Environment": .sensoryEnvironment,

        // Regulation
        "Overwhelm": .overwhelm,
        "Regulation State": .regulation,
        "Stimming": .stimming,
        "Thought Loops": .rumination,

        // Social
        "Social Energy": .socialEnergy,
        "Masking": .masking,
        "Social Recovery": .socialRecovery,
        "Connection": .connection,

        // Executive Function
        "Focus": .focus,
        "Starting Tasks": .taskInitiation,
        "Time Awareness": .timeAwareness,
        "Decision Making": .decisions,

        // Demands & Autonomy
        "Demand Response": .demandResponse,
        "Autonomy": .autonomy,
        "Avoidance": .avoidance,

        // Body & Routine
        "Body Signals": .bodySignals,
        "Sleep": .sleep,
        "Routine/Change": .routineChange
    ]

    /// Legacy mapping for backward compatibility with existing data
    static let legacyPatternMapping: [String: PatternType] = [
        // Map old pattern names to new ones
        "Sensory Overload": .sensoryState,
        "Environmental Sensitivity": .sensoryEnvironment,
        "Sensory Recovery Time": .recovery,
        "Sensory Seeking/Stimming": .sensorySeeking,
        "Task Initiation Difficulty": .taskInitiation,
        "Task Switching Challenge": .taskInitiation,
        "Time Blindness": .timeAwareness,
        "Decision Fatigue": .decisions,
        "Hyperfocus Session": .focus,
        "Energy/Spoon Level": .energyLevel,
        "Masking Intensity": .masking,
        "Burnout Indicator": .burnout,
        "Meltdown": .overwhelm,
        "Shutdown": .overwhelm,
        "Regulatory Stimming": .stimming,
        "Emotional Overwhelm": .overwhelm,
        "Rumination/Thought Loops": .rumination,
        "Flow State Achieved": .focus,
        "Authenticity Moment": .connection,
        "Social Interaction": .socialEnergy,
        "Social Recovery Needed": .socialRecovery,
        "Miscommunication": .socialEnergy,
        "Communication Difficulty": .socialEnergy,
        "Processing Time Needed": .socialRecovery,
        "Routine Disruption": .routineChange,
        "Transition Difficulty": .routineChange,
        "Unexpected Change": .routineChange,
        "Need for Sameness": .routineChange,
        "Uncertainty Intolerance": .routineChange,
        "Task Avoidance": .avoidance,
        "Internal Demand Struggle": .demandResponse,
        "External Demand Struggle": .demandResponse,
        "Autonomy Need": .autonomy,
        "What Helped Complete Task": .recovery,
        "Sleep Quality": .sleep,
        "Appetite Change": .bodySignals,
        "Physical Tension/Pain": .bodySignals,
        "Digestive Issue": .bodySignals,
        "Special Interest Engagement": .focus,
        "Difficulty Disengaging": .focus,
        "Successful Coping": .recovery,
        "Calm/Regulated State": .regulation,
        "Connection Moment": .connection,
        "Rest/Recovery Success": .recovery,
        "Sensory Comfort": .sensoryState,
        "Boundary Setting": .autonomy,
        "Self-Compassion": .regulation,
        "Accommodation Win": .recovery,
        "Joy/Happiness": .connection,
        "Achievement/Progress": .recovery
    ]

    /// Get PatternType from AI response string (checks both new and legacy mappings)
    static func patternType(from string: String) -> PatternType? {
        return patternTypeMapping[string] ?? legacyPatternMapping[string]
    }

    /// All valid pattern type names for validation
    static var validPatternNames: Set<String> {
        Set(patternTypeMapping.keys)
    }
}

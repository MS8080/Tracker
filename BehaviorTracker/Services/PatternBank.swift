import Foundation

/// Pattern bank definition for AI analysis
/// This defines all ASD/PDA patterns the AI should recognize and match
enum PatternBank {

    /// Full pattern bank prompt to embed in AI requests
    static let prompt = """
    You are an expert ASD/PDA pattern analyst. Analyze journal entries to extract behavioral patterns.

    PATTERN CATEGORIES AND TYPES:

    === SENSORY ===
    - Sensory Overload: overwhelmed by sensory input, too much noise/light/touch/smell, need to escape
    - Sensory Seeking/Stimming: seeking specific sensory input, stimming behaviors, pressure seeking
    - Environmental Sensitivity: bothered by environment, temperature, lighting, sounds, smells
    - Sensory Recovery Time: needing quiet/dark/alone time after sensory events

    === EXECUTIVE FUNCTION ===
    - Task Initiation Difficulty: can't start tasks, paralysis, knowing what to do but unable to begin
    - Task Switching Challenge: difficulty changing activities, stuck on one thing, can't transition
    - Time Blindness: losing track of time, surprised by how much time passed, always late
    - Decision Fatigue: overwhelmed by choices, can't decide, exhausted from decisions
    - Hyperfocus Session: deep focus on one thing, losing awareness of surroundings/time/needs

    === ENERGY & REGULATION ===
    - Energy/Spoon Level: overall energy, capacity for tasks, spoon theory reference
    - Masking Intensity: hiding autistic traits, performing neurotypical, exhaustion from pretending
    - Burnout Indicator: prolonged exhaustion, loss of skills, everything harder than usual
    - Meltdown: emotional explosion, loss of control, intense overwhelm expressed outward
    - Shutdown: going nonverbal, withdrawing, freezing, unable to respond or function
    - Regulatory Stimming: stimming to regulate, self-soothing behaviors
    - Emotional Overwhelm: intense emotions, can't process feelings, emotional flooding
    - Rumination/Thought Loops: repetitive thoughts, can't stop thinking about something, mental loops
    - Flow State Achieved: positive hyperfocus, productive, in the zone
    - Authenticity Moment: feeling genuine, unmasked, comfortable being self

    === SOCIAL & COMMUNICATION ===
    - Social Interaction: any social contact, meeting people, conversations
    - Social Recovery Needed: exhausted after socializing, need alone time
    - Miscommunication: being misunderstood, misunderstanding others, unclear communication
    - Communication Difficulty: hard to express thoughts, word finding, phone anxiety
    - Processing Time Needed: need extra time to understand, delayed processing

    === ROUTINE & CHANGE ===
    - Routine Disruption: schedule changed, routine broken, unexpected events
    - Transition Difficulty: hard time moving between activities or places
    - Unexpected Change: plans changed, surprises, things not as expected
    - Need for Sameness: wanting things to stay the same, comfort in routine
    - Uncertainty Intolerance: anxiety about unknown, can't handle not knowing, need certainty

    === DEMAND AVOIDANCE (PDA) ===
    - Task Avoidance: avoiding tasks, procrastination driven by demand, resistance
    - Internal Demand Struggle: own expectations feel like demands, self-imposed pressure
    - External Demand Struggle: others' requests/expectations feel overwhelming
    - Autonomy Need: need for control, resistance when autonomy threatened
    - What Helped Complete Task: strategies that worked to overcome avoidance

    === PHYSICAL & SLEEP ===
    - Sleep Quality: how well slept, insomnia, sleep disturbances
    - Appetite Change: eating more/less, food aversions, sensory food issues
    - Physical Tension/Pain: body tension, headaches, jaw clenching, physical stress
    - Digestive Issue: stomach problems, often stress-related

    === SPECIAL INTERESTS ===
    - Special Interest Engagement: time with special interest, joy from focused interest
    - Difficulty Disengaging: can't stop activity, unable to transition away

    === POSITIVE & COPING ===
    - Successful Coping: used a strategy that worked, managed a difficult situation well
    - Calm/Regulated State: feeling balanced, peaceful, in control, grounded
    - Connection Moment: positive social interaction, felt understood, meaningful connection
    - Rest/Recovery Success: good rest, successful recharge, feeling restored
    - Sensory Comfort: found sensory environment pleasant, comfortable, soothing
    - Boundary Setting: successfully set a limit, said no, protected own needs
    - Self-Compassion: was kind to self, accepted limitations, didn't judge harshly
    - Accommodation Win: an accommodation or adjustment worked well, felt supported
    - Joy/Happiness: genuine positive emotion, contentment, gratitude
    - Achievement/Progress: completed something, made progress, felt accomplished

    ---

    ANALYSIS INSTRUCTIONS:

    CRITICAL RULES:
    - ONLY identify patterns that are EXPLICITLY described in the entry
    - DO NOT infer, assume, or speculate about patterns not clearly stated
    - DO NOT mix up events or timelines - each entry is a single moment/event
    - If something is ambiguous, DO NOT include it as a pattern
    - Be CONSERVATIVE - fewer accurate patterns are better than many inaccurate ones
    - The entry describes ONE person's experience at ONE point in time

    1. Read the journal entry carefully - understand EXACTLY what happened
    2. Identify ONLY patterns that are clearly present (don't reach or infer)
    3. For each pattern, determine:
       - The exact pattern type from the list above
       - Intensity (1-10 scale) based on language used
       - Only triggers EXPLICITLY mentioned
       - Time of day ONLY if stated
       - Coping strategies ONLY if described

    4. DISTINGUISH USER INSIGHTS FROM OBSERVED PATTERNS:
       - User insight: When the user shows self-awareness about their patterns
         Look for phrases like: "I noticed", "I think", "I realized", "maybe it's because",
         "I wonder if", "it seems like", "I've figured out", "I understand now"
       - Mark is_user_insight=true when the user is analyzing their own behavior
       - Include their exact insight in user_insight_text
       - This helps us build on what the user already understands rather than restating it

    5. Identify CASCADES - ONLY if the entry explicitly shows one pattern leading to another:
       - The connection must be clear in the text
       - DO NOT assume cascades that aren't described
       - Include confidence score (0.0-1.0) for each connection

    6. Extract ONLY triggers that are explicitly mentioned in the text

    7. Note context ONLY from what's explicitly stated

    ---

    RESPONSE FORMAT:

    Return ONLY valid JSON with this exact structure:

    {
      "patterns": [
        {
          "type": "Pattern Type Name",
          "category": "Category Name",
          "intensity": 7,
          "triggers": ["trigger1", "trigger2"],
          "time_of_day": "morning|afternoon|evening|night|unknown",
          "coping_used": ["strategy1"],
          "details": "brief description of how this manifested",
          "is_user_insight": false,
          "user_insight_text": null
        }
      ],
      "cascades": [
        {
          "from": "Pattern Type Name",
          "to": "Pattern Type Name",
          "confidence": 0.85,
          "description": "brief explanation of the connection"
        }
      ],
      "triggers": ["overall trigger1", "overall trigger2"],
      "context": {
        "time_of_day": "morning|afternoon|evening|night|unknown",
        "location": "home|work|public|social|unknown",
        "social_context": "alone|with_family|with_friends|with_strangers|at_work|unknown",
        "sleep_mentioned": true|false,
        "medication_mentioned": true|false
      },
      "overall_intensity": 6,
      "confidence": 0.8,
      "summary": "One sentence summary of the entry's main theme"
    }

    IMPORTANT:
    - Use EXACT pattern type names from the list above
    - If no patterns found, return empty arrays
    - If uncertain about a pattern, DO NOT include it - accuracy over quantity
    - DO NOT speculate or infer - only extract what's explicitly written
    - Each entry is about ONE moment in time - don't create multiple timeline interpretations
    - Always return valid JSON, nothing else
    """

    /// Mapping from AI response pattern names to PatternType enum
    static let patternTypeMapping: [String: PatternType] = [
        "Sensory Overload": .sensoryOverload,
        "Sensory Seeking/Stimming": .sensorySeeking,
        "Environmental Sensitivity": .environmentalSensitivity,
        "Sensory Recovery Time": .sensoryRecovery,
        "Task Initiation Difficulty": .taskInitiation,
        "Task Switching Challenge": .taskSwitching,
        "Time Blindness": .timeBlindness,
        "Decision Fatigue": .decisionFatigue,
        "Hyperfocus Session": .hyperfocus,
        "Energy/Spoon Level": .energyLevel,
        "Masking Intensity": .maskingIntensity,
        "Burnout Indicator": .burnoutIndicator,
        "Meltdown": .meltdown,
        "Shutdown": .shutdown,
        "Regulatory Stimming": .regulatoryStimming,
        "Emotional Overwhelm": .emotionalOverwhelm,
        "Rumination/Thought Loops": .rumination,
        "Flow State Achieved": .flowState,
        "Authenticity Moment": .authenticityMoment,
        "Social Interaction": .socialInteraction,
        "Social Recovery Needed": .socialRecovery,
        "Miscommunication": .miscommunication,
        "Communication Difficulty": .communicationDifficulty,
        "Processing Time Needed": .processingTime,
        "Routine Disruption": .routineDisruption,
        "Transition Difficulty": .transitionDifficulty,
        "Unexpected Change": .unexpectedChange,
        "Need for Sameness": .samenessNeed,
        "Uncertainty Intolerance": .uncertaintyIntolerance,
        "Task Avoidance": .taskAvoidance,
        "Internal Demand Struggle": .internalDemand,
        "External Demand Struggle": .externalDemand,
        "Autonomy Need": .autonomyNeed,
        "What Helped Complete Task": .avoidanceStrategy,
        "Sleep Quality": .sleepQuality,
        "Appetite Change": .appetiteChange,
        "Physical Tension/Pain": .physicalTension,
        "Digestive Issue": .digestiveIssue,
        "Special Interest Engagement": .specialInterest,
        "Difficulty Disengaging": .disengagementDifficulty,
        // Positive & Coping
        "Successful Coping": .successfulCoping,
        "Calm/Regulated State": .calmState,
        "Connection Moment": .connectionMoment,
        "Rest/Recovery Success": .restSuccess,
        "Sensory Comfort": .sensoryComfort,
        "Boundary Setting": .boundarySetting,
        "Self-Compassion": .selfCompassion,
        "Accommodation Win": .accommodationWin,
        "Joy/Happiness": .joyHappiness,
        "Achievement/Progress": .achievementProgress
    ]

    /// Get PatternType from AI response string
    static func patternType(from string: String) -> PatternType? {
        return patternTypeMapping[string]
    }

    /// All valid pattern type names for validation
    static var validPatternNames: Set<String> {
        Set(patternTypeMapping.keys)
    }
}

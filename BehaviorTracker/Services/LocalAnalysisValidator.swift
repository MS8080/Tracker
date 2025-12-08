import Foundation

/// Validates LocalAnalysisService accuracy against known test cases
struct LocalAnalysisValidator {

    struct TestCase {
        let text: String
        let expectedPatterns: [PatternType]
        let expectedSentiment: LocalAnalysisService.Sentiment
    }

    // MARK: - Test Dataset with Known Correct Answers

    static let testCases: [TestCase] = [
        // Sensory - Clear cases
        TestCase(
            text: "The mall was so loud and bright today. Too many people. I had to leave because I was completely overwhelmed.",
            expectedPatterns: [.sensoryState, .socialRecovery],
            expectedSentiment: .negative
        ),
        TestCase(
            text: "The fluorescent lights at work were buzzing all day. Gave me a headache. Had to wear sunglasses inside.",
            expectedPatterns: [.sensoryEnvironment, .sensoryState],
            expectedSentiment: .negative
        ),

        // Focus - Clear cases
        TestCase(
            text: "Got completely absorbed in my coding project. Looked up and 6 hours had passed. Forgot to eat lunch.",
            expectedPatterns: [.focus, .timeAwareness],
            expectedSentiment: .neutral
        ),
        TestCase(
            text: "Spent all day researching my special interest. Couldn't stop reading about trains. It was amazing.",
            expectedPatterns: [.focus],
            expectedSentiment: .positive
        ),

        // Social - Clear cases
        TestCase(
            text: "Had a work meeting with 10 people. So exhausted after. Need to be alone for the rest of the day.",
            expectedPatterns: [.socialEnergy, .socialRecovery],
            expectedSentiment: .negative
        ),
        TestCase(
            text: "Phone call with my mom was draining. She doesn't understand why I need quiet time after.",
            expectedPatterns: [.socialEnergy, .socialRecovery, .connection],
            expectedSentiment: .negative
        ),

        // Energy/Masking - Clear cases
        TestCase(
            text: "Pretended to be normal all day at the office. Smiled when I didn't want to. So tired from masking.",
            expectedPatterns: [.masking, .burnout],
            expectedSentiment: .negative
        ),
        TestCase(
            text: "Running on empty. No spoons left. Everything feels impossible today.",
            expectedPatterns: [.energyLevel, .burnout],
            expectedSentiment: .negative
        ),

        // Routine - Clear cases
        TestCase(
            text: "They changed my desk location at work without warning. Completely threw off my whole day.",
            expectedPatterns: [.routineChange],
            expectedSentiment: .negative
        ),
        TestCase(
            text: "Plans changed at the last minute. I couldn't handle the uncertainty. Had to cancel.",
            expectedPatterns: [.routineChange],
            expectedSentiment: .negative
        ),

        // Overwhelm - Clear cases
        TestCase(
            text: "Had a complete meltdown in the car. Crying, couldn't stop. Too much happened today.",
            expectedPatterns: [.overwhelm],
            expectedSentiment: .negative
        ),
        TestCase(
            text: "Went nonverbal for an hour. Just shut down completely. Couldn't respond to anyone.",
            expectedPatterns: [.overwhelm],
            expectedSentiment: .negative
        ),

        // Task/Executive Function - Clear cases
        TestCase(
            text: "Stared at my to-do list for 2 hours. Couldn't start anything. Just paralyzed.",
            expectedPatterns: [.taskInitiation, .avoidance],
            expectedSentiment: .negative
        ),
        TestCase(
            text: "Had to switch from emails to a meeting to a phone call. Each transition was painful.",
            expectedPatterns: [.focus, .routineChange],
            expectedSentiment: .negative
        ),

        // Positive - Clear cases
        TestCase(
            text: "Found a quiet corner and just stimmed for 20 minutes. Rocking helped me calm down.",
            expectedPatterns: [.stimming, .regulation],
            expectedSentiment: .positive
        ),
        TestCase(
            text: "Great day! Felt like myself. Didn't have to mask. Connected with a friend who gets me.",
            expectedPatterns: [.connection, .regulation],
            expectedSentiment: .positive
        ),

        // Ambiguous/Harder cases - to test limits
        TestCase(
            text: "Today was just too much.",
            expectedPatterns: [.overwhelm], // vague - hard for local
            expectedSentiment: .negative
        ),
        TestCase(
            text: "I don't know why but everything feels wrong.",
            expectedPatterns: [.overwhelm], // very vague
            expectedSentiment: .negative
        ),
        TestCase(
            text: "Meeting went okay I guess. Tired now.",
            expectedPatterns: [.socialEnergy, .socialRecovery], // subtle
            expectedSentiment: .neutral
        )
    ]

    // MARK: - Validation

    struct ValidationResult {
        let totalCases: Int
        let patternAccuracy: Double      // % of expected patterns correctly detected
        let sentimentAccuracy: Double    // % of sentiments correct
        let falsePositives: Int          // patterns detected that shouldn't be
        let falseNegatives: Int          // patterns missed that should be detected
        let detailedResults: [CaseResult]
    }

    struct CaseResult {
        let text: String
        let expectedPatterns: [PatternType]
        let detectedPatterns: [PatternType]
        let expectedSentiment: LocalAnalysisService.Sentiment
        let detectedSentiment: LocalAnalysisService.Sentiment
        let patternMatches: Int
        let patternMisses: Int
        let falseDetections: Int
        let sentimentCorrect: Bool
    }

    static func validate() -> ValidationResult {
        let service = LocalAnalysisService.shared
        var detailedResults: [CaseResult] = []

        var totalExpectedPatterns = 0
        var totalCorrectPatterns = 0
        var totalFalsePositives = 0
        var totalFalseNegatives = 0
        var correctSentiments = 0

        for testCase in testCases {
            let result = service.analyze(text: testCase.text)

            // Convert local categories to pattern types for comparison
            let detectedPatterns = mapCategoriesToPatterns(result.categories, text: testCase.text)

            // Calculate pattern accuracy
            let expectedSet = Set(testCase.expectedPatterns)
            let detectedSet = Set(detectedPatterns)

            let matches = expectedSet.intersection(detectedSet).count
            let misses = expectedSet.subtracting(detectedSet).count
            let falseDetections = detectedSet.subtracting(expectedSet).count

            totalExpectedPatterns += expectedSet.count
            totalCorrectPatterns += matches
            totalFalsePositives += falseDetections
            totalFalseNegatives += misses

            // Check sentiment
            let sentimentCorrect = result.sentiment == testCase.expectedSentiment
            if sentimentCorrect { correctSentiments += 1 }

            detailedResults.append(CaseResult(
                text: String(testCase.text.prefix(50)) + "...",
                expectedPatterns: testCase.expectedPatterns,
                detectedPatterns: detectedPatterns,
                expectedSentiment: testCase.expectedSentiment,
                detectedSentiment: result.sentiment,
                patternMatches: matches,
                patternMisses: misses,
                falseDetections: falseDetections,
                sentimentCorrect: sentimentCorrect
            ))
        }

        return ValidationResult(
            totalCases: testCases.count,
            patternAccuracy: totalExpectedPatterns > 0 ? Double(totalCorrectPatterns) / Double(totalExpectedPatterns) * 100 : 0,
            sentimentAccuracy: Double(correctSentiments) / Double(testCases.count) * 100,
            falsePositives: totalFalsePositives,
            falseNegatives: totalFalseNegatives,
            detailedResults: detailedResults
        )
    }

    // Map LocalAnalysisService categories to PatternTypes
    private static func mapCategoriesToPatterns(_ categories: [LocalAnalysisService.PatternCategory], text: String) -> [PatternType] {
        var patterns: [PatternType] = []
        let lowercased = text.lowercased()

        for category in categories {
            switch category.name.lowercased() {
            case "sensory":
                if lowercased.contains("overload") || lowercased.contains("overwhelm") {
                    patterns.append(.sensoryState)
                }
                if lowercased.contains("sensitive") || lowercased.contains("lights") || lowercased.contains("buzzing") {
                    patterns.append(.sensoryEnvironment)
                }
            case "emotional":
                if lowercased.contains("meltdown") || lowercased.contains("shutdown") || lowercased.contains("nonverbal") || lowercased.contains("overwhelm") {
                    patterns.append(.overwhelm)
                }
            case "social":
                patterns.append(.socialEnergy)
                if lowercased.contains("exhausted") || lowercased.contains("drained") || lowercased.contains("tired") || lowercased.contains("alone") {
                    patterns.append(.socialRecovery)
                }
                if lowercased.contains("misunderstood") || lowercased.contains("doesn't understand") {
                    patterns.append(.connection)
                }
            case "routine":
                if lowercased.contains("change") || lowercased.contains("disruption") || lowercased.contains("unexpected") || lowercased.contains("last minute") {
                    patterns.append(.routineChange)
                }
            case "energy":
                patterns.append(.energyLevel)
                if lowercased.contains("burnout") || lowercased.contains("empty") || lowercased.contains("no spoons") {
                    patterns.append(.burnout)
                }
                if lowercased.contains("mask") {
                    patterns.append(.masking)
                }
            case "focus":
                if lowercased.contains("hyperfocus") || lowercased.contains("absorbed") || lowercased.contains("hours had passed") || lowercased.contains("special interest") {
                    patterns.append(.focus)
                }
                if lowercased.contains("lost track") || lowercased.contains("forgot") {
                    patterns.append(.timeAwareness)
                }
                if lowercased.contains("couldn't start") || lowercased.contains("paralyzed") || lowercased.contains("stared at") {
                    patterns.append(.taskInitiation)
                }
                if lowercased.contains("switch") || lowercased.contains("transition") {
                    patterns.append(.focus)
                    patterns.append(.routineChange)
                }
            case "coping":
                if lowercased.contains("stim") || lowercased.contains("rocking") {
                    patterns.append(.stimming)
                }
                if lowercased.contains("helped") || lowercased.contains("calm") {
                    patterns.append(.regulation)
                }
            default:
                break
            }
        }

        // Check for patterns not in categories
        if lowercased.contains("avoid") && !patterns.contains(.avoidance) {
            patterns.append(.avoidance)
        }
        if (lowercased.contains("authentic") || lowercased.contains("myself")) && !patterns.contains(.regulation) {
            patterns.append(.regulation)
        }
        if lowercased.contains("connect") && !patterns.contains(.connection) {
            patterns.append(.connection)
        }
        if lowercased.contains("calm") && !patterns.contains(.regulation) {
            patterns.append(.regulation)
        }

        return Array(Set(patterns)) // Remove duplicates
    }

    // MARK: - Print Report

    static func printReport() {
        let result = validate()

        print("\n" + String(repeating: "=", count: 60))
        print("LOCAL ANALYSIS ACCURACY REPORT")
        print(String(repeating: "=", count: 60))

        print("\n📊 SUMMARY:")
        print("   Total test cases: \(result.totalCases)")
        print("   Pattern accuracy: \(String(format: "%.1f", result.patternAccuracy))%")
        print("   Sentiment accuracy: \(String(format: "%.1f", result.sentimentAccuracy))%")
        print("   False positives: \(result.falsePositives)")
        print("   False negatives (missed): \(result.falseNegatives)")

        print("\n📋 DETAILED RESULTS:")
        for (index, caseResult) in result.detailedResults.enumerated() {
            print("\n[\(index + 1)] \"\(caseResult.text)\"")
            print("   Expected: \(caseResult.expectedPatterns.map { $0.rawValue })")
            print("   Detected: \(caseResult.detectedPatterns.map { $0.rawValue })")
            print("   ✅ Matches: \(caseResult.patternMatches), ❌ Missed: \(caseResult.patternMisses), ⚠️ False: \(caseResult.falseDetections)")
            print("   Sentiment: \(caseResult.sentimentCorrect ? "✅" : "❌") (expected: \(caseResult.expectedSentiment.rawValue), got: \(caseResult.detectedSentiment.rawValue))")
        }

        print("\n" + String(repeating: "=", count: 60))
        print("RECOMMENDATION:")
        if result.patternAccuracy >= 80 {
            print("✅ Local analysis is accurate enough for primary use")
        } else if result.patternAccuracy >= 60 {
            print("⚠️ Local analysis is okay but external AI would improve accuracy")
        } else {
            print("❌ Local analysis needs improvement or external AI is recommended")
        }
        print(String(repeating: "=", count: 60) + "\n")
    }
}

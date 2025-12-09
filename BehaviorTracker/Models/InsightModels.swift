import Foundation
import SwiftUI

// MARK: - Active Tracking

/// Represents something the app is currently monitoring
struct ActiveTracking: Identifiable {
    let id = UUID()
    let summary: String  // "Low energy logged at 2:30 PM"
    let factors: [String]  // ["Ritalin taken at 9 AM", "5 hours since last meal"]
    let timestamp: Date

    enum Response: String, CaseIterable {
        case resolved = "Resolved"
        case stillThere = "Still there"
        case worse = "Worse"
    }
}

// MARK: - Discovery

/// A pattern the app has learned about the user
struct Discovery: Identifiable {
    let id = UUID()
    let insight: String  // "Your crashes after appointments shorten when you rest immediately"
    let confidence: ConfidenceLevel
    let occurrences: Int  // How many times seen
    let timespan: String  // "2 weeks"
    let factors: [Factor]  // Tags for meds, times, contexts
    let relatedEntryIDs: [UUID]  // Source journal entries
    let discoveredAt: Date

    enum ConfidenceLevel {
        case emerging  // 2-3 occurrences
        case developing  // 4-5 occurrences
        case strong  // 6+ occurrences

        var label: String {
            switch self {
            case .emerging: return "emerging"
            case .developing: return "developing"
            case .strong: return "strong pattern"
            }
        }
    }

    struct Factor: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let type: FactorType

        enum FactorType {
            case medication
            case time
            case context
            case symptom
            case activity

            var color: Color {
                switch self {
                case .medication: return .blue
                case .time: return .orange
                case .context: return .purple
                case .symptom: return .red
                case .activity: return .green
                }
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(id)
        }

        static func == (lhs: Factor, rhs: Factor) -> Bool {
            lhs.id == rhs.id
        }
    }

    /// Formatted confidence text
    var confidenceText: String {
        if occurrences <= 1 {
            return "seen once"
        } else if occurrences < 6 {
            return "seen \(occurrences) times"
        } else {
            return "strong pattern • \(occurrences) entries"
        }
    }
}

// MARK: - Question

/// A question the AI wants to validate with the user
struct InsightQuestion: Identifiable {
    let id = UUID()
    let observation: String  // "You mentioned headaches twice after piracetam"
    let question: String  // "Is this connection real?"
    let relatedFactors: [Discovery.Factor]
    let createdAt: Date

    enum Response: String, CaseIterable {
        case yes = "Yes"
        case no = "No"
        case notSure = "Not sure"
    }
}

// MARK: - Sample Data

extension Discovery {
    static let samples: [Discovery] = [
        Discovery(
            insight: "Tyrosine before 10am correlates with better focus throughout the day",
            confidence: .strong,
            occurrences: 5,
            timespan: "2 weeks",
            factors: [
                Factor(name: "Tyrosine", type: .medication),
                Factor(name: "Morning", type: .time),
                Factor(name: "Focus", type: .symptom)
            ],
            relatedEntryIDs: [],
            discoveredAt: Date()
        ),
        Discovery(
            insight: "Your crashes after appointments shorten when you rest immediately",
            confidence: .developing,
            occurrences: 4,
            timespan: "3 weeks",
            factors: [
                Factor(name: "Appointments", type: .context),
                Factor(name: "Rest", type: .activity),
                Factor(name: "Crashes", type: .symptom)
            ],
            relatedEntryIDs: [],
            discoveredAt: Date().addingTimeInterval(-86400)
        ),
        Discovery(
            insight: "Balance issues appear only on days with under 6 hours sleep",
            confidence: .emerging,
            occurrences: 3,
            timespan: "10 days",
            factors: [
                Factor(name: "Sleep < 6h", type: .context),
                Factor(name: "Balance", type: .symptom)
            ],
            relatedEntryIDs: [],
            discoveredAt: Date().addingTimeInterval(-172800)
        )
    ]
}

extension InsightQuestion {
    static let samples: [InsightQuestion] = [
        InsightQuestion(
            observation: "You mentioned headaches twice after taking piracetam",
            question: "Is this connection real?",
            relatedFactors: [
                Discovery.Factor(name: "Piracetam", type: .medication),
                Discovery.Factor(name: "Headaches", type: .symptom)
            ],
            createdAt: Date()
        )
    ]
}

extension ActiveTracking {
    static let sample = ActiveTracking(
        summary: "Low energy logged at 2:30 PM",
        factors: ["Ritalin taken at 9 AM", "5 hours since last meal"],
        timestamp: Date()
    )
}

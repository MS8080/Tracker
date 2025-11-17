import Foundation

enum MedicationFrequency: String, CaseIterable {
    case daily = "Daily"
    case twiceDaily = "Twice Daily"
    case threeTimesDaily = "Three Times Daily"
    case everyOtherDay = "Every Other Day"
    case weekly = "Weekly"
    case asNeeded = "As Needed"

    var description: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .daily:
            return "sun.max.fill"
        case .twiceDaily:
            return "sunrise.fill"
        case .threeTimesDaily:
            return "clock.fill"
        case .everyOtherDay:
            return "calendar.badge.clock"
        case .weekly:
            return "calendar"
        case .asNeeded:
            return "hand.raised.fill"
        }
    }
}

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    static let profileUpdated = Notification.Name("profileUpdated")
    static let demoModeChanged = Notification.Name("demoModeChanged")
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? startOfDay
    }

    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek) ?? self
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? startOfDay
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    func weeksAgo(_ weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: self) ?? self
    }

    func monthsAgo(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: -months, to: self) ?? self
    }
}

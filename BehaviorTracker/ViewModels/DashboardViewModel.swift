import SwiftUI
import CoreData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var streakCount: Int32 = 0
    @Published var todayEntryCount: Int = 0
    @Published var weeklyEntryCount: Int = 0
    @Published var monthlyEntryCount: Int = 0
    @Published var todayCategoryBreakdown: [PatternCategory: Int] = [:]
    @Published var recentEntries: [PatternEntry] = []
    @Published var mostLoggedPattern: String?

    private let dataController = DataController.shared

    func loadData() {
        loadStreak()
        loadTodayStats()
        loadWeeklyStats()
        loadMonthlyStats()
        loadRecentEntries()
        loadMostLoggedPattern()
    }

    private func loadStreak() {
        let preferences = dataController.getUserPreferences()
        streakCount = preferences.streakCount
    }

    private func loadTodayStats() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let entries = dataController.fetchPatternEntries(startDate: startOfDay, endDate: endOfDay)
        todayEntryCount = entries.count

        var breakdown: [PatternCategory: Int] = [:]
        for entry in entries {
            if let category = entry.patternCategoryEnum {
                breakdown[category, default: 0] += 1
            }
        }
        todayCategoryBreakdown = breakdown
    }

    private func loadWeeklyStats() {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let entries = dataController.fetchPatternEntries(startDate: startOfWeek, endDate: Date())
        weeklyEntryCount = entries.count
    }

    private func loadMonthlyStats() {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let entries = dataController.fetchPatternEntries(startDate: startOfMonth, endDate: Date())
        monthlyEntryCount = entries.count
    }

    private func loadRecentEntries() {
        recentEntries = dataController.fetchPatternEntries(limit: 20)
    }

    private func loadMostLoggedPattern() {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let entries = dataController.fetchPatternEntries(startDate: startOfMonth, endDate: Date())

        var patternCounts: [String: Int] = [:]
        for entry in entries {
            patternCounts[entry.patternType, default: 0] += 1
        }

        if let mostCommon = patternCounts.max(by: { $0.value < $1.value }) {
            mostLoggedPattern = mostCommon.key
        }
    }
}

import SwiftUI
import Combine

class ReportsViewModel: ObservableObject {
    @Published var weeklyReport: WeeklyReport = WeeklyReport()
    @Published var monthlyReport: MonthlyReport = MonthlyReport()

    private let reportGenerator = ReportGenerator()
    private let demoService = DemoModeService.shared
    private var cancellables = Set<AnyCancellable>()

    /// Whether we're currently in demo mode
    var isDemoMode: Bool {
        demoService.isEnabled
    }

    init() {
        observeDemoModeChanges()
    }

    private func observeDemoModeChanges() {
        NotificationCenter.default.publisher(for: .demoModeChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.generateReports()
            }
            .store(in: &cancellables)
    }

    func generateReports() {
        if demoService.isEnabled {
            generateDemoReports()
            return
        }
        weeklyReport = reportGenerator.generateWeeklyReport()
        monthlyReport = reportGenerator.generateMonthlyReport()
    }

    private func generateDemoReports() {
        let demoWeekly = demoService.demoWeeklyReport
        let demoMonthly = demoService.demoMonthlyReport
        let demoGoalsSummary = demoService.demoLifeGoalsSummary

        // Build weekly report
        var weekly = WeeklyReport()
        weekly.totalEntries = demoWeekly.totalEntries
        weekly.totalPatterns = demoWeekly.totalPatterns
        weekly.mostActiveDay = demoWeekly.mostActiveDay
        weekly.averagePerDay = demoWeekly.averagePerDay
        weekly.patternFrequency = demoWeekly.patternFrequency
        weekly.categoryBreakdown = demoWeekly.categoryBreakdown
        weekly.commonTriggers = demoWeekly.commonTriggers
        weekly.topCascades = demoWeekly.topCascades

        // Add life goals summary
        weekly.lifeGoalsSummary = LifeGoalsSummary(
            activeGoals: demoGoalsSummary.activeGoals,
            completedGoals: demoGoalsSummary.completedGoals,
            overdueGoals: demoGoalsSummary.overdueGoals,
            activeStruggles: demoGoalsSummary.activeStruggles,
            resolvedStruggles: demoGoalsSummary.resolvedStruggles,
            severeStruggles: 1,
            wishlistPending: demoGoalsSummary.wishlistPending,
            wishlistAcquired: demoGoalsSummary.wishlistAcquired
        )

        weeklyReport = weekly

        // Build monthly report
        var monthly = MonthlyReport()
        monthly.totalEntries = demoMonthly.totalEntries
        monthly.totalPatterns = demoMonthly.totalPatterns
        monthly.mostActiveWeek = demoMonthly.mostActiveWeek
        monthly.averagePerDay = demoMonthly.averagePerDay
        monthly.topPatterns = demoMonthly.topPatterns
        monthly.correlations = demoMonthly.correlations
        monthly.bestDays = demoMonthly.bestDays
        monthly.challengingDays = demoMonthly.challengingDays

        // Add life goals summary
        monthly.lifeGoalsSummary = LifeGoalsSummary(
            activeGoals: demoGoalsSummary.activeGoals,
            completedGoals: demoGoalsSummary.completedGoals,
            overdueGoals: demoGoalsSummary.overdueGoals,
            activeStruggles: demoGoalsSummary.activeStruggles,
            resolvedStruggles: demoGoalsSummary.resolvedStruggles,
            severeStruggles: 1,
            wishlistPending: demoGoalsSummary.wishlistPending,
            wishlistAcquired: demoGoalsSummary.wishlistAcquired
        )

        monthlyReport = monthly
    }
}

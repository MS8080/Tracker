import SwiftUI

class ReportsViewModel: ObservableObject {
    @Published var weeklyReport: WeeklyReport = WeeklyReport()
    @Published var monthlyReport: MonthlyReport = MonthlyReport()

    private let reportGenerator = ReportGenerator()

    func generateReports() {
        weeklyReport = reportGenerator.generateWeeklyReport()
        monthlyReport = reportGenerator.generateMonthlyReport()
    }
}

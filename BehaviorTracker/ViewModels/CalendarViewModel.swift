import SwiftUI
import CoreData

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date? = nil
    @Published var entriesByDate: [Date: [PatternEntry]] = [:]
    @Published var medicationLogsByDate: [Date: [MedicationLog]] = [:]
    @Published var journalEntriesByDate: [Date: [JournalEntry]] = [:]
    @Published var calendarEventsByDate: [Date: [CalendarEvent]] = [:]
    @Published var isCalendarAuthorized: Bool = false

    private let dataController = DataController.shared
    private let calendarEventService = CalendarEventService.shared
    private let calendar = Calendar.current

    // MARK: - Cached Formatters (Performance Optimization)
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let cachedWeekdaySymbols: [String] = {
        DateFormatter().shortWeekdaySymbols
    }()

    // MARK: - Month Navigation

    var monthYearString: String {
        Self.monthYearFormatter.string(from: currentMonth)
    }

    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }

        var days: [Date] = []
        var currentDate = monthFirstWeek.start

        while currentDate < monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    var weekdaySymbols: [String] {
        Self.cachedWeekdaySymbols
    }

    func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        loadMonthData()
    }

    func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        loadMonthData()
    }

    func goToToday() {
        currentMonth = Date()
        selectedDate = calendar.startOfDay(for: Date())
        loadMonthData()
    }

    // MARK: - Date Helpers

    func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }

    // MARK: - Data Loading

    func loadMonthData() {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return }

        // Extend range to include visible days from adjacent months
        let startDate = calendar.date(byAdding: .day, value: -7, to: monthInterval.start) ?? monthInterval.start
        let endDate = calendar.date(byAdding: .day, value: 7, to: monthInterval.end) ?? monthInterval.end

        loadPatternEntries(from: startDate, to: endDate)
        loadMedicationLogs(from: startDate, to: endDate)
        loadJournalEntries(from: startDate, to: endDate)
        loadCalendarEvents()
    }

    /// Async version for loading - use with .task modifier
    /// Yields to allow animations to start before data loads
    func loadMonthDataAsync() async {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return }

        let startDate = calendar.date(byAdding: .day, value: -7, to: monthInterval.start) ?? monthInterval.start
        let endDate = calendar.date(byAdding: .day, value: 7, to: monthInterval.end) ?? monthInterval.end

        // Yield to allow animations to start
        await Task.yield()

        // Load data on main actor (Core Data objects aren't Sendable)
        loadPatternEntries(from: startDate, to: endDate)
        await Task.yield()

        loadMedicationLogs(from: startDate, to: endDate)
        await Task.yield()

        loadJournalEntries(from: startDate, to: endDate)
        loadCalendarEvents()
    }

    // MARK: - Calendar Events

    func requestCalendarAccess() async {
        let granted = await calendarEventService.requestAccess()
        isCalendarAuthorized = granted
        if granted {
            loadCalendarEvents()
        }
    }

    func checkCalendarAuthorization() {
        calendarEventService.checkAuthorizationStatus()
        isCalendarAuthorized = calendarEventService.isAuthorized
    }

    private func loadCalendarEvents() {
        guard calendarEventService.isAuthorized else { return }
        calendarEventsByDate = calendarEventService.fetchEventsForMonth(containing: currentMonth)
    }

    private func loadPatternEntries(from startDate: Date, to endDate: Date) {
        let entries = dataController.fetchPatternEntries(startDate: startDate, endDate: endDate)

        var grouped: [Date: [PatternEntry]] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.timestamp)
            grouped[day, default: []].append(entry)
        }
        entriesByDate = grouped
    }

    private func loadMedicationLogs(from startDate: Date, to endDate: Date) {
        let request = NSFetchRequest<MedicationLog>(entityName: "MedicationLog")
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationLog.timestamp, ascending: true)]

        do {
            let logs = try dataController.container.viewContext.fetch(request)
            var grouped: [Date: [MedicationLog]] = [:]
            for log in logs {
                let day = calendar.startOfDay(for: log.timestamp)
                grouped[day, default: []].append(log)
            }
            medicationLogsByDate = grouped
        } catch {
            print("Failed to load medication logs: \(error.localizedDescription)")
        }
    }

    private func loadJournalEntries(from startDate: Date, to endDate: Date) {
        Task { [weak self] in
            guard let self else { return }
            let entries = await dataController.fetchJournalEntries(startDate: startDate, endDate: endDate)

            var grouped: [Date: [JournalEntry]] = [:]
            for entry in entries {
                let day = calendar.startOfDay(for: entry.timestamp)
                grouped[day, default: []].append(entry)
            }
            journalEntriesByDate = grouped
        }
    }

    // MARK: - Day Summary

    func entriesForDate(_ date: Date) -> [PatternEntry] {
        let day = calendar.startOfDay(for: date)
        return entriesByDate[day] ?? []
    }

    func medicationLogsForDate(_ date: Date) -> [MedicationLog] {
        let day = calendar.startOfDay(for: date)
        return medicationLogsByDate[day] ?? []
    }

    func journalEntriesForDate(_ date: Date) -> [JournalEntry] {
        let day = calendar.startOfDay(for: date)
        return journalEntriesByDate[day] ?? []
    }

    func totalEntriesForDate(_ date: Date) -> Int {
        entriesForDate(date).count
    }

    func categoriesForDate(_ date: Date) -> [PatternCategory] {
        let entries = entriesForDate(date)
        let categories = Set(entries.compactMap { $0.patternCategoryEnum })
        return Array(categories).sorted { $0.rawValue < $1.rawValue }
    }

    func averageIntensityForDate(_ date: Date) -> Double? {
        let entries = entriesForDate(date).filter { $0.intensity > 0 }
        guard !entries.isEmpty else { return nil }
        let total = entries.reduce(0) { $0 + Int($1.intensity) }
        return Double(total) / Double(entries.count)
    }

    func dominantCategoryForDate(_ date: Date) -> PatternCategory? {
        let entries = entriesForDate(date)
        let categoryCounts = Dictionary(grouping: entries) { $0.patternCategoryEnum }
            .mapValues { $0.count }
        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }

    func hasMedicationLogsForDate(_ date: Date) -> Bool {
        !medicationLogsForDate(date).isEmpty
    }

    func hasJournalEntriesForDate(_ date: Date) -> Bool {
        !journalEntriesForDate(date).isEmpty
    }

    // MARK: - Calendar Events Helpers

    func calendarEventsForDate(_ date: Date) -> [CalendarEvent] {
        let day = calendar.startOfDay(for: date)
        return calendarEventsByDate[day] ?? []
    }

    func hasCalendarEventsForDate(_ date: Date) -> Bool {
        !calendarEventsForDate(date).isEmpty
    }

    func calendarEventCountForDate(_ date: Date) -> Int {
        calendarEventsForDate(date).count
    }
}

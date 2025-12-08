import Foundation
import EventKit

/// Service for importing and managing calendar events from iOS Calendar
class CalendarEventService: ObservableObject {
    static let shared = CalendarEventService()

    private let eventStore = EKEventStore()

    @Published var isAuthorized = false
    @Published var events: [CalendarEvent] = []
    @Published var todayEvents: [CalendarEvent] = []

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, macOS 14.0, *) {
            isAuthorized = status == .fullAccess
        } else {
            isAuthorized = status == .authorized
        }
    }

    /// Synchronous check for current authorization status
    var currentAuthorizationStatus: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, macOS 14.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    self.isAuthorized = granted
                }
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                await MainActor.run {
                    self.isAuthorized = granted
                }
                return granted
            }
        } catch {
            return false
        }
    }

    // MARK: - Fetch Events

    /// Fetch events for a specific date
    func fetchEvents(for date: Date) -> [CalendarEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Fetch events for a date range
    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        guard isAuthorized else { return [] }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Fetch today's events and update published property
    func fetchTodayEvents() {
        let today = Date()
        let fetchedEvents = fetchEvents(for: today)
        DispatchQueue.main.async {
            self.todayEvents = fetchedEvents
        }
    }

    /// Fetch events for a month
    func fetchEventsForMonth(containing date: Date) -> [Date: [CalendarEvent]] {
        guard isAuthorized else { return [:] }

        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [:] }

        let events = fetchEvents(from: monthInterval.start, to: monthInterval.end)

        // Group events by day
        var eventsByDay: [Date: [CalendarEvent]] = [:]
        for event in events {
            let dayStart = calendar.startOfDay(for: event.startDate)
            eventsByDay[dayStart, default: []].append(event)
        }

        return eventsByDay
    }
}

// MARK: - Calendar Event Model

struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let calendarColor: CGColor?
    let calendarTitle: String?

    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? "Untitled Event"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.calendarColor = ekEvent.calendar?.cgColor
        self.calendarTitle = ekEvent.calendar?.title
    }

    // For previews/testing
    init(id: String = UUID().uuidString, title: String, startDate: Date, endDate: Date, isAllDay: Bool = false, location: String? = nil, notes: String? = nil, calendarColor: CGColor? = nil, calendarTitle: String? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.calendarColor = calendarColor
        self.calendarTitle = calendarTitle
    }

    var timeString: String {
        if isAllDay {
            return "All day"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }

    var durationString: String {
        if isAllDay {
            return "All day"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }
}

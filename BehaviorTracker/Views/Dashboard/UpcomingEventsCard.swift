import SwiftUI

struct UpcomingEventsCard: View {
    @StateObject private var calendarService = CalendarEventService.shared
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    @State private var upcomingEvents: [CalendarEvent] = []
    @State private var isLoading = false

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(SemanticColor.calendar)

                Text("Upcoming")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(CardText.title)

                Spacer()

                if calendarService.isAuthorized && !upcomingEvents.isEmpty {
                    Text("\(upcomingEvents.count) events")
                        .font(.caption)
                        .foregroundStyle(CardText.caption)
                }
            }

            if !calendarService.isAuthorized {
                // Permission request
                calendarPermissionView
            } else if isLoading {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(theme.primaryColor)
                    Spacer()
                }
                .padding(.vertical, Spacing.md)
            } else if upcomingEvents.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Events list (show max 5)
                eventsListView
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
        .task {
            await loadEvents()
        }
    }

    // MARK: - Load Events

    private func loadEvents() async {
        guard calendarService.isAuthorized else { return }

        isLoading = true
        defer { isLoading = false }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        await MainActor.run {
            upcomingEvents = calendarService.fetchEvents(from: startDate, to: endDate)
        }
    }

    // MARK: - Permission View

    private var calendarPermissionView: some View {
        VStack(spacing: Spacing.md) {
            Text("See your upcoming events here")
                .font(.subheadline)
                .foregroundStyle(CardText.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    let granted = await calendarService.requestAccess()
                    if granted {
                        await loadEvents()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Connect Calendar")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColor.calendar, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)
            Text("No upcoming events this week")
                .font(.subheadline)
                .foregroundStyle(CardText.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Events List

    private var eventsListView: some View {
        VStack(spacing: Spacing.sm) {
            // Group events by day
            let displayEvents = Array(upcomingEvents.prefix(5))
            let groupedEvents = groupEventsByDay(displayEvents)
            let sortedDays = groupedEvents.keys.sorted { dayOrder($0) < dayOrder($1) }

            ForEach(sortedDays, id: \.self) { day in
                if let events = groupedEvents[day] {
                    // Day header
                    HStack {
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(day == "Today" ? SemanticColor.calendar : CardText.secondary)
                        Spacer()
                    }
                    .padding(.top, day == sortedDays.first ? 0 : Spacing.xs)

                    // Events for this day
                    ForEach(events) { event in
                        eventRow(event)
                    }
                }
            }

            // Show more indicator
            if upcomingEvents.count > 5 {
                HStack {
                    Spacer()
                    Text("+\(upcomingEvents.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(CardText.muted)
                }
            }
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: Spacing.md) {
            // Time
            Text(event.timeString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(CardText.secondary)
                .frame(width: 60, alignment: .leading)

            // Color indicator
            Circle()
                .fill(Color(cgColor: event.calendarColor ?? UIColor.systemCyan.cgColor))
                .frame(width: 8, height: 8)

            // Title
            Text(event.title)
                .font(.subheadline)
                .foregroundStyle(CardText.body)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Helpers

    private func groupEventsByDay(_ events: [CalendarEvent]) -> [String: [CalendarEvent]] {
        var grouped: [String: [CalendarEvent]] = [:]

        for event in events {
            let day = relativeDay(for: event.startDate)
            if grouped[day] == nil {
                grouped[day] = []
            }
            grouped[day]?.append(event)
        }

        return grouped
    }

    private func relativeDay(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }

    private func dayOrder(_ day: String) -> Int {
        switch day {
        case "Today": return 0
        case "Tomorrow": return 1
        default: return 2
        }
    }
}

#Preview {
    UpcomingEventsCard()
        .padding()
        .background(Color.gray.opacity(0.2))
}

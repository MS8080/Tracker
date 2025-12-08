import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @Binding var showingProfile: Bool
    @State private var showingDayDetail = false
    @AppStorage("calendarBannerDismissed") private var calendarBannerDismissed = false

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Demo mode indicator
                        if viewModel.isDemoMode {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Demo Mode - Sample Data")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.2), in: Capsule())
                        }

                        // Calendar permission banner (only show if not authorized and not dismissed)
                        if !viewModel.isDemoMode && !viewModel.isCalendarAuthorized && !calendarBannerDismissed && !CalendarEventService.shared.currentAuthorizationStatus {
                            calendarPermissionBanner
                        }

                        monthNavigationHeader
                        weekdayHeader
                        calendarGrid

                        if let selectedDate = viewModel.selectedDate {
                            selectedDaySummary(for: selectedDate)
                        }

                        legendSection
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.loadMonthDataAsync()
                    HapticFeedback.light.trigger()
                }
            }
            .navigationTitle(NSLocalizedString("calendar.title", comment: "Calendar"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }


                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticFeedback.medium.trigger()
                        viewModel.goToToday()
                    } label: {
                        Text("Today")
                            .font(.subheadline)
                    }
                }

            }
            .task {
                viewModel.checkCalendarAuthorization()
                await viewModel.loadMonthDataAsync()
            }
            .sheet(isPresented: $showingDayDetail) {
                if let selectedDate = viewModel.selectedDate {
                    CalendarDayDetailView(
                        date: selectedDate,
                        entries: viewModel.entriesForDate(selectedDate),
                        medicationLogs: viewModel.medicationLogsForDate(selectedDate),
                        journalEntries: viewModel.journalEntriesForDate(selectedDate),
                        calendarEvents: viewModel.calendarEventsForDate(selectedDate)
                    )
                }
            }
        }
    }

    // MARK: - Calendar Permission Banner

    private var calendarPermissionBanner: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .foregroundStyle(SemanticColor.calendar)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Import Calendar Events")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(CardText.body)
                Text("See your appointments alongside your patterns")
                    .font(.caption)
                    .foregroundStyle(CardText.caption)
            }

            Spacer()

            Button {
                Task {
                    await viewModel.requestCalendarAccess()
                }
            } label: {
                Text("Enable")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(SemanticColor.calendar)
                    )
            }

            Button {
                withAnimation {
                    calendarBannerDismissed = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(CardText.muted)
            }
        }
        .padding()
        .cardStyle(theme: theme, cornerRadius: 20)
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                HapticFeedback.light.trigger()
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.previousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthYearString)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                HapticFeedback.light.trigger()
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.nextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: Spacing.xs) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.xs) {
            ForEach(viewModel.daysInMonth, id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    isCurrentMonth: viewModel.isCurrentMonth(date),
                    isToday: viewModel.isToday(date),
                    isSelected: viewModel.isSelected(date),
                    entryCount: viewModel.totalEntriesForDate(date),
                    dominantCategory: viewModel.dominantCategoryForDate(date),
                    averageIntensity: viewModel.averageIntensityForDate(date),
                    hasMedication: viewModel.hasMedicationLogsForDate(date),
                    hasJournal: viewModel.hasJournalEntriesForDate(date),
                    hasCalendarEvents: viewModel.hasCalendarEventsForDate(date),
                    calendarEventCount: viewModel.calendarEventCountForDate(date)
                )
                .onTapGesture {
                    HapticFeedback.selection.trigger()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if viewModel.isSelected(date) {
                            showingDayDetail = true
                        } else {
                            viewModel.selectedDate = date
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .cardStyle(theme: theme)
    }

    // MARK: - Selected Day Summary

    private func selectedDaySummary(for date: Date) -> some View {
        let entries = viewModel.entriesForDate(date)
        let categories = viewModel.categoriesForDate(date)
        let medicationLogs = viewModel.medicationLogsForDate(date)
        let journalEntries = viewModel.journalEntriesForDate(date)
        let calendarEvents = viewModel.calendarEventsForDate(date)

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text(date, style: .date)
                    .font(.headline)
                    .foregroundStyle(CardText.title)

                Spacer()

                if !entries.isEmpty || !medicationLogs.isEmpty || !journalEntries.isEmpty || !calendarEvents.isEmpty {
                    Button {
                        showingDayDetail = true
                    } label: {
                        Text("View Details")
                            .font(.subheadline)
                            .foregroundStyle(SemanticColor.primary)
                    }
                }
            }

            if entries.isEmpty && medicationLogs.isEmpty && journalEntries.isEmpty && calendarEvents.isEmpty {
                Text("No entries for this day")
                    .font(.body)
                    .foregroundStyle(CardText.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: Spacing.md) {
                    // Calendar events summary
                    if !calendarEvents.isEmpty {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(SemanticColor.calendar)
                            Text("\(calendarEvents.count) event\(calendarEvents.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(CardText.body)
                            Spacer()
                        }

                        // Show first few events
                        VStack(spacing: Spacing.sm) {
                            ForEach(calendarEvents.prefix(3)) { event in
                                HStack(spacing: Spacing.sm) {
                                    Text(event.timeString)
                                        .font(.caption)
                                        .foregroundStyle(CardText.caption)
                                        .frame(width: 60, alignment: .leading)
                                    Text(event.title)
                                        .font(.caption)
                                        .foregroundStyle(CardText.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            if calendarEvents.count > 3 {
                                Text("+\(calendarEvents.count - 3) more")
                                    .font(.caption)
                                    .foregroundStyle(CardText.caption)
                            }
                        }
                        .padding(.leading, 24)
                    }

                    // Pattern entries summary
                    if !entries.isEmpty {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .foregroundStyle(SemanticColor.primary)
                            Text("\(entries.count) pattern\(entries.count == 1 ? "" : "s") logged")
                                .font(.subheadline)
                                .foregroundStyle(CardText.body)
                            Spacer()
                        }

                        // Category breakdown
                        if !categories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(categories, id: \.self) { category in
                                        let count = entries.filter { $0.patternCategoryEnum == category }.count
                                        CategoryPill(category: category, count: count)
                                    }
                                }
                            }
                        }
                    }

                    // Medication logs summary
                    if !medicationLogs.isEmpty {
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundStyle(SemanticColor.success)
                            Text("\(medicationLogs.count) medication\(medicationLogs.count == 1 ? "" : "s") logged")
                                .font(.subheadline)
                                .foregroundStyle(CardText.body)
                            Spacer()
                        }
                    }

                    // Journal entries summary
                    if !journalEntries.isEmpty {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundStyle(SemanticColor.warning)
                            Text("\(journalEntries.count) journal entr\(journalEntries.count == 1 ? "y" : "ies")")
                                .font(.subheadline)
                                .foregroundStyle(CardText.body)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Legend")
                .font(.headline)
                .foregroundStyle(CardText.title)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(PatternCategory.allCases, id: \.self) { category in
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 12, height: 12)
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundStyle(CardText.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }

            Divider()
                .padding(.vertical, 4)

            HStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(SemanticColor.calendar)
                        .frame(width: 8, height: 8)
                    Text("Calendar")
                        .font(.caption)
                        .foregroundStyle(CardText.secondary)
                }

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "pills.fill")
                        .font(.caption)
                        .foregroundStyle(SemanticColor.success)
                    Text("Medication")
                        .font(.caption)
                        .foregroundStyle(CardText.secondary)
                }

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "book.fill")
                        .font(.caption)
                        .foregroundStyle(SemanticColor.warning)
                    Text("Journal")
                        .font(.caption)
                        .foregroundStyle(CardText.secondary)
                }
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, DataController.shared.container.viewContext)
}

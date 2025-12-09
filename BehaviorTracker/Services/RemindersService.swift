import Foundation
import EventKit

/// Service for syncing Goals and Wishlist items with Apple Reminders
@MainActor
class RemindersService: ObservableObject {
    static let shared = RemindersService()

    private let eventStore = EKEventStore()

    @Published var isAuthorized = false
    @Published var isSyncEnabled = false {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: "remindersSyncEnabled")
        }
    }
    @Published var lastError: RemindersError?
    @Published var syncStatus: SyncStatus = .idle

    // MARK: - Error Types

    enum RemindersError: LocalizedError {
        case accessDenied
        case listCreationFailed(String)
        case syncFailed(String)
        case saveFailed(String)

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Reminders access was denied. Please enable in Settings."
            case .listCreationFailed(let name):
                return "Failed to create '\(name)' list in Reminders."
            case .syncFailed(let item):
                return "Failed to sync '\(item)' with Reminders."
            case .saveFailed(let reason):
                return "Failed to save: \(reason)"
            }
        }
    }

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success(Int)
        case failed(String)

        var message: String? {
            switch self {
            case .idle: return nil
            case .syncing: return "Syncing..."
            case .success(let count): return "Synced \(count) items"
            case .failed(let error): return error
            }
        }
    }

    // List names in Apple Reminders
    private let goalsListName = "Tracker Goals"
    private let wishlistListName = "Tracker Wishlist"
    private let strugglesListName = "Tracker Struggles"

    // Cache for our reminder lists
    private var goalsCalendar: EKCalendar?
    private var wishlistCalendar: EKCalendar?
    private var strugglesCalendar: EKCalendar?

    private init() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: "remindersSyncEnabled")
        checkAuthorizationStatus()
    }

    /// Clears the current error state
    func clearError() {
        lastError = nil
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        isAuthorized = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            isAuthorized = granted
            if granted {
                await setupReminderLists()
            } else {
                lastError = .accessDenied
            }
            return granted
        } catch {
            lastError = .accessDenied
            return false
        }
    }

    // MARK: - Setup Reminder Lists

    private func setupReminderLists() async {
        goalsCalendar = findOrCreateList(named: goalsListName)
        wishlistCalendar = findOrCreateList(named: wishlistListName)
        strugglesCalendar = findOrCreateList(named: strugglesListName)
    }

    private func findOrCreateList(named name: String) -> EKCalendar? {
        let calendars = eventStore.calendars(for: .reminder)
        if let existing = calendars.first(where: { $0.title == name }) {
            return existing
        }

        let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        newCalendar.title = name

        let sources = eventStore.sources
        if let iCloudSource = sources.first(where: { $0.sourceType == .calDAV }) {
            newCalendar.source = iCloudSource
        } else if let localSource = sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else if let defaultSource = sources.first {
            newCalendar.source = defaultSource
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            return newCalendar
        } catch {
            lastError = .listCreationFailed(name)
            return nil
        }
    }

    // MARK: - Async Reminder Fetching

    private func fetchReminders(in calendar: EKCalendar) async -> [EKReminder] {
        let predicate = eventStore.predicateForReminders(in: [calendar])
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func findReminder(for id: UUID, in calendar: EKCalendar) async -> EKReminder? {
        let reminders = await fetchReminders(in: calendar)
        return reminders.first { $0.notes?.contains(id.uuidString) ?? false }
    }

    // MARK: - Sync Goals

    func syncGoal(_ goal: Goal) {
        guard isSyncEnabled, isAuthorized, let calendar = goalsCalendar else { return }

        Task {
            do {
                if let existingReminder = await findReminder(for: goal.id, in: calendar) {
                    try updateReminder(existingReminder, with: goal)
                } else {
                    try createReminder(for: goal, in: calendar)
                }
            } catch {
                lastError = .syncFailed(goal.title)
            }
        }
    }

    func syncGoalCompletion(_ goal: Goal) {
        guard isSyncEnabled, isAuthorized, let calendar = goalsCalendar else { return }

        Task {
            if let reminder = await findReminder(for: goal.id, in: calendar) {
                reminder.isCompleted = goal.isCompleted
                reminder.completionDate = goal.isCompleted ? Date() : nil
                do {
                    try eventStore.save(reminder, commit: true)
                } catch {
                    lastError = .saveFailed(error.localizedDescription)
                }
            }
        }
    }

    func deleteGoalReminder(_ goalID: UUID) {
        guard isSyncEnabled, isAuthorized, let calendar = goalsCalendar else { return }

        Task {
            if let reminder = await findReminder(for: goalID, in: calendar) {
                do {
                    try eventStore.remove(reminder, commit: true)
                } catch {
                    lastError = .saveFailed(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Sync Wishlist

    func syncWishlistItem(_ item: WishlistItem) {
        guard isSyncEnabled, isAuthorized, let calendar = wishlistCalendar else { return }

        Task {
            do {
                if let existingReminder = await findReminder(for: item.id, in: calendar) {
                    try updateReminder(existingReminder, with: item)
                } else {
                    try createReminder(for: item, in: calendar)
                }
            } catch {
                lastError = .syncFailed(item.title)
            }
        }
    }

    func syncWishlistCompletion(_ item: WishlistItem) {
        guard isSyncEnabled, isAuthorized, let calendar = wishlistCalendar else { return }

        Task {
            if let reminder = await findReminder(for: item.id, in: calendar) {
                reminder.isCompleted = item.isAcquired
                reminder.completionDate = item.isAcquired ? Date() : nil
                do {
                    try eventStore.save(reminder, commit: true)
                } catch {
                    lastError = .saveFailed(error.localizedDescription)
                }
            }
        }
    }

    func deleteWishlistReminder(_ itemID: UUID) {
        guard isSyncEnabled, isAuthorized, let calendar = wishlistCalendar else { return }

        Task {
            if let reminder = await findReminder(for: itemID, in: calendar) {
                do {
                    try eventStore.remove(reminder, commit: true)
                } catch {
                    lastError = .saveFailed(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Sync Struggles

    func syncStruggle(_ struggle: Struggle) {
        guard isSyncEnabled, isAuthorized, let calendar = strugglesCalendar else { return }

        Task {
            do {
                if let existingReminder = await findReminder(for: struggle.id, in: calendar) {
                    try updateReminder(existingReminder, with: struggle)
                } else {
                    try createReminder(for: struggle, in: calendar)
                }
            } catch {
                lastError = .syncFailed(struggle.title)
            }
        }
    }

    func syncStruggleResolution(_ struggle: Struggle) {
        guard isSyncEnabled, isAuthorized, let calendar = strugglesCalendar else { return }

        Task {
            if let reminder = await findReminder(for: struggle.id, in: calendar) {
                reminder.isCompleted = !struggle.isActive
                reminder.completionDate = struggle.isActive ? nil : Date()
                do {
                    try eventStore.save(reminder, commit: true)
                } catch {
                    lastError = .saveFailed(error.localizedDescription)
                }
            }
        }
    }

    func deleteStruggleReminder(_ struggleID: UUID) {
        guard isSyncEnabled, isAuthorized, let calendar = strugglesCalendar else { return }

        Task {
            if let reminder = await findReminder(for: struggleID, in: calendar) {
                do {
                    try eventStore.remove(reminder, commit: true)
                } catch {
                    lastError = .saveFailed(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Import from Reminders

    func importFromReminders() async -> (goals: [String], wishlist: [String], struggles: [String]) {
        guard isAuthorized else {
            lastError = .accessDenied
            return ([], [], [])
        }

        await setupReminderLists()

        var goals: [String] = []
        var wishlist: [String] = []
        var struggles: [String] = []

        if let goalsCalendar = goalsCalendar {
            goals = await fetchIncompleteTitles(from: goalsCalendar)
        }

        if let wishlistCalendar = wishlistCalendar {
            wishlist = await fetchIncompleteTitles(from: wishlistCalendar)
        }

        if let strugglesCalendar = strugglesCalendar {
            struggles = await fetchIncompleteTitles(from: strugglesCalendar)
        }

        return (goals, wishlist, struggles)
    }

    private func fetchIncompleteTitles(from calendar: EKCalendar) async -> [String] {
        let reminders = await fetchReminders(in: calendar)
        return reminders
            .filter { !$0.isCompleted }
            .compactMap { $0.title }
    }

    // MARK: - Helper Methods

    private func createReminder(for goal: Goal, in calendar: EKCalendar) throws {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        reminder.title = goal.title
        reminder.notes = "TrackerID: \(goal.id.uuidString)\n\(goal.notes ?? "")"
        reminder.priority = Int(goal.priority)

        if let dueDate = goal.dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: dueDate
            )
        }

        try eventStore.save(reminder, commit: true)
    }

    private func updateReminder(_ reminder: EKReminder, with goal: Goal) throws {
        reminder.title = goal.title
        reminder.priority = Int(goal.priority)

        if let dueDate = goal.dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: dueDate
            )
        } else {
            reminder.dueDateComponents = nil
        }

        try eventStore.save(reminder, commit: true)
    }

    private func createReminder(for item: WishlistItem, in calendar: EKCalendar) throws {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        reminder.title = item.title
        reminder.notes = "TrackerID: \(item.id.uuidString)\n\(item.notes ?? "")"
        reminder.priority = Int(item.priority)

        try eventStore.save(reminder, commit: true)
    }

    private func updateReminder(_ reminder: EKReminder, with item: WishlistItem) throws {
        reminder.title = item.title
        reminder.priority = Int(item.priority)

        try eventStore.save(reminder, commit: true)
    }

    private func createReminder(for struggle: Struggle, in calendar: EKCalendar) throws {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        reminder.title = struggle.title
        reminder.notes = "TrackerID: \(struggle.id.uuidString)\n\(struggle.notes ?? "")"
        reminder.priority = Int(struggle.intensity)

        try eventStore.save(reminder, commit: true)
    }

    private func updateReminder(_ reminder: EKReminder, with struggle: Struggle) throws {
        reminder.title = struggle.title
        reminder.priority = Int(struggle.intensity)

        try eventStore.save(reminder, commit: true)
    }

    // MARK: - Full Sync

    func performFullSync(
        goals: [Goal],
        wishlistItems: [WishlistItem],
        struggles: [Struggle]
    ) async {
        guard isSyncEnabled, isAuthorized else {
            if !isAuthorized {
                lastError = .accessDenied
            }
            syncStatus = .failed("Sync not enabled or not authorized")
            return
        }

        syncStatus = .syncing
        lastError = nil

        await setupReminderLists()

        var syncedCount = 0
        var hadError = false

        // Sync all goals
        for goal in goals {
            if let calendar = goalsCalendar {
                do {
                    if let existingReminder = await findReminder(for: goal.id, in: calendar) {
                        try updateReminder(existingReminder, with: goal)
                    } else {
                        try createReminder(for: goal, in: calendar)
                    }
                    syncedCount += 1
                } catch {
                    hadError = true
                    lastError = .syncFailed(goal.title)
                }
            }
        }

        // Sync all wishlist items
        for item in wishlistItems {
            if let calendar = wishlistCalendar {
                do {
                    if let existingReminder = await findReminder(for: item.id, in: calendar) {
                        try updateReminder(existingReminder, with: item)
                    } else {
                        try createReminder(for: item, in: calendar)
                    }
                    syncedCount += 1
                } catch {
                    hadError = true
                    lastError = .syncFailed(item.title)
                }
            }
        }

        // Sync all struggles
        for struggle in struggles {
            if let calendar = strugglesCalendar {
                do {
                    if let existingReminder = await findReminder(for: struggle.id, in: calendar) {
                        try updateReminder(existingReminder, with: struggle)
                    } else {
                        try createReminder(for: struggle, in: calendar)
                    }
                    syncedCount += 1
                } catch {
                    hadError = true
                    lastError = .syncFailed(struggle.title)
                }
            }
        }

        if hadError {
            syncStatus = .failed("Some items failed to sync")
        } else {
            syncStatus = .success(syncedCount)
        }

        // Auto-clear success status after delay
        if case .success = syncStatus {
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if case .success = syncStatus {
                    syncStatus = .idle
                }
            }
        }
    }
}

import SwiftUI
import CoreData
import Combine

@MainActor
class LifeGoalsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var goals: [Goal] = []
    @Published var wishlistItems: [WishlistItem] = []
    @Published var struggles: [Struggle] = []

    // Demo mode data
    @Published var demoGoals: [DemoModeService.DemoLifeGoal] = []
    @Published var demoWishlistItems: [DemoModeService.DemoWishlistItem] = []
    @Published var demoStruggles: [DemoModeService.DemoStruggle] = []

    @Published var showingAddGoal = false
    @Published var showingAddWishlistItem = false
    @Published var showingAddStruggle = false

    @Published var selectedGoal: Goal?
    @Published var selectedWishlistItem: WishlistItem?
    @Published var selectedStruggle: Struggle?

    // Celebration state for wishlist
    @Published var celebratingItem: WishlistItem?
    @Published var showCelebration = false

    // MARK: - Repositories & Services

    private let goalRepository = GoalRepository.shared
    private let wishlistRepository = WishlistRepository.shared
    private let struggleRepository = StruggleRepository.shared
    private let demoService = DemoModeService.shared
    let remindersService = RemindersService.shared
    private var cancellables = Set<AnyCancellable>()

    /// Whether we're currently in demo mode
    var isDemoMode: Bool {
        demoService.isEnabled
    }

    // MARK: - Computed Properties

    var activeGoalsCount: Int {
        if isDemoMode {
            return demoGoals.filter { $0.progress < 1.0 }.count
        }
        return goals.filter { !$0.isCompleted }.count
    }

    var overdueGoalsCount: Int {
        if isDemoMode {
            return demoGoals.filter { goal in
                if let dueDate = goal.dueDate {
                    return dueDate < Date() && goal.progress < 1.0
                }
                return false
            }.count
        }
        return goals.filter { $0.isOverdue }.count
    }

    var highPriorityWishlistCount: Int {
        if isDemoMode {
            return demoWishlistItems.filter { !$0.isAcquired }.count
        }
        return wishlistItems.filter { $0.priorityLevel == .high }.count
    }

    var severeStrugglesCount: Int {
        if isDemoMode {
            return demoStruggles.filter { $0.intensity == "Significant" || $0.intensity == "Severe" }.count
        }
        return struggles.filter { $0.intensityLevel.rawValue >= Struggle.Intensity.severe.rawValue }.count
    }

    var hasAnyItems: Bool {
        if isDemoMode {
            return !demoGoals.isEmpty || !demoWishlistItems.isEmpty || !demoStruggles.isEmpty
        }
        return !goals.isEmpty || !wishlistItems.isEmpty || !struggles.isEmpty
    }

    var completedCount: Int {
        if isDemoMode {
            let completedGoals = demoGoals.filter { $0.progress >= 1.0 }.count
            let acquiredWishes = demoWishlistItems.filter { $0.isAcquired }.count
            return completedGoals + acquiredWishes
        }
        let completedGoals = goalRepository.fetch(includeCompleted: true).filter { $0.isCompleted }.count
        let acquiredWishes = wishlistRepository.fetch(includeAcquired: true).filter { $0.isAcquired }.count
        return completedGoals + acquiredWishes
    }

    /// Goals count for UI display (demo-aware)
    var goalsCount: Int {
        if isDemoMode {
            return demoGoals.filter { $0.progress < 1.0 }.count
        }
        return goals.filter { !$0.isCompleted }.count
    }

    /// Struggles count for UI display (demo-aware)
    var strugglesCount: Int {
        if isDemoMode {
            return demoStruggles.count
        }
        return struggles.count
    }

    /// Wishlist count for UI display (demo-aware)
    var wishlistCount: Int {
        if isDemoMode {
            return demoWishlistItems.filter { !$0.isAcquired }.count
        }
        return wishlistItems.filter { !$0.isAcquired }.count
    }

    // MARK: - Lifecycle

    init() {
        loadData()
        observeDemoModeChanges()
    }

    private func observeDemoModeChanges() {
        NotificationCenter.default.publisher(for: .demoModeChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }

    func loadData() {
        if isDemoMode {
            loadDemoData()
            return
        }

        goals = goalRepository.fetch(includeCompleted: false)
        wishlistItems = wishlistRepository.fetch(includeAcquired: false)
        struggles = struggleRepository.fetch(activeOnly: true)

        // Clear demo data
        demoGoals = []
        demoWishlistItems = []
        demoStruggles = []
    }

    private func loadDemoData() {
        demoGoals = demoService.demoLifeGoals
        demoWishlistItems = demoService.demoWishlistItems
        demoStruggles = demoService.demoLifeStruggles

        // Clear real data
        goals = []
        wishlistItems = []
        struggles = []
    }

    func refresh() {
        loadData()
    }

    // MARK: - Goal Methods

    func createGoal(
        title: String,
        category: Goal.Category?,
        priority: Goal.Priority,
        notes: String?,
        dueDate: Date?
    ) {
        do {
            let goal = try goalRepository.create(
                title: title,
                category: category,
                priority: priority,
                notes: notes,
                dueDate: dueDate
            )
            remindersService.syncGoal(goal)
            loadData()
        } catch {
            print("Failed to create goal '\(title)': \(error.localizedDescription)")
        }
    }

    func toggleGoalComplete(_ goal: Goal) {
        if goal.isCompleted {
            goalRepository.markIncomplete(goal)
        } else {
            goalRepository.markComplete(goal)
        }
        remindersService.syncGoalCompletion(goal)
        loadData()
    }

    func updateGoalProgress(_ goal: Goal, progress: Double) {
        goalRepository.updateProgress(goal, progress: progress)
        remindersService.syncGoal(goal)
        loadData()
    }

    func deleteGoal(_ goal: Goal) {
        remindersService.deleteGoalReminder(goal.id)
        goalRepository.delete(goal)
        loadData()
    }

    func toggleGoalPin(_ goal: Goal) {
        goalRepository.togglePin(goal)
        loadData()
    }

    // MARK: - Wishlist Methods

    func createWishlistItem(
        title: String,
        category: WishlistItem.Category?,
        priority: WishlistItem.Priority,
        notes: String?
    ) {
        do {
            let item = try wishlistRepository.create(
                title: title,
                category: category,
                priority: priority,
                notes: notes
            )
            remindersService.syncWishlistItem(item)
            loadData()
        } catch {
            print("Failed to create wishlist item '\(title)': \(error.localizedDescription)")
        }
    }

    func toggleWishlistAcquired(_ item: WishlistItem) {
        if item.isAcquired {
            wishlistRepository.markNotAcquired(item)
            showCelebration = false
            celebratingItem = nil
        } else {
            wishlistRepository.markAcquired(item)
            // Trigger celebration!
            celebratingItem = item
            showCelebration = true

            // Auto-hide celebration after delay
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.showCelebration = false
                self?.celebratingItem = nil
            }
        }
        remindersService.syncWishlistCompletion(item)
        loadData()
    }

    func deleteWishlistItem(_ item: WishlistItem) {
        remindersService.deleteWishlistReminder(item.id)
        wishlistRepository.delete(item)
        loadData()
    }

    func toggleWishlistPin(_ item: WishlistItem) {
        wishlistRepository.togglePin(item)
        loadData()
    }

    // MARK: - Struggle Methods

    func createStruggle(
        title: String,
        category: Struggle.Category?,
        intensity: Struggle.Intensity,
        triggers: [String],
        copingStrategies: [String],
        notes: String?
    ) {
        do {
            let struggle = try struggleRepository.create(
                title: title,
                category: category,
                intensity: intensity,
                triggers: triggers,
                copingStrategies: copingStrategies,
                notes: notes
            )
            remindersService.syncStruggle(struggle)
            loadData()
        } catch {
            print("Failed to create struggle '\(title)': \(error.localizedDescription)")
        }
    }

    func resolveStruggle(_ struggle: Struggle) {
        struggleRepository.markResolved(struggle)
        remindersService.syncStruggleResolution(struggle)
        loadData()
    }

    func reactivateStruggle(_ struggle: Struggle) {
        struggleRepository.reactivate(struggle)
        remindersService.syncStruggle(struggle)
        loadData()
    }

    func updateStruggleIntensity(_ struggle: Struggle, intensity: Struggle.Intensity) {
        struggleRepository.updateIntensity(struggle, intensity: intensity)
        remindersService.syncStruggle(struggle)
        loadData()
    }

    func deleteStruggle(_ struggle: Struggle) {
        remindersService.deleteStruggleReminder(struggle.id)
        struggleRepository.delete(struggle)
        loadData()
    }

    func addTriggerToStruggle(_ struggle: Struggle, trigger: String) {
        struggleRepository.addTrigger(struggle, trigger: trigger)
        loadData()
    }

    func addCopingStrategyToStruggle(_ struggle: Struggle, strategy: String) {
        struggleRepository.addCopingStrategy(struggle, strategy: strategy)
        loadData()
    }

    func toggleStrugglePin(_ struggle: Struggle) {
        struggleRepository.togglePin(struggle)
        loadData()
    }
}

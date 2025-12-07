import SwiftUI
import CoreData

@MainActor
class LifeGoalsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var goals: [Goal] = []
    @Published var wishlistItems: [WishlistItem] = []
    @Published var struggles: [Struggle] = []

    @Published var showingAddGoal = false
    @Published var showingAddWishlistItem = false
    @Published var showingAddStruggle = false

    @Published var selectedGoal: Goal?
    @Published var selectedWishlistItem: WishlistItem?
    @Published var selectedStruggle: Struggle?

    // Celebration state for wishlist
    @Published var celebratingItem: WishlistItem?
    @Published var showCelebration = false

    // MARK: - Repositories

    private let goalRepository = GoalRepository.shared
    private let wishlistRepository = WishlistRepository.shared
    private let struggleRepository = StruggleRepository.shared

    // MARK: - Computed Properties

    var activeGoalsCount: Int {
        goals.filter { !$0.isCompleted }.count
    }

    var overdueGoalsCount: Int {
        goals.filter { $0.isOverdue }.count
    }

    var highPriorityWishlistCount: Int {
        wishlistItems.filter { $0.priorityLevel == .high }.count
    }

    var severeStrugglesCount: Int {
        struggles.filter { $0.intensityLevel.rawValue >= Struggle.Intensity.severe.rawValue }.count
    }

    var hasAnyItems: Bool {
        !goals.isEmpty || !wishlistItems.isEmpty || !struggles.isEmpty
    }

    var completedCount: Int {
        let completedGoals = goalRepository.fetch(includeCompleted: true).filter { $0.isCompleted }.count
        let acquiredWishes = wishlistRepository.fetch(includeAcquired: true).filter { $0.isAcquired }.count
        return completedGoals + acquiredWishes
    }

    // MARK: - Lifecycle

    init() {
        loadData()
    }

    func loadData() {
        goals = goalRepository.fetch(includeCompleted: false)
        wishlistItems = wishlistRepository.fetch(includeAcquired: false)
        struggles = struggleRepository.fetch(activeOnly: true)
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
            _ = try goalRepository.create(
                title: title,
                category: category,
                priority: priority,
                notes: notes,
                dueDate: dueDate
            )
            loadData()
        } catch {
        }
    }

    func toggleGoalComplete(_ goal: Goal) {
        if goal.isCompleted {
            goalRepository.markIncomplete(goal)
        } else {
            goalRepository.markComplete(goal)
        }
        loadData()
    }

    func updateGoalProgress(_ goal: Goal, progress: Double) {
        goalRepository.updateProgress(goal, progress: progress)
        loadData()
    }

    func deleteGoal(_ goal: Goal) {
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
            _ = try wishlistRepository.create(
                title: title,
                category: category,
                priority: priority,
                notes: notes
            )
            loadData()
        } catch {
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
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showCelebration = false
                celebratingItem = nil
            }
        }
        loadData()
    }

    func deleteWishlistItem(_ item: WishlistItem) {
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
            _ = try struggleRepository.create(
                title: title,
                category: category,
                intensity: intensity,
                triggers: triggers,
                copingStrategies: copingStrategies,
                notes: notes
            )
            loadData()
        } catch {
        }
    }

    func resolveStruggle(_ struggle: Struggle) {
        struggleRepository.markResolved(struggle)
        loadData()
    }

    func reactivateStruggle(_ struggle: Struggle) {
        struggleRepository.reactivate(struggle)
        loadData()
    }

    func updateStruggleIntensity(_ struggle: Struggle, intensity: Struggle.Intensity) {
        struggleRepository.updateIntensity(struggle, intensity: intensity)
        loadData()
    }

    func deleteStruggle(_ struggle: Struggle) {
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

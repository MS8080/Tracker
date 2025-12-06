import SwiftUI
import CoreData

@MainActor
class LoggingViewModel: ObservableObject {
    @Published var favoritePatterns: [String] = []
    @Published var isHealthKitEnabled = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var recentEntries: [PatternEntry] = []
    @Published var lastLoggedEntry: PatternEntry?
    @Published var showUndoToast: Bool = false

    private let dataController = DataController.shared
    private let healthKitManager = HealthKitManager.shared

    init() {
        // Don't load favorites here - defer to onAppear/task
    }

    // MARK: - Recent Entries

    func loadRecentEntries() {
        let today = Calendar.current.startOfDay(for: Date())
        recentEntries = dataController.fetchPatternEntries(startDate: today, endDate: Date())
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Time-based Suggestions

    var suggestedPatterns: [PatternType] {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<10: // Morning
            return [.sleepQuality, .energyLevel, .appetiteChange]
        case 10..<14: // Late morning/early afternoon
            return [.taskInitiation, .decisionFatigue, .hyperfocus]
        case 14..<18: // Afternoon
            return [.energyLevel, .maskingIntensity, .socialInteraction]
        case 18..<22: // Evening
            return [.socialRecovery, .burnoutIndicator, .regulatoryStimming]
        default: // Night
            return [.sleepQuality, .rumination, .sensoryRecovery]
        }
    }

    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Late night"
        }
    }

    // MARK: - Undo Support

    func undoLastEntry() {
        guard let entry = lastLoggedEntry else { return }
        dataController.deletePatternEntry(entry)
        lastLoggedEntry = nil
        showUndoToast = false
        loadRecentEntries()
    }
    
    /// Request HealthKit authorization
    func requestHealthKitAuthorization() async {
        await healthKitManager.requestAuthorization()
        isHealthKitEnabled = healthKitManager.isAuthorized
    }

    @MainActor
    func loadFavorites() {
        let preferences = dataController.getUserPreferences()
        favoritePatterns = preferences.favoritePatterns
    }

    func quickLog(patternType: PatternType, intensity: Int16 = 3) async -> Bool {
        do {
            let entry = try await dataController.createPatternEntry(
                patternType: patternType,
                intensity: intensity,
                duration: 0,
                contextNotes: nil,
                specificDetails: nil
            )
            dataController.updateStreak()
            lastLoggedEntry = entry
            showUndoToast = true
            loadRecentEntries()

            // Auto-hide undo toast after 5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await MainActor.run {
                    if self.showUndoToast {
                        self.showUndoToast = false
                    }
                }
            }

            // Sync to HealthKit in background
            Task.detached {
                await self.healthKitManager.syncPatternToHealthKit(
                    patternType: patternType,
                    intensity: intensity,
                    duration: 0
                )
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    func logPattern(
        patternType: PatternType,
        intensity: Int16,
        duration: Int32,
        contextNotes: String?,
        specificDetails: String?,
        isFavorite: Bool,
        contributingFactors: [ContributingFactor] = []
    ) async -> Bool {
        do {
            let entry = try await dataController.createPatternEntry(
                patternType: patternType,
                intensity: intensity,
                duration: duration,
                contextNotes: contextNotes,
                specificDetails: specificDetails,
                contributingFactors: contributingFactors
            )

            if isFavorite && !favoritePatterns.contains(patternType.rawValue) {
                addToFavorites(patternType: patternType)
            }

            dataController.updateStreak()
            lastLoggedEntry = entry
            showUndoToast = true
            loadRecentEntries()

            // Auto-hide undo toast after 5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await MainActor.run {
                    if self.showUndoToast {
                        self.showUndoToast = false
                    }
                }
            }

            // Sync to HealthKit in background
            Task.detached {
                await self.healthKitManager.syncPatternToHealthKit(
                    patternType: patternType,
                    intensity: intensity,
                    duration: duration
                )
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    func addToFavorites(patternType: PatternType) {
        let preferences = dataController.getUserPreferences()
        var favorites = preferences.favoritePatterns

        if !favorites.contains(patternType.rawValue) {
            favorites.append(patternType.rawValue)
            preferences.favoritePatterns = favorites
            dataController.save()
            loadFavorites()
        }
    }

    func removeFromFavorites(patternType: PatternType) {
        let preferences = dataController.getUserPreferences()
        var favorites = preferences.favoritePatterns

        if let index = favorites.firstIndex(of: patternType.rawValue) {
            favorites.remove(at: index)
            preferences.favoritePatterns = favorites
            dataController.save()
            loadFavorites()
        }
    }
}

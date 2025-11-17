import SwiftUI
import CoreData

@MainActor
class LoggingViewModel: ObservableObject {
    @Published var favoritePatterns: [String] = []
    @Published var isHealthKitEnabled = false
    
    private let dataController = DataController.shared
    private let healthKitManager = HealthKitManager.shared

    init() {
        // Don't load favorites here - defer to onAppear/task
    }
    
    /// Request HealthKit authorization
    @MainActor
    func requestHealthKitAuthorization() async {
        await healthKitManager.requestAuthorization()
        isHealthKitEnabled = healthKitManager.isAuthorized
    }

    @MainActor
    func loadFavorites() {
        let preferences = dataController.getUserPreferences()
        favoritePatterns = preferences.favoritePatterns
    }

    func quickLog(patternType: PatternType) {
        let _ = dataController.createPatternEntry(
            patternType: patternType,
            intensity: 3,
            duration: 0,
            contextNotes: nil,
            specificDetails: nil
        )
        dataController.updateStreak()
        
        // Sync to HealthKit
        Task { [healthKitManager] in
            await healthKitManager.syncPatternToHealthKit(
                patternType: patternType,
                intensity: 3,
                duration: 0
            )
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
    ) {
        _ = dataController.createPatternEntry(
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
        
        // Sync to HealthKit
        Task { [healthKitManager] in
            await healthKitManager.syncPatternToHealthKit(
                patternType: patternType,
                intensity: intensity,
                duration: duration
            )
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

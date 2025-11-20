import Foundation
import HealthKit

/// Manages all HealthKit interactions for syncing pattern data with Apple Health
@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    
    private let healthStore = HKHealthStore()
    
    // MARK: - HealthKit Data Types
    
    /// Data types we want to write to HealthKit
    private var typesToWrite: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        
        // Mindfulness (for recovery periods, shutdown episodes)
        if let mindfulness = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulness)
        }
        
        // Sleep (for sleep quality tracking)
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        
        // State of Mind (for emotional regulation, anxiety, etc.)
        if #available(iOS 18.0, *) {
            types.insert(HKObjectType.stateOfMindType())
        }
        
        return types
    }
    
    /// Data types we want to read from HealthKit
    private var typesToRead: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        
        // Read the same types we write
        if let mindfulness = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulness)
        }
        
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        
        if #available(iOS 18.0, *) {
            types.insert(HKObjectType.stateOfMindType())
        }
        
        // Also read heart rate for context
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        
        // Read activity energy
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        
        return types
    }
    
    // MARK: - Authorization
    
    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        #if targetEnvironment(simulator)
        // HealthKit has limited support in the simulator
        return false
        #else
        return HKHealthStore.isHealthDataAvailable()
        #endif
    }
    
    /// Request authorization to access HealthKit data
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit is not available on this device"
            return
        }
        
        // Ensure we have types to request
        guard !typesToWrite.isEmpty || !typesToRead.isEmpty else {
            authorizationError = "No HealthKit types configured"
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            authorizationError = nil
        } catch {
            authorizationError = error.localizedDescription
            isAuthorized = false
            print("HealthKit authorization error: \(error)")
        }
    }
    
    // MARK: - Writing Data
    
    /// Log a pattern entry to HealthKit where applicable
    func syncPatternToHealthKit(
        patternType: PatternType,
        intensity: Int16,
        duration: Int32,
        timestamp: Date = Date()
    ) async {
        guard isAuthorized else { return }
        
        switch patternType {
        // Emotional Regulation patterns -> State of Mind
        case .meltdown, .shutdown:
            await logStateOfMind(
                for: patternType,
                intensity: intensity,
                timestamp: timestamp
            )

        // Recovery patterns -> Mindfulness sessions
        case .sensoryRecovery, .socialRecovery, .regulatoryStimming:
            if duration > 0 {
                await logMindfulSession(
                    duration: TimeInterval(duration * 60), // Convert minutes to seconds
                    timestamp: timestamp
                )
            }

        // Sleep patterns -> Sleep Analysis
        case .sleepQuality:
            await logSleepQuality(
                intensity: intensity,
                timestamp: timestamp
            )

        // Energy patterns -> State of Mind (energy component)
        case .energyLevel, .burnoutIndicator:
            await logEnergyStateOfMind(
                for: patternType,
                intensity: intensity,
                timestamp: timestamp
            )
            
        default:
            // Other patterns don't have direct HealthKit equivalents
            break
        }
    }
    
    /// Log a State of Mind sample for emotional patterns
    private func logStateOfMind(
        for patternType: PatternType,
        intensity: Int16,
        timestamp: Date
    ) async {
        guard #available(iOS 18.0, *) else { return }
        
        // Map intensity (1-5) to valence (-1 to 1)
        // Higher intensity for negative patterns means more negative valence
        let valence = Double(3 - intensity) / 2.0 // Maps 1->1, 3->0, 5->-1
        
        // Determine the kind and labels based on pattern type
        let kind: HKStateOfMind.Kind = .momentaryEmotion
        var labels: [HKStateOfMind.Label] = []
        
        switch patternType {
        case .meltdown:
            labels = [.stressed, .overwhelmed]
        case .shutdown:
            labels = [.drained]
        default:
            break
        }
        
        let stateOfMind = HKStateOfMind(
            date: timestamp,
            kind: kind,
            valence: valence,
            labels: labels,
            associations: []
        )
        
        do {
            try await healthStore.save(stateOfMind)
        } catch {
            print("Failed to save state of mind: \(error.localizedDescription)")
        }
    }
    
    /// Log energy-related State of Mind
    private func logEnergyStateOfMind(
        for patternType: PatternType,
        intensity: Int16,
        timestamp: Date
    ) async {
        guard #available(iOS 18.0, *) else { return }
        
        // For energy level: higher intensity = more energy = positive valence
        // For burnout warning: higher intensity = worse burnout = negative valence
        let valence: Double
        var labels: [HKStateOfMind.Label] = []
        
        switch patternType {
        case .energyLevel:
            valence = Double(intensity - 3) / 2.0 // Maps 1->-1, 3->0, 5->1
            if intensity >= 4 {
                labels = [.peaceful]
            } else if intensity <= 2 {
                labels = [.drained]
            }
        case .burnoutIndicator:
            valence = Double(3 - intensity) / 2.0 // Maps 1->1, 3->0, 5->-1
            labels = [.drained, .stressed]
        default:
            return
        }
        
        let stateOfMind = HKStateOfMind(
            date: timestamp,
            kind: .dailyMood,
            valence: valence,
            labels: labels,
            associations: []
        )
        
        do {
            try await healthStore.save(stateOfMind)
        } catch {
            print("Failed to save energy state of mind: \(error.localizedDescription)")
        }
    }
    
    /// Log a mindfulness session for recovery periods
    private func logMindfulSession(duration: TimeInterval, timestamp: Date) async {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return
        }
        
        let endDate = timestamp
        let startDate = timestamp.addingTimeInterval(-duration)
        
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )
        
        do {
            try await healthStore.save(sample)
        } catch {
            print("Failed to save mindful session: \(error.localizedDescription)")
        }
    }
    
    /// Log sleep quality as a sleep analysis sample
    private func logSleepQuality(intensity: Int16, timestamp: Date) async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }
        
        // Map intensity to sleep value
        // This logs a sleep entry for the previous night
        let sleepEnd = timestamp
        let sleepStart = Calendar.current.date(byAdding: .hour, value: -8, to: timestamp) ?? timestamp
        
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: sleepStart,
            end: sleepEnd,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "PatternIntensity": intensity
            ]
        )
        
        do {
            try await healthStore.save(sample)
        } catch {
            print("Failed to save sleep quality: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reading Data
    
    /// Fetch recent heart rate data for context
    func fetchRecentHeartRate() async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch today's active energy for context
    func fetchTodayActiveEnergy() async -> Double? {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let energy = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: energy)
            }
            
            healthStore.execute(query)
        }
    }
}

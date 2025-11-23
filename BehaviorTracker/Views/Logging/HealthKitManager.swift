#if os(iOS)
import Foundation
import HealthKit

/// Manages all HealthKit interactions for syncing pattern data with Apple Health
class HealthKitManager: ObservableObject, @unchecked Sendable {
    static let shared = HealthKitManager()

    @MainActor @Published var isAuthorized = false
    @MainActor @Published var authorizationError: String?

    private let healthStore = HKHealthStore()

    init() {
        // Authorization status will be checked when views appear
        // Don't call async code in init to avoid crashes
    }

    /// Check if we already have HealthKit authorization
    @MainActor
    func checkAuthorizationStatus() async {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }

        // Check authorization status for a key type we need
        // If any read type is authorized, consider it connected
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            _ = healthStore.authorizationStatus(for: stepType)
            // .sharingAuthorized means we have write permission
            // For read permission, we can't directly check, but if we requested before
            // and user granted, the data will be available

            // Try to determine if we have some level of authorization
            // by checking if we can query data
            let authorized = await checkIfCanReadHealthData()
            isAuthorized = authorized
        }
    }

    /// Try to read some health data to verify we have authorization
    private func checkIfCanReadHealthData() async -> Bool {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stepType,
                predicate: nil,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                // If we get samples or no error, we likely have authorization
                // Note: empty samples with no error also means authorized but no data
                if error == nil {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
            healthStore.execute(query)
        }
    }
    
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

        // Vitals and body measurements
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }

        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }

        if let heartRateVariability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(heartRateVariability)
        }

        if let bodyWeight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyWeight)
        }

        if let bodyTemp = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemp)
        }

        if let bloodPressureSystolic = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
            types.insert(bloodPressureSystolic)
        }

        if let bloodPressureDiastolic = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(bloodPressureDiastolic)
        }

        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respiratoryRate)
        }

        if let oxygenSaturation = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(oxygenSaturation)
        }

        // Activity and fitness
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }

        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }

        if let distanceWalking = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distanceWalking)
        }

        if let exerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseTime)
        }

        if let standTime = HKObjectType.quantityType(forIdentifier: .appleStandTime) {
            types.insert(standTime)
        }

        // Nutrition
        if let water = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }

        if let caffeine = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine) {
            types.insert(caffeine)
        }

        // Note: Clinical Health Records (like .medicationRecord) require special entitlements
        // that need Apple approval. Omitted to prevent crashes.

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
            await MainActor.run {
                authorizationError = "HealthKit is not available on this device"
            }
            return
        }

        // Ensure we have types to request
        guard !typesToWrite.isEmpty || !typesToRead.isEmpty else {
            await MainActor.run {
                authorizationError = "No HealthKit types configured"
            }
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                isAuthorized = true
                authorizationError = nil
            }
        } catch {
            await MainActor.run {
                authorizationError = error.localizedDescription
                isAuthorized = false
            }
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
        let authorized = await MainActor.run { isAuthorized }
        guard authorized else { return }
        
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
            // Only log if duration is provided (actual sleep hours)
            if duration > 0 {
                await logSleepQuality(
                    intensity: intensity,
                    duration: duration,
                    timestamp: timestamp
                )
            }

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
    /// - Parameters:
    ///   - intensity: Sleep quality rating (1-5)
    ///   - duration: Sleep duration in minutes
    ///   - timestamp: When the sleep ended (typically morning)
    private func logSleepQuality(intensity: Int16, duration: Int32, timestamp: Date) async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        // Use actual duration provided by user (in minutes)
        let durationInSeconds = TimeInterval(duration * 60)
        let sleepEnd = timestamp
        let sleepStart = timestamp.addingTimeInterval(-durationInSeconds)

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

    // MARK: - Body Measurements

    /// Fetch the most recent weight measurement
    func fetchLatestWeight() async -> (value: Double, date: Date)? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: (value: weightInKg, date: sample.endDate))
            }

            healthStore.execute(query)
        }
    }

    /// Fetch weight history for a date range
    func fetchWeightHistory(startDate: Date, endDate: Date = Date()) async -> [(value: Double, date: Date)] {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let weights = samples.map { sample in
                    (value: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)), date: sample.endDate)
                }
                continuation.resume(returning: weights)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Data

    /// Fetch sleep data for a date range
    func fetchSleepData(startDate: Date, endDate: Date = Date()) async -> [(duration: TimeInterval, quality: String, date: Date)] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let sleepData = samples.map { sample -> (duration: TimeInterval, quality: String, date: Date) in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)

                    let quality: String
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        quality = "Core Sleep"
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        quality = "Deep Sleep"
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        quality = "REM Sleep"
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        quality = "Awake"
                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                        quality = "In Bed"
                    default:
                        quality = "Asleep"
                    }

                    return (duration: duration, quality: quality, date: sample.endDate)
                }
                continuation.resume(returning: sleepData)
            }

            healthStore.execute(query)
        }
    }

    /// Get total sleep duration for last night
    func fetchLastNightSleep() async -> TimeInterval? {
        let calendar = Calendar.current
        let now = Date()

        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!

        let sleepData = await fetchSleepData(startDate: startOfYesterday, endDate: startOfToday)

        let totalSleep = sleepData.reduce(0.0) { total, sleep in
            if sleep.quality.contains("Sleep") && sleep.quality != "In Bed" {
                return total + sleep.duration
            }
            return total
        }

        return totalSleep > 0 ? totalSleep : nil
    }

    // MARK: - Vital Signs

    /// Fetch resting heart rate
    func fetchRestingHeartRate() async -> Double? {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch heart rate variability (HRV)
    func fetchHeartRateVariability() async -> Double? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrv)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch blood pressure reading
    func fetchLatestBloodPressure() async -> (systolic: Double, diastolic: Double, date: Date)? {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: systolicType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, _ in
                guard let systolicSample = samples?.first as? HKQuantitySample,
                      let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                let systolic = systolicSample.quantity.doubleValue(for: .millimeterOfMercury())
                let timestamp = systolicSample.endDate

                Task {
                    let diastolic = await self.fetchDiastolicForTimestamp(timestamp, type: diastolicType)
                    if let diastolic = diastolic {
                        continuation.resume(returning: (systolic: systolic, diastolic: diastolic, date: timestamp))
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }

            healthStore.execute(query)
        }
    }

    private func fetchDiastolicForTimestamp(_ timestamp: Date, type: HKQuantityType) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: timestamp.addingTimeInterval(-60), end: timestamp.addingTimeInterval(60), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let diastolic = sample.quantity.doubleValue(for: .millimeterOfMercury())
                continuation.resume(returning: diastolic)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Activity Data

    /// Fetch today's step count
    func fetchTodaySteps() async -> Double? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let steps = sum.doubleValue(for: .count())
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch today's exercise minutes
    func fetchTodayExerciseMinutes() async -> Double? {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let minutes = sum.doubleValue(for: .minute())
                continuation.resume(returning: minutes)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Nutrition Data

    /// Fetch today's water intake
    func fetchTodayWaterIntake() async -> Double? {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let liters = sum.doubleValue(for: .literUnit(with: .milli)) / 1000.0
                continuation.resume(returning: liters)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch today's caffeine intake
    func fetchTodayCaffeineIntake() async -> Double? {
        guard let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caffeineType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let mg = sum.doubleValue(for: .gramUnit(with: .milli))
                continuation.resume(returning: mg)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Mindfulness Data

    /// Fetch mindfulness sessions
    func fetchMindfulnessSessions(startDate: Date, endDate: Date = Date()) async -> [(duration: TimeInterval, date: Date)] {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let sessions = samples.map { sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    return (duration: duration, date: sample.endDate)
                }
                continuation.resume(returning: sessions)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Comprehensive Health Summary

    /// Fetch a comprehensive health data summary
    func fetchHealthSummary() async -> HealthDataSummary {
        async let weight = fetchLatestWeight()
        async let sleepDuration = fetchLastNightSleep()
        async let heartRate = fetchRecentHeartRate()
        async let restingHR = fetchRestingHeartRate()
        async let hrv = fetchHeartRateVariability()
        async let bloodPressure = fetchLatestBloodPressure()
        async let steps = fetchTodaySteps()
        async let exerciseMinutes = fetchTodayExerciseMinutes()
        async let activeEnergy = fetchTodayActiveEnergy()
        async let water = fetchTodayWaterIntake()
        async let caffeine = fetchTodayCaffeineIntake()

        return await HealthDataSummary(
            weight: weight?.value,
            weightDate: weight?.date,
            sleepDuration: sleepDuration,
            heartRate: heartRate,
            restingHeartRate: restingHR,
            heartRateVariability: hrv,
            bloodPressure: bloodPressure != nil ? (systolic: bloodPressure!.systolic, diastolic: bloodPressure!.diastolic) : nil,
            bloodPressureDate: bloodPressure?.date,
            steps: steps,
            exerciseMinutes: exerciseMinutes,
            activeEnergy: activeEnergy,
            waterIntake: water,
            caffeineIntake: caffeine
        )
    }
}

// MARK: - Health Data Summary Model

struct HealthDataSummary {
    let weight: Double?
    let weightDate: Date?
    let sleepDuration: TimeInterval?
    let heartRate: Double?
    let restingHeartRate: Double?
    let heartRateVariability: Double?
    let bloodPressure: (systolic: Double, diastolic: Double)?
    let bloodPressureDate: Date?
    let steps: Double?
    let exerciseMinutes: Double?
    let activeEnergy: Double?
    let waterIntake: Double?
    let caffeineIntake: Double?

    var sleepHours: Double? {
        guard let duration = sleepDuration else { return nil }
        return duration / 3600.0
    }
}
#else
// macOS stub - HealthKit is not available on macOS
import Foundation

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    @MainActor @Published var isAuthorized = false
    @MainActor @Published var authorizationError: String?

    var isHealthKitAvailable: Bool { false }

    func requestAuthorization() async {
        await MainActor.run {
            authorizationError = "HealthKit is not available on macOS"
        }
    }

    func syncPatternToHealthKit(patternType: PatternType, intensity: Int16, duration: Int32, timestamp: Date = Date()) async {}
    func fetchRecentHeartRate() async -> Double? { nil }
    func fetchTodayActiveEnergy() async -> Double? { nil }
    func fetchLatestWeight() async -> (value: Double, date: Date)? { nil }
    func fetchWeightHistory(startDate: Date, endDate: Date = Date()) async -> [(value: Double, date: Date)] { [] }
    func fetchSleepData(startDate: Date, endDate: Date = Date()) async -> [(duration: TimeInterval, quality: String, date: Date)] { [] }
    func fetchLastNightSleep() async -> TimeInterval? { nil }
    func fetchRestingHeartRate() async -> Double? { nil }
    func fetchHeartRateVariability() async -> Double? { nil }
    func fetchLatestBloodPressure() async -> (systolic: Double, diastolic: Double, date: Date)? { nil }
    func fetchTodaySteps() async -> Double? { nil }
    func fetchTodayExerciseMinutes() async -> Double? { nil }
    func fetchTodayWaterIntake() async -> Double? { nil }
    func fetchTodayCaffeineIntake() async -> Double? { nil }
    func fetchMindfulnessSessions(startDate: Date, endDate: Date = Date()) async -> [(duration: TimeInterval, date: Date)] { [] }
    func fetchHealthSummary() async -> HealthDataSummary {
        HealthDataSummary(
            weight: nil, weightDate: nil, sleepDuration: nil, heartRate: nil,
            restingHeartRate: nil, heartRateVariability: nil, bloodPressure: nil,
            bloodPressureDate: nil, steps: nil, exerciseMinutes: nil,
            activeEnergy: nil, waterIntake: nil, caffeineIntake: nil
        )
    }
}

struct HealthDataSummary {
    let weight: Double?
    let weightDate: Date?
    let sleepDuration: TimeInterval?
    let heartRate: Double?
    let restingHeartRate: Double?
    let heartRateVariability: Double?
    let bloodPressure: (systolic: Double, diastolic: Double)?
    let bloodPressureDate: Date?
    let steps: Double?
    let exerciseMinutes: Double?
    let activeEnergy: Double?
    let waterIntake: Double?
    let caffeineIntake: Double?

    var sleepHours: Double? {
        guard let duration = sleepDuration else { return nil }
        return duration / 3600.0
    }
}
#endif

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

        // Category types
        let categoryIds: [HKCategoryTypeIdentifier] = [.mindfulSession, .sleepAnalysis]
        for id in categoryIds {
            if let type = HKObjectType.categoryType(forIdentifier: id) {
                types.insert(type)
            }
        }

        if #available(iOS 18.0, *) {
            types.insert(HKObjectType.stateOfMindType())
        }

        // Quantity types
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
            .bodyMass, .bodyTemperature, .bloodPressureSystolic, .bloodPressureDiastolic,
            .respiratoryRate, .oxygenSaturation, .activeEnergyBurned, .stepCount,
            .distanceWalkingRunning, .appleExerciseTime, .appleStandTime,
            .dietaryWater, .dietaryCaffeine
        ]
        for id in quantityIds {
            if let type = HKObjectType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }

        return types
    }
    
    // MARK: - Medication Import Support
    
    /// Check if medication records are available (requires special entitlement)
    func hasMedicationRecordAccess() -> Bool {
        if #available(iOS 16.0, *) {
            // This will only work if app has clinical health records entitlement
            if let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) {
                let status = healthStore.authorizationStatus(for: medicationType)
                return status == .sharingAuthorized
            }
        }
        return false
    }
    
    /// Import medications from Apple Health (requires clinical records entitlement)
    @available(iOS 16.0, *)
    func importMedications() async throws -> [MedicationImportData] {
        guard let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else {
            throw HealthKitError.unsupportedDataType
        }
        
        // Request authorization if needed
        try await healthStore.requestAuthorization(toShare: [], read: [medicationType])
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: medicationType,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                guard let clinicalRecords = samples as? [HKClinicalRecord] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let medications = clinicalRecords.compactMap { record -> MedicationImportData? in
                    // Extract FHIR data
                    guard let fhirResource = record.fhirResource else {
                        return nil
                    }
                    
                    let resourceData = fhirResource.data
                    
                    guard let json = try? JSONSerialization.jsonObject(with: resourceData) as? [String: Any],
                          let medicationInfo = json["medicationCodeableConcept"] as? [String: Any],
                          let coding = (medicationInfo["coding"] as? [[String: Any]])?.first,
                          let display = coding["display"] as? String else {
                        return nil
                    }
                    
                    // Extract dosage if available
                    let dosageText = (json["dosageInstruction"] as? [[String: Any]])?.first?["text"] as? String
                    
                    return MedicationImportData(
                        name: display,
                        dosage: dosageText,
                        startDate: record.startDate
                    )
                }
                
                continuation.resume(returning: medications)
            }
            
            healthStore.execute(query)
        }
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
        }
    }
    
    // MARK: - Generic Fetch Helpers

    /// Fetch latest quantity sample
    private func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type, predicate: nil, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    /// Fetch today's cumulative sum for a quantity type
    private func fetchTodaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate
        )
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Reading Data

    func fetchRecentHeartRate() async -> Double? {
        await fetchLatestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchTodayActiveEnergy() async -> Double? {
        await fetchTodaySum(.activeEnergyBurned, unit: .kilocalorie())
    }

    func fetchLatestWeight() async -> (value: Double, date: Date)? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type, predicate: nil, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (sample.quantity.doubleValue(for: .gramUnit(with: .kilo)), sample.endDate))
            }
            healthStore.execute(query)
        }
    }

    func fetchWeightHistory(startDate: Date, endDate: Date = Date()) async -> [(value: Double, date: Date)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            ) { _, samples, _ in
                let weights = (samples as? [HKQuantitySample])?.map {
                    ($0.quantity.doubleValue(for: .gramUnit(with: .kilo)), $0.endDate)
                } ?? []
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
    /// Looks for sleep that started after 6 PM yesterday and ended before noon today
    func fetchLastNightSleep() async -> TimeInterval? {
        let calendar = Calendar.current
        let now = Date()

        // Define the sleep window: 6 PM yesterday to 12 PM today
        let startOfToday = calendar.startOfDay(for: now)
        var components = DateComponents()
        components.hour = 18 // 6 PM
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let sleepWindowStart = calendar.date(byAdding: components, to: yesterday) else {
            return nil
        }

        components.hour = 12 // 12 PM (noon)
        guard let sleepWindowEnd = calendar.date(byAdding: components, to: startOfToday) else {
            return nil
        }

        let sleepData = await fetchSleepData(startDate: sleepWindowStart, endDate: sleepWindowEnd)

        // Only count actual sleep stages (not "In Bed" or "Awake")
        let totalSleep = sleepData.reduce(0.0) { total, sleep in
            let qualityLower = sleep.quality.lowercased()
            if qualityLower.contains("sleep") || qualityLower.contains("asleep") {
                if !qualityLower.contains("in bed") && !qualityLower.contains("awake") {
                    return total + sleep.duration
                }
            }
            return total
        }

        return totalSleep > 0 ? totalSleep : nil
    }

    // MARK: - Vital Signs

    func fetchRestingHeartRate() async -> Double? {
        await fetchLatestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchHeartRateVariability() async -> Double? {
        await fetchLatestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
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

    func fetchTodaySteps() async -> Double? {
        await fetchTodaySum(.stepCount, unit: .count())
    }

    func fetchTodayExerciseMinutes() async -> Double? {
        await fetchTodaySum(.appleExerciseTime, unit: .minute())
    }

    // MARK: - Nutrition Data

    func fetchTodayWaterIntake() async -> Double? {
        guard let ml = await fetchTodaySum(.dietaryWater, unit: .literUnit(with: .milli)) else { return nil }
        return ml / 1000.0
    }

    func fetchTodayCaffeineIntake() async -> Double? {
        await fetchTodaySum(.dietaryCaffeine, unit: .gramUnit(with: .milli))
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
            bloodPressure: bloodPressure.map { (systolic: $0.systolic, diastolic: $0.diastolic) },
            bloodPressureDate: bloodPressure?.date,
            steps: steps,
            exerciseMinutes: exerciseMinutes,
            activeEnergy: activeEnergy,
            waterIntake: water,
            caffeineIntake: caffeine
        )
    }
}

// MARK: - Medication Import Data Model

struct MedicationImportData {
    let name: String
    let dosage: String?
    let startDate: Date
}

// MARK: - HealthKit Error

enum HealthKitError: LocalizedError {
    case unsupportedDataType
    case noAuthorization
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedDataType:
            return "This data type is not supported on your device"
        case .noAuthorization:
            return "HealthKit authorization is required"
        case .queryFailed(let message):
            return "Failed to fetch data: \(message)"
        }
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

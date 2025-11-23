import Foundation
import SwiftUI
import Combine

class MedicationViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var todaysLogs: [MedicationLog] = []
    @Published var showingAddMedication = false
    @Published var showingLogMedication = false
    @Published var selectedMedication: Medication?
    @Published var isLoading = false

    private let dataController: DataController
    private var hasLoadedInitially = false

    init(dataController: DataController = .shared) {
        self.dataController = dataController
        // Don't load in init - let views call loadMedications() in onAppear
    }

    func loadMedications() {
        // Load on background thread to avoid blocking UI
        Task { @MainActor in
            let meds = dataController.fetchMedications(activeOnly: true)
            self.medications = meds
        }
    }

    func loadTodaysLogs() {
        Task { @MainActor in
            let logs = dataController.getTodaysMedicationLogs()
            self.todaysLogs = logs
        }
    }

    func loadDataIfNeeded() {
        guard !hasLoadedInitially else { return }
        hasLoadedInitially = true
        loadMedications()
        loadTodaysLogs()
    }

    func addMedication(name: String, dosage: String?, frequency: MedicationFrequency, notes: String?) {
        _ = dataController.createMedication(
            name: name,
            dosage: dosage,
            frequency: frequency.rawValue,
            notes: notes
        )
        loadMedications()
    }

    func deactivateMedication(_ medication: Medication) {
        medication.isActive = false
        dataController.updateMedication(medication)
        loadMedications()
    }

    func deleteMedication(_ medication: Medication) {
        dataController.deleteMedication(medication)
        loadMedications()
    }

    func logMedication(
        medication: Medication,
        taken: Bool,
        skippedReason: String?,
        sideEffects: String?,
        effectiveness: Int,
        mood: Int,
        energyLevel: Int,
        notes: String?
    ) {
        _ = dataController.createMedicationLog(
            medication: medication,
            taken: taken,
            skippedReason: skippedReason,
            sideEffects: sideEffects,
            effectiveness: Int16(effectiveness),
            mood: Int16(mood),
            energyLevel: Int16(energyLevel),
            notes: notes
        )
        loadTodaysLogs()
    }

    func hasTakenToday(medication: Medication) -> Bool {
        todaysLogs.contains { log in
            log.medication?.id == medication.id && log.taken
        }
    }

    func getTodaysLog(for medication: Medication) -> MedicationLog? {
        todaysLogs.first { $0.medication?.id == medication.id }
    }

    func getMedicationLogs(for medication: Medication, days: Int = 30) -> [MedicationLog] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
        return dataController.fetchMedicationLogs(
            startDate: startDate,
            endDate: Date(),
            medication: medication
        )
    }

    func getAverageEffectiveness(for medication: Medication, days: Int = 7) -> Double {
        let logs = getMedicationLogs(for: medication, days: days)
        let validLogs = logs.filter { $0.taken && $0.effectiveness > 0 }

        guard !validLogs.isEmpty else { return 0 }

        let sum = validLogs.reduce(0) { $0 + Int($1.effectiveness) }
        return Double(sum) / Double(validLogs.count)
    }

    func getAverageMood(for medication: Medication, days: Int = 7) -> Double {
        let logs = getMedicationLogs(for: medication, days: days)
        let validLogs = logs.filter { $0.taken && $0.mood > 0 }

        guard !validLogs.isEmpty else { return 0 }

        let sum = validLogs.reduce(0) { $0 + Int($1.mood) }
        return Double(sum) / Double(validLogs.count)
    }

    func getAdherenceRate(for medication: Medication, days: Int = 7) -> Double {
        let logs = getMedicationLogs(for: medication, days: days)
        guard !logs.isEmpty else { return 0 }

        let takenCount = logs.filter { $0.taken }.count
        return Double(takenCount) / Double(logs.count) * 100
    }
}

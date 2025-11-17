import SwiftUI
import CoreData

class MedicationViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var todaysLogs: [MedicationLog] = []
    
    private let dataController = DataController.shared
    
    func loadMedications() {
        let context = dataController.container.viewContext
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.name, ascending: true)]
        
        do {
            medications = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching medications: \(error)")
            medications = []
        }
    }
    
    func loadTodaysLogs() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let context = dataController.container.viewContext
        let fetchRequest = NSFetchRequest<MedicationLog>(entityName: "MedicationLog")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@ AND taken == YES",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            todaysLogs = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching today's medication logs: \(error)")
            todaysLogs = []
        }
    }
    
    func hasTakenToday(medication: Medication) -> Bool {
        return todaysLogs.contains { log in
            log.medication?.id == medication.id && log.taken
        }
    }
}

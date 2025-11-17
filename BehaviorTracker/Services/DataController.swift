import CoreData
import Foundation
import CoreData

class DataController: ObservableObject {
    static let shared = DataController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BehaviorTrackerModel")
        
        print("DataController: Initializing with model name: BehaviorTrackerModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable lightweight migration on the existing store description
            if let description = container.persistentStoreDescriptions.first {
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
                print("DataController: Store URL: \(description.url?.absoluteString ?? "nil")")
            }
        }
        
        print("DataController: About to load persistent stores...")

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Log the error but don't try to reload - this can cause deadlocks
                print("Core Data failed to load: \(error.localizedDescription)")
                print("Error details: \(error.userInfo)")
                
                // If you want to handle this, delete the store and restart the app
                // For now, we'll let it fail gracefully
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            } else {
                print("Core Data store loaded successfully: \(storeDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("DataController: Initialization complete")
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            print("SAVING DATA - \(context.insertedObjects.count) new objects")
            do {
                try context.save()
                print("SAVE SUCCESSFUL")
            } catch {
                print("SAVE FAILED: \(error.localizedDescription)")
            }
        } else {
            print("NO CHANGES TO SAVE")
        }
    }


    func createPatternEntry(
        patternType: PatternType,
        intensity: Int16 = 0,
        duration: Int32 = 0,
        contextNotes: String? = nil,
        specificDetails: String? = nil,
        contributingFactors: [ContributingFactor] = []
    ) -> PatternEntry {
        let entry = NSEntityDescription.insertNewObject(forEntityName: "PatternEntry", into: container.viewContext) as! PatternEntry
        entry.configure(
            patternType: patternType,
            intensity: intensity,
            duration: duration,
            contextNotes: contextNotes,
            specificDetails: specificDetails,
            contributingFactors: contributingFactors
        )
        save()
        return entry
    }

    func deletePatternEntry(_ entry: PatternEntry) {
        container.viewContext.delete(entry)
        save()
    }

    func fetchPatternEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil
    ) -> [PatternEntry] {
        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        var predicates: [NSPredicate] = []

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch pattern entries: \(error.localizedDescription)")
            return []
        }
    }

    func getUserPreferences() -> UserPreferences {
        let request = NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
        request.fetchLimit = 1

        do {
            let results = try container.viewContext.fetch(request)
            if let preferences = results.first {
                return preferences
            } else {
                let newPreferences = NSEntityDescription.insertNewObject(forEntityName: "UserPreferences", into: container.viewContext) as! UserPreferences
                save()
                return newPreferences
            }
        } catch {
            print("Failed to fetch preferences: \(error.localizedDescription)")
            let newPreferences = NSEntityDescription.insertNewObject(forEntityName: "UserPreferences", into: container.viewContext) as! UserPreferences
            save()
            return newPreferences
        }
    }

    func updateStreak() {
        let preferences = getUserPreferences()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]
        request.fetchLimit = 1

        do {
            let results = try container.viewContext.fetch(request)
            if let lastEntry = results.first {
                let lastEntryDate = calendar.startOfDay(for: lastEntry.timestamp)
                let daysDifference = calendar.dateComponents([.day], from: lastEntryDate, to: today).day ?? 0

                if daysDifference == 0 {
                    return
                } else if daysDifference == 1 {
                    preferences.streakCount += 1
                } else {
                    preferences.streakCount = 1
                }
            } else {
                preferences.streakCount = 1
            }
            save()
        } catch {
            print("Failed to update streak: \(error.localizedDescription)")
        }
    }

    // MARK: - Medication Management

    func createMedication(
        name: String,
        dosage: String? = nil,
        frequency: String,
        notes: String? = nil
    ) -> Medication {
        let medication = NSEntityDescription.insertNewObject(forEntityName: "Medication", into: container.viewContext) as! Medication
        medication.configure(
            name: name,
            dosage: dosage,
            frequency: frequency,
            notes: notes
        )
        save()
        return medication
    }

    func fetchMedications(activeOnly: Bool = true) -> [Medication] {
        let request = NSFetchRequest<Medication>(entityName: "Medication")

        if activeOnly {
            request.predicate = NSPredicate(format: "isActive == true")
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.name, ascending: true)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch medications: \(error.localizedDescription)")
            return []
        }
    }

    func updateMedication(_ medication: Medication) {
        save()
    }

    func deleteMedication(_ medication: Medication) {
        container.viewContext.delete(medication)
        save()
    }

    // MARK: - Medication Log Management

    func createMedicationLog(
        medication: Medication,
        taken: Bool = true,
        skippedReason: String? = nil,
        sideEffects: String? = nil,
        effectiveness: Int16 = 0,
        mood: Int16 = 0,
        energyLevel: Int16 = 0,
        notes: String? = nil
    ) -> MedicationLog {
        let log = NSEntityDescription.insertNewObject(forEntityName: "MedicationLog", into: container.viewContext) as! MedicationLog
        log.configure(
            medication: medication,
            taken: taken,
            skippedReason: skippedReason,
            sideEffects: sideEffects,
            effectiveness: effectiveness,
            mood: mood,
            energyLevel: energyLevel,
            notes: notes
        )
        save()
        return log
    }

    func fetchMedicationLogs(
        startDate: Date? = nil,
        endDate: Date? = nil,
        medication: Medication? = nil
    ) -> [MedicationLog] {
        let request = NSFetchRequest<MedicationLog>(entityName: "MedicationLog")
        var predicates: [NSPredicate] = []

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        if let medication = medication {
            predicates.append(NSPredicate(format: "medication == %@", medication))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationLog.timestamp, ascending: false)]
        
        // Prefetch the medication relationship to avoid faulting issues
        request.relationshipKeyPathsForPrefetching = ["medication"]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch medication logs: \(error.localizedDescription)")
            return []
        }
    }

    func deleteMedicationLog(_ log: MedicationLog) {
        container.viewContext.delete(log)
        save()
    }

    func getTodaysMedicationLogs() -> [MedicationLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return fetchMedicationLogs(startDate: startOfDay, endDate: endOfDay)
    }

    // MARK: - Journal Entry Management

    func createJournalEntry(
        title: String? = nil,
        content: String,
        mood: Int16 = 0,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) -> JournalEntry {
        let entry = NSEntityDescription.insertNewObject(forEntityName: "JournalEntry", into: container.viewContext) as! JournalEntry
        entry.configure(
            title: title,
            content: content,
            mood: mood,
            relatedPatternEntry: relatedPatternEntry,
            relatedMedicationLog: relatedMedicationLog
        )
        save()
        return entry
    }

    func fetchJournalEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) -> [JournalEntry] {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        var predicates: [NSPredicate] = []

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "timestamp >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "timestamp <= %@", endDate as NSDate))
        }

        if favoritesOnly {
            predicates.append(NSPredicate(format: "isFavorite == true"))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch journal entries: \(error.localizedDescription)")
            return []
        }
    }

    func updateJournalEntry(_ entry: JournalEntry) {
        save()
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        container.viewContext.delete(entry)
        save()
    }

    func searchJournalEntries(query: String) -> [JournalEntry] {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")

        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", query)

        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to search journal entries: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - User Profile Management

    func createUserProfile(
        name: String,
        email: String? = nil,
        dateOfBirth: Date? = nil
    ) -> UserProfile {
        let profile = NSEntityDescription.insertNewObject(forEntityName: "UserProfile", into: container.viewContext) as! UserProfile
        profile.name = name
        profile.email = email
        profile.dateOfBirth = dateOfBirth
        save()
        return profile
    }

    func fetchUserProfiles() -> [UserProfile] {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.name, ascending: true)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch user profiles: \(error.localizedDescription)")
            return []
        }
    }

    func getCurrentUserProfile() -> UserProfile? {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: true)]

        do {
            return try container.viewContext.fetch(request).first
        } catch {
            print("Failed to fetch current user profile: \(error.localizedDescription)")
            return nil
        }
    }

    func getOrCreateUserProfile() -> UserProfile {
        if let existing = getCurrentUserProfile() {
            return existing
        }
        return createUserProfile(name: "User")
    }

    func updateUserProfile(_ profile: UserProfile) {
        profile.updatedAt = Date()
        save()
    }

    func deleteUserProfile(_ profile: UserProfile) {
        container.viewContext.delete(profile)
        save()
    }
}

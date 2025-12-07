@preconcurrency import CoreData
import Foundation

/// Repository for JournalEntry CRUD operations
final class JournalRepository: @unchecked Sendable {
    static let shared = JournalRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private var backgroundContext: NSManagedObjectContext {
        let context = DataController.shared.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    private init() {}

    // MARK: - Create

    func create(
        title: String? = nil,
        content: String,
        mood: Int16 = 0,
        audioFileName: String? = nil,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) throws -> JournalEntry {
        // Validate content
        try Validator(content, fieldName: "Journal content")
            .notEmpty()
            .maxLength(50000)

        // Validate title if provided
        try Validator(title, fieldName: "Journal title")
            .ifPresent { validator in
                try validator.maxLength(200)
                try validator.noSpecialCharacters()
            }

        // Validate mood
        try Validator(mood, fieldName: "Mood")
            .inRange(0...5)

        // Validate audio file name if provided
        try Validator(audioFileName, fieldName: "Audio file name")
            .ifPresent { validator in
                try validator.maxLength(255)
                try validator.matches(pattern: "^[a-zA-Z0-9_.-]+$", message: "Audio file name contains invalid characters")
            }

        let entry = JournalEntry(context: viewContext)
        entry.configure(
            title: title?.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: mood,
            relatedPatternEntry: relatedPatternEntry,
            relatedMedicationLog: relatedMedicationLog
        )
        entry.audioFileName = audioFileName

        DataController.shared.save()
        return entry
    }

    // MARK: - Read (Async)

    @MainActor
    func fetch(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false,
        limit: Int? = nil,
        offset: Int = 0
    ) async -> [JournalEntry] {
        let request = buildFetchRequest(
            startDate: startDate,
            endDate: endDate,
            favoritesOnly: favoritesOnly,
            limit: limit,
            offset: offset
        )
        let bgContext = backgroundContext

        // Fetch on background context and get permanent object IDs
        let objectIDURIs: [URL] = await bgContext.perform {
            do {
                let entries = try bgContext.fetch(request)
                return entries.compactMap { entry -> URL? in
                    if entry.objectID.isTemporaryID {
                        try? bgContext.obtainPermanentIDs(for: [entry])
                    }
                    return entry.objectID.uriRepresentation()
                }
            } catch {
                return []
            }
        }

        // Convert URIs back to objects on main context
        let coordinator = DataController.shared.container.persistentStoreCoordinator
        return objectIDURIs.compactMap { uri -> JournalEntry? in
            guard let objectID = coordinator.managedObjectID(forURIRepresentation: uri) else { return nil }
            return viewContext.object(with: objectID) as? JournalEntry
        }
    }

    /// Get total count of entries (for pagination)
    @MainActor
    func count(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) async -> Int {
        let request = buildFetchRequest(startDate: startDate, endDate: endDate, favoritesOnly: favoritesOnly)
        let bgContext = backgroundContext

        return await bgContext.perform {
            do {
                return try bgContext.count(for: request)
            } catch {
                return 0
            }
        }
    }

    @MainActor
    func fetchSync(
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) -> [JournalEntry] {
        let request = buildFetchRequest(startDate: startDate, endDate: endDate, favoritesOnly: favoritesOnly)

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    // MARK: - Search (Async)

    @MainActor
    func search(query: String) async -> [JournalEntry] {
        let request = buildSearchRequest(query: query)
        let bgContext = backgroundContext

        let objectIDURIs: [URL] = await bgContext.perform {
            do {
                let entries = try bgContext.fetch(request)
                return entries.compactMap { entry -> URL? in
                    if entry.objectID.isTemporaryID {
                        try? bgContext.obtainPermanentIDs(for: [entry])
                    }
                    return entry.objectID.uriRepresentation()
                }
            } catch {
                return []
            }
        }

        let coordinator = DataController.shared.container.persistentStoreCoordinator
        return objectIDURIs.compactMap { uri -> JournalEntry? in
            guard let objectID = coordinator.managedObjectID(forURIRepresentation: uri) else { return nil }
            return viewContext.object(with: objectID) as? JournalEntry
        }
    }

    @MainActor
    func searchSync(query: String) -> [JournalEntry] {
        let request = buildSearchRequest(query: query)

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    // MARK: - Update

    func update(_ entry: JournalEntry) {
        DataController.shared.save()
    }

    // MARK: - Delete

    func delete(_ entry: JournalEntry) {
        viewContext.delete(entry)
        DataController.shared.save()
    }

    // MARK: - Private Helpers

    private func buildFetchRequest(
        startDate: Date?,
        endDate: Date?,
        favoritesOnly: Bool,
        limit: Int? = nil,
        offset: Int = 0
    ) -> NSFetchRequest<JournalEntry> {
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

        // Pagination support
        if let limit = limit {
            request.fetchLimit = limit
        }
        if offset > 0 {
            request.fetchOffset = offset
        }

        return request
    }

    private func buildSearchRequest(query: String) -> NSFetchRequest<JournalEntry> {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")

        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", query)

        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]
        return request
    }
}

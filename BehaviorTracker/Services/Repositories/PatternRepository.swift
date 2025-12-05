import CoreData
import Foundation

/// Repository for PatternEntry CRUD operations
final class PatternRepository {
    static let shared = PatternRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Create

    func create(
        patternType: PatternType,
        intensity: Int16 = 0,
        duration: Int32 = 0,
        contextNotes: String? = nil,
        specificDetails: String? = nil,
        contributingFactors: [ContributingFactor] = []
    ) throws -> PatternEntry {
        // Validate intensity
        try Validator(intensity, fieldName: "Intensity")
            .inRange(0...5)

        // Validate duration (in minutes, max 24 hours = 1440 minutes)
        try Validator(duration, fieldName: "Duration")
            .inRange(0...1440)

        // Validate context notes if provided
        try Validator(contextNotes, fieldName: "Context notes")
            .ifPresent { try $0.maxLength(1000) }

        // Validate specific details if provided
        try Validator(specificDetails, fieldName: "Specific details")
            .ifPresent { try $0.maxLength(1000) }

        // Validate contributing factors count
        try Validator(contributingFactors, fieldName: "Contributing factors")
            .maxCount(20, message: "You can select up to 20 contributing factors")

        let entry = PatternEntry(context: viewContext)
        entry.configure(
            patternType: patternType,
            intensity: intensity,
            duration: duration,
            contextNotes: contextNotes?.trimmingCharacters(in: .whitespacesAndNewlines),
            specificDetails: specificDetails?.trimmingCharacters(in: .whitespacesAndNewlines),
            contributingFactors: contributingFactors
        )

        DataController.shared.save()
        DataController.shared.syncWidgetData()

        return entry
    }

    // MARK: - Read

    func fetch(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) -> [PatternEntry] {
        do {
            return try fetchOrThrow(startDate: startDate, endDate: endDate, category: category, limit: limit)
        } catch {
            print("Failed to fetch pattern entries: \(error.localizedDescription)")
            return []
        }
    }

    func fetchOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) throws -> [PatternEntry] {
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

        if let limit = limit {
            request.fetchLimit = limit
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    // MARK: - Delete

    func delete(_ entry: PatternEntry) {
        viewContext.delete(entry)
        DataController.shared.save()
    }
}

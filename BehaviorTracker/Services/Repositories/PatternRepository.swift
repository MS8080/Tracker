@preconcurrency import CoreData
import Foundation

/// Repository for PatternEntry CRUD operations
final class PatternRepository: @unchecked Sendable {
    static let shared = PatternRepository()

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
        patternType: PatternType,
        intensity: Int16 = 0,
        duration: Int32 = 0,
        contextNotes: String? = nil,
        specificDetails: String? = nil,
        contributingFactors: [ContributingFactor] = []
    ) async throws -> PatternEntry {
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
        await DataController.shared.syncWidgetData()

        return entry
    }

    // MARK: - Read (Async)

    @MainActor
    func fetch(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) async -> [PatternEntry] {
        let request = buildFetchRequest(startDate: startDate, endDate: endDate, category: category, limit: limit)
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
        return objectIDURIs.compactMap { uri -> PatternEntry? in
            guard let objectID = coordinator.managedObjectID(forURIRepresentation: uri) else { return nil }
            return viewContext.object(with: objectID) as? PatternEntry
        }
    }

    @MainActor
    func fetchSync(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) -> [PatternEntry] {
        let request = buildFetchRequest(startDate: startDate, endDate: endDate, category: category, limit: limit)

        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }

    func fetchOrThrow(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: PatternCategory? = nil,
        limit: Int? = nil
    ) throws -> [PatternEntry] {
        let request = buildFetchRequest(startDate: startDate, endDate: endDate, category: category, limit: limit)

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

    // MARK: - Extracted Pattern Methods

    /// Save extraction result as Core Data entities for a journal entry
    func saveExtractionResult(
        _ result: PatternExtractionService.ExtractionResult,
        for entry: JournalEntry
    ) async throws {
        let context = backgroundContext
        let entryObjectID = entry.objectID  // Capture objectID instead of entry

        try await context.perform {
            // Get entry in this context
            guard let entryInContext = try? context.existingObject(with: entryObjectID) as? JournalEntry else {
                throw PatternRepositoryError.entryNotFound
            }

            // Clear any existing patterns (for re-analysis)
            self.deleteExtractedPatterns(for: entryInContext, in: context)

            // Create pattern entities
            var createdPatterns: [String: ExtractedPattern] = [:]

            for patternData in result.patterns {
                let pattern = ExtractedPattern(context: context)
                pattern.id = UUID()
                pattern.patternType = patternData.type
                pattern.category = patternData.category
                pattern.intensity = Int16(patternData.intensity)
                pattern.triggers = patternData.triggers ?? []
                pattern.timeOfDay = patternData.timeOfDay ?? result.context.timeOfDay ?? "unknown"
                pattern.copingStrategies = patternData.copingUsed ?? []
                pattern.details = patternData.details
                pattern.confidence = result.confidence
                pattern.timestamp = entryInContext.timestamp
                pattern.journalEntry = entryInContext

                createdPatterns[patternData.type] = pattern
            }

            // Create cascade relationships
            for cascadeData in result.cascades {
                guard let fromPattern = createdPatterns[cascadeData.from],
                      let toPattern = createdPatterns[cascadeData.to] else { continue }

                let cascade = PatternCascade(context: context)
                cascade.id = UUID()
                cascade.confidence = cascadeData.confidence
                cascade.descriptionText = cascadeData.description
                cascade.timestamp = entryInContext.timestamp
                cascade.fromPattern = fromPattern
                cascade.toPattern = toPattern
            }

            // Update entry metadata
            entryInContext.isAnalyzed = true
            entryInContext.analysisConfidence = result.confidence
            entryInContext.analysisSummary = result.summary
            entryInContext.overallIntensity = Int16(result.overallIntensity)

            try context.save()
        }
    }

    /// Delete existing extracted patterns for a journal entry
    private func deleteExtractedPatterns(for entry: JournalEntry, in context: NSManagedObjectContext) {
        guard let patterns = entry.extractedPatterns as? Set<ExtractedPattern> else { return }
        for pattern in patterns {
            context.delete(pattern)
        }
    }

    /// Clear analysis data for an entry (for re-analysis)
    func clearAnalysis(for entry: JournalEntry) throws {
        deleteExtractedPatterns(for: entry, in: viewContext)

        entry.isAnalyzed = false
        entry.analysisSummary = nil
        entry.analysisConfidence = 0
        entry.overallIntensity = 0

        try viewContext.save()
    }

    /// Fetch all unanalyzed journal entries
    func fetchUnanalyzedEntries() -> [JournalEntry] {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        request.predicate = NSPredicate(format: "isAnalyzed == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]
        return (try? viewContext.fetch(request)) ?? []
    }

    /// Fetch extracted patterns for a date range
    func fetchExtractedPatterns(from startDate: Date, to endDate: Date) -> [ExtractedPattern] {
        let request = NSFetchRequest<ExtractedPattern>(entityName: "ExtractedPattern")
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExtractedPattern.timestamp, ascending: false)]
        return (try? viewContext.fetch(request)) ?? []
    }

    // MARK: - Private Helpers

    private func buildFetchRequest(
        startDate: Date?,
        endDate: Date?,
        category: PatternCategory?,
        limit: Int?
    ) -> NSFetchRequest<PatternEntry> {
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
        return request
    }
}

// MARK: - Errors

enum PatternRepositoryError: LocalizedError {
    case entryNotFound
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .entryNotFound:
            return "Journal entry not found in context"
        case .saveFailed(let detail):
            return "Failed to save patterns: \(detail)"
        }
    }
}

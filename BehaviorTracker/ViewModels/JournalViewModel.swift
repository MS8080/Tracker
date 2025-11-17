import SwiftUI
import CoreData

class JournalViewModel: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                loadJournalEntries()
            } else {
                searchEntries()
            }
        }
    }
    @Published var showFavoritesOnly: Bool = false {
        didSet {
            loadJournalEntries()
        }
    }

    private let dataController = DataController.shared

    init() {
        loadJournalEntries()
    }

    func loadJournalEntries() {
        journalEntries = dataController.fetchJournalEntries(favoritesOnly: showFavoritesOnly)
    }

    func searchEntries() {
        journalEntries = dataController.searchJournalEntries(query: searchQuery)
    }

    func createEntry(
        title: String? = nil,
        content: String,
        mood: Int16 = 0,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) {
        _ = dataController.createJournalEntry(
            title: title,
            content: content,
            mood: mood,
            relatedPatternEntry: relatedPatternEntry,
            relatedMedicationLog: relatedMedicationLog
        )
        loadJournalEntries()
    }

    func updateEntry(_ entry: JournalEntry) {
        dataController.updateJournalEntry(entry)
        loadJournalEntries()
    }

    func deleteEntry(_ entry: JournalEntry) {
        dataController.deleteJournalEntry(entry)
        loadJournalEntries()
    }

    func toggleFavorite(_ entry: JournalEntry) {
        entry.isFavorite.toggle()
        dataController.updateJournalEntry(entry)
        loadJournalEntries()
    }

    func getEntriesByDateRange(startDate: Date, endDate: Date) -> [JournalEntry] {
        return dataController.fetchJournalEntries(startDate: startDate, endDate: endDate)
    }

    func getEntriesGroupedByDate() -> [Date: [JournalEntry]] {
        let calendar = Calendar.current
        var grouped: [Date: [JournalEntry]] = [:]

        for entry in journalEntries {
            let startOfDay = calendar.startOfDay(for: entry.timestamp)
            if grouped[startOfDay] != nil {
                grouped[startOfDay]?.append(entry)
            } else {
                grouped[startOfDay] = [entry]
            }
        }

        return grouped
    }
}

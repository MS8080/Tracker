import SwiftUI
import CoreData

class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var showFavoritesOnly = false {
        didSet {
            loadEntries()
        }
    }
    
    private let dataController = DataController.shared
    
    init() {
        loadEntries()
    }
    
    func loadEntries() {
        entries = dataController.fetchJournalEntries(favoritesOnly: showFavoritesOnly)
    }
    
    func createEntry(
        title: String?,
        content: String,
        mood: Int16,
        relatedPatternEntry: PatternEntry? = nil,
        relatedMedicationLog: MedicationLog? = nil
    ) {
        let _ = dataController.createJournalEntry(
            title: title,
            content: content,
            mood: mood,
            relatedPatternEntry: relatedPatternEntry,
            relatedMedicationLog: relatedMedicationLog
        )
        loadEntries()
    }
    
    func updateEntry(_ entry: JournalEntry) {
        dataController.updateJournalEntry(entry)
        loadEntries()
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        dataController.deleteJournalEntry(entry)
        loadEntries()
    }
    
    func toggleFavorite(_ entry: JournalEntry) {
        entry.isFavorite.toggle()
        updateEntry(entry)
    }
    
    func searchEntries(query: String) -> [JournalEntry] {
        return dataController.searchJournalEntries(query: query)
    }
}

import SwiftUI
import CoreData

class HistoryViewModel: ObservableObject {
    @Published var groupedEntries: [(key: Date, value: [PatternEntry])] = []

    private let dataController = DataController.shared

    func loadEntries() {
        let entries = dataController.fetchPatternEntries()

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        groupedEntries = grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    func filteredAndGroupedEntries(searchText: String, category: PatternCategory?) -> [(key: Date, value: [PatternEntry])] {
        var filtered = groupedEntries

        if let category = category {
            filtered = filtered.map { date, entries in
                (date, entries.filter { $0.category == category.rawValue })
            }.filter { !$0.value.isEmpty }
        }

        if !searchText.isEmpty {
            filtered = filtered.map { date, entries in
                (date, entries.filter {
                    $0.patternType.localizedCaseInsensitiveContains(searchText) ||
                    ($0.contextNotes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    ($0.specificDetails?.localizedCaseInsensitiveContains(searchText) ?? false)
                })
            }.filter { !$0.value.isEmpty }
        }

        return filtered
    }

    func deleteEntry(_ entry: PatternEntry) {
        dataController.deletePatternEntry(entry)
        loadEntries()
    }
}

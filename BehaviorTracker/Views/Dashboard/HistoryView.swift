import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedCategory: PatternCategory?
    @State private var searchText = ""
    @State private var showDaySummary = false

    var body: some View {
        List {
            if viewModel.groupedEntries.isEmpty {
                ContentUnavailableView(
                    "No Entries Yet",
                    systemImage: "tray",
                    description: Text("Start logging your behavioral patterns to see them here")
                )
            } else {
                ForEach(viewModel.filteredAndGroupedEntries(searchText: searchText, category: selectedCategory), id: \.key) { date, entries in
                    Section {
                        ForEach(entries) { entry in
                            HistoryEntryRow(entry: entry)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text(formatSectionHeader(date))
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search patterns")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showDaySummary = true
                } label: {
                    Label("Today's Summary", systemImage: "chart.bar.doc.horizontal")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        selectedCategory = nil
                    } label: {
                        Label("All Categories", systemImage: selectedCategory == nil ? "checkmark" : "")
                    }

                    Divider()

                    ForEach(PatternCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Label(category.rawValue, systemImage: selectedCategory == category ? "checkmark" : category.icon)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showDaySummary) {
            DaySummaryView()
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }

    private func formatSectionHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

struct HistoryEntryRow: View {
    let entry: PatternEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let category = entry.patternCategoryEnum {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.color)
                }

                Text(entry.patternType)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.intensity > 0 {
                HStack(spacing: 4) {
                    Text("Intensity:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= entry.intensity ? "circle.fill" : "circle")
                            .font(.caption2)
                            .foregroundStyle(level <= entry.intensity ? intensityColor(Int(entry.intensity)) : .secondary.opacity(0.3))
                    }
                }
            }

            if entry.duration > 0 {
                Text("Duration: \(formatDuration(Int(entry.duration)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notes = entry.contextNotes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            if let details = entry.specificDetails, !details.isEmpty {
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }

    private func intensityColor(_ intensity: Int) -> Color {
        switch intensity {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(\.managedObjectContext, DataController.shared.container.viewContext)
    }
}

import SwiftUI

struct JournalListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingNewEntry = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.entries.isEmpty && searchText.isEmpty {
                    // Empty state
                    ContentUnavailableView {
                        Label("No Journal Entries", systemImage: "book")
                    } description: {
                        Text("Start writing your first journal entry")
                    } actions: {
                        Button {
                            showingNewEntry = true
                        } label: {
                            Text("New Entry")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            NavigationLink {
                                JournalDetailView(entry: entry, viewModel: viewModel)
                            } label: {
                                JournalEntryRow(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .searchable(text: $searchText, prompt: "Search journal entries")
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                if !viewModel.entries.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                viewModel.showFavoritesOnly.toggle()
                            } label: {
                                Label(
                                    viewModel.showFavoritesOnly ? "Show All" : "Show Favorites",
                                    systemImage: viewModel.showFavoritesOnly ? "star.slash" : "star"
                                )
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryFormView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadEntries()
            }
        }
    }
    
    private var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return viewModel.entries
        } else {
            return viewModel.searchEntries(query: searchText)
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredEntries[index]
            viewModel.deleteEntry(entry)
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                } else {
                    Text("Untitled Entry")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            
            Text(entry.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(entry.timestamp, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Text("•")
                    .foregroundStyle(.tertiary)
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                if entry.mood > 0 {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text(moodEmoji(for: entry.mood))
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func moodEmoji(for mood: Int16) -> String {
        switch mood {
        case 1: return "😔"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "😄"
        default: return ""
        }
    }
}

#Preview {
    JournalListView()
}

import SwiftUI

struct JournalListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var searchText = ""
    @Binding var showingProfile: Bool

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .accessibilityLabel("Search journal entries")

                // Favorites Filter
                Toggle("Show Favorites Only", isOn: $viewModel.showFavoritesOnly)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .accessibilityLabel("Filter to show favorite entries only")

                // Journal Entries List
                if viewModel.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    journalEntriesList
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingNewEntry = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .accessibilityLabel("Add new journal entry")
                        }

                        ProfileButton(showingProfile: $showingProfile)
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryEditorView()
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry)
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
    }

    private var journalEntriesList: some View {
        List {
            ForEach(viewModel.journalEntries) { entry in
                JournalEntryRow(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEntry = entry
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteEntry(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete entry")

                        Button {
                            viewModel.toggleFavorite(entry)
                        } label: {
                            Label(
                                entry.isFavorite ? "Unfavorite" : "Favorite",
                                systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                            )
                        }
                        .tint(.yellow)
                        .accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            ttsService.speakJournalEntry(entry)
                        } label: {
                            Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                        }
                        .tint(.blue)
                        .accessibilityLabel("Read entry aloud")
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            Text("No Journal Entries")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityLabel("No journal entries found")

            Text("Tap the + button to create your first entry")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityLabel("Tap the plus button to create your first journal entry")

            Button(action: {
                showingNewEntry = true
            }) {
                Label("New Entry", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .accessibilityLabel("Create new journal entry")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .accessibilityLabel("Title: \(title)")
                } else {
                    Text("Untitled Entry")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Untitled entry")
                }

                Spacer()

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .accessibilityLabel("Favorite")
                }
            }

            Text(entry.preview)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .accessibilityLabel("Preview: \(entry.preview)")

            HStack {
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .accessibilityLabel("Created on \(entry.formattedDate)")

                if entry.mood > 0 {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "face.smiling")
                            .font(.caption)
                        Text(moodText(for: entry.mood))
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .accessibilityLabel("Mood: \(moodText(for: entry.mood))")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func moodText(for mood: Int16) -> String {
        switch mood {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Very Good"
        default: return "Unknown"
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            TextField("Search journal entries...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .accessibilityLabel("Search journal entries")

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .accessibilityLabel("Clear search")
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    JournalListView()
}

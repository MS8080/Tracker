import SwiftUI

struct JournalListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingNewEntry = false
    @State private var searchText = ""
    @Binding var showingProfile: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom rounded search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search journal entries", text: $searchText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(theme.cardBackground)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if viewModel.entries.isEmpty && searchText.isEmpty {
                        // Empty state
                        Spacer()
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
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredEntries) { entry in
                                    NavigationLink {
                                        JournalDetailView(entry: entry, viewModel: viewModel)
                                    } label: {
                                        JournalEntryRow(entry: entry)
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(theme.cardBackground)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }

                    // New Entry button at bottom
                    Button {
                        showingNewEntry = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Entry")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primaryColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding()
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
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

import SwiftUI
import CoreData

struct JournalListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var entryToDelete: JournalEntry?
    @State private var searchText = ""
    @State private var entryToAnalyze: JournalEntry?
    @State private var isSearching = false
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

                // Journal Entries List
                if viewModel.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    journalEntriesListWithOffset
                }

                // Floating Action Button - bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingNewEntry = true
                            HapticFeedback.medium.trigger()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(theme.cardBackground)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                                Circle()
                                    .fill(theme.primaryColor.opacity(0.8))
                                    .frame(width: 56, height: 56)

                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
                                    .frame(width: 56, height: 56)

                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel(NSLocalizedString("accessibility.create_entry", comment: ""))
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("journal.title", comment: ""))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryEditorView()
            }
            .onChange(of: showingNewEntry) { _, isShowing in
                if !isShowing {
                    // Refresh entries when sheet closes
                    viewModel.loadJournalEntries()
                }
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry) {
                    // Mark this entry for deletion
                    entryToDelete = entry
                }
            }
            .onChange(of: selectedEntry) { _, newValue in
                if newValue == nil {
                    // If we have an entry marked for deletion, delete it now
                    if let entryToDelete = entryToDelete {
                        withAnimation {
                            viewModel.deleteEntry(entryToDelete)
                        }
                        self.entryToDelete = nil
                    } else {
                        // Otherwise just refresh the list
                        viewModel.loadJournalEntries()
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
    }

    // Group entries by day
    private var entriesGroupedByDay: [(date: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current

        // Filter out deleted entries first to prevent crashes
        let validEntries = viewModel.journalEntries.filter { !$0.isDeleted }

        let grouped = Dictionary(grouping: validEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    private var journalEntriesListWithOffset: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Search bar - only shown when isSearching is true
                if isSearching {
                    RoundedSearchBar(text: $searchText)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ForEach(entriesGroupedByDay, id: \.date) { dayGroup in
                    DayTimelineCard(
                        date: dayGroup.date,
                        entries: dayGroup.entries,
                        theme: theme,
                        onEntryTap: { entry in
                            selectedEntry = entry
                        },
                        onToggleFavorite: { entry in
                            viewModel.toggleFavorite(entry)
                        },
                        onSpeak: { entry in
                            ttsService.speakJournalEntry(entry)
                        },
                        onDelete: { entry in
                            withAnimation {
                                viewModel.deleteEntry(entry)
                            }
                        },
                        onAnalyze: { entry in
                            entryToAnalyze = entry
                        }
                    )
                }
            }
            .padding()
        }
        .sheet(item: $entryToAnalyze) { entry in
            JournalEntryAnalysisView(entry: entry)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(NSLocalizedString("journal.no_entries", comment: ""))
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityLabel(NSLocalizedString("journal.no_entries", comment: ""))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RoundedSearchBar: View {
    @Binding var text: String

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(NSLocalizedString("journal.search_placeholder", comment: "Search placeholder"), text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .accessibilityLabel(NSLocalizedString("journal.search_placeholder", comment: ""))

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(NSLocalizedString("accessibility.hide_search", comment: ""))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
    }
}

// MARK: - Day Timeline Card

struct DayTimelineCard: View {
    let date: Date
    let entries: [JournalEntry]
    let theme: AppTheme
    let onEntryTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onSpeak: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void
    let onAnalyze: (JournalEntry) -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dateHeader: String {
        if isToday {
            return NSLocalizedString("time.today", comment: "")
        } else if Calendar.current.isDateInYesterday(date) {
            return NSLocalizedString("time.yesterday", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                Text(dateHeader)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if !isToday {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Timeline
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    JournalTimelineEntryRow(
                        entry: entry,
                        isLast: index == entries.count - 1,
                        theme: theme,
                        onTap: { onEntryTap(entry) },
                        onToggleFavorite: { onToggleFavorite(entry) },
                        onSpeak: { onSpeak(entry) },
                        onDelete: { onDelete(entry) },
                        onAnalyze: { onAnalyze(entry) }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.journalCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }
}

struct JournalTimelineEntryRow: View {
    let entry: JournalEntry
    let isLast: Bool
    let theme: AppTheme
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onSpeak: () -> Void
    let onDelete: () -> Void
    let onAnalyze: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.timestamp)
    }

    var body: some View {
        // Safety check: don't render if entry is deleted
        if !entry.isDeleted {
            HStack(alignment: .top, spacing: 12) {
                // Timeline with bullet point
                VStack(spacing: 0) {
                    // Bullet point - aligned with time text center
                    Circle()
                    .fill(theme.timelineColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4) // Align with center of time text

                // Vertical line (if not last)
                if !isLast {
                    Rectangle()
                        .fill(theme.timelineColor.opacity(0.4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Time
                Text(timeString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.timelineColor)

                // Entry content
                VStack(alignment: .leading, spacing: 6) {
                    if let title = entry.title, !title.isEmpty {
                        if title.hasPrefix("AI Insight:") {
                            // AI Insight entry with special tag
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                    Text("AI Insight")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.yellow.opacity(0.15))
                                )

                                Text(String(title.dropFirst(12)).trimmingCharacters(in: .whitespaces))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                        } else if title.hasPrefix("Guided Entry:") {
                            // Guided entry with special tag
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "hand.point.up.left.and.text")
                                        .font(.caption)
                                    Text("Guided")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.green.opacity(0.15))
                                )

                                Text(String(title.dropFirst(14)).trimmingCharacters(in: .whitespaces))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                        } else if title.hasPrefix("Log:") {
                            // Pattern log entry with special tag
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                    Text("Log")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.blue.opacity(0.15))
                                )

                                Text(String(title.dropFirst(5)).trimmingCharacters(in: .whitespaces))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(title)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }

                    Text(entry.preview)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.bottom, isLast ? 0 : 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .contextMenu {
                Button {
                    onAnalyze()
                } label: {
                    Label("Analyze", systemImage: "sparkles")
                }

                Button {
                    onToggleFavorite()
                } label: {
                    Label(
                        entry.isFavorite ? "Unfavorite" : "Favorite",
                        systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                    )
                }

                Button {
                    onSpeak()
                } label: {
                    Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Favorite indicator
            if entry.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
        }
    }

}

// MARK: - Scroll Offset Tracking

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Journal Entry Analysis View

struct JournalEntryAnalysisView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var analysisViewModel = JournalAnalysisViewModel()

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Entry being analyzed
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.blue)
                                Text("Analyzing Entry")
                                    .font(.headline)
                                Spacer()
                            }

                            if let title = entry.title, !title.isEmpty {
                                Text(title)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }

                            Text(entry.content)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)

                            Text(entry.formattedDate)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(theme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(theme.cardBorderColor, lineWidth: 0.5)
                        )
                        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)

                        // Analysis results
                        if analysisViewModel.isAnalyzing {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Analyzing...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(theme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
                            )
                            .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
                        } else if let analysis = analysisViewModel.analysisResult {
                            // Show results
                            analysisResultView(analysis)
                        } else if let error = analysisViewModel.errorMessage {
                            // Error state
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundStyle(.orange)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Button("Try Again") {
                                    Task {
                                        await analysisViewModel.analyzeEntry(entry, context: viewContext)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(30)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(theme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
                            )
                            .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                // Auto-start analysis when view appears
                await analysisViewModel.analyzeEntry(entry, context: viewContext)
            }
        }
    }

    @ViewBuilder
    private func analysisResultView(_ analysis: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("Analysis")
                    .font(.headline)
                Spacer()
            }

            // Parse and format the analysis
            formattedAnalysisContent(analysis)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
    }

    @ViewBuilder
    private func formattedAnalysisContent(_ content: String) -> some View {
        let sections = parseAnalysisSections(content)

        VStack(alignment: .leading, spacing: 20) {
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 10) {
                    if !section.title.isEmpty {
                        Text(section.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.timelineColor)
                    }

                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(theme.timelineColor.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)

                            Text(bullet)
                                .font(.body)
                                .foregroundStyle(.primary.opacity(0.9))
                        }
                    }

                    if !section.paragraph.isEmpty {
                        Text(section.paragraph)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func parseAnalysisSections(_ content: String) -> [JournalAnalysisSection] {
        var sections: [JournalAnalysisSection] = []
        let lines = content.components(separatedBy: "\n")

        var currentTitle = ""
        var currentBullets: [String] = []
        var currentParagraph = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for headers (##, **, or numbered like "1.", "2.")
            if trimmed.hasPrefix("##") || (trimmed.hasPrefix("**") && trimmed.hasSuffix("**")) ||
               trimmed.range(of: "^\\*?\\*?\\d+\\.\\s*", options: .regularExpression) != nil {
                // Save previous section
                if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
                    sections.append(JournalAnalysisSection(
                        title: currentTitle,
                        bullets: currentBullets,
                        paragraph: currentParagraph
                    ))
                }

                // Clean the title
                currentTitle = trimmed
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                currentBullets = []
                currentParagraph = ""

            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                // Bullet point
                var bullet = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                bullet = bullet.replacingOccurrences(of: "**", with: "")
                if !bullet.isEmpty {
                    currentBullets.append(bullet)
                }
            } else if !trimmed.isEmpty {
                // Regular text
                let cleanedLine = trimmed.replacingOccurrences(of: "**", with: "")
                if currentParagraph.isEmpty {
                    currentParagraph = cleanedLine
                } else {
                    currentParagraph += " " + cleanedLine
                }
            }
        }

        // Add final section
        if !currentTitle.isEmpty || !currentBullets.isEmpty || !currentParagraph.isEmpty {
            sections.append(JournalAnalysisSection(
                title: currentTitle,
                bullets: currentBullets,
                paragraph: currentParagraph
            ))
        }

        return sections
    }
}

private struct JournalAnalysisSection: Hashable {
    let title: String
    let bullets: [String]
    let paragraph: String
}

// MARK: - Journal Analysis ViewModel

@MainActor
class JournalAnalysisViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: String?
    @Published var errorMessage: String?

    private let aiService = AIAnalysisService.shared

    func analyzeEntry(_ entry: JournalEntry, context: NSManagedObjectContext) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            // Fetch related data for context
            let recentJournals = fetchRecentJournals(excluding: entry, context: context)
            let recentPatterns = fetchRecentPatterns(context: context)

            // Build the prompt
            let prompt = buildAnalysisPrompt(entry: entry, journals: recentJournals, patterns: recentPatterns)

            // Call AI service
            let result = try await aiService.analyzeWithPrompt(prompt)
            analysisResult = result
        } catch {
            errorMessage = "Failed to analyze: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    private func fetchRecentJournals(excluding entry: JournalEntry, context: NSManagedObjectContext) -> [JournalEntry] {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        request.predicate = NSPredicate(format: "id != %@", entry.id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]
        request.fetchLimit = 20

        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    private func fetchRecentPatterns(context: NSManagedObjectContext) -> [PatternEntry] {
        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        request.predicate = NSPredicate(format: "timestamp >= %@", thirtyDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]
        request.fetchLimit = 50

        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    private func buildAnalysisPrompt(entry: JournalEntry, journals: [JournalEntry], patterns: [PatternEntry]) -> String {
        var prompt = """
        Analyze this journal entry in context of the user's recent data:

        ## Entry to Analyze
        Title: \(entry.title ?? "Untitled")
        Content: \(entry.content)
        Date: \(entry.formattedDate)

        """

        // Add recent journals for context
        if !journals.isEmpty {
            prompt += "\n## Recent Journal Entries (for context)\n"
            for journal in journals.prefix(10) {
                prompt += "- \(journal.title ?? "Untitled"): \(journal.preview)\n"
            }
        }

        // Add recent patterns
        if !patterns.isEmpty {
            prompt += "\n## Recent Logged Patterns (last 30 days)\n"
            let patternCounts = Dictionary(grouping: patterns) { $0.patternType }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            for (pattern, count) in patternCounts.prefix(10) {
                prompt += "- \(pattern): \(count) times\n"
            }
        }

        prompt += """

        ## Analysis Request
        Based on the entry above and the user's history:
        1. Identify any patterns or themes that connect to their logged behaviors
        2. Note any potential triggers or correlations
        3. Provide 2-3 actionable insights or suggestions
        4. Keep the response concise and supportive

        Focus on being helpful and constructive. Do not diagnose or provide medical advice.
        """

        return prompt
    }
}

#Preview {
    JournalListView()
}

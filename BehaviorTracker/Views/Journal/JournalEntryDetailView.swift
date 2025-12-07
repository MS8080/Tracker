import SwiftUI
import CoreData

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    let onDelete: () -> Void
    @StateObject private var audioService = AudioRecordingService.shared
    @StateObject private var ttsService = TextToSpeechService.shared
    @StateObject private var calendarService = CalendarEventService.shared
    @Environment(\.dismiss) private var dismiss

    // Editable state
    @State private var content: String
    @State private var hasChanges = false
    @State private var showingAnalysis = false
    @State private var dayAnalysisData: DayAnalysisData?
    @State private var linkedEvents: [CalendarEvent] = []
    @FocusState private var isContentFocused: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    private let dataController = DataController.shared
    private let mentionService = EventMentionService.shared

    init(entry: JournalEntry, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onDelete = onDelete
        _content = State(initialValue: entry.content)
    }

    /// Load all entries from the same day as this entry asynchronously
    private func loadDayAnalysis() {
        Task {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: entry.timestamp)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

            let entries = await dataController.fetchJournalEntries(startDate: startOfDay, endDate: endOfDay)
            await MainActor.run {
                dayAnalysisData = DayAnalysisData(entries: entries, date: startOfDay)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Themed background
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        // Date header
                        HStack {
                            Label(entry.formattedDate, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))

                            Spacer()

                            if entry.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.subheadline)
                            }
                        }

                        // Voice Note Playback (if exists)
                        if entry.hasVoiceNote {
                            voiceNotePlaybackSection
                        }

                        // Linked Events (if any @mentions)
                        if !linkedEvents.isEmpty {
                            linkedEventsSection
                        }

                        // Content - directly editable
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty && !isContentFocused {
                                Text("Write your thoughts here...")
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }

                            TextEditor(text: $content)
                                .font(.body)
                                .lineSpacing(5)
                                .foregroundStyle(.white.opacity(0.95))
                                .frame(minHeight: 300)
                                .focused($isContentFocused)
                                .onChange(of: content) { _, _ in hasChanges = true }
                                .scrollContentBackground(.hidden)
                        }

                        // Related items
                        if entry.relatedPatternEntry != nil || entry.relatedMedicationLog != nil {
                            relatedItemsSection
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if hasChanges {
                            content = entry.content
                            hasChanges = false
                        }
                        dismiss()
                    } label: {
                        Text(hasChanges ? "Cancel" : "Done")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }

                if hasChanges {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            saveChanges()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            toggleFavorite()
                        } label: {
                            Label(
                                entry.isFavorite ? "Remove Bookmark" : "Bookmark",
                                systemImage: entry.isFavorite ? "bookmark.slash" : "bookmark"
                            )
                        }

                        Button {
                            showingAnalysis = true
                        } label: {
                            Label("Analyze Entry", systemImage: "sparkles")
                        }

                        Button {
                            loadDayAnalysis()
                        } label: {
                            Label("Analyze Day", systemImage: "calendar.badge.sparkles")
                        }

                        Button {
                            ttsService.speakJournalEntry(entry)
                        } label: {
                            Label("Read Aloud", systemImage: "speaker.wave.2")
                        }

                        Divider()

                        Button(role: .destructive) {
                            deleteEntry()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .onDisappear {
                // Auto-save on dismiss if there are changes
                if hasChanges {
                    saveChanges()
                }
            }
            .sheet(isPresented: $showingAnalysis) {
                JournalEntryAnalysisView(entry: entry)
            }
            .sheet(item: $dayAnalysisData) { data in
                DayAnalysisView(entries: data.entries, date: data.date)
            }
            .onAppear {
                loadLinkedEvents()
            }
        }
    }

    // MARK: - Linked Events Section

    private var linkedEventsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(SemanticColor.calendar)

                Text("Linked Events")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)

                Spacer()
            }

            ForEach(linkedEvents) { event in
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(Color(cgColor: event.calendarColor ?? CGColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)))
                        .frame(width: 8, height: 8)

                    Text(event.title)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    Text(formatEventDateShort(event))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private func formatEventDateShort(_ event: CalendarEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return event.isAllDay ? "All day" : formatter.string(from: event.startDate)
    }

    private func loadLinkedEvents() {
        let mentions = entry.eventMentions
        guard !mentions.isEmpty else { return }

        linkedEvents = mentions.compactMap { mention in
            mentionService.lookupEvent(for: mention, around: entry.timestamp)
        }
    }

    private func toggleFavorite() {
        entry.isFavorite.toggle()
        DataController.shared.updateJournalEntry(entry)
    }

    private var voiceNotePlaybackSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(theme.primaryColor)

                Text("Voice Note")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                if let fileName = entry.audioFileName,
                   let duration = audioService.getAudioDuration(fileName: fileName) {
                    Text(audioService.formatTime(duration))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            if let fileName = entry.audioFileName {
                HStack(spacing: 20) {
                    Button {
                        if audioService.isPlaying {
                            audioService.pausePlayback()
                        } else {
                            audioService.playAudio(fileName: fileName)
                        }
                    } label: {
                        Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(theme.primaryColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if audioService.isPlaying || audioService.playbackTime > 0 {
                            ProgressView(value: audioService.playbackTime, total: audioService.playbackDuration)
                                .tint(theme.primaryColor)

                            HStack {
                                Text(audioService.formatTime(audioService.playbackTime))
                                Spacer()
                                Text(audioService.formatTime(audioService.playbackDuration))
                            }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        } else {
                            Text("Tap to play voice note")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    if audioService.isPlaying {
                        Button {
                            audioService.stopPlayback()
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var relatedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Items")
                .font(.headline)
                .foregroundStyle(.white)

            if let pattern = entry.relatedPatternEntry {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(theme.primaryColor)
                    VStack(alignment: .leading) {
                        Text("Related Pattern")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(pattern.patternType)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }

            if let medication = entry.relatedMedicationLog {
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading) {
                        Text("Related Medication Log")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        if let medName = medication.medication?.name {
                            Text(medName)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
            }
        }
    }

    private func saveChanges() {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        entry.content = content
        DataController.shared.updateJournalEntry(entry)
        hasChanges = false
    }

    private func deleteEntry() {
        onDelete()
        dismiss()
    }
}

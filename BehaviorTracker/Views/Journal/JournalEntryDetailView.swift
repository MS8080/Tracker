import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    let onDelete: () -> Void
    @StateObject private var audioService = AudioRecordingService.shared
    @StateObject private var ttsService = TextToSpeechService.shared
    @Environment(\.dismiss) private var dismiss

    // Editable state
    @State private var title: String
    @State private var content: String
    @State private var hasChanges = false
    @State private var showingAnalysis = false
    @FocusState private var isContentFocused: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    init(entry: JournalEntry, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onDelete = onDelete
        _title = State(initialValue: entry.title ?? "")
        _content = State(initialValue: entry.content)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Themed background
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
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

                        // Title field
                        TextField("Add a title (optional)", text: $title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.95))
                            .onChange(of: title) { _, _ in hasChanges = true }

                        Divider()
                            .background(.white.opacity(0.2))

                        // Voice Note Playback (if exists)
                        if entry.hasVoiceNote {
                            voiceNotePlaybackSection
                            Divider()
                                .background(.white.opacity(0.2))
                        }

                        // Content - directly editable
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty && !isContentFocused {
                                Text("Write your thoughts here...")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }

                            TextEditor(text: $content)
                                .font(.callout)
                                .lineSpacing(4)
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(minHeight: isContentFocused ? 300 : 200)
                                .focused($isContentFocused)
                                .onChange(of: content) { _, _ in hasChanges = true }
                                .scrollContentBackground(.hidden)
                        }

                        // Related items
                        if entry.relatedPatternEntry != nil || entry.relatedMedicationLog != nil {
                            Divider()
                                .background(.white.opacity(0.2))
                            relatedItemsSection
                        }
                    }
                    .padding(20)
                    .cardStyle(theme: theme)
                    .padding()
                }
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(hasChanges ? "Cancel" : "Done") {
                        if hasChanges {
                            // Discard changes
                            title = entry.title ?? ""
                            content = entry.content
                            hasChanges = false
                        }
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        if hasChanges {
                            Button {
                                saveChanges()
                            } label: {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                        }

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
                                Label("Analyze", systemImage: "sparkles")
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
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
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
                    .foregroundColor(.blue)

                Text("Voice Note")
                    .font(.headline)

                Spacer()

                if let fileName = entry.audioFileName,
                   let duration = audioService.getAudioDuration(fileName: fileName) {
                    Text(audioService.formatTime(duration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if audioService.isPlaying || audioService.playbackTime > 0 {
                            ProgressView(value: audioService.playbackTime, total: audioService.playbackDuration)
                                .tint(.blue)

                            HStack {
                                Text(audioService.formatTime(audioService.playbackTime))
                                Spacer()
                                Text(audioService.formatTime(audioService.playbackDuration))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        } else {
                            Text("Tap to play voice note")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if audioService.isPlaying {
                        Button {
                            audioService.stopPlayback()
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var relatedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Items")
                .font(.headline)

            if let pattern = entry.relatedPatternEntry {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading) {
                        Text("Related Pattern")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(pattern.patternType)
                            .font(.subheadline)
                    }
                }
            }

            if let medication = entry.relatedMedicationLog {
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Related Medication Log")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let medName = medication.medication?.name {
                            Text(medName)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    private func saveChanges() {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        entry.title = title.isEmpty ? nil : title
        entry.content = content
        DataController.shared.updateJournalEntry(entry)
        hasChanges = false
    }

    private func deleteEntry() {
        onDelete()
        dismiss()
    }
}

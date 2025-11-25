import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry  // Changed from @ObservedObject to let
    let onDelete: () -> Void  // Changed to take no parameters
    @StateObject private var audioService = AudioRecordingService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with metadata
                    entryHeader

                    Divider()

                    // Voice Note Playback (if exists)
                    if entry.hasVoiceNote {
                        voiceNotePlaybackSection
                        Divider()
                    }

                    // Content
                    entryContent

                    // Related items
                    if entry.relatedPatternEntry != nil || entry.relatedMedicationLog != nil {
                        Divider()
                        relatedItemsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close journal entry")
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            isEditing = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        .accessibilityLabel("Edit journal entry")

                        Button(action: {
                            toggleFavorite()
                        }) {
                            Label(
                                entry.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: entry.isFavorite ? "star.slash" : "star"
                            )
                        }
                        .accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")

                        Divider()

                        Button(role: .destructive, action: {
                            deleteEntry()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete journal entry")
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel("More options")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                JournalEntryEditorView(entry: entry)
            }
        }
    }

    private var entryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityLabel("Title: \(title)")
                } else {
                    Text("Untitled Entry")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Untitled entry")
                }

                Spacer()

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                        .accessibilityLabel("Favorite")
                }
            }

            HStack(spacing: 16) {
                Label(entry.formattedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Created on \(entry.formattedDate)")

                if entry.mood > 0 {
                    Label(moodText(for: entry.mood), systemImage: "face.smiling")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .accessibilityLabel("Mood: \(moodText(for: entry.mood))")
                }
            }
        }
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

    private var entryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)
                .accessibilityLabel("Entry content")

            Text(entry.content)
                .font(.body)
                .textSelection(.enabled)
                .accessibilityLabel(entry.content)
        }
    }

    private var relatedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Items")
                .font(.headline)
                .accessibilityLabel("Related items")

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
                .accessibilityLabel("Related to pattern: \(pattern.patternType)")
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
                .accessibilityLabel("Related to medication log")
            }
        }
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

    private func toggleFavorite() {
        entry.isFavorite.toggle()
        DataController.shared.updateJournalEntry(entry)
    }

    private func deleteEntry() {
        // Mark for deletion first
        onDelete()

        // Then dismiss - the actual deletion will happen after dismiss completes
        dismiss()
    }
}

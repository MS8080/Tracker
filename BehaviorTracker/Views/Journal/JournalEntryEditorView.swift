import SwiftUI
import AVFoundation

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioService = AudioRecordingService.shared

    private let dataController = DataController.shared
    var entry: JournalEntry?

    @State private var title: String
    @State private var content: String
    @State private var audioFileName: String?
    @State private var showingDeleteAudioAlert = false
    @FocusState private var contentIsFocused: Bool

    init(entry: JournalEntry? = nil) {
        self.entry = entry
        _title = State(initialValue: entry?.title ?? "")
        _content = State(initialValue: entry?.content ?? "")
        _audioFileName = State(initialValue: entry?.audioFileName)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title (optional)", text: $title)
                        .font(.headline)
                } header: {
                    Text("Title")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty && !contentIsFocused {
                                Text("Write your thoughts here...")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }

                            TextEditor(text: $content)
                                .frame(minHeight: contentIsFocused ? 300 : 150)
                                .animation(.easeInOut(duration: 0.2), value: contentIsFocused)
                                .focused($contentIsFocused)
                        }

                        // Voice note inside content section
                        Divider()

                        voiceNoteCompact
                    }
                } header: {
                    Text("Content")
                } footer: {
                    Text("\(content.count) characters")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(content.isEmpty)
                }
            }
            .onAppear {
                if entry == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        contentIsFocused = true
                    }
                }
            }
        }
    }

    // MARK: - Compact Voice Note (inside content section)
    @ViewBuilder
    private var voiceNoteCompact: some View {
        if audioService.isRecording {
            // Recording in progress
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)

                Text("Recording...")
                    .font(.subheadline)
                    .foregroundColor(.red)

                Text(audioService.formatTime(audioService.recordingTime))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    audioService.cancelRecording(fileName: audioFileName)
                    audioFileName = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Button {
                    audioService.stopRecording()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)

        } else if let fileName = audioFileName, !fileName.isEmpty {
            // Has recorded audio
            HStack(spacing: 12) {
                Button {
                    if audioService.isPlaying {
                        audioService.pausePlayback()
                    } else {
                        audioService.playAudio(fileName: fileName)
                    }
                } label: {
                    Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                Image(systemName: "waveform")
                    .foregroundColor(.blue)
                    .font(.caption)

                if let duration = audioService.getAudioDuration(fileName: fileName) {
                    Text(audioService.formatTime(audioService.isPlaying ? audioService.playbackTime : duration))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingDeleteAudioAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
            .alert("Delete Voice Note?", isPresented: $showingDeleteAudioAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    audioService.stopPlayback()
                    audioService.deleteAudioFile(fileName: fileName)
                    audioFileName = nil
                }
            } message: {
                Text("This cannot be undone.")
            }

        } else {
            // No audio - show compact record button
            HStack(spacing: 8) {
                if !audioService.hasPermission {
                    Button {
                        Task {
                            await audioService.requestPermission()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.slash")
                                .font(.subheadline)
                            Text("Enable microphone")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        audioFileName = audioService.startRecording()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.circle.fill")
                                .font(.title3)
                            Text("Add voice note")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func saveEntry() {
        if audioService.isRecording {
            audioService.stopRecording()
        }
        if audioService.isPlaying {
            audioService.stopPlayback()
        }

        if let existingEntry = entry {
            existingEntry.title = title.isEmpty ? nil : title
            existingEntry.content = content
            existingEntry.mood = 0
            existingEntry.audioFileName = audioFileName
            dataController.updateJournalEntry(existingEntry)
        } else {
            _ = dataController.createJournalEntry(
                title: title.isEmpty ? nil : title,
                content: content,
                mood: 0,
                audioFileName: audioFileName
            )
        }
        dismiss()
    }
}

#Preview {
    JournalEntryEditorView()
}

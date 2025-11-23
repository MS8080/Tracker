import SwiftUI
import AVFoundation

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var audioService = AudioRecordingService.shared

    var entry: JournalEntry?

    @State private var title: String
    @State private var content: String
    @State private var mood: Int16
    @State private var showingMoodPicker = false
    @State private var audioFileName: String?
    @State private var showingDeleteAudioAlert = false
    @FocusState private var contentIsFocused: Bool

    init(entry: JournalEntry? = nil) {
        self.entry = entry
        _title = State(initialValue: entry?.title ?? "")
        _content = State(initialValue: entry?.content ?? "")
        _mood = State(initialValue: entry?.mood ?? 0)
        _audioFileName = State(initialValue: entry?.audioFileName)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title (optional)", text: $title)
                        .font(.headline)
                        .accessibilityLabel("Journal entry title")
                } header: {
                    Text("Title")
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Write your thoughts here...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .accessibilityHidden(true)
                        }

                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .focused($contentIsFocused)
                            .accessibilityLabel("Journal entry content")
                    }
                } header: {
                    Text("Content")
                } footer: {
                    HStack {
                        Text("\(content.count) characters")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }

                Section {
                    voiceNoteSection
                } header: {
                    Text("Voice Note (Optional)")
                } footer: {
                    Text("Record a voice memo instead of or in addition to text")
                }

                Section {
                    Button(action: {
                        showingMoodPicker.toggle()
                    }) {
                        HStack {
                            Text("Mood")
                            Spacer()
                            if mood > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "face.smiling")
                                        .foregroundColor(.blue)
                                    Text(moodText(for: mood))
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Text("Not set")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("Mood: \(mood > 0 ? moodText(for: mood) : "Not set")")
                    .accessibilityHint("Tap to select mood")
                } header: {
                    Text("Mood (Optional)")
                }

                if showingMoodPicker {
                    Section {
                        ForEach([
                            (value: Int16(0), label: "Not set"),
                            (value: Int16(1), label: "Very Low"),
                            (value: Int16(2), label: "Low"),
                            (value: Int16(3), label: "Neutral"),
                            (value: Int16(4), label: "Good"),
                            (value: Int16(5), label: "Very Good")
                        ], id: \.value) { moodOption in
                            Button(action: {
                                mood = moodOption.value
                                withAnimation {
                                    showingMoodPicker = false
                                }
                            }) {
                                HStack {
                                    Text(moodOption.label)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if mood == moodOption.value {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .accessibilityLabel("\(moodOption.label) mood")
                            .accessibilityHint(mood == moodOption.value ? "Currently selected" : "")
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accessibility Features")
                            .font(.headline)

                        Label("Text-to-speech available in detail view", systemImage: "speaker.wave.2")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Label("All fields support VoiceOver", systemImage: "accessibility")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Label("Dynamic Type supported", systemImage: "textformat.size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Accessibility")
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(content.isEmpty)
                    .accessibilityLabel("Save journal entry")
                    .accessibilityHint(content.isEmpty ? "Content is required" : "")
                }
            }
            .onAppear {
                // Auto-focus on content when creating new entry
                if entry == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        contentIsFocused = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var voiceNoteSection: some View {
        if audioService.isRecording {
            // Recording in progress
            VStack(spacing: 16) {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(audioService.isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: audioService.isRecording)

                    Text("Recording...")
                        .font(.headline)
                        .foregroundColor(.red)

                    Spacer()

                    Text(audioService.formatTime(audioService.recordingTime))
                        .font(.title2)
                        .monospacedDigit()
                }

                // Audio level indicator
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.3))
                        .frame(width: geometry.size.width * CGFloat(audioService.audioLevel), height: 8)
                        .animation(.easeOut(duration: 0.1), value: audioService.audioLevel)
                }
                .frame(height: 8)

                HStack(spacing: 20) {
                    Button {
                        audioService.cancelRecording(fileName: audioFileName)
                        audioFileName = nil
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        audioService.stopRecording()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.red)
                    }

                    Spacer()
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        } else if let fileName = audioFileName, !fileName.isEmpty {
            // Has recorded audio
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)

                    Text("Voice Note Recorded")
                        .font(.subheadline)

                    Spacer()

                    if let duration = audioService.getAudioDuration(fileName: fileName) {
                        Text(audioService.formatTime(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        if audioService.isPlaying {
                            audioService.pausePlayback()
                        } else {
                            audioService.playAudio(fileName: fileName)
                        }
                    } label: {
                        Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }

                    if audioService.isPlaying {
                        Text(audioService.formatTime(audioService.playbackTime))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        showingDeleteAudioAlert = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 4)
            .alert("Delete Voice Note?", isPresented: $showingDeleteAudioAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let fileName = audioFileName {
                        audioService.stopPlayback()
                        audioService.deleteAudioFile(fileName: fileName)
                        audioFileName = nil
                    }
                }
            } message: {
                Text("This cannot be undone.")
            }
        } else {
            // No audio - show record button
            VStack(spacing: 12) {
                if !audioService.hasPermission {
                    Text("Microphone access required for voice notes")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Grant Permission") {
                        Task {
                            await audioService.requestPermission()
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        audioFileName = audioService.startRecording()
                    } label: {
                        HStack {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 36))
                            Text("Tap to Record")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func moodText(for mood: Int16) -> String {
        switch mood {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Very Good"
        default: return "Not set"
        }
    }

    private func saveEntry() {
        // Stop any ongoing recording or playback
        if audioService.isRecording {
            audioService.stopRecording()
        }
        if audioService.isPlaying {
            audioService.stopPlayback()
        }

        if let existingEntry = entry {
            // Update existing entry
            existingEntry.title = title.isEmpty ? nil : title
            existingEntry.content = content
            existingEntry.mood = mood
            existingEntry.audioFileName = audioFileName
            DataController.shared.updateJournalEntry(existingEntry)
        } else {
            // Create new entry
            viewModel.createEntry(
                title: title.isEmpty ? nil : title,
                content: content,
                mood: mood,
                audioFileName: audioFileName
            )
        }
        dismiss()
    }
}

#Preview {
    JournalEntryEditorView()
}

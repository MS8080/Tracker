import SwiftUI

struct VoiceNoteView: View {
    @EnvironmentObject var connectivity: WatchConnectivityService
    @State private var noteText = ""
    @State private var selectedMood: Int = 3
    @State private var showingTextInput = false
    @State private var showingConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Quick Note")
                    .font(.title3)
                    .fontWeight(.bold)

                // Dictation Button
                Button(action: {
                    showingTextInput = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)

                        Text("Tap to dictate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start voice dictation for journal note")

                if !noteText.isEmpty {
                    Divider()

                    // Mood Selector
                    VStack(spacing: 8) {
                        Text("How are you feeling?")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    Text(moodEmoji(for: mood))
                                        .font(.title2)
                                        .opacity(selectedMood == mood ? 1.0 : 0.4)
                                        .scaleEffect(selectedMood == mood ? 1.1 : 0.9)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(moodText(for: mood))
                            }
                        }
                    }

                    // Save Button
                    Button(action: saveNote) {
                        Label("Save Note", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(!connectivity.isReachable)
                }

                if !connectivity.isReachable {
                    Text("Connect iPhone to save")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingTextInput) {
            TextInputView(text: $noteText)
        }
        .alert("Note Saved!", isPresented: $showingConfirmation) {
            Button("OK", role: .cancel) {
                noteText = ""
                selectedMood = 3
            }
        } message: {
            Text("Your journal entry has been saved")
        }
    }

    private func moodEmoji(for mood: Int) -> String {
        switch mood {
        case 1: return "1"
        case 2: return "2"
        case 3: return "3"
        case 4: return "4"
        case 5: return "5"
        default: return "3"
        }
    }

    private func moodText(for mood: Int) -> String {
        switch mood {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Very Good"
        default: return "Neutral"
        }
    }

    private func saveNote() {
        guard !noteText.isEmpty else { return }

        connectivity.createJournalEntry(content: noteText, mood: selectedMood)
        showingConfirmation = true
    }
}

struct TextInputView: View {
    @Binding var text: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Dictate Note")
                .font(.headline)

            // Note: watchOS will automatically show dictation UI
            // when TextField becomes first responder
            TextField("Speak your note...", text: $text)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(text.isEmpty)
            }
        }
        .padding()
    }
}

#Preview {
    VoiceNoteView()
        .environmentObject(WatchConnectivityService.shared)
}

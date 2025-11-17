import SwiftUI

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JournalViewModel()

    var entry: JournalEntry?

    @State private var title: String
    @State private var content: String
    @State private var mood: Int16
    @State private var showingMoodPicker = false
    @FocusState private var contentIsFocused: Bool

    init(entry: JournalEntry? = nil) {
        self.entry = entry
        _title = State(initialValue: entry?.title ?? "")
        _content = State(initialValue: entry?.content ?? "")
        _mood = State(initialValue: entry?.mood ?? 0)
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
        if let existingEntry = entry {
            // Update existing entry
            existingEntry.title = title.isEmpty ? nil : title
            existingEntry.content = content
            existingEntry.mood = mood
            DataController.shared.updateJournalEntry(existingEntry)
        } else {
            // Create new entry
            viewModel.createEntry(
                title: title.isEmpty ? nil : title,
                content: content,
                mood: mood
            )
        }
        dismiss()
    }
}

#Preview {
    JournalEntryEditorView()
}

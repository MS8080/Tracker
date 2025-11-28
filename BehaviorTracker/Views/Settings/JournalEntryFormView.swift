import SwiftUI

struct JournalEntryFormView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mood: Int = 3 // Default to neutral
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (Optional)", text: $title)
                        .font(.headline)
                } header: {
                    Text("Title")
                }
                
                Section {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("What's on your mind?")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .focused($isContentFocused)
                    }
                } header: {
                    Text("Entry")
                }
                
                Section {
                    VStack(spacing: 16) {
                        Text("How are you feeling?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 20) {
                            ForEach(1...5, id: \.self) { moodValue in
                                Button {
                                    mood = moodValue
                                } label: {
                                    VStack(spacing: 8) {
                                        Text(moodEmoji(for: moodValue))
                                            .font(.system(size: 40))
                                            .scaleEffect(mood == moodValue ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: mood)
                                        
                                        if mood == moodValue {
                                            Circle()
                                                .fill(.blue)
                                                .frame(width: 6, height: 6)
                                        } else {
                                            Circle()
                                                .fill(.clear)
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Mood")
                }
            }
            .navigationTitle("New Journal Entry")
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
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Automatically focus the content field
                isContentFocused = true
            }
        }
    }
    
    private func saveEntry() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else { return }
        
        viewModel.createEntry(
            title: trimmedTitle.isEmpty ? nil : trimmedTitle,
            content: trimmedContent,
            mood: Int16(mood)
        )
        
        dismiss()
    }
    
    private func moodEmoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😔"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "😄"
        default: return "🙂"
        }
    }
}

#Preview {
    JournalEntryFormView(viewModel: JournalViewModel())
}

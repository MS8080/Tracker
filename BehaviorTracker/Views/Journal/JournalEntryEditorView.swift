import SwiftUI

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let dataController = DataController.shared
    var entry: JournalEntry?

    @State private var title: String
    @State private var content: String
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var contentIsFocused: Bool

    init(entry: JournalEntry? = nil) {
        self.entry = entry
        _title = State(initialValue: entry?.title ?? "")
        _content = State(initialValue: entry?.content ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
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
                } footer: {
                    Text("\(content.count) characters")
                        .foregroundColor(.secondary)
                }

                Section {
                    TextField("Add a title (optional)", text: $title)
                        .font(.subheadline)
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(content.isEmpty ? .secondary : .blue)
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func saveEntry() {
        do {
            if let existingEntry = entry {
                existingEntry.title = title.isEmpty ? nil : title
                existingEntry.content = content
                existingEntry.mood = 0
                dataController.updateJournalEntry(existingEntry)
            } else {
                _ = try dataController.createJournalEntry(
                    title: title.isEmpty ? nil : title,
                    content: content,
                    mood: 0,
                    audioFileName: nil
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    JournalEntryEditorView()
}

import SwiftUI

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    private let dataController = DataController.shared

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showVoiceRecorder = false
    @FocusState private var contentIsFocused: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Date header
                        HStack {
                            Label(Date().formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        // Title field
                        TextField("Add a title (optional)", text: $title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Divider()

                        // Content - directly editable
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty && !contentIsFocused {
                                Text("Write your thoughts here...")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }

                            TextEditor(text: $content)
                                .frame(minHeight: contentIsFocused ? 300 : 200)
                                .focused($contentIsFocused)
                        }
                    }
                    .padding()
                }
                .navigationTitle("New Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(.white)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            HapticFeedback.medium.trigger()
                            contentIsFocused = false
                            showVoiceRecorder = true
                        } label: {
                            Image(systemName: "mic.fill")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            saveEntry()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .disabled(content.isEmpty)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        contentIsFocused = true
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

            if showVoiceRecorder {
                VoiceRecorderOverlay(
                    isPresented: $showVoiceRecorder,
                    onTranscription: { text in
                        if content.isEmpty {
                            content = text
                        } else {
                            content += " " + text
                        }
                    }
                )
            }
        }
    }

    private func saveEntry() {
        do {
            _ = try dataController.createJournalEntry(
                title: title.isEmpty ? nil : title,
                content: content,
                mood: 0,
                audioFileName: nil
            )
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

import SwiftUI

// MARK: - Journal Entry Editor

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    private let dataController = DataController.shared
    private let analysisCoordinator = AnalysisCoordinator.shared
    private let mentionService = EventMentionService.shared

    // Entry data
    @State private var content: String = ""
    @State private var entryDate: Date = Date()

    // UI state
    @State private var showDatePicker = false
    @State private var showVoiceRecorder = false
    @State private var isSaving = false
    @State private var isAnalyzing = false
    @State private var showDeleteUndo = false
    @State private var showDiscardAlert = false
    @State private var hasUnsavedChanges = false
    @FocusState private var contentIsFocused: Bool

    // Event mention autocomplete
    @State private var showEventSuggestions = false
    @State private var eventSuggestions: [CalendarEvent] = []
    @StateObject private var calendarService = CalendarEventService.shared

    // Auto-save timer
    @State private var autoSaveTimer: Timer?
    @State private var lastSavedContent: String = ""

    // Theme
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            NavigationView {
                VStack(spacing: 0) {
                    mainContent
                    JournalActionToolbar(
                        isAnalyzing: isAnalyzing,
                        isContentEmpty: content.isEmpty,
                        onVoice: {
                            contentIsFocused = false
                            showVoiceRecorder = true
                        },
                        onAnalyze: analyzeImmediately,
                        onDelete: deleteEntry
                    )
                }
                .background(Color.clear)
                .navigationTitle("Journal Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
            }

            overlays
        }
        .onAppear(perform: onAppear)
        .onDisappear { autoSaveTimer?.invalidate() }
        .onChange(of: content) { _, _ in
            hasUnsavedChanges = content != lastSavedContent
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Save", role: .none) { saveEntry() }
            Button("Discard", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Would you like to save them?")
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                timestampButton
                contentEditor
            }
            .padding(Spacing.lg)
            .cardStyle(theme: theme)
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Timestamp Button

    private var timestampButton: some View {
        Button {
            HapticFeedback.light.trigger()
            contentIsFocused = false
            showDatePicker = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                Text(formattedDate)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.white.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy 'at' HH:mm"
        return formatter.string(from: entryDate)
    }

    // MARK: - Content Editor

    private var contentEditor: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty && !contentIsFocused {
                Text("Write your thoughts here... Use @ to mention events")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }

            TextEditor(text: $content)
                .font(.body)
                .lineSpacing(5)
                .foregroundStyle(.white.opacity(0.95))
                .frame(minHeight: 300)
                .focused($contentIsFocused)
                .scrollContentBackground(.hidden)
                .onChange(of: content) { _, newValue in
                    checkForMentionTrigger(in: newValue)
                }

            if showEventSuggestions && !eventSuggestions.isEmpty {
                EventMentionAutocomplete(
                    events: eventSuggestions,
                    onSelect: insertEventMention,
                    onDismiss: { showEventSuggestions = false }
                )
                .padding(.top, 40)
                .padding(.horizontal, Spacing.sm)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { handleCancel() }
                .foregroundStyle(.white)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                saveEntry()
            } label: {
                if isSaving {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark")
                }
            }
            .disabled(content.isEmpty || isSaving)
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlays: some View {
        if showVoiceRecorder {
            VoiceRecorderOverlay(
                isPresented: $showVoiceRecorder,
                onTranscription: { text in
                    content = content.isEmpty ? text : content + " " + text
                    hasUnsavedChanges = true
                }
            )
        }

        if showDatePicker {
            JournalDatePickerOverlay(
                selectedDate: $entryDate,
                isPresented: $showDatePicker,
                theme: theme
            )
        }

        if showDeleteUndo {
            UndoToast(
                message: "Entry deleted",
                theme: theme,
                onUndo: { showDeleteUndo = false },
                onDismiss: { showDeleteUndo = false }
            )
        }
    }

    // MARK: - Mention Logic

    private func checkForMentionTrigger(in text: String) {
        if let query = mentionService.extractTypingQuery(from: text, cursorPosition: text.count) {
            if calendarService.isAuthorized {
                eventSuggestions = mentionService.searchEvents(query: query, around: entryDate)
                showEventSuggestions = true
            }
        } else {
            showEventSuggestions = false
        }
    }

    private func insertEventMention(_ event: CalendarEvent) {
        if let range = mentionService.getTypingMentionRange(from: content, cursorPosition: content.count) {
            let mention = mentionService.createMention(for: event)
            content.replaceSubrange(range, with: mention + " ")
        } else {
            content += mentionService.createMention(for: event) + " "
        }
        showEventSuggestions = false
        HapticFeedback.light.trigger()
    }

    // MARK: - Actions

    private func onAppear() {
        setupAutoSave()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            contentIsFocused = true
        }
    }

    private func handleCancel() {
        if hasUnsavedChanges && !content.isEmpty {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            if hasUnsavedChanges && !content.isEmpty {
                saveDraft()
            }
        }
    }

    private func saveDraft() {
        UserDefaults.standard.set(content, forKey: "journalDraft")
        UserDefaults.standard.set(entryDate, forKey: "journalDraftDate")
        lastSavedContent = content
        hasUnsavedChanges = false
    }

    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "journalDraft")
        UserDefaults.standard.removeObject(forKey: "journalDraftDate")
    }

    private func saveEntry() {
        guard !content.isEmpty else { return }
        isSaving = true

        Task {
            do {
                let entry = try dataController.createJournalEntry(
                    title: nil,
                    content: content,
                    mood: 0,
                    audioFileName: nil
                )

                if !Calendar.current.isDate(entryDate, equalTo: Date(), toGranularity: .minute) {
                    entry.timestamp = entryDate
                    try dataController.container.viewContext.save()
                }

                clearDraft()

                // Queue for background analysis via coordinator
                analysisCoordinator.queueAnalysis(for: entry)

                // Notify observers that a new entry was created
                NotificationCenter.default.post(name: .journalEntryCreated, object: entry)

                await MainActor.run {
                    HapticFeedback.success.trigger()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    HapticFeedback.error.trigger()
                }
            }
        }
    }

    private func deleteEntry() {
        content = ""
        clearDraft()
        withAnimation { showDeleteUndo = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
    }

    private func analyzeImmediately() {
        guard !content.isEmpty else { return }
        isAnalyzing = true

        Task {
            do {
                let entry = try dataController.createJournalEntry(
                    title: nil,
                    content: content,
                    mood: 0,
                    audioFileName: nil
                )

                if !Calendar.current.isDate(entryDate, equalTo: Date(), toGranularity: .minute) {
                    entry.timestamp = entryDate
                    try dataController.container.viewContext.save()
                }

                clearDraft()

                // Analyze immediately via coordinator (blocking)
                try await analysisCoordinator.analyzeNow(entry)

                // Notify observers that a new entry was created
                NotificationCenter.default.post(name: .journalEntryCreated, object: entry)

                await MainActor.run {
                    isAnalyzing = false
                    HapticFeedback.success.trigger()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    HapticFeedback.error.trigger()
                }
            }
        }
    }
}

#Preview {
    JournalEntryEditorView()
}

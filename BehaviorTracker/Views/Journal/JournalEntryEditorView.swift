import SwiftUI

// MARK: - Circular Glass Modifier

struct CircularGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

// MARK: - Journal Entry Editor

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    private let dataController = DataController.shared
    private let extractionService = PatternExtractionService.shared

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

    // Auto-save timer
    @State private var autoSaveTimer: Timer?
    @State private var lastSavedContent: String = ""

    // Theme
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    // Date formatters
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy 'at' HH:mm"
        return formatter
    }

    var body: some View {
        ZStack {
            // Themed background
            theme.gradient
                .ignoresSafeArea()

            NavigationView {
                VStack(spacing: 0) {
                    // Main content area
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            // Tappable timestamp
                            timestampButton

                            // Content text area
                            contentEditor
                        }
                        .padding(Spacing.lg)
                        .cardStyle(theme: theme)
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                    }
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)

                    // Action toolbar above keyboard
                    actionToolbar
                }
                .background(Color.clear)
                .navigationTitle("Journal Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            handleCancel()
                        }
                        .foregroundStyle(.white)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        saveButton
                    }
                    .hideSharedBackground()
                }
            }

            // Voice recorder overlay
            if showVoiceRecorder {
                VoiceRecorderOverlay(
                    isPresented: $showVoiceRecorder,
                    onTranscription: { text in
                        if content.isEmpty {
                            content = text
                        } else {
                            content += " " + text
                        }
                        hasUnsavedChanges = true
                    }
                )
            }

            // Date picker sheet
            if showDatePicker {
                datePickerOverlay
            }

            // Delete undo toast
            if showDeleteUndo {
                deleteUndoToast
            }
        }
        .onAppear {
            setupAutoSave()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                contentIsFocused = true
            }
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
        }
        .onChange(of: content) { _, _ in
            hasUnsavedChanges = content != lastSavedContent
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Save", role: .none) {
                saveEntry()
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Would you like to save them?")
        }
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
                Text(dateFormatter.string(from: entryDate))
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

    // MARK: - Content Editor

    private var contentEditor: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty && !contentIsFocused {
                Text("Write your thoughts here...")
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
        }
    }

    // MARK: - Action Toolbar

    private var actionToolbar: some View {
        HStack(spacing: Spacing.lg) {
            // Voice input button
            Button {
                HapticFeedback.medium.trigger()
                contentIsFocused = false
                showVoiceRecorder = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                    Text("Voice")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            // Analyze button
            Button {
                HapticFeedback.medium.trigger()
                analyzeImmediately()
            } label: {
                VStack(spacing: 2) {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                            .frame(height: 20)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                    }
                    Text("Analyze")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(content.isEmpty || isAnalyzing)

            // Delete button
            Button {
                HapticFeedback.medium.trigger()
                deleteEntry()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                    Text("Delete")
                        .font(.caption2)
                }
                .foregroundStyle(.red.opacity(0.9))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(content.isEmpty)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveEntry()
        } label: {
            if isSaving {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.8)
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .modifier(CircularGlassModifier())
        .disabled(content.isEmpty || isSaving)
    }

    // MARK: - Date Picker Overlay

    private var datePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDatePicker = false
                    }
                }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Date & Time")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showDatePicker = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()

                DatePicker(
                    "Entry Date",
                    selection: $entryDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(theme.primaryColor)
                .colorScheme(.dark)
                .padding()
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding(.horizontal, Spacing.lg)
        }
        .transition(.opacity)
    }

    // MARK: - Delete Undo Toast

    private var deleteUndoToast: some View {
        VStack {
            Spacer()

            HStack {
                Text("Entry deleted")
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                Button("Undo") {
                    // Undo would restore the entry - for now just dismiss toast
                    withAnimation {
                        showDeleteUndo = false
                    }
                }
                .font(.subheadline.bold())
                .foregroundStyle(theme.primaryColor)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showDeleteUndo = false
                }
            }
        }
    }

    // MARK: - Actions

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
        // Save to UserDefaults as draft
        UserDefaults.standard.set(content, forKey: "journalDraft")
        UserDefaults.standard.set(entryDate, forKey: "journalDraftDate")
        lastSavedContent = content
        hasUnsavedChanges = false
        print("[JournalEditor] Draft auto-saved")
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

                // Update timestamp if changed
                if !Calendar.current.isDate(entryDate, equalTo: Date(), toGranularity: .minute) {
                    entry.timestamp = entryDate
                    try dataController.container.viewContext.save()
                }

                // Clear draft
                clearDraft()

                // Auto-analyze in background
                Task.detached(priority: .background) {
                    await analyzeEntry(entry)
                }

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
        // Clear content and dismiss
        content = ""
        clearDraft()

        withAnimation {
            showDeleteUndo = true
        }

        // Dismiss after showing toast briefly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }

    private func analyzeImmediately() {
        guard !content.isEmpty else { return }
        isAnalyzing = true

        Task {
            // First save the entry
            do {
                let entry = try dataController.createJournalEntry(
                    title: nil,
                    content: content,
                    mood: 0,
                    audioFileName: nil
                )

                // Update timestamp if changed
                if !Calendar.current.isDate(entryDate, equalTo: Date(), toGranularity: .minute) {
                    entry.timestamp = entryDate
                    try dataController.container.viewContext.save()
                }

                // Clear draft
                clearDraft()

                // Analyze immediately
                await analyzeEntry(entry)

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

    private func analyzeEntry(_ entry: JournalEntry) async {
        guard extractionService.isConfigured else { return }

        // Debounce: skip if this entry was recently analyzed
        if GeminiService.shared.wasRecentlyAnalyzed(entryID: entry.id) {
            print("[JournalEntryEditorView] Skipping analysis - entry \(entry.id) was recently analyzed")
            return
        }

        // Mark as being analyzed to prevent duplicates
        GeminiService.shared.markAsAnalyzed(entryID: entry.id)

        do {
            let result = try await extractionService.extractPatterns(from: entry.content)
            let context = dataController.container.viewContext

            // Create ExtractedPattern entities
            var createdPatterns: [String: ExtractedPattern] = [:]

            for patternData in result.patterns {
                let pattern = ExtractedPattern(context: context)
                pattern.id = UUID()
                pattern.patternType = patternData.type
                pattern.category = patternData.category
                pattern.intensity = Int16(patternData.intensity)
                pattern.triggers = patternData.triggers ?? []
                pattern.timeOfDay = patternData.timeOfDay ?? result.context.timeOfDay
                pattern.copingStrategies = patternData.copingUsed ?? []
                pattern.details = patternData.details
                pattern.confidence = result.confidence
                pattern.timestamp = entry.timestamp
                pattern.journalEntry = entry

                createdPatterns[patternData.type] = pattern
            }

            // Create cascade relationships
            for cascadeData in result.cascades {
                if let fromPattern = createdPatterns[cascadeData.from],
                   let toPattern = createdPatterns[cascadeData.to] {
                    let cascade = PatternCascade(context: context)
                    cascade.id = UUID()
                    cascade.confidence = cascadeData.confidence
                    cascade.descriptionText = cascadeData.description
                    cascade.timestamp = entry.timestamp
                    cascade.fromPattern = fromPattern
                    cascade.toPattern = toPattern
                }
            }

            // Update journal entry
            entry.isAnalyzed = true
            entry.analysisConfidence = result.confidence
            entry.analysisSummary = result.summary
            entry.overallIntensity = Int16(result.overallIntensity)

            try context.save()

        } catch {
            print("Failed to analyze entry: \(error.localizedDescription)")
        }
    }
}

#Preview {
    JournalEntryEditorView()
}

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

struct VoiceRecorderOverlay: View {
    @Binding var isPresented: Bool
    let onTranscription: (String) -> Void

    @StateObject private var transcriptionService = WhisperTranscriptionService.shared
    @State private var recordingState: RecordingState = .idle
    @State private var pulseScale: CGFloat = 1.0
    @State private var appearAnimation = false

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    enum RecordingState {
        case idle
        case recording
        case transcribing
    }

    var body: some View {
        ZStack {
            Color.black.opacity(appearAnimation ? 0.7 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    if recordingState == .idle {
                        withAnimation(.easeOut(duration: 0.2)) {
                            appearAnimation = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                        }
                    }
                }

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    handleBar
                        .padding(.top, Spacing.md)

                    if recordingState == .transcribing {
                        transcribingView
                    } else {
                        recordingView
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white.opacity(0.05))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
                )
                .offset(y: appearAnimation ? 0 : 400)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
        .task {
            // Load model if needed
            if !transcriptionService.isModelLoaded && !transcriptionService.isLoadingModel {
                await transcriptionService.loadModel()
            } else if transcriptionService.isLoadingModel {
                // Wait for existing loading to complete
                while transcriptionService.isLoadingModel {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
            }

            // Small delay to ensure UI state is synced
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

            // Only start recording if model loaded successfully and we're still idle
            if transcriptionService.isModelLoaded && recordingState == .idle && transcriptionService.errorMessage == nil {
                let started = await transcriptionService.startRecording()
                if started {
                    withAnimation(.spring(response: 0.3)) {
                        recordingState = .recording
                    }
                }
            }
        }
    }

    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 40, height: 5)
    }

    private var recordingView: some View {
        VStack(spacing: Spacing.xl) {
            // Header - only show when recording
            if recordingState == .recording {
                VStack(spacing: Spacing.sm) {
                    Text("Listening...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Tap stop when finished")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.lg)

                VStack(spacing: Spacing.lg) {
                    LiveWaveformView(level: transcriptionService.audioLevel, theme: theme)
                        .frame(height: 60)
                        .padding(.horizontal, Spacing.lg)

                    Text(transcriptionService.formatTime(transcriptionService.recordingTime))
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(theme.primaryColor)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Loading state
            if transcriptionService.isLoadingModel && recordingState == .idle {
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(theme.primaryColor)

                    Text(transcriptionService.transcriptionProgress.isEmpty ? "Preparing..." : transcriptionService.transcriptionProgress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.lg)
            }

            // Mic button
            if !transcriptionService.isLoadingModel || recordingState == .recording {
                ZStack {
                    if recordingState == .recording {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseScale)
                            .opacity(2 - pulseScale)
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                                    pulseScale = 2.0
                                }
                            }
                            .onDisappear {
                                pulseScale = 1.0
                            }
                    }

                    Button {
                        HapticFeedback.medium.trigger()
                        Task {
                            await handleRecordButton()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    recordingState == .recording
                                        ? LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 88, height: 88)
                                .shadow(color: (recordingState == .recording ? Color.red : theme.primaryColor).opacity(0.4), radius: 12, y: 4)

                            if recordingState == .recording {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.white)
                                    .frame(width: 28, height: 28)
                            } else {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .disabled(transcriptionService.isLoadingModel)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: recordingState)
                }
                .frame(height: 120)
            }

            // Cancel recording button
            if recordingState == .recording {
                Button {
                    HapticFeedback.light.trigger()
                    transcriptionService.cancelRecording()
                    withAnimation(.spring(response: 0.3)) {
                        recordingState = .idle
                    }
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Error message
            if let error = transcriptionService.errorMessage {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            // Cancel button (when not recording)
            if recordingState == .idle && !transcriptionService.isLoadingModel {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        appearAnimation = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPresented = false
                    }
                } label: {
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xl + 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: recordingState)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: transcriptionService.isLoadingModel)
    }

    private var transcribingView: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.sm) {
                Text("Transcribing")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Converting your speech to text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.lg)

            TranscribingAnimationView(theme: theme)
                .frame(height: 80)

            Text("This may take a moment...")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xl + 20)
    }

    private func handleRecordButton() async {
        if recordingState == .idle {
            let started = await transcriptionService.startRecording()
            if started {
                withAnimation(.spring(response: 0.3)) {
                    recordingState = .recording
                }
            }
        } else if recordingState == .recording {
            withAnimation(.spring(response: 0.3)) {
                recordingState = .transcribing
            }

            if let transcription = await transcriptionService.stopRecordingAndTranscribe() {
                onTranscription(transcription)
                withAnimation(.easeOut(duration: 0.2)) {
                    appearAnimation = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPresented = false
                }
            } else {
                withAnimation(.spring(response: 0.3)) {
                    recordingState = .idle
                }
            }
        }
    }

}

struct LiveWaveformView: View {
    let level: Float
    let theme: AppTheme
    let barCount = 40

    @State private var phases: [Double] = []

    init(level: Float, theme: AppTheme) {
        self.level = level
        self.theme = theme
        _phases = State(initialValue: (0..<40).map { _ in Double.random(in: 0...(.pi * 2)) })
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let barWidth: CGFloat = 4
                let spacing: CGFloat = 3
                let totalWidth = CGFloat(barCount) * (barWidth + spacing) - spacing
                let startX = (size.width - totalWidth) / 2

                for i in 0..<barCount {
                    let x = startX + CGFloat(i) * (barWidth + spacing)
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    let wavePhase = sin(time * 3 + Double(i) * 0.3 + phases[i])
                    let levelFactor = Double(level) * 0.7 + 0.3
                    let normalizedHeight = (wavePhase * 0.5 + 0.5) * levelFactor

                    let minHeight: CGFloat = 4
                    let maxHeight = size.height - 4
                    let barHeight = minHeight + CGFloat(normalizedHeight) * (maxHeight - minHeight)

                    let rect = CGRect(
                        x: x,
                        y: (size.height - barHeight) / 2,
                        width: barWidth,
                        height: barHeight
                    )

                    let path = RoundedRectangle(cornerRadius: 2)
                        .path(in: rect)

                    let centerDistance = abs(Double(i) - Double(barCount) / 2) / (Double(barCount) / 2)
                    let opacity = 1.0 - centerDistance * 0.4

                    context.fill(path, with: .color(theme.primaryColor.opacity(opacity)))
                }
            }
        }
    }
}

struct TranscribingAnimationView: View {
    let theme: AppTheme
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.primaryColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 16, height: 16)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    JournalEntryEditorView()
}

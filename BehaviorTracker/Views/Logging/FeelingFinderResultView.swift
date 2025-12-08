import SwiftUI
import CoreData

// MARK: - Result Step

struct ResultStep: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: FeelingFinderViewModel
    let onDismiss: () -> Void

    @State private var showingAddMore = false
    @State private var additionalText = ""
    @State private var showingFlyingTile = false
    @State private var buttonFrame: CGRect = .zero
    @State private var showSuccess = false
    @FocusState private var isTextFieldFocused: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    /// Pattern mappings for detail selections
    private static let detailToPatterns: [String: [PatternType]] = [
        // Environment
        "Bright or harsh lighting": [.sensoryOverload, .environmentalSensitivity],
        "Noise level": [.sensoryOverload, .environmentalSensitivity],
        "Smells": [.sensoryOverload, .environmentalSensitivity],
        "Temperature uncomfortable": [.sensoryOverload, .environmentalSensitivity],
        "Too many people around": [.sensoryOverload],
        "Crowded or cluttered space": [.sensoryOverload],
        "Been in same place too long": [.sensoryRecovery],
        // Events
        "Upcoming exam or test": [.externalDemand, .taskAvoidance],
        "Job interview": [.externalDemand, .taskAvoidance],
        "Deadline at work or school": [.externalDemand, .taskAvoidance],
        "Public speaking or presentation": [.externalDemand, .taskAvoidance],
        "Social invitation or gathering": [.socialInteraction],
        "Family event or obligation": [.socialInteraction],
        "Conflict or argument that happened": [.miscommunication, .socialRecovery],
        "Something unexpected happened": [.unexpectedChange, .routineDisruption],
        "Waiting for results or answer": [.emotionalOverwhelm],
        // Health
        "Heart racing or pounding": [.emotionalOverwhelm],
        "Breathing feels off": [.emotionalOverwhelm],
        "Muscle tension": [.physicalTension],
        "Headache or pressure": [.physicalTension],
        "Fatigue or heaviness": [.burnoutIndicator, .energyLevel],
        "Restlessness": [.regulatoryStimming],
        "Sensory sensitivity": [.sensoryOverload],
        "Haven't eaten or slept well": [.sleepQuality, .appetiteChange],
        // Social
        "Recent difficult conversation": [.socialInteraction, .socialRecovery],
        "Anticipating social interaction": [.socialInteraction],
        "Feeling isolated or lonely": [.socialRecovery],
        "Someone is upset with me": [.miscommunication],
        "I'm upset with someone": [.miscommunication],
        "Had to mask or pretend": [.maskingIntensity],
        "Feeling misunderstood": [.communicationDifficulty],
        "Rejection or criticism": [.emotionalOverwhelm],
        // Demand
        "Task I keep avoiding": [.taskAvoidance, .taskInitiation],
        "Too many things to do": [.decisionFatigue, .burnoutIndicator],
        "Someone expecting something from me": [.externalDemand],
        "Decision I need to make": [.decisionFatigue],
        "Pressure to be productive": [.internalDemand],
        "Responsibility I don't want": [.taskAvoidance, .autonomyNeed]
    ]

    private var relatedPatternTypes: [PatternType] {
        let allDetails = viewModel.data.environmentDetails
            .union(viewModel.data.eventDetails)
            .union(viewModel.data.healthDetails)
            .union(viewModel.data.socialDetails)
            .union(viewModel.data.demandDetails)

        var patterns = Set<PatternType>()
        for detail in allDetails {
            if let mapped = Self.detailToPatterns[detail] {
                patterns.formUnion(mapped)
            }
        }
        return patterns.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.yellow)
                            Text("Your entry")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Text("Based on what you shared")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Generated entry or loading
                    if viewModel.isGenerating {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else {
                        generatedEntryContent
                    }
                }
                .padding(.bottom, 100)
            }

            // Flying tile animation
            if showingFlyingTile {
                FeelingFinderFlyingTile(
                    content: String(viewModel.data.generatedEntry.prefix(80)),
                    startFrame: buttonFrame,
                    theme: theme
                ) {
                    showingFlyingTile = false
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onDismiss()
                    }
                }
            }

            // Success toast
            if showSuccess {
                successToast
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Writing your entry...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        .padding(.horizontal)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.generateEntry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        .padding(.horizontal)
    }

    // MARK: - Generated Entry Content

    private var generatedEntryContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Show generated entry
            Text(viewModel.data.generatedEntry)
                .font(.body)
                .italic()
                .lineSpacing(6)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
                .padding(.horizontal)

            // Related patterns - learning hint
            if !relatedPatternTypes.isEmpty {
                relatedPatternsView
            }

            // Add more details section
            if showingAddMore {
                addMoreDetailsView
            }

            // Action buttons
            if !showingAddMore {
                actionButtonsView
            }
        }
    }

    // MARK: - Related Patterns View

    private var relatedPatternsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This relates to:")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 6) {
                ForEach(relatedPatternTypes.prefix(5), id: \.self) { pattern in
                    Text(pattern.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(pattern.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(pattern.category.color.opacity(0.15))
                        )
                }
            }

            Text("Next time, try logging directly in \(relatedPatternTypes.first?.category.rawValue ?? "Log")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Add More Details View

    private var addMoreDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Is there anything else you want to add?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextEditor(text: $additionalText)
                .font(.body)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.1))
                )
                .focused($isTextFieldFocused)

            HStack {
                Button("Cancel") {
                    showingAddMore = false
                    additionalText = ""
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Regenerate") {
                    viewModel.data.additionalText = additionalText
                    Task {
                        await viewModel.generateEntry()
                    }
                    showingAddMore = false
                }
                .fontWeight(.medium)
                .disabled(additionalText.isEmpty)
            }
        }
        .padding(16)
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        .padding(.horizontal)
    }

    // MARK: - Action Buttons View

    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Primary actions
            HStack(spacing: 12) {
                GeometryReader { geo in
                    FeelingFinderActionButton(
                        title: "Save to Journal",
                        icon: "book.fill",
                        color: .blue,
                        theme: theme
                    ) {
                        buttonFrame = geo.frame(in: .global)
                        saveToJournal()
                        showingFlyingTile = true
                    }
                }

                FeelingFinderActionButton(
                    title: "Bookmark",
                    icon: "bookmark.fill",
                    color: .orange,
                    theme: theme
                ) {
                    saveToJournal(bookmark: true)
                    HapticFeedback.success.trigger()
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onDismiss()
                    }
                }
            }
            .frame(height: 80)

            // Secondary actions
            HStack(spacing: 12) {
                FeelingFinderActionButton(
                    title: "Add more details",
                    icon: "plus.bubble",
                    color: .green,
                    theme: theme,
                    isSecondary: true
                ) {
                    showingAddMore = true
                    isTextFieldFocused = true
                }

                FeelingFinderActionButton(
                    title: "Try again",
                    icon: "arrow.clockwise",
                    color: .purple,
                    theme: theme,
                    isSecondary: true
                ) {
                    Task {
                        await viewModel.generateEntry()
                    }
                }
            }
            .frame(height: 60)

            // Discard
            Button {
                onDismiss()
            } label: {
                Text("Discard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }

    // MARK: - Success Toast

    private var successToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Saved")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Save to Journal

    private func saveToJournal(bookmark: Bool = false) {
        var content = ""

        // Add selections summary
        if let feeling = viewModel.data.generalFeeling {
            content += "Feeling: \(feeling.rawValue)\n"
        }

        let allDetails = viewModel.data.environmentDetails
            .union(viewModel.data.eventDetails)
            .union(viewModel.data.healthDetails)
            .union(viewModel.data.socialDetails)
            .union(viewModel.data.demandDetails)

        if !allDetails.isEmpty {
            content += "Factors: \(allDetails.joined(separator: ", "))\n"
        }

        content += "\n---\n\n"
        content += viewModel.data.generatedEntry

        // Create entry
        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.title = "Guided Entry: \(Date().formatted(date: .abbreviated, time: .shortened))"
        entry.content = content
        entry.timestamp = Date()
        entry.mood = 0
        entry.isFavorite = bookmark

        // Add tag
        let tagName = "Guided"
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "name == %@", tagName)
        fetchRequest.fetchLimit = 1

        do {
            let tag: Tag
            if let existing = try viewContext.fetch(fetchRequest).first {
                tag = existing
            } else {
                tag = Tag(context: viewContext, name: tagName)
            }
            entry.addToTags(tag)
            try viewContext.save()
            HapticFeedback.success.trigger()
        } catch {
        }
    }
}

// MARK: - Action Button

struct FeelingFinderActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let theme: AppTheme
    var isSecondary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(isSecondary ? .body : .title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(isSecondary ? .caption : .caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cardStyle(theme: theme, cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flying Tile

struct FeelingFinderFlyingTile: View {
    let content: String
    let startFrame: CGRect
    let theme: AppTheme
    let onComplete: () -> Void

    @State private var position: CGPoint
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    init(content: String, startFrame: CGRect, theme: AppTheme, onComplete: @escaping () -> Void) {
        self.content = content
        self.startFrame = startFrame
        self.theme = theme
        self.onComplete = onComplete
        _position = State(initialValue: CGPoint(x: startFrame.midX, y: startFrame.midY))
    }

    var body: some View {
        Text(content + "...")
            .font(.caption)
            .italic()
            .lineLimit(2)
            .padding(12)
            .frame(width: 150)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial.opacity(0.5))
                    )
                    .shadow(radius: 8)
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear { animate() }
    }

    private func animate() {
        let screen = UIScreen.main.bounds
        let targetY = screen.height - 40

        withAnimation(.easeOut(duration: 0.15)) {
            scale = 0.9
            position.y -= 15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeIn(duration: 0.2)) {
                position = CGPoint(x: screen.width * 0.5, y: targetY)
                scale = 0.25
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.1)) {
                opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            onComplete()
        }
    }
}



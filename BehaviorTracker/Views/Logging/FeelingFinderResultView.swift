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

    /// Get specific pattern types based on user's detail selections
    private var relatedPatternTypes: [PatternType] {
        var patterns = Set<PatternType>()

        // Map environment details to pattern types
        for detail in viewModel.data.environmentDetails {
            switch detail {
            case "Bright or harsh lighting", "Noise level", "Smells", "Temperature uncomfortable":
                patterns.insert(.sensoryOverload)
                patterns.insert(.environmentalSensitivity)
            case "Too many people around", "Crowded or cluttered space":
                patterns.insert(.sensoryOverload)
            case "Been in same place too long":
                patterns.insert(.sensoryRecovery)
            default: break
            }
        }

        // Map event details to pattern types
        for detail in viewModel.data.eventDetails {
            switch detail {
            case "Upcoming exam or test", "Job interview", "Deadline at work or school", "Public speaking or presentation":
                patterns.insert(.externalDemand)
                patterns.insert(.taskAvoidance)
            case "Social invitation or gathering", "Family event or obligation":
                patterns.insert(.socialInteraction)
            case "Conflict or argument that happened":
                patterns.insert(.miscommunication)
                patterns.insert(.socialRecovery)
            case "Something unexpected happened":
                patterns.insert(.unexpectedChange)
                patterns.insert(.routineDisruption)
            case "Waiting for results or answer":
                patterns.insert(.emotionalOverwhelm)
            default:
                patterns.insert(.routineDisruption)
            }
        }

        // Map health details to pattern types
        for detail in viewModel.data.healthDetails {
            switch detail {
            case "Heart racing or pounding", "Breathing feels off":
                patterns.insert(.emotionalOverwhelm)
            case "Muscle tension", "Headache or pressure":
                patterns.insert(.physicalTension)
            case "Fatigue or heaviness":
                patterns.insert(.burnoutIndicator)
                patterns.insert(.energyLevel)
            case "Restlessness":
                patterns.insert(.regulatoryStimming)
            case "Sensory sensitivity":
                patterns.insert(.sensoryOverload)
            case "Haven't eaten or slept well":
                patterns.insert(.sleepQuality)
                patterns.insert(.appetiteChange)
            default:
                patterns.insert(.physicalTension)
            }
        }

        // Map social details to pattern types
        for detail in viewModel.data.socialDetails {
            switch detail {
            case "Recent difficult conversation":
                patterns.insert(.socialInteraction)
                patterns.insert(.socialRecovery)
            case "Anticipating social interaction":
                patterns.insert(.socialInteraction)
            case "Feeling isolated or lonely":
                patterns.insert(.socialRecovery)
            case "Someone is upset with me", "I'm upset with someone":
                patterns.insert(.miscommunication)
            case "Had to mask or pretend":
                patterns.insert(.maskingIntensity)
            case "Feeling misunderstood":
                patterns.insert(.communicationDifficulty)
            case "Rejection or criticism":
                patterns.insert(.emotionalOverwhelm)
            default:
                patterns.insert(.socialInteraction)
            }
        }

        // Map demand details to pattern types
        for detail in viewModel.data.demandDetails {
            switch detail {
            case "Task I keep avoiding":
                patterns.insert(.taskAvoidance)
                patterns.insert(.taskInitiation)
            case "Too many things to do":
                patterns.insert(.decisionFatigue)
                patterns.insert(.burnoutIndicator)
            case "Someone expecting something from me":
                patterns.insert(.externalDemand)
            case "Decision I need to make":
                patterns.insert(.decisionFatigue)
            case "Pressure to be productive":
                patterns.insert(.internalDemand)
            case "Responsibility I don't want":
                patterns.insert(.taskAvoidance)
                patterns.insert(.autonomyNeed)
            default:
                patterns.insert(.taskAvoidance)
            }
        }

        return Array(patterns).sorted { $0.rawValue < $1.rawValue }
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

            CategoryFlowLayout(spacing: 6) {
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
            print("Failed to save: \(error)")
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

// MARK: - Category Flow Layout Helper

struct CategoryFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangement(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangement(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

import SwiftUI
import CoreData

// MARK: - Data Models

struct FeelingFinderData {
    var generalFeeling: GeneralFeeling?
    var selectedFactors: Set<GuidedFactor> = []
    var environmentDetails: Set<String> = []
    var eventDetails: Set<String> = []
    var healthDetails: Set<String> = []
    var socialDetails: Set<String> = []
    var demandDetails: Set<String> = []
    var additionalText: String = ""
    var generatedEntry: String = ""
}

enum GeneralFeeling: String, CaseIterable, Identifiable {
    case irritated = "Irritated / Agitated"
    case sad = "Sad / Down"
    case anxious = "Anxious / On edge"
    case overwhelmed = "Overwhelmed / Too much"
    case empty = "Empty / Numb"
    case mixed = "Mixed / Confused"
    case other = "Something else I can't name"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .irritated: return "flame"
        case .sad: return "cloud.rain"
        case .anxious: return "bolt.heart"
        case .overwhelmed: return "tornado"
        case .empty: return "circle.dashed"
        case .mixed: return "arrow.triangle.2.circlepath"
        case .other: return "questionmark"
        }
    }

    var color: Color {
        switch self {
        case .irritated: return .red
        case .sad: return .blue
        case .anxious: return .orange
        case .overwhelmed: return .purple
        case .empty: return .gray
        case .mixed: return .cyan
        case .other: return .secondary
        }
    }
}

enum GuidedFactor: String, CaseIterable, Identifiable {
    case environment = "Environment"
    case event = "Specific event"
    case health = "Health / Body"
    case social = "Social / People"
    case demands = "Demands / Obligations"
    case notSure = "Not sure"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .environment: return "building.2"
        case .event: return "calendar.badge.exclamationmark"
        case .health: return "heart.text.square"
        case .social: return "person.2"
        case .demands: return "checklist"
        case .notSure: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .environment: return .cyan
        case .event: return .orange
        case .health: return .green
        case .social: return .purple
        case .demands: return .red
        case .notSure: return .gray
        }
    }

    /// Maps to the app's main logging categories
    var relatedCategories: [PatternCategory] {
        switch self {
        case .environment:
            return [.sensory]
        case .event:
            return [.routineChange, .energyRegulation]
        case .health:
            return [.physicalWellbeing, .energyRegulation]
        case .social:
            return [.social]
        case .demands:
            return [.demandAvoidance, .executiveFunction]
        case .notSure:
            return []
        }
    }
}

// MARK: - Detail Options

struct DetailOptions {
    static let environment = [
        "Bright or harsh lighting",
        "Noise level",
        "Too many people around",
        "Crowded or cluttered space",
        "Temperature uncomfortable",
        "Smells",
        "Been in same place too long"
    ]

    static let event = [
        "Upcoming exam or test",
        "Job interview",
        "Social invitation or gathering",
        "Family event or obligation",
        "Medical appointment",
        "Travel plans",
        "Deadline at work or school",
        "Public speaking or presentation",
        "Holiday or national event",
        "Anniversary or significant date",
        "Conflict or argument that happened",
        "Bad news received",
        "Waiting for results or answer",
        "Something unexpected happened"
    ]

    static let health = [
        "Heart racing or pounding",
        "Dizziness or lightheaded",
        "Nausea or stomach upset",
        "Muscle tension",
        "Headache or pressure",
        "Fatigue or heaviness",
        "Restlessness",
        "Sensory sensitivity",
        "Breathing feels off",
        "Haven't eaten or slept well"
    ]

    static let social = [
        "Recent difficult conversation",
        "Anticipating social interaction",
        "Feeling isolated or lonely",
        "Someone is upset with me",
        "I'm upset with someone",
        "Had to mask or pretend",
        "Feeling misunderstood",
        "Rejection or criticism"
    ]

    static let demands = [
        "Task I keep avoiding",
        "Too many things to do",
        "Someone expecting something from me",
        "Decision I need to make",
        "Pressure to be productive",
        "Responsibility I don't want"
    ]
}

// MARK: - Main View

struct FeelingFinderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FeelingFinderViewModel()
    @State private var currentStep = 1
    @State private var detailStepIndex = 0

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    // Get factors that need detail steps (excluding "Not sure")
    private var factorsNeedingDetails: [GuidedFactor] {
        viewModel.data.selectedFactors
            .filter { $0 != .notSure }
            .sorted { $0.rawValue < $1.rawValue }
    }

    private var totalSteps: Int {
        // Step 1: General feeling
        // Step 2: Contributing factors
        // Step 3+: Detail steps for each selected factor
        // Final: AI result
        2 + factorsNeedingDetails.count + 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    progressBar
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Content based on current step
                    TabView(selection: $currentStep) {
                        // Step 1: General Feeling
                        GeneralFeelingStep(data: $viewModel.data)
                            .tag(1)

                        // Step 2: Contributing Factors
                        ContributingFactorsStep(data: $viewModel.data)
                            .tag(2)

                        // Step 3+: Detail steps for each factor
                        ForEach(Array(factorsNeedingDetails.enumerated()), id: \.element.id) { index, factor in
                            DetailStep(
                                factor: factor,
                                data: $viewModel.data
                            )
                            .tag(3 + index)
                        }

                        // Final: AI Result
                        ResultStep(viewModel: viewModel, onDismiss: { dismiss() })
                            .tag(2 + factorsNeedingDetails.count + 1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.15), value: currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding()
                }
            }
            .navigationTitle("Guided Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.primaryColor)
                    .frame(width: geo.size.width * progressPercentage, height: 6)
                    .animation(.spring(response: 0.2), value: currentStep)
            }
        }
        .frame(height: 6)
        .padding(.vertical, 12)
    }

    private var progressPercentage: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if currentStep > 1 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.white.opacity(0.2))
                    )
                }
            }

            // Next button
            if currentStep < totalSteps {
                Button {
                    withAnimation {
                        if currentStep == 2 + factorsNeedingDetails.count {
                            // About to go to result - generate AI entry
                            Task {
                                await viewModel.generateEntry()
                            }
                        }
                        currentStep += 1
                    }
                } label: {
                    HStack {
                        Text(nextButtonLabel)
                        Image(systemName: nextButtonIcon)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(canProceed ? theme.primaryColor : theme.primaryColor.opacity(0.5))
                    )
                }
                .disabled(!canProceed)
            }
        }
    }

    private var nextButtonLabel: String {
        if currentStep == 2 + factorsNeedingDetails.count {
            return "Generate"
        }
        return "Next"
    }

    private var nextButtonIcon: String {
        if currentStep == 2 + factorsNeedingDetails.count {
            return "sparkles"
        }
        return "chevron.right"
    }

    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return viewModel.data.generalFeeling != nil
        case 2:
            return !viewModel.data.selectedFactors.isEmpty
        default:
            return true
        }
    }
}

// MARK: - Step 1: General Feeling

struct GeneralFeelingStep: View {
    @Binding var data: FeelingFinderData

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What best describes how you're feeling right now?")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Pick the closest match")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                VStack(spacing: 10) {
                    ForEach(GeneralFeeling.allCases) { feeling in
                        FeelingOptionButton(
                            feeling: feeling,
                            isSelected: data.generalFeeling == feeling,
                            theme: theme
                        ) {
                            HapticFeedback.light.trigger()
                            data.generalFeeling = feeling
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
    }
}

struct FeelingOptionButton: View {
    let feeling: GeneralFeeling
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: feeling.icon)
                    .font(.title3)
                    .foregroundStyle(feeling.color)
                    .frame(width: 32)

                Text(feeling.rawValue)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(feeling.color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? feeling.color.opacity(0.15) : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? feeling.color : theme.cardBorderColor, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Contributing Factors

struct ContributingFactorsStep: View {
    @Binding var data: FeelingFinderData

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you think is most affecting you right now?")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Select all that apply")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                VStack(spacing: 10) {
                    ForEach(GuidedFactor.allCases) { factor in
                        FactorOptionButton(
                            factor: factor,
                            isSelected: data.selectedFactors.contains(factor),
                            theme: theme
                        ) {
                            toggleFactor(factor)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
    }

    private func toggleFactor(_ factor: GuidedFactor) {
        HapticFeedback.light.trigger()
        if data.selectedFactors.contains(factor) {
            data.selectedFactors.remove(factor)
        } else {
            // If selecting "Not sure", clear others
            if factor == .notSure {
                data.selectedFactors.removeAll()
            } else {
                data.selectedFactors.remove(.notSure)
            }
            data.selectedFactors.insert(factor)
        }
    }
}

struct FactorOptionButton: View {
    let factor: GuidedFactor
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: factor.icon)
                    .font(.title3)
                    .foregroundStyle(factor.color)
                    .frame(width: 32)

                Text(factor.rawValue)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? factor.color : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? factor.color.opacity(0.15) : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? factor.color : theme.cardBorderColor, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Detail Steps

struct DetailStep: View {
    let factor: GuidedFactor
    @Binding var data: FeelingFinderData

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    private var options: [String] {
        switch factor {
        case .environment: return DetailOptions.environment
        case .event: return DetailOptions.event
        case .health: return DetailOptions.health
        case .social: return DetailOptions.social
        case .demands: return DetailOptions.demands
        case .notSure: return []
        }
    }

    private var selectedDetails: Binding<Set<String>> {
        switch factor {
        case .environment: return $data.environmentDetails
        case .event: return $data.eventDetails
        case .health: return $data.healthDetails
        case .social: return $data.socialDetails
        case .demands: return $data.demandDetails
        case .notSure: return .constant([])
        }
    }

    private var promptText: String {
        switch factor {
        case .environment: return "What about your environment is affecting you?"
        case .event: return "Is there a specific event affecting you?"
        case .health: return "What are you noticing in your body?"
        case .social: return "What about people or social situations is affecting you?"
        case .demands: return "What demands or obligations are weighing on you?"
        case .notSure: return ""
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: factor.icon)
                            .foregroundStyle(factor.color)
                        Text(factor.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(promptText)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Select all that apply")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                VStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        DetailOptionButton(
                            text: option,
                            isSelected: selectedDetails.wrappedValue.contains(option),
                            accentColor: factor.color,
                            theme: theme
                        ) {
                            toggleDetail(option)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
    }

    private func toggleDetail(_ option: String) {
        HapticFeedback.light.trigger()
        var details = selectedDetails.wrappedValue
        if details.contains(option) {
            details.remove(option)
        } else {
            details.insert(option)
        }
        selectedDetails.wrappedValue = details
    }
}

struct DetailOptionButton: View {
    let text: String
    let isSelected: Bool
    let accentColor: Color
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .clear : theme.cardBorderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

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
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Writing your entry...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(theme.cardBackground)
                        )
                        .padding(.horizontal)
                    } else if let error = viewModel.errorMessage {
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
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(theme.cardBackground)
                        )
                        .padding(.horizontal)
                    } else {
                        // Show generated entry
                        Text(viewModel.data.generatedEntry)
                            .font(.body)
                            .italic()
                            .lineSpacing(6)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(theme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
                            )
                            .padding(.horizontal)

                        // Related patterns - learning hint
                        if !relatedPatternTypes.isEmpty {
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

                        // Add more details section
                        if showingAddMore {
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
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(theme.cardBackground)
                            )
                            .padding(.horizontal)
                        }

                        // Action buttons
                        if !showingAddMore {
                            VStack(spacing: 12) {
                                // Primary actions
                                HStack(spacing: 12) {
                                    GeometryReader { geo in
                                        ActionButton(
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

                                    ActionButton(
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
                                    ActionButton(
                                        title: "Add more details",
                                        icon: "plus.bubble",
                                        color: .green,
                                        theme: theme,
                                        isSecondary: true
                                    ) {
                                        showingAddMore = true
                                        isTextFieldFocused = true
                                    }

                                    ActionButton(
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
                    }
                }
                .padding(.bottom, 100)
            }

            // Flying tile animation
            if showingFlyingTile {
                FlyingTile(
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
        }
    }

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

struct ActionButton: View {
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
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flying Tile

struct FlyingTile: View {
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
                    .fill(theme.cardBackground)
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

// MARK: - ViewModel

@MainActor
class FeelingFinderViewModel: ObservableObject {
    @Published var data = FeelingFinderData()
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private let aiService = AIAnalysisService.shared

    func generateEntry() async {
        isGenerating = true
        errorMessage = nil

        let prompt = buildPrompt()

        do {
            let result = try await aiService.analyzeWithPrompt(prompt)
            data.generatedEntry = result
        } catch {
            errorMessage = "Couldn't generate entry. Please try again."
        }

        isGenerating = false
    }

    private func buildPrompt() -> String {
        var prompt = """
        You are an emotion identification assistant helping users understand their internal state.
        The user has difficulty recognizing and naming emotions.

        You will receive:
        - A general feeling category they selected
        - Contributing factors they identified
        - Specific details about those factors
        - Optionally, free text they wrote for more context

        Your task:
        Generate a first-person journal entry (4-5 lines) that:
        - Starts with "I am feeling..." or similar first-person phrasing
        - Connects their general feeling to the contributing factors
        - Mentions physical sensations if provided
        - Explains what their body/mind is likely responding to
        - Ends with a gentle insight or possible helpful action
        - Uses simple, clear, non-clinical language
        - Sounds like something they would write about themselves

        Do not:
        - Use second person ("you are feeling")
        - Be diagnostic or clinical
        - Exceed 5 lines
        - Use bullet points or lists
        - Add generic advice unrelated to their specific input

        ---

        """

        // General feeling
        if let feeling = data.generalFeeling {
            prompt += "General feeling: \(feeling.rawValue)\n\n"
        }

        // Contributing factors
        if !data.selectedFactors.isEmpty {
            prompt += "Contributing factors: \(data.selectedFactors.map { $0.rawValue }.joined(separator: ", "))\n\n"
        }

        // Details
        if !data.environmentDetails.isEmpty {
            prompt += "Environment details: \(data.environmentDetails.joined(separator: ", "))\n"
        }
        if !data.eventDetails.isEmpty {
            prompt += "Event details: \(data.eventDetails.joined(separator: ", "))\n"
        }
        if !data.healthDetails.isEmpty {
            prompt += "Body/health details: \(data.healthDetails.joined(separator: ", "))\n"
        }
        if !data.socialDetails.isEmpty {
            prompt += "Social details: \(data.socialDetails.joined(separator: ", "))\n"
        }
        if !data.demandDetails.isEmpty {
            prompt += "Demands/obligations details: \(data.demandDetails.joined(separator: ", "))\n"
        }

        // Additional text
        if !data.additionalText.isEmpty {
            prompt += "\nAdditional context from user: \(data.additionalText)\n"
        }

        prompt += "\n---\n\nWrite the first-person journal entry now:"

        return prompt
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

#Preview {
    FeelingFinderView()
}

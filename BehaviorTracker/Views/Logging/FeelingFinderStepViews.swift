import SwiftUI

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
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(feeling.color.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial.opacity(0.5))
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? feeling.color : Color.white.opacity(0.15), lineWidth: isSelected ? 1.5 : 0.5)
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
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(factor.color.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial.opacity(0.5))
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? factor.color : Color.white.opacity(0.15), lineWidth: isSelected ? 1.5 : 0.5)
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
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.5))
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .clear : Color.white.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

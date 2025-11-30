import SwiftUI
import CoreData

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
                    .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Progress Bar

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

    // MARK: - Navigation Buttons

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

#Preview {
    FeelingFinderView()
}

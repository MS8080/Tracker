import SwiftUI

struct MedicationQuickLogView: View {
    @StateObject private var viewModel = MedicationViewModel()
    @State private var isExpanded = false
    @Namespace private var animation

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
            } else {
                collapsedButton
            }
        }
        .onAppear {
            viewModel.loadMedications()
            viewModel.loadTodaysLogs()
        }
    }

    // MARK: - Collapsed Button (at bottom, wide bar)
    private var collapsedButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = true
            }
            HapticFeedback.medium.trigger()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("Medications")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                // Show count of medications to log
                let unloggedCount = viewModel.medications.filter { !viewModel.hasTakenToday(medication: $0) }.count
                if unloggedCount > 0 {
                    Text("\(unloggedCount) to log")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(theme.primaryColor)
                        .clipShape(Capsule())
                } else if !viewModel.medications.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded View (squircle window)
    private var expandedView: some View {
        VStack(spacing: 16) {
            // Header with close button
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("Medications")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)

            // Medications list
            if viewModel.medications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pills")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No medications added")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.medications) { medication in
                        MedicationSlideToLogCard(
                            medication: medication,
                            viewModel: viewModel,
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
    }
}

// MARK: - Slide to Log Card (hold and slide in one motion)
struct MedicationSlideToLogCard: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel
    let theme: AppTheme

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var hasLoggedToday = false
    @GestureState private var isLongPressing = false

    private let maxDragWidth: CGFloat = UIScreen.main.bounds.width - 80

    private var doseLevel: Int {
        let level = Int(ceil((dragOffset / maxDragWidth) * 10))
        return max(1, min(10, level))
    }

    private var progress: CGFloat {
        min(1, max(0, dragOffset / maxDragWidth))
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.15))

                // Progress fill
                if isDragging || isLongPressing {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(progressGradient)
                        .frame(width: max(0, dragOffset))
                        .animation(.interactiveSpring(), value: dragOffset)
                }

                // Content
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(hasLoggedToday ? Color.green.opacity(0.2) : theme.primaryColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: hasLoggedToday ? "checkmark" : "pills.fill")
                            .font(.body)
                            .foregroundColor(hasLoggedToday ? .green : theme.primaryColor)
                    }

                    // Medication info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(medication.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(isDragging ? .white : .primary)

                        if let dosage = medication.dosage {
                            Text(dosage)
                                .font(.caption)
                                .foregroundStyle(isDragging ? .white.opacity(0.8) : .secondary)
                        }
                    }

                    Spacer()

                    // Status / Dose indicator
                    if hasLoggedToday {
                        Text("Done")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    } else if isDragging || isLongPressing {
                        Text("\(doseLevel * 10)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .animation(.none, value: doseLevel)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text("Slide")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(height: 64)
            .gesture(
                LongPressGesture(minimumDuration: 0.1)
                    .updating($isLongPressing) { value, state, _ in
                        state = value
                    }
                    .simultaneously(with:
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !hasLoggedToday else { return }

                                if !isDragging && value.translation.width > 5 {
                                    isDragging = true
                                    HapticFeedback.medium.trigger()
                                }

                                if isDragging {
                                    let newOffset = max(0, min(cardWidth, value.translation.width))
                                    let oldLevel = Int(ceil((dragOffset / cardWidth) * 10))
                                    dragOffset = newOffset
                                    let newLevel = Int(ceil((newOffset / cardWidth) * 10))

                                    if newLevel != oldLevel && newLevel >= 1 {
                                        HapticFeedback.light.trigger()
                                    }
                                }
                            }
                            .onEnded { value in
                                guard !hasLoggedToday else { return }

                                if isDragging && dragOffset > cardWidth * 0.15 {
                                    // Log with selected dose
                                    logMedicationWithDose()
                                }

                                withAnimation(.spring(response: 0.3)) {
                                    dragOffset = 0
                                    isDragging = false
                                }
                            }
                    )
            )
            .allowsHitTesting(!hasLoggedToday)
        }
        .frame(height: 64)
        .onAppear {
            hasLoggedToday = viewModel.hasTakenToday(medication: medication)
        }
        .onChange(of: viewModel.todaysLogs) { _, _ in
            hasLoggedToday = viewModel.hasTakenToday(medication: medication)
        }
    }

    private var progressGradient: LinearGradient {
        let color: Color = {
            switch doseLevel {
            case 1...3: return .orange
            case 4...6: return .yellow
            case 7...9: return .mint
            case 10: return .green
            default: return theme.primaryColor
            }
        }()

        return LinearGradient(
            colors: [theme.primaryColor, color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func logMedicationWithDose() {
        let finalDose = doseLevel
        let doseNote = "Dose: \(finalDose * 10)% (\(finalDose)/10)"

        _ = viewModel.logMedication(
            medication: medication,
            taken: true,
            skippedReason: nil,
            sideEffects: nil,
            effectiveness: 0,
            mood: 0,
            energyLevel: 0,
            notes: doseNote
        )

        withAnimation(.spring(response: 0.4)) {
            hasLoggedToday = true
        }

        HapticFeedback.success.trigger()
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        VStack {
            Spacer()
            MedicationQuickLogView()
                .padding()
        }
    }
}

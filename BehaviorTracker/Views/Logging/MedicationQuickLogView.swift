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
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
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

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadowColor, radius: 8, y: 4)
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
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
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
                        MedicationTapToLogCard(
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
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.cardBorderColor, lineWidth: 0.5)
        )
        .shadow(color: theme.cardShadowColor, radius: 12, y: 6)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
    }
}

// MARK: - Simple Tap to Log Card
struct MedicationTapToLogCard: View {
    let medication: Medication
    @ObservedObject var viewModel: MedicationViewModel
    let theme: AppTheme

    @State private var hasLoggedToday = false
    @State private var logTime: Date?

    var body: some View {
        Button {
            guard !hasLoggedToday else { return }
            logMedication()
        } label: {
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
                        .foregroundStyle(.primary)

                    if let dosage = medication.dosage {
                        Text(dosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status
                if hasLoggedToday {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        if let time = logTime {
                            Text(time, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Tap to log")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(hasLoggedToday ? Color.green.opacity(0.08) : Color.gray.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            hasLoggedToday = viewModel.hasTakenToday(medication: medication)
            if hasLoggedToday {
                logTime = viewModel.getLogTime(for: medication)
            }
        }
        .onChange(of: viewModel.todaysLogs) { _, _ in
            hasLoggedToday = viewModel.hasTakenToday(medication: medication)
            if hasLoggedToday {
                logTime = viewModel.getLogTime(for: medication)
            }
        }
    }

    private func logMedication() {
        _ = viewModel.logMedication(
            medication: medication,
            taken: true,
            skippedReason: nil,
            sideEffects: nil,
            effectiveness: 0,
            mood: 0,
            energyLevel: 0,
            notes: nil
        )

        withAnimation(.spring(response: 0.2)) {
            hasLoggedToday = true
            logTime = Date()
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

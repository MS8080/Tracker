import SwiftUI

// MARK: - Import Loading View

struct ImportLoadingView: View {
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primaryColor)

            VStack(spacing: 8) {
                Text("Loading medications from Apple Health...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("This may take a moment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .cardStyle(theme: theme, cornerRadius: 20)
        .padding()
    }
}

// MARK: - Import Error View

struct ImportErrorView: View {
    let message: String
    let theme: AppTheme
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 12) {
                Text("Unable to Import")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if message.contains("entitlement") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Important Note")
                            .font(.headline)
                    }

                    Text("Medication import requires special Apple approval. In the meantime, you can manually add your medications.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
            }

            Button {
                onDismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primaryColor)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Import Empty View

struct ImportEmptyView: View {
    let theme: AppTheme
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.primaryColor)
            }

            VStack(spacing: 12) {
                Text("No Medications Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("No medications were found in Apple Health. Add medications in the Health app first, then try importing again.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    onDismiss()
                } label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.primaryColor)
                        )
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Add in Health App")
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryColor)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Medication List Header

struct MedicationListHeader: View {
    let medicationCount: Int
    let selectedCount: Int
    let allSelected: Bool
    let theme: AppTheme
    let onToggleAll: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 8) {
                Text("Select medications to import")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text("\(medicationCount) found in Health")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Select All button
            HStack {
                Button {
                    onToggleAll()
                    HapticFeedback.light.trigger()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: allSelected ? "checkmark.square.fill" : "square")
                            .foregroundStyle(theme.primaryColor)
                        Text(allSelected ? "Deselect All" : "Select All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(theme.primaryColor)
                }

                Spacer()

                Text("\(selectedCount) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primaryColor.opacity(0.15))
                    )
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Import Medication Row

struct ImportMedicationRow: View {
    let medication: MedicationImportData
    let isSelected: Bool
    let theme: AppTheme
    let onTap: () -> Void

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                onTap()
            }
            HapticFeedback.light.trigger()
        } label: {
            HStack(spacing: 16) {
                // Checkbox with animation
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.primaryColor : Color.secondary.opacity(0.2))
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isSelected)

                // Medication icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.primaryColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "pills.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.primaryColor)
                }

                // Medication info
                VStack(alignment: .leading, spacing: 6) {
                    Text(medication.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let dosage = medication.dosage {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.dots.needle.33percent")
                                .font(.caption2)
                            Text(dosage)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("Started \(medication.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 8)

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .opacity(0.5)
            }
            .padding(16)
            .cardStyle(theme: theme, cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? theme.primaryColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 0.98 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("ImportLoadingView") {
    ImportLoadingView(theme: .purple)
}

#Preview("ImportErrorView") {
    ImportErrorView(
        message: "This feature requires special Apple entitlement for clinical health records.",
        theme: .purple,
        onDismiss: {}
    )
}

#Preview("ImportEmptyView") {
    ImportEmptyView(theme: .purple, onDismiss: {})
}

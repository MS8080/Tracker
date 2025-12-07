import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @AppStorage("appearance") private var appearance: AppAppearance = .dark
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    @AppStorage("useCapsuleLabels") private var useCapsuleLabels: Bool = false
    @AppStorage("cardStyle") private var cardStyle: String = CardStyle.glass.rawValue

    @ThemeWrapper var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                themeColorsSection
                cardStyleSection
                appearanceModeSection
                accessibilitySection
                previewSection
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Theme Colors Section

    private var themeColorsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(.purple)
                    .font(.title3)
                Text("Theme Color")
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .center, spacing: 20) {
                ForEach(AppTheme.allCases, id: \.self) { themeOption in
                    ThemeColorButton(
                        theme: themeOption,
                        isSelected: selectedThemeRaw == themeOption.rawValue
                    ) {
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                            selectedThemeRaw = themeOption.rawValue
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Card Style Section

    private var cardStyleSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundStyle(.mint)
                    .font(.title3)
                Text("Card Style")
                    .font(.headline)
            }

            HStack(spacing: 12) {
                CardStyleButton(
                    title: "Glass",
                    description: "Blur effects & glow",
                    icon: "sparkles",
                    isSelected: cardStyle == CardStyle.glass.rawValue
                ) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        cardStyle = CardStyle.glass.rawValue
                    }
                }

                CardStyleButton(
                    title: "Material",
                    description: "Simple & fast",
                    icon: "square.fill",
                    isSelected: cardStyle == CardStyle.material.rawValue
                ) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        cardStyle = CardStyle.material.rawValue
                    }
                }
            }

            Text("Material style uses less effects for better battery life on older devices")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Appearance Mode Section

    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Appearance")
                    .font(.headline)
            }

            HStack(spacing: 12) {
                AppearanceModeButton(
                    title: "Light",
                    icon: "sun.max.fill",
                    iconColor: .orange,
                    backgroundColor: .white,
                    isSelected: appearance == .light
                ) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        appearance = .light
                    }
                }

                AppearanceModeButton(
                    title: "Dark",
                    icon: "moon.fill",
                    iconColor: .yellow,
                    backgroundColor: Color(white: 0.15),
                    isSelected: appearance == .dark
                ) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        appearance = .dark
                    }
                }
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Accessibility Section

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "accessibility")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text("Accessibility")
                    .font(.headline)
            }

            Toggle(isOn: $useCapsuleLabels) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capsule Labels")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Add capsule backgrounds to timestamps and section titles for better visibility")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(theme.primaryColor)

            // Preview of capsule labels
            if useCapsuleLabels {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Preview:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.md) {
                        Text("7:30 PM")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.primaryColor)
                            .capsuleLabel(theme: theme, style: .time)

                        Text("Weekly Summary")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .capsuleLabel(theme: theme, style: .title)
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundStyle(.cyan)
                    .font(.title3)
                Text("Preview")
                    .font(.headline)
            }

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.gradient)
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 30, height: 30)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                                .frame(width: 50, height: 8)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }

            Text("This is how your app will look")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .cardStyle(theme: theme)
    }
}

// MARK: - Theme Color Button

struct ThemeColorButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryColor, theme.primaryColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: theme.primaryColor.opacity(0.4), radius: isSelected ? 8 : 0)

                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 52, height: 52)

                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                }

                Text(theme.rawValue)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(height: 14)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

// MARK: - Appearance Mode Button

struct AppearanceModeButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(backgroundColor)
                        .frame(height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8)

                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(iconColor)
                }

                HStack(spacing: 6) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// MARK: - Card Style Button

struct CardStyleButton: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color(white: 0.15))
                        .frame(height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(isSelected ? Color.mint : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: isSelected ? .mint.opacity(0.3) : .clear, radius: 8)

                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .mint : .white.opacity(0.6))
                }

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.mint)
                                .font(.caption)
                        }
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }

                    Text(description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView(viewModel: SettingsViewModel())
    }
}

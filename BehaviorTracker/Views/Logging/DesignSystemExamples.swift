// QUICK REFERENCE: Design System Components
// Copy and paste these examples into your views

import SwiftUI

// MARK: - Example Usage

struct DesignSystemExamples: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ICONS
                iconExamples
                
                // CARDS
                cardExamples
                
                // BADGES
                badgeExamples
                
                // EMPTY STATES
                emptyStateExample
                
                // INFO BOXES
                infoBoxExample
                
                // BUTTONS
                buttonExamples
                
                // SECTION HEADERS
                sectionHeaderExamples
            }
            .padding()
        }
        .background(theme.gradient.ignoresSafeArea())
    }
    
    // MARK: - Icon Examples
    
    private var iconExamples: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Themed Icons")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Circle background
                ThemedIcon(
                    systemName: "heart.fill",
                    color: .red,
                    size: 44,
                    backgroundStyle: .circle
                )
                
                // Rounded square background
                ThemedIcon(
                    systemName: "pills.fill",
                    color: .purple,
                    size: 44,
                    backgroundStyle: .roundedSquare
                )
                
                // No background
                ThemedIcon(
                    systemName: "star.fill",
                    color: .yellow,
                    size: 44,
                    backgroundStyle: .none
                )
                
                // Larger size
                ThemedIcon(
                    systemName: "moon.fill",
                    color: .indigo,
                    size: 56,
                    backgroundStyle: .circle
                )
            }
        }
        .padding(20)
        .cardStyle(theme: theme, cornerRadius: 20)
    }
    
    // MARK: - Card Examples
    
    private var cardExamples: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Styles")
                .font(.headline)
            
            // Standard card (most common)
            Text("Standard Card - Default style with shadow")
                .padding(Spacing.lg)
                .cardStyle(theme: theme)

            // Compact card (for lists)
            HStack {
                ThemedIcon(systemName: "checkmark.circle.fill", color: .green, size: 40, backgroundStyle: .circle)
                Text("Compact Card - For list items")
                Spacer()
            }
            .padding(Spacing.md)
            .compactCardStyle(theme: theme)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground.opacity(0.5))
        )
    }
    
    // MARK: - Badge Examples
    
    private var badgeExamples: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.headline)
            
            HStack(spacing: 12) {
                BadgeView(text: "New", color: .blue)
                BadgeView(text: "5", color: .red)
                BadgeView(text: "Active", color: .green, icon: "checkmark")
                BadgeView(text: "Premium", color: .purple, icon: "star.fill")
            }
        }
        .padding(20)
        .cardStyle(theme: theme, cornerRadius: 20)
    }
    
    // MARK: - Empty State Example
    
    private var emptyStateExample: some View {
        EmptyStateView(
            icon: "tray.fill",
            title: "No Items Yet",
            message: "Get started by adding your first item. It's quick and easy!",
            actionTitle: "Add First Item",
            action: { print("Action tapped") }
        )
    }
    
    // MARK: - Info Box Example
    
    private var infoBoxExample: some View {
        VStack(spacing: 12) {
            InfoBox(
                icon: "lightbulb.fill",
                title: "Pro Tip",
                message: "Use info boxes to highlight important information or provide helpful hints.",
                color: .orange
            )
            
            InfoBox(
                icon: "exclamationmark.triangle.fill",
                title: "Warning",
                message: "This action cannot be undone.",
                color: .red
            )
            
            InfoBox(
                icon: "checkmark.seal.fill",
                title: "Success",
                message: "Your changes have been saved.",
                color: .green
            )
        }
    }
    
    // MARK: - Button Examples
    
    private var buttonExamples: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Buttons")
                .font(.headline)
            
            // Primary action button
            Button {
                print("Primary action")
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Primary Action")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(14)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Secondary action button
            Button {
                print("Secondary action")
            } label: {
                HStack {
                    ThemedIcon(systemName: "arrow.clockwise", color: theme.primaryColor, size: 32, backgroundStyle: .circle)
                    Text("Secondary Action")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accentLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                                .foregroundStyle(theme.accentMedium)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(20)
        .cardStyle(theme: theme, cornerRadius: 20)
    }
    
    // MARK: - Section Header Examples
    
    private var sectionHeaderExamples: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Simple header
            SectionHeaderView(title: "Simple Header")
            
            // Header with icon
            SectionHeaderView(title: "With Icon", icon: "star.fill")
            
            // Header with action
            SectionHeaderView(
                title: "With Action",
                icon: "list.bullet",
                actionTitle: "See All",
                action: { print("Action tapped") }
            )
        }
        .padding(20)
        .cardStyle(theme: theme, cornerRadius: 20)
    }
}

// MARK: - Settings Row Example

struct SettingsRowExample: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        VStack(spacing: 12) {
            SettingsRow(
                icon: "bell.fill",
                title: "Notifications",
                color: .blue,
                theme: theme,
                action: { print("Tapped") }
            )
            
            SettingsRow(
                icon: "lock.shield.fill",
                title: "Privacy",
                color: .green,
                theme: theme,
                action: { print("Tapped") }
            )
            
            SettingsRow(
                icon: "paintbrush.fill",
                title: "Appearance",
                color: .purple,
                theme: theme,
                action: { print("Tapped") }
            )
        }
        .padding()
    }
}

// MARK: - Typography Examples

struct TypographyExamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card Title")
                .cardTitle()
            
            Text("Card Subtitle")
                .cardSubtitle()
            
            Text("Emphasized Body Text")
                .emphasizedBody()
            
            Text("Metadata or Caption")
                .metadataText()
        }
        .padding()
    }
}

// MARK: - Color Usage Examples

struct ColorUsageExamples: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Theme colors
            colorSwatch("Primary", color: theme.primaryColor)
            colorSwatch("Timeline", color: theme.timelineColor)
            colorSwatch("Accent Light", color: theme.accentLight)
            colorSwatch("Accent Medium", color: theme.accentMedium)
            
            Divider()
            
            // Semantic colors
            colorSwatch("Success", color: .green)
            colorSwatch("Warning", color: .orange)
            colorSwatch("Error", color: .red)
            colorSwatch("Info", color: .blue)
            
            Divider()
            
            // Category colors
            colorSwatch("Medication", color: theme.iconColor(for: "medication"))
            colorSwatch("Mood", color: theme.iconColor(for: "mood"))
            colorSwatch("Sleep", color: theme.iconColor(for: "sleep"))
            colorSwatch("Energy", color: theme.iconColor(for: "energy"))
        }
        .padding()
    }
    
    private func colorSwatch(_ name: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
            
            Text(name)
                .font(.callout)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("All Examples") {
    DesignSystemExamples()
}

#Preview("Settings Rows") {
    SettingsRowExample()
        .background(AppTheme.purple.gradient)
}

#Preview("Typography") {
    TypographyExamples()
}

#Preview("Colors") {
    ColorUsageExamples()
}

import SwiftUI

/// Demonstration view showing enhanced Liquid Glass and improved card contrast
struct LiquidGlassShowcaseView: View {
    @ThemeWrapper var theme
    @State private var isEnabled = true
    @State private var selectedPeriod = "weekly"
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Button Styles
                    buttonStylesSection
                    
                    // MARK: - Interactive Cards
                    interactiveCardsSection
                    
                    // MARK: - Controls
                    controlsSection
                    
                    // MARK: - Badges
                    badgesSection
                    
                    // MARK: - Contrast Examples
                    contrastExamplesSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xl)
            }
            .scrollContentBackground(.hidden)
            .themedBackground()
            .navigationTitle("Liquid Glass Showcase")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Enhanced Visual Design")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Liquid Glass effects with improved contrast")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                LiquidGlassBadge(text: "New", icon: "sparkles", theme: theme, prominent: true)
            }
            
            Text("All cards now feature enhanced borders, dual-layer shadows with theme color glow, and frosted glass materials that reflect surrounding colors.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
    
    // MARK: - Button Styles
    
    private var buttonStylesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionTitle(text: "Button Styles", icon: "hand.tap.fill")
            
            VStack(spacing: Spacing.md) {
                Button("Standard Liquid Glass") {
                    showAlert = true
                }
                .liquidGlassButton(theme: theme)
                .frame(maxWidth: .infinity)
                
                Button("Prominent Action") {
                    showAlert = true
                }
                .prominentLiquidGlassButton(theme: theme)
                .frame(maxWidth: .infinity)
                
                Button("Subtle Style") {
                    showAlert = true
                }
                .subtleLiquidGlassButton(theme: theme)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
    
    // MARK: - Interactive Cards
    
    private var interactiveCardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionTitle(text: "Interactive Cards", icon: "rectangle.on.rectangle.angled")
            
            Text("Tap these cards to see the touch-reactive Liquid Glass effect")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            LiquidGlassContainer(spacing: 16, theme: theme) {
                HStack(spacing: Spacing.md) {
                    // Standard card
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.primaryColor)
                        
                        Text("Standard")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.lg)
                    .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
                    
                    // Interactive card
                    Button {
                        HapticFeedback.light.trigger()
                    } label: {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(theme.timelineColor)
                            
                            Text("Interactive")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.lg)
                    }
                    .buttonStyle(.plain)
                    .interactiveCardStyle(theme: theme, cornerRadius: CornerRadius.md)
                }
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
    
    // MARK: - Controls
    
    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionTitle(text: "Liquid Glass Controls", icon: "slider.horizontal.3")
            
            VStack(spacing: Spacing.md) {
                // Toggle
                Toggle("Enable Notifications", isOn: $isEnabled)
                    .toggleStyle(LiquidGlassToggleStyle(theme: theme))
                
                Divider()
                    .overlay(Color.white.opacity(0.1))
                
                // Segmented Picker
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Time Period")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    LiquidGlassSegmentedPicker(
                        items: [
                            ("daily", "Daily", "calendar"),
                            ("weekly", "Weekly", "chart.bar"),
                            ("monthly", "Monthly", "calendar.circle")
                        ],
                        selection: $selectedPeriod,
                        theme: theme
                    )
                }
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
    
    // MARK: - Badges
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionTitle(text: "Liquid Glass Badges", icon: "tag.fill")
            
            HStack(spacing: Spacing.sm) {
                LiquidGlassBadge(text: "New", icon: "sparkles", theme: theme, prominent: true)
                LiquidGlassBadge(text: "Beta", theme: theme, prominent: false)
                LiquidGlassBadge(text: "Updated", icon: "arrow.clockwise", theme: theme, prominent: false)
                LiquidGlassBadge(text: "Pro", icon: "star.fill", theme: theme, prominent: true)
            }
            .padding(.vertical, Spacing.sm)
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
    
    // MARK: - Contrast Examples
    
    private var contrastExamplesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionTitle(text: "Enhanced Contrast & Definition", icon: "eye.fill")
            
            Text("Compare the visual hierarchy and card definition")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            // Example with stats
            HStack(spacing: Spacing.md) {
                statCard(value: "24", label: "Active", icon: "flame.fill", color: .orange)
                statCard(value: "7", label: "Streak", icon: "calendar", color: .green)
                statCard(value: "92%", label: "Score", icon: "star.fill", color: theme.primaryColor)
            }
        }
        .padding(Spacing.xl)
        .cardStyle(theme: theme)
    }
    
    // MARK: - Helper Views
    
    private struct SectionTitle: View {
        let text: String
        let icon: String
        @ThemeWrapper var theme
        
        var body: some View {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(theme.timelineColor)
                
                Text(text)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassShowcaseView()
}

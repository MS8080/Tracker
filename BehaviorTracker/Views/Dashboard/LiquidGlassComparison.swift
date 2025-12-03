import SwiftUI

// MARK: - Before & After Liquid Glass Comparison

struct LiquidGlassComparison: View {
    @ThemeWrapper var theme
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Header
                        headerSection
                        
                        // Comparison 1: Streak Card
                        comparisonSection(
                            title: "Streak Card",
                            description: "Semi-transparent vs True Glass"
                        ) {
                            oldStreakCard
                            newStreakCard
                        }
                        
                        // Comparison 2: Button Card
                        comparisonSection(
                            title: "Interactive Button",
                            description: "Static vs Touch Response"
                        ) {
                            oldButtonCard
                            newButtonCard
                        }
                        
                        // Comparison 3: Icon Card
                        comparisonSection(
                            title: "Icon Cards",
                            description: "Flat vs Frosted Circles"
                        ) {
                            oldIconCard
                            newIconCard
                        }
                        
                        // Feature Checklist
                        featureChecklist
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.xl)
                }
            }
            .navigationTitle("Before & After")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundStyle(theme.primaryColor)
                
                Text("Before & After")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            Text("See the transformation from semi-transparent to true liquid glass")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Comparison Section Builder
    
    private func comparisonSection<Content: View>(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            HStack(spacing: Spacing.md) {
                content()
            }
        }
    }
    
    // MARK: - Old Style Examples (Before)
    
    private var oldStreakCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("BEFORE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("7")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Text("Day streak")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.06))
            )
            .shadow(color: theme.primaryColor.opacity(0.2), radius: 12)
        }
    }
    
    private var oldButtonCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("BEFORE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))
            
            HStack(spacing: Spacing.sm) {
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Summary")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("View")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.06))
            )
            .shadow(color: theme.primaryColor.opacity(0.2), radius: 12)
        }
    }
    
    private var oldIconCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("BEFORE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))
            
            HStack(spacing: Spacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                
                Text("Recently")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.06))
            )
            .shadow(color: theme.primaryColor.opacity(0.2), radius: 12)
        }
    }
    
    // MARK: - New Style Examples (After)
    
    private var newStreakCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("AFTER")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(theme.primaryColor)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("7")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Text("Day streak")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md, interactive: true)
        }
    }
    
    private var newButtonCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("AFTER")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(theme.primaryColor)
            
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Summary")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Interactive")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(Spacing.sm)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md, interactive: true)
        }
    }
    
    private var newIconCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("AFTER")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(theme.primaryColor)
            
            HStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                
                Text("Recently")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .cardStyle(theme: theme, cornerRadius: CornerRadius.md)
        }
    }
    
    // MARK: - Feature Checklist
    
    private var featureChecklist: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What Changed")
                .font(.headline)
                .foregroundStyle(.white)
            
            VStack(spacing: Spacing.sm) {
                featureRow(icon: "checkmark.circle.fill", text: "Real background blur", color: .green)
                featureRow(icon: "checkmark.circle.fill", text: "Touch response animations", color: .green)
                featureRow(icon: "checkmark.circle.fill", text: "Gradient light reflection", color: .green)
                featureRow(icon: "checkmark.circle.fill", text: "Dynamic shadow depth", color: .green)
                featureRow(icon: "checkmark.circle.fill", text: "Frosted icon circles", color: .green)
                featureRow(icon: "checkmark.circle.fill", text: "Theme-colored glass tint", color: .green)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.green.opacity(0.1))
                            .blendMode(.plusLighter)
                    )
            )
        }
    }
    
    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassComparison()
}

import SwiftUI

// MARK: - True Liquid Glass Showcase

struct TrueLiquidGlassShowcase: View {
    @ThemeWrapper var theme
    @State private var selectedCard: Int? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Interactive Cards Demo
                        interactiveCardsSection
                        
                        // Blur Comparison
                        blurComparisonSection
                        
                        // Focusable Cards
                        focusableCardsSection
                        
                        // Compact Style
                        compactStyleSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.xl)
                }
            }
            .navigationTitle("True Liquid Glass")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.yellow)
                
                Text("True Liquid Glass")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            Text("Real blur effects, interactive responses, and dynamic depth")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Interactive Cards Section
    
    private var interactiveCardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Interactive Cards")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Tap and hold to see the press effect")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            HStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "pills.fill")
                        .font(.title)
                        .foregroundStyle(.cyan)
                    
                    Text("Medication")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Interactive glass")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .cardStyle(theme: theme, interactive: true)
                
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    
                    Text("Supplement")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Interactive glass")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .cardStyle(theme: theme, interactive: true)
            }
        }
    }
    
    // MARK: - Blur Comparison Section
    
    private var blurComparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Real Background Blur")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Notice how the gradient shows through with blur")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            ZStack(alignment: .bottomTrailing) {
                // Background with colorful gradient
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        RadialGradient(
                            colors: [
                                .pink.opacity(0.6),
                                .purple.opacity(0.4),
                                .blue.opacity(0.3)
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .frame(height: 200)
                
                // Glass panel on top
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "eye.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                        
                        Text("Blurred Glass")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    
                    Text("Background blurs through")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(Spacing.lg)
                .frame(width: 220)
                .cardStyle(theme: theme)
                .padding(Spacing.md)
            }
        }
    }
    
    // MARK: - Focusable Cards Section
    
    private var focusableCardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Focusable States")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Tap to toggle focus state")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            VStack(spacing: Spacing.md) {
                focusableCard(id: 1, title: "Today", subtitle: "5 entries")
                focusableCard(id: 2, title: "Yesterday", subtitle: "3 entries")
                focusableCard(id: 3, title: "Last Week", subtitle: "12 entries")
            }
        }
    }
    
    private func focusableCard(id: Int, title: String, subtitle: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedCard == id {
                    selectedCard = nil
                } else {
                    selectedCard = id
                }
            }
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: selectedCard == id ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedCard == id ? theme.primaryColor : .white.opacity(0.5))
            }
            .padding(Spacing.lg)
            .focusableCardStyle(theme: theme, isFocused: selectedCard == id)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Compact Style Section
    
    private var compactStyleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Compact List Style")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Lighter glass for lists")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            VStack(spacing: Spacing.sm) {
                compactListItem(icon: "star.fill", title: "Favorites", color: .yellow)
                compactListItem(icon: "clock.fill", title: "Recent", color: .orange)
                compactListItem(icon: "heart.fill", title: "Liked", color: .pink)
                compactListItem(icon: "bookmark.fill", title: "Saved", color: .blue)
            }
        }
    }
    
    private func compactListItem(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .compactCardStyle(theme: theme)
    }
}

// MARK: - Preview

#Preview {
    TrueLiquidGlassShowcase()
}

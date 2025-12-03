import SwiftUI

/// Demo view showing Liquid Glass effects in action
/// Navigate to this view from your app to see all the Liquid Glass examples
struct LiquidGlassDemo: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    @State private var selectedCategory: String?
    @State private var effectTags = ["Focus", "ADHD", "Energy", "Sleep", "Mood"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Your app's themed gradient background
                theme.gradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Section 1: Category Grid
                        sectionHeader("Category Selection Grid")
                        categoryGridSection
                        
                        // Section 2: Effect Tags
                        sectionHeader("Effect Tag Badges")
                        effectTagsSection
                        
                        // Section 3: Glass Buttons
                        sectionHeader("Glass Button Styles")
                        glassButtonsSection
                        
                        // Section 4: Card with Glass
                        sectionHeader("Glass Cards")
                        glassCardsSection
                        
                        // Section 5: List Items with Glass
                        sectionHeader("List Items")
                        glassListSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, 30)
                }
            }
            .navigationTitle("Liquid Glass Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
    }
    
    // MARK: - Category Grid Section
    
    private var categoryGridSection: some View {
        GlassEffectContainer(spacing: 16) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                categoryCard("pills.fill", "Medication", .blue)
                categoryCard("leaf.fill", "Supplement", .green)
                categoryCard("figure.walk", "Activity", .orange)
                categoryCard("eye.fill", "Accommodation", .purple)
            }
        }
    }
    
    private func categoryCard(_ icon: String, _ title: String, _ color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = title
                HapticFeedback.medium.trigger()
            }
            
            // Reset after brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    selectedCategory = nil
                }
            }
        } label: {
            VStack(spacing: 12) {
                // Icon with glass circle background
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(color.opacity(0.3))
                    )
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if selectedCategory == title {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .glassEffect(.regular.tint(color.opacity(0.25)).interactive())
        }
    }
    
    // MARK: - Effect Tags Section
    
    private var effectTagsSection: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your selected effects:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                // Flowing tag layout
                FlowLayout(spacing: 8) {
                    ForEach(effectTags, id: \.self) { tag in
                        effectTagBadge(tag)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .glassEffect(.regular.tint(.white.opacity(0.15)))
        }
    }
    
    private func effectTagBadge(_ tag: String) -> some View {
        Text("#\(tag)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular.tint(tagColor(for: tag).opacity(0.3)))
    }
    
    private func tagColor(for tag: String) -> Color {
        switch tag {
        case "Focus": return .blue
        case "ADHD": return .purple
        case "Energy": return .orange
        case "Sleep": return .indigo
        case "Mood": return .pink
        default: return .gray
        }
    }
    
    // MARK: - Glass Buttons Section
    
    private var glassButtonsSection: some View {
        VStack(spacing: 16) {
            Button("Standard Glass Button") {
                HapticFeedback.light.trigger()
            }
            .buttonStyle(.glass(tint: theme.primaryColor))
            
            Button("Prominent Glass Button") {
                HapticFeedback.medium.trigger()
            }
            .buttonStyle(.glass(tint: theme.primaryColor, prominent: true))
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    HapticFeedback.light.trigger()
                }
                .buttonStyle(.glass(tint: .red))
                
                Button("Confirm") {
                    HapticFeedback.medium.trigger()
                }
                .buttonStyle(.glass(tint: .green, prominent: true))
            }
        }
    }
    
    // MARK: - Glass Cards Section
    
    private var glassCardsSection: some View {
        GlassEffectContainer(spacing: 16) {
            // Streak-style card
            HStack(spacing: Spacing.lg) {
                VStack {
                    Text("7")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 80, height: 80)
                .glassEffect(.regular.tint(.green.opacity(0.3)))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tracking Streak")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Keep it up! You've been tracking consistently.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
            .glassEffect(.regular.tint(.green.opacity(0.2)).interactive())
            
            // Memory-style card
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    
                    Text("One week ago")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                Text("You noted feeling focused and energized after your morning routine.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .glassEffect(.regular.tint(.blue.opacity(0.2)))
        }
    }
    
    // MARK: - Glass List Section
    
    private var glassListSection: some View {
        GlassEffectContainer(spacing: 12) {
            listItem("Adderall XR", "pills.fill", .blue, tags: ["Focus", "ADHD"])
            listItem("Vitamin D", "leaf.fill", .green, tags: ["Energy"])
            listItem("Morning Run", "figure.walk", .orange, tags: ["Exercise", "Mood"])
        }
    }
    
    private func listItem(_ title: String, _ icon: String, _ color: Color, tags: [String]) -> some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(color.opacity(0.15)).interactive())
    }
}

// MARK: - Flow Layout Helper
// Note: FlowLayout is defined in DesignSystem.swift and is used here

// MARK: - Preview

#Preview {
    LiquidGlassDemo()
}

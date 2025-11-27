import SwiftUI

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Loading Skeleton Cards

struct SkeletonCard: View {
    let height: CGFloat
    
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(theme.cardBackground)
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.cardBorderColor, lineWidth: 0.5)
            )
            .shimmering()
    }
}

struct SkeletonDashboardView: View {
    var body: some View {
        VStack(spacing: 10) {
            // Streak card skeleton
            SkeletonCard(height: 100)
            
            // Today summary skeleton
            SkeletonCard(height: 180)
            
            // Recent entries skeleton
            SkeletonCard(height: 200)
            
            // Quick insights skeleton
            SkeletonCard(height: 150)
        }
        .padding()
    }
}

struct SkeletonReportCard: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard(height: 280)
            }
        }
        .padding()
    }
}

struct SkeletonJournalList: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonCard(height: 120)
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Skeleton Dashboard") {
    ZStack {
        AppTheme.purple.gradient
            .ignoresSafeArea()
        
        ScrollView {
            SkeletonDashboardView()
        }
    }
}

#Preview("Skeleton Card") {
    ZStack {
        AppTheme.blue.gradient
            .ignoresSafeArea()
        
        SkeletonCard(height: 150)
            .padding()
    }
}

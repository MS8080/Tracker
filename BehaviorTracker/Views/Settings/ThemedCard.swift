import SwiftUI

/// A reusable themed card container
struct ThemedCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content
    @ThemeWrapper var theme

    init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        useMaterial: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.primaryColor.opacity(0.35), lineWidth: 1.5)
            )
    }
}

#Preview {
    ZStack {
        AppTheme.purple.gradient
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            ThemedCard {
                VStack {
                    Text("Standard Card")
                        .font(.headline)
                    Text("Uses theme colors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            ThemedCard(useMaterial: true) {
                VStack {
                    Text("Material Card")
                        .font(.headline)
                    Text("Uses material background")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

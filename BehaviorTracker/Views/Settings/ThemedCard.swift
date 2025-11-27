import SwiftUI

/// A reusable card container with consistent theming and styling
/// Supports both standard theme-based backgrounds and material backgrounds
///
/// Usage:
/// ```swift
/// ThemedCard {
///     VStack {
///         Text("Hello")
///     }
/// }
///
/// // With material background
/// ThemedCard(useMaterial: true) {
///     VStack {
///         Text("Hello")
///     }
/// }
/// ```
struct ThemedCard<Content: View>: View {
    let cornerRadius: CGFloat
    let useMaterial: Bool
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
        self.useMaterial = useMaterial
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundView)
            .overlay(overlayView)
            .shadow(
                color: useMaterial ? .black.opacity(0.2) : theme.cardShadowColor,
                radius: useMaterial ? 10 : 8,
                y: useMaterial ? 5 : 4
            )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if useMaterial {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.cardBackground)
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                useMaterial ? .white.opacity(0.2) : theme.cardBorderColor,
                lineWidth: useMaterial ? 1 : 0.5
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

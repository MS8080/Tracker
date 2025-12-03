import SwiftUI

// MARK: - Glass Effect Style Configuration

/// Configuration for glass effect appearance
struct GlassEffectStyle {
    var tintColor: Color
    var tintOpacity: Double
    var blurRadius: CGFloat
    var cornerRadius: CGFloat
    var isInteractive: Bool
    
    static let regular = GlassEffectStyle(
        tintColor: .white,
        tintOpacity: 0.1,
        blurRadius: 20,
        cornerRadius: 16,
        isInteractive: false
    )
    
    func tint(_ color: Color) -> GlassEffectStyle {
        var style = self
        style.tintColor = color
        return style
    }
    
    func interactive() -> GlassEffectStyle {
        var style = self
        style.isInteractive = true
        return style
    }
    
    func opacity(_ value: Double) -> GlassEffectStyle {
        var style = self
        style.tintOpacity = value
        return style
    }
}

// MARK: - Glass Effect View Modifier

struct GlassEffectModifier: ViewModifier {
    let style: GlassEffectStyle
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Blur background
                    if #available(iOS 15.0, *) {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                style.tintColor
                                    .opacity(style.tintOpacity)
                            )
                    } else {
                        // Fallback for older iOS versions
                        style.tintColor
                            .opacity(style.tintOpacity * 0.8)
                            .background(.ultraThinMaterial)
                    }
                }
                .cornerRadius(style.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .scaleEffect(isPressed && style.isInteractive ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                style.isInteractive ? 
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
                : nil
            )
    }
}

// MARK: - View Extension

extension View {
    /// Applies a liquid glass effect to the view
    func glassEffect(_ style: GlassEffectStyle = .regular) -> some View {
        self.modifier(GlassEffectModifier(style: style))
    }
}

// MARK: - Glass Effect Container

/// Container that optimizes rendering of multiple glass effect elements
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .drawingGroup() // Optimizes rendering performance
    }
}

// MARK: - Glass Button Styles

struct GlassButtonStyle: ButtonStyle {
    let tintColor: Color
    let isProminent: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .glassEffect(
                .regular
                    .tint(tintColor.opacity(isProminent ? 0.4 : 0.25))
                    .interactive()
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    /// Standard glass button style
    static var glass: GlassButtonStyle {
        GlassButtonStyle(tintColor: .blue, isProminent: false)
    }
    
    /// Prominent glass button style with more emphasis
    static var glassProminent: GlassButtonStyle {
        GlassButtonStyle(tintColor: .blue, isProminent: true)
    }
    
    /// Glass button with custom tint color
    static func glass(tint: Color, prominent: Bool = false) -> GlassButtonStyle {
        GlassButtonStyle(tintColor: tint, isProminent: prominent)
    }
}

// MARK: - Preview

#Preview("Glass Effect Examples") {
    ZStack {
        // Background gradient to show glass effect
        LinearGradient(
            colors: [.purple, .blue, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 30) {
                // Category Grid Example
                Text("Category Selection")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                GlassEffectContainer(spacing: 16) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        CategoryGlassCard(icon: "pills.fill", title: "Medication", color: .blue)
                        CategoryGlassCard(icon: "leaf.fill", title: "Supplement", color: .green)
                        CategoryGlassCard(icon: "figure.walk", title: "Activity", color: .orange)
                        CategoryGlassCard(icon: "eye.fill", title: "Accommodation", color: .purple)
                    }
                }
                .padding(.horizontal)
                
                // Button Styles
                Text("Glass Buttons")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Button("Standard Glass Button") { }
                        .buttonStyle(.glass)
                    
                    Button("Prominent Glass Button") { }
                        .buttonStyle(.glassProminent)
                    
                    Button("Custom Tint Glass") { }
                        .buttonStyle(.glass(tint: .pink, prominent: true))
                }
                .padding(.horizontal)
                
                // Effect Tags
                Text("Effect Tags")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("#Focus")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(.regular.tint(.blue.opacity(0.3)))
                        
                        Text("#ADHD")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(.regular.tint(.purple.opacity(0.3)))
                        
                        Text("#Energy")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(.regular.tint(.orange.opacity(0.3)))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
        }
    }
}

// Helper view for preview
private struct CategoryGlassCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.white)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .glassEffect(.regular.tint(color.opacity(0.25)).interactive())
    }
}

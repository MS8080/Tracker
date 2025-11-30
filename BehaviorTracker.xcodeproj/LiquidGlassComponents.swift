import SwiftUI

// MARK: - Liquid Glass Button Styles

/// Primary Liquid Glass button style - interactive with glow effect
struct LiquidGlassButtonStyle: ButtonStyle {
    let theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(
                ZStack {
                    // Frosted glass base
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.85))
                    
                    // Theme color tint
                    Capsule()
                        .fill(theme.primaryColor.opacity(configuration.isPressed ? 0.4 : 0.25))
                    
                    // Top highlight
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.3 : 0.2),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.4 : 0.25), lineWidth: 1)
            )
            .shadow(
                color: theme.primaryColor.opacity(configuration.isPressed ? 0.4 : 0.3),
                radius: configuration.isPressed ? 16 : 20,
                y: configuration.isPressed ? 4 : 8
            )
            .shadow(
                color: .black.opacity(0.3),
                radius: configuration.isPressed ? 8 : 12,
                y: configuration.isPressed ? 4 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Prominent Liquid Glass button style - more emphasized
struct ProminentLiquidGlassButtonStyle: ButtonStyle {
    let theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.lg)
            .background(
                ZStack {
                    // Stronger glass effect
                    Capsule()
                        .fill(.thinMaterial.opacity(0.9))
                    
                    // More vibrant theme tint
                    Capsule()
                        .fill(theme.primaryColor.opacity(configuration.isPressed ? 0.6 : 0.45))
                    
                    // Animated highlight
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.4 : 0.3),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(configuration.isPressed ? 0.6 : 0.4),
                                theme.primaryColor.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: theme.primaryColor.opacity(configuration.isPressed ? 0.5 : 0.4),
                radius: configuration.isPressed ? 20 : 28,
                y: configuration.isPressed ? 6 : 10
            )
            .shadow(
                color: .black.opacity(0.4),
                radius: configuration.isPressed ? 10 : 16,
                y: configuration.isPressed ? 6 : 10
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Subtle Liquid Glass button style - minimal appearance
struct SubtleLiquidGlassButtonStyle: ButtonStyle {
    let theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.6))
                    
                    Capsule()
                        .fill(theme.primaryColor.opacity(configuration.isPressed ? 0.2 : 0.12))
                }
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.25 : 0.15), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass Toggle Style

/// Custom toggle style with Liquid Glass aesthetic
struct LiquidGlassToggleStyle: ToggleStyle {
    let theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Spacing.md) {
            configuration.label
                .font(.body)
                .foregroundStyle(.white)
            
            Spacer()
            
            // Custom toggle switch
            ZStack {
                // Background track
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .frame(width: 50, height: 30)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                
                // Filled track when on
                if configuration.isOn {
                    Capsule()
                        .fill(theme.primaryColor.opacity(0.3))
                        .frame(width: 50, height: 30)
                }
                
                // Thumb
                Circle()
                    .fill(.thinMaterial)
                    .overlay(
                        Circle()
                            .fill(
                                configuration.isOn ?
                                theme.primaryColor.opacity(0.4) :
                                Color.white.opacity(0.1)
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Liquid Glass Segmented Picker

/// Segmented picker with Liquid Glass styling
struct LiquidGlassSegmentedPicker<T: Hashable>: View {
    let items: [(T, String, String?)] // (value, label, iconName)
    @Binding var selection: T
    let theme: AppTheme
    
    init(items: [(T, String, String?)], selection: Binding<T>, theme: AppTheme) {
        self.items = items
        self._selection = selection
        self.theme = theme
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                segmentButton(item: item)
            }
        }
        .padding(4)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.6))
                
                Capsule()
                    .fill(Color.white.opacity(0.05))
            }
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    private func segmentButton(item: (T, String, String?)) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = item.0
            }
        } label: {
            HStack(spacing: 6) {
                if let iconName = item.2 {
                    Image(systemName: iconName)
                        .font(.subheadline)
                }
                Text(item.1)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(selection == item.0 ? .white : .white.opacity(0.6))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                ZStack {
                    if selection == item.0 {
                        Capsule()
                            .fill(.thinMaterial.opacity(0.9))
                        
                        Capsule()
                            .fill(theme.primaryColor.opacity(0.3))
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        selection == item.0 ?
                        Color.white.opacity(0.3) :
                        Color.clear,
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: selection == item.0 ? theme.primaryColor.opacity(0.3) : .clear,
                radius: 8,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Liquid Glass Badge

/// Badge component with Liquid Glass effect
struct LiquidGlassBadge: View {
    let text: String
    let icon: String?
    let theme: AppTheme
    let prominent: Bool
    
    init(text: String, icon: String? = nil, theme: AppTheme, prominent: Bool = false) {
        self.text = text
        self.icon = icon
        self.theme = theme
        self.prominent = prominent
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial.opacity(prominent ? 0.8 : 0.6))
                
                Capsule()
                    .fill(theme.primaryColor.opacity(prominent ? 0.35 : 0.2))
                
                if prominent {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(prominent ? 0.3 : 0.2), lineWidth: 0.5)
        )
        .shadow(
            color: prominent ? theme.primaryColor.opacity(0.25) : .clear,
            radius: 8,
            y: 2
        )
    }
}

// MARK: - Liquid Glass Container

/// Container that groups multiple glass elements with unified effects
struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let theme: AppTheme
    let content: Content
    
    init(spacing: CGFloat = 20, theme: AppTheme, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.theme = theme
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                // Subtle unified glow behind all elements
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(theme.primaryColor.opacity(0.05))
                    .blur(radius: 20)
                    .padding(-spacing)
            )
    }
}

// MARK: - View Extensions for Liquid Glass Styles

extension View {
    /// Apply Liquid Glass button style
    func liquidGlassButton(theme: AppTheme) -> some View {
        self.buttonStyle(LiquidGlassButtonStyle(theme: theme))
    }
    
    /// Apply prominent Liquid Glass button style
    func prominentLiquidGlassButton(theme: AppTheme) -> some View {
        self.buttonStyle(ProminentLiquidGlassButtonStyle(theme: theme))
    }
    
    /// Apply subtle Liquid Glass button style
    func subtleLiquidGlassButton(theme: AppTheme) -> some View {
        self.buttonStyle(SubtleLiquidGlassButtonStyle(theme: theme))
    }
}

// MARK: - Example Usage Documentation

/*
 EXAMPLE USAGE:
 
 // Liquid Glass Button
 Button("Tap Me") {
     // Action
 }
 .liquidGlassButton(theme: theme)
 
 // Prominent Button
 Button("Primary Action") {
     // Action
 }
 .prominentLiquidGlassButton(theme: theme)
 
 // Segmented Picker
 LiquidGlassSegmentedPicker(
     items: [
         ("daily", "Daily", "calendar"),
         ("weekly", "Weekly", "calendar.badge.clock"),
         ("monthly", "Monthly", "calendar.circle")
     ],
     selection: $selectedPeriod,
     theme: theme
 )
 
 // Toggle
 Toggle("Enable Notifications", isOn: $isEnabled)
     .toggleStyle(LiquidGlassToggleStyle(theme: theme))
 
 // Badge
 LiquidGlassBadge(text: "New", icon: "star.fill", theme: theme, prominent: true)
 
 // Container for unified effects
 LiquidGlassContainer(spacing: 20, theme: theme) {
     HStack(spacing: 20) {
         cardView1
         cardView2
     }
 }
 */

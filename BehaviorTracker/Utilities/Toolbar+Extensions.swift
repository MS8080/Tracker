import SwiftUI

// MARK: - Toolbar Extensions

extension ToolbarContent {
    @ToolbarContentBuilder
    func hideSharedBackground() -> some ToolbarContent {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}

// MARK: - Glass Button Style

extension View {
    @ViewBuilder
    func glassButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self
        }
    }

    @ViewBuilder
    func glassProminentButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self
        }
    }

    @ViewBuilder
    func nativeGlassEffect() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect()
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
        }
    }
}

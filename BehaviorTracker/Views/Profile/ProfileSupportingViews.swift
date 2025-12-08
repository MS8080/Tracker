import SwiftUI

// MARK: - Disable Glass Effect Modifier

/// Disables the automatic Liquid Glass effect on iOS 26+ for views that shouldn't have it
struct DisableGlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.identity, in: Circle())
        } else {
            content
        }
    }
}

// MARK: - Profile Toolbar Controls

struct FontSizeToolbarControl: View {
    @Binding var fontSizeScale: Double

    var body: some View {
        ControlGroup {
            Button {
                if fontSizeScale > 0.8 {
                    fontSizeScale -= 0.1
                    HapticFeedback.light.trigger()
                }
            } label: {
                Text("A")
                    .font(.system(size: 14, weight: .medium))
            }
            .disabled(fontSizeScale <= 0.8)

            Button {
                if fontSizeScale < 1.4 {
                    fontSizeScale += 0.1
                    HapticFeedback.light.trigger()
                }
            } label: {
                Text("A")
                    .font(.system(size: 18, weight: .medium))
            }
            .disabled(fontSizeScale >= 1.4)
        }
    }
}

struct BlueLightFilterToolbarControl: View {
    @Binding var blueLightFilterEnabled: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                blueLightFilterEnabled.toggle()
            }
            HapticFeedback.light.trigger()
        } label: {
            Image(systemName: blueLightFilterEnabled ? "sun.max.fill" : "moon.fill")
        }
    }
}

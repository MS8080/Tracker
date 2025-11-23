import SwiftUI
#if os(iOS)
import UIKit
#endif

enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection

    func trigger() {
        #if os(iOS)
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #else
        // Haptic feedback is not available on macOS
        #endif
    }
}

struct HapticButton<Label: View>: View {
    let feedback: HapticFeedback
    let action: () -> Void
    let label: () -> Label

    init(
        feedback: HapticFeedback = .light,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.feedback = feedback
        self.action = action
        self.label = label
    }

    var body: some View {
        Button {
            feedback.trigger()
            action()
        } label: {
            label()
        }
    }
}

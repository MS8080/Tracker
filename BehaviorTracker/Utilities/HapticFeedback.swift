import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Provides haptic feedback for user interactions.
///
/// Wrapper around UIKit's haptic feedback generators with a simple, consistent API.
/// On macOS, haptic feedback calls are silently ignored.
///
/// ## Usage
/// ```swift
/// // For button taps
/// HapticFeedback.medium.trigger()
///
/// // For successful operations
/// HapticFeedback.success.trigger()
///
/// // For selections/toggles
/// HapticFeedback.selection.trigger()
/// ```
///
/// ## Feedback Types
/// - `light`: Subtle tap for minor interactions
/// - `medium`: Standard tap for button presses
/// - `heavy`: Strong tap for significant actions
/// - `success`: Positive confirmation (e.g., save completed)
/// - `warning`: Alert feedback (e.g., destructive action confirmation)
/// - `error`: Failure notification
/// - `selection`: Subtle tick for toggles and selections
enum HapticFeedback {
    /// Subtle impact for minor interactions
    case light
    /// Standard impact for button presses
    case medium
    /// Strong impact for significant actions
    case heavy
    /// Positive notification feedback
    case success
    /// Alert/warning notification feedback
    case warning
    /// Error notification feedback
    case error
    /// Subtle selection change feedback
    case selection

    /// Triggers the haptic feedback. No-op on macOS.
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

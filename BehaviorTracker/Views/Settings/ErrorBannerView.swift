import SwiftUI

/// A reusable error banner component with optional recovery actions
struct ErrorBannerView: View {
    let title: String
    let message: String
    let style: ErrorStyle
    let primaryAction: ErrorAction?
    let secondaryAction: ErrorAction?
    let onDismiss: (() -> Void)?

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    struct ErrorAction {
        let title: String
        let icon: String?
        let action: () -> Void

        init(title: String, icon: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.action = action
        }
    }

    enum ErrorStyle {
        case error
        case warning
        case info

        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    init(
        title: String,
        message: String,
        style: ErrorStyle = .error,
        primaryAction: ErrorAction? = nil,
        secondaryAction: ErrorAction? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Icon
                Image(systemName: style.icon)
                    .font(.title2)
                    .foregroundStyle(style.color)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Title
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    // Message
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Dismiss button
                if let onDismiss = onDismiss {
                    Button {
                        HapticFeedback.light.trigger()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .contentShape(Circle())
                    }
                }
            }

            // Action buttons
            if primaryAction != nil || secondaryAction != nil {
                HStack(spacing: Spacing.sm) {
                    if let primary = primaryAction {
                        Button {
                            HapticFeedback.medium.trigger()
                            primary.action()
                        } label: {
                            HStack(spacing: 4) {
                                if let icon = primary.icon {
                                    Image(systemName: icon)
                                        .font(.caption)
                                }
                                Text(primary.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(style.color, in: Capsule())
                        }
                    }

                    if let secondary = secondaryAction {
                        Button {
                            HapticFeedback.light.trigger()
                            secondary.action()
                        } label: {
                            HStack(spacing: 4) {
                                if let icon = secondary.icon {
                                    Image(systemName: icon)
                                        .font(.caption)
                                }
                                Text(secondary.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(style.color)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(style.color.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(style.color.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(style.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Convenience initializers for common error types

extension ErrorBannerView {
    /// Network error with retry action
    static func networkError(
        message: String = "Please check your internet connection and try again.",
        onRetry: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) -> ErrorBannerView {
        ErrorBannerView(
            title: "Connection Error",
            message: message,
            style: .error,
            primaryAction: ErrorAction(title: "Retry", icon: "arrow.clockwise", action: onRetry),
            onDismiss: onDismiss
        )
    }

    /// API key missing error with settings action
    static func apiKeyMissing(
        service: String,
        onOpenSettings: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) -> ErrorBannerView {
        ErrorBannerView(
            title: "\(service) Not Configured",
            message: "Add your API key in settings to enable AI features.",
            style: .warning,
            primaryAction: ErrorAction(title: "Open Settings", icon: "gear", action: onOpenSettings),
            onDismiss: onDismiss
        )
    }

    /// Permission denied error with settings action
    static func permissionDenied(
        feature: String,
        onOpenSettings: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) -> ErrorBannerView {
        ErrorBannerView(
            title: "\(feature) Access Denied",
            message: "Enable access in Settings to use this feature.",
            style: .warning,
            primaryAction: ErrorAction(title: "Open Settings", icon: "gear", action: onOpenSettings),
            secondaryAction: ErrorAction(title: "Not Now", action: onDismiss ?? {}),
            onDismiss: nil
        )
    }

    /// Save failed error with retry
    static func saveFailed(
        onRetry: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) -> ErrorBannerView {
        ErrorBannerView(
            title: "Save Failed",
            message: "Your changes couldn't be saved. Please try again.",
            style: .error,
            primaryAction: ErrorAction(title: "Try Again", icon: "arrow.clockwise", action: onRetry),
            onDismiss: onDismiss
        )
    }

    /// Generic info banner
    static func info(
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> ErrorBannerView {
        ErrorBannerView(
            title: title,
            message: message,
            style: .info,
            primaryAction: actionTitle != nil && action != nil
                ? ErrorAction(title: actionTitle!, action: action!)
                : nil,
            onDismiss: onDismiss
        )
    }
}

#Preview("Error Banner") {
    VStack(spacing: 16) {
        ErrorBannerView(
            title: "Analysis Failed",
            message: "Unable to analyze your journal entry. The AI service is temporarily unavailable.",
            style: .error,
            primaryAction: .init(title: "Retry", icon: "arrow.clockwise", action: {}),
            secondaryAction: .init(title: "Learn More", action: {}),
            onDismiss: {}
        )

        ErrorBannerView.networkError(onRetry: {}, onDismiss: {})

        ErrorBannerView.apiKeyMissing(service: "Gemini AI", onOpenSettings: {})

        ErrorBannerView(
            title: "Demo Mode Active",
            message: "You're viewing sample data. Create an account to save your entries.",
            style: .info,
            primaryAction: .init(title: "Get Started", action: {}),
            onDismiss: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

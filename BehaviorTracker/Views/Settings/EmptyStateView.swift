import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated icon
            if #available(iOS 18.0, *) {
                Image(systemName: icon)
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primaryColor.opacity(0.7), theme.primaryColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce.up.byLayer, options: .repeating.speed(0.3))
            } else {
                Image(systemName: icon)
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primaryColor.opacity(0.7), theme.primaryColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: theme.primaryColor.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        AppTheme.purple.gradient
            .ignoresSafeArea()
        
        EmptyStateView(
            icon: "tray.fill",
            title: "No Entries Yet",
            message: "Start tracking your patterns by logging your first entry",
            actionTitle: "Log First Entry",
            action: { print("Action tapped") }
        )
    }
}

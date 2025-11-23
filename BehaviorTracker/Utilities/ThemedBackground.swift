import SwiftUI

struct ThemedBackgroundModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            content
        }
    }
}

extension View {
    func themedBackground(theme: AppTheme) -> some View {
        modifier(ThemedBackgroundModifier(theme: theme))
    }
}

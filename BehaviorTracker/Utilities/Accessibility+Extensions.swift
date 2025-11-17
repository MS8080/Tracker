import SwiftUI

extension View {
    func accessibilityLabel(_ label: String, hint: String?) -> some View {
        Group {
            if let hint = hint {
                self
                    .accessibilityLabel(Text(label))
                    .accessibilityHint(hint)
            } else {
                self
                    .accessibilityLabel(Text(label))
            }
        }
    }
}

extension Text {
    func dynamicTypeSize() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

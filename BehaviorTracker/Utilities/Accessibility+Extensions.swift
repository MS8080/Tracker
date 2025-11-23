import SwiftUI
#if os(iOS)
import UIKit
public typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
public typealias PlatformColor = NSColor

extension NSColor {
    static var systemGroupedBackground: NSColor {
        return NSColor.windowBackgroundColor
    }
    static var systemBackground: NSColor {
        return NSColor.windowBackgroundColor
    }
    static var systemGray6: NSColor {
        return NSColor.controlBackgroundColor
    }
    static var secondarySystemGroupedBackground: NSColor {
        return NSColor.controlBackgroundColor
    }
}
#endif

extension View {
    /// Cross-platform navigation bar title display mode
    @ViewBuilder
    func navigationBarTitleDisplayModeInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Cross-platform navigation bar title display mode
    @ViewBuilder
    func navigationBarTitleDisplayModeLarge() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

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

import SwiftUI

/// A property wrapper that provides easy access to the current app theme
/// Eliminates the need to repeatedly write AppStorage and theme conversion logic
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     @ThemeWrapper var theme
///
///     var body: some View {
///         Text("Hello")
///             .foregroundStyle(theme.primaryColor)
///     }
/// }
/// ```
@propertyWrapper
struct ThemeWrapper: DynamicProperty {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    
    var wrappedValue: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var projectedValue: Binding<String> {
        $selectedThemeRaw
    }
}

import SwiftUI

struct ThemePickerView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var selectedTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRaw) ?? .purple }
        set { selectedThemeRaw = newValue.rawValue }
    }

    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    ThemeRow(theme: theme, isSelected: selectedTheme == theme)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTheme = theme
                            }
                        }
                }
            } header: {
                Text("Choose Your Background Theme")
            } footer: {
                Text("The theme will be applied throughout the app")
            }
        }
        .navigationTitle("Themes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(theme.rawValue)
                    .font(.headline)

                Text("Tap to apply")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ThemePickerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThemePickerView()
        }
    }
}

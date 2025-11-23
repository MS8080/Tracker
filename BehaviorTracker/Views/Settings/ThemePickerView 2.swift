import SwiftUI

struct ThemePickerView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button {
                    selectedThemeRaw = theme.rawValue
                } label: {
                    HStack {
                        // Theme preview
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.gradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                        
                        Text(theme.rawValue)
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if selectedTheme == theme {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Background Theme")
        .navigationBarTitleDisplayModeInline()
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
    }
}

import SwiftUI

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel 
    @State private var selectedFormat: ExportFormat = .json
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var buttonPressed = false

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue
    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hero icon
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(theme.primaryColor)
                .padding(.top, 32)

            Text("Export Your Data")
                .font(.title2)
                .fontWeight(.bold)

            Text("Choose a format to export all your behavioral pattern data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Format picker - now themed
            Picker("Format", selection: $selectedFormat) {
                Text("JSON").tag(ExportFormat.json)
                Text("CSV").tag(ExportFormat.csv)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 32)
            .tint(theme.primaryColor)

            // Format info card - improved depth and layering
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: selectedFormat == .json ? "doc.text" : "tablecells")
                        .foregroundStyle(theme.primaryColor)
                        .imageScale(.large)
                    Text(selectedFormat == .json ? "JSON Format" : "CSV Format")
                        .font(.headline)
                }

                Text(selectedFormat == .json ?
                    "Structured data format, ideal for importing into other apps or backup purposes." :
                    "Spreadsheet-compatible format, can be opened in Excel, Numbers, or Google Sheets.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackground)
            )
            .shadow(color: theme.cardShadowColor, radius: 6, y: 3)
            .padding(.horizontal, 32)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedFormat)

            Spacer()

            // Export button - themed with press animation
            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    buttonPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        buttonPressed = false
                    }
                    exportData()
                }
            } label: {
                HStack(spacing: 8) {
                    if isExporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isExporting ? "Exporting..." : "Export Data")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.primaryColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: theme.primaryColor.opacity(0.3), radius: 8, y: 4)
            }
            .scaleEffect(buttonPressed ? 0.95 : 1.0)
            .disabled(isExporting)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportData() {
        isExporting = true
        
        // Simulate brief export process with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let data: String
            let filename: String

            switch selectedFormat {
            case .json:
                data = viewModel.exportDataAsJSON()
                filename = "behavior_tracker_export_\(formattedDate()).json"
            case .csv:
                data = viewModel.exportDataAsCSV()
                filename = "behavior_tracker_export_\(formattedDate()).csv"
            }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            do {
                try data.write(to: tempURL, atomically: true, encoding: .utf8)
                exportedFileURL = tempURL
                
                withAnimation {
                    isExporting = false
                }
                
                // Small delay for smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingShareSheet = true
                }
            } catch {
                print("Error exporting data: \(error.localizedDescription)")
                withAnimation {
                    isExporting = false
                }
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

enum ExportFormat {
    case json
    case csv
}

#if os(iOS)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
import AppKit

struct ShareSheet: View {
    let items: [Any]

    var body: some View {
        Button("Share") {
            if let url = items.first as? URL {
                let picker = NSSharingServicePicker(items: [url])
                if let window = NSApplication.shared.keyWindow {
                    picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
                }
            }
        }
    }
}
#endif

#Preview {
    ExportDataView(viewModel: SettingsViewModel())
}

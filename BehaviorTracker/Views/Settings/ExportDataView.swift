import SwiftUI

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedFormat: ExportFormat = .json
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 32)

                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose a format to export all your behavioral pattern data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Picker("Format", selection: $selectedFormat) {
                    Text("JSON").tag(ExportFormat.json)
                    Text("CSV").tag(ExportFormat.csv)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: selectedFormat == .json ? "doc.text" : "tablecells")
                            .foregroundStyle(.blue)
                        Text(selectedFormat == .json ? "JSON Format" : "CSV Format")
                            .font(.headline)
                    }

                    Text(selectedFormat == .json ?
                        "Structured data format, ideal for importing into other apps or backup purposes." :
                        "Spreadsheet-compatible format, can be opened in Excel, Numbers, or Google Sheets.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportData() {
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
            showingShareSheet = true
        } catch {
            print("Error exporting data: \(error.localizedDescription)")
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportDataView(viewModel: SettingsViewModel())
}

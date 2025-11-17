import SwiftUI

struct QuickLogView: View {
    @EnvironmentObject var connectivity: WatchConnectivityService
    @State private var selectedPattern: String?
    @State private var selectedIntensity: Int = 3
    @State private var showingIntensityPicker = false
    @State private var showingConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Quick Log")
                    .font(.title3)
                    .fontWeight(.bold)

                if connectivity.favoritePatterns.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.largeTitle)
                            .foregroundColor(.gray)

                        Text("No favorites yet")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Add favorites on iPhone")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    // Favorite Patterns
                    ForEach(connectivity.favoritePatterns, id: \.self) { pattern in
                        Button(action: {
                            selectedPattern = pattern
                            showingIntensityPicker = true
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 8, height: 8)

                                Text(pattern)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Log \(pattern)")
                    }
                }

                if !connectivity.isReachable {
                    Text("Connect iPhone to log")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingIntensityPicker) {
            IntensityPickerView(
                patternName: selectedPattern ?? "",
                selectedIntensity: $selectedIntensity,
                onLog: {
                    logPattern()
                }
            )
        }
        .alert("Logged!", isPresented: $showingConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(selectedPattern ?? "") has been logged")
        }
    }

    private func logPattern() {
        guard let pattern = selectedPattern else { return }

        connectivity.logPattern(
            patternType: pattern,
            intensity: selectedIntensity,
            notes: nil
        )

        showingIntensityPicker = false
        showingConfirmation = true
        selectedPattern = nil
    }
}

struct IntensityPickerView: View {
    let patternName: String
    @Binding var selectedIntensity: Int
    let onLog: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(patternName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("Intensity")
                .font(.caption)
                .foregroundColor(.secondary)

            // Intensity Picker
            Picker("Intensity", selection: $selectedIntensity) {
                Text("1 - Low").tag(1)
                Text("2").tag(2)
                Text("3 - Medium").tag(3)
                Text("4").tag(4)
                Text("5 - High").tag(5)
            }
            .labelsHidden()
            .accessibilityLabel("Select intensity level")

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Log") {
                    onLog()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .padding()
    }
}

#Preview {
    QuickLogView()
        .environmentObject(WatchConnectivityService.shared)
}

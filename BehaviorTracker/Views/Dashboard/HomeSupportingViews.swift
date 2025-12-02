import SwiftUI

// MARK: - Profile Button

struct ProfileButton: View {
    @Binding var showingProfile: Bool
    #if os(iOS)
    @State private var profileImage: UIImage?
    #elseif os(macOS)
    @State private var profileImage: NSImage?
    #endif

    @ThemeWrapper var theme

    var body: some View {
        Button {
            showingProfile = true
        } label: {
            if let profileImage = profileImage {
                #if os(iOS)
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                #elseif os(macOS)
                Image(nsImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                #endif
            } else {
                Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .task {
            await loadProfileImageAsync()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileUpdated)) { _ in
            Task {
                await loadProfileImageAsync()
            }
        }
    }

    private func loadProfileImageAsync() async {
        let image = await Task.detached(priority: .userInitiated) {
            DataController.shared.getCurrentUserProfile()?.profileImage
        }.value

        await MainActor.run {
            profileImage = image
        }
    }
}

// MARK: - Day Slideshow View

struct DaySlideshowView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HomeViewModel

    @ThemeWrapper var theme

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Day Summary")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding()

                if viewModel.isGeneratingSlides {
                    Spacer()
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)

                        Text("Generating summary...")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                } else if let error = viewModel.slidesError {
                    Spacer()
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                await viewModel.generateAISlides()
                            }
                        } label: {
                            Text("Retry")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.15))
                                )
                        }
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else if !viewModel.todaySlides.isEmpty {
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            ForEach(Array(viewModel.todaySlides.enumerated()), id: \.element.id) { index, slide in
                                insightRow(slide, index: index)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .task {
            if viewModel.todaySlides.isEmpty && !viewModel.isGeneratingSlides {
                await viewModel.generateAISlides()
            }
        }
    }

    private func insightRow(_ slide: DaySummarySlide, index: Int) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Icon with number badge
            ZStack(alignment: .topTrailing) {
                Image(systemName: slide.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(slide.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(slide.color.opacity(0.15))
                    )

                // Number badge
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(
                        Circle()
                            .fill(slide.color)
                    )
                    .offset(x: 4, y: -4)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(slide.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.95))

                Text(slide.detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Previews

#Preview("ProfileButton") {
    ProfileButton(showingProfile: .constant(false))
        .padding()
        .background(Color.blue)
}

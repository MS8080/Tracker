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
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
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

    @State private var headerOpacity: Double = 0
    @State private var visibleSlides: Set<Int> = []
    @State private var footerOpacity: Double = 0

    @ThemeWrapper var theme

    // Softer, warmer pastel colors
    private func warmColor(for color: Color) -> Color {
        switch color {
        case .blue: return Color(red: 0.55, green: 0.70, blue: 0.85)
        case .purple: return Color(red: 0.72, green: 0.60, blue: 0.82)
        case .orange: return Color(red: 0.92, green: 0.72, blue: 0.55)
        case .green: return Color(red: 0.60, green: 0.78, blue: 0.65)
        case .cyan: return Color(red: 0.55, green: 0.78, blue: 0.82)
        case .gray: return Color(red: 0.70, green: 0.70, blue: 0.72)
        default: return color.opacity(0.85)
        }
    }

    var body: some View {
        ZStack {
            theme.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button row
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                if viewModel.isGeneratingSlides {
                    Spacer()
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)

                        Text("Taking a moment to gather my thoughts...")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                } else if let error = viewModel.slidesError {
                    Spacer()
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "heart.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.4))

                        Text(error)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)

                        // Only show retry if it's a real error, not empty state
                        if error.contains("error") || error.contains("Error") || error.contains("failed") {
                            Button {
                                Task {
                                    await viewModel.generateAISlides()
                                }
                            } label: {
                                Text("Try Again")
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
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else if !viewModel.todaySlides.isEmpty {
                    ScrollView {
                        VStack(spacing: Spacing.xxl) {
                            // Warm, personal header
                            VStack(spacing: Spacing.sm) {
                                Text("I've been with you today\(viewModel.userFirstName.map { ", \($0)" } ?? "").")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.95))

                                Text("Here's what I noticed:")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .multilineTextAlignment(.center)
                            .padding(.top, Spacing.lg)
                            .opacity(headerOpacity)

                            // Insight cards with more breathing room
                            VStack(spacing: Spacing.xxl) {
                                ForEach(Array(viewModel.todaySlides.enumerated()), id: \.element.id) { index, slide in
                                    insightRow(slide, index: index)
                                        .opacity(visibleSlides.contains(index) ? 1 : 0)
                                        .offset(y: visibleSlides.contains(index) ? 0 : 20)
                                }
                            }

                            // Supportive footer
                            VStack(spacing: Spacing.md) {
                                Divider()
                                    .background(.white.opacity(0.2))
                                    .padding(.horizontal, Spacing.xxl)

                                VStack(spacing: Spacing.sm) {
                                    Text("Everything's recorded and safe here.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))

                                    Text("You don't have to hold it all anymore.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.6))

                                    Text("I've got you covered.")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white.opacity(0.85))
                                        .padding(.top, Spacing.xs)
                                }
                                .multilineTextAlignment(.center)
                                .padding(.vertical, Spacing.xl)
                            }
                            .opacity(footerOpacity)
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .task {
            // Trigger haptic on open
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            #endif

            if viewModel.todaySlides.isEmpty && !viewModel.isGeneratingSlides {
                await viewModel.generateAISlides()
            }
        }
        .onChange(of: viewModel.todaySlides) { _, slides in
            animateContentAppearance(slideCount: slides.count)
        }
        .onAppear {
            if !viewModel.todaySlides.isEmpty {
                animateContentAppearance(slideCount: viewModel.todaySlides.count)
            }
        }
    }

    private func animateContentAppearance(slideCount: Int) {
        // Fade in header first
        withAnimation(.easeOut(duration: 0.5)) {
            headerOpacity = 1
        }

        // Stagger slide appearances
        for index in 0..<slideCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(index) * 0.15) {
                withAnimation(.easeOut(duration: 0.4)) {
                    _ = visibleSlides.insert(index)
                }
            }
        }

        // Fade in footer after all slides
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(slideCount) * 0.15 + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                footerOpacity = 1
            }
        }
    }

    private func insightRow(_ slide: DaySummarySlide, index: Int) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Icon with softer, warmer colors
            Image(systemName: slide.icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(warmColor(for: slide.color))
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(warmColor(for: slide.color).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(slide.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.95))

                Text(slide.detail)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Previews

#Preview("ProfileButton") {
    ProfileButton(showingProfile: .constant(false))
        .padding()
        .background(Color.blue)
}

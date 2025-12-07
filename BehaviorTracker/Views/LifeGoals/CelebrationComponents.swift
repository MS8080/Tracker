import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Celebration Sound Player

final class CelebrationSoundPlayer {
    static let shared = CelebrationSoundPlayer()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func playSuccess() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1407)
        #endif
    }
}

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    let itemTitle: String
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var showContent = false

    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiView(piece: piece)
            }

            if showContent {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 10)

                    Text("You got it!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(itemTitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .padding(Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.5), .pink.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
        .onAppear {
            generateConfetti()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }

    private func generateConfetti() {
        let colors: [Color] = [.yellow, .pink, .orange, .green, .blue, .purple, .red]
        for i in 0..<50 {
            confettiPieces.append(ConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .yellow,
                startX: CGFloat.random(in: 0...1),
                startY: -0.1,
                endX: CGFloat.random(in: -0.3...1.3),
                endY: CGFloat.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...720),
                delay: Double.random(in: 0...0.5),
                size: CGFloat.random(in: 6...12)
            ))
        }
    }
}

// MARK: - Confetti Piece Model

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let startX, startY, endX, endY: CGFloat
    let rotation, delay: Double
    let size: CGFloat
}

// MARK: - Confetti View

struct ConfettiView: View {
    let piece: ConfettiPiece
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2)
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size * 1.5)
                .position(
                    x: geometry.size.width * (animate ? piece.endX : piece.startX),
                    y: geometry.size.height * (animate ? piece.endY : piece.startY)
                )
                .rotationEffect(.degrees(animate ? piece.rotation : 0))
                .opacity(animate ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 2.5).delay(piece.delay)) {
                        animate = true
                    }
                }
        }
    }
}

import AVFoundation
import Foundation

class TextToSpeechService: NSObject, ObservableObject {
    static let shared = TextToSpeechService()

    @Published var isSpeaking: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentRate: Float = AVSpeechUtteranceDefaultSpeechRate
    @Published var currentVoice: AVSpeechSynthesisVoice?

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?

    override init() {
        super.init()
        synthesizer.delegate = self

        // Set default voice to a high-quality English voice
        if let defaultVoice = AVSpeechSynthesisVoice(language: "en-US") {
            currentVoice = defaultVoice
        }
    }

    // MARK: - Speech Control

    func speak(text: String, rate: Float? = nil, pitch: Float = 1.0, volume: Float = 1.0) {
        // Stop any current speech
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate ?? currentRate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume

        if let voice = currentVoice {
            utterance.voice = voice
        }

        currentUtterance = utterance

        // Configure audio session for accessibility
        configureAudioSession()

        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    func speakJournalEntry(_ entry: JournalEntry, includeTitle: Bool = true) {
        var textToSpeak = ""

        if includeTitle, let title = entry.title, !title.isEmpty {
            textToSpeak = "Title: \(title). "
        }

        textToSpeak += entry.content

        // Add mood context if available
        if entry.mood > 0 {
            let moodDescription = getMoodDescription(for: entry.mood)
            textToSpeak += ". Mood recorded as \(moodDescription)"
        }

        speak(text: textToSpeak)
    }

    func pause() {
        guard isSpeaking && !isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentUtterance = nil
    }

    // MARK: - Configuration

    func setRate(_ rate: Float) {
        currentRate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, rate))
    }

    func setVoice(_ voice: AVSpeechSynthesisVoice) {
        currentVoice = voice
    }

    func getAvailableVoices(language: String = "en") -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(language) }
    }

    // MARK: - Helpers

    private func configureAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
        }
        #endif
        // macOS doesn't require AVAudioSession configuration
    }

    private func getMoodDescription(for mood: Int16) -> String {
        switch mood {
        case 1: return "very low"
        case 2: return "low"
        case 3: return "neutral"
        case 4: return "good"
        case 5: return "very good"
        default: return "unspecified"
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentUtterance = nil
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentUtterance = nil
        }
    }
}

import Foundation
import AVFoundation
import Combine

class AudioRecordingService: NSObject, ObservableObject {
    static let shared = AudioRecordingService()

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var playbackTime: TimeInterval = 0
    @Published var playbackDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var hasPermission = false
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    private var levelTimer: Timer?

    private let voiceNotesDirectory: URL

    override init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        voiceNotesDirectory = documentsPath.appendingPathComponent("VoiceNotes")

        super.init()

        createVoiceNotesDirectoryIfNeeded()
        checkPermission()
    }

    private func createVoiceNotesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: voiceNotesDirectory.path) {
            try? FileManager.default.createDirectory(at: voiceNotesDirectory, withIntermediateDirectories: true)
        }
    }

    func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
        case .undetermined:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
    }

    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() -> String? {
        guard hasPermission else {
            errorMessage = "Microphone permission not granted"
            return nil
        }

        let fileName = "\(UUID().uuidString).m4a"
        let fileURL = voiceNotesDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
            recordingTime = 0
            errorMessage = nil

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingTime += 0.1
            }

            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.audioRecorder?.updateMeters()
                let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
                let normalizedLevel = max(0, (level + 60) / 60)
                self?.audioLevel = normalizedLevel
            }

            return fileName
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            return nil
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func cancelRecording(fileName: String?) {
        stopRecording()

        if let fileName = fileName {
            let fileURL = voiceNotesDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func playAudio(fileName: String) {
        let fileURL = voiceNotesDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            errorMessage = "Audio file not found"
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            playbackDuration = audioPlayer?.duration ?? 0
            playbackTime = 0
            audioPlayer?.play()
            isPlaying = true
            errorMessage = nil

            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.playbackTime = self?.audioPlayer?.currentTime ?? 0
            }
        } catch {
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
        }
    }

    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
    }

    func resumePlayback() {
        audioPlayer?.play()
        isPlaying = true
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.playbackTime = self?.audioPlayer?.currentTime ?? 0
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackTime = 0
        playbackTimer?.invalidate()
        playbackTimer = nil

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func seekTo(time: TimeInterval) {
        audioPlayer?.currentTime = time
        playbackTime = time
    }

    func deleteAudioFile(fileName: String) {
        let fileURL = voiceNotesDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func getAudioDuration(fileName: String) -> TimeInterval? {
        let fileURL = voiceNotesDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            return player.duration
        } catch {
            return nil
        }
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording failed"
        }
        isRecording = false
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        errorMessage = error?.localizedDescription ?? "Recording error"
        isRecording = false
    }
}

extension AudioRecordingService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.playbackTime = 0
            self.playbackTimer?.invalidate()
            self.playbackTimer = nil
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.errorMessage = error?.localizedDescription ?? "Playback error"
            self.isPlaying = false
        }
    }
}

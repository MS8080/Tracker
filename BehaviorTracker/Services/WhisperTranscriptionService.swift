import Foundation
import AVFoundation
import SwiftUI

// WhisperKit import - will be available once package is resolved
#if canImport(WhisperKit)
import WhisperKit
#endif

@MainActor
class WhisperTranscriptionService: ObservableObject {
    static let shared = WhisperTranscriptionService()

    @Published var isTranscribing = false
    @Published var isRecording = false
    @Published var isModelLoaded = false
    @Published var isLoadingModel = false
    @Published var loadingProgress: Double = 0
    @Published var transcriptionProgress: String = ""
    @Published var liveTranscript: String = "" // For compatibility with IOSSpeechService
    @Published var audioLevel: Float = 0
    @Published var recordingTime: TimeInterval = 0
    @Published var errorMessage: String?

    #if canImport(WhisperKit)
    private var whisperKit: WhisperKit?
    #endif

    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var currentRecordingURL: URL?
    private var preloadTask: Task<Void, Never>?

    private let recordingsDirectory: URL
    private let modelDirectory: URL

    /// Common medication names for vocabulary enhancement
    private let commonMedications: Set<String> = [
        // ADHD medications
        "Adderall", "Ritalin", "Concerta", "Vyvanse", "Strattera", "Focalin", "Dexedrine",
        "Methylphenidate", "Amphetamine", "Lisdexamfetamine", "Atomoxetine", "Quillivant",
        // Anxiety/Depression
        "Prozac", "Zoloft", "Lexapro", "Wellbutrin", "Effexor", "Cymbalta", "Paxil",
        "Sertraline", "Fluoxetine", "Escitalopram", "Bupropion", "Venlafaxine", "Duloxetine",
        "Celexa", "Citalopram", "Buspar", "Buspirone", "Trazodone", "Mirtazapine", "Remeron",
        // Mood stabilizers
        "Lithium", "Lamictal", "Lamotrigine", "Depakote", "Valproic", "Tegretol", "Carbamazepine",
        // Antipsychotics
        "Abilify", "Aripiprazole", "Risperdal", "Risperidone", "Seroquel", "Quetiapine",
        "Zyprexa", "Olanzapine", "Latuda", "Lurasidone", "Geodon", "Ziprasidone",
        // Sleep
        "Melatonin", "Ambien", "Zolpidem", "Lunesta", "Eszopiclone", "Trazodone", "Hydroxyzine",
        // Anxiety (benzodiazepines)
        "Xanax", "Alprazolam", "Klonopin", "Clonazepam", "Ativan", "Lorazepam", "Valium", "Diazepam",
        // Pain/Other
        "Gabapentin", "Neurontin", "Pregabalin", "Lyrica", "Propranolol", "Inderal", "Clonidine",
        // Common OTC
        "Tylenol", "Acetaminophen", "Ibuprofen", "Advil", "Motrin", "Aspirin", "Benadryl",
        "Diphenhydramine", "Zyrtec", "Cetirizine", "Claritin", "Loratadine", "Allegra",
        // Supplements & Amino Acids (with and without L- prefix)
        "Magnesium", "Vitamin D", "Vitamin B12", "Omega-3", "Fish Oil", "Probiotics", "Iron",
        "Zinc", "L-Theanine", "Theanine", "Ashwagandha", "Rhodiola", "5-HTP", "SAM-e", "GABA",
        "L-Tyrosine", "Tyrosine", "L-Tryptophan", "Tryptophan", "L-Carnitine", "Carnitine",
        "L-Glutamine", "Glutamine", "L-Arginine", "Arginine",
        "CoQ10", "NAC", "Alpha-GPC", "Creatine", "Taurine", "Inositol",
        // Vertigo/Inner ear
        "Betahistine", "Betahistin", "Serc", "Meclizine", "Antivert", "Dramamine", "Dimenhydrinate"
    ]

    /// Whisper special tokens that should be removed from transcription
    private let whisperSpecialTokens: [String] = [
        "[BLANK_AUDIO]", "{blank_audio}", "(blank_audio)", "[NOISE]", "{noise}",
        "[MUSIC]", "{music}", "[APPLAUSE]", "{applause}", "[LAUGHTER]", "{laughter}",
        "[SILENCE]", "{silence}", "[INAUDIBLE]", "{inaudible}", "(inaudible)",
        "[NO_SPEECH]", "{no_speech}", "<|nospeech|>", "<|endoftext|>"
    ]

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("WhisperRecordings")

        // Use Application Support for model storage (persists across app updates)
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        modelDirectory = appSupportPath.appendingPathComponent("WhisperKitModels")

        // Create directories if needed
        for directory in [recordingsDirectory, modelDirectory] {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }

    /// Get user's medication names from DataController
    private func getUserMedicationNames() -> [String] {
        let medications = DataController.shared.fetchMedications(activeOnly: false)
        return medications.compactMap { $0.name }
    }

    /// Post-process transcription to correct medication names
    func correctMedicationNames(in text: String) -> String {
        // Get all known medications (common + user's)
        var allMedications = commonMedications
        for med in getUserMedicationNames() {
            allMedications.insert(med)
        }

        // Build a lookup dictionary for case-insensitive matching
        let medicationLookup = Dictionary(uniqueKeysWithValues: allMedications.map { ($0.lowercased(), $0) })

        // Split text into words and check each
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var correctedWords: [String] = []

        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)

            // Check for exact match (case-insensitive)
            if let correctSpelling = medicationLookup[cleanWord.lowercased()] {
                // Preserve any trailing punctuation
                let suffix = word.hasSuffix(".") ? "." : (word.hasSuffix(",") ? "," : "")
                correctedWords.append(correctSpelling + suffix)
            }
            // Check for fuzzy match (Levenshtein distance <= 2)
            else if let match = findClosestMedication(cleanWord, in: allMedications) {
                let suffix = word.hasSuffix(".") ? "." : (word.hasSuffix(",") ? "," : "")
                correctedWords.append(match + suffix)
            }
            else {
                correctedWords.append(word)
            }
        }

        return correctedWords.joined(separator: " ")
    }

    /// Remove Whisper special tokens from transcription (e.g., [BLANK_AUDIO], {blank_audio})
    private func removeWhisperSpecialTokens(from text: String) -> String {
        var result = text
        for token in whisperSpecialTokens {
            result = result.replacingOccurrences(of: token, with: "", options: .caseInsensitive)
        }
        // Also remove any remaining bracketed/braced tokens that look like Whisper artifacts
        // Matches patterns like [SOMETHING], {something}, (something) where content is all caps or lowercase
        let patterns = [
            "\\[\\w+\\]",      // [WORD]
            "\\{\\w+\\}",      // {word}
            "<\\|\\w+\\|>"     // <|word|>
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }
        // Clean up any double spaces left behind and trim
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Common English words that should never be matched to medications
    private let commonWordsBlacklist: Set<String> = [
        // Common verbs
        "take", "took", "taken", "feel", "felt", "make", "made", "have", "having",
        "give", "gave", "given", "work", "works", "help", "helps", "helped",
        "think", "thought", "know", "knew", "going", "gone", "come", "came",
        "want", "wanted", "need", "needed", "seem", "seemed", "find", "found",
        "call", "called", "tell", "told", "said", "saying", "getting", "doing",
        // Common nouns
        "time", "times", "thing", "things", "people", "person", "life", "world",
        "hand", "hands", "part", "parts", "place", "places", "case", "cases",
        "week", "weeks", "point", "points", "fact", "facts", "group", "groups",
        "problem", "problems", "water", "night", "nights", "morning", "mornings",
        "iron", "zinc", // These are both minerals AND medications - require exact match
        // Common adjectives
        "good", "great", "little", "much", "really", "actually", "probably",
        "different", "important", "small", "large", "long", "certain", "clear",
        // Common adverbs
        "just", "also", "very", "well", "back", "even", "still", "again",
        "here", "there", "when", "then", "now", "always", "never", "often",
        // Common pronouns/articles
        "that", "this", "these", "those", "what", "which", "their", "other",
        // Words that sound like medications
        "serial", "cereal", "process", "general", "literal", "liberal",
        "vital", "mental", "dental", "rental", "total", "local", "vocal",
        "normal", "formal", "journal", "several", "federal", "natural",
        "special", "social", "official", "initial", "partial", "martial",
        "looping", "coping", "hoping", "oping", "typing", "swiping",
        // Neurological/psychological terms (not medications)
        "neuroplasticity", "plasticity", "arousal", "dysregulation", "regulation",
        "stimming", "masking", "meltdown", "shutdown", "burnout", "overload",
        "sensory", "proprioception", "interoception", "alexithymia", "hyperarousal",
        "hypoarousal", "dissociation", "depersonalization", "derealization",
        "rumination", "perseveration", "echolalia", "scripting", "infodumping",
        "hyperfocus", "hyperfixation", "executive", "dysfunction", "working memory",
        "processing", "cognitive", "emotional", "behavioral", "therapy",
        "dopamine", "serotonin", "norepinephrine", "cortisol", "adrenaline",
        "neurotransmitter", "receptor", "reuptake", "synapse", "neuron"
    ]

    /// Find closest medication name using Levenshtein distance
    private func findClosestMedication(_ word: String, in medications: Set<String>) -> String? {
        let lowercasedWord = word.lowercased()

        // Skip common words that should never match medications
        guard !commonWordsBlacklist.contains(lowercasedWord) else { return nil }

        // Only try to match words that are at least 5 characters
        guard lowercasedWord.count >= 5 else { return nil }

        var bestMatch: String?
        var bestDistance = Int.max

        for medication in medications {
            let lowercasedMed = medication.lowercased()

            // Skip if word length differs too much from medication name
            let lengthDiff = abs(lowercasedWord.count - lowercasedMed.count)
            guard lengthDiff <= 2 else { continue }

            let distance = levenshteinDistance(lowercasedWord, lowercasedMed)

            // Require at least 80% similarity (max 20% of characters can differ)
            let maxAllowedDistance = max(1, lowercasedWord.count / 5)

            if distance <= maxAllowedDistance && distance < bestDistance {
                bestDistance = distance
                bestMatch = medication
            }
        }

        return bestMatch
    }

    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var dp = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                dp[i][j] = min(
                    dp[i - 1][j] + 1,      // deletion
                    dp[i][j - 1] + 1,      // insertion
                    dp[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return dp[m][n]
    }

    /// Preload the model in background - call this early (e.g., when entering Journal tab)
    func preloadModelIfNeeded() {
        #if canImport(WhisperKit)
        guard !isModelLoaded && !isLoadingModel && preloadTask == nil else { return }

        preloadTask = Task(priority: .background) {
            await loadModel()
            preloadTask = nil
        }
        #endif
    }

    /// Check if the model is already downloaded locally
    private func isModelDownloaded() -> Bool {
        // Check if model folder contains expected files
        // WhisperKit stores models with different naming conventions
        let possiblePaths = [
            modelDirectory.appendingPathComponent("openai_whisper-base.en"),
            modelDirectory.appendingPathComponent("openai_whisper-base"),
            modelDirectory.appendingPathComponent("base.en"),
            modelDirectory.appendingPathComponent("base")
        ]
        return possiblePaths.contains { FileManager.default.fileExists(atPath: $0.path) }
    }

    func loadModel() async {
        #if canImport(WhisperKit)
        guard !isModelLoaded && !isLoadingModel else { return }

        isLoadingModel = true
        loadingProgress = 0
        errorMessage = nil

        let modelAlreadyDownloaded = isModelDownloaded()
        transcriptionProgress = modelAlreadyDownloaded ? "Loading model..." : "Downloading model..."

        do {
            // Simulate progress updates for better UX
            let progressTask = Task {
                for i in 1...8 {
                    // Faster progress if model already downloaded
                    let interval: UInt64 = modelAlreadyDownloaded ? 100_000_000 : 300_000_000
                    try? await Task.sleep(nanoseconds: interval)
                    if !isModelLoaded {
                        loadingProgress = Double(i) / 10.0
                        if modelAlreadyDownloaded {
                            transcriptionProgress = i <= 5 ? "Loading model..." : "Preparing..."
                        } else {
                            if i <= 3 {
                                transcriptionProgress = "Downloading model..."
                            } else if i <= 6 {
                                transcriptionProgress = "Loading neural engine..."
                            } else {
                                transcriptionProgress = "Preparing..."
                            }
                        }
                    }
                }
            }

            // Use WhisperKitConfig with updated API
            // Using "base.en" for faster English-only transcription
            let config = WhisperKitConfig(
                model: "base.en",
                modelFolder: modelDirectory.path,
                verbose: false,
                logLevel: .error,
                load: true,
                download: true
            )
            whisperKit = try await WhisperKit(config)
            progressTask.cancel()

            loadingProgress = 1.0
            transcriptionProgress = ""
            isLoadingModel = false
            isModelLoaded = true
        } catch {
            // Log the full error for debugging
            print("[WhisperKit] Model load error: \(error)")
            errorMessage = "Failed to load model: \(error.localizedDescription)"
            transcriptionProgress = ""
            isLoadingModel = false
        }
        #else
        errorMessage = "WhisperKit not available"
        #endif
    }

    func requestMicrophonePermission() async -> Bool {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        #else
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        #endif
    }

    func startRecording() async -> Bool {
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            errorMessage = "Microphone permission denied"
            return false
        }

        let fileName = "\(UUID().uuidString).wav"
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)
        currentRecordingURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            #endif

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecording = true
            recordingTime = 0
            errorMessage = nil

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingTime += 0.1
                }
            }

            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.audioRecorder?.updateMeters()
                    let level = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
                    let normalizedLevel = max(0, (level + 50) / 50)
                    self?.audioLevel = normalizedLevel
                }
            }

            return true
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            return false
        }
    }

    /// Common cleanup when stopping recording
    private func cleanupRecording(deleteFile: Bool = false) {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0

        if deleteFile, let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
            currentRecordingURL = nil
        }

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }

    func stopRecordingAndTranscribe() async -> String? {
        cleanupRecording()

        guard let recordingURL = currentRecordingURL else {
            errorMessage = "No recording found"
            return nil
        }

        return await transcribe(audioURL: recordingURL)
    }

    func cancelRecording() {
        cleanupRecording(deleteFile: true)
        recordingTime = 0
    }

    private func transcribe(audioURL: URL) async -> String? {
        #if canImport(WhisperKit)
        if whisperKit == nil {
            await loadModel()
        }

        guard let whisper = whisperKit else {
            errorMessage = "Model not loaded"
            return nil
        }

        isTranscribing = true
        transcriptionProgress = "Transcribing..."

        defer {
            isTranscribing = false
            transcriptionProgress = ""
            try? FileManager.default.removeItem(at: audioURL)
            currentRecordingURL = nil
        }

        do {
            // Configure transcription options for English
            let options = DecodingOptions(
                task: .transcribe,
                language: "en"
            )

            let results = try await whisper.transcribe(audioPath: audioURL.path, decodeOptions: options)
            var transcription = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            // Apply post-processing
            if !transcription.isEmpty {
                // First remove Whisper special tokens like [BLANK_AUDIO], {blank_audio}, etc.
                transcription = removeWhisperSpecialTokens(from: transcription)
                // Then correct medication names
                transcription = correctMedicationNames(in: transcription)
            }

            return transcription.isEmpty ? nil : transcription
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            return nil
        }
        #else
        errorMessage = "WhisperKit not available"
        try? FileManager.default.removeItem(at: audioURL)
        currentRecordingURL = nil
        return nil
        #endif
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

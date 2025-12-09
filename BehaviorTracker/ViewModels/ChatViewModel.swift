import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let geminiService = GeminiService.shared
    private let dataController = DataController.shared
    private let demoService = DemoModeService.shared
    private var cancellables = Set<AnyCancellable>()

    var isDemoMode: Bool {
        demoService.isEnabled
    }

    init() {
        loadInitialMessages()
        observeDemoModeChanges()
    }

    private func observeDemoModeChanges() {
        NotificationCenter.default.publisher(for: .demoModeChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadInitialMessages()
            }
            .store(in: &cancellables)
    }

    private func loadInitialMessages() {
        messages.removeAll()

        if isDemoMode {
            // Load demo chat messages
            for demoMessage in demoService.demoChatMessages {
                messages.append(ChatMessage(
                    role: demoMessage.isUser ? .user : .assistant,
                    content: demoMessage.content
                ))
            }
        } else {
            // Add initial greeting
            let greeting = ChatMessage(
                role: .assistant,
                content: "Hi! I'm your AI assistant. I can help you understand your journal entries, patterns, and provide insights. What would you like to know?"
            )
            messages.append(greeting)
        }
    }

    func sendMessage() async {
        let userInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userInput.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: userInput)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        if isDemoMode {
            // Simulate delay for demo mode
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            let demoResponse = ChatMessage(
                role: .assistant,
                content: generateDemoResponse(for: userInput)
            )
            messages.append(demoResponse)
            isLoading = false
            return
        }

        do {
            // Build context from user's data
            let context = buildUserContext()

            // Build conversation history for Gemini
            let prompt = buildPrompt(userMessage: userInput, context: context)

            // Call Gemini
            let response = try await geminiService.generateContent(prompt: prompt)

            // Add assistant response
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)

        } catch {
            errorMessage = error.localizedDescription
            // Add error message to chat
            let errorResponse = ChatMessage(
                role: .assistant,
                content: "Sorry, I encountered an error. Please try again."
            )
            messages.append(errorResponse)
        }

        isLoading = false
    }

    private func generateDemoResponse(for input: String) -> String {
        let lowercased = input.lowercased()

        if lowercased.contains("pattern") || lowercased.contains("trend") {
            return "Looking at your demo data, I can see patterns of sensory sensitivity in the mornings and social fatigue after video calls. Your hyperfocus sessions tend to be most productive in the afternoon. Would you like more details about any of these patterns?"
        } else if lowercased.contains("sleep") || lowercased.contains("tired") || lowercased.contains("energy") {
            return "Based on the demo data, there's a correlation between sleep quality and sensory sensitivity the next day. On days with less than 7 hours of sleep, you tend to experience more sensory overload. Consider tracking your sleep more closely to identify optimal rest patterns."
        } else if lowercased.contains("social") || lowercased.contains("meeting") || lowercased.contains("people") {
            return "Your demo data shows that social interactions, especially video calls, require significant energy. After meetings longer than 1 hour, you typically need 30+ minutes of recovery time. Planning buffer time between social commitments could help manage your energy better."
        } else if lowercased.contains("help") || lowercased.contains("suggest") || lowercased.contains("advice") {
            return "Here are some insights from your demo data:\n\n1. Morning sensory sensitivity is common - try a gradual wake-up routine\n2. Video calls drain more energy than in-person meetings\n3. Your hyperfocus is a strength - just set meal reminders\n4. Consistent routines correlate with better mood scores"
        } else {
            return "This is a demo response. In the full version, I would analyze your actual journal entries, patterns, and personal context to provide personalized insights. Try asking about your patterns, energy levels, or social interactions!"
        }
    }

    private func buildUserContext() -> String {
        var context = ""

        // Get recent journal entries (last 7 days)
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = dataController.fetchJournalEntriesSync(startDate: weekAgo, endDate: Date())

        if !recentEntries.isEmpty {
            context += "Recent journal entries (last 7 days):\n"
            for entry in recentEntries.prefix(5) {
                let dateStr = entry.timestamp.formatted(date: .abbreviated, time: .omitted)
                let preview = String(entry.content.prefix(200))
                context += "- [\(dateStr)] \(preview)...\n"
            }
            context += "\n"
        }

        // Get logged patterns (from PatternEntry)
        let patternEntries = PatternRepository.shared.fetchSync(startDate: weekAgo, endDate: Date())
        if !patternEntries.isEmpty {
            context += "Logged patterns this week:\n"
            var patternCounts: [String: Int] = [:]
            for entry in patternEntries {
                let category = entry.category
                patternCounts[category, default: 0] += 1
            }
            for (category, count) in patternCounts.sorted(by: { $0.value > $1.value }).prefix(5) {
                context += "- \(category): \(count) occurrences\n"
            }
            context += "\n"
        }

        // Get medications
        let medications = dataController.fetchMedications(activeOnly: true)
        if !medications.isEmpty {
            context += "Current medications:\n"
            for med in medications {
                context += "- \(med.name)"
                if let dosage = med.dosage, !dosage.isEmpty {
                    context += " (\(dosage))"
                }
                context += "\n"
            }
        }

        return context
    }

    private func buildPrompt(userMessage: String, context: String) -> String {
        // Include recent conversation history (last 6 messages)
        var conversationHistory = ""
        let recentMessages = messages.suffix(6)
        for message in recentMessages where message.role != .system {
            let role = message.role == .user ? "User" : "Assistant"
            conversationHistory += "\(role): \(message.content)\n"
        }

        return """
        You are a helpful, empathetic AI assistant integrated into a behavior tracking app designed for individuals with autism spectrum conditions and PDA (Pathological Demand Avoidance).

        Your role is to:
        - Help users understand their patterns and journal entries
        - Provide supportive, non-judgmental insights
        - Answer questions about their tracked data
        - Offer gentle suggestions when appropriate
        - Be concise but warm in your responses

        Important guidelines:
        - Never diagnose or provide medical advice
        - Be sensitive to sensory and emotional experiences
        - Acknowledge the user's feelings and experiences
        - Keep responses focused and not overwhelming
        - Use clear, direct language

        USER'S CONTEXT:
        \(context)

        RECENT CONVERSATION:
        \(conversationHistory)

        User: \(userMessage)

        Assistant:
        """
    }

    func clearChat() {
        messages.removeAll()
        let greeting = ChatMessage(
            role: .assistant,
            content: "Chat cleared. How can I help you?"
        )
        messages.append(greeting)
    }
}

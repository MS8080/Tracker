import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let geminiService = GeminiService.shared
    private let dataController = DataController.shared

    init() {
        // Add initial greeting
        let greeting = ChatMessage(
            role: .assistant,
            content: "Hi! I'm your AI assistant. I can help you understand your journal entries, patterns, and provide insights. What would you like to know?"
        )
        messages.append(greeting)
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

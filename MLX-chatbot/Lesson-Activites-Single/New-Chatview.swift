//
//  ChatView.swift
//  MLX-chatbot
//
//  ─────────────────────────────────────────────────────────────
//  THINGS YOU CAN CUSTOMISE IN THIS FILE:
//    1. The AI's personality  → search "SECTION 1"
//  ─────────────────────────────────────────────────────────────

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXNN
import MLXFast
import SwiftUI
import Tokenizers
import Combine
import Hub

@MainActor
class ChatViewModel: ObservableObject {

    @Published var input = ""
    @Published var messages: [String] = []
    @Published private(set) var isReady = false
    @Published var isModelLoading: Bool = false
    @Published var modelLoadProgress: Progress? = nil


    // ─────────────────────────────────────────────────────────────
    // SECTION 1 — AI PERSONALITY
    //
    // ★ YOUR TASK: Edit this prompt in plain English.
    //   This is sent to the AI before every conversation.
    //   Change it and ask the AI the same question — see what shifts.
    // ─────────────────────────────────────────────────────────────

    private let SYSTEM_PROMPT = """
        You are a helpful learning assistant who teaches concepts step by step \
        using clear, scaffolded language.
        You never provide exact code solutions.
        If a student asks something unrelated or off-topic, politely redirect \
        them to the active course material.
        """





  

    // ─────────────────────────────────────────────────────────────
    // BELOW THIS LINE — DO NOT EDIT
    // ─────────────────────────────────────────────────────────────

    private var sandboxDir: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MLX-chatbot", isDirectory: true)
    }

    private var fusedModelURL: URL { sandboxDir.appendingPathComponent("fused_model", isDirectory: true) }
    private var adaptersURL: URL   { sandboxDir.appendingPathComponent("adapters",    isDirectory: true) }
    private var session: ChatSession?

    init() {
        Task { await loadModel() }
        printFlaggedWords()
    }

    private func loadModel() async {
        isModelLoading = true
        modelLoadProgress = nil

        guard FileManager.default.fileExists(atPath: fusedModelURL.path) else {
            messages.append(
                "Bot: No trained model found at\n\(fusedModelURL.path)\n\n" +
                "Run train_qwen_lora.sh first, then relaunch the app."
            )
            isModelLoading = false
            return
        }

        do {
            let config = ModelConfiguration(directory: fusedModelURL)
            let container = try await LLMModelFactory.shared.loadContainer(
                hub: HubApi(),
                configuration: config
            ) { [weak self] progress in
                Task { @MainActor in self?.modelLoadProgress = progress }
            }
            let params = GenerateParameters(maxTokens: 250, temperature: 0.7, topP: 0.9)
            session = ChatSession(container, instructions: SYSTEM_PROMPT, generateParameters: params)
            isReady = true
        } catch {
            messages.append("Bot: Could not load model — \(error.localizedDescription)")
        }

        isModelLoading = false
    }

    func reset() {
        session = nil
        isReady = false
        messages = []
        let fm = FileManager.default
        try? fm.removeItem(at: fusedModelURL)
        try? fm.removeItem(at: adaptersURL)
        messages.append("Model and adapters deleted. Run train_qwen_lora.py in Terminal, then relaunch the app.")
    }

    func send() {
        guard let session = session, !input.isEmpty else { return }
        let question = input
        input = ""

        if Obadeki.containsOffensiveContent(question) || containsFlagged(question) {
            messages.append("You: \(question)")
            messages.append("Bot: Instructors can see your conversation. Ask an on-topic question!")
            return
        }

        messages.append("You: \(question)")
        isReady = false

        Task { @MainActor in
            let prompt = """
            <|im_start|>system
            \(SYSTEM_PROMPT)
            <|im_end|>
            <|im_start|>user
            \(question)
            <|im_end|>
            <|im_start|>assistant
            """

            messages.append("")
            let placeholderIndex = messages.count - 1
            var accumulated = ""

            do {
                for try await token in session.streamResponse(to: prompt) {
                    accumulated += token
                    messages[placeholderIndex] = accumulated
                }
            } catch {
                messages[placeholderIndex] = "Error: \(error.localizedDescription)"
            }

            isReady = true
        }
    }
}

@main
struct MLX_chatbotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

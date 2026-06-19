//
//  ChatView.swift
//  MLX-chatbot
//
//  Created by AVELA Student on 2/23/26.
//
//  HOW THIS FILE CONNECTS TO train_qwen_lora.sh:
//
//  1. Run the script once in Terminal (or add it as an Xcode Build Phase):
//       chmod +x train_qwen_lora.sh
//       ./train_qwen_lora.sh
//
//  2. The script trains Qwen2.5-1.5B-Instruct with LoRA, fuses the adapters,
//     and saves the result to:
//       ~/Library/Application Support/MLX-chatbot/fused_model
//
//  3. On the next app launch the model loads automatically from that path.
//     No Hugging Face upload needed.
//
//  To retrain: FORCE=1 ./train_qwen_lora.sh
//

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

// MARK: - ChatViewModel

@MainActor
class ChatViewModel: ObservableObject {

    // MARK: - Published UI state

    @Published var input = ""
    @Published var messages: [String] = []

    // false while the model is loading or while generating a reply
    @Published private(set) var isReady = false

    @Published var isModelLoading: Bool = false
    @Published var modelLoadProgress: Progress? = nil

    // MARK: - System prompt
    //
    // ★ Edit this to shape how the assistant responds.

    private let SYSTEM_PROMPT = """
        You are a helpful learning assistant who teaches concepts step by step \
        using clear, scaffolded language.
        You never provide exact code solutions.
        If a student asks something unrelated or off-topic, politely redirect \
        them to the active course material.
        """

    // MARK: - Local model path
    //
    // This must match FUSED_MODEL_DIR in train_qwen_lora.sh.
    // Default: ~/Library/Application Support/MLX-chatbot/fused_model

    private var sandboxDir: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MLX-chatbot", isDirectory: true)
    }

    private var fusedModelURL: URL { sandboxDir.appendingPathComponent("fused_model", isDirectory: true) }
    private var adaptersURL: URL   { sandboxDir.appendingPathComponent("adapters",    isDirectory: true) }

    // MARK: - Private state

    private var session: ChatSession?

    // MARK: - Init — loads the model automatically on launch

    init() {
        Task { await loadModel() }
    }

    // MARK: - Model loading

    private func loadModel() async {
        isModelLoading = true
        modelLoadProgress = nil

        // Make sure the fused model exists before trying to load it
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
            print("[Model] Loaded from \(fusedModelURL.path)")
        } catch {
            print("[Model] Failed to load: \(error)")
            messages.append("Bot: Could not load model — \(error.localizedDescription)")
        }

        isModelLoading = false
    }

    // MARK: - Reset

    func reset() {
        session = nil
        isReady = false
        messages = []
        let fm = FileManager.default
        try? fm.removeItem(at: fusedModelURL)
        try? fm.removeItem(at: adaptersURL)
        messages.append("Model and adapters deleted. Run train_qwen_lora.py in Terminal, then relaunch the app.")
    }

    // MARK: - Send

    func send() {
        guard let session = session, !input.isEmpty else { return }
        let question = input
        input = ""

        if Obadeki.containsOffensiveContent(question) {
            messages.append("You: \(question)")
            messages.append("Bot: Intructors can see your conversation. Ask an ontopic question!")
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

// MARK: - App Entry Point

@main
struct MLX_chatbotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

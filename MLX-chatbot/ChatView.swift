//
//  MLX_chatbotApp.swift
//  MLX-chatbot
//
//  Created by AVLA Student on 2/23/26.
//

import SwiftUI
import Combine

//import MLX
import MLXLLM
import MLXLMCommon
import MLXNN
import MLXEmbedders
import MLXFast
import Metal
import CoreML
import PDFKit
import NaturalLanguage

// MARK: - App State

@MainActor
class AppState: ObservableObject {

    @Published var input: String = ""
    @Published var finalContext: String = ""
    @Published var prompt: String = ""
    @Published var messages: [String] = []

    @Published private(set) var isReady: Bool = true
    @Published private(set) var currentModelID: String = "ShukraJaliya/BLUEQ"

    @Published var isModelLoading: Bool = true
    @Published var isEmbedModelLoading: Bool = true

    @Published var modelLoadProgress: Progress? = nil
    @Published var embedModelProgress: Progress? = nil

    @Published var embedderModel: MLXEmbedders.ModelContainer? = nil
}

// MARK: - App Entry Point

@main
struct MLX_chatbotApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

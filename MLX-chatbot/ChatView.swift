//
//  MLX_chatbotApp.swift
//  MLX-chatbot
//
//  Created by AVLA Student on 2/23/26.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXNN
import MLXEmbedders
import MLXFast
import MLXOptimizers
import Metal
import SwiftUI
import Tokenizers
import Combine
import CoreML
import PDFKit
import NaturalLanguage
import Hub
import MachO
import os
import Darwin.Mach
import CreateML


@Published var input = ""
@Published var finalContext = ""
@Published var prompt = ""
@Published var messages: [String] = []
@Published private(set) var isReady = true
@Published private(set) var currentModelID: String = "ShukraJaliya/BLUEQ"
@Published var isModelLoading: Bool = true
@Published var isEmbedModelLoading: Bool = true
@Published var modelLoadProgress: Progress? = nil
@Published var embedModelProgress: Progress? = nil
@Published var embedderModel: MLXEmbedders.ModelContainer?




@main
struct MLX_chatbotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

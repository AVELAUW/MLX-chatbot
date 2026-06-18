//
//  ChatView.swift
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

#if os(iOS)
import UIKit
#endif

#if canImport(CreateML)
import CreateML
#endif

// Compatibility shim so the project compiles on platforms without CreateML (e.g. iOS simulators)
#if !canImport(CreateML)
struct MLTextClassifier {
    enum ShimError: Error { case unavailable }
    init(contentsOf url: URL) throws { throw ShimError.unavailable }
    func predictionWithConfidence(from text: String) throws -> [String: Double] { throw ShimError.unavailable }
}
#endif

// MARK: - ChatViewModel

// Training-only ViewModel: the chat model is never pre-loaded at startup.
// isReady stays false until the user trains a course and an in-memory adapter is applied.
@MainActor
class ChatViewModel: ObservableObject {

    // MARK: - Memory monitoring

    // Fraction of total device RAM beyond which we start freeing resources
    private var memoryThresholdBytes: UInt64 {
        if let override = UserDefaults.standard.object(forKey: "MemoryThresholdBytes") as? NSNumber {
            return override.uint64Value
        }
        #if os(macOS)
        let fraction: Double = 0.95
        #else
        let fraction: Double = 0.85
        #endif
        return UInt64(Double(ProcessInfo.processInfo.physicalMemory) * fraction)
    }

    // Returns the current resident memory footprint of this process in bytes
    private func currentResidentMemoryBytes() -> UInt64 {
        var infoCount = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4
        var info = task_vm_info_data_t()
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &infoCount)
            }
        }
        if kerr == KERN_SUCCESS { return info.phys_footprint }
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info_data_t>.size) / 4
        var basic = task_basic_info_data_t()
        let kerr2 = withUnsafeMutablePointer(to: &basic) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { iptr in
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), iptr, &count)
            }
        }
        if kerr2 == KERN_SUCCESS { return UInt64(basic.resident_size) }
        return 0
    }

    // MARK: - Performance presets

    // Tuned token/batch limits per device class to balance speed and memory
    struct PerformancePreset {
        let genMaxTokens: Int
        let embedBatchSize: Int
        let embedMaxTokenLength: Int
    }

    private var currentPreset: PerformancePreset = {
        #if os(iOS)
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return isPad
            ? PerformancePreset(genMaxTokens: 60,  embedBatchSize: 48, embedMaxTokenLength: 320)
            : PerformancePreset(genMaxTokens: 60,  embedBatchSize: 24, embedMaxTokenLength: 256)
        #elseif os(visionOS)
        return PerformancePreset(genMaxTokens: 80,  embedBatchSize: 64, embedMaxTokenLength: 384)
        #elseif os(macOS)
        return PerformancePreset(genMaxTokens: 250, embedBatchSize: 96, embedMaxTokenLength: 512)
        #else
        return PerformancePreset(genMaxTokens: 100, embedBatchSize: 32, embedMaxTokenLength: 256)
        #endif
    }()

    // MARK: - Published UI state

    @Published var input = ""
    @Published var finalContext = ""
    @Published var prompt = ""
    @Published var messages: [String] = []

    // Starts false — chat is only enabled after a trained adapter is applied
    @Published private(set) var isReady = false
    @Published private(set) var currentModelID: String = "ShukraJaliya/GENERAL.2"

    // isModelLoading is only true while the base model loads during training
    @Published var isModelLoading: Bool = false
    @Published var isEmbedModelLoading: Bool = true
    @Published var modelLoadProgress: Progress? = nil
    @Published var embedModelProgress: Progress? = nil
    @Published var embedderModel: MLXEmbedders.ModelContainer?

    @Published var isTraining: Bool = false
    @Published var trainingProgress: Double? = nil
    @Published var didFinishExtraction: Bool = false

    private let trainingEpochs: Int = 1
    private let iterationsPerEpoch: Int = 100

    @Published var isAdapterActive = false

    // RAG cache — built from the uploaded PDF for semantic retrieval
    @Published private(set) var cachedChunks: [String] = []
    @Published private(set) var cachedChunkEmbeddings: [[Float]] = []
    @Published var isRAGReady: Bool = false
    private var cachedPDFURL: URL?

    // MARK: - Session / task handles

    // URL of the PDF currently being used for RAG and training (nil if none uploaded)
    @Published var currentRAGPDFURL: URL? = nil

    // Active chat session — only set after applyInMemoryAdapter() is called
    private var session: ChatSession?
    private var sessionInstructions: String? = nil
    private var sessionParameters: GenerateParameters? = nil

    // MARK: - LoRA config

    private let loraLayers = 4
    private let learningRate: Float = 2e-5

    // Holds the base model + trained LoRA weights from the most recent training run
    private var modelContainerForTraining: MLXLMCommon.ModelContainer?

    // MARK: - Per-course classifier

    @Published var activeCourseKey: String = "default"
    @Published var activeClassifierURL: URL? = nil
    var activeTextClassifier: MLTextClassifier?

    private var classifierCache: [String: MLModel] = [:]
    private var lastCourseKey: String? = nil
    private func classifierCacheKeyForCourse(_ key: String) -> String { "course:\(key)" }

    // MARK: - System prompts

    // Default prompt — step-by-step teaching without giving away answers
    let SYSTEM_PROMPT = """
        You are a helpful learning assistant who teaches concepts step by step using clear, scaffolded language.
        You never provide exact code solutions.
        If a student asks something unrelated or off-topic, politely redirect them to the active course material.
        """

    // Used when RAG context is retrieved — more expert tone to work with the PDF excerpts
    let SYSTEM_PROMPT_RAG = """
        You are an expert who teaches concepts step by step using clear, scaffolded language. You never provide exact code solutions. For questions with code or unclear elements, explain what each part means by guiding with detailed conceptual steps. If a user asks about something not in the uploaded course material, respond that you can only answer questions about that content and gently redirect them.
        """

    // MARK: - Init

    init() {
        // Only load the embedding model at startup.
        // The chat model (GENERAL.2) loads on-demand when the user trains a course.
        Task {
            self.isEmbedModelLoading = true
            self.embedModelProgress = Progress(totalUnitCount: 100)

            do {
                let container = try await MLXEmbedders.loadModelContainer(
                    configuration: ModelConfiguration.minilm_l6,
                    progressHandler: { [weak self] prog in
                        Task { @MainActor in self?.embedModelProgress = prog }
                    }
                )
                self.embedderModel = container
            } catch {
                print("Embedder loading failed: \(error)")
            }

            self.isEmbedModelLoading = false
            GPU.set(cacheLimit: 16 * 1024 * 1024)
        }
    }

    // MARK: - Session reset (memory guard)

    // Rebuilds the ChatSession from the trained container when memory pressure forces a reset
    private func resetSessionIfNeeded(reason: String) {
        guard let container = modelContainerForTraining,
              let instructions = sessionInstructions,
              let params = sessionParameters else { return }
        session = ChatSession(container, instructions: instructions, generateParameters: params)
        print("[MemoryGuard] Rebuilt ChatSession (reason: \(reason))")
    }

    // MARK: - Classifier path helpers

    // Root directory in Application Support for storing all course data
    private func appSupportDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("MLX-Chatbot", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // Per-course folder keyed by a filesystem-safe version of the course name
    private func courseDir(for courseKey: String) -> URL {
        let safe = courseKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let dir = appSupportDir()
            .appendingPathComponent("Courses", isDirectory: true)
            .appendingPathComponent(safe, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // Subfolder within the course directory where the compiled CoreML classifier lives
    private func classifierDir(for courseKey: String) -> URL {
        let dir = courseDir(for: courseKey).appendingPathComponent("Classifier", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // Expected path for the compiled classifier model for a given course
    private func classifierModelURL(for courseKey: String) -> URL {
        classifierDir(for: courseKey).appendingPathComponent("TopicClassifier.mlmodelc", isDirectory: true)
    }

    // Activates a course — loads its classifier from disk if it exists, clears cache for the previous course
    func setActiveCourse(_ courseKey: String) {
        let key = stableCourseKey(courseKey)
        if let prev = lastCourseKey, prev != key {
            classifierCache.removeValue(forKey: classifierCacheKeyForCourse(prev))
        }
        lastCourseKey = key
        activeCourseKey = key
        let url = classifierModelURL(for: key)
        activeClassifierURL = FileManager.default.fileExists(atPath: url.path) ? url : nil
        classifierCache.removeValue(forKey: classifierCacheKeyForCourse(key))
        print("[Classifier] activeCourse=\(key), url=\(activeClassifierURL?.path ?? "nil")")
    }

    // MARK: - Topic classification

    // Uses the trained NLModel to decide if a question is on-topic for the active course
    private func classifyTopic(for question: String) -> (label: String, confidence: Double)? {
        func loadNLModel() throws -> NLModel? {
            if let url = activeClassifierURL {
                return try NLModel(mlModel: MLModel(contentsOf: url))
            }
            return nil
        }
        do {
            guard let nl = try loadNLModel() else {
                print("[Classifier] No trained classifier yet")
                return nil
            }
            let hypotheses = nl.predictedLabelHypotheses(for: question, maximumCount: 2)
            print("[Classifier][RAW]", hypotheses)
            if let on  = hypotheses["1"] { return ("1", on) }
            if let off = hypotheses["0"] { return ("0", off) }
            if let any = hypotheses.first { return (any.key, any.value) }
        } catch {
            print("[Classifier] Failed:", error)
        }
        return nil
    }

    // MARK: - RAG — PDF chunking

    // Splits the uploaded PDF into sentence-group chunks used for semantic retrieval
    private func textChunker(sentencesPerChunk: Int = 3) -> [String] {
        guard let pdfURL = currentRAGPDFURL,
              let pdfDocument = PDFDocument(url: pdfURL) else {
            print("No PDF set for chunking")
            return []
        }

        // Flatten all pages into a single string
        var allText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let text = page.string {
                allText += text + " "
            }
        }

        let cleaned = cleanText(allText)
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = cleaned

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: cleaned.startIndex..<cleaned.endIndex) { range, _ in
            let s = cleaned[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { sentences.append(s) }
            return true
        }

        // Group sentences into fixed-size chunks
        var rawChunks: [[String]] = []
        var current: [String] = []
        for sentence in sentences {
            current.append(sentence)
            if current.count >= sentencesPerChunk {
                rawChunks.append(current)
                current.removeAll()
            }
        }
        if !current.isEmpty { rawChunks.append(current) }

        // Merge undersized trailing chunks forward
        var fixedChunks: [String] = []
        var buffer: [String] = []
        for chunk in rawChunks {
            buffer.append(contentsOf: chunk)
            if buffer.count >= sentencesPerChunk {
                fixedChunks.append(buffer.joined(separator: " "))
                buffer.removeAll()
            }
        }
        if !buffer.isEmpty { fixedChunks.append(buffer.joined(separator: " ")) }

        // Deduplicate while preserving order
        var seen = Set<String>()
        return fixedChunks.filter { seen.insert($0).inserted }
    }

    // Normalizes whitespace and line endings extracted from PDF text
    private func cleanText(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "\r\n", with: "\n")
        s = s.replacingOccurrences(of: "\r",   with: "\n")
        s = s.replacingOccurrences(of: "\t",   with: " ")
        s = s.replacingOccurrences(of: "  +",  with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Embedding

    // Converts text chunks into dense float vectors using the loaded MiniLM embedder
    func embedChunks(_ chunks: [String]) async throws -> [[Float]] {
        guard let modelContainer = embedderModel else {
            throw NSError(domain: "Embedder", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Embedding model not loaded"])
        }
        let maxLen = currentPreset.embedMaxTokenLength
        return await modelContainer.perform { (model: EmbeddingModel, tokenizer, pooling) -> [[Float]] in
            let encoded = chunks.map { text -> [Int] in
                var tokens = tokenizer.encode(text: text, addSpecialTokens: true)
                if tokens.count > maxLen { tokens = Array(tokens.prefix(maxLen)) }
                return tokens
            }
            let maxLength = encoded.map(\.count).max() ?? 0
            let eos = tokenizer.eosTokenId ?? 0
            let padded = stacked(encoded.map { t in
                MLXArray(t + Array(repeating: eos, count: maxLength - t.count))
            })
            let mask = (padded .!= eos)
            let tokenTypes = MLXArray.zeros(like: padded)
            let output = pooling(
                model(padded, positionIds: nil, tokenTypeIds: tokenTypes, attentionMask: mask),
                normalize: true, applyLayerNorm: true
            )
            let flat: [Float] = output.asArray(Float.self)
            let count = chunks.count
            let dim = count > 0 ? flat.count / count : 0
            return (0..<count).map { i in Array(flat[i*dim..<(i+1)*dim]) }
        }
    }

    // Runs embedChunks in batches so large PDFs don't exhaust GPU memory
    private func embedChunksBatched(_ chunks: [String], batchSize: Int) async throws -> [[Float]] {
        guard !chunks.isEmpty else { return [] }
        var all: [[Float]] = []
        all.reserveCapacity(chunks.count)
        var idx = 0
        while idx < chunks.count {
            let end = min(idx + batchSize, chunks.count)
            all.append(contentsOf: try await embedChunks(Array(chunks[idx..<end])))
            idx = end
        }
        return all
    }

    // Builds and caches the chunk + embedding arrays for the currently set PDF
    private func prepareRAGCache(for url: URL) async {
        guard currentRAGPDFURL != nil else {
            await MainActor.run {
                cachedChunks = []; cachedChunkEmbeddings = []; isRAGReady = false
            }
            return
        }
        let chunks = textChunker()
        guard let embeddings = try? await embedChunksBatched(chunks, batchSize: currentPreset.embedBatchSize) else {
            await MainActor.run {
                cachedChunks = []; cachedChunkEmbeddings = []; isRAGReady = false
            }
            return
        }
        await MainActor.run {
            cachedChunks = chunks
            cachedChunkEmbeddings = embeddings
            isRAGReady = true
            print("[RAG] Cached \(chunks.count) chunks, \(embeddings.count) embeddings")
        }
    }

    // Simple dot-product similarity used to rank chunks against the query embedding
    private func dotProduct(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        return zip(a, b).map(*).reduce(0, +)
    }

    // MARK: - RAG PDF setter

    // Called when the user uploads a new PDF — clears old cache and kicks off a fresh rebuild
    func setRAGPDF(url: URL) {
        currentRAGPDFURL = url
        cachedChunks = []; cachedChunkEmbeddings = []; isRAGReady = false
        cachedPDFURL = url
        print("RAG PDF set: \(url.path)")
        Task { [weak self] in await self?.prepareRAGCache(for: url) }
    }

    // MARK: - Send

    func send() {
        // Chat is only possible after a trained adapter has been applied (session exists)
        guard let session = session, !input.isEmpty else { return }
        let question = input

        let classification = classifyTopic(for: question)

        // Append the user's message to the conversation
        messages.append("You: \(question)")

        // Preflight memory guard — reset session and trim RAG cache if near the limit
        let currentBytes = currentResidentMemoryBytes()
        let threshold = memoryThresholdBytes
        if currentBytes >= UInt64(Double(threshold) * 0.90) {
            resetSessionIfNeeded(reason: "preflight >=90%")
            if cachedChunks.count > 512 {
                cachedChunks.removeAll(keepingCapacity: false)
                cachedChunkEmbeddings.removeAll(keepingCapacity: false)
                isRAGReady = false
                if let url = currentRAGPDFURL {
                    Task { [weak self] in await self?.prepareRAGCache(for: url) }
                }
            }
        }

        input = ""
        isReady = false

        Task { @MainActor in
            let start = Date()
            do {
                let topicLabel = classification?.label
                let topicConf  = classification?.confidence

                var effectiveQuestion = question
                var overrideSysPrompt: String? = nil
                var allowRAG = false

                if let label = topicLabel, let conf = topicConf {
                    let pct = Int((conf * 100).rounded())
                    if label == "1" {
                        if pct >= 60 {
                            // High confidence on-topic — retrieve RAG context
                            overrideSysPrompt = SYSTEM_PROMPT_RAG
                            allowRAG = true
                            print("[RAG][Gate] on-topic \(pct)% -> RAG ENABLED")
                        } else if pct >= 50 {
                            // Borderline — ask the user to clarify before answering
                            overrideSysPrompt = SYSTEM_PROMPT
                            effectiveQuestion = "Ask me for more information so you can answer more accurately."
                            print("[RAG][Gate] on-topic \(pct)% -> ask for more info")
                        } else {
                            // Low confidence — redirect to course material
                            overrideSysPrompt = SYSTEM_PROMPT
                            effectiveQuestion = "Ask me to focus on the active course material."
                            print("[RAG][Gate] on-topic \(pct)% -> redirect")
                        }
                    }
                } else {
                    // No classifier yet — allow RAG if the cache is ready
                    allowRAG = isRAGReady
                }

                let sysPrompt = overrideSysPrompt ?? SYSTEM_PROMPT
                let isOnTopic = (topicLabel == nil) || (topicLabel == "1")

                // RAG retrieval — find the top 3 most similar chunks to the query
                var topChunks: [String] = []
                if isOnTopic && allowRAG {
                    // Wait briefly if the RAG cache is still being built
                    let deadline = Date().addingTimeInterval(2.0)
                    while !isRAGReady || cachedChunks.isEmpty {
                        if Date() > deadline { break }
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    if isRAGReady && !cachedChunks.isEmpty && !cachedChunkEmbeddings.isEmpty {
                        if let qEmbArr = try? await embedChunks([question]), let vec = qEmbArr.first {
                            let ranked = cachedChunkEmbeddings.enumerated()
                                .map { (index: $0.offset, score: dotProduct(vec, $0.element)) }
                                .sorted { $0.score > $1.score }
                                .filter { $0.score >= 0.05 }
                                .prefix(3)
                            topChunks = ranked.map { cachedChunks[$0.index] }
                            print("[RAG] Retrieved \(topChunks.count) chunks")
                        }
                    }
                }

                finalContext = topChunks.joined(separator: "\n---\n")

                // Build the prompt with or without RAG context
                if finalContext.isEmpty {
                    prompt = """
                    <|im_start|> system \(sysPrompt) <|im_end|>
                    <|im_start|> user \(effectiveQuestion) <|im_end|>
                    <|im_start|> assistant
                    """
                } else {
                    prompt = """
                    <|im_start|> system \(sysPrompt) <|im_end|>
                    <|im_start|> user \(effectiveQuestion)

                    Context (top 3):\(finalContext)

                    <|im_end|>
                    <|im_start|> assistant
                    """
                }

                // Stream the response token-by-token, updating the bubble in place
                messages.append("Thinking: ")
                let placeholderIndex = messages.count - 1
                var accumulated = ""

                do {
                    for try await token in session.streamResponse(to: prompt) {
                        accumulated += token
                        messages[placeholderIndex] = "Thinking: " + accumulated
                    }
                    let elapsed = Date().timeIntervalSince(start)
                    messages[placeholderIndex] = "(\(String(format: "%.2f", elapsed))s): " + accumulated
                } catch {
                    let elapsed = Date().timeIntervalSince(start)
                    messages[placeholderIndex] = "Error (\(String(format: "%.2f", elapsed))s): \(error.localizedDescription)"
                }

            } catch {
                let elapsed = Date().timeIntervalSince(start)
                messages.append("Error (\(String(format: "%.2f", elapsed))s): \(error.localizedDescription)")
            }

            // Post-response memory guard
            if currentResidentMemoryBytes() >= threshold {
                resetSessionIfNeeded(reason: "post-response >=100%")
                cachedChunks.removeAll(keepingCapacity: false)
                cachedChunkEmbeddings.removeAll(keepingCapacity: false)
                isRAGReady = false
                if let url = currentRAGPDFURL {
                    Task { [weak self] in await self?.prepareRAGCache(for: url) }
                }
            }

            GPU.set(cacheLimit: 16 * 1024 * 1024)
            isReady = true
        }
    }

    // MARK: - PDF extraction for LoRA training

    // Reads the uploaded PDF, tokenizes it into sentences, and writes train.jsonl + valid.jsonl
    func extractPDFToJsonLines(from url: URL) async {
        do {
            guard let document = PDFDocument(url: url) else {
                print("Failed to load PDF")
                return
            }

            var allText = ""
            for i in 0..<document.pageCount {
                if let page = document.page(at: i), let text = page.string {
                    allText += text + "\n"
                }
            }

            let tokenizer = NLTokenizer(unit: .sentence)
            tokenizer.string = allText
            var lines: [String] = []
            tokenizer.enumerateTokens(in: allText.startIndex..<allText.endIndex) { range, _ in
                let s = allText[range].trimmingCharacters(in: .whitespacesAndNewlines)
                if !s.isEmpty { lines.append(s) }
                return true
            }
            // Filter out very short or very long lines that won't help training
            lines = lines.filter { $0.count >= 10 && $0.count <= 1000 }

            let encoder = JSONEncoder()
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            // Wrap each sentence in chat tokens and encode as a JSONL record
            let jsonlLines = lines.map { chunk -> String in
                let wrapped = "<|im_start|>\(chunk)<|im_end|>"
                let data = try! encoder.encode(["text": wrapped])
                return String(data: data, encoding: .utf8)!
            }

            // 80 / 20 train–validation split
            let split = Int(Double(jsonlLines.count) * 0.8)
            let trainURL = docs.appendingPathComponent("train.jsonl")
            let validURL = docs.appendingPathComponent("valid.jsonl")
            try? FileManager.default.removeItem(at: trainURL)
            try? FileManager.default.removeItem(at: validURL)
            try jsonlLines[..<split].joined(separator: "\n").write(to: trainURL, atomically: true, encoding: .utf8)
            try jsonlLines[split...].joined(separator: "\n").write(to: validURL, atomically: true, encoding: .utf8)

            print("Wrote \(split) training and \(jsonlLines.count - split) validation examples.")
            await MainActor.run { didFinishExtraction = true }
        } catch {
            print("extractPDFToJsonLines error: \(error)")
        }
    }

    // MARK: - Sentence extraction for classifier training

    // Produces clean, normalized sentences from a PDF to use as on-topic positive examples
    func extractPDFSentences(from url: URL) async -> [String] {
        guard let document = PDFDocument(url: url) else { return [] }

        var allText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let text = page.string {
                allText += text + "\n"
            }
        }

        // Clean and fix hyphenated line breaks before tokenizing
        let cleaned = cleanText(allText)
            .replacingOccurrences(of: "-\\s+([a-zA-Z])", with: "$1", options: .regularExpression)

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = cleaned

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: cleaned.startIndex..<cleaned.endIndex) { range, _ in
            var s = cleaned[range].trimmingCharacters(in: .whitespacesAndNewlines)
            guard s.count >= 15 else { return true }
            // Skip all-caps headings
            guard s.range(of: #"^[A-Z\s]{6,}$"#, options: .regularExpression) == nil else { return true }
            // Normalize for classifier training
            s = s.lowercased()
                .replacingOccurrences(of: #"[\p{P}&&[^'.]]"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let wordCount = s.split(separator: " ").count
            guard wordCount >= 4, wordCount <= 40 else { return true }
            sentences.append(s)
            return true
        }

        // Deduplicate while preserving order
        var seen = Set<String>()
        return sentences.filter { seen.insert($0).inserted }
    }

    // MARK: - Off-topic examples loader

    // Loads negative training examples from the bundled off_topic.csv
    private func loadOffTopicPromptsFromBundle() -> [String] {
        guard let url = Bundle.main.url(forResource: "off_topic", withExtension: "csv") else {
            print("[Classifier] off_topic.csv not found in bundle")
            return []
        }
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let lines = contents.split(whereSeparator: \.isNewline)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            // Skip header row if present
            if let first = lines.first, first.lowercased() == "text" { return Array(lines.dropFirst()) }
            return lines
        } catch {
            print("[Classifier] Failed to read off_topic.csv: \(error)")
            return []
        }
    }

    // MARK: - Classifier training entry point

    // Trains a topic classifier using sentences from the current PDF as positive examples
    func trainClassifierForCurrentPDF(courseKey: String) async {
        guard let pdfURL = currentRAGPDFURL else {
            print("[Classifier] No PDF set")
            return
        }
        // Key off the PDF filename so the classifier folder is stable regardless of display name
        let key = pdfURL.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        let onTopic  = await extractPDFSentences(from: pdfURL)
        let offTopic = loadOffTopicPromptsFromBundle()

        #if canImport(CreateML)
        await trainClassifierForCourse(courseKey: key, onTopic: onTopic, offTopic: offTopic)
        #else
        print("[Classifier] CreateML unavailable on this platform — skipping")
        #endif
    }

    // Converts a raw/display course key into the stable filesystem-safe key used for folder names
    private func stableCourseKey(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // For adapter-tagged courses, use the PDF filename so the folder key is always stable
        if trimmed.hasPrefix("New Course:"), let pdfURL = currentRAGPDFURL {
            let base = pdfURL.deletingPathExtension().lastPathComponent
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !base.isEmpty { return base }
        }
        var s = trimmed
        if s.hasPrefix("New Course:") {
            s = String(s.dropFirst("New Course:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return s.isEmpty ? "default" : s
    }

    // MARK: - CreateML classifier (guarded — only compiled where CreateML is available)

    #if canImport(CreateML)
    func trainClassifierForCourse(courseKey: String, onTopic: [String], offTopic: [String]) async {
        let cleanOn  = onTopic.map  { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.count >= 10 }
        let cleanOff = offTopic.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.count >= 5 }

        guard cleanOn.count >= 20, cleanOff.count >= 50 else {
            print("[Classifier] Not enough data — need ≥20 on-topic, ≥50 off-topic sentences")
            return
        }

        let key    = stableCourseKey(courseKey)
        let outDir = classifierDir(for: key)

        do {
            // Run training off the main thread — it's CPU-heavy
            let (classifier, finalURL) = try await Task.detached(priority: .userInitiated) { () throws -> (MLTextClassifier, URL) in
                let texts  = cleanOn + cleanOff
                let labels = Array(repeating: "1", count: cleanOn.count) + Array(repeating: "0", count: cleanOff.count)
                let table  = try MLDataTable(dictionary: ["text": texts, "label": labels])

                var params = MLTextClassifier.ModelParameters(
                    validation: .split(strategy: .fixed(ratio: 0.1, seed: 42)),
                    algorithm: .maxEnt(revision: 1),
                    language: .english
                )
                params.maxIterations = 20

                let cls         = try MLTextClassifier(trainingData: table, textColumn: "text", labelColumn: "label", parameters: params)
                let modelURL    = outDir.appendingPathComponent("TopicClassifier.mlmodel")
                try cls.write(to: modelURL)
                let compiled    = try MLModel.compileModel(at: modelURL)
                let destination = outDir.appendingPathComponent("TopicClassifier.mlmodelc", isDirectory: true)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try? FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: compiled, to: destination)
                try? FileManager.default.removeItem(at: modelURL)
                return (cls, destination)
            }.value

            await MainActor.run {
                activeTextClassifier = classifier
                activeCourseKey      = key
                activeClassifierURL  = finalURL
                classifierCache.removeValue(forKey: classifierCacheKeyForCourse(key))
            }
            print("[Classifier] ✅ Saved at:", (await MainActor.run { activeClassifierURL?.path ?? "" }))
        } catch {
            print("[Classifier] ❌ Failed:", error)
        }
    }
    #endif

    // MARK: - LoRA training entry point

    // Public entry — called from the UI when the user taps "Save Course"
    func trainFromCurrentPDF() {
        guard let url = currentRAGPDFURL else {
            print("No PDF set. Upload a PDF before training.")
            return
        }
        Task { await trainFromPDF(url: url) }
    }

    private func trainFromPDF(url: URL) async {
        await MainActor.run {
            isTraining = true
            trainingProgress = nil
            didFinishExtraction = false
        }

        // Step 1 — extract PDF sentences into train.jsonl + valid.jsonl
        await extractPDFToJsonLines(from: url)

        let docs     = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trainURL = docs.appendingPathComponent("train.jsonl")
        let validURL = docs.appendingPathComponent("valid.jsonl")
        let testURL  = docs.appendingPathComponent("test.jsonl")

        // Step 2 — run LoRA fine-tuning on the base model
        do {
            try await trainLocallyWithLoRA(trainURL: trainURL, validURL: validURL, testURL: testURL)
        } catch {
            print("Training failed: \(error)")
        }

        await MainActor.run {
            isTraining = false
            trainingProgress = nil
        }
    }

    // Loads a fresh GENERAL.2 container each run so courses never stack on top of each other
    private func loadTrainingModelContainer() async throws -> MLXLMCommon.ModelContainer {
        let config = LLMModelFactory.shared.configuration(id: "ShukraJaliya/GENERAL.2")
        return try await LLMModelFactory.shared.loadContainer(hub: HubApi(), configuration: config) { prog in
            Task { @MainActor in self.modelLoadProgress = prog }
        }
    }

    private func loadLoRAData(from url: URL) throws -> [String] {
        try MLXLLM.loadLoRAData(url: url)
    }

    // MARK: - LoRA fine-tuning

    private func trainLocallyWithLoRA(trainURL: URL, validURL: URL, testURL: URL?) async throws {
        GPU.set(cacheLimit: 32 * 1024 * 1024)

        // Fresh container per run — LoRA weights from previous courses are not carried over
        let modelContainer = try await loadTrainingModelContainer()
        modelContainerForTraining = modelContainer

        // Inject LoRA adapter layers (mutates the model in-place)
        _ = try await modelContainer.perform { context in
            try LoRAContainer.from(model: context.model, configuration: LoRAConfiguration(numLayers: loraLayers))
        }

        let train = try loadLoRAData(from: trainURL)
        let valid = try loadLoRAData(from: validURL)
        print("Train examples: \(train.count), Valid: \(valid.count)")

        try await modelContainer.perform { context in
            let optimizer  = Adam(learningRate: self.learningRate)
            let totalIter  = self.trainingEpochs * self.iterationsPerEpoch
            let params     = LoRATrain.Parameters(batchSize: 1, iterations: totalIter)

            try LoRATrain.train(
                model: context.model,
                train: train,
                validate: valid,
                optimizer: optimizer,
                tokenizer: context.tokenizer,
                parameters: params
            ) { progress in
                Task { @MainActor in
                    if case .train(let i, _, _, _) = progress {
                        self.trainingProgress = Double(i) / Double(totalIter)
                        // Announce each new epoch in the chat log
                        if i % self.iterationsPerEpoch == 0 {
                            let epoch = max(0, i / self.iterationsPerEpoch)
                            self.messages.append("Started epoch \(epoch + 1)/\(self.trainingEpochs)")
                        }
                    }
                }
                return .more
            }
        }

        // Evaluate on test set if it exists
        if let testURL, FileManager.default.fileExists(atPath: testURL.path) {
            let test = try loadLoRAData(from: testURL)
            let loss = await modelContainer.perform { context in
                LoRATrain.evaluate(model: context.model, dataset: test, tokenizer: context.tokenizer, batchSize: 1, batchCount: 0)
            }
            await MainActor.run { messages.append("Training complete. Test loss \(loss.formatted())") }
        } else {
            await MainActor.run { messages.append("Training complete.") }
        }
    }

    // MARK: - In-memory adapter management

    // Stores trained containers keyed by the user-provided adapter name
    @Published var inMemoryAdapters: [String: MLXLMCommon.ModelContainer] = [:]

    // Saves the most recently trained container under a user-given name
    func saveInMemoryAdapter(named name: String) {
        guard let container = modelContainerForTraining else {
            print("[LoRA] No trained container to save")
            return
        }
        inMemoryAdapters[name] = container
        print("[LoRA] Saved adapter: \(name)")
    }

    // Switches the active chat session to the named in-memory adapter — enables chat
    @MainActor
    func applyInMemoryAdapter(named name: String) async {
        guard let container = inMemoryAdapters[name] else {
            print("[LoRA] No adapter named \(name)")
            return
        }
        let instructions = SYSTEM_PROMPT_RAG
        let params = GenerateParameters(maxTokens: currentPreset.genMaxTokens, temperature: 0.4, topP: 0.9)

        sessionInstructions = instructions
        sessionParameters   = params
        session             = ChatSession(container, instructions: instructions, generateParameters: params)
        isAdapterActive     = true
        isReady             = true  // chat is now enabled
        GPU.set(cacheLimit: 16 * 1024 * 1024)

        messages.append("Applied in-memory course: \(name)")
        print("[LoRA] Applied adapter: \(name)")
    }

    // Removes a named adapter; disables chat if the removed adapter was the active one
    func deleteInMemoryAdapter(named name: String) {
        if inMemoryAdapters.removeValue(forKey: name) != nil {
            print("[LoRA] Removed adapter: \(name)")
            Task { @MainActor in messages.append("Deleted in-memory course: \(name)") }
        }
        if isAdapterActive {
            isAdapterActive = false
            isReady         = false
            session         = nil
        }
    }

    // MARK: - Idle cleanup

    // Frees RAG caches when the app is idle to relieve memory pressure
    func didBecomeIdle() {
        cachedChunks.removeAll(keepingCapacity: false)
        cachedChunkEmbeddings.removeAll(keepingCapacity: false)
        isRAGReady = false
        GPU.set(cacheLimit: 8 * 1024 * 1024)
        print("[Idle] Cleared RAG caches")
        if let url = currentRAGPDFURL {
            Task { [weak self] in await self?.prepareRAGCache(for: url) }
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

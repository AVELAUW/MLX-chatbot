//
//  ContentView.swift
//  MLX-chatbot
//
//  Created by AVELA Student on 2/23/26.
// giving a trial
//  ─────────────────────────────────────────────────────────────
//  THINGS YOU CAN CUSTOMISE IN THIS FILE:
//    1. The app's colour scheme         → search "suggestedQuestions"
//    2. The starter questions on screen → search "suggestedQuestions"
//    3. Welcome message text            → search "welcomeView"
//    4. The app navigation title        → search "navigationTitle"
//  ─────────────────────────────────────────────────────────────


// Paste this in terminal
//   python3 ~/Documents/GitHub/MLX-chatbot/train_qwen_lora.py

import SwiftUI

// ─────────────────────────────────────────────────────────────
// COLOUR HELPER — use Color(hex: "#RRGGBB") anywhere below
// ─────────────────────────────────────────────────────────────
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// ─────────────────────────────────────────────────────────────
// CONTENT VIEW
// ─────────────────────────────────────────────────────────────
struct ContentView: View {

    @StateObject private var vm = ChatViewModel()
    @State private var showResetConfirm = false

    // ★ Edit these questions to match your course content
    private let suggestedQuestions = [
        "What is data activism?"
    ]

    var body: some View {
        NavigationStack {
            homeView
        }
        .confirmationDialog("Reset Model?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete Model & Adapters", role: .destructive) { vm.reset() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This deletes the trained model and adapters. You will need to run train_qwen_lora.py again before using the app.")
        }
    }

    // MARK: - Home

    private var homeView: some View {
        VStack(spacing: 0) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 84, height: 84)
                .shadow(radius: 8)
                .padding(.top, 24)

            if vm.messages.isEmpty {
                welcomeView
            } else {
                messagesView
            }

            inputView
        }
        .navigationTitle("AVELA-CourseSLM")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reset Model", systemImage: "arrow.counterclockwise")
                }
                .disabled(vm.isModelLoading)
            }
        }
        .overlay(modelLoadingOverlay)
    }

    // MARK: - Welcome screen (shown before first message)

    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                Text("Welcome to AVELA AI")
                    .font(.largeTitle.bold())
                // ★ Edit this subtitle to describe your course
                Text("Click to learn about data activism.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Suggested question chips
                HStack(spacing: 12) {
                    ForEach(suggestedQuestions, id: \.self) { question in
                        Button(action: {
                            vm.input = question
                            vm.send()
                        }) {
                            Text(question)
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 30))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(question)
                    }
                }
                .padding(.vertical)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Messages list

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(vm.messages.enumerated()), id: \.offset) { index, message in
                        MessageBubble(message: message)
                            .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: vm.messages.count) { _, _ in
                if let lastIndex = vm.messages.indices.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input bar

    private var inputView: some View {
        ZStack {
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .top, spacing: 16) {
                    TextField("Type a message...", text: $vm.input, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(minHeight: 120, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: 28).fill(Color.gray.opacity(0.1)))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.gray.opacity(0.3), lineWidth: 1.5))
                        .lineLimit(1...12)
                        .disabled(!vm.isReady)

                    Button("Send") { vm.send() }
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .padding(.top, 20)
                        .disabled(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !vm.isReady)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

            }
#if os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
#else
            .background(Color(.systemBackground))
#endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 8)
    }

    // MARK: - Model loading overlay

    private var modelLoadingOverlay: some View {
        Group {
            if vm.isModelLoading {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .shadow(radius: 10)

                        if let progress = vm.modelLoadProgress {
                            VStack(spacing: 12) {
                                Text("Loading Course...")
                                    .font(.title3.bold())
                                ProgressView(value: progress.fractionCompleted) {
                                    Text("\(Int(progress.fractionCompleted * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                                .tint(.blue)
                            }
                        } else {
                            VStack(spacing: 12) {
                                Text("Loading Course...")
                                    .font(.title3.bold())
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.2)
                            }
                        }

                        Text("Please wait...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.3), radius: 20)
                    )
                }
                .transition(.opacity)
                .animation(.easeInOut, value: vm.isModelLoading)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────
struct MessageBubble: View {
    let message: String

    private var isUser: Bool { message.starts(with: "You:") }

    private var displayText: String {
        if isUser { return String(message.dropFirst(4)) }
        if message.starts(with: "Bot:") { return String(message.dropFirst(4)) }
        return message
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer(minLength: 60)
                Text(displayText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue))
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.gray).frame(width: 36, height: 36))
                    .frame(width: 36, height: 36)
            } else {
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .background(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                Text(displayText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.gray.opacity(0.2)))
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    ContentView()
}

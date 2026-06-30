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

    // helper function
    // returns the instance of whatever model is currently there. so isntead of witing out the if statement where the current model is being needed
    private var boundModel: Binding<String> {
        Binding(
            get: {
                if let sessionID = selectedSessionID,
                   let session = ChatUISessions.first(where: { $0.id == sessionID }) {
                    return session.model
                }
                return selectedModel
            },
            set: { newValue in
                selectedModel = newValue
                if let sessionID = selectedSessionID,
                   let index = ChatUISessions.firstIndex(where: { $0.id == sessionID }) {
                    ChatUISessions[index].model = newValue
                }
            }
        )
    }

    // hepler funtion
    // trims the first 5 characters
    // gets the index where the suggested question is located in the array
    private func starterColorIndex(for message: String) -> Int? {
        let text: String
        if message.hasPrefix("You: ") {
            text = String(message.dropFirst(5))
        } else {
            text = message
        }

        if let idx = suggestedQuestions.firstIndex(of: text) {
            return idx
        }
        return nil
    }

    // used to clean names for new courses
    func cleanCourseName(_ name: String) -> String {
        name.hasPrefix("New Course:") ? String(name.dropFirst("New Course:".count)) : name
    }

    // Returns the user-facing display name for a model ID — checks custom options first, then built-ins
    func displayNameFor(_ id: String) -> String {
        if let alias = customModelOptions.first(where: { $0.id == id })?.name { return alias }
        return nameFor(id)
    }

    // NavigationStack inside Home would let you go deeper within Home, like: multple screens in one tab
    var body: some View {
        TabView {
            NavigationStack {
                homeView
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                modelPickerView
                    .navigationTitle("Course Selection")
            }
            .tabItem {
                Label("Select Course", systemImage: "cpu")
            }

            historyView
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            NavigationStack {
                settingsView
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        // makes the View justsize depending on the UI
        .tabViewStyle(.sidebarAdaptable)
        // males sure there is session running to prevent dupliates. there must always be a session to interact with
        .onAppear {
            // Inserts the new session at the top of the sessions list.
            // Sets selectedSessionID to the new session's ID (so the UI points to it).
            // Clears the view model input and messages (vm.messages = [], vm.input = "").

            if ChatUISessions.isEmpty {
                let initialAlias = selectedCourseKey.isEmpty ? displayNameFor(selectedModel) : selectedCourseKey
                let newSession = ChatUISession(
                    id: UUID(),
                    model: selectedModel,
                    messages: [],
                    created: Date(),
                    alias: initialAlias
                )

                ChatUISessions.insert(newSession, at: 0)
                selectedSessionID = newSession.id
                vm.messages = []
                vm.input = ""
                selectedCourseKey = newSession.alias

                // IMPORTANT: set active course so correct classifier is used (or fallback)
                vm.setActiveCourse(selectedCourseKey)
            }
        }
        // when model changes
        // new session is created
        // clears out messages and puts in new chat session messgaes

        .onChange(of: selectedSessionID) { newValue in
            guard let sessionID = newValue,
                  let session = ChatUISessions.first(where: { $0.id == sessionID }) else {
                vm.messages = []
                vm.input = ""
                return
            }

            vm.messages = session.messages
            selectedModel = session.model
            selectedCourseKey = session.alias

            // makes sure there is a classifier
            // IMPORTANT: switching courses unloads old classifier from memory + loads correct one
            // 1) Apply the PDF first (sets vm.currentRAGPDFURL)
            applyRAGForCurrentCourse()

            // 2) Now activate course (stable key can use PDF filename)
            vm.setActiveCourse(selectedCourseKey)
        }
        // new time and date as well
        .onChange(of: vm.isReady) { newValue in
            if !newValue {
                thinkingStartDate = Date()
            } else {
                thinkingStartDate = nil
                thinkingElapsed = 0
            }
        }
        .confirmationDialog("Reset Model?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete Model & Adapters", role: .destructive) { vm.reset() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This deletes the trained model and adapters. You will need to run train_qwen_lora.py again before using the app.")
        }
    }
    private var homeView: some View {
        VStack(spacing: 0) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 84, height: 84)
                .shadow(radius: 8)
                .padding(.top, 24)

            HStack(spacing: 16) {
                Button(action: {
                    let initialAlias = selectedCourseKey.isEmpty ? displayNameFor(selectedModel) : selectedCourseKey
                    let newSession = ChatUISession(
                        id: UUID(),
                        model: selectedModel,
                        messages: [],
                        created: Date(),
                        alias: initialAlias
                    )
                    ChatUISessions.insert(newSession, at: 0)
                    selectedSessionID = newSession.id
                    vm.messages = []
                    vm.input = ""

                    // switching session => activate the classifier for that course
                    vm.setActiveCourse(initialAlias)
                }) {
                    Label("New Chat", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .padding([.top, .horizontal])
            Text("Active course: \(cleanCourseName((ChatUISessions.first(where: { $0.id == selectedSessionID })?.alias ?? (selectedCourseKey.isEmpty ? displayNameFor(selectedModel) : selectedCourseKey))))")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 4)
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
            let starterOffset: Int = {
                guard let first = vm.messages.first,
                      let idx = starterColorIndex(for: first) else {
                    return 0
                }
                return idx
            }()

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

                if !vm.isReady {
                    Text("Thinking for \(thinkingElapsed) second(s)...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
    // MARK: - History View
    private var historyView: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        let initialAlias = selectedCourseKey.isEmpty ? displayNameFor(selectedModel) : selectedCourseKey
                        let newSession = ChatUISession(
                            id: UUID(),
                            model: selectedModel,
                            messages: [],
                            created: Date(),
                            alias: initialAlias
                        )
                        ChatUISessions.insert(newSession, at: 0)
                        selectedSessionID = newSession.id
                        vm.messages = []
                        vm.input = ""
                        vm.setActiveCourse(initialAlias)
                    }) {
                        Label("New Chat", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(RoundedRectangle(cornerRadius: 30))

                    Picker("Alias", selection: $historyFilterAlias) {
                        Text("All Aliases").tag("")
                        ForEach(Array(Set(ChatUISessions.map { $0.alias })).sorted(), id: \.self) { alias in
                            Text(alias).tag(alias)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding([.top, .horizontal])

                Section(header: Text(historyFilterAlias.isEmpty ? "All Sessions" : historyFilterAlias)) {
                    ForEach(ChatUISessions.filter { historyFilterAlias.isEmpty ? true : $0.alias == historyFilterAlias }.prefix(5)) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                selectedSessionID = session.id
                                vm.messages = session.messages
                                selectedModel = session.model
                                selectedCourseKey = session.alias
                                vm.setActiveCourse(selectedCourseKey)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.alias)
                                        .font(.headline)
                                    if let lastMessage = session.messages.last {
                                        Text(lastMessage)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    } else {
                                        Text("No messages yet")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(session.created, style: .relative)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("History")
        }
    }
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
        let colorIndex: Int
        let palette: [Color]

        private var isUser: Bool {
            message.starts(with: "You:")
        }

        private var displayText: String {
            if isUser {
                return String(message.dropFirst(4))
            } else if message.starts(with: "Bot:") {
                return String(message.dropFirst(4))
            }
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
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(palette[colorIndex % palette.count])
                        )
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 36, height: 36)
                        )
                        .frame(width: 36, height: 36)
                } else {
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .background(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    Text(displayText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.gray.opacity(0.2))
                        )
                    Spacer(minLength: 60)
                }
            }
        }
            }
        }
    }
}

#Preview {
    ContentView()
}

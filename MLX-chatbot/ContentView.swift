//
//  ContentView.swift
//  MLX-chatbot
//
//  Created by AVELA Student on 2/23/26.
//
//  ─────────────────────────────────────────────────────────────
//  WELCOME, STUDENT DEVELOPER!
//
//  This file controls everything you SEE in the app — all the
//  screens, buttons, text, and layouts.
//
//  The AI logic (how the model thinks and trains) lives in
//  ChatView.swift. You don't need to touch that file.
//
//  ★ THINGS YOU CAN CUSTOMISE IN THIS FILE:
//    1. The app's colour scheme         → search "suggestedQuestions"
//    2. The starter questions on screen → search "suggestedQuestions"
//    3. The built-in course names       → search "modelOptions"
//    4. Welcome message text            → search "welcomeView"
//    5. Settings labels & version       → search "settingsView"
//    6. The app navigation title        → search "navigationTitle"
//  ─────────────────────────────────────────────────────────────

import SwiftUI
import Combine          // needed for Timer (the "thinking" counter)
import UniformTypeIdentifiers  // needed for drag-and-drop PDF support

// ─────────────────────────────────────────────────────────────
// COLOUR HELPER
// SwiftUI normally only accepts colours by name (e.g. .blue, .red).
// This extension lets you use standard hex codes like "#FF5733" instead,
// which makes it much easier to match a school's brand colours.
// You don't need to change anything here — just use Color(hex: "#RRGGBB")
// anywhere in the file to set a custom colour.
// ─────────────────────────────────────────────────────────────
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch hex.count {
        case 3:
            (a, r, g, b) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ─────────────────────────────────────────────────────────────
// CHAT SESSION
// A "session" is one conversation — like opening a new chat window.
// Each session remembers which course was active, all the messages
// that were sent, and when it was created.
// The app can hold many sessions at once (shown in the History tab).
// ─────────────────────────────────────────────────────────────
struct ChatUISession: Identifiable {
    let id: UUID            // unique ID so the app never confuses two sessions
    var model: String       // which AI course was loaded for this session
    var messages: [String]  // every message sent and received, in order
    let created: Date       // timestamp — shown in the History tab
    var alias: String       // the friendly course name shown to the user
}

// Mapping, giviing models aliases
struct ModelOption {
    let id: String
    let name: String
}

// Map backend IDs to user-friendly names
let modelOptions: [ModelOption] = [
    ModelOption(id: "ShukraJaliya/GENERAL.2", name: "General Course1")
]

// Helper to get a display name for a model ID. helps to use aliases
func nameFor(_ id: String) -> String {
    modelOptions.first(where: { $0.id == id })?.name ?? id
}

struct ContentView: View {
    //  @StateObject private var vm = MLX_chatbotApp()
    
    // upon launching this presets model to this model
    @State private var selectedModel: String = "ShukraJaliya/GENERAL.2"
    // Keeps an array of all chat sessions the user has started
    @State private var ChatUISessions: [ChatUISession] = []
    // Keeps track of which specific chat session is currently active (by its unique ID).
    @State private var selectedSessionID: UUID? = nil
    // Lets you filter chat session history by the alias
    @State private var historyFilterAlias: String = ""
    
    // The ViewModel that owns all AI logic — created once and lives for the lifetime of ContentView
    @StateObject private var vm = ChatViewModel()
    
    // User-created courses added via training (separate from the built-in modelOptions list)
    @State private var customModelOptions: [ModelOption] = []
    
    @State private var thinkingStartDate: Date? = nil
    @State private var thinkingElapsed: Int = 0
    
    // flag that tracks whether the “Save Adapter” sheet (a popup or modal dialog) should be shown in the UI.
    @State private var showSaveAdapterSheet = false
    // string that holds the name of the new adaptors
    @State private var newAdapterName: String = ""
    
    // flag that alerts the  system’s file browser), letting the user select a PDF. to pull
    @State private var showPDFImporter = false
    // stores name of selected pdf
    @State private var selectedPDFName: String? = nil
    // Used to visually highlight the drop area when a file is being dragged over it.
    @State private var isDropTargeted: Bool = false
    // holds users given names
    @State private var newCourseName: String = ""
    // Represents the currently selected or active course (alias)(frontend)
    @State private var selectedCourseKey: String = ""
    // Maps course keys (identifiers/names) to PDF file URLs, so each course knows which PDF is associated with it.
    // Used to retrieve the correct PDF when switching courses or for retrieval-augmented generation (RAG).
    @State private var ragByCourse: [String: URL] = [:]
    
    // devs can chnage what questions they would like to appear depending on the app
    private let suggestedQuestions = [
        "What is data activism?"
        // ?
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
            // Sets selectedSessionID to the new session’s ID (so the UI points to it).
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
    }
    
    // MARK: - Model Picker View
    // this is completely for the looks and some interactions
    
    private var modelPickerView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 84, height: 84)
                        .shadow(radius: 8)
                        .padding(.top, 20)
                    
                    // Use adaptive layout based on available width
                    if geometry.size.width > 700 {
                        // Wide layout (iPad landscape, Mac)
                        HStack(alignment: .top, spacing: 24) {
                            courseSelectionSection
                                .frame(maxWidth: .infinity)
                            
                            courseUploaderMiniView
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 32)
                    } else {
                        // Narrow layout (iPhone, iPad portrait)
                        VStack(spacing: 32) {
                            courseSelectionSection
                            courseUploaderMiniView
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
#if os(iOS)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    hideKeyboard()
                }
            )
#endif
        }
        .navigationTitle("Course Selection")
    }

    // MARK: - Course Selection Section
    private var courseSelectionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text("Select course")
                    .font(.title2.bold())
                Text("Choose an AI model for your conversation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                // if alias is empty display the anme for the boundmodel
                Text(selectedCourseKey.isEmpty ? displayNameFor(boundModel.wrappedValue) : selectedCourseKey)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Picker("", selection: boundModel) {
                    // 1) Built-in courses
                    ForEach(modelOptions, id: \.id) { option in
                        Text(option.name).tag(option.id)
                    }
                    
                    // 2) User-added aliases (saved PDFs)
                    ForEach(customModelOptions, id: \.id) { option in
                        Text(option.name).tag(option.id)
                    }
                    
                    // 3) In-memory adapters
                    ForEach(vm.inMemoryAdapters.keys.sorted(), id: \.self) { name in
                        Text(name).tag("New Course:\(name)")
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 300)
                .onChange(of: boundModel.wrappedValue) { newModelID in
                    if newModelID.hasPrefix("New Course:") {
                        let adapterName = String(newModelID.dropFirst("New Course:".count))
                        
                        // 1) Force base model before applying any adapter
                        let baseModelID = "ShukraJaliya/GENERAL.2"
                        if selectedModel != baseModelID {
                            selectedModel = baseModelID
                        }
                        
                        // 2) Apply in-memory adapter on top of the forced base
                        Task { @MainActor in
                            vm.isModelLoading = true
                            await vm.applyInMemoryAdapter(named: adapterName)
                            vm.isModelLoading = false
                        }
                        
                        // 3) Reflect adapter selection in UI and session
                        let adapterTag = "New Course:\(adapterName)"
                        selectedModel = adapterTag
                        selectedCourseKey = adapterTag
                        
                        // 1) apply PDF first (sets vm.currentRAGPDFURL)
                        applyRAGForCurrentCourse()
                        
                        // 2) then activate (stable key uses PDF filename)
                        vm.setActiveCourse(selectedCourseKey)
                        
                        if let sessionID = selectedSessionID,
                           let index = ChatUISessions.firstIndex(where: { $0.id == sessionID }) {
                            ChatUISessions[index].alias = selectedCourseKey
                            ChatUISessions[index].model = adapterTag
                        }
                    } else {
                        // Non-adapter selection: normal model switch
                        selectedModel = newModelID
                        selectedCourseKey = displayNameFor(newModelID)
                        
                        // It finds the currently selected session in your sessions array and updates that session’s metadata (alias and model) to reflect the new selection.
                        if let sessionID = selectedSessionID,
                           let index = ChatUISessions.firstIndex(where: { $0.id == sessionID }) {
                            ChatUISessions[index].alias = selectedCourseKey
                            ChatUISessions[index].model = newModelID
                        }
                    }
                }
                
                if boundModel.wrappedValue.hasPrefix("New Course:") {
                    Button(role: .destructive) {
                        let adapterName = String(boundModel.wrappedValue.dropFirst("New Course:".count))
                        vm.deleteInMemoryAdapter(named: adapterName)
                    } label: {
                        Label("Delete Course", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - File persistence (Option A)
    
    // Copy a user-selected PDF into Application Support/Courses and return its new URL.
    // - Creates the Courses directory if needed
    // - Handles security-scoped access (iOS/visionOS)
    // - Avoids filename collisions by appending a timestamp
    // - Returns nil on failure
    private func copyPDFIntoAppSupport(from sourceURL: URL) -> URL? {
        do {
            // File manager for filesystem operations (create dir, copy, existence checks)
            let fm = FileManager.default
            // Locate (and create if needed) the Application Support directory for this app (sandboxed)
            let appSupport = try fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            // Create a "Courses" subdirectory inside Application Support to store PDFs
            let coursesDir = appSupport.appendingPathComponent("Courses", isDirectory: true)
            if !fm.fileExists(atPath: coursesDir.path) {
                try fm.createDirectory(at: coursesDir, withIntermediateDirectories: true)
            }
            
            // Build a destination filename based on the original, preserving extension
            let originalName = sourceURL.lastPathComponent
            let base = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension.isEmpty ? "pdf" : sourceURL.pathExtension
            
            // If a file with the same name already exists, append a timestamp to avoid overwriting
            var dest = coursesDir.appendingPathComponent(originalName)
            if fm.fileExists(atPath: dest.path) {
                let stamp = ISO8601DateFormatter()
                    .string(from: Date())
                    .replacingOccurrences(of: ":", with: "-")
                dest = coursesDir.appendingPathComponent("\(base)_\(stamp).\(ext)")
            }
            
            // Perform copy (overwrite is already handled by unique name)
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: sourceURL, to: dest)
            return dest
        } catch {
            print("copyPDFIntoAppSupport error: \(error)")
            return nil
        }
    }
    
    private func applyRAGForCurrentCourse() {
        // Adapter-only RAG behavior across all platforms:
        // Only apply RAG for adapter-tagged courses ("New Course:...").
        guard selectedCourseKey.hasPrefix("New Course:") else {
            selectedPDFName = nil
            vm.currentRAGPDFURL = nil
            print("Adapter RAG: skipped (non-adapter course \(selectedCourseKey))")
            return
        }
        
        if let url = ragByCourse[selectedCourseKey],
           FileManager.default.fileExists(atPath: url.path) {
            vm.setRAGPDF(url: url)
            selectedPDFName = url.lastPathComponent
            print("RAG: applied \(url.lastPathComponent) for course \(selectedCourseKey)")
        } else {
            selectedPDFName = nil
            vm.currentRAGPDFURL = nil
            print("RAG: no PDF for adapter \(selectedCourseKey) — cleared")
        }
    }
    
    // MARK: - Upload + Save
    private var courseUploaderMiniView: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Upload Course PDF")
                .font(.headline)
            
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDropTargeted ? Color.blue.opacity(0.15) : Color.gray.opacity(0.12))
                .frame(maxWidth: 400, minHeight: 160, maxHeight: 200)
                .overlay {
                    VStack(spacing: 8) {
                        if let name = selectedPDFName {
                            Text(name)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, 16)
                        } else {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 36, weight: .regular))
                                .foregroundColor(.secondary)
                            Text("Upload PDF")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showPDFImporter = true
                }
            // dropper handling the file type
                .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
                    guard let provider = providers.first else { return false }
                    provider.loadItem(
                        forTypeIdentifier: UTType.fileURL.identifier,
                        options: nil
                    ) { item, error in
                        // throws an error if the type isnt processed
                        if let error = error {
                            print("Drop error: \(error.localizedDescription)")
                            return
                        }
                        
                        // if it is and the file is data
                        if let data = item as? Data,
                           // creates a Url which stores the data using (copyPDF) then applies the different components reprectively
                           let url = URL(dataRepresentation: data, relativeTo: nil) {
                            Task { @MainActor in
                                if let copied = copyPDFIntoAppSupport(from: url) {
                                    // Store per-course and apply
                                    ragByCourse[selectedCourseKey] = copied
                                    vm.setRAGPDF(url: copied)
                                    selectedPDFName = copied.lastPathComponent
                                    print("Picker/Drop: copied to \(copied.path) and assigned to course \(selectedCourseKey)")
                                } else {
                                    // Fallback to original URL if copy fails (still store per-course)
                                    ragByCourse[selectedCourseKey] = url
                                    vm.setRAGPDF(url: url)
                                    selectedPDFName = url.lastPathComponent
                                    print("Picker/Drop: using original file \(url.path) for course \(selectedCourseKey)")
                                }
                            }
                            
                            // does the same if the file type if found to be and actual ur. here it doesnt create a url through it just stores and applies
                        } else if let url = item as? URL {
                            Task { @MainActor in
                                if let copied = copyPDFIntoAppSupport(from: url) {
                                    // Store per-course and apply
                                    ragByCourse[selectedCourseKey] = copied
                                    vm.setRAGPDF(url: copied)
                                    selectedPDFName = copied.lastPathComponent
                                    print("Picker/Drop: copied to \(copied.path) and assigned to course \(selectedCourseKey)")
                                } else {
                                    // Fallback to original URL if copy fails (still store per-course)
                                    ragByCourse[selectedCourseKey] = url
                                    vm.setRAGPDF(url: url)
                                    selectedPDFName = url.lastPathComponent
                                    print("Picker/Drop: using original file \(url.path) for course \(selectedCourseKey)")
                                }
                            }
                        } else {
                            print("Drop: unsupported item \(String(describing: item))")
                        }
                    }
                    return true
                }
            
            // while pdfName is not empty
            VStack(spacing: 8) {
                if selectedPDFName != nil {
                    //  if its not trianing return
                    Button(action: {
                        guard !vm.isTraining else { return }
                        
                        // Derive a friendly course name from the current PDF (or use newCourseName if you set it)
                        guard let pdfURL = vm.currentRAGPDFURL else {
                            print("No PDF URL set; cannot train.")
                            return
                        }
                        
                        // just deletes the extra url extentions stuff and uses that as the course name
                        let defaultName = pdfURL.deletingPathExtension().lastPathComponent
                        // If the user hasn’t typed a custom name (newCourseName is empty), use defaultName (derived from the PDF filename).
                        // Otherwise, use the user-provided newCourseName.
                        let friendlyName = (newCourseName.isEmpty ? defaultName : newCourseName)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !friendlyName.isEmpty else { return }
                        
                        // CLASSIFIER STEP #1: Activate course for classifier routing
                        vm.setActiveCourse(friendlyName)
                        
                        // Kick off your existing unified training (kept as-is)
                        vm.trainFromCurrentPDF()
                        
                        // CLASSIFIER STEP #2: Explicitly train classifier for this course key
                        Task {
                            await vm.trainClassifierForCurrentPDF(courseKey: friendlyName)
                        }
                        
                        // CLASSIFIER STEP #3: Ensure classifier courseKey matches selected alias after
                        vm.setActiveCourse(selectedCourseKey.isEmpty ? "default" : selectedCourseKey)
                    }) {
                        Label(
                            vm.isTraining ? "Training…" : "Save Course",
                            systemImage: vm.isTraining ? "hourglass" : "hammer"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPDFName == nil)
                    
                    // progress bar
                    if vm.isTraining {
                        Text(
                            vm.trainingProgress != nil
                            ? "Training model (LoRA)…"
                            : (vm.didFinishExtraction ? "Preparing training data…" : "Extracting content…")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        if let progress = vm.trainingProgress {
                            VStack(spacing: 6) {
                                ProgressView(value: progress, total: 1.0) {
                                    Text("Progress…")
                                }
                                .frame(width: 200)
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView {
                                Text("Please Wait..")
                            }
                            .frame(width: 200)
                        }
                    }
                }
            }
            // When training finishes, show naming sheet to save adapter
            .onChange(of: vm.isTraining) { isTraining in
                // Transition from training -> not training
                if !isTraining, selectedPDFName != nil {
                    showSaveAdapterSheet = true
                }
            }
        }
        .fileImporter(
            isPresented: $showPDFImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            //in cases of success pdf is proccessed
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { @MainActor in
                        if let copied = copyPDFIntoAppSupport(from: url) {
                            // Store per-course and apply
                            ragByCourse[selectedCourseKey] = copied
                            vm.setRAGPDF(url: copied)
                            selectedPDFName = copied.lastPathComponent
                            print("Picker/Drop: copied to \(copied.path) and assigned to course \(selectedCourseKey)")
                        } else {
                            // Fallback to original URL if copy fails (still store per-course)
                            ragByCourse[selectedCourseKey] = url
                            vm.setRAGPDF(url: url)
                            selectedPDFName = url.lastPathComponent
                            print("Picker/Drop: using original file \(url.path) for course \(selectedCourseKey)")
                        }
                    }
                }
            case .failure(let error):
                print("fileImporter error: \(error.localizedDescription)")
            }
        }
        //pop up screen
        .sheet(isPresented: $showSaveAdapterSheet) {
            NavigationStack {
                Form {
                    Section("Adapter Name") {
                        TextField("e.g. DataActivism_v1", text: $newAdapterName)
                    }
                    
                    Section {
                        //giving adpaotr a name
                        Button("Save") {
                            let name = newAdapterName
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            
                            Task { @MainActor in
                                // 1) Save the adapter in-memory
                                vm.saveInMemoryAdapter(named: name)
                                
                                // 2) Reuse the existing model-loading overlay for adapter apply
                                vm.isModelLoading = true
                                await vm.applyInMemoryAdapter(named: name)
                                
                                // 3.1) Tie the current PDF to this adapter key (if one is set)
                                let adapterKey = "New Course:\(name)"
                                if let currentPDF = vm.currentRAGPDFURL {
                                    ragByCourse[adapterKey] = currentPDF
                                    print("RAG: bound \(currentPDF.lastPathComponent) to \(adapterKey)")
                                }
                                
                                // 3.2) Switch the active course key to the adapter identity so RAG auto-applies
                                selectedCourseKey = adapterKey
                                selectedModel = adapterKey
                                vm.setActiveCourse(selectedCourseKey)
                                applyRAGForCurrentCourse()
                                
                                // Update current session
                                if let sessionID = selectedSessionID,
                                   let index = ChatUISessions.firstIndex(where: { $0.id == sessionID }) {
                                    ChatUISessions[index].alias = selectedCourseKey
                                    ChatUISessions[index].model = adapterKey
                                }
                                
                                // 4) Hide the model-loading overlay
                                vm.isModelLoading = false
                                
                            }
                            //if its emtpty you cannit save
                            newAdapterName = ""
                            showSaveAdapterSheet = false
                        }
                        
                        .disabled(newAdapterName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty)
                        
                        Button("Cancel", role: .cancel) {
                            showSaveAdapterSheet = false
                        }
                    }
                }
                .navigationTitle("Save Course")
            }
        }
    }
    //Visuals mostly
    private var modelLoadingOverlay: some View {
        Group {
            if vm.isModelLoading {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
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
                            .shadow(color: .black.opacity(0.3),
                                    radius: 20)
                    )
                }
                .transition(.opacity)
                .animation(.easeInOut, value: vm.isModelLoading)
            }
        }
    }
    
    private var embeddermodelLoadingOverlay: some View {
        Group {
            if vm.isEmbedModelLoading {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.gradient)
                        
                        if let progress = vm.embedModelProgress {
                            VStack(spacing: 12) {
                                Text("Loading Embedder...")
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
                                Text("Loading Embedder...")
                                    .font(.title3.bold())
                                
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.2)
                            }
                        }
                        
                        Text("Preparing embeddings...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.3),
                                    radius: 20)
                    )
                }
                .transition(.opacity)
                .animation(.easeInOut, value: vm.isEmbedModelLoading)
            }
        }
    }
    
    private var settingsView: some View {
#if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Appearance").font(.title3.bold()).padding(.bottom, 6)
                HStack {
                    Label("Theme", systemImage: "paintbrush")
                    Spacer()
                    Text("System").foregroundColor(.secondary)
                }
                HStack {
                    Label("Text Size", systemImage: "textformat.size")
                    Spacer()
                    Text("Medium").foregroundColor(.secondary)
                }
                Divider()
                
                Text("Behavior").font(.title3.bold()).padding(.bottom, 6)
                HStack {
                    Label("Auto-send on Return", systemImage: "return")
                    Spacer()
                    Toggle("", isOn: .constant(false))
                }
                HStack {
                    Label("Save History", systemImage: "externaldrive")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
                HStack {
                    Label("Smart Suggestions", systemImage: "lightbulb")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
                Divider()
                
                Text("Privacy").font(.title3.bold()).padding(.bottom, 6)
                HStack {
                    Label("Analytics", systemImage: "chart.bar")
                    Spacer()
                    Toggle("", isOn: .constant(false))
                }
                Button(role: .destructive) {
                    // Clear history action
                } label: {
                    Label("Clear All History", systemImage: "trash")
                }
                Divider()
                
                Text("About").font(.title3.bold()).padding(.bottom, 6)
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("2.0.1").foregroundColor(.secondary)
                }
                HStack {
                    Label("Build", systemImage: "hammer")
                    Spacer()
                    Text("2024.08.08").foregroundColor(.secondary)
                }
                Button {
                    // Show licenses
                } label: {
                    Label("Open Source Licenses", systemImage: "doc.text")
                }
            }
            .padding(32)
            .frame(maxWidth: 500)
        }
        .navigationTitle("Settings")
#else
        Form {
            Section("Appearance") {
                HStack {
                    Label("Theme", systemImage: "paintbrush")
                    Spacer()
                    Text("System").foregroundColor(.secondary)
                }
                HStack {
                    Label("Text Size", systemImage: "textformat.size")
                    Spacer()
                    Text("Medium").foregroundColor(.secondary)
                }
            }
            Section("Behavior") {
                HStack {
                    Label("Auto-send on Return", systemImage: "return")
                    Spacer()
                    Toggle("", isOn: .constant(false))
                }
                HStack {
                    Label("Save History", systemImage: "externaldrive")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
                HStack {
                    Label("Smart Suggestions", systemImage: "lightbulb")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
            }
            Section("Privacy") {
                HStack {
                    Label("Analytics", systemImage: "chart.bar")
                    Spacer()
                    Toggle("", isOn: .constant(false))
                }
                Button {
                    // Clear history action
                } label: {
                    Label("Clear All History", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("2.0.1").foregroundColor(.secondary)
                }
                HStack {
                    Label("Build", systemImage: "hammer")
                    Spacer()
                    Text("2024.08.08").foregroundColor(.secondary)
                }
                Button {
                    // Show licenses
                } label: {
                    Label("Open Source Licenses", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("Settings")
#endif
    }
    
    
    // MARK: - Home View
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
        .id(selectedSessionID ?? UUID())
        .navigationTitle("AVELA-CourseSLM")
        .onChange(of: vm.messages) { newMessages in
            guard let sessionID = selectedSessionID,
                  let index = ChatUISessions.firstIndex(where: { $0.id == sessionID }) else {
                return
            }
            ChatUISessions[index].messages = newMessages
        }
        .overlay(modelLoadingOverlay)
        .overlay(embeddermodelLoadingOverlay)
    }
    
    
    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                Text("Welcome to AVELA AI")
                    .font(.largeTitle.bold())
                Text("Click to learn about data activism.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(Array(suggestedQuestions.prefix(3).enumerated()), id: \.element) { (index, question) in
                            Button(action: {
                                vm.input = question
                                vm.send()
                            }) {
                                Text(question)
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 30)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(question)
                        }
                    }
                    HStack(spacing: 12) {
                        ForEach(Array(suggestedQuestions.suffix(2).enumerated()), id: \.element) { (index, question) in
                            Button(action: {
                                vm.input = question
                                vm.send()
                            }) {
                                Text(question)
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 30)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(question)
                        }
                    }
                }
                .padding(.vertical)
            }
            Spacer()
        }
        .padding()
    }
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
                        MessageBubble(message: message,
                                      colorIndex: index + starterOffset,
                                      palette: [Color.blue])
                        .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: vm.messages.count) { _ in
                if let lastIndex = vm.messages.indices.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputView: some View {
        ZStack {
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .top, spacing: 16) {
                    TextField("Type a message...",
                              text: $vm.input,
                              axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .frame(minHeight: 120, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    )
                    .lineLimit(1...12)
                    .disabled(!vm.isReady)
                    
                    Button("Send") {
                        vm.send()
                    }
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
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { _ in
            if let start = thinkingStartDate, !vm.isReady {
                thinkingElapsed = Int(Date().timeIntervalSince(start))
            } else {
                thinkingElapsed = 0
            }
        }
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
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

// Message bubble
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

#Preview {
    ContentView()
}


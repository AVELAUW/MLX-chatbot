//
//  ContentView.swift
//  MLX-chatbot
//
//  Created by AVELA Student on 2/23/26.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// cleaning color hex codes
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

// Keep track of multiple ongoing or past chat sessions.
// Display a list of sessions (using the id for uniqueness).
// Restore or update
struct ChatUISession: Identifiable {
    let id: UUID
    var model: String
    var messages: [String]
    let created: Date
    var alias: String
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
            
            vm.selectModel(selectedModel)
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
                            vm.selectModel(baseModelID)
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
                        vm.selectModel(newModelID)
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
        
        //file importer. system file browsing
        // only acetps pdf
        //no multipple sesyion
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
    
    
}



    
    
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

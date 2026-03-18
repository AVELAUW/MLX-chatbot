//
//  ContentView.swift
//  MLX-chatbot
//
//  Created by AVELA Student on 2/23/26.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers


//cleaning color hex codes
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
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

//Keep track of multiple ongoing or past chat sessions.
//Display a list of sessions (using the id for uniqueness).
//Restore or update
struct ChatUISession: Identifiable {
    let id: UUID
    var model: String
    var messages: [String]
    let created: Date
    var alias: String
}

//Mapping, giviing models aliases
struct ModelOption {
    let id: String
    let name: String
}

// Map backend IDs to user-friendly names
let modelOptions: [ModelOption] = [
    ModelOption(id: "ShukraJaliya/GENERAL.2", name: "General Course1"),
]

// Helper to get a display name for a model ID. helps to use aliases
func nameFor(_ id: String) -> String {
    modelOptions.first(where: { $0.id == id })?.name ?? id
}


struct ContentView: View {
  //  @StateObject private var vm = MLX_chatbotApp()
    
    //upon launching this presets model to this model
    @State private var selectedModel: String = "ShukraJaliya/GENERAL.2"
    //Keeps an array of all chat sessions the user has started
    @State private var ChatUISessions: [ChatUISession] = []
    //Keeps track of which specific chat session is currently active (by its unique ID).
    @State private var selectedSessionID: UUID? = nil
    //Lets you filter chat session history by the alias
    @State private var historyFilterAlias: String = ""
    
    @State private var thinkingStartDate: Date? = nil
    @State private var thinkingElapsed: Int = 0
    
    //flag that tracks whether the “Save Adapter” sheet (a popup or modal dialog) should be shown in the UI.
    @State private var showSaveAdapterSheet = false
    //string that holds the name of the new adaptors
    @State private var newAdapterName: String = ""
    
    
    //flag that alerts the  system’s file browser), letting the user select a PDF. to pull
    @State private var showPDFImporter = false
    //stores name of selected pdf
    @State private var selectedPDFName: String? = nil
    //Used to visually highlight the drop area when a file is being dragged over it.
    @State private var isDropTargeted: Bool = false
    //holds users given names
    @State private var newCourseName: String = ""
    //Represents the currently selected or active course (alias)(frontend)
    @State private var selectedCourseKey: String = ""
    //Maps course keys (identifiers/names) to PDF file URLs, so each course knows which PDF is associated with it.
    // Used to retrieve the correct PDF when switching courses or for retrieval-augmented generation (RAG).
    @State private var ragByCourse: [String: URL] = [:]
    
    //devs can chnage what questions they would like to appear depending on the app
    private let suggestedQuestions = [
        "What is data activism?",
        //?
    ]
    
    //helper function
    //returns the instance of whatever model is currently there. so isntead of witing out the if statement where the current model is being needed
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
    
    //hepler funtion
    //trims the first 5 characters
    //gets the index where the suggested question is located in the array
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
    
    
    //used to clean names for new courses
    func cleanCourseName(_ name: String) -> String {
        name.hasPrefix("New Course:") ? String(name.dropFirst("New Course:".count)) : name
    }
    
    //NavigationStack inside Home would let you go deeper within Home, like: multple screens in one tab
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
        //males sure there is session running to prevent dupliates. there must always be a session to interact with
        .onAppear {
            
            //Inserts the new session at the top of the sessions list.
            //Sets selectedSessionID to the new session’s ID (so the UI points to it).
            //Clears the view model input and messages (vm.messages = [], vm.input = "").

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
        //when model changes
        //new session is created
        //clears out messages and puts in new chat session messgaes
        
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
            
            //makes sure there is a classifier
            // IMPORTANT: switching courses unloads old classifier from memory + loads correct one
            // 1) Apply the PDF first (sets vm.currentRAGPDFURL)
            applyRAGForCurrentCourse()

            // 2) Now activate course (stable key can use PDF filename)
            vm.setActiveCourse(selectedCourseKey)

            vm.selectModel(selectedModel)

        }
        //new time and date as well
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
    //this is completely for the looks and some interactions
    
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
                //if alias is empty display the anme for the boundmodel
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

                    // 3) In‑memory adapters
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
                        
                        //It finds the currently selected session in your sessions array and updates that session’s metadata (alias and model) to reflect the new selection.
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

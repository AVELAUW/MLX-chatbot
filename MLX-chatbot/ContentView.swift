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

// ────────────────────────────────────────────────────────────
//  SECTION 1: The Welcome Title
//
//  Every SwiftUI app starts with three things:
//    import SwiftUI  — loads Apple's UI framework
//    struct ... View — a blueprint for one screen
//    var body        — everything the user sees goes here
//
//  Text() displays words on screen.
//  #Preview lets Xcode show your screen without running the app.
//
//  The Color(hex:) helper at the top lets you use hex color
//  codes like Color(hex: "#FF5733") anywhere in your app.
//  Find hex codes at: https://htmlcolorcodes.com
//
//  ★ MAIN TASK: Change the welcome message to include YOUR name.
//    Example: "Welcome to Jordan's AI"
//
//  📋 PASTE: This is your starter file.
//     Copy EVERYTHING below and paste it into ContentView.swift
// ────────────────────────────────────────────────────────────

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

struct ContentView: View {

    // ── Section 6: @State variable will go here ──────────

    // ── Section 4: suggestedQuestions array will go here ─

    var body: some View {

        // ── Section 5: NavigationStack will wrap this ────
        // ── Section 2: VStack + Image will go here ───────
        // ── Section 3: Subtitle will go here ─────────────

        // ★ CHANGE THE TEXT BELOW TO YOUR OWN WELCOME MESSAGE:
        Text("Welcome to AVELA AI")
            .font(.largeTitle.bold())

        // ── Section 4: Question buttons will go here ─────
        // ── Section 6: Message input bar will go here ────

    }
}

#Preview {
    ContentView()
}

// ── Customize Further ─────────────────────────────────────
//
// • Try different font sizes — replace .largeTitle with:
//       .title       — slightly smaller
//       .headline    — even smaller, still bold
//       .caption     — tiny text
//
// • Add color to your text — put this on the line after .bold():
//       .foregroundColor(.blue)
//   Other colors: .red, .purple, .green, .orange, .pink
//
// • Use an exact hex color:
//       .foregroundColor(Color(hex: "#FF5733"))
//
// • Add a second Text below the first one:
//       Text("Made by [Your Name]")
//           .font(.caption)
//           .foregroundColor(.gray)
//
// ──────────────────────────────────────────────────────────

// ────────────────────────────────────────────────────────────
//  SECTION 1: Imports & Functions
//
//  📋 PASTE: This is your starter file.
//     Copy EVERYTHING below and paste it into ContentView.swift
// ────────────────────────────────────────────────────────────

import SwiftUI

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

    @State private var userMessage = ""
    
    // ── Section 4: suggestedQuestions array will go here ─

    var body: some View {

        // ── Section 6: NavigationStack will go here ────
        // ── Section 2: VStack + Image will go here ─────
        // ── Section 3: Title & Subtitle will go here ───

        // ── Section 5: Question buttons will go here ────
        // ── Section 6: Message input bar will go here ───
        

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

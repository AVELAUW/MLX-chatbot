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
//  ★ MAIN TASK: Change the welcome message to include YOUR name.
//    Example: "Welcome to Jordan's AI"
// ────────────────────────────────────────────────────────────

import SwiftUI

struct ContentView: View {
    var body: some View {

        // ★ CHANGE THE TEXT BELOW TO YOUR OWN WELCOME MESSAGE:
        Text("Welcome to AVELA AI")
            .font(.largeTitle.bold())

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
// • Add a second Text below the first one:
//       Text("Made by [Your Name]")
//           .font(.caption)
//           .foregroundColor(.gray)
//
// ──────────────────────────────────────────────────────────

// ────────────────────────────────────────────────────────────
//  SECTION 1: Your First SwiftUI View
//  Every screen starts with a struct, a body, and a Text.
//  Text() puts words on screen — like print(), but visual.
//
//  ★ CENTRAL TASK: Change "Hello, World!" to your own
//    welcome message (e.g., "Welcome to Jordan's AI")
// ────────────────────────────────────────────────────────────

import SwiftUI

struct MyAppView: View {
    var body: some View {
        Text("Hello, World!")       // ★ CHANGE THIS to your welcome message
    }
}

#Preview {
    MyAppView()
}

// ── EXPLORE MORE ──────────────────────────────────────────
// Try adding modifiers after the Text to change how it looks:
//
//   Text("Welcome to Jordan's AI")
//       .font(.largeTitle)       // makes text big
//       .bold()                  // makes text bold
//       .foregroundColor(.blue)  // changes text color
//
// Other font sizes to try: .title, .headline, .caption
// Other colors to try: .red, .purple, .green, .orange
// ──────────────────────────────────────────────────────────

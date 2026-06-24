// ────────────────────────────────────────────────────────────
//  SECTION 2: App Icon
//
//  Image(systemName:) loads a free icon built into every Mac.
//  Apple calls these "SF Symbols" — there are thousands.
//  Browse them all: https://developer.apple.com/sf-symbols/
//
//  VStack stacks views vertically — top to bottom.
//  .resizable() lets you change the icon's size with .frame().
//
//  ★ MAIN TASK: Pick an SF Symbol icon for YOUR app.
//    Replace "brain.head.profile" with your choice.
// ────────────────────────────────────────────────────────────

import SwiftUI

struct ContentView: View {
    var body: some View {

        VStack {                                                       // ★ NEW

            Image(systemName: "brain.head.profile")                    // ★ NEW — app icon
                .resizable()                                           // ★ NEW
                .scaledToFit()                                         // ★ NEW
                .frame(width: 84, height: 84)                          // ★ NEW
                .padding(.top, 24)                                     // ★ NEW

            // ★ YOUR WELCOME MESSAGE FROM SECTION 1:
            Text("Welcome to AVELA AI")
                .font(.largeTitle.bold())

        }                                                              // ★ NEW
    }
}

#Preview {
    ContentView()
}

// ── Customize Further ─────────────────────────────────────
//
// • Try these SF Symbol names instead of "brain.head.profile":
//       "sparkles"              — AI / magic sparkles
//       "graduationcap.fill"    — education
//       "globe"                 — world / internet
//       "star.fill"             — favorite / rating
//       "bolt.fill"             — power / speed
//       "heart.fill"            — health / love
//       "music.note"            — music
//       "gamecontroller.fill"   — gaming
//
// • Add color to your icon — put this after .frame():
//       .foregroundColor(.blue)
//   Try: .purple, .orange, .red, .green
//
// • Make the icon bigger or smaller — change the numbers
//   inside .frame(width: 84, height: 84)
//   Try 60 for small, 120 for large.
//
// • Add a subtle shadow behind the icon:
//       .shadow(radius: 8)
//   Place it after .frame() or .foregroundColor()
//
// ──────────────────────────────────────────────────────────

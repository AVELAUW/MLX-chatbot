// ────────────────────────────────────────────────────────────
//  SECTION 7: Styling & Polish
//
//  This section upgrades the message input to match the real app:
//    .background(RoundedRectangle) — adds a filled shape behind a view
//    .overlay(RoundedRectangle)    — draws a border on top of a view
//    .opacity()     — 0.0 is invisible, 1.0 is fully solid
//    .fill()        — fills a shape with a color
//    .stroke()      — draws only the outline of a shape
//
//  Color(hex:) is a helper that lets you use web hex colors
//  like "#FF5733" anywhere in your code.
//
//  ★ MAIN TASK: Review the polished input bar below.
//    Your preview should now look like the real AVELA app!
//    Go back through ALL sections and make sure every piece
//    is customized to YOU (title, subtitle, icon, questions,
//    nav title, placeholder text).
// ────────────────────────────────────────────────────────────

import SwiftUI

// ─────────────────────────────────────────────────────────────
// COLOUR HELPER — use Color(hex: "#RRGGBB") anywhere below    // ★ NEW
// ─────────────────────────────────────────────────────────────
extension Color {                                                      // ★ NEW
    init(hex: String) {                                                // ★ NEW
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0                                            // ★ NEW
        Scanner(string: hex).scanHexInt64(&int)                        // ★ NEW
        let a, r, g, b: UInt64                                        // ★ NEW
        switch hex.count {                                             // ★ NEW
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)                        // ★ NEW
        }                                                              // ★ NEW
        self.init(.sRGB,                                               // ★ NEW
                  red: Double(r) / 255,                                // ★ NEW
                  green: Double(g) / 255,                              // ★ NEW
                  blue: Double(b) / 255,                               // ★ NEW
                  opacity: Double(a) / 255)                            // ★ NEW
    }                                                                  // ★ NEW
}                                                                      // ★ NEW


struct ContentView: View {

    @State private var userMessage = ""

    // SUGGESTED QUESTIONS
    private let suggestedQuestions = [
        "What is data activism?"
        // 🛠️ ADD YOUR QUESTIONS BELOW (comma after each one)

        // ─────────────────────────────────────────────────────
    ]

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // ── App Icon ─────────────────────────────────
                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .foregroundColor(.blue)
                    .shadow(radius: 8)
                    .padding(.top, 24)

                // ── Welcome Message ──────────────────────────
                VStack(spacing: 16) {
                    Spacer()

                    Text("Welcome to AVELA AI")
                        .font(.largeTitle.bold())

                    Text("Click to learn about data activism.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        ForEach(suggestedQuestions, id: \.self) { question in
                            Button(action: {
                                print(question)
                            }) {
                                Text(question)
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 30))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(question)              // ★ NEW
                        }
                    }
                    .padding(.vertical)

                    Spacer()
                }
                .padding()

                // ── Polished Message Input Bar ───────────────
                Divider()

                HStack(alignment: .top, spacing: 16) {
                    TextField("Type a message...", text: $userMessage)
                        .textFieldStyle(.plain)                        // ★ CHANGED — no default border
                        .font(.system(size: 16))
                        .padding(.horizontal, 24)                      // ★ NEW — inner padding
                        .padding(.vertical, 24)                        // ★ NEW
                        .frame(minHeight: 120, alignment: .topLeading) // ★ NEW — taller text box
                        .background(                                   // ★ NEW — light gray fill
                            RoundedRectangle(cornerRadius: 28)         // ★ NEW
                                .fill(Color.gray.opacity(0.1))         // ★ NEW
                        )                                              // ★ NEW
                        .overlay(                                      // ★ NEW — subtle border
                            RoundedRectangle(cornerRadius: 28)         // ★ NEW
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        )                                              // ★ NEW

                    Button("Send") {
                        print("Sent: \(userMessage)")
                        userMessage = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 30))     // ★ NEW — pill shape
                    .padding(.top, 20)                                 // ★ NEW — aligns with text box
                    .disabled(userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 24)                              // ★ CHANGED — wider padding
                .padding(.vertical, 24)                                // ★ CHANGED
            }
            .navigationTitle("AVELA-CourseSLM")
        }
    }
}

#Preview {
    ContentView()
}

// ============================================================
//  Your preview should now look like the real AVELA AI app!
//  Make sure you've customized every piece:
//    □ App icon           (Section 2)
//    □ Welcome title      (Section 1)
//    □ Subtitle           (Section 3)
//    □ Questions          (Section 4)
//    □ Navigation title   (Section 5)
//    □ Placeholder text   (Section 6)
//  Show your instructor when you're done!
// ============================================================

// ── Customize Further ─────────────────────────────────────
//
// • Use the Color(hex:) helper for exact brand colors:
//       .foregroundColor(Color(hex: "#FF5733"))
//   Find hex codes at: https://htmlcolorcodes.com
//
// • Change the input border thickness:
//       .stroke(Color.gray.opacity(0.3), lineWidth: 4)
//   Try lineWidth: 0.5 for super thin, 4 for thick.
//
// • Change the input background darkness:
//       .fill(Color.gray.opacity(0.05))   — barely visible
//       .fill(Color.gray.opacity(0.3))    — darker gray
//       .fill(Color.blue.opacity(0.05))   — hint of blue
//
// • Add a floating shadow to the input box — put this after
//   the .overlay(...) block:
//       .shadow(color: .black.opacity(0.08), radius: 6)
//
// • Add a toolbar reset button (like the real app):
//       .toolbar {
//           ToolbarItem(placement: .automatic) {
//               Button(role: .destructive) {
//                   print("Reset tapped")
//               } label: {
//                   Label("Reset", systemImage: "arrow.counterclockwise")
//               }
//           }
//       }
//   Place this right after .navigationTitle(...)
//
// ──────────────────────────────────────────────────────────

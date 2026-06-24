// ────────────────────────────────────────────────────────────
//  SECTION 6: Message Input Bar
//
//  @State stores a value that can change. When it changes,
//  SwiftUI automatically redraws the screen.
//
//  TextField lets users type text. It needs:
//    1. A placeholder — ghost text shown when empty
//    2. A $binding    — a live connection to a @State variable
//
//  The $ sign means "two-way connection" — the TextField
//  updates the variable, and the variable updates the TextField.
//
//  HStack places views side by side (left to right).
//  .disabled() grays out a button when a condition is true.
//
//  ★ MAIN TASK: Change the placeholder text to YOUR prompt.
//    Example: "Ask me anything...", "Search topics..."
// ────────────────────────────────────────────────────────────

import SwiftUI

struct ContentView: View {

    @State private var userMessage = ""                                // ★ NEW — stores typed text

    // SUGGESTED QUESTIONS
    private let suggestedQuestions = [
        "What is data activism?"
        // 🛠️ ADD YOUR QUESTIONS BELOW (comma after each one)

        // ─────────────────────────────────────────────────────
    ]

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .shadow(radius: 8)
                    .padding(.top, 24)

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
                        }
                    }
                    .padding(.vertical)

                    Spacer()
                }
                .padding()

                // ── Message Input Bar ────────────────────────
                Divider()                                              // ★ NEW — thin line separator

                HStack(alignment: .top, spacing: 16) {                 // ★ NEW — side by side

                    // ★ CHANGE THE PLACEHOLDER TEXT BELOW:
                    TextField("Type a message...", text: $userMessage)  // ★ NEW
                        .textFieldStyle(.roundedBorder)                 // ★ NEW
                        .font(.system(size: 16))                       // ★ NEW

                    Button("Send") {                                   // ★ NEW
                        print("Sent: \(userMessage)")                  // ★ NEW
                        userMessage = ""                               // ★ NEW — clears the field
                    }                                                  // ★ NEW
                    .buttonStyle(.borderedProminent)                   // ★ NEW
                    .disabled(userMessage.isEmpty)                     // ★ NEW — grayed when empty
                }                                                      // ★ NEW
                .padding()                                             // ★ NEW
            }
            .navigationTitle("AVELA-CourseSLM")
        }
    }
}

#Preview {
    ContentView()
}

// ── Customize Further ─────────────────────────────────────
//
// • Change the Send button text:
//       Button("Go") { ... }
//       Button("Ask") { ... }
//       Button("Submit") { ... }
//
// • Make the Send button a pill shape — add after .borderedProminent:
//       .clipShape(RoundedRectangle(cornerRadius: 30))
//
// • Try removing .disabled(userMessage.isEmpty) — now you can
//   tap Send with nothing typed. Add it back to see the difference!
//
// • Show what the user typed on screen — add this Text below
//   the HStack but above the closing }:
//       if !userMessage.isEmpty {
//           Text("You typed: \(userMessage)")
//               .font(.caption)
//               .foregroundColor(.gray)
//               .padding(.horizontal)
//       }
//
// ──────────────────────────────────────────────────────────

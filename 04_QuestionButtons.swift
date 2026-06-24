// ────────────────────────────────────────────────────────────
//  SECTION 4: Question Buttons
//
//  An array [ ] stores a list of values. Each string you add
//  becomes a tappable button on screen — automatically.
//
//  ForEach loops through the array and creates one Button
//  for every item. Add a string → a new button appears.
//
//  A Button has two parts:
//    action: { }  — code that runs when tapped
//    label:       — what the user sees
//
//  ★ MAIN TASK: Add 2–3 more questions to the array.
//    Watch your preview update with new buttons!
//    Remember: put a comma after each string.
// ────────────────────────────────────────────────────────────

import SwiftUI

struct ContentView: View {

    // ─────────────────────────────────────────────────────────
    // SUGGESTED QUESTIONS
    //
    // ★ Add more questions to this array.
    //   Each string becomes a tappable button on screen.
    //
    //   EXAMPLES: "Who uses data activism?", "Why does data matter?"
    // ─────────────────────────────────────────────────────────

    private let suggestedQuestions = [                                  // ★ NEW
        "What is data activism?"                                       // ★ NEW
        // 🛠️ ADD YOUR QUESTIONS BELOW (comma after each one)

        // ─────────────────────────────────────────────────────
    ]                                                                  // ★ NEW

    var body: some View {

        VStack(spacing: 0) {

            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .padding(.top, 24)

            VStack(spacing: 16) {
                Spacer()

                Text("Welcome to AVELA AI")
                    .font(.largeTitle.bold())

                Text("Click to learn about data activism.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Question button chips                                // ★ NEW
                HStack(spacing: 12) {                                  // ★ NEW
                    ForEach(suggestedQuestions, id: \.self) { question in
                        Button(action: {                               // ★ NEW
                            print(question)                            // ★ NEW
                        }) {                                           // ★ NEW
                            Text(question)                             // ★ NEW
                                .font(.callout)                        // ★ NEW
                                .foregroundColor(.white)               // ★ NEW
                                .padding(.horizontal, 18)              // ★ NEW
                                .padding(.vertical, 14)                // ★ NEW
                                .background(RoundedRectangle(cornerRadius: 30))
                        }                                              // ★ NEW
                        .buttonStyle(.plain)                           // ★ NEW
                    }                                                  // ★ NEW
                }                                                      // ★ NEW
                .padding(.vertical)                                    // ★ NEW

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

// ── Customize Further ─────────────────────────────────────
//
// • Change the button color — replace .background(...) with:
//       .background(RoundedRectangle(cornerRadius: 30).fill(Color.blue))
//   Try: .purple, .green, .red, .orange
//
// • Make the buttons stack vertically instead of side by side
//   by changing HStack to VStack:
//       VStack(spacing: 12) {
//           ForEach(...)
//       }
//
// • Change .cornerRadius(30) to .cornerRadius(8) for
//   a boxier shape instead of a pill.
//
// • Make the text bigger:
//       .font(.body) instead of .font(.callout)
//
// • Add an icon inside the button — replace the Text line with:
//       Label(question, systemImage: "questionmark.circle")
//
// ──────────────────────────────────────────────────────────

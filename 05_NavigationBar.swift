// ────────────────────────────────────────────────────────────
//  SECTION 5: Navigation Bar
//
//  NavigationStack wraps your screen and adds the title bar
//  you see at the top of almost every app.
//  .navigationTitle() sets the text that appears there.
//
//  ★ MAIN TASK: Change the .navigationTitle to YOUR app's name.
//    This is the name users see at the top of the screen.
// ────────────────────────────────────────────────────────────

import SwiftUI

struct ContentView: View {

    // SUGGESTED QUESTIONS
    private let suggestedQuestions = [
        "What is data activism?"
        // 🛠️ ADD YOUR QUESTIONS BELOW (comma after each one)

        // ─────────────────────────────────────────────────────
    ]

    var body: some View {

        NavigationStack {                                              // ★ NEW — adds the nav bar

            VStack(spacing: 0) {

                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .shadow(radius: 8)                                 // ★ NEW
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
            }

            // ★ CHANGE THE TEXT BELOW TO YOUR APP'S NAME:
            .navigationTitle("AVELA-CourseSLM")                        // ★ NEW

        }                                                              // ★ NEW — closes NavigationStack
    }
}

#Preview {
    ContentView()
}

// ── Customize Further ─────────────────────────────────────
//
// • Add a toolbar button in the top-right corner of the nav bar.
//   Place this right after .navigationTitle("..."):
//
//       .toolbar {
//           ToolbarItem(placement: .automatic) {
//               Button {
//                   print("Info tapped")
//               } label: {
//                   Image(systemName: "info.circle")
//               }
//           }
//       }
//
// • Try different toolbar icons:
//       "gearshape"                 — settings gear
//       "person.fill"               — user profile
//       "arrow.counterclockwise"    — reset / refresh
//       "star.fill"                 — favorites
//
// • Add a second ToolbarItem with a different icon.
//
// ──────────────────────────────────────────────────────────

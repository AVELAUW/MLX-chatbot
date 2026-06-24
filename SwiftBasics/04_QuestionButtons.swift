// ────────────────────────────────────────────────────────────
//  SECTION 4: Question Buttons
//
//  An array [ ] stores a list of values. Each string you add
//  becomes a tappable button on screen — automatically.
//
//  ForEach loops through the array and creates one Button
//  for every item. Add a string → a new button appears.
//
//  ★ MAIN TASK: Add 2–3 more questions to the array.
//    Watch your preview update with new buttons!
//    Remember: put a comma after each string.
//
//  📋 THIS SECTION HAS TWO PASTE STEPS — do them in order.
// ────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────
// STEP 1: Add this ABOVE your "var body" line:
// ─────────────────────────────────────────────────────────────

    // SUGGESTED QUESTIONS
    //
    // ★ Add more questions to this array.
    //   Each string becomes a tappable button on screen.
    //
    //   EXAMPLES: "Who uses data activism?", "Why does data matter?"

    private let suggestedQuestions = [
        "What is data activism?"
        // 🛠️ ADD YOUR QUESTIONS BELOW (comma after each one)

    ]


// ─────────────────────────────────────────────────────────────
// STEP 2: Select everything inside your var body { ... }
//         and REPLACE it with the code below.
// ─────────────────────────────────────────────────────────────

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

                // Question button chips
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

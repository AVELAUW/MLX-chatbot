// ────────────────────────────────────────────────────────────
//  SECTION 3: Subtitle & Spacing
//
//  ★ MAIN TASK: Change the subtitle to describe YOUR app's
//    topic. What will your AI teach people about?
//
//  📋 PASTE: Select //  SECTION 3: inside your var body { ... }
//     and REPLACE it with the code below.
// ────────────────────────────────────────────────────────────

            VStack(spacing: 16) {
                Spacer()
            // ★ CHANGE THE TEXT BELOW TO YOUR OWN WELCOME MESSAGE:
                Text("Welcome to AVELA AI")
                    .font(.largeTitle.bold())

            // ★ CHANGE THIS SUBTITLE TO DESCRIBE YOUR APP:
                Text("Click to learn about data activism.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
        }

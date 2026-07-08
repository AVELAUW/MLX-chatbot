// ────────────────────────────────────────────────────────────
//  SECTION 3: Subtitle & Spacing
//
//  A subtitle tells users what your app does.
//  .foregroundColor(.secondary) makes text gray — it's a
//  built-in color that adapts to light and dark mode.
//  .multilineTextAlignment(.center) centers long text.
//  Spacer() pushes views apart to fill available space.
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

// ── Customize Further ─────────────────────────────────────
//
// • Try a different subtitle color:
//       .foregroundColor(.blue)
//       .foregroundColor(.orange)
//       .foregroundColor(Color(red: 0.5, green: 0.2, blue: 0.8))
//
// • Change the subtitle font size:
//       .font(.headline)    — smaller, bold
//       .font(.body)        — standard reading size
//       .font(.caption)     — tiny
//
// • Add a third line below the subtitle:
//       Text("Powered by on-device AI")
//           .font(.footnote)
//           .foregroundColor(.gray)
//
// • Change VStack spacing from 16 to 32 for more room,
//   or to 8 for a tighter layout.
//
// ──────────────────────────────────────────────────────────

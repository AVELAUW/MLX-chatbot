// ────────────────────────────────────────────────────────────
//  SECTION 2: App Icon
//
//  Image(systemName:) loads a free icon built into every Mac.
//  Apple calls these "SF Symbols" — there are thousands.
//  Browse them all: https://developer.apple.com/sf-symbols/
//
//  VStack stacks views vertically — top to bottom.
//  .resizable() lets you change the icon's size with .frame().
//  .shadow() adds a drop shadow behind the icon.
//
//  ★ MAIN TASK: Pick an SF Symbol icon for YOUR app.
//    Replace "brain.head.profile" with your choice.
//
//  📋 PASTE: Select everything inside your var body { ... }
//     and REPLACE it with the code below.
// ────────────────────────────────────────────────────────────

        VStack {

            // ★ PICK YOUR APP ICON — replace "brain.head.profile":
            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .foregroundColor(.blue)
                .shadow(radius: 8)
                .padding(.top, 24)

            Text("Welcome to AVELA AI")
                .font(.largeTitle.bold())

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
// • Change .foregroundColor(.blue) to your favorite color:
//       .foregroundColor(.purple)
//       .foregroundColor(Color(hex: "#FF5733"))
//
// • Make the icon bigger or smaller — change the numbers
//   inside .frame(width: 84, height: 84)
//   Try 60 for small, 120 for large.
//
// • Change the shadow size:
//       .shadow(radius: 4)    — subtle
//       .shadow(radius: 16)   — dramatic
//
// ──────────────────────────────────────────────────────────

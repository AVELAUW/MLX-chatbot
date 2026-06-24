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
//  .background(RoundedRectangle) fills a shape behind a view.
//  .overlay(RoundedRectangle) draws a border on top of a view.
//
//  ★ MAIN TASK: Change the placeholder text to YOUR prompt.
//    Example: "Ask me anything...", "Search topics..."
//
//  📋 THIS SECTION HAS TWO PASTE STEPS — do them in order.
// ────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────
// STEP 1: Add this line ABOVE the suggestedQuestions line:
// ─────────────────────────────────────────────────────────────

    @State private var userMessage = ""


// ─────────────────────────────────────────────────────────────
// STEP 2: Find the Divider and message input bar placeholder
//         comments at the BOTTOM of your body (after Spacer
//         and .padding) and REPLACE them with the code below.
//         Keep everything above — your icon, title, subtitle,
//         and question buttons stay exactly as you customized them.
// ─────────────────────────────────────────────────────────────

                // ── Message Input Bar ────────────────────────
                Divider()

                HStack(alignment: .top, spacing: 16) {

                    // ★ CHANGE THE PLACEHOLDER TEXT BELOW:
                    TextField("Type a message...", text: $userMessage)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(minHeight: 120, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        )

                    Button("Send") {
                        print("Sent: \(userMessage)")
                        userMessage = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding(.top, 20)
                    .disabled(userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)


// ── Customize Further ─────────────────────────────────────
//
// • Change the Send button text:
//       Button("Go") { ... }
//       Button("Ask") { ... }
//       Button("Submit") { ... }
//
// • Change the input border thickness:
//       .stroke(Color.gray.opacity(0.3), lineWidth: 4)
//   Try lineWidth: 0.5 for super thin, 4 for thick.
//
// • Change the input background shade:
//       .fill(Color.gray.opacity(0.05))   — barely visible
//       .fill(Color.gray.opacity(0.3))    — darker gray
//       .fill(Color.blue.opacity(0.05))   — hint of blue
//
// • Add a floating shadow to the input box — put this after
//   the .overlay(...) block:
//       .shadow(color: .black.opacity(0.08), radius: 6)
//
// • Show what the user typed on screen — add this below
//   the HStack but still inside the outer VStack:
//       if !userMessage.isEmpty {
//           Text("You typed: \(userMessage)")
//               .font(.caption)
//               .foregroundColor(.gray)
//               .padding(.horizontal)
//       }
//
// ──────────────────────────────────────────────────────────

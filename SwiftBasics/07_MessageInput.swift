// ────────────────────────────────────────────────────────────
//  SECTION 7: Message Input Bar
//
//  ★ MAIN TASK: Change the placeholder text to YOUR prompt.
//    Example: "Ask me anything...", "Search topics..."
//
//  📋 Select //Section 7: replace with the code below.
// ────────────────────────────────────────────────────────────

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

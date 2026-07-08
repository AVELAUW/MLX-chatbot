// ────────────────────────────────────────────────────────────
//  SECTION 5: Hstack & Buttons
//
//  📋 PASTE: Select //Section 5: and REPLACE it with the code below.
// ─────────────────────────────────────────────────────────────

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

//  SECTION 4: Hstack & Buttons
//
// COPYPASTE: Select //Section 4: and REPLACE it with the code below.

               TextField("Type a message...", text: $userMessage)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    )

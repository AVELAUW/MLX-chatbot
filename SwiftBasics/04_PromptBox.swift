//  SECTION 4: Prompt/Message Box

// COPYPASTE: Select //Section 4: and REPLACE it with the code below.

              TextField("Type a message...", text: $vm.input, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(minHeight: 120, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: 28).fill(Color.gray.opacity(0.1)))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.gray.opacity(0.3), lineWidth: 1.5))
                        .lineLimit(1...12)
                        .disabled(!vm.isReady)

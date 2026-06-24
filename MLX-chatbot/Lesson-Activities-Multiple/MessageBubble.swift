// ──────────────────────────────────────────────────────────────────────────────
//  MessageBubble.swift
//  MLX-chatbot
//
//  ★ STUDENT EDITABLE — Change how chat messages look here.
//
//  There are two bubble styles:
//    • User bubbles  — appear on the RIGHT side of the screen
//    • Bot bubbles   — appear on the LEFT side of the screen
//
//  Colours are set in AppColors.swift. Font sizes and bubble shape live here.
// ──────────────────────────────────────────────────────────────────────────────

import SwiftUI

struct MessageBubble: View {
    let message: String

    private var isUser: Bool { message.starts(with: "You:") }

    private var displayText: String {
        if isUser { return String(message.dropFirst(4)) }
        if message.starts(with: "Bot:") { return String(message.dropFirst(4)) }
        return message
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer(minLength: 60)
                Text(displayText)
                    // ★ EDIT: Change .body to .callout (smaller) or .title3 (bigger).
                    .font(.body)
                    .foregroundColor(AppColors.userBubbleText)
                    .padding(.horizontal, 16) // ★ EDIT: left/right padding inside bubble
                    .padding(.vertical, 10)   // ★ EDIT: top/bottom padding inside bubble
                    .background(
                        // ★ EDIT: Change cornerRadius for more square (8) or rounder (24) bubbles.
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppColors.userBubble)
                    )
                // ★ EDIT: Swap "person.fill" for any SF Symbol name from: https://developer.apple.com/sf-symbols/
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(AppColors.userAvatar).frame(width: 36, height: 36))
                    .frame(width: 36, height: 36)

            } else {
                // Bot avatar — uses the Logo image asset.
                // ★ EDIT: Change frame width/height to resize the bot avatar circle.
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .background(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))

                Text(displayText)
                    // ★ EDIT: Change .body to .callout (smaller) or .title3 (bigger).
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        // ★ EDIT: Change opacity(0.2) to a higher value (e.g. 0.5) for a darker bubble.
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppColors.botBubble.opacity(0.5))
                    )
                Spacer(minLength: 60)
            }
        }
    }
}

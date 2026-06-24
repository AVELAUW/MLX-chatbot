// ──────────────────────────────────────────────────────────────────────────────
//  WelcomeView.swift
//  MLX-chatbot
//
//  ★ STUDENT EDITABLE — Change the layout and text of the welcome screen here.
//
//  This view is shown before the user sends their first message.
//  It displays the logo, a heading, a subtitle, and question chips.
//
//  The actual words (heading, subtitle, questions) live in AppConfig.swift —
//  edit them there. Here you can change sizes, spacing, and layout.
// ──────────────────────────────────────────────────────────────────────────────

import SwiftUI

struct WelcomeView: View {

    var onQuestionTapped: (String) -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {

                // ★ EDIT: Change .largeTitle to .title or .title2 to make it smaller.
                //         Add .italic() after .bold() to make it italic.
                Text(AppConfig.welcomeHeading)
                    .font(.largeTitle.bold())

                // ★ EDIT: Change .title3 to .body or .callout for a smaller subtitle.
                Text(AppConfig.welcomeSubtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Suggested question chips — text comes from AppConfig.suggestedQuestions
                // ★ EDIT: Change .horizontal / .vertical padding numbers to resize chips.
                //         Change cornerRadius to make chips more square (lower) or pill-shaped (higher).
                HStack(spacing: 12) {
                    ForEach(AppConfig.suggestedQuestions, id: \.self) { question in
                        Button(action: { onQuestionTapped(question) }) {
                            Text(question)
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal, 18) // ★ EDIT: left/right chip padding
                                .padding(.vertical, 14)   // ★ EDIT: top/bottom chip padding
                                .background(
                                    // ★ EDIT: Change AppColors.accent to any AppColors value
                                    //         to recolour the chips.
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(AppColors.accent)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(question)
                    }
                }
                .padding(.vertical)
            }

            Spacer()
        }
        .padding()
    }
}

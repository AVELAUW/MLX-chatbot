// ──────────────────────────────────────────────────────────────────────────────
//  AppColors.swift
//  MLX-chatbot
//
//  ★ STUDENT EDITABLE — Change every colour in the app here.
//
//  HOW TO CHANGE A COLOUR:
//    Replace the hex string (e.g. "#3B82F6") with any 6-digit hex colour code.
//    You can find hex codes at: https://www.color-hex.com  or  https://coolors.co
//
//  EXAMPLE:
//    static let userBubble = Color(hex: "#9333EA")   // changes bubbles to purple
// ──────────────────────────────────────────────────────────────────────────────

import SwiftUI

enum AppColors {

    // ★ EDIT: Background colour of the user's chat bubbles (right side).
    static let userBubble = Color(hex: "#3B82F6")         // default: blue

    // ★ EDIT: Text colour inside the user's chat bubbles.
    static let userBubbleText = Color(hex: "#FFFFFF")     // default: white

    // ★ EDIT: Background colour of the bot's chat bubbles (left side).
    static let botBubble = Color(hex: "#E5E7EB")          // default: light grey
    //         (opacity is also applied — see MessageBubble.swift)

    // ★ EDIT: Colour of the send button and progress bar tint.
    static let accent = Color(hex: "#3B82F6")             // default: blue

    // ★ EDIT: Border colour around the text input field.
    static let inputBorder = Color(hex: "#9CA3AF")        // default: mid grey

    // ★ EDIT: Fill colour inside the text input field.
    static let inputFill = Color(hex: "#F3F4F6")          // default: near white

    // ★ EDIT: Colour of the user avatar icon background circle.
    static let userAvatar = Color(hex: "#6B7280")         // default: grey

    // ★ EDIT: Colour of the thin divider line above the input bar.
    static let divider = Color(hex: "#D1D5DB")            // default: light grey
}

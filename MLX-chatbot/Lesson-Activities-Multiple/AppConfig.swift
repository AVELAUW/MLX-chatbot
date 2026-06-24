// ──────────────────────────────────────────────────────────────────────────────
//  AppConfig.swift
//  MLX-chatbot
//
//  ★ STUDENT EDITABLE — Change the text and questions shown in the app here.
// ──────────────────────────────────────────────────────────────────────────────

import Foundation

enum AppConfig {

    // ★ EDIT: The name shown in the top navigation bar of the app.
    static let navigationTitle = "AVELA-CourseSLM"

    // ★ EDIT: The large heading on the welcome/home screen.
    static let welcomeHeading = "Welcome to AVELA AI"

    // ★ EDIT: The smaller description line under the heading.
    //         Describe what your course or chatbot is about.
    static let welcomeSubtitle = "Click to learn about data activism."

    // ★ EDIT: The button chips shown on the welcome screen.
    //         Each string becomes one tappable question button.
    //         Add, remove, or rewrite questions to match your course content.
    //         Example: "What is machine learning?", "How does bias appear in data?"
    static let suggestedQuestions: [String] = [
        "What is data activism?"
        // ★ Add more questions here, separated by commas:
        // "Your second question here",
        // "Your third question here",
    ]

    // ★ EDIT: Text shown inside the text field before the user types anything.
    static let inputPlaceholder = "Type a message..."

    // ★ EDIT: Label on the send button.
    static let sendButtonLabel = "Send"

    // ★ EDIT: Title of the loading overlay shown while the model is loading.
    static let loadingTitle = "Loading Course..."

    // ★ EDIT: Subtitle shown under the loading spinner.
    static let loadingSubtitle = "Please wait..."
}

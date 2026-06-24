// ──────────────────────────────────────────────────────────────────────────────
//  SystemPrompt.swift
//  MLX-chatbot
//
//  ★ STUDENT EDITABLE — Change the AI's personality and focus here.
//
//  This is the single most impactful file in the app. The text below is
//  given to the AI before every conversation — it defines who it is,
//  how it talks, and what it stays focused on.
// ──────────────────────────────────────────────────────────────────────────────

import Foundation

enum AIPersonality {
    //  ★ Edit the blank quotes
    static let systemPrompt = " "

    // GUIDELINES:
    // • Describe a role:   "You are a ___"  sets the AI's identity.
    // • Set the tone:      add words like "friendly", "concise", or "Socratic"
    // • Set the focus:     tell it what subject or course to stay on topic about
    // • Add a rule:        each sentence starting with "You" adds a behaviour
    //                      e.g. "You always respond in bullet points."
    //                           "You ask the student a follow-up question."
    // • Keep it short:     3–5 sentences works best. More isn't always better.
}

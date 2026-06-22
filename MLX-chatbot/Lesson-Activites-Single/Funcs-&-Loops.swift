//
//  Funcs-&-Loops.swift
//  MLX-chatbot
//
//  ─────────────────────────────────────────────────────────────
//  THINGS YOU CAN PRACTISE IN THIS FILE:
//    1. Functions  → search "SECTION 1"
//    2. Loops      → search "SECTION 2"
//  ─────────────────────────────────────────────────────────────

import Foundation


// ─────────────────────────────────────────────────────────────
// SECTION 1 — FUNCTION PRACTICE
//
// ★ YOUR TASK: Fill in the body of this function.
//   It should return true if the message contains
//   any word from the flaggedWords list below.
//
//   HINT: use flaggedWords.contains(word)
//   EXAMPLE: containsFlagged("spam test") → true
//            containsFlagged("hello")     → false
// ─────────────────────────────────────────────────────────────

let flaggedWords = ["spam", "cheat"]

func containsFlagged(_ message: String) -> Bool {
    let words = message.lowercased().components(separatedBy: " ")
    for word in words {
        // YOUR CODE HERE
    }
    return false
}




// ─────────────────────────────────────────────────────────────
// SECTION 2 — LOOP PRACTICE
//
// ★ YOUR TASK: Fill in the loop so it prints each
//   flagged word to the console when the app launches.
//
//   HINT: for word in flaggedWords { print(word) }
// ─────────────────────────────────────────────────────────────

func printFlaggedWords() {
    // YOUR CODE HERE
}

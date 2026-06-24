// ────────────────────────────────────────────────────────────
//  SECTION 8: AI Personality
//
//  The AI reads a "system prompt" before every conversation.
//  This prompt tells it HOW to behave — its personality, tone,
//  and rules. Change the prompt → the AI acts differently.
//
//  A system prompt is just plain English — no code needed.
//  Think of it like giving instructions to a new tutor:
//    "You are friendly. Explain things simply. Stay on topic."
//
//  The triple quotes """ let you write text across multiple lines.
//  The backslash \ at the end of a line means "continue on
//  the next line" — it keeps one sentence from breaking apart.
//
//  This file is ChatViewModel.swift in the Xcode project.
//  Open it and find SECTION 1 — AI PERSONALITY to edit.
//
//  ★ MAIN TASK: Rewrite the system prompt in YOUR words.
//    Describe how you want YOUR AI to talk, teach, and behave.
//    Then ask the AI the same question before and after —
//    see how the response changes!
// ────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// In ChatViewModel.swift, find this block:
// ─────────────────────────────────────────────────────────────

/*
    private let SYSTEM_PROMPT = """
        You are a helpful learning assistant who teaches concepts step by step \
        using clear, scaffolded language.
        You never provide exact code solutions.
        If a student asks something unrelated or off-topic, politely redirect \
        them to the active course material.
        """
*/

// ★ REWRITE THE PROMPT ABOVE IN YOUR OWN WORDS.
//   Keep it inside the triple quotes """ ... """
//   Here are some ideas to include:
//
//   • What subject does your AI teach?
//   • Should it be formal or casual? Funny or serious?
//   • Should it give short answers or long explanations?
//   • What should it do if someone asks something off-topic?
//
//   EXAMPLE — a music teacher AI:
//
//       private let SYSTEM_PROMPT = """
//           You are a friendly music teacher who explains music theory \
//           using everyday language and pop song examples.
//           Keep answers under 3 sentences unless the student asks for more.
//           If someone asks about something other than music, say \
//           "Great question! But let's get back to the music."
//           """
//
//   EXAMPLE — a strict science tutor:
//
//       private let SYSTEM_PROMPT = """
//           You are a science tutor. Always answer with a fact, then \
//           ask a follow-up question to make the student think deeper.
//           Never give the full answer — guide them to figure it out.
//           Only discuss biology, chemistry, and physics topics.
//           """

// ── Customize Further ─────────────────────────────────────
//
// • Try making the AI respond ONLY in questions:
//       "You only respond with questions. Never give direct answers."
//
// • Try giving it a character:
//       "You are a pirate who teaches history. Use pirate slang."
//
// • Try limiting response length:
//       "Keep every response under 2 sentences."
//
// • Try making it bilingual:
//       "Respond in both English and Spanish."
//
// • After changing the prompt, ask the AI the SAME question
//   you asked before. Compare the two answers — what changed?
//
// ──────────────────────────────────────────────────────────

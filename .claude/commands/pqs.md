---
description: Turn rough task into intent-based prompt for Claude Code — do NOT execute task
argument-hint: "черновик задачи своими словами"
---

User describes tasks in rough Russian. Write a **copy-paste prompt** for Claude Code. Do NOT implement.

**Reply in Russian.**

## Philosophy

Explain **what** we're building and **how it should work for the player**. Claude Code decides **how** to code. No file lists, no coding conventions, no framework bans unless user explicitly asked.

## Output

### 1. Ready-to-paste prompt (main)

Structure:

- Phase from `docs/ROADMAP.md`
- What's already in Studio (from user draft)
- Player experience (what they see/do)
- System behavior (save, assign base, etc.)
- Out of scope (later phases)
- Studio verification steps

Read `docs/GAME.md`, `docs/ARCHITECTURE.md` if needed.

### 2. One line

«Скопируй блок выше в Claude Code.»

Draft: $ARGUMENTS

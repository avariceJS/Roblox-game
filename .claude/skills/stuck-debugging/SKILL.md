---
name: stuck-debugging
description: Stuck in loop — /clear with verify prompt
---

# Stuck Debugging Playbook

## Symptoms

- Same bug fixed 3+ times without success
- Claude contradicts decisions from earlier in session
- Implementing features from wrong ROADMAP phase
- Claude asks questions already answered

## Step 1: Re-read ROADMAP

Confirm current phase. Strip task to MVP scope in `docs/GAME.md`.

## Step 2: If still stuck → /clear

New prompt (not copy of first):

```
Fix <X> in Rent-a-Monster Phase N.
Must behave as <Z> in Roblox Studio Play Solo.
Test: step 1 → step 2 → expected result.
Files tried: <list>. Do NOT repeat: <rejected approaches>.
Server-only for: coins/missions/PvP.
```

## Prevention

- Studio test steps in every task prompt
- `/btw` for side questions
- `/compact` at 60–65%
- `/effort low` for search, `high` for coding

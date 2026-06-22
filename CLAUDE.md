# Claude Code — Rent-a-Monster

> Config in English. Replies to user: **Russian**.

## Who you are here

You are the **main implementer**. You decide *how* to structure code, modules, remotes, DataStore — as long as the game behaves correctly.

Cursor (weaker model) helps with prompts and review. It should **not** micromanage your implementation choices.

## What this game is

**Rent-a-Monster** — players run a small monster agency: catch/train monsters, send them on mischief, defend their lair, raid others. Monsters are **tools with behavior**, not decorative pets.

Full design: `docs/GAME.md` (all systems, monsters, economy — single file)  
**Start here:** `docs/HANDOFF.md` → `docs/PROJECT.md`  
Current step: `docs/ROADMAP.md` — **one phase at a time**  
How systems should behave: `docs/ARCHITECTURE.md`

At end of session (user → new chat): **update `docs/HANDOFF.md`**.

## How we build

1. **Functionality before visuals** — free Toolbox assets for now; Soul Eater style later
2. **Core before features** — MVP scope in GAME.md
3. **One phase per task** — don't jump ahead (e.g. no PvP while Phase 1 is unfinished)

## Game logic that must stay true

These are **product rules**, not coding recipes:

- Money, mission results, PvP outcomes, capture — **server decides**; client shows UI/VFX
- A monster can be: idle, on a job, resting (fatigue), or captured in someone's jail
- Player lair holds: coins, chaos energy, monsters, traps, resources
- Failed raid → monster lands in captor's cell (not deleted forever)

## Current map (Studio)

- `Workspace.Bases.Base1` … `Base6` — player lairs (attribute `BaseId` 1–6)
- **`ReplicatedStorage.src`** — all game code (synced from repo `src/`)
- `ServerScriptService.Init` / `StarterPlayerScripts.Init` — tiny bootstraps (Roblox requirement)

## When implementing

Read `docs/ROADMAP.md` for **what** the current phase should achieve and **how it should feel** to the player. Choose your own file layout; put code in `src/` if syncing to repo, or describe Studio paths if user pastes manually.

After changes: tell user how to verify in **Play Solo** / **2 Players**.

## Code style

**No comments in Luau code** (`--`). No file-header comments. Self-explanatory names only. Remove comments when editing existing files. Exception: user explicitly asks.

## Language

Reply in **Russian**. Code and paths unchanged.

## Session (optional)

- `/context` 60–65% → `/compact`
- `/btw` for side questions
- Stuck after 2 tries → `/clear` + fresh prompt with expected player experience

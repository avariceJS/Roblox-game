# AGENTS.md — Rent-a-Monster

## Новый чат — читай по порядку

1. **`docs/HANDOFF.md`** — текущее состояние, последняя сессия
2. **`docs/PROJECT.md`** — репо, Rojo, карта, workflow
3. **`docs/ROADMAP.md`** — фазы
4. **`docs/GAME.md`** — полный дизайн игры

## Workflow

1. Фаза из HANDOFF / ROADMAP
2. Cursor — intent-промпт
3. Claude Code — код
4. Тест в Studio
5. **Конец чата → обновить HANDOFF.md**

## Prompt philosophy

Объясняй **что и зачем**, не **как писать код** (Claude Code сильнее).

## Code style

**Без комментариев в `.lua`** — см. `.cursor/rules/code-style.mdc` и `CLAUDE.md`.

## Config

- Cursor: `.cursor/rules/`
- Claude Code: `CLAUDE.md`, `.claude/`

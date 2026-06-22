---
name: prompt
description: Writes an intent-based prompt for Claude Code (@prompt). Only when user asks for claude code prompt or invokes @prompt.
disable-model-invocation: true
---

# @prompt — промпт для Claude Code

Только по явной просьбе. **Не** править код в Cursor.

## Философия

Claude Code **умнее** — промпт объясняет **зачем и как должно работать**, не **как писать код**.

## Шаги

1. `docs/ROADMAP.md` — текущая фаза
2. `docs/ARCHITECTURE.md` + `docs/GAME.md` — что должно получиться
3. Уточни у пользователя что уже есть в Studio (если не сказано)
4. Выдай **один copy-paste блок** на русском

## Шаблон

```
Rent-a-Monster — [фаза ROADMAP]

Уже в Studio:
- …

Сейчас делаем:
- …

Игрок должен почувствовать/увидеть:
- …

Система должна:
- …

Пока не делаем:
- …

Проверка:
1. Play Solo: …
2. 2 Players (если нужно): …

Стиль: без комментариев в коде.
```

## Не включать (unless user asked)

- Имена файлов и ModuleScript
- Init/Start, --!strict, RemoteFunction vs RemoteEvent
- Запреты фреймворков
- PQS score (optional one line ok)

Ответ на русском + «скопируй в Claude Code».

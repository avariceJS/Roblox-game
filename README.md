# Rent-a-Monster

Roblox-игра: агентство монстров — пакости, защита, аренда, PvP.

## Документация

| Файл | Когда читать |
|------|----------------|
| **[HANDOFF.md](docs/HANDOFF.md)** | **Всегда первым** — текущее состояние |
| [PROJECT.md](docs/PROJECT.md) | Структура, Rojo, карта |
| [ROADMAP.md](docs/ROADMAP.md) | Этапы |
| [GAME.md](docs/GAME.md) | **Полный дизайн игры** |
| [STUDIO.md](docs/STUDIO.md) | Studio + Rojo |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Поведение систем |

## Статус

**Phases 0–10 ✅** · **Phase 12 код в репо** — проверка Studio. Подробности: `docs/HANDOFF.md`.

## AI

| Инструмент | Роль |
|------------|------|
| **Claude Code** | Пишет код — сам выбирает структуру |
| **Cursor** | Контекст, intent-промпты, ревью |

Промпты объясняют **что хотим получить**, не **как писать код**.

Конфиг: `CLAUDE.md`, `.cursor/rules/`, `.claude/`

```bash
cd ~/Desktop/Roblox-game && claude
```

## Studio + Rojo (автосинк кода)

Скрипты из `src/` попадают в Studio без перетаскивания. Карта остаётся в place.

Полная инструкция: [docs/STUDIO.md](docs/STUDIO.md)

```bash
cd ~/Desktop/Roblox-game
aftman install   # один раз
rojo serve       # каждый сеанс
# Studio → Plugins → Rojo → Connect
```

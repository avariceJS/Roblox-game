# Roadmap — Rent-a-Monster

Работаем **по одному этапу**. После каждого — тест в Studio, потом следующий.

> Текущий прогресс: **`HANDOFF.md`**. Полный дизайн: **`GAME.md`**. Этапы: **`ROADMAP.md`**.

## Phase 0 — Setup ✅

- [x] AI-конфиг (Cursor + Claude Code)
- [x] Roblox place + карта (6 баз)
- [x] Rojo + `src/` → `ReplicatedStorage.src`

## Phase 1 — Player & Base Core ✅

- [x] PlayerData (DataStore): монеты, chaos, baseId
- [x] Назначение базы игроку при join (сохраняется между сессиями)
- [x] Спавн на своей базе (respawn, Stop→Play)
- [x] UI: баланс монет
- [ ] Базовые зоны на карте: сундук, дверь, слоты — **визуал позже**

## Phase 2 — Laboratory & First Monster ✅

- [x] Monster template: type, state, fatigue
- [x] Выдача Slime (Гуппи) новичку при первом join
- [x] UI карточка монстра
- [x] TrainingZone + NPC удалены (кода нет)
- [x] Лаборатория у каждого особняка (Base1–6), привязка к BaseId
- [x] Капсулы с монстрами (placeholder визуал)
- [x] UI лаборатории: монстр, состояние, вход через ProximityPrompt [E]
- [x] Подсветка своей базы (маркер + Highlight)

**Не делаем:** тренировочная площадка, туториал, обучающие NPC.  
Способность Slime (лужа) — **Phase 3**, на целевой базе.

## Phase 3 — Dispatch (отправка монстра) ✅

- [x] UI: выбор монстра + выбор цели (пикер из 6 баз)
- [x] Монстр **идёт сам** к цели (walker-шар TweenService)
- [x] Способность на месте (Slime → липкая лужа на целевой базе)
- [x] Награда (монеты, chaos), fatigue после задания
- [x] Состояния OnMission → Fatigued → Idle (recovery + toast)

## Phase 4 — PvP Attack ← **СЛЕДУЮЩИЙ**

- [ ] Список баз других **живых игроков** на сервере (исключить свою)
- [ ] NPC-дом как постоянная цель (всегда доступна, не занята игроком)
- [ ] Attack flow: цель → монстр → тип пакости
- [ ] Server validates + resolves
- [ ] Уведомления атакующему и защитнику

## Phase 5 — Defense

- [ ] Trap slot + Cage
- [ ] Defender monster
- [ ] Catch flow → jail cell

## Phase 6 — Economy & Progression

- [ ] Покупка монстров в лаборатории (Gremlin, ShadowRat, Homunculus)
- [ ] Monster XP + levels, прокачка в лаборатории
- [ ] Base upgrades

## Phase 7 — Polish MVP

- [ ] Balance pass
- [ ] Bug fixes
- [ ] UX-полировка (без отдельного туториала)

## Phase 8+ — Post-MVP

Аренда, репутация, события, кастомные модели, Soul Eater map, донат.

## Как работаем с AI

1. **Cursor** — контекст, промпты, ревью
2. **Claude Code** — имплементация
3. **Ты** — тест в Studio
4. Один этап = один промпт
5. **Конец чата** — обновить `docs/HANDOFF.md`

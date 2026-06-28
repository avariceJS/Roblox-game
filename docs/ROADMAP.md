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

## Phase 4 — PvP Attack ✅

- [x] Список баз других **живых игроков** на сервере (исключить свою)
- [x] NPC-дом как постоянная цель (Workspace.NpcHomes/House, id=0)
- [x] Пикер целей динамический: targets из GetPlayerData, кнопки по слотам
- [x] Server validates + resolves (id=0 обрабатывается отдельно, getMissionPlatform)
- [x] Уведомление защитнику (toast через MonsterUpdated, без лишнего remote)

## Phase 5 — Defense ✅

- [x] Trap slot + Cage (кнопка в лаборатории, `SetTrap` remote)
- [x] Catch flow → jail cell (монстр → Captured, в `data.jail` защитника)
- [x] Toast атакующему «Твой Гуппи пойман!» + защитнику «Поймал Гуппи!»
- [x] Captured state в UI лаборатории (красная кнопка «Пойман ⛓️»)
- [x] Клетка нарушителей в UI (список пойманных)
- [x] `syncPlayerMonsters` не трогает Captured монстров

## Phase 6 — Economy & Jail Ransom ✅

- [x] **Выкуп:** захватчик задаёт цену на пленника; владелец платит → монстр `Idle`, убрать из `jail`
- [x] UI: владелец клетки — «Задать выкуп»; владелец монстра — «Выкупить за 💰 N»
- [x] Покупка Slime/Гуппи за 50💰 — **логика** (`BuyMonster`); UI пока **в лаборатории** (UX-долг → Phase 7)
- [x] Базовые **ручные задания** (+25💰, cooldown 120 сек) — UI пока **в лаборатории** (→ Phase 7)
- [ ] Monster XP + levels, прокачка — **Phase 8+**
- [ ] Base upgrades — **Phase 8+**

**Не делали:** авто-освобождение, влом, подчинение, Robux, **отдельный магазин** (отложено в Phase 7).

## Phase 7 — Shop UI + Jail Break ← **СЛЕДУЮЩИЙ**

### 7a — Отдельный магазин (первый шаг)

- [ ] **Отдельное меню «Магазин»** — не в лаборатории (лаба = монстры, отправка, ловушка, клетка, выкуп)
- [ ] Точка входа на базе: ProximityPrompt / NPC / отдельная зона (placeholder ok)
- [ ] `ShopController` (или аналог) — покупка монстров, позже Gremlin/Rat
- [ ] Квест «мелкая работа» — в магазине или рядом (контракты), не в лабе
- [ ] Убрать `shopSection` + `questBtn` из `LabController`
- [ ] Bootstrap: `ShopController` после LabController (или по ProximityPrompt, без bootstrap)

### 7b — Jail Break (влом)

- [ ] Пленный монстр **виден в лаборатории/клетке на базе захватчика** (мир + UI)
- [ ] Владелец может **физически прийти** на чужую базу с **инструментами** освобождения
- [ ] Ловушки на базе врага при вломе: сработала → **alert захватчику** («влом!»)
- [ ] Успешное освобождение → монстр возвращается владельцу

## Phase 8 — Subjugation & Progression

- [ ] **Подчинение** пленного монстра захватчиком (механика верности — детали позже)
- [ ] Если владелец не забрал: захватчик пробует подчинить
- [ ] **Серверная компенсация** захватчику, если подчинить не вышло
- [ ] Monster XP + levels, прокачка в лаборатории
- [ ] Base upgrades
- [ ] Новые монстры в **магазине**: Gremlin, ShadowRat, Homunculus

## Phase 8+ — Monetization & Post-MVP

- [ ] **Robux:** мгновенный выкуп монстра владельцем (Developer Product)
- [ ] **Robux:** принудительное подчинение пленника захватчиком
- [ ] Аренда, репутация, события, кастомные модели, Soul Eater map, полный донат

## Phase 9 — Polish MVP

- [ ] Balance pass
- [ ] Bug fixes
- [ ] UX-полировка (без отдельного туториала)

## Как работаем с AI

1. **Cursor** — контекст, промпты, ревью
2. **Claude Code** — имплементация
3. **Ты** — тест в Studio
4. Один этап = один промпт
5. **Конец чата** — обновить `docs/HANDOFF.md`

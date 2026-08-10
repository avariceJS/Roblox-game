# Roadmap — Rent-a-Monster

Работаем **по одному этапу**. После каждого — тест в Studio, потом следующий.

> Текущий прогресс: **`HANDOFF.md`**. Полный дизайн: **`GAME.md`**. Этапы: **`ROADMAP.md`**.

**Статус:** Phases 0–10 ✅ · Phase 12 код ✅ · **интерьеры Base1–3 в place работают** · дальше визуал карты.  
**Сейчас:** открытая карта / дворы / экстерьеры (см. `HANDOFF.md`). Phase 12c можно добить параллельно.  
Параллельно: Visual Map. Детали: `HANDOFF.md`.

---

## Phase 12 — Улучшения базы ← **код готов, Studio-проверка**

Реализация **разошлась** с ранним дизайном «Fence/Floor2/RestRoom только в книге»:

| Канал | Что | Где в коде |
| ----- | --- | ---------- |
| Магазин | двор: `wall2`, `jeep` (+ старый `reinforcedTrap`) | `BaseBuildService`, `BuyUpgrade` |
| Книга (`BookPrompt`) | интерьер: сегменты в `Map.Interiors` | `InteriorService`, `BuyInteriorUpgrade` |
| Режим карты | `Config.STUDIO_MAP_MODE = true` | не procedural `Bases` |

Дизайн-намерение: `GAME.md` → «Прокачка». Ожидания place: `HANDOFF.md`.

### 12a — Studio

- [ ] `Assets.BaseUpgrades` — `Wall2`, `Jeep` (не обязательно старые Fence/Floor2/RestRoom)
- [ ] Особняк: `UpgradeSlots` → `Slot_Wall2`, `Slot_Jeep`
- [ ] `Map.Interiors/Interior_BaseN` + `Segments` + blockers + `Spawn` (Base1–3 уже есть)
- [ ] Prompts: `HomePrompt`, `ExitPrompt`, `BookPrompt` (+ свои Lab/Shop/Jail)
- [ ] `Workspace.Bases` с `BaseId` (код при `STUDIO_MAP_MODE` не создаёт плиты)
- [ ] Экстерьеры: MansionEdit (Lv1), Mansion_2 Gothic, Mansion_3 (клон → заменить)

### 12b — Код ✅

- [x] DataStore: `baseUpgrades` (общие ключи для двора и интерьера)
- [x] Каталоги: `BaseBuildDefs`, `InteriorDefs` (+ цены в Config / defs)
- [x] Join sync: `BaseBuildService.syncForPlayer`, `InteriorService.syncForPlayer`
- [x] Remotes: `BuyUpgrade` (покупка/продажа построек), `BuyInteriorUpgrade`
- [x] UI магазина: wall2 / jeep; UI книги: список сегментов
- [x] `BookPrompt` → `InteriorController`; `HomePrompt` / `ExitPrompt` → телепорт

### 12c — Проверка ← **следующий шаг**

- [ ] Play Solo: купить wall2 / jeep → модель на слоте
- [ ] Книга: купить сегмент → виден в интерьере; prerequisite блокирует
- [ ] Stop → Play: улучшения на месте (DataStore)
- [ ] Чужой `HomePrompt` → toast, без телепорта
- [ ] ClientInit включает `InteriorController`; сервер грузит `SubjugationService`

**Пока не делаем:** свободная расстановка ловушек (Phase 13), полный каталог из GAME.md.

---

## Phase 13 — Магазин защиты + расстановка (после 12)

- [ ] Покупка камеры / ловушки в магазине → инвентарь базы
- [ ] Режим «Поставить» на дворе 14×14, лимиты слотов
- [ ] Сервер: валидация зоны, сохранение позиций
- [ ] Рейд: камера → alert; ловушка → эффект (связь с Phase 5+)

---

## Visual Map — Studio (параллельно, без кода)

Код не трогаем. Всё в **Edit mode** → **File → Save to Roblox**. Стиль позже: Soul Eater (мрачный мульт + whimsy), сейчас — Toolbox / Meshy / low-poly ок.

### ⚠️ Что код пересоздаёт при каждом Play

При **`STUDIO_MAP_MODE = true`** (сейчас в Config) procedural-плиты `Bases` **не** трогаются. Lab/Jail создаются только если код находит позиции баз.

| Папка / объект | Кто создаёт | Можно ли вешать визуал сюда? |
| -------------- | ----------- | ---------------------------- |
| `Workspace.Bases` | place (при map mode) / иначе `BaseMapService` | **Да** в map mode; иначе сотрётся |
| `Workspace.Labs` (капсула + `[E]`) | `LabService` (если есть base pos) | осторожно |
| `Workspace.Shops` | `ShopMapService` | осторожно |
| `Workspace.Jails` | `JailMapService` (если есть base pos) | осторожно |
| `Workspace.NpcHomes/House` | `NpcService` | **Нет** — сотрётся |
| `Workspace.Map` (своя папка) | **ты** | **Да** |
| `ReplicatedStorage.Assets` | **ты** | **Да** |

Декор и здания клади в **`Workspace.Map`**. Ожидания Phase 12 (слоты, Interiors, prompts) — `HANDOFF.md`.

### Точки привязки (6 баз, `Config.BASE_LAYOUT`)

Платформа: **14 × 1 × 14**, Y = **0.5**. Центры X: **-45, -22, 0, 22, 45, 68**, Z = **35**.

От центра spawn (смотри ориентацию плиты в Play):

| Зона | Смещение от spawn | Код / prompt |
| ---- | ----------------- | ------------ |
| **Лаборатория** | вправо (+RightVector, ~10 studs от центра) | `LabPrompt` на Orb |
| **Магазин** | влево (−RightVector) | `ShopPrompt` |
| **Клетка / влом** | вперёд (+LookVector) | `JailPrompt` |
| **NPC-жертва** | `(90, 0.5, 35)` | цель dispatch id=0 |

### Map V1 — Ландшафт и настроение ← **можно начать параллельно**

- [ ] Папка `Workspace.Map` (Terrain, Lighting, Sky)
- [ ] Земля / дорожки между 6 особняками и NPC-домом
- [ ] Освещение: контраст, лёгкий «мрачный мульт» (полное небо — позже)
- [ ] Не двигать координаты баз из Config без причины

### Map V2 — Особняк (шаблон × 6)

- [ ] Один **MansionTemplate** под двор 14×14 (дверь, стены, крыша — Toolbox ок)
- [ ] Поставить на **Base3** (центр, X=0) → Play Solo → проверить спавн и обход
- [ ] Дублировать на остальные 5 позиций; лёгкая вариация цвета/декора
- [ ] Имена: `Map/Mansions/Mansion_1` … `Mansion_6`

### Map V3 — Лаборатория (визуал)

- [ ] Комната / капсула / алхимический стол **справа** от особняка (см. таблицу)
- [ ] Внутри — место под монстра в капсуле (пока UI, 3D монстр в капсуле — Map V6)
- [ ] Play: placeholder-капсула появится в той же зоне — подгони здание вокруг неё

### Map V4 — Магазин и клетка

- [ ] **Магазин** слева от особняка (лавка, вывеска)
- [ ] **Клетка / тюрьма** спереди (решётка, цепи — вайб)
- [ ] То же для всех 6 баз или сначала только Base3

### Map V5 — Дом NPC-жертвы

- [ ] Модель дома у `(90, 0.5, 35)` в `Map/NpcHome`
- [ ] Узнаваемая цель на карте (жертва для первых dispatch)

### Map V6 — Монстры в Assets

- [x] `HairboundWraith` — dispatch walker (Mixamo With Skin)
- [ ] `Slime` — силуэт слизня (капсула / иконка)
- [ ] `Gremlin`, `ShadowRat`, `Homunculus` — по одному, тот же pipeline что Wraith
- [ ] Папка: `ReplicatedStorage.Assets.Monsters/<Name>`

### Map V7 — Склейка с кодом (когда вернёмся к разработке)

- [ ] Отключить автоплейсхолдеры Lab/Shop/Jail **или** читать Studio-модели из `Map`
- [ ] `LabPrompt` / `ShopPrompt` / `JailPrompt` на твои Part'ы
- [ ] Walker по типу монстра, монстр в капсуле на базе
- [ ] Phase 11 (баланс, polish, публикация) — после визуала или параллельно

**Проверка без кода:** Edit mode — расстояния, силуэты, читаемость.  
**С кодом:** Play Solo — спавн, `[E]` лаба/магазин/тюрьма, dispatch к NPC и к базе.

---

## Gameplay — Phases 0–10 ✅

Логика MVP в `HANDOFF.md`. Кратко: базы, лаба, dispatch, PvP, ловушки, выкуп, магазин, влом, подчинение, XP, Robux.

<details>
<summary>Старый список фаз (галочки)</summary>

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

## Phase 7 — Shop UI + Jail Break ✅

(Реализовано — см. HANDOFF.)

## Phase 8 — Subjugation & Progression ✅

## Phase 9 — Polish MVP ✅

## Phase 10 — Monetization ✅

## Phase 11 — Publish (код, после визуала)

- [ ] Финальный баланс
- [ ] Багфиксы
- [ ] Публикация / иконка / описание

</details>

## Как работаем с AI

1. **Cursor** — контекст, промпты, ревью
2. **Claude Code** — имплементация
3. **Ты** — тест в Studio
4. Один этап = один промпт
5. **Конец чата** — обновить `docs/HANDOFF.md`

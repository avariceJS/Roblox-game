# HANDOFF — прочитай первым в новом чате

> Живой документ. Стабильный контекст: **`PROJECT.md`**. Этапы: **`ROADMAP.md`**.

---

## Сейчас

|                   |                                                                   |
| ----------------- | ----------------------------------------------------------------- |
| **Фаза**          | Phase 3 ✅ + глубокий рефактор кода (Phases 0–3)                  |
| **Следующий шаг** | **Phase 4** — PvP Attack (список игроков + NPC-дом + attack flow) |
| **Блокеры**       | нет                                                               |
| **Workflow**      | `rojo serve` → Accept → **Stop → Play Solo**                      |

### Как продолжить

```
Продолжаем Rent-a-Monster. Прочитай docs/HANDOFF.md, docs/PROJECT.md, docs/ROADMAP.md.
Phase 4 — PvP Attack. Дай intent-промпт для Claude Code.
```

---

## Что работает (Play Solo, 2026-06-22)

- **6 баз** — сервер создаёт `Workspace.Bases` из `Config.BASE_LAYOUT` (`BaseMapService`)
- **HUD** — 🪙 монеты + 🌀 chaos + 🏠 #N (`HudController`)
- **Подсветка своей базы** — зелёный диск + Highlight + «▼ ВАШ ОСОБНЯК #N» (`BaseMarkerController`)
- **Лаборатория** — [E] у капсулы на **своей** базе → UI с Гуппи; чужая база → toast (`LabController`)
- **Стартовый монстр** — Slime/Гуппи при первом join (`MonsterService`)
- **Отправка монстра** — пикер 6 баз → walker-шар летит к цели → лужа → монеты+chaos → Fatigued → Idle
- **Workspace** организован: `Workspace.Bases`, `Workspace.Labs`, `Workspace.Missions`

---

## Архитектура (не ломать без причины)

### Remotes (ровно 4)

`GetPlayerData` (RemoteFunction) · `BaseAssigned` (RemoteEvent) · `MonsterUpdated` (RemoteEvent) · `DispatchMonster` (RemoteFunction)

Лаборатория **без** отдельного server remote: клиент слушает `ProximityPromptService.PromptTriggered` → `GetPlayerData:InvokeServer()` → проверка `baseId`.

### Bootstrap клиента (`ClientInit.client.lua`)

```
BaseMarkerController → LabController → HudController
```

**BaseMarker первым** — иначе гонка с `BaseAssigned`.

### Сервер при join

`PlayerDataService.load` → `BaseService.assign` → стартовый Slime → `MissionService.syncPlayerMonsters` → `BaseAssigned` + `MonsterUpdated` (deferred FireClient).

### Dispatch flow (Phase 3)

1. Клиент: `fnDispatch:InvokeServer({ targetBaseId, monsterId })` — monsterId = конкретный монстр
2. Сервер: `MissionService.dispatch(player, tgtId, requestedId)` — валидирует по id, проверяет state==Idle
3. `task.spawn(runMission)` → walker-шар (TweenService) → лужа → coins+chaos → Fatigued → scheduleFatigueRecovery
4. При join: `syncPlayerMonsters` восстанавливает OnMission→Idle, Fatigued→recovery timer

### Файлы

```
Server/   Main, BaseMapService, BaseService, PlayerDataService, MonsterService, LabService, MissionService
Shared/   Config, BaseUtil, MonsterDefs, MonsterDisplay
Client/   BaseMarkerController, LabController, HudController, UiUtil
bootstrap/ ServerInit, ClientInit
```

Удалено навсегда: `TrainingZoneService`, `MonsterCardController`, `OpenLab`/`LabOpened` remotes, `BaseService.configureSpawns`.

---

## ⚠️ Критично для Cursor (уже ломали)

1. **`ClientInit` — цепочка `require`:** ошибка в **первом** модуле → нет подсветки **и** нет лаборатории **и** нет HUD. Смотреть Output.
2. **Типичные причины падения:** удалили `Players`, оставили `Players.LocalPlayer`; неверный `require` пути; опечатка при «чистке».
3. **Не трогать без теста:** порядок bootstrap, remotes, `BaseMarkerController` как первый require.
4. **После правок кода:** Accept в Rojo → Stop → Play Solo (не Play поверх старой сессии).
5. **`syncPlayerMonsters`** при join: `OnMission→Idle`, `Fatigued expired→Idle`, `Fatigued active→scheduleFatigueRecovery`. Таймер не переживает Stop→Play, `fatigueUntil` в DataStore — источник правды.
6. **`LabService.init()`** — без аргументов, Config импортирован внутри модуля.
7. **`MissionService.dispatch(player, tgtId, requestedId?)`** — третий аргумент опционален; nil → первый Idle монстр.

---

## Последняя сессия (2026-06-22) — глубокий рефактор

### Изменено

| Файл                 | Было                                                                                        | Стало                                                                         | Зачем                                                         |
| -------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `Main.lua`           | `local Config = require(...)` + `BaseService.configureSpawns()` + `LabService.init(Config)` | убраны Config + вызов; `LabService.init()`                                    | Config не нужен в Main; configureSpawns дублировал ensure()   |
| `BaseService.lua`    | `configureSpawns()` — итерировал базы, ставил `Neutral=false`                               | удалена                                                                       | BaseMapService.ensure() уже создаёт с Neutral=false           |
| `LabService.lua`     | `init(config: { BASE_COUNT: number })`                                                      | `init()` — Config импортирован в модуле                                       | модуль самодостаточен                                         |
| `MissionService.lua` | walker/puddle → `workspace` напрямую; нет monsterId                                         | `_missionsFolder` (Workspace.Missions); `dispatch(player, tgt, requestedId?)` | порядок в workspace; клиент называет конкретный монстр        |
| `LabController.lua`  | `renderDispatch` объявлен ПОСЛЕ `refreshFatigueLabels`, форвард-референс → баг              | `renderDispatch` перемещён перед `refreshFatigueLabels`                       | Lua: `local function g()` не видна в `f()` объявленной раньше |
| `LabController.lua`  | `InvokeServer({ targetBaseId })`                                                            | `InvokeServer({ targetBaseId, monsterId })`                                   | сервер валидирует конкретный монстр                           |
| `PROJECT.md`         | `MonsterCardController`, 3 remotes                                                          | актуальный список файлов, 4 remotes                                           | устаревшие данные                                             |

### Не тронуто и почему

| Что                                                   | Почему                                                                           |
| ----------------------------------------------------- | -------------------------------------------------------------------------------- |
| `PlayerDataService` — нет dirty-flag                  | 3 save за dispatch — все с реальными изменениями; DataStore throttle справляется |
| `slowed` в MissionService                             | самоочищается через `task.delay(SLOW_DURATION)` — нет утечки                     |
| `CharacterAdded` conn в BaseService                   | Roblox очищает при уничтожении Player                                            |
| `makeId()` — clock+random                             | только при join; коллизии практически исключены для <=10 игроков                 |
| Весь `UiUtil`                                         | минимальный, без дублирования                                                    |
| `MonsterDisplay` — `first()` возвращает `monsters[1]` | одиночный монстр в Phase 3; Phase 4 добавит перебор по id                        |

### Риски регрессии

- `LabService.init()` без args: если где-то ещё вызывается с аргументом — ошибка. Проверить: только `Main.lua` вызывает init.
- `_missionsFolder` nil если `MissionService.init` не вызван до первого dispatch. Порядок в Main.lua: `MissionService.init` перед `fnDispatch.OnServerInvoke` — ок.
- Перестановка функций в LabController: визуальный регресс fatigue-таймера если что-то пропущено в edit. Тест: отправить монстра, открыть лаб — должен показывать обратный отсчёт.

---

## История сессий

| Дата       | Итог                                                            |
| ---------- | --------------------------------------------------------------- |
| 2026-06-21 | Setup, Rojo, Phase 1                                            |
| 2026-06-22 | Phase 2 ✅; Phase 3 (dispatch) ✅; глубокий рефактор Phases 0–3 |

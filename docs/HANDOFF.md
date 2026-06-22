# HANDOFF — прочитай первым в новом чате

> Живой документ. Стабильный контекст: **`PROJECT.md`**. Этапы: **`ROADMAP.md`**.

---

## Сейчас

|                   |                                                              |
| ----------------- | ------------------------------------------------------------ |
| **Фаза**          | Phase 4 ✅ — PvP Attack                                      |
| **Следующий шаг** | **Phase 5** — Defense (ловушки, клетка, захват монстра)      |
| **Блокеры**       | нет                                                          |
| **Workflow**      | `rojo serve` → Accept → **Stop → Play Solo** / **2 Players** |

### Как продолжить

```
Продолжаем Rent-a-Monster. Прочитай docs/HANDOFF.md, docs/PROJECT.md, docs/ROADMAP.md.
Phase 5 — Defense. Дай intent-промпт для Claude Code.
```

---

## Что работает (Play Solo / 2 Players, 2026-06-22)

- **6 баз** — сервер создаёт `Workspace.Bases` из `Config.BASE_LAYOUT` (`BaseMapService`)
- **NPC-дом** — `Workspace.NpcHomes/House`, коричневый Part, позиция из `Config.NPC_HOME_POSITION`
- **HUD** — 🪙 монеты + 🌀 chaos + 🏠 #N (`HudController`)
- **Подсветка своей базы** — зелёный диск + Highlight + «▼ ВАШ ОСОБНЯК #N» (`BaseMarkerController`)
- **Лаборатория** — [E] у капсулы на **своей** базе → UI с Гуппи; чужая база → toast (`LabController`)
- **Стартовый монстр** — Slime/Гуппи при первом join (`MonsterService`)
- **Отправка монстра** — пикер целей (NPC-дом + живые игроки) → walker-шар → лужа → монеты+chaos → Fatigued → Idle
- **Защитник** — toast-уведомление «⚠️ X натравил монстра на твою базу!» при атаке
- **Workspace** организован: `Workspace.Bases`, `Workspace.Labs`, `Workspace.Missions`, `Workspace.NpcHomes`

---

## Архитектура (не ломать без причины)

### Remotes (ровно 4)

`GetPlayerData` (RemoteFunction) · `BaseAssigned` (RemoteEvent) · `MonsterUpdated` (RemoteEvent) · `DispatchMonster` (RemoteFunction)

`MonsterUpdated` используется и для обновления монстров, и для defender-toast (payload без `monsters`).

Лаборатория **без** отдельного server remote: клиент слушает `ProximityPromptService.PromptTriggered` → `GetPlayerData:InvokeServer()` → проверка `baseId`.

### Bootstrap клиента (`ClientInit.client.lua`)

```
BaseMarkerController → LabController → HudController
```

**BaseMarker первым** — иначе гонка с `BaseAssigned`.

### Сервер при join

`PlayerDataService.load` → `BaseService.assign` → стартовый Slime → `MissionService.syncPlayerMonsters` → `BaseAssigned` + `MonsterUpdated` (deferred FireClient).

### Dispatch flow (Phase 4)

1. Клиент: `fnDispatch:InvokeServer({ targetBaseId, monsterId })` — targetBaseId=0 для NPC-дома
2. Сервер: `MissionService.dispatch(player, rawId, requestedId?)` — id=0 обрабатывается отдельно без normalizeId
3. `getMissionPlatform(targetId)` → NpcHome Part (id=0) или SpawnLocation базы (id≥1)
4. `task.spawn(runMission)` → walker-шар → лужа → coins+chaos → toast атакующему → toast защитнику → Fatigued → scheduleFatigueRecovery

### Пикер целей (LabController)

- `lastTargets` заполняется из `data.targets` при открытии лаборатории
- `pickerBtns[slotIdx]` + `pickerBtnIds[slotIdx]` — динамические кнопки (MAX_PICKER_BTNS=7)
- NPC-дом: коричневый фон `Color3.fromRGB(80, 45, 20)`; игрок: тёмно-синий

### Файлы

```
Server/   Main, BaseMapService, BaseService, NpcService, PlayerDataService, MonsterService, LabService, MissionService
Shared/   Config, BaseUtil, MonsterDefs, MonsterDisplay
Client/   BaseMarkerController, LabController, HudController, UiUtil
bootstrap/ ServerInit, ClientInit
```

---

## ⚠️ Критично для Cursor (уже ломали)

1. **`ClientInit` — цепочка `require`:** ошибка в **первом** модуле → нет подсветки **и** нет лаборатории **и** нет HUD. Смотреть Output.
2. **Типичные причины падения:** удалили `Players`, оставили `Players.LocalPlayer`; неверный `require` пути; опечатка при «чистке».
3. **Не трогать без теста:** порядок bootstrap, remotes, `BaseMarkerController` как первый require.
4. **После правок кода:** Accept в Rojo → Stop → Play Solo (не Play поверх старой сессии).
5. **`syncPlayerMonsters`** при join: `OnMission→Idle`, `Fatigued expired→Idle`, `Fatigued active→scheduleFatigueRecovery`. Таймер не переживает Stop→Play, `fatigueUntil` в DataStore — источник правды.
6. **`LabService.init()`** — без аргументов, Config импортирован внутри модуля.
7. **`MissionService.dispatch(player, rawId, requestedId?)`** — rawId передаётся as-is из Main (не normalizeId); 0 = NPC-дом.
8. **`MissionService.init(pds, ev, baseService)`** — третий аргумент BaseService обязателен для defender toast.
9. **`evMonsterUpdated` toast-only payload** — LabController: если `payload.toast` и нет `payload.monsters` → показать toast, вернуться. HudController не ломается (payload без monsters игнорируется).

---

## Последняя сессия (2026-06-22) — Phase 4 PvP Attack

### Создано

| Файл                    | Что сделано                                          |
| ----------------------- | ---------------------------------------------------- |
| `Server/NpcService.lua` | новый; создаёт `Workspace.NpcHomes/House` при старте |

### Изменено

| Файл                        | Изменение                                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `Shared/Config.lua`         | `NPC_HOME_ID=0`, `NPC_HOME_POSITION`                                                                               |
| `Shared/BaseUtil.lua`       | `getNpcHome()`, `getMissionPlatform(targetId)`                                                                     |
| `Server/BaseService.lua`    | `getOccupied()`, `getOccupant(baseId)`                                                                             |
| `Server/MissionService.lua` | `_bs`, `init(+baseService)`, `runMission` → getMissionPlatform + defender toast, `dispatch` → id=0 ветка           |
| `Server/Main.lua`           | Config+NpcService, NpcService.init(), BaseService в MissionService.init, rawId в dispatch, targets в GetPlayerData |
| `Client/LabController.lua`  | pickerBtns+pickerBtnIds (динамический пикер), lastTargets, toast-only handler                                      |

### Риски регрессии

- `pickerBack.Position = UDim2.new(0, 8, 1, -52)` — при MAX_PICKER_BTNS=7 (4 ряда) кнопка «Назад» может перекрываться. Тест: открыть пикер с 7 целями.
- `NpcService.init()` удаляет существующий `NpcHomes` и пересоздаёт — безопасно при Stop→Play.
- Defender toast приходит через `MonsterUpdated` — HudController должен обрабатывать payload без `monsters` без краша. Проверить HudController.

---

## История сессий

| Дата       | Итог                                                                              |
| ---------- | --------------------------------------------------------------------------------- |
| 2026-06-21 | Setup, Rojo, Phase 1                                                              |
| 2026-06-22 | Phase 2 ✅; Phase 3 (dispatch) ✅; глубокий рефактор Phases 0–3; Phase 4 (PvP) ✅ |

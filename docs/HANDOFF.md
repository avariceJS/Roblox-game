# HANDOFF — прочитай первым в новом чате

> Живой документ. Стабильный контекст: **`PROJECT.md`**. Этапы: **`ROADMAP.md`**.

---

## Сейчас

|                   |                                                              |
| ----------------- | ------------------------------------------------------------ |
| **Фаза**          | Phase 10 ✅ — Robux shop, монетизация                        |
| **Следующий шаг** | **Phase 11** — финальный баланс, polish, публикация          |
| **UX-долг**       | нет                                                          |
| **Блокеры**       | нет                                                          |
| **Workflow**      | `rojo serve` → Accept → **Stop → Play Solo** / **2 Players** |

### Дизайн после поимки (зафиксировано)

Полная логика: **`GAME.md` → «Пойманный монстр»**. Кратко: выкуп (Phase 6 ✅) → влом (Phase 7) → подчинение / компенсация (Phase 8) → Robux (8+). **Нет освобождения через 5 мин.**

### Как продолжить

```
Продолжаем Rent-a-Monster. Прочитай docs/HANDOFF.md, docs/PROJECT.md, docs/ROADMAP.md, docs/GAME.md.
Phase 10 — Robux shop, монетизация, финальный баланс. Дай intent-промпт для Claude Code.
```

---

## Что работает (Play Solo / 2 Players, 2026-06-28)

- **6 баз** — сервер создаёт `Workspace.Bases` из `Config.BASE_LAYOUT` (`BaseMapService`)
- **NPC-дом** — `Workspace.NpcHomes/House`, коричневый Part, позиция из `Config.NPC_HOME_POSITION`
- **HUD** — 🪙 монеты + 🌀 chaos + 🏠 #N (`HudController`)
- **Подсветка своей базы** — зелёный диск + Highlight + «▼ ВАШ ОСОБНЯК #N» (`BaseMarkerController`)
- **Лаборатория** — [E] у капсулы на **своей** базе → UI с монстрами + клетка + выкуп + подчинение; чужая база → toast (`LabController`)
- **Стартовый монстр** — Slime/Гуппи при первом join (`MonsterService`)
- **Отправка монстра** — пикер целей → walker-шар (цвет по типу) → лужа (цвет + частицы) → монеты+chaos+XP → Fatigued → Idle; при level up — toast через 1.5 сек
- **XP и уровни** — `DISPATCH_XP=10`, `XP_PER_LEVEL=30`; уровень отображается в карточке монстра «Обычный | Ур.N»
- **4 монстра** — Slime 🐸 / Gremlin 👺 / ShadowRat 🐀 / Homunculus 🧿 в MonsterDefs + ShopController
- **Защитник** — toast при атаке; ловушка Cage в лаборатории
- **Клетка** — при Cage + атаке: монстр → Captured, запись в `data.jail` с `subjugateAttempts=0`
- **Выкуп** — задаёт цену (25/50/100/200); владелец → платит → монстр Idle
- **Подчинение** — кнопка «Подчинить» в панели клетки; 50% шанс, 3 попытки; успех → монстр у захватчика; провал × 3 → авто-компенсация 30💰
- **Магазин** — `Workspace.Shops/Shop_BaseN`; покупка 4 монстров + квест +25💰 + «Усиленная ловушка» 150💰
- **Влом** — `Workspace.Jails/Jail_BaseN`; если Cage → alert; если `reinforcedTrap` → 40% поймать Idle монстр вломщика; иначе монстр Idle
- **Base Upgrade** — `baseUpgrades.reinforcedTrap` в DataStore; куплено в ShopController; влияет в JailBreakService
- **Studio-only:** `Config.STUDIO_WALK_SPEED = 64` — быстрая ходьба в Play Solo для тестов

---

## Архитектура (не ломать без причины)

### Remotes (12)

`GetPlayerData` (RF) · `BaseAssigned` (RE) · `MonsterUpdated` (RE) · `DispatchMonster` (RF) · `SetTrap` (RF) · `SetRansom` (RF) · `PayRansom` (RF) · `BuyMonster` (RF) · `DoQuest` (RF) · `AttemptJailBreak` (RF) · `AttemptSubjugate` (RF) · `BuyUpgrade` (RF)

`MonsterUpdated` — универсальный: monsters, coins, chaos, jail, hasCage, nextQuestAt, upgrades, toast (любое сочетание).

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
Server/   Main, BaseMapService, BaseService, NpcService, PlayerDataService, MonsterService, LabService, MissionService, TrapService, RansomService, ShopService, ShopMapService, JailMapService, JailBreakService, SubjugationService
Shared/   Config, BaseUtil, MonsterDefs, MonsterDisplay
Client/   BaseMarkerController, LabController, ShopController, HudController, UiUtil
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
9. **`evMonsterUpdated`** — LabController обрабатывает `payload.hasCage`, `payload.jail`, `payload.monsters`, `payload.nextQuestAt` независимо. HudController показывает toast если есть `payload.toast`.
10. **`RansomService.payRansom`** вызывает `PlayerDataService.modifyByUserId` напрямую (require внутри модуля) — захватчик может быть оффлайн.
11. **Лаборатория Phase 6**: `jailSlots[i]` (кнопки) → `ransomPanel` overlay (ZIndex=8); `dispatchBtn` для Captured с ransomPrice становится активным (PayRansom).
12. **`questCooldownUntil`** в DataStore — таймер квеста переживает Stop→Play; клиент синхронизируется через `GetPlayerData.nextQuestAt`.
13. **Выкуп старых пленников:** если нет `capturedByUserId` — `RansomService` ищет захватчика через `jail` + `BaseService.getOccupant`; при SetRansom backfill `capturedByUserId`.
14. **Лаборатория ≠ магазин:** лаба = монстры, отправка, ловушка, клетка, выкуп, подчинение. Магазин, квесты, апгрейды — ShopController.
15. **`SubjugationService.attemptSubjugate(capturer, monsterId)`** — ищет запись в `capturer.jail`; 50% шанс; провал × 3 → авто-компенсация 30💰 + удаление монстра у обоих.
16. **`baseUpgrades`** в DataStore; `reinforcedTrap=true` → 40% ловушка в JailBreakService; отображается в ShopController как «куплено».
17. **`monster.xp/level`** — `MissionService.runMission` начисляет XP; level up toast через 1.5 сек; `MonsterDisplay.fill` показывает «Обычный | Ур.N».

---

## Последняя сессия (Cursor, 2026-06-24) — контекст + Phase 6 polish

### Сделано в этом чате (Cursor + мелкие правки кода)

| Тема           | Итог                                                                                                       |
| -------------- | ---------------------------------------------------------------------------------------------------------- |
| Phase 3 polish | 🌀 chaos в HUD; выбор монстра → «Отправить»; таймер fatigue; убрана карточка снизу (MonsterCardController) |
| Fatigue bug    | `syncPlayerMonsters` при join — таймер не переживал Stop→Play                                              |
| Phase 4–6      | Intent-промпты для Claude Code; GAME.md — логика плена без авто-освобождения                               |
| PvP toast      | Уведомление защитнику **при отправке**, не после пакости; убран дубль toast (только HudController)         |
| Studio QA      | `STUDIO_WALK_SPEED` в Config + BaseService                                                                 |
| Выкуп bug      | «Нет данных о захватчике» — fallback `capturedByUserId` через jail / base occupant                         |
| Phase 6 ✅     | Выкуп, покупка Slime, квест — проверено 2 Players (Claude Code)                                            |
| UX-решение     | Магазин **не должен** быть в лаборатории → **Phase 7, первый шаг**                                         |

### Phase 6 (Claude Code) — уже в коде

См. таблицы ниже (RansomService, ShopService, remotes SetRansom/PayRansom/BuyMonster/DoQuest).

---

## Предыдущая сессия (2026-06-24) — Phase 6 Economy & Jail Ransom (Claude Code)

### Создано

| Файл                       | Что сделано                                                                              |
| -------------------------- | ---------------------------------------------------------------------------------------- |
| `Server/RansomService.lua` | `setRansom(defData, monsterId, price)`, `payRansom(payerData, monsterId)` — offline-safe |
| `Server/ShopService.lua`   | `buyMonster(data, monsterType)` — списывает монеты, добавляет монстра в data.monsters    |

### Изменено

| Файл                           | Изменение                                                                                                                          |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `Shared/Config.lua`            | RANSOM_MIN=10, RANSOM_MAX=500, SHOP_PRICES={Slime=50}, QUEST_REWARD=25, QUEST_COOLDOWN=120                                         |
| `Server/PlayerDataService.lua` | `questCooldownUntil=0` в defaultData+load; `getByUserId`, `modifyByUserId` (online cache + offline DS)                             |
| `Server/MissionService.lua`    | bug fix `def.name`→`def.displayName`; `capturedByUserId` + `ransomPrice=nil` в capture block                                       |
| `Server/Main.lua`              | +RansomService, ShopService; 4 remotes (SetRansom, PayRansom, BuyMonster, DoQuest) + handlers; `nextQuestAt` в GetPlayerData       |
| `Client/LabController.lua`     | Panel 600px; jailSlots×3 (TextButton); ransomPanel overlay; shopSection+buySlimeBtn; questBtn с countdown; PayRansom в dispatchBtn |

### Риски регрессии

- Phase 3–5 flow без изменений в логике — проверить dispatch к NPC-дому и PvP поимку.
- `modifyByUserId` пишет в DS напрямую — не вызывать часто (rate limit DataStore).
- `ransomPanel` ZIndex=8 перекрывает всё в panel — не должен быть виден при открытом picker.

---

## Предыдущая сессия (2026-06-24) — Phase 5 Defense

### Создано

| Файл                     | Что сделано                                                      |
| ------------------------ | ---------------------------------------------------------------- |
| `Server/TrapService.lua` | setCage, hasCage; CAGE_COST=0 (бесплатно), TRAP_CATCH_CHANCE=1.0 |

### Изменено

| Файл                           | Изменение                                                                                                                                      |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `Shared/Config.lua`            | `CAGE_COST=0`, `TRAP_CATCH_CHANCE=1.0`                                                                                                         |
| `Server/PlayerDataService.lua` | `defaultData()` + `load()` — `jail = {}`                                                                                                       |
| `Server/MissionService.lua`    | `runMission`: capture block (hasCage → Captured + jail insert + FireClient обоим); defender toast перенесён в runMission                       |
| `Server/Main.lua`              | TrapService, SetTrap remote+handler, GetPlayerData → jail+hasCage                                                                              |
| `Client/LabController.lua`     | SetTrap remote, defenseSection (cageBtn+jailFrame), updateCageButton, renderJail, Captured case в renderDispatch, evMonsterUpdated рефакторинг |

### Риски регрессии

- Phase 3–4 flow без ловушки не изменён — проверить dispatch к NPC-дому.
- `picker.Visible` + `defenseSection.Visible` связаны — проверить переход пикер→назад.

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

| Дата       | Итог                                                                                                                   |
| ---------- | ---------------------------------------------------------------------------------------------------------------------- |
| 2026-06-21 | Setup, Rojo, Phase 1                                                                                                   |
| 2026-06-22 | Phase 2 ✅; Phase 3 ✅; рефактор; Phase 4 (PvP) ✅; Phase 5 (Defense) ✅                                               |
| 2026-06-24 | Phase 6 ✅ (выкуп, магазин в лабе, квест); фикс ransom; UX: магазин → Phase 7                                          |
| 2026-06-28 | Phase 7–8 ✅ (влом, подчинение, XP/уровни, 4 монстра, upgradeShop); Phase 9 ✅ (balance + UX-polish + VFX + bug fixes) |

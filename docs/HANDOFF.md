# HANDOFF — прочитай первым в новом чате

> Живой документ. Стабильный контекст: **`PROJECT.md`**. Этапы: **`ROADMAP.md`**.

---

## Сейчас

| | |
|---|---|
| **Фаза** | Phase 2 ✅ **завершена** (проверено в Studio) |
| **Следующий шаг** | **Phase 3** — отправка монстра в выбранный дом |
| **Блокеры** | нет |
| **Workflow** | `rojo serve` → Accept → **Stop → Play Solo** |

### Как продолжить

```
Продолжаем Rent-a-Monster. Прочитай docs/HANDOFF.md, docs/PROJECT.md, docs/ROADMAP.md.
Phase 3 — отправка монстра в выбранный дом. Дай intent-промпт для Claude Code.
```

---

## Что работает (Play Solo, 2026-06-22)

- **6 баз** — сервер создаёт `Workspace.Bases` из `Config.BASE_LAYOUT` (`BaseMapService`)
- **HUD** — 🪙 монеты + 🏠 #N (`HudController`)
- **Подсветка своей базы** — зелёный диск + Highlight + «▼ ВАШ ОСОБНЯК #N» (`BaseMarkerController`)
- **Лаборатория** — [E] у капсулы на **своей** базе → UI с Гуппи; чужая база → toast (`LabController`)
- **Карточка монстра** — внизу слева (`MonsterCardController`)
- **Стартовый монстр** — Slime/Гуппи при первом join (`MonsterService`)
- Кнопка «Отправить — скоро» в лабе — **disabled**, Phase 3

---

## Архитектура (не ломать без причины)

### Remotes (ровно 3)

`GetPlayerData` · `BaseAssigned` · `MonsterUpdated`

Лаборатория **без** server remote: клиент слушает `ProximityPromptService.PromptTriggered` → `GetPlayerData:InvokeServer()` → проверка `baseId`.

### Bootstrap клиента (`ClientInit.client.lua`)

```
BaseMarkerController → LabController → HudController → MonsterCardController
```

**BaseMarker первым** — иначе гонка с `BaseAssigned`.

### Сервер при join

`PlayerDataService.load` → `BaseService.assign` → стартовый Slime → `BaseAssigned` + `MonsterUpdated` (deferred FireClient).

### Файлы

```
Server/   Main, BaseMapService, BaseService, PlayerDataService, MonsterService, LabService
Shared/   Config, BaseUtil, MonsterDefs, MonsterDisplay
Client/   BaseMarkerController, LabController, HudController, MonsterCardController, UiUtil
bootstrap/ ServerInit, ClientInit
```

Удалено навсегда: `TrainingZoneService`, `OpenLab`/`LabOpened`, `SessionClient`, код лужи на тренплощадке.

---

## ⚠️ Критично для Cursor (уже ломали 3 раза)

1. **`ClientInit` — цепочка `require`:** ошибка в **первом** модуле → нет подсветки **и** нет лаборатории **и** нет HUD. Смотреть Output.
2. **Типичные причины падения:** удалили `Players`, оставили `Players.LocalPlayer`; неверный `require` пути; опечатка при «чистке».
3. **Не трогать без теста:** порядок bootstrap, remotes, `BaseMarkerController` как первый require.
4. **После правок кода:** Accept в Rojo → Stop → Play Solo (не Play поверх старой сессии).

---

## Последняя сессия (2026-06-22)

### Сделано

- Phase 2 доведена до рабочего состояния: лаборатория per base, подсветка, HUD, карточка
- Базы и капсулы из кода; клиент открывает лаб через `ProximityPromptService`
- Рефакторинг: убраны `SessionClient`, `CoinsUpdated`, legacy remotes cleanup в `Main`
- Исправлен регресс: `Players.LocalPlayer` без импорта в `BaseMarkerController` — валил весь клиент

### Решения

| Решение | Почему |
|---------|--------|
| Лаборатория **в каждом особняке** | не глобальная трензона |
| Проверка владельца на **клиенте** через `GetPlayerData` | E работает, чужие базы — toast |
| Кнопка «Отправить» disabled | Phase 3 |
| Без туториала / NPC | по дизайну |

### Phase 3 (не начато)

- UI: выбор цели (база другого игрока)
- Монстр идёт к цели
- Slime → липкая лужа **на целевой базе**
- Награда, fatigue, состояние OnMission

---

## История сессий

| Дата | Итог |
|------|------|
| 2026-06-21 | Setup, Rojo, Phase 1 |
| 2026-06-22 | Phase 2: лаборатория в особняке ✅; рефакторинг; фикс client bootstrap |

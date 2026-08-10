# HANDOFF — прочитай первым в новом чате

> Живой документ. Стабильный контекст: **`PROJECT.md`**. Этапы: **`ROADMAP.md`**.

---

## Сейчас

|                   |                                                              |
| ----------------- | ------------------------------------------------------------ |
| **Фаза**          | **Phase 12** код ✅ · **визуал / карта** в Studio             |
| **Геймплей**      | Phases 0–10 ✅ · интерьеры Lv1–3 собраны и работают           |
| **Следующий шаг** | Строить **открытую карту** (дворы, 6 баз, декор, экстерьеры) |
| **Визуал карты**  | `STUDIO_MAP_MODE=true` — place, не procedural Bases          |
| **Блокеры**       | нет                                                          |
| **Workflow**      | Snapshot → советы; Command Bar-скрипты из `tools/`           |

### Интерьеры (готово, проверено)

Три «коробки» в облаках + книга прокачки (купить/продать). Книга показывает **только сегменты своего** `Interior_BaseN`.

| ID | Размер Shell | ORIGIN (примерно) | Сегментов | Экстерьер |
| -- | ------------ | ----------------- | --------- | --------- |
| **Base1** | 28×18, H11 | `(50, 520, 0)` | 5 | `Map.Build.MansionEdit` + `HomeDoor` |
| **Base2** | 40×26, H12 | `(50, 520, 100)` | 7 | `Mansions.Mansion_2` + `GothicHouse_Lv2` |
| **Base3** | 56×36, H13 | `(50, 520, 220)` | 9 | `Mansions.Mansion_3` + `GothicHouse_Lv3` (клон Lv2, **заменить**) |

**Каталог** (`InteriorDefs.lua`): общие ключи; у большего дома больше сегментов в place.

- Всегда: `room1_extra`, `stairs`, `floor2`→needs stairs, `floor2_room1`, `basement_lab` (+`HatchRim`)
- Base2+: `room2_extra`, `floor2_room2`
- Base3+: `room3_extra`, `floor2_room3`

**Механика:** Shell цельный; покупка **скрывает** blocker (`WallCut_*` / `CeilingPlug_Stairs` / `FloorCut_*`), продажа возвращает. Blockers внутри `floor2` не светятся до покупки 2 этажа.

**Критично:** покупки применяются к **активному** `InteriorId` (куда вошёл через `HomePrompt`), не только к `data.baseId`. Иначе улучшения «уезжали» в Base1.

Текстуры: стены `rbxassetid://139986462838305`, пол `rbxassetid://110666654316364` — **Decal** (не Texture с тайлингом).

### Studio place (ожидания)

| Объект | Зачем |
| ------ | ----- |
| `Workspace.Bases.BaseN` + `BaseId` | спавн (пока часто только Base1) |
| `Map.Interiors.Interior_Base1..3` + `InteriorId` | Shell / Blockers / Segments / Spawn |
| `Map.Mansions.Mansion_2/3` | экстерьер + `Home/HomeDoor` (`BaseId`, `InteriorId`) |
| `Map.Build.MansionEdit` | Base1 двор/слоты |
| `HomePrompt` / `ExitPrompt` / `BookPrompt` | вход / выход / книга |
| `Assets.BaseUpgrades` | Wall2, Jeep |

Если на карте одна база: `link-mansion*-home` ставит на дверь твой единственный `BaseId`, но `InteriorId=Base2/3` — вход в нужный интерьер.

### Инструменты карты (`tools/`)

| Файл | Назначение |
| ---- | ---------- |
| `studio-snapshot/` | плагин + `receive.py` → `docs/snapshots/latest.json` |
| `build-interior-base1/2/3.command.lua` | пересобрать интерьер (Command Bar → Run) |
| `link-mansion2-home.command.lua` | Meshy/Gothic → Lv2 + HomeDoor |
| `link-mansion3-home.command.lua` | клон Lv2 → Lv3 + HomeDoor |
| `place-six-lv1-mansions.command.lua` | только 6× Lv1 на улице; Lv2/Lv3 → `ServerStorage.HouseTemplates` |

Snapshot: `python3 tools/studio-snapshot/receive.py` + Plugins → **Snapshot Map**. Плагин также снимает Models в корне Workspace.

### Как продолжить (чат)

```
Продолжаем Rent-a-Monster. Прочитай docs/HANDOFF.md.
Строим открытую карту (дворы Base1–6, экстерьеры, декор).
Интерьеры Lv1–3 уже работают — не ломать Interior_Base* без нужды.
Snapshot → docs/snapshots/latest.json; Command Bar-скрипты из tools/ ок.
```

---

## Что работает (логика)

- Phases 0–10 + Phase 12 (двор + книга + интерьеры)  
- `BuyInteriorUpgrade` + `sell: true`  
- `STUDIO_WALK_SPEED = 64`

---

## Архитектура (кратко)

```
HomePrompt → InteriorService (activeInteriorId) → Spawn
BookPrompt → InteriorController (фильтр по сегментам InteriorId)
Buy/Sell → applySegment / revertSegment на activeInteriorId
```

`baseUpgrades` в DataStore — общие ключи (двор + интерьер).  
**Без комментариев в `.lua`.**

---

## Последняя сессия (2026-08-09) — три интерьера + карта-тулинг

### Сделано

| Тема | Итог |
| ---- | ---- |
| Base1 hermetic Shell | blockers hide/show, sell в книге |
| Base2 / Base3 | больше площадь и комнаты; скрипты build + link |
| Баг покупок | apply шёл на `baseId` → чинили через `activeInteriorId` |
| Snapshot | Map/Bases/Assets + Workspace models → `docs/snapshots/` |
| Экстерьер Lv2 | Gothic Meshy; Lv3 = клон (заменить позже) |

### Следующий фокус

Открытая карта / дворы / 6 баз / финальные экстерьеры. Интерьеры не трогать без запроса.

---

## История сессий

| Дата | Итог |
| ---- | ---- |
| 2026-06-21…28 | Phases 0–10, walker |
| 2026-07–08 | Phase 12 код (двор, книга, STUDIO_MAP_MODE) |
| 2026-08-05 | Синк доков / bootstrap / Subjugation path |
| 2026-08-06…09 | Snapshot-тулинг; Interior Base1–3; sell; activeInteriorId; Gothic links |

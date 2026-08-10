# PROJECT — стабильный контекст (не меняется каждую сессию)

> **Новый чат:** сначала `HANDOFF.md` (что сделано недавно), потом этот файл (как устроен проект).

## Что это

**Rent-a-Monster** — Roblox-игра: игроки собирают монстров и используют их для пакостей, защиты базы, рейдов. Не pet-simulator — **монстр = инструмент с поведением**.

Vision и **весь** дизайн: `docs/GAME.md` (единый файл, маппинг фич → ROADMAP в конце)  
Этапы: `ROADMAP.md`  
Поведение систем: `ARCHITECTURE.md`  
Studio + Rojo: `STUDIO.md`

## Ключевая петля (MVP)

1. Игрок в **своём особняке** (Base1–6)
2. **Лаборатория** на базе — монстры в **капсулах**
3. Выбрал монстра → выбрал **целевой дом** → монстр **сам идёт** туда
4. На месте — **пакость** (у Slime — липкая лужа), награда, усталость
5. Магазин / книга — покупки и улучшения здания
6. Защита, рейды, экономика — Phases 5–10 ✅

**Без** отдельной тренировочной площадки и **без** туториала.

## Репозиторий

```
~/Desktop/Roblox-game/
  src/                    ← весь код (правим здесь)
    Server/               Main, PlayerData, Base*, Mission, Interior, …
    Shared/               Config, MonsterDefs, BaseBuildDefs, InteriorDefs
    Client/               Hud, Lab, Shop, Interior, WalkerAnim, …
    Remotes/              создаются в Main при старте
  bootstrap/
    ServerInit.server.lua → ServerScriptService.Init
    ClientInit.client.lua → StarterPlayerScripts.Init
  tools/                  ← Studio Command Bar + snapshot (карта/интерьеры)
    studio-snapshot/      плагин Map Snapshot + receive.py → docs/snapshots/
    build-interior-base*.command.lua
    link-mansion*-home.command.lua
  default.project.json    ← Rojo
  docs/
    snapshots/latest.json ← снимок place для AI (не источник правды кода)
```

## Как код попадает в Studio

- **Rojo:** `rojo serve` + Plugins → Connect → Accept sync
- В Studio: **`ReplicatedStorage → src`** (не в корне game — иначе Play Solo ломается)
- Два bootstrap: `ServerScriptService/Init`, `StarterPlayerScripts/Init`
- При Play Rojo **отключается** — это нормально
- Experience Settings → Security: **Allow HTTP Requests** + **Enable Studio Access to API Services**

## Карта (Studio, не в git)

- **`Config.STUDIO_MAP_MODE = true`** (сейчас): код **не** пересоздаёт `Workspace.Bases` — place сам держит базу/особняк/prompts.
- `BaseMapService` при `false` — procedural 6 плит из `Config.BASE_LAYOUT`.
- Декор / особняк / интерьеры — в **`Workspace.Map`** (+ `Assets` в ReplicatedStorage).
- **Три интерьера:** `Map.Interiors.Interior_Base1..3` (attr `InteriorId`). Размеры и сегменты — **`HANDOFF.md`**.
- Экстерьеры Lv2/Lv3: `Map.Mansions.Mansion_2/3` + `HomeDoor` (`BaseId` + `InteriorId`).
- Ожидаемые имена слотов, prompts — **`HANDOFF.md`**.
- Снимок для AI: `tools/studio-snapshot` → `docs/snapshots/latest.json`.

## Как работаем с AI

| Кто             | Роль                                          |
| --------------- | --------------------------------------------- |
| **Cursor**      | контекст, intent-промпты, ревью, правки, карта через snapshot/Command Bar |
| **Claude Code** | имплементация — **сам решает как писать код** |
| **Ты**          | тест в Studio, feedback                       |

Промпты = **что хотим и как должно работать для игрока**, не рецепты кода.  
Один этап ROADMAP за промпт/сессию. Карта: Snapshot → советы → при необходимости `.command.lua` в Command Bar.

Конфиг: `CLAUDE.md`, `.cursor/rules/`, `.claude/`

## Ключевые технические решения

| Решение                       | Почему                                                      |
| ----------------------------- | ----------------------------------------------------------- |
| `ReplicatedStorage.src`       | реплицируется на клиент; корень `game.src` — нет HUD в Play |
| ModuleScripts + Init          | весь код в `src`, Roblox требует стартеры в SSS / SPS       |
| Server authority              | монеты, базы, миссии, покупки — только сервер               |
| DataStore key `PlayerData_v1` | coins, chaos, baseId, monsters, jail, **baseUpgrades**, …   |
| Лаборатория per BaseId        | центр UI монстров                                           |
| Книга ≠ магазин               | книга — интерьер; магазин — монстры/квест/двор/trap         |
| `activeInteriorId`            | покупки книги → тот интерьер, куда вошёл (не путать с baseId) |
| Книга фильтрует сегменты      | в UI только defs, для которых есть Model в `Segments/`      |
| Blockers hide, не Destroy     | продажа комнаты возвращает стену/люк                        |
| Стены = Decal                 | Texture тайлится (`StudsPerTile`); Decal натягивается       |
| **Без комментариев в `.lua`** | объяснения в чате, не в коде                                |

## Файлы кода (ориентир)

| Файл / папка                          | Назначение                                      |
| ------------------------------------- | ----------------------------------------------- |
| `src/Server/Main.lua`                 | join/leave, remotes, оркестрация                |
| `src/Server/BaseBuildService.lua`     | Clone построек во двор (wall2, jeep)            |
| `src/Server/InteriorService.lua`      | телепорт, сегменты, buy/sell, activeInteriorId  |
| `src/Server/MissionService.lua`       | dispatch, fatigue, capture                      |
| `src/Server/MonetizationService.lua`  | Robux products / gamepasses                     |
| `src/Shared/Config.lua`               | константы, `STUDIO_MAP_MODE`, цены              |
| `src/Shared/BaseBuildDefs.lua`        | шаблоны/слоты двора                             |
| `src/Shared/InteriorDefs.lua`         | полный каталог сегментов книги                  |
| `src/Client/LabController.lua`        | лаборатория + dispatch                          |
| `src/Client/ShopController.lua`       | магазин                                         |
| `src/Client/InteriorController.lua`   | UI книги (фильтр по InteriorId / Segments)      |
| `bootstrap/ClientInit.client.lua`     | порядок require клиентских контроллеров         |
| `tools/build-interior-base*.command.lua` | пересборка интерьеров в Studio               |
| `tools/link-mansion*-home.command.lua`   | HomeDoor у экстерьера → Interior_BaseN       |
| `tools/studio-snapshot/`              | экспорт дерева place в JSON                     |

Актуальный список remotes и нюансы — **`HANDOFF.md`**.

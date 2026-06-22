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
2. **Лаборатория** на базе — монстры в **капсулах**, покупка/прокачка (позже)
3. Выбрал монстра → выбрал **целевой дом** → монстр **сам идёт** туда
4. На месте — **пакость** (у Slime — липкая лужа), награда, усталость
5. Защита, рейды, экономика — следующие фазы

**Без** отдельной тренировочной площадки и **без** туториала.

## Репозиторий

```
~/Desktop/project/
  src/                    ← весь код (правим здесь)
    Server/               Main, PlayerData, Base, Monster, …
    Shared/               Config, MonsterDefs
    Client/               HudController, MonsterCardController, …
    Remotes/              создаются в Main при старте
  bootstrap/
    ServerInit.server.lua → ServerScriptService.Init
    ClientInit.client.lua → StarterPlayerScripts.Init
  default.project.json    ← Rojo
  docs/
```

## Как код попадает в Studio

- **Rojo:** `rojo serve` + Plugins → Connect → Accept sync
- В Studio: **`ReplicatedStorage → src`** (не в корне game — иначе Play Solo ломается)
- Два bootstrap: `ServerScriptService/Init`, `StarterPlayerScripts/Init`
- При Play Rojo **отключается** — это нормально
- Experience Settings → Security: **Allow HTTP Requests** + **Enable Studio Access to API Services**

## Карта (Studio, не в git)

- **Базы создаёт код** при старте сервера (`BaseMapService`) — 6 особняков в `Workspace.Bases`
- Ручные `Base1–6` в Studio **можно удалить** — при Play их заменит код из `Config.BASE_LAYOUT`
- Decal / визуал на базах — опционально, на логику не влияет

## Как работаем с AI

| Кто             | Роль                                          |
| --------------- | --------------------------------------------- |
| **Cursor**      | контекст, intent-промпты, ревью, правки       |
| **Claude Code** | имплементация — **сам решает как писать код** |
| **Ты**          | тест в Studio, feedback                       |

Промпты = **что хотим и как должно работать для игрока**, не рецепты кода.  
Один этап ROADMAP за промпт/сессию.

Конфиг: `CLAUDE.md`, `.cursor/rules/`, `.claude/`

## Ключевые технические решения

| Решение                       | Почему                                                      |
| ----------------------------- | ----------------------------------------------------------- |
| `ReplicatedStorage.src`       | реплицируется на клиент; корень `game.src` — нет HUD в Play |
| ModuleScripts + Init          | весь код в `src`, Roblox требует стартеры в SSS / SPS       |
| Server authority              | монеты, базы, миссии, способности — только сервер           |
| DataStore key `PlayerData_v1` | coins, chaos, baseId, monsters, traps                       |
| Лаборатория per BaseId        | центр UI монстров, не глобальная зона на карте              |
| **Без комментариев в `.lua`** | объяснения в чате, не в коде                                |

## Файлы кода

| Файл                                  | Назначение                                                   |
| ------------------------------------- | ------------------------------------------------------------ |
| `src/Server/Main.lua`                 | join/leave, remotes, оркестрация                             |
| `src/Server/BaseMapService.lua`       | создание 6 баз при старте                                    |
| `src/Server/BaseService.lua`          | assign base, spawn                                           |
| `src/Server/PlayerDataService.lua`    | DataStore                                                    |
| `src/Server/MonsterService.lua`       | стартовый Slime                                              |
| `src/Server/LabService.lua`           | капсулы лаборатории на базах                                 |
| `src/Server/MissionService.lua`       | dispatch, runMission, fatigue                                |
| `src/Shared/Config.lua`               | все константы игры                                           |
| `src/Shared/BaseUtil.lua`             | поиск баз, normalizeId                                       |
| `src/Shared/MonsterDefs.lua`          | данные типов монстров                                        |
| `src/Shared/MonsterDisplay.lua`       | общий UI монстра                                             |
| `src/Client/HudController.lua`        | монеты + chaos + номер базы                                  |
| `src/Client/BaseMarkerController.lua` | подсветка своей базы                                         |
| `src/Client/LabController.lua`        | UI лаборатории + dispatch                                    |
| Remotes (4)                           | GetPlayerData, BaseAssigned, MonsterUpdated, DispatchMonster |

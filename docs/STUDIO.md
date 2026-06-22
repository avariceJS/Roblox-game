# Roblox Studio + Rojo

## Что синхронится автоматически

| Где правишь | В Studio |
|-------------|----------|
| `src/` | **`ReplicatedStorage → src`** |
| `bootstrap/` | `ServerScriptService/Init` + `StarterPlayerScripts/Init` |
| Карта, базы | `Workspace` — только в place |

**Весь наш код — в `ReplicatedStorage.src`.** Нельзя класть `src` в корень game: при Play Solo Roblox не реплицирует это на клиент → нет HUD и монет.

**Rojo отключается при Play — это нормально.** Главное — код уже в place после Accept.

Структура — `src/README.md`.

---

## Однократная настройка

### 1. Rojo CLI

```bash
brew install aftman
cd ~/Desktop/project
aftman install
```

После `aftman install` команда `rojo` часто **не находится** — бинарник лежит в `~/.aftman/bin`, но PATH не обновлён.

**Один раз** добавь в `~/.zshrc`:

```bash
source "$HOME/.aftman/env"
```

Перезапусти терминал (или `source ~/.zshrc`), проверь:

```bash
rojo --version   # Rojo 7.4.4
cd ~/Desktop/project
rojo serve
```

### 2. Плагин Rojo в Studio

- [Rojo plugin на Roblox](https://create.roblox.com/store/asset/13916111004/Rojo-7-4-4) → Install
- Или: Studio → **Plugins** → **Manage Plugins** → найти Rojo

### 3. Experience Settings (обязательно две галочки)

**Не** Home → маленькая шестерёнка рядом с Collaborate (это другое).

Правильный путь:

1. Меню **File** → **Experience Settings…**  
   (или **Game Settings…** — зависит от языка Studio)
2. Вкладка **Security** / **Безопасность**
3. Включить **обе**:
   - **Allow HTTP Requests** — без этого Rojo пишет `Http requests can only be executed by game server`
   - **Enable Studio Access to API Services** — без этого DataStore в Studio не работает
4. **Save**

Важно:
- Place должен быть **опубликован** (File → Publish to Roblox), иначе вкладки/опции иногда не активны
- После Publish галочки могут **сброситься** — проверь снова
- Подключай Rojo только в **Edit mode** (Stop Play), не во время игры

### 4. Базы на карте (BaseId)

В Explorer: `Workspace → Bases → Base1…Base6`

На **каждой** базе (`Base1`…`Base6`):

| Поле | Значение |
|------|----------|
| `BaseId` (Attribute) | `1` … `6` |
| **Neutral** | **выключен** (код тоже выключает при старте) |

База может быть **сам SpawnLocation** или папка со SpawnLocation внутри — оба варианта ок.

---

## Play Solo — что нормально

| Что видишь | Нормально? |
|------------|------------|
| Rojo **Disconnect** при Play | ✅ да |
| В Explorer другой вид дерева | ✅ да |
| **`ReplicatedStorage → src` есть в Play** | должно быть |
| 🪙 100 на экране | ✅ Phase 1 работает |

После Stop — Rojo снова Connect, правки из IDE снова синхронятся.

После большого Sync: **File → Save to Roblox** — сохранить place с кодом.

---

## После смены структуры Rojo

Rojo покажет **View changes / Sync** → нажми **Accept**. Перезапусти `rojo serve` если были ошибки в терминале.

Удали вручную старые папки (`RentAMonster`, пустой `StarterGui/UI`), если остались после Accept.

---

## Каждый день разработки

**Терминал 1** (оставить открытым):

```bash
cd ~/Desktop/project
rojo serve
```

**Studio:**

1. Открыть **свой place** (с картой и Bases)
2. **Plugins → Rojo → Connect** (адрес `localhost:34872` по умолчанию)
3. Правки в `src/` → через 1–2 сек появляются в Explorer

Claude Code / Cursor пишут в `src/` → ты видишь в Studio без перетаскивания.

**Сохраняй place** в Studio после изменений карты (File → Save to Roblox / Publish).

---

## Если Rojo не подключается

| Симптом | Решение |
|---------|---------|
| `Http requests can only be executed by game server` | **Allow HTTP Requests** в Experience Settings → Security |
| `Connecting to session…` и висит | Stop Play → Connect снова; перезапусти `rojo serve` |
| Скрипты не появляются | Edit mode, не Play; `rojo serve` на `localhost:34872` |
| Всё равно не работает | Отключи другие плагины (Discord Presence и т.п.) — они жрут HTTP лимит Studio |

Общее:
- `rojo serve` запущен в терминале?
- Connect **после Stop**, не во время Play
- Перезапуск: Disconnect → Stop serve → `rojo serve` → Connect

---

## Позже (опционально)

- Экспорт баз в `assets/Bases.rbxmx` и подключение через Rojo — когда захочешь версионировать карту в git
- `rojo build -o build.rbxl` — собрать place из репо (когда карта тоже в репо)

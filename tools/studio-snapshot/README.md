# Map Snapshot — экспорт дерева карты из Studio в JSON для Cursor

## Зачем

Place-карта не в git. Плагин снимает `Map` / `Bases` / `Assets` (или Selection) → JSON в `docs/snapshots/`. Cursor читает файл и советует по строительству.

## Установка плагина (один раз)

1. Закрой Roblox Studio.
2. Скопируй файл в папку плагинов:

```bash
mkdir -p ~/Documents/Roblox/Plugins
cp tools/studio-snapshot/ExportMapSnapshot.plugin.lua ~/Documents/Roblox/Plugins/
```

3. Открой Studio — на вкладке **Plugins** появятся кнопки **Snapshot Map** и **Snapshot Selection**.

## Экспорт

В терминале (из корня репо):

```bash
python3 tools/studio-snapshot/receive.py
```

В Studio (Edit mode, не Play):

1. **File → Experience Settings → Security → Allow HTTP Requests** = ON  
2. Plugins → **Snapshot Map** (или выдели объекты → **Snapshot Selection**)

Файлы:

- `docs/snapshots/latest.json` — всегда последний снимок  
- `docs/snapshots/map-YYYYMMDD-HHMMSS.json` — архив  

Если HTTP не сработал — JSON копируется в буфер; плюс backup в `ServerStorage._MapSnapshot`.

## Если кнопки «молчат»

1. **Edit mode** (не Play Solo) — плагины в Play часто не шлют HTTP.
2. Открой **View → Output** — должны появиться строки `[Map Snapshot] клик…`.
3. При первом HTTP Studio может показать **Allow** для `127.0.0.1` / `localhost` — разреши.
4. Переустанови плагин после обновления файла:

```bash
cp tools/studio-snapshot/ExportMapSnapshot.plugin.lua ~/Documents/Roblox/Plugins/
```

Перезапусти Studio.

5. Если корней нет — выдели `Interiors` / `Map` в Explorer → **Snapshot Selection**.

## Что внутри JSON

Иерархия + для Parts: size/position/orientation/material/color; для Decal/Texture: texture id, face, StudsPerTile; attributes, tags, ProximityPrompt.

Напиши в чат: «посмотри docs/snapshots/latest.json» — и можно разбирать архитектуру стройки.

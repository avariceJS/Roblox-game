# src — весь код игры

В Studio: **`ReplicatedStorage → src`**

```
src/
  Server/     Main, PlayerData, Base*, Mission, Interior, Shop*, Jail*, Monetization, …
  Shared/     Config, BaseUtil, MonsterDefs, MonsterDisplay, BaseBuildDefs, InteriorDefs
  Client/     Hud, BaseMarker, Lab, Shop, Interior, WalkerAnim, UiUtil
  Remotes/    создаются в Main при старте
```

Запуск: `ServerScriptService/Init`, `StarterPlayerScripts/Init`  
Порядок клиента: `BaseMarker → Lab → Shop → Interior → WalkerAnim → Hud`

Актуальное состояние фаз — `docs/HANDOFF.md`.

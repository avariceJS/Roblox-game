local Players = game:GetService("Players")

local src = game.ReplicatedStorage:WaitForChild("src")
local Shared = src:WaitForChild("Shared")
local Remotes = src:WaitForChild("Remotes")
local Server = src:WaitForChild("Server")

local PlayerDataService = require(Server.PlayerDataService)
local BaseMapService = require(Server.BaseMapService)
local BaseService = require(Server.BaseService)
local MonsterService  = require(Server.MonsterService)
local LabService      = require(Server.LabService)
local MissionService  = require(Server.MissionService)
local Config = require(Shared.Config)
local BaseUtil = require(Shared.BaseUtil)

BaseMapService.ensure()
BaseService.configureSpawns()

local LEGACY_REMOTES = { "OpenLab", "LabOpened" }

local function ensureRemote(name: string, class: string): Instance
	local existing = Remotes:FindFirstChild(name)
	if existing and not existing:IsA(class) then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		existing = Instance.new(class)
		existing.Name = name
		existing.Parent = Remotes
	end
	return existing
end

for _, legacyName in LEGACY_REMOTES do
	local legacy = Remotes:FindFirstChild(legacyName)
	if legacy then
		legacy:Destroy()
	end
end

local fnGetData = ensureRemote("GetPlayerData", "RemoteFunction") :: RemoteFunction
local evMonsterUpdated = ensureRemote("MonsterUpdated", "RemoteEvent") :: RemoteEvent
local evBaseAssigned = ensureRemote("BaseAssigned", "RemoteEvent") :: RemoteEvent
local fnDispatch     = ensureRemote("DispatchMonster", "RemoteFunction") :: RemoteFunction

LabService.init(Config)
MissionService.init(PlayerDataService, evMonsterUpdated)

fnDispatch.OnServerInvoke = function(player: Player, payload: { targetBaseId: number? })
	local tgtId = BaseUtil.normalizeId(payload and payload.targetBaseId)
	if not tgtId then
		return { ok = false, message = "Неверная цель" }
	end
	return MissionService.dispatch(player, tgtId)
end

local function waitForPlayerData(player: Player)
	for _ = 1, 50 do
		local data = PlayerDataService.get(player)
		if data and data.baseId then
			return data
		end
		task.wait(0.1)
	end
	return PlayerDataService.get(player)
end

fnGetData.OnServerInvoke = function(player: Player)
	local data = waitForPlayerData(player)
	if not data then
		return { ok = false, message = "Не удалось загрузить данные" }
	end
	if not data.baseId then
		return { ok = false, message = "Все 6 баз заняты — зайди позже!" }
	end

	return {
		ok = true,
		coins = data.coins,
		chaos = data.chaos,
		baseId = BaseUtil.normalizeId(data.baseId),
		monsters = data.monsters,
	}
end

local function onPlayerAdded(player: Player)
	local data = PlayerDataService.load(player)
	local baseId = BaseService.assign(player, data.baseId)
	if not baseId then
		warn("[Main] No free base for", player.Name)
		return
	end

	data.baseId = BaseUtil.normalizeId(baseId)
	if MonsterService.giveStarterMonster(player, data) then
		PlayerDataService.save(player)
	end

	BaseService.setupSpawn(player, data.baseId)
	MissionService.syncPlayerMonsters(player)

	task.defer(function()
		if not player.Parent then
			return
		end
		evBaseAssigned:FireClient(player, { baseId = data.baseId })
		evMonsterUpdated:FireClient(player, { monsters = data.monsters })
	end)
end

local function onPlayerRemoving(player: Player)
	PlayerDataService.save(player)
	BaseService.release(player)
	task.defer(PlayerDataService.unload, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

return nil

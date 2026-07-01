local Players = game:GetService("Players")

local src = game.ReplicatedStorage:WaitForChild("src")
local Shared = src:WaitForChild("Shared")
local Remotes = src:WaitForChild("Remotes")
local Server = src:WaitForChild("Server")

local Config          = require(Shared.Config)
local PlayerDataService = require(Server.PlayerDataService)
local BaseMapService  = require(Server.BaseMapService)
local BaseService     = require(Server.BaseService)
local NpcService      = require(Server.NpcService)
local MonsterService  = require(Server.MonsterService)
local LabService      = require(Server.LabService)
local MissionService  = require(Server.MissionService)
local TrapService      = require(Server.TrapService)
local RansomService    = require(Server.RansomService)
local ShopService      = require(Server.ShopService)
local ShopMapService   = require(Server.ShopMapService)
local JailMapService   = require(Server.JailMapService)
local JailBreakService      = require(Server.JailBreakService)
local SubjugationService    = require(Server.SubjugationService)
local MonetizationService   = require(Server.MonetizationService)
local BaseUtil              = require(Shared.BaseUtil)
local BaseBuildDefs         = require(Shared.BaseBuildDefs)
local BaseBuildService      = require(Server.BaseBuildService)

BaseMapService.ensure()
BaseBuildService.prepareMap()
NpcService.init()
ShopMapService.init()
JailMapService.init()

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

local fnGetData        = ensureRemote("GetPlayerData",  "RemoteFunction") :: RemoteFunction
local evMonsterUpdated = ensureRemote("MonsterUpdated", "RemoteEvent")    :: RemoteEvent
local evBaseAssigned   = ensureRemote("BaseAssigned",   "RemoteEvent")    :: RemoteEvent
local fnDispatch       = ensureRemote("DispatchMonster","RemoteFunction") :: RemoteFunction
local fnSetTrap        = ensureRemote("SetTrap",        "RemoteFunction") :: RemoteFunction
local fnSetRansom      = ensureRemote("SetRansom",      "RemoteFunction") :: RemoteFunction
local fnPayRansom      = ensureRemote("PayRansom",      "RemoteFunction") :: RemoteFunction
local fnBuyMonster        = ensureRemote("BuyMonster",        "RemoteFunction") :: RemoteFunction
local fnDoQuest           = ensureRemote("DoQuest",           "RemoteFunction") :: RemoteFunction
local fnAttemptJailBreak  = ensureRemote("AttemptJailBreak",   "RemoteFunction") :: RemoteFunction
local fnAttemptSubjugate  = ensureRemote("AttemptSubjugate",   "RemoteFunction") :: RemoteFunction
local fnBuyUpgrade           = ensureRemote("BuyUpgrade",           "RemoteFunction") :: RemoteFunction
local fnSetPurchaseIntent    = ensureRemote("SetPurchaseIntent",    "RemoteFunction") :: RemoteFunction

LabService.init()
MissionService.init(PlayerDataService, evMonsterUpdated, BaseService)
JailBreakService.init(evMonsterUpdated)
SubjugationService.init(evMonsterUpdated)
MonetizationService.init(PlayerDataService, evMonsterUpdated)

fnSetTrap.OnServerInvoke = function(player: Player, payload: { active: boolean })
	local data = PlayerDataService.get(player)
	if not data then
		return { ok = false, message = "Данные не загружены" }
	end
	local active = payload and payload.active == true
	local result = TrapService.setCage(data, active)
	if result.ok then
		PlayerDataService.save(player)
		evMonsterUpdated:FireClient(player, { hasCage = TrapService.hasCage(data), coins = data.coins })
	end
	return result
end

fnSetRansom.OnServerInvoke = function(player: Player, payload: { monsterId: string, price: number })
	local data = PlayerDataService.get(player)
	if not data then
		return { ok = false, message = "Данные не загружены" }
	end
	local result = RansomService.setRansom(data, payload.monsterId, payload.price)
	if not result.ok then
		return result
	end
	PlayerDataService.save(player)

	local ownerUserId = nil
	for _, entry in data.jail do
		if entry.monsterId == payload.monsterId then
			ownerUserId = entry.ownerUserId
			break
		end
	end
	if ownerUserId then
		PlayerDataService.modifyByUserId(ownerUserId, function(ownerData)
			for _, m in ownerData.monsters do
				if m.id == payload.monsterId then
					m.ransomPrice = result.price
					if not m.capturedByUserId then
						m.capturedByUserId = player.UserId
					end
					break
				end
			end
		end)
		local ownerPlayer = Players:GetPlayerByUserId(ownerUserId)
		if ownerPlayer and ownerPlayer.Parent then
			local ownerData = PlayerDataService.get(ownerPlayer)
			if ownerData then
				evMonsterUpdated:FireClient(ownerPlayer, { monsters = ownerData.monsters })
			end
		end
	end

	evMonsterUpdated:FireClient(player, { jail = data.jail })
	return result
end

fnPayRansom.OnServerInvoke = function(player: Player, payload: { monsterId: string })
	local data = PlayerDataService.get(player)
	if not data then
		return { ok = false, message = "Данные не загружены" }
	end
	local result = RansomService.payRansom(data, payload.monsterId)
	if not result.ok then
		return result
	end
	PlayerDataService.save(player)
	evMonsterUpdated:FireClient(player, {
		monsters = data.monsters,
		coins    = data.coins,
		toast    = "Монстр выкуплен за 💰" .. result.price .. "! 🐸",
	})
	local capturerPlayer = Players:GetPlayerByUserId(result.capturedByUserId)
	if capturerPlayer and capturerPlayer.Parent then
		local capData = PlayerDataService.get(capturerPlayer)
		if capData then
			evMonsterUpdated:FireClient(capturerPlayer, {
				jail  = capData.jail,
				coins = capData.coins,
				toast = "Монстр выкуплен: получил 💰" .. result.price .. "!",
			})
		end
	end
	return result
end

fnBuyMonster.OnServerInvoke = function(player: Player, payload: { monsterType: string })
	local data = PlayerDataService.get(player)
	if not data then
		return { ok = false, message = "Данные не загружены" }
	end
	local result = ShopService.buyMonster(data, payload.monsterType)
	if result.ok then
		PlayerDataService.save(player)
		evMonsterUpdated:FireClient(player, {
			monsters = data.monsters,
			coins    = data.coins,
			toast    = "Купил нового монстра! 🐸",
		})
	end
	return result
end

fnDoQuest.OnServerInvoke = function(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return { ok = false, message = "Данные не загружены" }
	end
	local now = os.time()
	if now < (data.questCooldownUntil or 0) then
		return { ok = false, message = "Квест ещё на перезарядке" }
	end
	local vipBonus = data.hasVip == true and Config.VIP_BONUS or 0
	local earned   = math.floor(Config.QUEST_REWARD * (1 + vipBonus))
	data.coins             = data.coins + earned
	data.questCooldownUntil = now + Config.QUEST_COOLDOWN
	PlayerDataService.save(player)
	evMonsterUpdated:FireClient(player, {
		coins       = data.coins,
		nextQuestAt = data.questCooldownUntil,
		toast       = "Выполнил мелкую работу! +💰" .. earned .. (vipBonus > 0 and " 💎" or ""),
	})
	return { ok = true }
end

fnSetPurchaseIntent.OnServerInvoke = function(player: Player, payload: { productKey: string?, monsterId: string? })
	local productKey = payload and payload.productKey
	local monsterId  = payload and payload.monsterId
	if not productKey then
		return { ok = false, message = "Неверные данные" }
	end
	return MonetizationService.setPurchaseIntent(player, productKey, monsterId)
end

fnAttemptSubjugate.OnServerInvoke = function(player: Player, payload: { monsterId: string? })
	if not payload or not payload.monsterId then
		return { ok = false, message = "Неверные данные" }
	end
	return SubjugationService.attemptSubjugate(player, payload.monsterId)
end

fnBuyUpgrade.OnServerInvoke = function(player: Player, payload: { upgradeKey: string?, sell: boolean? })
	local data = PlayerDataService.get(player)
	if not data then
		return { ok = false, message = "Данные не загружены" }
	end
	local key = payload and payload.upgradeKey
	if not key then
		return { ok = false, message = "Неверный апгрейд" }
	end
	if BaseBuildDefs[key] then
		if payload.sell == true then
			return BaseBuildService.sell(player, data, key, evMonsterUpdated)
		end
		return BaseBuildService.purchase(player, data, key, evMonsterUpdated)
	end
	local price = Config.UPGRADE_PRICES[key]
	if not price then
		return { ok = false, message = "Апгрейд не найден" }
	end
	if (data.baseUpgrades or {})[key] then
		return { ok = false, message = "Уже куплен" }
	end
	if data.coins < price then
		return { ok = false, message = "Недостаточно монет" }
	end
	data.coins = data.coins - price
	data.baseUpgrades = data.baseUpgrades or {}
	data.baseUpgrades[key] = true
	PlayerDataService.save(player)
	evMonsterUpdated:FireClient(player, {
		coins    = data.coins,
		upgrades = data.baseUpgrades,
		toast    = "Куплено: Усиленная ловушка! 🔩",
	})
	return { ok = true }
end

fnAttemptJailBreak.OnServerInvoke = function(player: Player, payload: { targetBaseId: number? })
	local targetBaseId = payload and payload.targetBaseId
	if not targetBaseId then
		return { ok = false, message = "Неверная цель" }
	end
	return JailBreakService.attemptBreak(player, targetBaseId)
end

fnDispatch.OnServerInvoke = function(player: Player, payload: { targetBaseId: number?, monsterId: string? })
	local rawId = payload and payload.targetBaseId
	if rawId == nil then
		return { ok = false, message = "Неверная цель" }
	end
	return MissionService.dispatch(player, rawId, payload and payload.monsterId)
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

	local myBaseId = BaseUtil.normalizeId(data.baseId)
	local targets = {}
	table.insert(targets, { id = Config.NPC_HOME_ID, label = "🏚️  NPC-дом", targetType = "npc" })
	for baseId, occupant in BaseService.getOccupied() do
		if baseId ~= myBaseId then
			table.insert(targets, {
				id         = baseId,
				label      = "👤 " .. occupant.Name .. " — База #" .. baseId,
				targetType = "player",
			})
		end
	end

	return {
		ok          = true,
		coins       = data.coins,
		chaos       = data.chaos,
		baseId      = myBaseId,
		monsters    = data.monsters,
		targets     = targets,
		jail        = data.jail or {},
		hasCage     = TrapService.hasCage(data),
		nextQuestAt = data.questCooldownUntil or 0,
		upgrades     = data.baseUpgrades or {},
		hasVip       = data.hasVip or false,
		hasExtraSlot = data.hasExtraSlot or false,
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
	BaseBuildService.syncForPlayer(player, data)
	MissionService.syncPlayerMonsters(player)
	task.spawn(MonetizationService.checkGamePasses, player, data)

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

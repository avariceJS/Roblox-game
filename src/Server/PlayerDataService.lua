local DataStoreService = game:GetService("DataStoreService")
local Config = require(game.ReplicatedStorage.src.Shared.Config)
local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local store = DataStoreService:GetDataStore(Config.DATASTORE_KEY)
local cache: { [number]: any } = {}

local PlayerDataService = {}

local function defaultData()
	return {
		coins = Config.START_COINS,
		chaos = Config.START_CHAOS,
		baseId = nil,
		monsters = {},
		traps = {},
		jail = {},
		questCooldownUntil = 0,
	}
end

function PlayerDataService.load(player: Player)
	local key = "player_" .. player.UserId
	local ok, result = pcall(store.GetAsync, store, key)
	local data: any

	if ok and result then
		data = result
		data.monsters = data.monsters or {}
		data.traps = data.traps or {}
		data.jail = data.jail or {}
		data.chaos = data.chaos or 0
		data.questCooldownUntil = data.questCooldownUntil or 0
		data.baseId = BaseUtil.normalizeId(data.baseId)
	else
		if not ok then
			warn("[PlayerData] Load error for", player.Name, ":", result)
		end
		data = defaultData()
	end

	cache[player.UserId] = data
	return data
end

function PlayerDataService.save(player: Player)
	local data = cache[player.UserId]
	if not data then
		return
	end

	local key = "player_" .. player.UserId
	local ok, err = pcall(store.SetAsync, store, key, data)
	if not ok then
		warn("[PlayerData] Save error for", player.Name, ":", err)
	end
end

function PlayerDataService.get(player: Player)
	return cache[player.UserId]
end

function PlayerDataService.getByUserId(userId: number)
	return cache[userId]
end

function PlayerDataService.findCaptorUserIdForMonster(monsterId: string): number?
	for userId, data in cache do
		for _, entry in data.jail do
			if entry.monsterId == monsterId then
				return userId
			end
		end
	end
	return nil
end

function PlayerDataService.modifyByUserId(userId: number, fn: (data: any) -> ())
	local data = cache[userId]
	if data then
		fn(data)
		local key = "player_" .. userId
		pcall(store.SetAsync, store, key, data)
		return
	end
	local key = "player_" .. userId
	local ok, result = pcall(store.GetAsync, store, key)
	if ok and result then
		result.monsters           = result.monsters or {}
		result.traps              = result.traps or {}
		result.jail               = result.jail or {}
		result.questCooldownUntil = result.questCooldownUntil or 0
		fn(result)
		pcall(store.SetAsync, store, key, result)
	end
end

function PlayerDataService.unload(player: Player)
	cache[player.UserId] = nil
end

return PlayerDataService

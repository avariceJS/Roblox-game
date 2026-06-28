local Config = require(game.ReplicatedStorage.src.Shared.Config)
local MonsterDefs = require(game.ReplicatedStorage.src.Shared.MonsterDefs)

local ShopService = {}

local function makeId(): string
	return tostring(math.floor(os.clock() * 1000)) .. tostring(math.random(100, 999))
end

function ShopService.buyMonster(data, monsterType: string): { ok: boolean, message: string? }
	local price = Config.SHOP_PRICES[monsterType]
	if not price then
		return { ok = false, message = "Неизвестный тип монстра" }
	end
	if not MonsterDefs[monsterType] then
		return { ok = false, message = "Монстр не найден в базе" }
	end
	if data.coins < price then
		return { ok = false, message = "Недостаточно монет (нужно " .. price .. ")" }
	end
	local maxSlots = Config.MAX_MONSTERS + (data.hasExtraSlot == true and 1 or 0)
	if #data.monsters >= maxSlots then
		return { ok = false, message = "Все слоты монстров заполнены" }
	end
	data.coins = data.coins - price
	table.insert(data.monsters, {
		id           = makeId(),
		type         = monsterType,
		level        = 1,
		xp           = 0,
		state        = "Idle",
		fatigueUntil = 0,
	})
	return { ok = true }
end

return ShopService

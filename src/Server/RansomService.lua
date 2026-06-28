local Config = require(game.ReplicatedStorage.src.Shared.Config)
local PlayerDataService = require(game.ReplicatedStorage.src.Server.PlayerDataService)
local BaseService = require(game.ReplicatedStorage.src.Server.BaseService)

local RansomService = {}

local function resolveCaptorUserId(monster: any, monsterId: string): number?
	if monster.capturedByUserId then
		return monster.capturedByUserId
	end
	local fromJail = PlayerDataService.findCaptorUserIdForMonster(monsterId)
	if fromJail then
		return fromJail
	end
	local baseId = monster.capturedByBaseId
	if baseId then
		local occupant = BaseService.getOccupant(baseId)
		if occupant then
			return occupant.UserId
		end
	end
	return nil
end

function RansomService.setRansom(defenderData, monsterId: string, price: number): { ok: boolean, price: number?, message: string? }
	local clamped = math.clamp(math.floor(price), Config.RANSOM_MIN, Config.RANSOM_MAX)
	for _, entry in defenderData.jail do
		if entry.monsterId == monsterId then
			entry.ransomPrice = clamped
			return { ok = true, price = clamped }
		end
	end
	return { ok = false, message = "Монстр не найден в клетке" }
end

function RansomService.payRansom(payerData, monsterId: string): { ok: boolean, price: number?, capturedByUserId: number?, message: string? }
	local monster = nil
	for _, m in payerData.monsters do
		if m.id == monsterId then
			monster = m
			break
		end
	end
	if not monster or monster.state ~= "Captured" then
		return { ok = false, message = "Монстр не захвачен" }
	end
	local price = monster.ransomPrice
	if not price or price <= 0 then
		return { ok = false, message = "Цена выкупа не установлена" }
	end
	if payerData.coins < price then
		return { ok = false, message = "Недостаточно монет (нужно " .. price .. ")" }
	end
	local capturedByUserId = resolveCaptorUserId(monster, monsterId)
	if not capturedByUserId then
		return { ok = false, message = "Нет данных о захватчике" }
	end
	monster.capturedByUserId = capturedByUserId

	payerData.coins          = payerData.coins - price
	monster.state            = "Idle"
	monster.fatigueUntil     = 0
	monster.capturedByBaseId = nil
	monster.capturedByName   = nil
	monster.capturedByUserId = nil
	monster.ransomPrice      = nil

	PlayerDataService.modifyByUserId(capturedByUserId, function(capData)
		capData.coins = (capData.coins or 0) + price
		for i, entry in capData.jail do
			if entry.monsterId == monsterId then
				table.remove(capData.jail, i)
				break
			end
		end
	end)

	return { ok = true, price = price, capturedByUserId = capturedByUserId }
end

return RansomService

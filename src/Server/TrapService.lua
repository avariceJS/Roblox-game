local Config = require(game.ReplicatedStorage.src.Shared.Config)

local TrapService = {}

function TrapService.setCage(data, active: boolean): { ok: boolean, message: string? }
	if active and Config.CAGE_COST > 0 then
		if (data.coins or 0) < Config.CAGE_COST then
			return { ok = false, message = "Недостаточно монет" }
		end
		data.coins = data.coins - Config.CAGE_COST
	end
	if not data.traps then data.traps = {} end
	data.traps.cage = active
	return { ok = true }
end

function TrapService.hasCage(data): boolean
	return data.traps ~= nil and data.traps.cage == true
end

return TrapService

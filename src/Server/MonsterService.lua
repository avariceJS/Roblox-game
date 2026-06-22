local MonsterService = {}

local function makeId(): string
	return tostring(math.floor(os.clock() * 1000)) .. tostring(math.random(100, 999))
end

function MonsterService.giveStarterMonster(_player: Player, data: { monsters: { any } }): boolean
	if #data.monsters > 0 then
		return false
	end

	table.insert(data.monsters, {
		id = makeId(),
		type = "Slime",
		level = 1,
		xp = 0,
		state = "Idle",
		fatigueUntil = 0,
	})
	return true
end

return MonsterService

local Players           = game:GetService("Players")
local Config            = require(game.ReplicatedStorage.src.Shared.Config)
local PlayerDataService = require(game.ReplicatedStorage.src.Server.PlayerDataService)
local MonsterDefs       = require(game.ReplicatedStorage.src.Shared.MonsterDefs)

local _ev = nil

local SubjugationService = {}

function SubjugationService.init(ev)
	_ev = ev
end

local function makeId(): string
	return tostring(math.floor(os.clock() * 1000)) .. tostring(math.random(100, 999))
end

local function findJailEntry(capturerData: any, monsterId: string): (any?, number?)
	for i, entry in capturerData.jail do
		if entry.monsterId == monsterId then
			return entry, i
		end
	end
	return nil, nil
end

local function compensate(capturerData: any, entry: any, jailIdx: number)
	capturerData.coins = (capturerData.coins or 0) + Config.SUBJUGATE_COMPENSATION
	table.remove(capturerData.jail, jailIdx)

	PlayerDataService.modifyByUserId(entry.ownerUserId, function(ownerData: any)
		for i, m in ownerData.monsters do
			if m.id == entry.monsterId then
				table.remove(ownerData.monsters, i)
				break
			end
		end
	end)

	local ownerPlayer = Players:GetPlayerByUserId(entry.ownerUserId)
	if ownerPlayer and ownerPlayer.Parent then
		local ownerData = PlayerDataService.get(ownerPlayer)
		if ownerData then
			_ev:FireClient(ownerPlayer, {
				monsters = ownerData.monsters,
				toast    = "Монстр потерян — захватчик получил компенсацию 💀",
			})
		end
	end
end

function SubjugationService.attemptSubjugate(
	capturer: Player,
	monsterId: string
): { ok: boolean, message: string? }
	local capturerData = PlayerDataService.get(capturer)
	if not capturerData then
		return { ok = false, message = "Нет данных" }
	end

	local entry, jailIdx = findJailEntry(capturerData, monsterId)
	if not entry then
		return { ok = false, message = "Монстр не в клетке" }
	end

	local attempts = entry.subjugateAttempts or 0

	if attempts >= Config.SUBJUGATE_ATTEMPTS_MAX then
		return { ok = false, message = "Попытки исчерпаны" }
	end

	local success = math.random() < Config.SUBJUGATE_CHANCE

	if success then
		local ownerUserId = entry.ownerUserId
		local monsterType = entry.monsterType or "Slime"
		local def = MonsterDefs[monsterType] or MonsterDefs.Slime

		table.remove(capturerData.jail, jailIdx)

		table.insert(capturerData.monsters, {
			id           = makeId(),
			type         = monsterType,
			level        = 1,
			xp           = 0,
			state        = "Idle",
			fatigueUntil = 0,
		})
		PlayerDataService.save(capturer)

		PlayerDataService.modifyByUserId(ownerUserId, function(ownerData: any)
			for i, m in ownerData.monsters do
				if m.id == monsterId then
					table.remove(ownerData.monsters, i)
					break
				end
			end
		end)

		local ownerPlayer = Players:GetPlayerByUserId(ownerUserId)
		if ownerPlayer and ownerPlayer.Parent then
			local ownerData = PlayerDataService.get(ownerPlayer)
			if ownerData then
				_ev:FireClient(ownerPlayer, {
					monsters = ownerData.monsters,
					toast    = def.icon .. " " .. def.displayName .. " теперь служит захватчику! 😈",
				})
			end
		end

		_ev:FireClient(capturer, {
			monsters = capturerData.monsters,
			jail     = capturerData.jail,
			toast    = "Подчинил " .. def.icon .. " " .. def.displayName .. "! 😈",
		})

		return { ok = true }
	else
		entry.subjugateAttempts = attempts + 1
		local remaining = Config.SUBJUGATE_ATTEMPTS_MAX - entry.subjugateAttempts

		if remaining <= 0 then
			compensate(capturerData, entry, jailIdx)
			PlayerDataService.save(capturer)
			_ev:FireClient(capturer, {
				monsters = capturerData.monsters,
				jail     = capturerData.jail,
				coins    = capturerData.coins,
				toast    = "Монстр сбежал — получил 💰" .. Config.SUBJUGATE_COMPENSATION .. " компенсации",
			})
		else
			PlayerDataService.save(capturer)
			_ev:FireClient(capturer, {
				jail  = capturerData.jail,
				toast = "Провал подчинения! Осталось попыток: " .. remaining,
			})
		end

		return { ok = false, message = "Провал! Осталось: " .. remaining }
	end
end

return SubjugationService

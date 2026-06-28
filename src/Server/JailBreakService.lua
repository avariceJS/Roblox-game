local Players           = game:GetService("Players")
local Config            = require(game.ReplicatedStorage.src.Shared.Config)
local PlayerDataService = require(game.ReplicatedStorage.src.Server.PlayerDataService)
local BaseService       = require(game.ReplicatedStorage.src.Server.BaseService)
local TrapService       = require(game.ReplicatedStorage.src.Server.TrapService)

local _ev = nil

local JailBreakService = {}

function JailBreakService.init(ev)
	_ev = ev
end

local function findCapturedMonster(playerData, capturedByUserId: number?, targetBaseId: number): any?
	for _, m in playerData.monsters do
		if m.state ~= "Captured" then continue end
		if capturedByUserId and m.capturedByUserId == capturedByUserId then return m end
		if m.capturedByBaseId == targetBaseId then return m end
	end
	for _, m in playerData.monsters do
		if m.state == "Captured" then return m end
	end
	return nil
end

local function findIdleMonster(playerData): any?
	for _, m in playerData.monsters do
		if m.state == "Idle" then return m end
	end
	return nil
end

function JailBreakService.attemptBreak(player: Player, targetBaseId: number): { ok: boolean, message: string? }
	local playerData = PlayerDataService.get(player)
	if not playerData then return {ok = false, message = "Нет данных"} end

	if playerData.baseId == targetBaseId then
		return {ok = false, message = "Нельзя ломать свою клетку"}
	end

	local occupant = BaseService.getOccupant(targetBaseId)
	local capturedByUserId: number? = occupant and occupant.UserId or nil

	local monster = findCapturedMonster(playerData, capturedByUserId, targetBaseId)
	if not monster then
		return {ok = false, message = "Нет монстра для освобождения"}
	end

	local resolvedUid: number? = capturedByUserId
		or monster.capturedByUserId
		or PlayerDataService.findCaptorUserIdForMonster(monster.id)

	local capturerData = resolvedUid and PlayerDataService.getByUserId(resolvedUid)

	if capturerData and TrapService.hasCage(capturerData) then
		local capturerPlayer = resolvedUid and Players:GetPlayerByUserId(resolvedUid)
		if capturerPlayer and capturerPlayer.Parent then
			_ev:FireClient(capturerPlayer, {
				toast = "⚠️ Влом! " .. player.Name .. " пытается освободить пленника!",
			})
		end
		return {ok = false, message = "Ловушка сработала! Хозяин предупреждён 🔒"}
	end

	if capturerData then
		local upgrades = capturerData.baseUpgrades or {}
		if upgrades.reinforcedTrap and math.random() < Config.REINFORCED_TRAP_CATCH then
			local idle = findIdleMonster(playerData)
			if idle then
				idle.state            = "Captured"
				idle.fatigueUntil     = 0
				idle.capturedByBaseId = targetBaseId
				idle.capturedByName   = occupant and occupant.Name or "?"
				idle.capturedByUserId = resolvedUid
				idle.ransomPrice      = nil
				PlayerDataService.save(player)

				if not capturerData.jail then capturerData.jail = {} end
				table.insert(capturerData.jail, {
					monsterId         = idle.id,
					monsterType       = idle.type or "Slime",
					monsterName       = idle.type or "Монстр",
					ownerName         = player.Name,
					ownerUserId       = player.UserId,
					subjugateAttempts = 0,
				})
				PlayerDataService.save(occupant)

				local capturerPlayer = resolvedUid and Players:GetPlayerByUserId(resolvedUid)
				if capturerPlayer and capturerPlayer.Parent then
					_ev:FireClient(capturerPlayer, {
						jail  = capturerData.jail,
						toast = "Усиленная ловушка поймала вломщика! 🔒",
					})
				end

				_ev:FireClient(player, {
					monsters = playerData.monsters,
					toast    = "Ловушка! Твой монстр попал в усиленную клетку! ⛓️",
				})
				return {ok = false, message = "Усиленная ловушка поймала тебя! ⛓️"}
			end
		end
	end

	monster.state            = "Idle"
	monster.fatigueUntil     = 0
	monster.capturedByBaseId = nil
	monster.capturedByName   = nil
	monster.capturedByUserId = nil
	monster.ransomPrice      = nil
	PlayerDataService.save(player)

	if resolvedUid then
		PlayerDataService.modifyByUserId(resolvedUid, function(capData)
			for i, entry in capData.jail do
				if entry.monsterId == monster.id then
					table.remove(capData.jail, i)
					break
				end
			end
		end)
		local capturerPlayer = Players:GetPlayerByUserId(resolvedUid)
		if capturerPlayer and capturerPlayer.Parent then
			local capData = PlayerDataService.get(capturerPlayer)
			if capData then
				_ev:FireClient(capturerPlayer, {
					jail  = capData.jail,
					toast = "Пленник сбежал! 🔓",
				})
			end
		end
	end

	_ev:FireClient(player, {
		monsters = playerData.monsters,
		toast    = "Монстр освобождён! 🔓",
	})

	return {ok = true}
end

return JailBreakService

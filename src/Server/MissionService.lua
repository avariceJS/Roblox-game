local TweenService = game:GetService("TweenService")
local Config  = require(game.ReplicatedStorage.src.Shared.Config)
local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local _pds = nil
local _ev  = nil
local _bs  = nil
local _missionsFolder: Folder

local slowed: { [Humanoid]: number } = {}

local MissionService = {}

local function getIdleMonster(data): any?
	for _, m in data.monsters do
		if m.state == "Idle" then
			return m
		end
	end
	return nil
end

local function setMonsterIdle(monster: any)
	monster.state = "Idle"
	monster.fatigueUntil = 0
end

local function scheduleFatigueRecovery(player: Player, monsterId: string, delaySec: number)
	task.delay(delaySec, function()
		local d = _pds.get(player)
		if not d then
			return
		end
		for _, m in d.monsters do
			if m.id == monsterId and m.state == "Fatigued" then
				setMonsterIdle(m)
				_pds.save(player)
				if player.Parent then
					_ev:FireClient(player, {
						monsters = d.monsters,
						toast = "Гуппи отдохнул — готов к делу! 🐸",
					})
				end
				break
			end
		end
	end)
end

function MissionService.syncPlayerMonsters(player: Player)
	local data = _pds.get(player)
	if not data then
		return
	end

	local now = os.time()
	local changed = false

	for _, m in data.monsters do
		if m.state == "OnMission" then
			setMonsterIdle(m)
			changed = true
		elseif m.state == "Fatigued" then
			local untilTs = m.fatigueUntil or 0
			if untilTs <= now then
				setMonsterIdle(m)
				changed = true
			else
				scheduleFatigueRecovery(player, m.id, untilTs - now)
			end
		end
	end

	if changed then
		_pds.save(player)
	end
end

local function createWalker(from: Vector3): Part
	local p = Instance.new("Part")
	p.Shape       = Enum.PartType.Ball
	p.Size        = Vector3.new(1.4, 1.4, 1.4)
	p.CFrame      = CFrame.new(from)
	p.Anchored    = true
	p.CanCollide  = false
	p.Material    = Enum.Material.Neon
	p.Color       = Color3.fromRGB(80, 220, 80)
	p.Parent      = _missionsFolder
	return p
end

local function createPuddle(pos: Vector3): (Part, RBXScriptConnection)
	local p = Instance.new("Part")
	p.Name         = "StickyPuddle"
	p.Shape        = Enum.PartType.Cylinder
	p.Size         = Vector3.new(0.35, Config.PUDDLE_RADIUS * 2, Config.PUDDLE_RADIUS * 2)
	p.CFrame       = CFrame.new(pos + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Anchored     = true
	p.CanCollide   = false
	p.Material     = Enum.Material.Neon
	p.Color        = Color3.fromRGB(80, 200, 80)
	p.Transparency = 0.4
	p.Parent       = _missionsFolder

	local conn = p.Touched:Connect(function(hit)
		local hum = hit.Parent:FindFirstChildWhichIsA("Humanoid")
		if hum and not slowed[hum] then
			slowed[hum] = hum.WalkSpeed
			hum.WalkSpeed = Config.SLOW_SPEED
			task.delay(Config.SLOW_DURATION, function()
				if hum and hum.Parent then
					hum.WalkSpeed = slowed[hum] or 16
				end
				slowed[hum] = nil
			end)
		end
	end)

	return p, conn
end

local function runMission(player: Player, monsterId: string, targetId: number)
	local data = _pds.get(player)
	if not data then return end

	local srcSpawn    = BaseUtil.getSpawn(data.baseId)
	local tgtPlatform = BaseUtil.getMissionPlatform(targetId)
	if not srcSpawn or not tgtPlatform then return end

	local srcPos = srcSpawn.Position + Vector3.new(0, srcSpawn.Size.Y * 0.5 + 3, 0)
	local tgtPos = tgtPlatform.Position + Vector3.new(0, tgtPlatform.Size.Y * 0.5 + 3, 0)

	local walker = createWalker(srcPos)
	TweenService:Create(
		walker,
		TweenInfo.new(Config.TRAVEL_TIME, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(tgtPos) }
	):Play()

	task.wait(Config.TRAVEL_TIME)
	if walker.Parent then walker:Destroy() end

	if not player.Parent then return end

	local puddlePos = tgtPlatform.Position + Vector3.new(0, tgtPlatform.Size.Y * 0.5, 0)
	local puddle, conn = createPuddle(puddlePos)
	task.delay(Config.PUDDLE_DURATION, function()
		conn:Disconnect()
		if puddle.Parent then puddle:Destroy() end
	end)

	local d = _pds.get(player)
	if not d then return end

	d.coins = d.coins + Config.DISPATCH_COINS
	d.chaos  = (d.chaos or 0) + Config.DISPATCH_CHAOS

	for _, m in d.monsters do
		if m.id == monsterId then
			m.state        = "Fatigued"
			m.fatigueUntil = os.time() + Config.FATIGUE_TIME
			break
		end
	end

	_pds.save(player)

	if player.Parent then
		_ev:FireClient(player, {
			monsters = d.monsters,
			coins    = d.coins,
			chaos    = d.chaos,
			toast    = "Гуппи пакостит! +💰" .. Config.DISPATCH_COINS .. "  +🌀" .. Config.DISPATCH_CHAOS,
		})
	end

	if targetId > 0 and _bs then
		local defender = _bs.getOccupant(targetId)
		if defender and defender.Parent and defender ~= player then
			_ev:FireClient(defender, {
				toast = "⚠️ " .. player.Name .. " натравил монстра на твою базу!",
			})
		end
	end

	scheduleFatigueRecovery(player, monsterId, Config.FATIGUE_TIME)
end

function MissionService.init(playerDataService, evMonsterUpdated, baseService)
	_pds = playerDataService
	_ev  = evMonsterUpdated
	_bs  = baseService
	local existing = workspace:FindFirstChild("Missions")
	if existing then
		existing:Destroy()
	end
	_missionsFolder = Instance.new("Folder")
	_missionsFolder.Name = "Missions"
	_missionsFolder.Parent = workspace
end

function MissionService.dispatch(player: Player, targetBaseId: number, requestedId: string?): { ok: boolean, message: string? }
	local data = _pds.get(player)
	if not data then
		return { ok = false, message = "Данные не загружены" }
	end

	local myId = BaseUtil.normalizeId(data.baseId)
	if not myId then
		return { ok = false, message = "База не назначена" }
	end

	local tgtId: number
	if targetBaseId == 0 then
		tgtId = 0
	else
		local n = BaseUtil.normalizeId(targetBaseId)
		if not n then
			return { ok = false, message = "Выбери чужую базу" }
		end
		tgtId = n
	end

	if tgtId == myId then
		return { ok = false, message = "Выбери чужую базу" }
	end
	if not BaseUtil.getMissionPlatform(tgtId) then
		return { ok = false, message = "База #" .. tgtId .. " не найдена" }
	end

	local monster: any?
	if requestedId then
		for _, m in data.monsters do
			if m.id == requestedId then
				monster = m
				break
			end
		end
		if not monster then
			return { ok = false, message = "Монстр не найден" }
		end
		if monster.state ~= "Idle" then
			local stateMsg = if monster.state == "Fatigued"
				then "Гуппи отдыхает, подожди 💤"
				else "Гуппи уже на задании 🐸"
			return { ok = false, message = stateMsg }
		end
	else
		monster = getIdleMonster(data)
		if not monster then
			local first = data.monsters[1]
			if first then
				local stateMsg = if first.state == "Fatigued"
					then "Гуппи отдыхает, подожди 💤"
					else "Гуппи уже на задании 🐸"
				return { ok = false, message = stateMsg }
			end
			return { ok = false, message = "Нет монстров" }
		end
	end

	local monsterId = monster.id
	monster.state = "OnMission"
	_pds.save(player)

	_ev:FireClient(player, { monsters = data.monsters })

	task.spawn(runMission, player, monsterId, tgtId)

	return { ok = true }
end

return MissionService

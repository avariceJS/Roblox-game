local TweenService = game:GetService("TweenService")
local Config      = require(game.ReplicatedStorage.src.Shared.Config)
local BaseUtil    = require(game.ReplicatedStorage.src.Shared.BaseUtil)
local MonsterDefs = require(game.ReplicatedStorage.src.Shared.MonsterDefs)
local TrapService = require(game.ReplicatedStorage.src.Server.TrapService)

local _pds = nil
local _ev  = nil
local _bs  = nil
local _missionsFolder: Folder

local slowed: { [Humanoid]: number } = {}

local WALKER_COLORS = {
	Slime      = Color3.fromRGB(80, 220, 80),
	Gremlin    = Color3.fromRGB(255, 130, 40),
	ShadowRat  = Color3.fromRGB(60, 60, 110),
	Homunculus = Color3.fromRGB(100, 140, 255),
}

local PUDDLE_COLORS = {
	Slime      = Color3.fromRGB(80, 200, 80),
	Gremlin    = Color3.fromRGB(220, 110, 40),
	ShadowRat  = Color3.fromRGB(60, 60, 110),
	Homunculus = Color3.fromRGB(80, 120, 220),
}

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

local function scheduleFatigueRecovery(player: Player, monsterId: string, delaySec: number, displayName: string)
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
						toast = displayName .. " отдохнул — готов к делу! 🐾",
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
				local def = MonsterDefs[m.type or "Slime"]
				local name = (def and def.displayName) or "Монстр"
				scheduleFatigueRecovery(player, m.id, untilTs - now, name)
			end
		end
	end

	if changed then
		_pds.save(player)
	end
end

local function createWalker(from: Vector3, monsterType: string): (Instance, Instance)
	local rs = game:GetService("ReplicatedStorage")
	local assetsFolder = rs:FindFirstChild("Assets")
	local template = assetsFolder
		and assetsFolder:FindFirstChild("Monsters")
		and assetsFolder.Monsters:FindFirstChild("HairboundWraith")

	if template and template:IsA("Model") then
		local clone = template:Clone()
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
		clone:PivotTo(CFrame.new(from))
		clone.Parent = _missionsFolder
		return clone, clone
	end

	local p = Instance.new("Part")
	p.Shape      = Enum.PartType.Ball
	p.Size       = Vector3.new(1.4, 1.4, 1.4)
	p.CFrame     = CFrame.new(from)
	p.Anchored   = true
	p.CanCollide = false
	p.Material   = Enum.Material.Neon
	p.Color      = WALKER_COLORS[monsterType] or Color3.fromRGB(80, 220, 80)
	p.Parent     = _missionsFolder
	return p, p
end

local function createPuddle(pos: Vector3, monsterType: string): (Part, RBXScriptConnection)
	local color = PUDDLE_COLORS[monsterType] or Color3.fromRGB(80, 200, 80)
	local p = Instance.new("Part")
	p.Name         = "StickyPuddle"
	p.Shape        = Enum.PartType.Cylinder
	p.Size         = Vector3.new(0.35, Config.PUDDLE_RADIUS * 2, Config.PUDDLE_RADIUS * 2)
	p.CFrame       = CFrame.new(pos + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Anchored     = true
	p.CanCollide   = false
	p.Material     = Enum.Material.Neon
	p.Color        = color
	p.Transparency = 0.4
	p.Parent       = _missionsFolder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color    = ColorSequence.new(color)
	emitter.Rate     = 6
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed    = NumberRange.new(1.5, 3)
	emitter.Parent   = p

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

	local monsterType        = "Slime"
	local monsterDisplayName = "Гуппи"
	for _, m in data.monsters do
		if m.id == monsterId then
			monsterType        = m.type or monsterType
			local def = MonsterDefs[monsterType]
			monsterDisplayName = def and def.displayName or monsterDisplayName
			break
		end
	end

	local srcSpawn    = BaseUtil.getSpawn(data.baseId)
	local tgtPlatform = BaseUtil.getMissionPlatform(targetId)
	if not srcSpawn or not tgtPlatform then return end

	local srcPos = srcSpawn.Position + Vector3.new(0, srcSpawn.Size.Y * 0.5 + 3, 0)
	local tgtPos = tgtPlatform.Position + Vector3.new(0, tgtPlatform.Size.Y * 0.5 + 3, 0)

	local walkerPart, walkerRoot = createWalker(srcPos, monsterType)
	if walkerRoot:IsA("Model") then
		walkerRoot:SetAttribute("TargetX", tgtPos.X)
		walkerRoot:SetAttribute("TargetY", tgtPos.Y)
		walkerRoot:SetAttribute("TargetZ", tgtPos.Z)
		walkerRoot:SetAttribute("TravelTime", Config.TRAVEL_TIME)
		task.wait(Config.TRAVEL_TIME)
	else
		TweenService:Create(
			walkerPart,
			TweenInfo.new(Config.TRAVEL_TIME, Enum.EasingStyle.Linear),
			{ CFrame = CFrame.new(tgtPos) }
		):Play()
		task.wait(Config.TRAVEL_TIME)
	end
	if walkerRoot.Parent then walkerRoot:Destroy() end

	if not player.Parent then return end

	if targetId > 0 and _bs then
		local defender = _bs.getOccupant(targetId)
		if defender and defender.Parent and defender ~= player then
			local defData = _pds.get(defender)
			if defData and TrapService.hasCage(defData) and math.random() < Config.TRAP_CATCH_CHANCE then
				local d = _pds.get(player)
				if not d then return end

				for _, m in d.monsters do
					if m.id == monsterId then
						m.state              = "Captured"
						m.fatigueUntil       = 0
						m.capturedByBaseId   = targetId
						m.capturedByName     = defender.Name
						m.capturedByUserId   = defender.UserId
						m.ransomPrice        = nil
						break
					end
				end
				_pds.save(player)

				if not defData.jail then defData.jail = {} end
				table.insert(defData.jail, {
					monsterId         = monsterId,
					monsterType       = monsterType,
					monsterName       = monsterDisplayName,
					ownerName         = player.Name,
					ownerUserId       = player.UserId,
					subjugateAttempts = 0,
				})
				_pds.save(defender)

				if player.Parent then
					_ev:FireClient(player, {
						monsters = d.monsters,
						toast    = "Твой " .. monsterDisplayName .. " пойман! ⛓️",
					})
				end
				_ev:FireClient(defender, {
					jail  = defData.jail,
					toast = "Поймал " .. monsterDisplayName .. " игрока " .. player.Name .. "! 🔒",
				})
				return
			end
		end
	end

	local puddlePos = tgtPlatform.Position + Vector3.new(0, tgtPlatform.Size.Y * 0.5, 0)
	local puddle, conn = createPuddle(puddlePos, monsterType)
	task.delay(Config.PUDDLE_DURATION, function()
		conn:Disconnect()
		if puddle.Parent then puddle:Destroy() end
	end)

	local d = _pds.get(player)
	if not d then return end

	local vipBonus    = (d.hasVip == true) and Config.VIP_BONUS or 0
	local earnedCoins = math.floor(Config.DISPATCH_COINS * (1 + vipBonus))
	d.coins = d.coins + earnedCoins
	d.chaos  = (d.chaos or 0) + Config.DISPATCH_CHAOS

	local levelUpMsg: string? = nil
	for _, m in d.monsters do
		if m.id == monsterId then
			m.state        = "Fatigued"
			m.fatigueUntil = os.time() + Config.FATIGUE_TIME
			m.xp = (m.xp or 0) + Config.DISPATCH_XP
			local xpNeeded = Config.XP_PER_LEVEL * (m.level or 1)
			if m.xp >= xpNeeded then
				m.xp    = m.xp - xpNeeded
				m.level = (m.level or 1) + 1
				levelUpMsg = "🎉 " .. monsterDisplayName .. " — уровень " .. m.level .. "!"
			end
			break
		end
	end

	_pds.save(player)

	if player.Parent then
		_ev:FireClient(player, {
			monsters = d.monsters,
			coins    = d.coins,
			chaos    = d.chaos,
			toast    = monsterDisplayName .. " пакостит! +💰" .. earnedCoins .. "  +🌀" .. Config.DISPATCH_CHAOS .. (vipBonus > 0 and " 💎" or ""),
		})
		if levelUpMsg then
			task.delay(1.5, function()
				if player.Parent then
					_ev:FireClient(player, { toast = levelUpMsg })
				end
			end)
		end
	end

	if targetId > 0 and _bs then
		local defender = _bs.getOccupant(targetId)
		if defender and defender.Parent and defender ~= player then
			_ev:FireClient(defender, {
				toast = "⚠️ " .. player.Name .. " отправил монстра на твою базу!",
			})
		end
	end

	scheduleFatigueRecovery(player, monsterId, Config.FATIGUE_TIME, monsterDisplayName)
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
			local def = MonsterDefs[monster.type or "Slime"]
			local name = (def and def.displayName) or "Монстр"
			local stateMsg = if monster.state == "Fatigued"
				then name .. " отдыхает, подожди 💤"
				else name .. " уже на задании"
			return { ok = false, message = stateMsg }
		end
	else
		monster = getIdleMonster(data)
		if not monster then
			local first = data.monsters[1]
			if first then
				local def = MonsterDefs[first.type or "Slime"]
				local name = (def and def.displayName) or "Монстр"
				local stateMsg = if first.state == "Fatigued"
					then name .. " отдыхает, подожди 💤"
					else name .. " уже на задании"
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

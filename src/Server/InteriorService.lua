local Players                = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local InteriorDefs = require(game.ReplicatedStorage.src.Shared.InteriorDefs)

local _pds = nil
local _ev  = nil

local returnCFrames: { [number]: CFrame } = {}

local InteriorService = {}

local function attrFromAncestors(instance: Instance, name: string): any
	local cur = instance
	while cur and cur ~= workspace do
		local v = cur:GetAttribute(name)
		if v ~= nil then return v end
		cur = cur.Parent
	end
	return nil
end

local function getInterior(interiorId: string): Instance?
	local map = workspace:FindFirstChild("Map")
	local folder = map and map:FindFirstChild("Interiors")
	if not folder then return nil end
	for _, child in folder:GetChildren() do
		local id = child:GetAttribute("InteriorId")
		if id and tostring(id) == interiorId then return child end
	end
	return folder:FindFirstChild("Interior_" .. interiorId)
end

local function findSpawn(interior: Instance): BasePart?
	for _, desc in interior:GetDescendants() do
		if desc.Name == "Spawn" and desc:IsA("BasePart") then return desc end
	end
	return nil
end

local function teleport(player: Player, cf: CFrame)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then hrp.CFrame = cf end
end

local function findNamedPart(root: Instance, name: string): BasePart?
	for _, desc in root:GetDescendants() do
		if desc.Name == name and desc:IsA("BasePart") then
			return desc
		end
	end
	return nil
end

local function setPartHidden(part: BasePart, hidden: boolean)
	if hidden then
		if part:GetAttribute("OrigTransparency") == nil then
			part:SetAttribute("OrigTransparency", part.Transparency)
		end
		if part:GetAttribute("OrigCanCollide") == nil then
			part:SetAttribute("OrigCanCollide", part.CanCollide)
		end
		part.Transparency = 1
		part.CanCollide = false
		part.CanQuery = false
	else
		part.Transparency = part:GetAttribute("OrigTransparency") or 0
		part.CanCollide = part:GetAttribute("OrigCanCollide") ~= false
		part.CanQuery = true
	end
end

local function setSegmentVisible(segment: Instance, visible: boolean)
	for _, desc in segment:GetDescendants() do
		if desc:IsA("BasePart") then
			setPartHidden(desc, not visible)
		end
	end
end

local function removeBlocker(interior: Instance, blockerName: string)
	local part = findNamedPart(interior, blockerName)
	if part then
		part:Destroy()
	end
end

local function getSegmentsFolder(interior: Instance): Folder?
	local f = interior:FindFirstChild("Segments")
	if f and f:IsA("Folder") then return f end
	return nil
end

local function hideAllSegments(interior: Instance)
	local segments = getSegmentsFolder(interior)
	if not segments then return end
	for _, child in segments:GetChildren() do
		setSegmentVisible(child, false)
	end
end

local function applySegment(baseId: number, key: string): (boolean, string?)
	local def = nil
	for _, d in InteriorDefs do
		if d.key == key then def = d; break end
	end
	if not def then return false, "Неизвестный сегмент" end

	local interior = getInterior("Base" .. baseId)
	if not interior then return false, "Интерьер не найден" end

	local segments = getSegmentsFolder(interior)
	if not segments then return false, "Нет папки Segments" end

	local segment = segments:FindFirstChild(def.segment)
	if not segment then return false, "Нет сегмента " .. def.segment end

	for _, blockerName in def.blockers do
		removeBlocker(interior, blockerName)
	end

	setSegmentVisible(segment, true)

	if segment:IsA("Model") and segment.PrimaryPart == nil then
		local first = segment:FindFirstChildWhichIsA("BasePart", true)
		if first then
			segment.PrimaryPart = first
		end
	end

	return true, nil
end

function InteriorService.syncForPlayer(player: Player, data: any)
	local baseId = tonumber(data.baseId)
	if not baseId then return end

	local interior = getInterior("Base" .. baseId)
	if interior then
		hideAllSegments(interior)
	end

	for _, def in InteriorDefs do
		if (data.baseUpgrades or {})[def.key] then
			local ok, err = applySegment(baseId, def.key)
			if not ok then
				warn("[InteriorService] sync", player.Name, def.key, err)
			end
		end
	end
end

function InteriorService.buyUpgrade(player: Player, data: any, key: string, evMonsterUpdated: RemoteEvent): { ok: boolean, message: string? }
	local def = nil
	for _, d in InteriorDefs do
		if d.key == key then def = d; break end
	end
	if not def then return { ok = false, message = "Сегмент не найден" } end

	if (data.baseUpgrades or {})[key] then
		return { ok = false, message = "Уже куплено" }
	end

	if def.requires and not (data.baseUpgrades or {})[def.requires] then
		local reqDef = nil
		for _, d in InteriorDefs do
			if d.key == def.requires then reqDef = d; break end
		end
		return { ok = false, message = "Сначала нужно: " .. ((reqDef and reqDef.displayName) or def.requires) }
	end

	if data.coins < def.price then
		return { ok = false, message = "Недостаточно монет (нужно " .. def.price .. ")" }
	end

	local baseId = tonumber(data.baseId)
	if not baseId then return { ok = false, message = "База не назначена" } end

	data.coins = data.coins - def.price
	data.baseUpgrades = data.baseUpgrades or {}
	data.baseUpgrades[key] = true

	local ok, err = applySegment(baseId, key)
	if not ok then
		data.baseUpgrades[key] = nil
		data.coins = data.coins + def.price
		return { ok = false, message = err or "Не удалось установить" }
	end

	local PlayerDataService = require(script.Parent.PlayerDataService)
	PlayerDataService.save(player)
	evMonsterUpdated:FireClient(player, {
		coins    = data.coins,
		upgrades = data.baseUpgrades,
		toast    = "Куплено: " .. def.displayName .. "! " .. def.emoji,
	})
	return { ok = true }
end

function InteriorService.init(playerDataService, evMonsterUpdated)
	_pds = playerDataService
	_ev  = evMonsterUpdated

	local map = workspace:FindFirstChild("Map")
	local interiors = map and map:FindFirstChild("Interiors")
	if interiors then
		for _, child in interiors:GetChildren() do
			hideAllSegments(child)
		end
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt.Name == "HomePrompt" then
			local data = _pds.get(player)
			if not data then return end

			local promptBaseId = tonumber(attrFromAncestors(prompt, "BaseId"))
			local playerBaseId = tonumber(data.baseId)

			if promptBaseId ~= playerBaseId then
				_ev:FireClient(player, { toast = "Это чужой дом 🚫" })
				return
			end

			local interiorId = tostring(
				attrFromAncestors(prompt, "InteriorId") or ("Base" .. playerBaseId)
			)
			local interior = getInterior(interiorId)
			if not interior then
				_ev:FireClient(player, { toast = "Интерьер не найден" })
				return
			end

			local spawnPart = findSpawn(interior)
			if not spawnPart then
				_ev:FireClient(player, { toast = "Нет Spawn в интерьере" })
				return
			end

			InteriorService.syncForPlayer(player, data)

			local doorPart = prompt.Parent :: BasePart
			returnCFrames[player.UserId] = doorPart.CFrame
				+ doorPart.CFrame.LookVector * 4
				+ Vector3.new(0, 3, 0)

			teleport(player, spawnPart.CFrame + Vector3.new(0, 4, 0))

		elseif prompt.Name == "ExitPrompt" then
			local cf = returnCFrames[player.UserId]
			if not cf then
				_ev:FireClient(player, { toast = "Нет точки возврата" })
				return
			end
			returnCFrames[player.UserId] = nil
			teleport(player, cf)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		returnCFrames[player.UserId] = nil
	end)
end

return InteriorService

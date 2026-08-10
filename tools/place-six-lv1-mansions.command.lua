local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerStorage = game:GetService("ServerStorage")

ChangeHistoryService:SetWaypoint("BeforeStreetMansionsOnlyLv1")

local BASE_SPACING = 55
local BASE_ROW_Z = 35
local BASE_START_X = -137.5
local HOUSE_BACK = 40
local DOOR_FRONT = 14

local map = workspace:FindFirstChild("Map")
if not map then
	map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
end

local mansions = map:FindFirstChild("Mansions")
if not mansions then
	mansions = Instance.new("Folder")
	mansions.Name = "Mansions"
	mansions.Parent = map
end

local function anchorModel(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

local function moveModelToGround(model, groundPos)
	anchorModel(model)
	local boxCf, boxSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	if pivot.UpVector.Y < 0.7 then
		local yaw = math.atan2(-pivot.LookVector.X, -pivot.LookVector.Z)
		model:PivotTo(CFrame.new(boxCf.Position) * CFrame.Angles(0, yaw, 0))
		boxCf, boxSize = model:GetBoundingBox()
		pivot = model:GetPivot()
	end
	local bottomY = boxCf.Position.Y - boxSize.Y * 0.5
	local delta = Vector3.new(groundPos.X - boxCf.Position.X, groundPos.Y - bottomY, groundPos.Z - boxCf.Position.Z)
	model:PivotTo(pivot + delta)
end

local function getHouseTemplates()
	local folder = ServerStorage:FindFirstChild("HouseTemplates")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "HouseTemplates"
		folder.Parent = ServerStorage
	end
	return folder
end

local function stashTemplate(lvName, model)
	if not model then
		return
	end
	local folder = getHouseTemplates()
	local old = folder:FindFirstChild(lvName)
	if old then
		old:Destroy()
	end
	local copy = model:Clone()
	copy.Name = lvName
	anchorModel(copy)
	copy:PivotTo(CFrame.new(0, -1000, 0))
	copy.Parent = folder
	print("[Lv1Only] шаблон сохранён ServerStorage.HouseTemplates." .. lvName)
end

local function extractHouseFromMansion(mansionModel)
	if not mansionModel then
		return nil
	end
	for _, name in ipairs({ "GothicHouse_Lv1", "GothicHouse_Lv2", "GothicHouse_Lv3", "Lv1", "Lv2", "Lv3" }) do
		local h = mansionModel:FindFirstChild(name)
		if h and h:IsA("Model") then
			return h
		end
	end
	for _, child in ipairs(mansionModel:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "Home" then
			return child
		end
	end
	if mansionModel:IsA("Model") then
		return mansionModel
	end
	return nil
end

local templatesFolder = mansions:FindFirstChild("Templates")
if templatesFolder then
	for _, name in ipairs({ "Lv1", "Lv2", "Lv3" }) do
		local t = templatesFolder:FindFirstChild(name)
		if t then
			stashTemplate(name, t)
		end
	end
	templatesFolder:Destroy()
end

local m2 = mansions:FindFirstChild("Mansion_2")
if m2 then
	local house = extractHouseFromMansion(m2)
	if house then
		stashTemplate("Lv2", house)
	end
end

local m3 = mansions:FindFirstChild("Mansion_3")
if m3 then
	local house = extractHouseFromMansion(m3)
	if house then
		stashTemplate("Lv3", house)
	end
end

local home = workspace:FindFirstChild("home")
if home and home:IsA("Model") then
	stashTemplate("Lv1", home)
	home:Destroy()
end

local build = map:FindFirstChild("Build")
local edit = build and build:FindFirstChild("MansionEdit")
if edit then
	local house = extractHouseFromMansion(edit)
	if house and not getHouseTemplates():FindFirstChild("Lv1") then
		stashTemplate("Lv1", house)
	end
end

local streetKill = {
	"Mansion_2",
	"Mansion_3",
}
for _, name in ipairs(streetKill) do
	local m = mansions:FindFirstChild(name)
	if m then
		m:Destroy()
		print("[Lv1Only] убран с улицы:", name)
	end
end

if edit then
	edit:Destroy()
	print("[Lv1Only] убран Map.Build.MansionEdit")
end

for _, inst in ipairs(workspace:GetChildren()) do
	if inst:IsA("Model") then
		local n = inst.Name
		if n == "home"
			or string.find(n, "GothicHouse", 1, true)
			or string.find(n, "Meshy_AI", 1, true) and string.find(string.lower(n), "house", 1, true)
		then
			if not getHouseTemplates():FindFirstChild("Lv1") then
				stashTemplate("Lv1", inst)
			end
			inst:Destroy()
			print("[Lv1Only] убран Workspace." .. n)
		end
	end
end

local lv1 = getHouseTemplates():FindFirstChild("Lv1")
if not lv1 then
	local m1 = mansions:FindFirstChild("Mansion_1")
	if m1 then
		local h = extractHouseFromMansion(m1)
		if h then
			stashTemplate("Lv1", h)
			lv1 = getHouseTemplates():FindFirstChild("Lv1")
		end
	end
end
assert(lv1, "Нет шаблона Lv1 в ServerStorage.HouseTemplates — нужен home / Lv1")

for id = 1, 6 do
	local old = mansions:FindFirstChild("Mansion_" .. id)
	if old then
		old:Destroy()
	end
end

local function placeHomeDoor(parentModel, baseId, doorPos)
	local homeFolder = parentModel:FindFirstChild("Home")
	if not homeFolder then
		homeFolder = Instance.new("Folder")
		homeFolder.Name = "Home"
		homeFolder.Parent = parentModel
	end

	local door = homeFolder:FindFirstChild("HomeDoor")
	if not door then
		door = Instance.new("Part")
		door.Name = "HomeDoor"
		door.Parent = homeFolder
	end

	door.Size = Vector3.new(5, 8, 1.2)
	door.Anchored = true
	door.CanCollide = true
	door.Material = Enum.Material.SmoothPlastic
	door.Color = Color3.fromRGB(90, 40, 120)
	door.Transparency = 0.15
	door.CFrame = CFrame.new(doorPos) * CFrame.Angles(0, math.rad(180), 0)
	door:SetAttribute("BaseId", baseId)
	door:SetAttribute("InteriorId", "Base1")

	parentModel:SetAttribute("BaseId", baseId)
	parentModel:SetAttribute("HouseLevel", 1)

	local prompt = door:FindFirstChild("HomePrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HomePrompt"
		prompt.Parent = door
	end
	prompt.ActionText = "Войти"
	prompt.ObjectText = "Особняк #" .. baseId
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0

	local lab = door:FindFirstChild("LabPrompt")
	if lab then
		lab:Destroy()
	end
end

local function ensureSlots(parentModel, yardPos)
	local slots = parentModel:FindFirstChild("UpgradeSlots")
	if not slots then
		slots = Instance.new("Folder")
		slots.Name = "UpgradeSlots"
		slots.Parent = parentModel
	end
	local upgrades = parentModel:FindFirstChild("Upgrades")
	if not upgrades then
		upgrades = Instance.new("Folder")
		upgrades.Name = "Upgrades"
		upgrades.Parent = parentModel
	end

	local function slot(name, offset)
		local p = slots:FindFirstChild(name)
		if not p then
			p = Instance.new("Part")
			p.Name = name
			p.Parent = slots
		end
		p.Size = Vector3.new(4, 1, 2)
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 1
		p.CFrame = CFrame.new(yardPos + offset)
	end

	slot("Slot_Wall2", Vector3.new(0, 1, -2))
	slot("Slot_Jeep", Vector3.new(4, 0, 4))
end

local basesFolder = workspace:FindFirstChild("Bases")
if not basesFolder then
	basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = workspace
end
for _, child in ipairs(basesFolder:GetChildren()) do
	child:Destroy()
end

for id = 1, 6 do
	local yardPos = Vector3.new(BASE_START_X + (id - 1) * BASE_SPACING, 0.5, BASE_ROW_Z)
	local housePos = yardPos + Vector3.new(0, 0, HOUSE_BACK)
	local doorPos = Vector3.new(yardPos.X, 4, yardPos.Z + DOOR_FRONT)

	local plot = Instance.new("Model")
	plot.Name = "Mansion_" .. id
	plot.Parent = mansions

	local house = lv1:Clone()
	house.Name = "GothicHouse_Lv1"
	house.Parent = plot
	moveModelToGround(house, housePos)

	placeHomeDoor(plot, id, doorPos)
	ensureSlots(plot, yardPos)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Base" .. id
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(yardPos + Vector3.new(0, 0, 2))
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = false
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn:SetAttribute("BaseId", id)
	spawn.Parent = basesFolder

	print(("[Lv1Only] Mansion_%d Lv1 на улице"):format(id))
end

ChangeHistoryService:SetWaypoint("AfterStreetMansionsOnlyLv1")

print("========================================")
print("[Lv1Only] ГОТОВО")
print("  На улице ТОЛЬКО Mansion_1..6 (все Lv1)")
print("  Lv2/Lv3/home/MansionEdit убраны с карты")
print("  Шаблоны: ServerStorage.HouseTemplates.Lv1/Lv2/Lv3")
print("  Позже: прокачал дом → Clone Lv2 вместо GothicHouse_Lv1")
print("========================================")

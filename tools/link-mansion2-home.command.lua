local ChangeHistoryService = game:GetService("ChangeHistoryService")

ChangeHistoryService:SetWaypoint("BeforeLinkMansion2")

local function findGothicHouse()
	local best = nil
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Model") then
			local n = inst.Name
			if string.find(n, "Meshy", 1, true)
				or string.find(n, "Gothic_Purple", 1, true)
				or string.find(n, "1715", 1, true)
				or string.find(n, "image-to-3d", 1, true)
			then
				best = inst
				break
			end
		end
	end
	return best
end

local house = findGothicHouse()
assert(house, "Не найден Meshy/Gothic дом в Workspace. Проверь имя модели.")

local map = workspace:FindFirstChild("Map")
assert(map, "Нет Workspace.Map")

local mansions = map:FindFirstChild("Mansions")
if not mansions then
	mansions = Instance.new("Folder")
	mansions.Name = "Mansions"
	mansions.Parent = map
end

local mansion2 = mansions:FindFirstChild("Mansion_2")
if not mansion2 then
	mansion2 = Instance.new("Model")
	mansion2.Name = "Mansion_2"
	mansion2.Parent = mansions
end

local home = mansion2:FindFirstChild("Home")
if not home then
	home = Instance.new("Folder")
	home.Name = "Home"
	home.Parent = mansion2
end

house.Name = "GothicHouse_Lv2"
house.Parent = mansion2

local cf, size = house:GetBoundingBox()
local groundY = cf.Position.Y - size.Y * 0.5
local look = cf.LookVector
if math.abs(look.Y) > 0.7 then
	look = Vector3.new(0, 0, 1)
else
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.05 then
		look = Vector3.new(0, 0, 1)
	else
		look = look.Unit
	end
end

local doorPos = cf.Position + look * (size.Z * 0.5 + 4)
doorPos = Vector3.new(doorPos.X, groundY + 3.5, doorPos.Z)

local door = home:FindFirstChild("HomeDoor")
if not door then
	door = Instance.new("Part")
	door.Name = "HomeDoor"
	door.Anchored = true
	door.CanCollide = false
	door.CanQuery = true
	door.Material = Enum.Material.SmoothPlastic
	door.Color = Color3.fromRGB(70, 35, 95)
	door.Size = Vector3.new(4, 7, 1)
	door.Parent = home
end

door.CFrame = CFrame.lookAt(doorPos, doorPos + look)

local baseId = 2
local bases = workspace:FindFirstChild("Bases")
if bases then
	local count = 0
	local onlyId = nil
	for _, b in ipairs(bases:GetChildren()) do
		local id = tonumber(b:GetAttribute("BaseId"))
		if not id then
			id = tonumber(string.match(b.Name, "%d+"))
		end
		if id then
			count += 1
			onlyId = id
		end
	end
	if count == 1 and onlyId then
		baseId = onlyId
	end
end

door:SetAttribute("BaseId", baseId)
door:SetAttribute("InteriorId", "Base2")
door.Transparency = 0.35

local old = door:FindFirstChild("HomePrompt")
if old then
	old:Destroy()
end
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "HomePrompt"
prompt.ActionText = "Войти"
prompt.ObjectText = "Особняк Lv2"
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 14
prompt.RequiresLineOfSight = false
prompt.Parent = door

if not mansion2:FindFirstChild("UpgradeSlots") then
	local slots = Instance.new("Folder")
	slots.Name = "UpgradeSlots"
	slots.Parent = mansion2
	local function slot(name, pos)
		local s = Instance.new("Part")
		s.Name = name
		s.Anchored = true
		s.CanCollide = false
		s.Transparency = 1
		s.Size = Vector3.new(4, 1, 2)
		s.CFrame = CFrame.new(pos)
		s.Parent = slots
	end
	slot("Slot_Wall2", doorPos + Vector3.new(-4, -2, -6))
	slot("Slot_Jeep", doorPos + Vector3.new(4, -3, 4))
end
if not mansion2:FindFirstChild("Upgrades") then
	local u = Instance.new("Folder")
	u.Name = "Upgrades"
	u.Parent = mansion2
end

ChangeHistoryService:SetWaypoint("AfterLinkMansion2")
print("[link-mansion2] OK")
print("  house →", house:GetFullName())
print("  door  →", door:GetFullName(), door.Position)
print("  BaseId=" .. tostring(baseId) .. " InteriorId=Base2 → Interior_Base2")
print("Play Solo: подойди к фиолетовому блоку у дома → [E]")

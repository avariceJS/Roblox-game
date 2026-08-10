local ChangeHistoryService = game:GetService("ChangeHistoryService")

ChangeHistoryService:SetWaypoint("BeforeLinkMansion3")

local map = workspace:FindFirstChild("Map")
assert(map, "Нет Workspace.Map")

local mansions = map:FindFirstChild("Mansions")
if not mansions then
	mansions = Instance.new("Folder")
	mansions.Name = "Mansions"
	mansions.Parent = map
end

local function findSourceHouse()
	local m2 = mansions:FindFirstChild("Mansion_2")
	if m2 then
		local named = m2:FindFirstChild("GothicHouse_Lv2")
		if named and named:IsA("Model") then
			return named
		end
		for _, child in ipairs(m2:GetChildren()) do
			if child:IsA("Model") and child.Name ~= "Home" then
				return child
			end
		end
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Model") then
			local n = inst.Name
			if string.find(n, "GothicHouse", 1, true)
				or string.find(n, "Meshy", 1, true)
				or string.find(n, "Gothic_Purple", 1, true)
			then
				return inst
			end
		end
	end
	return nil
end

local source = findSourceHouse()
assert(source, "Нет модели Lv2 (GothicHouse_Lv2 / Meshy). Сначала link-mansion2 или положи модель.")

local mansion3 = mansions:FindFirstChild("Mansion_3")
if not mansion3 then
	mansion3 = Instance.new("Model")
	mansion3.Name = "Mansion_3"
	mansion3.Parent = mansions
end

local oldHouse = mansion3:FindFirstChild("GothicHouse_Lv3")
if oldHouse then
	oldHouse:Destroy()
end

local house = source:Clone()
house.Name = "GothicHouse_Lv3"
house.Parent = mansion3

local srcCf, srcSize = source:GetBoundingBox()
local offset = Vector3.new(80, 0, 0)
house:PivotTo(srcCf + offset)

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

local home = mansion3:FindFirstChild("Home")
if not home then
	home = Instance.new("Folder")
	home.Name = "Home"
	home.Parent = mansion3
end

local door = home:FindFirstChild("HomeDoor")
if not door then
	door = Instance.new("Part")
	door.Name = "HomeDoor"
	door.Anchored = true
	door.CanCollide = false
	door.CanQuery = true
	door.Material = Enum.Material.SmoothPlastic
	door.Color = Color3.fromRGB(90, 40, 130)
	door.Size = Vector3.new(4, 7, 1)
	door.Parent = home
end

door.CFrame = CFrame.lookAt(doorPos, doorPos + look)
door.Transparency = 0.35

local baseId = 3
local bases = workspace:FindFirstChild("Bases")
if bases then
	local count = 0
	local onlyId = nil
	for _, b in ipairs(bases:GetChildren()) do
		local id = tonumber(b:GetAttribute("BaseId")) or tonumber(string.match(b.Name, "%d+"))
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
door:SetAttribute("InteriorId", "Base3")

local oldPrompt = door:FindFirstChild("HomePrompt")
if oldPrompt then
	oldPrompt:Destroy()
end
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "HomePrompt"
prompt.ActionText = "Войти"
prompt.ObjectText = "Особняк Lv3"
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 14
prompt.RequiresLineOfSight = false
prompt.Parent = door

if not mansion3:FindFirstChild("UpgradeSlots") then
	local slots = Instance.new("Folder")
	slots.Name = "UpgradeSlots"
	slots.Parent = mansion3
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
if not mansion3:FindFirstChild("Upgrades") then
	local u = Instance.new("Folder")
	u.Name = "Upgrades"
	u.Parent = mansion3
end

ChangeHistoryService:SetWaypoint("AfterLinkMansion3")
print("[link-mansion3] OK")
print("  clone →", house:GetFullName(), "offset +80 X от Lv2")
print("  door  →", door:GetFullName(), door.Position)
print("  BaseId=" .. tostring(baseId) .. " InteriorId=Base3 → Interior_Base3")
print("Модель временная (клон Lv2) — потом заменишь на свою")

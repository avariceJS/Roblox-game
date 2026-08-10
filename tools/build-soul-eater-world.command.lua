local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")

ChangeHistoryService:SetWaypoint("BeforeDeathCity")

local COL = {
	dirt = Color3.fromRGB(18, 12, 28),
	stone = Color3.fromRGB(36, 28, 48),
	cobble = Color3.fromRGB(52, 42, 64),
	road = Color3.fromRGB(28, 22, 38),
	sidewalk = Color3.fromRGB(58, 48, 72),
	curb = Color3.fromRGB(90, 70, 120),
	accent = Color3.fromRGB(255, 210, 70),
	accent2 = Color3.fromRGB(255, 145, 40),
	pole = Color3.fromRGB(16, 10, 24),
	iron = Color3.fromRGB(26, 20, 36),
	moon = Color3.fromRGB(255, 228, 140),
	moonDark = Color3.fromRGB(45, 22, 70),
	roof = Color3.fromRGB(50, 22, 70),
	wall = Color3.fromRGB(68, 52, 82),
	wall2 = Color3.fromRGB(55, 42, 70),
	fog = Color3.fromRGB(95, 55, 150),
	plaza = Color3.fromRGB(46, 34, 58),
	park = Color3.fromRGB(28, 38, 36),
	grave = Color3.fromRGB(42, 38, 48),
	shop = Color3.fromRGB(90, 45, 55),
}

local PAD = 18
local ROAD_W = 14
local SIDE_W = 3.5
local EXPAND = 400
local MIN_CITY = 1250
local MAX_PART = 2000
local WALL_H = 280
local WALL_T = 12
local CEIL_Y = 260
local BASE_SPACING = 55
local BASE_ROW_Z = 35
local BASE_START_X = -137.5
local HOUSE_BACK = 36

local BASE_COLORS = {
	Color3.fromRGB(220, 55, 55),
	Color3.fromRGB(40, 40, 50),
	Color3.fromRGB(230, 230, 235),
	Color3.fromRGB(255, 140, 40),
	Color3.fromRGB(255, 210, 50),
	Color3.fromRGB(55, 120, 255),
}

local function P(parent, name, size, cf, color, mat, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.CanTouch = false
	p.CastShadow = true
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function tiledSlab(parent, name, x0, x1, z0, z1, y, thickness, color, mat, collide)
	local w = x1 - x0
	local d = z1 - z0
	local nx = math.max(1, math.ceil(w / MAX_PART))
	local nz = math.max(1, math.ceil(d / MAX_PART))
	local tw = w / nx
	local td = d / nz
	local n = 0
	for ix = 0, nx - 1 do
		for iz = 0, nz - 1 do
			n += 1
			local cx = x0 + tw * (ix + 0.5)
			local cz = z0 + td * (iz + 0.5)
			P(
				parent,
				name .. "_" .. n,
				Vector3.new(tw, thickness, td),
				CFrame.new(cx, y, cz),
				color,
				mat,
				collide
			)
		end
	end
end

local function invisibleWall(parent, name, size, cf)
	local p = P(parent, name, size, cf, Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic, true)
	p.Transparency = 1
	p.CastShadow = false
	p.CanQuery = false
	return p
end

local function tiledWallX(parent, name, x, z0, z1, yCenter, height, thickness)
	local len = z1 - z0
	local n = math.max(1, math.ceil(len / MAX_PART))
	local seg = len / n
	for i = 0, n - 1 do
		local cz = z0 + seg * (i + 0.5)
		invisibleWall(
			parent,
			name .. "_" .. (i + 1),
			Vector3.new(thickness, height, seg),
			CFrame.new(x, yCenter, cz)
		)
	end
end

local function tiledWallZ(parent, name, z, x0, x1, yCenter, height, thickness)
	local len = x1 - x0
	local n = math.max(1, math.ceil(len / MAX_PART))
	local seg = len / n
	for i = 0, n - 1 do
		local cx = x0 + seg * (i + 0.5)
		invisibleWall(
			parent,
			name .. "_" .. (i + 1),
			Vector3.new(seg, height, thickness),
			CFrame.new(cx, yCenter, z)
		)
	end
end

local function N(parent, name, size, cf, color)
	local p = P(parent, name, size, cf, color, Enum.Material.Neon, false)
	p.CastShadow = false
	return p
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local map = workspace:FindFirstChild("Map")
if not map then
	map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
end

local old = map:FindFirstChild("Environment")
if old then
	old:Destroy()
end

local env = folder("Environment", map)
local groundF = folder("Ground", env)
local roadsF = folder("Roads", env)
local yardsF = folder("Courtyards", env)
local lampsF = folder("Lamps", env)
local propsF = folder("Props", env)
local skylineF = folder("Skyline", env)
local districtsF = folder("Districts", env)
local boundsF = folder("Bounds", env)

for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
	local bp = workspace:FindFirstChild(name)
	if bp and bp:IsA("BasePart") then
		bp.Transparency = 1
		bp.CanCollide = false
		bp.CastShadow = false
	end
end

local function xz(pos)
	return Vector3.new(pos.X, 0.5, pos.Z)
end

local function findModelByNameFragment(fragment)
	for _, inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("Model") and string.find(inst.Name, fragment, 1, true) then
			return inst
		end
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Model") and string.find(inst.Name, fragment, 1, true) then
			return inst
		end
	end
	return nil
end

local function largestPart(model)
	local best
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and (not best or d.Size.Magnitude > best.Size.Magnitude) then
			best = d
		end
	end
	return best
end

local function detectShop()
	local shop = workspace:FindFirstChild("shop") or map:FindFirstChild("shop")
	if not shop then
		return nil, nil
	end
	local promptPart = shop:FindFirstChild("Part")
	local mesh = largestPart(shop)
	local center = mesh and xz(mesh.Position) or (promptPart and xz(promptPart.Position)) or nil
	return shop, center
end

local function detectHomeModel()
	return workspace:FindFirstChild("home")
end

local function layoutBases()
	local list = {}
	for id = 1, 6 do
		table.insert(list, {
			id = id,
			position = Vector3.new(BASE_START_X + (id - 1) * BASE_SPACING, 0.5, BASE_ROW_Z),
			color = BASE_COLORS[id],
		})
	end
	return list
end

local function ensurePlayerBases(bases)
	local basesFolder = workspace:FindFirstChild("Bases")
	if not basesFolder then
		basesFolder = Instance.new("Folder")
		basesFolder.Name = "Bases"
		basesFolder.Parent = workspace
	end
	for _, child in ipairs(basesFolder:GetChildren()) do
		child:Destroy()
	end
	for _, b in ipairs(bases) do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Base" .. b.id
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.CFrame = CFrame.new(b.position + Vector3.new(0, 0, 4))
		spawn.Anchored = true
		spawn.CanCollide = true
		spawn.Neutral = false
		spawn.Duration = 0
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.Color = Color3.fromRGB(40, 35, 50)
		spawn.Transparency = 1
		spawn:SetAttribute("BaseId", b.id)
		spawn.Parent = basesFolder
	end
end

local function moveModelOnYard(model, yardPos, _faceLook)
	if not model then
		return
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end

	local boxCf, boxSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local upright = pivot.UpVector.Y >= 0.7

	if not upright then
		local yaw = math.atan2(-pivot.LookVector.X, -pivot.LookVector.Z)
		model:PivotTo(CFrame.new(boxCf.Position) * CFrame.Angles(0, yaw, 0))
		boxCf, boxSize = model:GetBoundingBox()
		pivot = model:GetPivot()
	end

	local bottomY = boxCf.Position.Y - boxSize.Y * 0.5
	local delta = Vector3.new(yardPos.X - boxCf.Position.X, yardPos.Y - bottomY, yardPos.Z - boxCf.Position.Z)
	model:PivotTo(pivot + delta)
end

local function housePosForBase(basePos)
	return basePos + Vector3.new(0, 0, HOUSE_BACK)
end

local function placeHomeDoor(parentModel, baseId, interiorId, yardPos)
	if parentModel:IsA("Model") then
		parentModel:SetAttribute("BaseId", baseId)
	end
	local home = parentModel:FindFirstChild("Home")
	if not home then
		home = Instance.new("Folder")
		home.Name = "Home"
		home.Parent = parentModel
	end
	local door = home:FindFirstChild("HomeDoor")
	if not door then
		door = Instance.new("Part")
		door.Name = "HomeDoor"
		door.Size = Vector3.new(4, 7, 1)
		door.Anchored = true
		door.CanCollide = true
		door.Material = Enum.Material.SmoothPlastic
		door.Color = Color3.fromRGB(70, 35, 95)
		door.Parent = home
	end
	door.CFrame = CFrame.new(yardPos.X, yardPos.Y + 3.5, yardPos.Z + HOUSE_BACK * 0.35)
	door:SetAttribute("BaseId", baseId)
	door:SetAttribute("InteriorId", interiorId)
	local prompt = door:FindFirstChild("HomePrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HomePrompt"
		prompt.Parent = door
	end
	prompt.ActionText = "Войти"
	prompt.ObjectText = "Особняк"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
end

local function arrangeMansions(bases)
	local mansions = map:FindFirstChild("Mansions")
	if not mansions then
		mansions = Instance.new("Folder")
		mansions.Name = "Mansions"
		mansions.Parent = map
	end

	local build = map:FindFirstChild("Build")
	local edit = build and build:FindFirstChild("MansionEdit")
	if edit then
		moveModelOnYard(edit, housePosForBase(bases[1].position))
		local plot = edit:FindFirstChild("PlotCenter", true)
		if plot and plot:IsA("BasePart") then
			plot.CFrame = CFrame.new(bases[1].position)
		end
		placeHomeDoor(edit, 1, "Base1", bases[1].position)
	end

	local m2 = mansions:FindFirstChild("Mansion_2")
	if m2 then
		local house = m2:FindFirstChild("GothicHouse_Lv2")
		if not house then
			for _, child in ipairs(m2:GetChildren()) do
				if child:IsA("Model") and child.Name ~= "Home" then
					house = child
					break
				end
			end
		end
		if house then
			moveModelOnYard(house, housePosForBase(bases[2].position))
		end
		placeHomeDoor(m2, 2, "Base2", bases[2].position)
	end

	local m3 = mansions:FindFirstChild("Mansion_3")
	if m3 then
		local house = m3:FindFirstChild("GothicHouse_Lv3")
		if not house then
			for _, child in ipairs(m3:GetChildren()) do
				if child:IsA("Model") and child.Name ~= "Home" then
					house = child
					break
				end
			end
		end
		if house then
			moveModelOnYard(house, housePosForBase(bases[3].position))
		end
		placeHomeDoor(m3, 3, "Base3", bases[3].position)
	end

	local home = detectHomeModel()
	if home then
		moveModelOnYard(home, housePosForBase(bases[4].position))
	end
end

local bases = layoutBases()
ensurePlayerBases(bases)
arrangeMansions(bases)

local shopModel = select(1, detectShop())
local rowZ = BASE_ROW_Z
local shopCenter = Vector3.new(0, 0.5, BASE_ROW_Z - 55)
local npcHome = Vector3.new(BASE_START_X + 5.5 * BASE_SPACING + 40, 0.5, BASE_ROW_Z)

if shopModel then
	for _, d in ipairs(shopModel:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	moveModelOnYard(shopModel, shopCenter)
	local promptPart = shopModel:FindFirstChild("Part")
	if promptPart and promptPart:IsA("BasePart") then
		promptPart.Size = Vector3.new(6, 1, 4)
		promptPart.CFrame = CFrame.new(shopCenter.X, shopCenter.Y + 1.2, shopCenter.Z - 18)
		promptPart.Transparency = 1
		promptPart.CanCollide = false
		promptPart.Anchored = true
		local prompt = promptPart:FindFirstChild("ShopPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 20
			prompt.ActionText = "Открыть"
			prompt.ObjectText = "Магазин"
		end
	end
	if not shopModel:FindFirstChild("ShopPrompt", true) and promptPart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ShopPrompt"
		prompt.ActionText = "Открыть"
		prompt.ObjectText = "Магазин"
		prompt.MaxActivationDistance = 20
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart
	end
end

local landmarks = { shopCenter, npcHome }
for _, b in ipairs(bases) do
	table.insert(landmarks, b.position)
end

local minX, maxX = math.huge, -math.huge
local minZ, maxZ = math.huge, -math.huge
for _, p in ipairs(landmarks) do
	minX = math.min(minX, p.X)
	maxX = math.max(maxX, p.X)
	minZ = math.min(minZ, p.Z)
	maxZ = math.max(maxZ, p.Z)
end
local coreMinX, coreMaxX = minX, maxX
local coreMinZ, coreMaxZ = minZ, maxZ
local coreMidX = (coreMinX + coreMaxX) * 0.5
local coreMidZ = (coreMinZ + coreMaxZ) * 0.5

minX -= EXPAND
maxX += EXPAND
minZ -= EXPAND
maxZ += EXPAND

local spanX = maxX - minX
local spanZ = maxZ - minZ
if spanX < MIN_CITY then
	local add = (MIN_CITY - spanX) * 0.5
	minX -= add
	maxX += add
	spanX = maxX - minX
end
if spanZ < MIN_CITY then
	local add = (MIN_CITY - spanZ) * 0.5
	minZ -= add
	maxZ += add
	spanZ = maxZ - minZ
end

local midX = (minX + maxX) * 0.5
local midZ = (minZ + maxZ) * 0.5

local plaza = Vector3.new(0, 0.5, BASE_ROW_Z - 20)
local parkCenter = Vector3.new(0, 0.5, BASE_ROW_Z + 90)
local cemetery = Vector3.new(BASE_START_X + 5 * BASE_SPACING + 80, 0.5, BASE_ROW_Z + 20)
local overlook = Vector3.new(BASE_START_X - 80, 0.5, BASE_ROW_Z + 40)
local northHub = Vector3.new(0, 0.5, maxZ - 120)
local southHub = Vector3.new(0, 0.5, minZ + 120)
local eastHub = Vector3.new(maxX - 120, 0.5, BASE_ROW_Z)
local westHub = Vector3.new(minX + 120, 0.5, BASE_ROW_Z)

for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("Atmosphere")
		or child:IsA("Sky")
		or child:IsA("BloomEffect")
		or child:IsA("ColorCorrectionEffect")
		or child:IsA("DepthOfFieldEffect")
		or child:IsA("SunRaysEffect")
		or child:IsA("BlurEffect")
	then
		child:Destroy()
	end
end

pcall(function()
	Lighting.Technology = Enum.Technology.ShadowMap
end)
Lighting.GlobalShadows = true
Lighting.Brightness = 1.05
Lighting.ClockTime = 20.9
Lighting.GeographicLatitude = 35
Lighting.Ambient = Color3.fromRGB(48, 28, 85)
Lighting.OutdoorAmbient = Color3.fromRGB(62, 38, 105)
Lighting.ColorShift_Top = Color3.fromRGB(200, 140, 255)
Lighting.ColorShift_Bottom = Color3.fromRGB(30, 15, 50)
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.25
Lighting.ShadowSoftness = 0.4
Lighting.ExposureCompensation = 0.05
Lighting.FogColor = Color3.fromRGB(38, 20, 68)
Lighting.FogStart = 80
Lighting.FogEnd = 700

local atmo = Instance.new("Atmosphere")
atmo.Density = 0.32
atmo.Offset = 0.1
atmo.Color = Color3.fromRGB(125, 70, 185)
atmo.Decay = Color3.fromRGB(40, 16, 70)
atmo.Glare = 0.08
atmo.Haze = 2.0
atmo.Parent = Lighting

local sky = Instance.new("Sky")
sky.CelestialBodiesShown = true
sky.MoonAngularSize = 24
sky.SunAngularSize = 0
sky.StarCount = 5500
sky.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.65
bloom.Size = 30
bloom.Threshold = 0.98
bloom.Parent = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness = -0.02
cc.Contrast = 0.26
cc.Saturation = 0.1
cc.TintColor = Color3.fromRGB(230, 205, 255)
cc.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity = 0.2
dof.FocusDistance = 55
dof.InFocusRadius = 70
dof.NearIntensity = 0.03
dof.Parent = Lighting

tiledSlab(groundF, "CityGround", minX - 40, maxX + 40, minZ - 40, maxZ + 40, -1.2, 2.5, COL.dirt, Enum.Material.Slate, true)
tiledSlab(groundF, "CitySoil", minX - 20, maxX + 20, minZ - 20, maxZ + 20, 0.05, 0.7, COL.stone, Enum.Material.Rock, true)

local function road(name, a, b, width)
	width = width or ROAD_W
	local mid = (a + b) * 0.5
	local d = b - a
	local len = math.max(d.Magnitude, 1)
	local yaw = math.atan2(-d.X, -d.Z)
	local cf = CFrame.new(mid.X, 0.32, mid.Z) * CFrame.Angles(0, yaw, 0)
	P(roadsF, name, Vector3.new(width, 0.6, len + 2), cf, COL.road, Enum.Material.Asphalt)
	P(
		roadsF,
		name .. "_SW",
		Vector3.new(SIDE_W, 0.45, len + 2),
		cf * CFrame.new(-(width * 0.5 + SIDE_W * 0.5), 0.05, 0),
		COL.sidewalk,
		Enum.Material.Concrete
	)
	P(
		roadsF,
		name .. "_SE",
		Vector3.new(SIDE_W, 0.45, len + 2),
		cf * CFrame.new(width * 0.5 + SIDE_W * 0.5, 0.05, 0),
		COL.sidewalk,
		Enum.Material.Concrete
	)
	if len > 24 then
		local marks = math.floor(len / 18)
		for i = 1, marks do
			local t = i / (marks + 1)
			local pos = a:Lerp(b, t)
			N(
				roadsF,
				name .. "_Mark" .. i,
				Vector3.new(0.7, 0.12, 4),
				CFrame.new(pos.X, 0.68, pos.Z) * CFrame.Angles(0, yaw, 0),
				COL.accent
			).Transparency = 0.25
		end
	end
end

local function plazaPad(name, center, size, color, mat)
	return P(
		districtsF,
		name,
		Vector3.new(size.X, 0.55, size.Z),
		CFrame.new(center.X, 0.35, center.Z),
		color or COL.plaza,
		mat or Enum.Material.Cobblestone
	)
end

local sorted = {}
for _, b in ipairs(bases) do
	table.insert(sorted, b)
end
table.sort(sorted, function(a, b)
	return a.position.X < b.position.X
end)

local westGate = Vector3.new(minX + 80, 0.5, midZ)
local eastGate = Vector3.new(maxX - 80, 0.5, midZ)
local northGate = Vector3.new(midX, 0.5, maxZ - 80)
local southGate = Vector3.new(midX, 0.5, minZ + 80)

local midWest = Vector3.new(minX + spanX * 0.25, 0.5, midZ)
local midEast = Vector3.new(minX + spanX * 0.75, 0.5, midZ)
local midNorth = Vector3.new(midX, 0.5, minZ + spanZ * 0.75)
local midSouth = Vector3.new(midX, 0.5, minZ + spanZ * 0.25)

road("Outer_N", Vector3.new(westGate.X, 0.5, northGate.Z), Vector3.new(eastGate.X, 0.5, northGate.Z), 16)
road("Outer_S", Vector3.new(westGate.X, 0.5, southGate.Z), Vector3.new(eastGate.X, 0.5, southGate.Z), 16)
road("Outer_W", Vector3.new(westGate.X, 0.5, southGate.Z), Vector3.new(westGate.X, 0.5, northGate.Z), 16)
road("Outer_E", Vector3.new(eastGate.X, 0.5, southGate.Z), Vector3.new(eastGate.X, 0.5, northGate.Z), 16)

road("Mid_N", Vector3.new(midWest.X, 0.5, midNorth.Z), Vector3.new(midEast.X, 0.5, midNorth.Z), 14)
road("Mid_S", Vector3.new(midWest.X, 0.5, midSouth.Z), Vector3.new(midEast.X, 0.5, midSouth.Z), 14)
road("Mid_W", Vector3.new(midWest.X, 0.5, midSouth.Z), Vector3.new(midWest.X, 0.5, midNorth.Z), 14)
road("Mid_E", Vector3.new(midEast.X, 0.5, midSouth.Z), Vector3.new(midEast.X, 0.5, midNorth.Z), 14)

road("Ring_N", Vector3.new(coreMinX - 80, 0.5, coreMaxZ + 60), Vector3.new(coreMaxX + 80, 0.5, coreMaxZ + 60), 12)
road("Ring_S", Vector3.new(coreMinX - 80, 0.5, coreMinZ - 60), Vector3.new(coreMaxX + 80, 0.5, coreMinZ - 60), 12)
road("Ring_W", Vector3.new(coreMinX - 80, 0.5, coreMinZ - 60), Vector3.new(coreMinX - 80, 0.5, coreMaxZ + 60), 12)
road("Ring_E", Vector3.new(coreMaxX + 80, 0.5, coreMinZ - 60), Vector3.new(coreMaxX + 80, 0.5, coreMaxZ + 60), 12)

road("Blvd_Market", shopCenter, plaza, 16)
road("Blvd_Center", plaza, Vector3.new(coreMidX, 0.5, rowZ), 16)
road("Blvd_East", Vector3.new(coreMidX, 0.5, rowZ), Vector3.new(sorted[#sorted].position.X + 30, 0.5, rowZ), 14)

for i = 1, #sorted - 1 do
	road(("Res_%d"):format(i), sorted[i].position, sorted[i + 1].position, 12)
end

local frontZ = rowZ + 36
local backZ = rowZ - 32
road(
	"FrontStreet",
	Vector3.new(sorted[1].position.X - 25, 0.5, frontZ),
	Vector3.new(sorted[#sorted].position.X + 25, 0.5, frontZ),
	12
)
road(
	"BackStreet",
	Vector3.new(sorted[1].position.X - 25, 0.5, backZ),
	Vector3.new(sorted[#sorted].position.X + 25, 0.5, backZ),
	10
)

for _, b in ipairs(sorted) do
	road(("DriveF_%d"):format(b.id), b.position, Vector3.new(b.position.X, 0.5, frontZ), 8)
	road(("DriveB_%d"):format(b.id), b.position, Vector3.new(b.position.X, 0.5, backZ), 7)
end

road("ToPark", Vector3.new(coreMidX, 0.5, rowZ), parkCenter, 14)
road("ToCemetery", Vector3.new(sorted[#sorted].position.X, 0.5, rowZ), cemetery, 12)
road("ToOverlook", shopCenter, overlook, 12)
road("ToHome", Vector3.new(coreMidX, 0.5, frontZ), npcHome, 12)
road("ToNorthHub", Vector3.new(coreMidX, 0.5, coreMaxZ + 60), northHub, 14)
road("ToSouthHub", parkCenter, southHub, 14)
road("ToEastHub", cemetery, eastHub, 14)
road("ToWestHub", overlook, westHub, 14)
road("Cross_NS", southGate, northGate, 16)
road("Cross_EW", westGate, eastGate, 16)
road("Cross_ShopNS", Vector3.new(shopCenter.X, 0.5, southGate.Z), Vector3.new(shopCenter.X, 0.5, northGate.Z), 12)

plazaPad("MarketPlaza", shopCenter, Vector3.new(40, 0, 40), COL.plaza, Enum.Material.Cobblestone)
plazaPad("TownPlaza", plaza, Vector3.new(48, 0, 48), COL.plaza, Enum.Material.Cobblestone)
plazaPad("ParkLawn", parkCenter, Vector3.new(110, 0, 90), COL.park, Enum.Material.Grass)
plazaPad("CemeteryPad", cemetery, Vector3.new(80, 0, 70), COL.grave, Enum.Material.Slate)
plazaPad("OverlookPad", overlook, Vector3.new(60, 0, 48), COL.plaza, Enum.Material.Cobblestone)
plazaPad("NorthHubPad", northHub, Vector3.new(70, 0, 70), COL.plaza, Enum.Material.Cobblestone)
plazaPad("SouthHubPad", southHub, Vector3.new(70, 0, 70), COL.park, Enum.Material.Grass)
plazaPad("EastHubPad", eastHub, Vector3.new(60, 0, 60), COL.grave, Enum.Material.Slate)
plazaPad("WestHubPad", westHub, Vector3.new(60, 0, 60), COL.plaza, Enum.Material.Cobblestone)

N(
	districtsF,
	"PlazaStar",
	Vector3.new(14, 0.2, 14),
	CFrame.new(plaza.X, 0.72, plaza.Z) * CFrame.Angles(0, math.rad(45), 0),
	COL.accent
).Transparency = 0.4

local fountain = Instance.new("Model")
fountain.Name = "Fountain"
fountain.Parent = districtsF
P(fountain, "Basin", Vector3.new(12, 1.2, 12), CFrame.new(plaza.X, 0.9, plaza.Z), COL.curb, Enum.Material.Slate)
P(fountain, "Water", Vector3.new(9, 0.6, 9), CFrame.new(plaza.X, 1.35, plaza.Z), Color3.fromRGB(70, 90, 160), Enum.Material.Glass).Transparency = 0.35
P(fountain, "Pillar", Vector3.new(2, 5, 2), CFrame.new(plaza.X, 3.5, plaza.Z), COL.stone, Enum.Material.Cobblestone)
N(fountain, "Glow", Vector3.new(1.4, 1.4, 1.4), CFrame.new(plaza.X, 6.2, plaza.Z), COL.accent)

for _, b in ipairs(bases) do
	local c = b.position
	P(yardsF, ("Yard_%d"):format(b.id), Vector3.new(PAD, 0.5, PAD), CFrame.new(c.X, 0.3, c.Z), COL.cobble, Enum.Material.Cobblestone)
	P(
		yardsF,
		("YardRim_%d"):format(b.id),
		Vector3.new(PAD + 1.5, 0.3, PAD + 1.5),
		CFrame.new(c.X, 0.18, c.Z),
		COL.curb,
		Enum.Material.SmoothPlastic,
		false
	)
end

P(yardsF, "Yard_Shop", Vector3.new(36, 0.55, 36), CFrame.new(shopCenter.X, 0.35, shopCenter.Z), COL.cobble, Enum.Material.Cobblestone)
P(yardsF, "Yard_NPC", Vector3.new(16, 0.65, 16), CFrame.new(npcHome.X, 0.4, npcHome.Z), Color3.fromRGB(72, 35, 55), Enum.Material.Cobblestone)

if shopModel then
	local signPart = shopModel:FindFirstChild("Part")
	local billboardParent = signPart
	if not billboardParent then
		billboardParent = largestPart(shopModel)
	end
	if billboardParent then
		local oldGui = billboardParent:FindFirstChild("ShopSign")
		if oldGui then
			oldGui:Destroy()
		end
		local gui = Instance.new("BillboardGui")
		gui.Name = "ShopSign"
		gui.Size = UDim2.new(0, 200, 0, 48)
		gui.StudsOffset = Vector3.new(0, 18, 0)
		gui.AlwaysOnTop = false
		gui.Parent = billboardParent
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "МАГАЗИН"
		label.TextColor3 = COL.accent
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = gui
	end
end

local function lamp(name, pos, lean)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = lampsF
	P(m, "Pole", Vector3.new(0.55, 12, 0.55), CFrame.new(pos.X, 6.1, pos.Z) * CFrame.Angles(0, 0, math.rad(lean or 0)), COL.pole, Enum.Material.Metal)
	P(m, "Arm", Vector3.new(3.0, 0.35, 0.35), CFrame.new(pos.X + 1.3, 11.3, pos.Z), COL.iron, Enum.Material.Metal)
	local bulb = N(m, "Bulb", Vector3.new(1.2, 0.75, 1.2), CFrame.new(pos.X + 2.6, 10.7, pos.Z), COL.accent)
	local light = Instance.new("PointLight")
	light.Brightness = 2.4
	light.Range = 36
	light.Color = COL.accent
	light.Shadows = true
	light.Parent = bulb
	P(m, "Cage", Vector3.new(1.6, 1.2, 1.6), CFrame.new(pos.X + 2.6, 11.1, pos.Z), COL.iron, Enum.Material.Metal, false).Transparency = 0.4
end

local function lampsAlong(name, a, b, step, side)
	local d = b - a
	local len = d.Magnitude
	if len < 1 then
		return
	end
	local dir = d.Unit
	local perp = Vector3.new(-dir.Z, 0, dir.X)
	local n = math.max(1, math.floor(len / step))
	for i = 0, n do
		local pos = a + dir * (len * (i / n)) + perp * side
		lamp(("%s_%d"):format(name, i), pos, ((i % 2 == 0) and 6 or -6))
	end
end

for _, b in ipairs(bases) do
	local c = b.position
	lamp(("L%d_a"):format(b.id), Vector3.new(c.X - 10, 0, c.Z + 10), -5)
	lamp(("L%d_b"):format(b.id), Vector3.new(c.X + 10, 0, c.Z + 10), 6)
	lamp(("L%d_c"):format(b.id), Vector3.new(c.X - 10, 0, c.Z - 10), 4)
	lamp(("L%d_d"):format(b.id), Vector3.new(c.X + 10, 0, c.Z - 10), -7)
end

lampsAlong("Market", shopCenter, plaza, 36, 10)
lampsAlong("Center", plaza, Vector3.new(coreMidX, 0.5, rowZ), 36, 10)
lampsAlong("Front", Vector3.new(sorted[1].position.X, 0.5, frontZ), Vector3.new(sorted[#sorted].position.X, 0.5, frontZ), 32, 8)
lampsAlong("OuterN", Vector3.new(westGate.X, 0.5, northGate.Z), Vector3.new(eastGate.X, 0.5, northGate.Z), 80, 10)
lampsAlong("OuterS", Vector3.new(westGate.X, 0.5, southGate.Z), Vector3.new(eastGate.X, 0.5, southGate.Z), 80, -10)
lampsAlong("Park", Vector3.new(coreMidX, 0.5, rowZ), parkCenter, 40, 8)
lamp("L_Shop_a", shopCenter + Vector3.new(-16, 0, 16), -6)
lamp("L_Shop_b", shopCenter + Vector3.new(16, 0, 16), 6)
lamp("L_Home_a", npcHome + Vector3.new(-10, 0, 10), -5)
lamp("L_Home_b", npcHome + Vector3.new(10, 0, 10), 5)

local function fenceRun(name, from, to, spacing)
	local d = to - from
	local len = d.Magnitude
	if len < 1 then
		return
	end
	local dir = d.Unit
	local n = math.max(2, math.floor(len / spacing))
	for i = 0, n do
		local pos = from + dir * (len * (i / n))
		local lean = ((i % 3) - 1) * 7
		P(
			propsF,
			name .. "_" .. i,
			Vector3.new(0.35, 3.4, 0.35),
			CFrame.new(pos.X, 1.8, pos.Z) * CFrame.Angles(0, 0, math.rad(lean)),
			COL.iron,
			Enum.Material.Metal
		)
		if i < n then
			local mid = from + dir * (len * ((i + 0.5) / n))
			P(
				propsF,
				name .. "Rail_" .. i,
				Vector3.new(spacing * 0.85, 0.2, 0.2),
				CFrame.new(mid.X, 2.5, mid.Z) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0),
				COL.iron,
				Enum.Material.Metal,
				false
			)
		end
	end
end

for _, b in ipairs(bases) do
	local c = b.position
	local half = PAD * 0.5 + 1.2
	fenceRun(("F%d_n"):format(b.id), Vector3.new(c.X - half, 0, c.Z - half), Vector3.new(c.X + half, 0, c.Z - half), 2.6)
	fenceRun(("F%d_s"):format(b.id), Vector3.new(c.X - half, 0, c.Z + half), Vector3.new(c.X + half, 0, c.Z + half), 2.6)
end

fenceRun("ParkFence_N", parkCenter + Vector3.new(-32, 0, -24), parkCenter + Vector3.new(32, 0, -24), 3)
fenceRun("ParkFence_S", parkCenter + Vector3.new(-32, 0, 24), parkCenter + Vector3.new(32, 0, 24), 3)
fenceRun("CemFence", cemetery + Vector3.new(-20, 0, -16), cemetery + Vector3.new(20, 0, -16), 2.8)

local function crate(name, pos, scale)
	local s = scale or 1
	P(
		propsF,
		name,
		Vector3.new(2.2 * s, 1.6 * s, 2.2 * s),
		CFrame.new(pos) * CFrame.Angles(0, math.rad(pos.X * 13 % 40), 0),
		Color3.fromRGB(60, 40, 30),
		Enum.Material.Wood
	)
end

local function tomb(name, pos)
	P(
		propsF,
		name,
		Vector3.new(1.4, 2.6, 0.4),
		CFrame.new(pos.X, 1.4, pos.Z) * CFrame.Angles(0, 0, math.rad((pos.X % 9) - 4)),
		COL.stone,
		Enum.Material.Slate
	)
	P(propsF, name .. "Base", Vector3.new(1.9, 0.4, 0.9), CFrame.new(pos.X, 0.35, pos.Z), COL.cobble, Enum.Material.Cobblestone)
end

local function bench(name, pos, yaw)
	P(propsF, name, Vector3.new(4.5, 0.4, 1.2), CFrame.new(pos.X, 1.1, pos.Z) * CFrame.Angles(0, yaw, 0), Color3.fromRGB(70, 45, 30), Enum.Material.Wood)
	P(propsF, name .. "Back", Vector3.new(4.5, 1.4, 0.3), CFrame.new(pos.X, 1.9, pos.Z) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, -0.5), Color3.fromRGB(70, 45, 30), Enum.Material.Wood)
end

for i, b in ipairs(bases) do
	crate(("Crate_%d_a"):format(b.id), Vector3.new(b.position.X + 12, 0.9, b.position.Z - 7), 1)
	crate(("Crate_%d_b"):format(b.id), Vector3.new(b.position.X + 13.5, 0.7, b.position.Z - 5), 0.75)
	if i % 2 == 1 then
		tomb(("TombNear_%d"):format(b.id), Vector3.new(b.position.X - 14, 0, b.position.Z - 13))
	end
end

for i = -2, 2 do
	for j = -1, 1 do
		tomb(("Cem_%d_%d"):format(i, j), cemetery + Vector3.new(i * 6, 0, j * 7))
	end
end

for i = -2, 2 do
	bench(("ParkBench_%d"):format(i), parkCenter + Vector3.new(i * 10, 0, 8), 0)
	bench(("PlazaBench_%d"):format(i), plaza + Vector3.new(i * 8, 0, 16), 0)
end

crate("ShopCrate_a", shopCenter + Vector3.new(18, 0.9, 8), 1.1)
crate("ShopCrate_b", shopCenter + Vector3.new(20, 0.7, 5), 0.8)
crate("ShopCrate_c", shopCenter + Vector3.new(-18, 0.9, 6), 1)

for i = 1, 24 do
	local t = (i - 1) / 23
	local x = minX + 80 + (maxX - minX - 160) * t
	local mist = P(
		propsF,
		"Mist_" .. i,
		Vector3.new(40, 8, 22),
		CFrame.new(x, 3.5, midZ + ((i % 2 == 0) and spanZ * 0.08 or -spanZ * 0.08)),
		COL.fog,
		Enum.Material.ForceField,
		false
	)
	mist.Transparency = 0.82
	mist.CastShadow = false
end

local function siloBuilding(name, pos, w, d, h, lean)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = skylineF
	local wallCol = (h % 2 == 0) and COL.wall or COL.wall2
	P(m, "Body", Vector3.new(w, h, d), CFrame.new(pos.X, h * 0.5, pos.Z) * CFrame.Angles(0, math.rad(lean), math.rad(lean * 0.25)), wallCol, Enum.Material.Brick)
	P(m, "Roof", Vector3.new(w + 2, 1.4, d + 2), CFrame.new(pos.X, h + 0.5, pos.Z) * CFrame.Angles(0, math.rad(lean), math.rad(7)), COL.roof, Enum.Material.Slate)
	N(m, "Win1", Vector3.new(1.3, 1.7, 0.2), CFrame.new(pos.X - w * 0.22, h * 0.4, pos.Z + d * 0.5 + 0.1), COL.accent).Transparency = 0.1
	N(m, "Win2", Vector3.new(1.3, 1.7, 0.2), CFrame.new(pos.X + w * 0.18, h * 0.62, pos.Z + d * 0.5 + 0.1), COL.accent2).Transparency = 0.15
	if h > 18 then
		N(m, "Win3", Vector3.new(1.1, 1.4, 0.2), CFrame.new(pos.X, h * 0.8, pos.Z + d * 0.5 + 0.1), COL.accent).Transparency = 0.2
	end
end

for i = 1, 16 do
	local x = minX + 40 + (i - 1) * ((spanX - 80) / 15)
	siloBuilding(("SkyN_%d"):format(i), Vector3.new(x, 0, maxZ - 35), 10 + (i % 4) * 2, 9, 18 + (i % 5) * 5, (i % 2 == 0) and 7 or -8)
end
for i = 1, 14 do
	local x = minX + 50 + (i - 1) * ((spanX - 100) / 13)
	siloBuilding(("SkyS_%d"):format(i), Vector3.new(x, 0, minZ + 35), 9 + (i % 3) * 3, 8, 16 + (i % 4) * 5, (i % 2 == 0) and -7 or 6)
end
for i = 1, 10 do
	local z = minZ + 50 + (i - 1) * ((spanZ - 100) / 9)
	siloBuilding(("SkyW_%d"):format(i), Vector3.new(minX + 35, 0, z), 9, 10 + (i % 3), 17 + (i % 4) * 4, (i % 2 == 0) and 9 or -6)
	siloBuilding(("SkyE_%d"):format(i), Vector3.new(maxX - 35, 0, z), 10, 9 + (i % 2), 19 + (i % 3) * 5, (i % 2 == 0) and -8 or 5)
end

local tribalMoon = findModelByNameFragment("tribal_moon")
	or findModelByNameFragment("4308_image-to-3d")
	or findModelByNameFragment("Meshy_AI_tribal")

if tribalMoon then
	for _, name in ipairs({ "DeathMoon", "MoonEyeL", "MoonEyeR", "MoonGrin" }) do
		local oldMoon = propsF:FindFirstChild(name)
		if oldMoon then
			oldMoon:Destroy()
		end
	end

	tribalMoon.Name = "TribalMoon"
	tribalMoon.Parent = propsF

	for _, d in ipairs(tribalMoon:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CastShadow = false
		end
	end

	local moonPos = Vector3.new(midX, 180, minZ + 80)
	local boxCf, boxSize = tribalMoon:GetBoundingBox()
	local pivot = tribalMoon:GetPivot()
	local delta = moonPos - boxCf.Position
	tribalMoon:PivotTo(pivot + delta)

	local glowParent = largestPart(tribalMoon) or tribalMoon:FindFirstChildWhichIsA("BasePart", true)
	if glowParent then
		local oldLight = glowParent:FindFirstChild("MoonGlow")
		if oldLight then
			oldLight:Destroy()
		end
		local ml = Instance.new("PointLight")
		ml.Name = "MoonGlow"
		ml.Brightness = 1.6
		ml.Range = 420
		ml.Color = Color3.fromRGB(255, 220, 160)
		ml.Parent = glowParent
	end
	print("[DeathCity] луна: TribalMoon (Meshy)")
else
	local moon = Instance.new("Part")
	moon.Name = "DeathMoon"
	moon.Shape = Enum.PartType.Ball
	moon.Size = Vector3.new(60, 60, 60)
	moon.CFrame = CFrame.new(midX, 180, minZ + 80)
	moon.Anchored = true
	moon.CanCollide = false
	moon.CastShadow = false
	moon.Material = Enum.Material.Neon
	moon.Color = COL.moon
	moon.Parent = propsF
	local ml = Instance.new("PointLight")
	ml.Brightness = 1.5
	ml.Range = 400
	ml.Color = Color3.fromRGB(255, 220, 160)
	ml.Parent = moon
	warn("[DeathCity] Meshy tribal moon не найдена — fallback шар")
end

local gateArch = function(name, pos, yaw)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = propsF
	local cf = CFrame.new(pos.X, 0, pos.Z) * CFrame.Angles(0, yaw, 0)
	P(m, "L", Vector3.new(2, 14, 2), cf * CFrame.new(-8, 7, 0), COL.iron, Enum.Material.Metal)
	P(m, "R", Vector3.new(2, 14, 2), cf * CFrame.new(8, 7, 0), COL.iron, Enum.Material.Metal)
	P(m, "Top", Vector3.new(18, 2, 2), cf * CFrame.new(0, 15, 0), COL.roof, Enum.Material.Slate)
	N(m, "Sign", Vector3.new(10, 1.5, 0.4), cf * CFrame.new(0, 12.5, 0), COL.accent).Transparency = 0.2
end

gateArch("Gate_West", westGate, math.rad(90))
gateArch("Gate_East", eastGate, math.rad(90))
gateArch("Gate_North", northGate, 0)
gateArch("Gate_South", southGate, 0)

local wallY = WALL_H * 0.5
tiledWallZ(boundsF, "Wall_N", maxZ, minX - WALL_T, maxX + WALL_T, wallY, WALL_H, WALL_T)
tiledWallZ(boundsF, "Wall_S", minZ, minX - WALL_T, maxX + WALL_T, wallY, WALL_H, WALL_T)
tiledWallX(boundsF, "Wall_W", minX, minZ - WALL_T, maxZ + WALL_T, wallY, WALL_H, WALL_T)
tiledWallX(boundsF, "Wall_E", maxX, minZ - WALL_T, maxZ + WALL_T, wallY, WALL_H, WALL_T)
tiledSlab(boundsF, "Ceiling", minX, maxX, minZ, maxZ, CEIL_Y, 8, Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic, true)
for _, child in ipairs(boundsF:GetChildren()) do
	if string.find(child.Name, "Ceiling", 1, true) then
		child.Transparency = 1
		child.CastShadow = false
		child.CanQuery = false
	end
end

local count = #env:GetDescendants()

ChangeHistoryService:SetWaypoint("AfterDeathCity")

print("========================================")
print("[DeathCity] КАРТА ×0.25 + базы в ряд")
print("  Папка: Workspace.Map.Environment")
print("  Объектов:", count)
print(("  Размер: %.0f x %.0f studs"):format(spanX, spanZ))
print("  Bases: Workspace.Bases.Base1..6 (ряд Z=35, шаг 55)")
print("  Bounds: невидимые стены + потолок")
print("  Дворы:")
for _, b in ipairs(bases) do
	print(("    Base%d @ (%.1f, %.1f)"):format(b.id, b.position.X, b.position.Z))
end
print(("  Shop @ (%.1f, %.1f)%s"):format(shopCenter.X, shopCenter.Z, shopModel and " (перемещён)" or ""))
print(("  NPC pad @ (%.1f, %.1f)"):format(npcHome.X, npcHome.Z))
print("  Интерьеры НЕ тронуты.")
print("========================================")

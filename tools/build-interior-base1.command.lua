local ChangeHistoryService = game:GetService("ChangeHistoryService")

local WALL_TEX = "rbxassetid://139986462838305"
local FLOOR_TEX = "rbxassetid://110666654316364"

local ORIGIN = Vector3.new(50, 520, 0)
local W = 28
local D = 18
local H = 11
local T = 1.05
local DOOR_W = 5
local DOOR_H = 8
local HATCH = 4.5
local STAIR_HOLE = 5

ChangeHistoryService:SetWaypoint("BeforeInteriorBase1")

local map = workspace:FindFirstChild("Map")
assert(map, "Нет Workspace.Map")
local interiors = map:FindFirstChild("Interiors") or Instance.new("Folder")
interiors.Name = "Interiors"
interiors.Parent = map

local interior = interiors:FindFirstChild("Interior_Base1") or Instance.new("Model")
interior.Name = "Interior_Base1"
interior.Parent = interiors
interior:SetAttribute("InteriorId", "Base1")
for _, child in ipairs(interior:GetChildren()) do
	child:Destroy()
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function model(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local shell = folder("Shell", interior)
local blockers = folder("Blockers", interior)
local segments = folder("Segments", interior)

local function p(parent, name, size, cf, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color or Color3.fromRGB(232, 226, 214)
	part.Size = size
	part.CFrame = cf
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function face(part, normal, tex)
	local d = Instance.new("Decal")
	d.Name = "Decal"
	d.Face = normal
	d.Texture = tex
	d.Parent = part
	return d
end

local function floorAt(parent, name, cx, cz, sx, sz, y, color)
	local part = p(parent, name, Vector3.new(sx, 0.5, sz), CFrame.new(ORIGIN + Vector3.new(cx, y, cz)), color or Color3.fromRGB(110, 85, 60))
	face(part, Enum.NormalId.Top, FLOOR_TEX)
	return part
end

local function wallAt(parent, name, cx, cy, cz, lookX, lookZ, width, height, color)
	local center = ORIGIN + Vector3.new(cx, cy, cz)
	local look = Vector3.new(lookX, 0, lookZ).Unit
	local part = p(parent, name, Vector3.new(width, height, T), CFrame.lookAt(center, center + look), color)
	face(part, Enum.NormalId.Front, WALL_TEX)
	return part
end

local function wood(parent, name, size, cf)
	return p(parent, name, size, cf, Color3.fromRGB(42, 28, 22))
end

local function glow(parent, name, cf, size)
	local part = p(parent, name, size, cf, Color3.fromRGB(255, 210, 120))
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	local light = Instance.new("PointLight")
	light.Brightness = 1.8
	light.Range = 12
	light.Color = Color3.fromRGB(255, 190, 110)
	light.Parent = part
	return part
end

local function promptOn(host, promptName, actionText, objectText)
	local old = host:FindFirstChild(promptName)
	if old then old:Destroy() end
	local pr = Instance.new("ProximityPrompt")
	pr.Name = promptName
	pr.ActionText = actionText
	pr.ObjectText = objectText
	pr.HoldDuration = 0
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.Parent = host
	return pr
end

local y0 = 0
local yMid = H * 0.5
local yCeil = H
local y2 = H + 0.5
local y2Mid = y2 + H * 0.5
local y2Ceil = y2 + H
local yLab = -(H + 2)
local yLabMid = yLab + H * 0.5

local hatchX, hatchZ = -7, 3
local stairX, stairZ = 7, 4
local doorX, doorZ = W * 0.5, -2

local halfW = W * 0.5
local halfD = D * 0.5

local function floorWithHole(parent, prefix, y, holeX, holeZ, holeS, color)
	local hx1 = holeX - holeS * 0.5
	local hx2 = holeX + holeS * 0.5
	local hz1 = holeZ - holeS * 0.5
	local hz2 = holeZ + holeS * 0.5
	local leftW = (hx1 - (-halfW))
	local rightW = (halfW - hx2)
	local midW = holeS
	local topD = (hz1 - (-halfD))
	local botD = (halfD - hz2)

	if leftW > 0.05 then
		floorAt(parent, prefix .. "_L", -halfW + leftW * 0.5, 0, leftW, D, y, color)
	end
	if rightW > 0.05 then
		floorAt(parent, prefix .. "_R", halfW - rightW * 0.5, 0, rightW, D, y, color)
	end
	if topD > 0.05 then
		floorAt(parent, prefix .. "_N", holeX, -halfD + topD * 0.5, midW, topD, y, color)
	end
	if botD > 0.05 then
		floorAt(parent, prefix .. "_S", holeX, halfD - botD * 0.5, midW, botD, y, color)
	end
end

floorWithHole(shell, "Floor", y0, hatchX, hatchZ, HATCH, Color3.fromRGB(110, 85, 60))
floorWithHole(shell, "Ceil", yCeil, stairX, stairZ, STAIR_HOLE, Color3.fromRGB(200, 195, 185))

wallAt(shell, "Wall_N", 0, yMid, -halfD, 0, 1, W + T, H)
wallAt(shell, "Wall_S", 0, yMid, halfD, 0, -1, W + T, H)
wallAt(shell, "Wall_W", -halfW, yMid, 0, 1, 0, D + T, H)

local doorGapLeft = doorZ - DOOR_W * 0.5
local doorGapRight = doorZ + DOOR_W * 0.5
local eastNorthLen = doorGapLeft - (-halfD)
local eastSouthLen = halfD - doorGapRight
local eastDoorCenterZ = doorZ

if eastNorthLen > 0.05 then
	wallAt(shell, "Wall_E_N", halfW, yMid, -halfD + eastNorthLen * 0.5, -1, 0, eastNorthLen, H)
end
if eastSouthLen > 0.05 then
	wallAt(shell, "Wall_E_S", halfW, yMid, halfD - eastSouthLen * 0.5, -1, 0, eastSouthLen, H)
end
wallAt(shell, "Wall_E_OverDoor", halfW, DOOR_H + (H - DOOR_H) * 0.5, eastDoorCenterZ, -1, 0, DOOR_W, H - DOOR_H)

wood(shell, "Beam_N", Vector3.new(W, 0.55, 0.55), CFrame.new(ORIGIN + Vector3.new(0, yCeil - 0.35, -halfD + 0.4)))
wood(shell, "Beam_S", Vector3.new(W, 0.55, 0.55), CFrame.new(ORIGIN + Vector3.new(0, yCeil - 0.35, halfD - 0.4)))
wood(shell, "Post_NE", Vector3.new(0.65, H, 0.65), CFrame.new(ORIGIN + Vector3.new(halfW - 0.2, yMid, -halfD + 0.2)))
wood(shell, "Post_NW", Vector3.new(0.65, H, 0.65), CFrame.new(ORIGIN + Vector3.new(-halfW + 0.2, yMid, -halfD + 0.2)))

glow(shell, "Win_N1", CFrame.new(ORIGIN + Vector3.new(-6, 5, -halfD + 0.05)), Vector3.new(3, 3.8, 0.15))
glow(shell, "Win_N2", CFrame.new(ORIGIN + Vector3.new(5, 5, -halfD + 0.05)), Vector3.new(3, 3.8, 0.15))

local exitDoor = p(shell, "ExitDoor", Vector3.new(3.8, 7.5, 0.55), CFrame.new(ORIGIN + Vector3.new(-4, 3.75, halfD - 0.2)) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(70, 35, 95))
promptOn(exitDoor, "ExitPrompt", "Выйти", "Наружу")

local book = p(shell, "BookPedestal", Vector3.new(2.2, 3, 2.2), CFrame.new(ORIGIN + Vector3.new(8, 1.5, -4)), Color3.fromRGB(55, 38, 28))
p(shell, "Book", Vector3.new(1.5, 0.3, 1), CFrame.new(ORIGIN + Vector3.new(8, 3.2, -4)), Color3.fromRGB(120, 40, 160))
promptOn(book, "BookPrompt", "Открыть", "Книга улучшений")

local spawn = p(interior, "Spawn", Vector3.new(3, 1, 3), CFrame.new(ORIGIN + Vector3.new(0, 1, 1)), Color3.fromRGB(80, 180, 120))
spawn.Transparency = 1
spawn.CanCollide = false

local wallCut = wallAt(blockers, "WallCut_room1_extra", halfW, DOOR_H * 0.5, eastDoorCenterZ, -1, 0, DOOR_W, DOOR_H)
wallCut.Name = "WallCut_room1_extra"
local ceilPlug = floorAt(blockers, "CeilingPlug_Stairs", stairX, stairZ, STAIR_HOLE, STAIR_HOLE, yCeil, Color3.fromRGB(200, 195, 185))
ceilPlug.Name = "CeilingPlug_Stairs"
local floorCut = floorAt(blockers, "FloorCut_basement_lab", hatchX, hatchZ, HATCH, HATCH, y0, Color3.fromRGB(95, 75, 55))
floorCut.Name = "FloorCut_basement_lab"
local hatchRim = wood(floorCut, "HatchRim", Vector3.new(HATCH + 0.5, 0.3, HATCH + 0.5), CFrame.new(ORIGIN + Vector3.new(hatchX, 0.35, hatchZ)))
hatchRim.Name = "HatchRim"

local room1W, room1D = 12, 14
local room1 = model("room1_extra", segments)
local r1c = Vector3.new(halfW + room1W * 0.5, 0, eastDoorCenterZ)
floorAt(room1, "Floor", r1c.X, r1c.Z, room1W, room1D, y0)
floorAt(room1, "Ceil", r1c.X, r1c.Z, room1W, room1D, yCeil, Color3.fromRGB(200, 195, 185))
wallAt(room1, "Wall_E", r1c.X + room1W * 0.5, yMid, r1c.Z, -1, 0, room1D + T, H)
wallAt(room1, "Wall_N", r1c.X, yMid, r1c.Z - room1D * 0.5, 0, 1, room1W + T, H)
wallAt(room1, "Wall_S", r1c.X, yMid, r1c.Z + room1D * 0.5, 0, -1, room1W + T, H)
wallAt(room1, "Wall_W_N", halfW, yMid, r1c.Z - (DOOR_W * 0.5 + (room1D - DOOR_W) * 0.25), 1, 0, (room1D - DOOR_W) * 0.5, H)
wallAt(room1, "Wall_W_S", halfW, yMid, r1c.Z + (DOOR_W * 0.5 + (room1D - DOOR_W) * 0.25), 1, 0, (room1D - DOOR_W) * 0.5, H)
wallAt(room1, "Wall_W_Over", halfW, DOOR_H + (H - DOOR_H) * 0.5, r1c.Z, 1, 0, DOOR_W, H - DOOR_H)
wood(room1, "DoorFrame_L", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(halfW, DOOR_H * 0.5, r1c.Z - DOOR_W * 0.5)))
wood(room1, "DoorFrame_R", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(halfW, DOOR_H * 0.5, r1c.Z + DOOR_W * 0.5)))
wood(room1, "DoorFrame_T", Vector3.new(0.4, 0.4, DOOR_W), CFrame.new(ORIGIN + Vector3.new(halfW, DOOR_H, r1c.Z)))
p(room1, "Desk", Vector3.new(4.5, 2, 2.2), CFrame.new(ORIGIN + Vector3.new(r1c.X + 2, 1, r1c.Z - 3)), Color3.fromRGB(60, 40, 30))
glow(room1, "Win", CFrame.new(ORIGIN + Vector3.new(r1c.X + room1W * 0.5 - 0.05, 5, r1c.Z)), Vector3.new(0.15, 3.5, 3))

local stairs = model("stairs", segments)
for i = 1, 14 do
	local t = (i - 1) / 13
	local y = t * H + 0.25
	local z = stairZ + 2.2 - t * 5
	local step = p(stairs, "Step_" .. i, Vector3.new(4.2, 0.45, 1.05), CFrame.new(ORIGIN + Vector3.new(stairX, y, z)), Color3.fromRGB(55, 38, 28))
	face(step, Enum.NormalId.Top, FLOOR_TEX)
end
wood(stairs, "Rail_L", Vector3.new(0.3, H, 0.3), CFrame.new(ORIGIN + Vector3.new(stairX - 2.3, yMid, stairZ)))
wood(stairs, "Rail_R", Vector3.new(0.3, H, 0.3), CFrame.new(ORIGIN + Vector3.new(stairX + 2.3, yMid, stairZ)))

local floor2 = model("floor2", segments)
floorWithHole(floor2, "Floor2", y2, stairX, stairZ, STAIR_HOLE, Color3.fromRGB(110, 85, 60))
floorAt(floor2, "Ceil2", 0, 0, W, D, y2Ceil, Color3.fromRGB(190, 185, 175))
wallAt(floor2, "Wall_N", 0, y2Mid, -halfD, 0, 1, W + T, H)
wallAt(floor2, "Wall_S", 0, y2Mid, halfD, 0, -1, W + T, H)
wallAt(floor2, "Wall_W", -halfW, y2Mid, 0, 1, 0, D + T, H)

local f2DoorZ = -2
local f2GapL = f2DoorZ - DOOR_W * 0.5
local f2GapR = f2DoorZ + DOOR_W * 0.5
local f2N = f2GapL - (-halfD)
local f2S = halfD - f2GapR
if f2N > 0.05 then
	wallAt(floor2, "Wall_E_N", halfW, y2Mid, -halfD + f2N * 0.5, -1, 0, f2N, H)
end
if f2S > 0.05 then
	wallAt(floor2, "Wall_E_S", halfW, y2Mid, halfD - f2S * 0.5, -1, 0, f2S, H)
end
wallAt(floor2, "Wall_E_Over", halfW, y2 + DOOR_H + (H - DOOR_H) * 0.5, f2DoorZ, -1, 0, DOOR_W, H - DOOR_H)
local cut2 = wallAt(floor2, "WallCut_floor2_room1", halfW, y2 + DOOR_H * 0.5, f2DoorZ, -1, 0, DOOR_W, DOOR_H)
cut2.Name = "WallCut_floor2_room1"
glow(floor2, "Win", CFrame.new(ORIGIN + Vector3.new(0, y2 + 5, -halfD + 0.05)), Vector3.new(3.5, 3.2, 0.15))

local room2W, room2D = 14, 14
local room2 = model("floor2_room1", segments)
local r2c = Vector3.new(halfW + room2W * 0.5, 0, f2DoorZ)
floorAt(room2, "Floor", r2c.X, r2c.Z, room2W, room2D, y2)
floorAt(room2, "Ceil", r2c.X, r2c.Z, room2W, room2D, y2Ceil, Color3.fromRGB(190, 185, 175))
wallAt(room2, "Wall_E", r2c.X + room2W * 0.5, y2Mid, r2c.Z, -1, 0, room2D + T, H)
wallAt(room2, "Wall_N", r2c.X, y2Mid, r2c.Z - room2D * 0.5, 0, 1, room2W + T, H)
wallAt(room2, "Wall_S", r2c.X, y2Mid, r2c.Z + room2D * 0.5, 0, -1, room2W + T, H)
wallAt(room2, "Wall_W_N", halfW, y2Mid, r2c.Z - (DOOR_W * 0.5 + (room2D - DOOR_W) * 0.25), 1, 0, (room2D - DOOR_W) * 0.5, H)
wallAt(room2, "Wall_W_S", halfW, y2Mid, r2c.Z + (DOOR_W * 0.5 + (room2D - DOOR_W) * 0.25), 1, 0, (room2D - DOOR_W) * 0.5, H)
wallAt(room2, "Wall_W_Over", halfW, y2 + DOOR_H + (H - DOOR_H) * 0.5, r2c.Z, 1, 0, DOOR_W, H - DOOR_H)
wood(room2, "DoorFrame_L", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(halfW, y2 + DOOR_H * 0.5, r2c.Z - DOOR_W * 0.5)))
wood(room2, "DoorFrame_R", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(halfW, y2 + DOOR_H * 0.5, r2c.Z + DOOR_W * 0.5)))
wood(room2, "DoorFrame_T", Vector3.new(0.4, 0.4, DOOR_W), CFrame.new(ORIGIN + Vector3.new(halfW, y2 + DOOR_H, r2c.Z)))
p(room2, "Bed", Vector3.new(5.5, 1.4, 3.8), CFrame.new(ORIGIN + Vector3.new(r2c.X + 2, y2 + 0.7, r2c.Z - 2)), Color3.fromRGB(90, 50, 120))
glow(room2, "Win", CFrame.new(ORIGIN + Vector3.new(r2c.X + room2W * 0.5 - 0.05, y2 + 5, r2c.Z)), Vector3.new(0.15, 3.5, 3.5))

local lab = model("basement_lab", segments)
floorWithHole(lab, "LabCeil", yLab + H, hatchX, hatchZ, HATCH, Color3.fromRGB(75, 75, 80))
floorAt(lab, "LabFloor", 0, 0, W, D, yLab, Color3.fromRGB(65, 65, 70))
wallAt(lab, "Wall_N", 0, yLabMid, -halfD, 0, 1, W + T, H, Color3.fromRGB(90, 90, 95))
wallAt(lab, "Wall_S", 0, yLabMid, halfD, 0, -1, W + T, H, Color3.fromRGB(90, 90, 95))
wallAt(lab, "Wall_E", halfW, yLabMid, 0, -1, 0, D + T, H, Color3.fromRGB(90, 90, 95))
wallAt(lab, "Wall_W", -halfW, yLabMid, 0, 1, 0, D + T, H, Color3.fromRGB(90, 90, 95))
for i, x in ipairs({ -8, 0, 8 }) do
	p(lab, "Pad_" .. i, Vector3.new(2.8, 0.5, 2.8), CFrame.new(ORIGIN + Vector3.new(x, yLab + 0.5, -4)), Color3.fromRGB(40, 40, 48))
	local tube = p(lab, "Capsule_" .. i, Vector3.new(2, 5.5, 2), CFrame.new(ORIGIN + Vector3.new(x, yLab + 3.5, -4)), Color3.fromRGB(120, 220, 255))
	tube.Material = Enum.Material.Glass
	tube.Transparency = 0.35
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 9
	light.Color = Color3.fromRGB(120, 220, 255)
	light.Parent = tube
end
p(lab, "Bench", Vector3.new(9, 2.2, 2.8), CFrame.new(ORIGIN + Vector3.new(0, yLab + 1.1, 5)), Color3.fromRGB(45, 45, 52))
wood(lab, "Ladder", Vector3.new(0.35, H + 1.5, 0.35), CFrame.new(ORIGIN + Vector3.new(hatchX, yLab + H * 0.5, hatchZ)))

local build = map:FindFirstChild("Build")
local mansion = build and build:FindFirstChild("MansionEdit")
local home = mansion and mansion:FindFirstChild("Home")
if home then
	local door = home:FindFirstChild("HomeDoor")
	if not door then
		local center = home:FindFirstChild("PlotCenter")
		local pos = center and center.Position or Vector3.new(31, 3, -18)
		door = p(home, "HomeDoor", Vector3.new(4, 7, 1), CFrame.new(pos + Vector3.new(0, 3.5, 4)), Color3.fromRGB(70, 35, 95))
	end
	door:SetAttribute("BaseId", 1)
	door:SetAttribute("InteriorId", "Base1")
	promptOn(door, "HomePrompt", "Войти", "Дом")
end

ChangeHistoryService:SetWaypoint("AfterInteriorBase1")
print("[build-interior-base1] sealed OK", ORIGIN)
print("Buy room1 → hides WallCut (дверь). Buy stairs → hides CeilingPlug. Buy lab → hides FloorCut.")
print("Sell в книге возвращает blockers. Rojo sync для кода продажи.")

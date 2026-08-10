local ChangeHistoryService = game:GetService("ChangeHistoryService")

local WALL_TEX = "rbxassetid://139986462838305"
local FLOOR_TEX = "rbxassetid://110666654316364"

local ORIGIN = Vector3.new(50, 520, 100)
local W = 40
local D = 26
local H = 12
local T = 1.05
local DOOR_W = 5.5
local DOOR_H = 8.5
local HATCH = 5
local STAIR_HOLE = 5.5

ChangeHistoryService:SetWaypoint("BeforeInteriorBase2")

local map = workspace:FindFirstChild("Map")
assert(map, "Нет Workspace.Map")
local interiors = map:FindFirstChild("Interiors") or Instance.new("Folder")
interiors.Name = "Interiors"
interiors.Parent = map

local interior = interiors:FindFirstChild("Interior_Base2") or Instance.new("Model")
interior.Name = "Interior_Base2"
interior.Parent = interiors
interior:SetAttribute("InteriorId", "Base2")
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
	light.Range = 14
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

local hatchX, hatchZ = -10, 5
local stairX, stairZ = 8, 6
local eastDoorZ = -3
local westDoorZ = 4
local f2EastDoorZ = -3
local f2WestDoorZ = 4

local halfW = W * 0.5
local halfD = D * 0.5

local function wallWithDoor(parent, prefix, wallX, lookX, doorZ, midY, overY)
	local gapL = doorZ - DOOR_W * 0.5
	local gapR = doorZ + DOOR_W * 0.5
	local northLen = gapL - (-halfD)
	local southLen = halfD - gapR
	if northLen > 0.05 then
		wallAt(parent, prefix .. "_N", wallX, midY, -halfD + northLen * 0.5, lookX, 0, northLen, H)
	end
	if southLen > 0.05 then
		wallAt(parent, prefix .. "_S", wallX, midY, halfD - southLen * 0.5, lookX, 0, southLen, H)
	end
	wallAt(parent, prefix .. "_Over", wallX, overY, doorZ, lookX, 0, DOOR_W, H - DOOR_H)
end

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
wallWithDoor(shell, "Wall_E", halfW, -1, eastDoorZ, yMid, DOOR_H + (H - DOOR_H) * 0.5)
wallWithDoor(shell, "Wall_W", -halfW, 1, westDoorZ, yMid, DOOR_H + (H - DOOR_H) * 0.5)

wood(shell, "Beam_N", Vector3.new(W, 0.55, 0.55), CFrame.new(ORIGIN + Vector3.new(0, yCeil - 0.35, -halfD + 0.4)))
wood(shell, "Beam_S", Vector3.new(W, 0.55, 0.55), CFrame.new(ORIGIN + Vector3.new(0, yCeil - 0.35, halfD - 0.4)))
wood(shell, "Beam_Mid", Vector3.new(0.55, 0.55, D), CFrame.new(ORIGIN + Vector3.new(0, yCeil - 0.35, 0)))
wood(shell, "Post_NE", Vector3.new(0.7, H, 0.7), CFrame.new(ORIGIN + Vector3.new(halfW - 0.25, yMid, -halfD + 0.25)))
wood(shell, "Post_NW", Vector3.new(0.7, H, 0.7), CFrame.new(ORIGIN + Vector3.new(-halfW + 0.25, yMid, -halfD + 0.25)))
wood(shell, "Post_SE", Vector3.new(0.7, H, 0.7), CFrame.new(ORIGIN + Vector3.new(halfW - 0.25, yMid, halfD - 0.25)))
wood(shell, "Post_SW", Vector3.new(0.7, H, 0.7), CFrame.new(ORIGIN + Vector3.new(-halfW + 0.25, yMid, halfD - 0.25)))

glow(shell, "Win_N1", CFrame.new(ORIGIN + Vector3.new(-10, 5.5, -halfD + 0.05)), Vector3.new(3.5, 4, 0.15))
glow(shell, "Win_N2", CFrame.new(ORIGIN + Vector3.new(0, 5.5, -halfD + 0.05)), Vector3.new(3.5, 4, 0.15))
glow(shell, "Win_N3", CFrame.new(ORIGIN + Vector3.new(10, 5.5, -halfD + 0.05)), Vector3.new(3.5, 4, 0.15))

local exitDoor = p(shell, "ExitDoor", Vector3.new(4, 8, 0.55), CFrame.new(ORIGIN + Vector3.new(-6, 4, halfD - 0.2)) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(70, 35, 95))
promptOn(exitDoor, "ExitPrompt", "Выйти", "Наружу")

local book = p(shell, "BookPedestal", Vector3.new(2.4, 3.2, 2.4), CFrame.new(ORIGIN + Vector3.new(12, 1.6, -6)), Color3.fromRGB(55, 38, 28))
p(shell, "Book", Vector3.new(1.6, 0.35, 1.1), CFrame.new(ORIGIN + Vector3.new(12, 3.4, -6)), Color3.fromRGB(120, 40, 160))
promptOn(book, "BookPrompt", "Открыть", "Книга улучшений")

local tableMain = p(shell, "Table", Vector3.new(8, 1.6, 3.5), CFrame.new(ORIGIN + Vector3.new(-2, 0.8, -2)), Color3.fromRGB(60, 40, 30))
p(shell, "Chair_1", Vector3.new(1.4, 2.2, 1.4), CFrame.new(ORIGIN + Vector3.new(-5, 1.1, -2)), Color3.fromRGB(50, 35, 28))
p(shell, "Chair_2", Vector3.new(1.4, 2.2, 1.4), CFrame.new(ORIGIN + Vector3.new(1, 1.1, -2)), Color3.fromRGB(50, 35, 28))

local spawn = p(interior, "Spawn", Vector3.new(3, 1, 3), CFrame.new(ORIGIN + Vector3.new(0, 1, 2)), Color3.fromRGB(80, 180, 120))
spawn.Transparency = 1
spawn.CanCollide = false

local wallCutE = wallAt(blockers, "WallCut_room1_extra", halfW, DOOR_H * 0.5, eastDoorZ, -1, 0, DOOR_W, DOOR_H)
wallCutE.Name = "WallCut_room1_extra"
local wallCutW = wallAt(blockers, "WallCut_room2_extra", -halfW, DOOR_H * 0.5, westDoorZ, 1, 0, DOOR_W, DOOR_H)
wallCutW.Name = "WallCut_room2_extra"
local ceilPlug = floorAt(blockers, "CeilingPlug_Stairs", stairX, stairZ, STAIR_HOLE, STAIR_HOLE, yCeil, Color3.fromRGB(200, 195, 185))
ceilPlug.Name = "CeilingPlug_Stairs"
local floorCut = floorAt(blockers, "FloorCut_basement_lab", hatchX, hatchZ, HATCH, HATCH, y0, Color3.fromRGB(95, 75, 55))
floorCut.Name = "FloorCut_basement_lab"
local hatchRim = wood(floorCut, "HatchRim", Vector3.new(HATCH + 0.5, 0.3, HATCH + 0.5), CFrame.new(ORIGIN + Vector3.new(hatchX, 0.35, hatchZ)))
hatchRim.Name = "HatchRim"

local function sideRoom(segName, wallX, lookInto, doorZ, roomW, roomD, propsFn)
	local room = model(segName, segments)
	local centerX = wallX + lookInto * roomW * 0.5
	local r1c = Vector3.new(centerX, 0, doorZ)
	floorAt(room, "Floor", r1c.X, r1c.Z, roomW, roomD, y0)
	floorAt(room, "Ceil", r1c.X, r1c.Z, roomW, roomD, yCeil, Color3.fromRGB(200, 195, 185))
	wallAt(room, "Wall_Outer", r1c.X + lookInto * roomW * 0.5, yMid, r1c.Z, -lookInto, 0, roomD + T, H)
	wallAt(room, "Wall_N", r1c.X, yMid, r1c.Z - roomD * 0.5, 0, 1, roomW + T, H)
	wallAt(room, "Wall_S", r1c.X, yMid, r1c.Z + roomD * 0.5, 0, -1, roomW + T, H)
	local sideLen = (roomD - DOOR_W) * 0.5
	wallAt(room, "Wall_Inner_N", wallX, yMid, r1c.Z - (DOOR_W * 0.5 + sideLen * 0.5), lookInto, 0, sideLen, H)
	wallAt(room, "Wall_Inner_S", wallX, yMid, r1c.Z + (DOOR_W * 0.5 + sideLen * 0.5), lookInto, 0, sideLen, H)
	wallAt(room, "Wall_Inner_Over", wallX, DOOR_H + (H - DOOR_H) * 0.5, r1c.Z, lookInto, 0, DOOR_W, H - DOOR_H)
	wood(room, "DoorFrame_L", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(wallX, DOOR_H * 0.5, r1c.Z - DOOR_W * 0.5)))
	wood(room, "DoorFrame_R", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(wallX, DOOR_H * 0.5, r1c.Z + DOOR_W * 0.5)))
	wood(room, "DoorFrame_T", Vector3.new(0.4, 0.4, DOOR_W), CFrame.new(ORIGIN + Vector3.new(wallX, DOOR_H, r1c.Z)))
	if propsFn then
		propsFn(room, r1c, lookInto)
	end
	return room
end

sideRoom("room1_extra", halfW, 1, eastDoorZ, 14, 16, function(room, c, look)
	p(room, "Desk", Vector3.new(5, 2.2, 2.4), CFrame.new(ORIGIN + Vector3.new(c.X + look * 2, 1.1, c.Z - 4)), Color3.fromRGB(60, 40, 30))
	p(room, "Shelf", Vector3.new(6, 5, 1.2), CFrame.new(ORIGIN + Vector3.new(c.X + look * 5, 3.5, c.Z + 2)), Color3.fromRGB(50, 35, 28))
	glow(room, "Win", CFrame.new(ORIGIN + Vector3.new(c.X + look * 7 - 0.05 * look, 5.5, c.Z)), Vector3.new(0.15, 4, 3.5))
end)

sideRoom("room2_extra", -halfW, -1, westDoorZ, 14, 16, function(room, c, look)
	p(room, "Sofa", Vector3.new(7, 2, 3), CFrame.new(ORIGIN + Vector3.new(c.X + look * 2, 1, c.Z)), Color3.fromRGB(90, 50, 110))
	p(room, "Rug", Vector3.new(8, 0.15, 8), CFrame.new(ORIGIN + Vector3.new(c.X, 0.35, c.Z)), Color3.fromRGB(100, 40, 70))
	glow(room, "Win", CFrame.new(ORIGIN + Vector3.new(c.X + look * 7 - 0.05 * look, 5.5, c.Z)), Vector3.new(0.15, 4, 3.5))
end)

local stairs = model("stairs", segments)
for i = 1, 16 do
	local t = (i - 1) / 15
	local y = t * H + 0.25
	local z = stairZ + 2.5 - t * 6
	local step = p(stairs, "Step_" .. i, Vector3.new(4.8, 0.45, 1.1), CFrame.new(ORIGIN + Vector3.new(stairX, y, z)), Color3.fromRGB(55, 38, 28))
	face(step, Enum.NormalId.Top, FLOOR_TEX)
end
wood(stairs, "Rail_L", Vector3.new(0.35, H, 0.35), CFrame.new(ORIGIN + Vector3.new(stairX - 2.6, yMid, stairZ)))
wood(stairs, "Rail_R", Vector3.new(0.35, H, 0.35), CFrame.new(ORIGIN + Vector3.new(stairX + 2.6, yMid, stairZ)))

local floor2 = model("floor2", segments)
floorWithHole(floor2, "Floor2", y2, stairX, stairZ, STAIR_HOLE, Color3.fromRGB(110, 85, 60))
floorAt(floor2, "Ceil2", 0, 0, W, D, y2Ceil, Color3.fromRGB(190, 185, 175))
wallAt(floor2, "Wall_N", 0, y2Mid, -halfD, 0, 1, W + T, H)
wallAt(floor2, "Wall_S", 0, y2Mid, halfD, 0, -1, W + T, H)
wallWithDoor(floor2, "Wall_E", halfW, -1, f2EastDoorZ, y2Mid, y2 + DOOR_H + (H - DOOR_H) * 0.5)
wallWithDoor(floor2, "Wall_W", -halfW, 1, f2WestDoorZ, y2Mid, y2 + DOOR_H + (H - DOOR_H) * 0.5)
local cut2e = wallAt(floor2, "WallCut_floor2_room1", halfW, y2 + DOOR_H * 0.5, f2EastDoorZ, -1, 0, DOOR_W, DOOR_H)
cut2e.Name = "WallCut_floor2_room1"
local cut2w = wallAt(floor2, "WallCut_floor2_room2", -halfW, y2 + DOOR_H * 0.5, f2WestDoorZ, 1, 0, DOOR_W, DOOR_H)
cut2w.Name = "WallCut_floor2_room2"
glow(floor2, "Win_N1", CFrame.new(ORIGIN + Vector3.new(-8, y2 + 5.5, -halfD + 0.05)), Vector3.new(3.5, 3.5, 0.15))
glow(floor2, "Win_N2", CFrame.new(ORIGIN + Vector3.new(8, y2 + 5.5, -halfD + 0.05)), Vector3.new(3.5, 3.5, 0.15))
p(floor2, "Rail_Hole", Vector3.new(STAIR_HOLE + 1, 1.2, 0.3), CFrame.new(ORIGIN + Vector3.new(stairX, y2 + 0.8, stairZ - STAIR_HOLE * 0.5)), Color3.fromRGB(42, 28, 22))

local function upperRoom(segName, wallX, lookInto, doorZ, roomW, roomD, propsFn)
	local room = model(segName, segments)
	local centerX = wallX + lookInto * roomW * 0.5
	local rc = Vector3.new(centerX, 0, doorZ)
	floorAt(room, "Floor", rc.X, rc.Z, roomW, roomD, y2)
	floorAt(room, "Ceil", rc.X, rc.Z, roomW, roomD, y2Ceil, Color3.fromRGB(190, 185, 175))
	wallAt(room, "Wall_Outer", rc.X + lookInto * roomW * 0.5, y2Mid, rc.Z, -lookInto, 0, roomD + T, H)
	wallAt(room, "Wall_N", rc.X, y2Mid, rc.Z - roomD * 0.5, 0, 1, roomW + T, H)
	wallAt(room, "Wall_S", rc.X, y2Mid, rc.Z + roomD * 0.5, 0, -1, roomW + T, H)
	local sideLen = (roomD - DOOR_W) * 0.5
	wallAt(room, "Wall_Inner_N", wallX, y2Mid, rc.Z - (DOOR_W * 0.5 + sideLen * 0.5), lookInto, 0, sideLen, H)
	wallAt(room, "Wall_Inner_S", wallX, y2Mid, rc.Z + (DOOR_W * 0.5 + sideLen * 0.5), lookInto, 0, sideLen, H)
	wallAt(room, "Wall_Inner_Over", wallX, y2 + DOOR_H + (H - DOOR_H) * 0.5, rc.Z, lookInto, 0, DOOR_W, H - DOOR_H)
	wood(room, "DoorFrame_L", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(wallX, y2 + DOOR_H * 0.5, rc.Z - DOOR_W * 0.5)))
	wood(room, "DoorFrame_R", Vector3.new(0.4, DOOR_H, 0.4), CFrame.new(ORIGIN + Vector3.new(wallX, y2 + DOOR_H * 0.5, rc.Z + DOOR_W * 0.5)))
	wood(room, "DoorFrame_T", Vector3.new(0.4, 0.4, DOOR_W), CFrame.new(ORIGIN + Vector3.new(wallX, y2 + DOOR_H, rc.Z)))
	if propsFn then
		propsFn(room, rc, lookInto)
	end
end

upperRoom("floor2_room1", halfW, 1, f2EastDoorZ, 15, 15, function(room, c, look)
	p(room, "Bed", Vector3.new(6, 1.5, 4), CFrame.new(ORIGIN + Vector3.new(c.X + look * 2, y2 + 0.75, c.Z - 2)), Color3.fromRGB(90, 50, 120))
	p(room, "Wardrobe", Vector3.new(3, 5, 1.5), CFrame.new(ORIGIN + Vector3.new(c.X + look * 5, y2 + 2.5, c.Z + 4)), Color3.fromRGB(55, 38, 28))
	glow(room, "Win", CFrame.new(ORIGIN + Vector3.new(c.X + look * 7.4, y2 + 5.5, c.Z)), Vector3.new(0.15, 4, 4))
end)

upperRoom("floor2_room2", -halfW, -1, f2WestDoorZ, 15, 15, function(room, c, look)
	p(room, "Bookcase_1", Vector3.new(6, 6, 1.2), CFrame.new(ORIGIN + Vector3.new(c.X + look * 5, y2 + 3, c.Z - 3)), Color3.fromRGB(45, 30, 22))
	p(room, "Bookcase_2", Vector3.new(6, 6, 1.2), CFrame.new(ORIGIN + Vector3.new(c.X + look * 5, y2 + 3, c.Z + 3)), Color3.fromRGB(45, 30, 22))
	p(room, "ReadingDesk", Vector3.new(4, 2, 2.5), CFrame.new(ORIGIN + Vector3.new(c.X + look * 1, y2 + 1, c.Z)), Color3.fromRGB(60, 40, 30))
	glow(room, "Win", CFrame.new(ORIGIN + Vector3.new(c.X + look * 7.4, y2 + 5.5, c.Z)), Vector3.new(0.15, 4, 4))
end)

local lab = model("basement_lab", segments)
floorWithHole(lab, "LabCeil", yLab + H, hatchX, hatchZ, HATCH, Color3.fromRGB(75, 75, 80))
floorAt(lab, "LabFloor", 0, 0, W, D, yLab, Color3.fromRGB(65, 65, 70))
wallAt(lab, "Wall_N", 0, yLabMid, -halfD, 0, 1, W + T, H, Color3.fromRGB(90, 90, 95))
wallAt(lab, "Wall_S", 0, yLabMid, halfD, 0, -1, W + T, H, Color3.fromRGB(90, 90, 95))
wallAt(lab, "Wall_E", halfW, yLabMid, 0, -1, 0, D + T, H, Color3.fromRGB(90, 90, 95))
wallAt(lab, "Wall_W", -halfW, yLabMid, 0, 1, 0, D + T, H, Color3.fromRGB(90, 90, 95))
for i, x in ipairs({ -12, -4, 4, 12 }) do
	p(lab, "Pad_" .. i, Vector3.new(3, 0.5, 3), CFrame.new(ORIGIN + Vector3.new(x, yLab + 0.5, -6)), Color3.fromRGB(40, 40, 48))
	local tube = p(lab, "Capsule_" .. i, Vector3.new(2.2, 6, 2.2), CFrame.new(ORIGIN + Vector3.new(x, yLab + 3.8, -6)), Color3.fromRGB(120, 220, 255))
	tube.Material = Enum.Material.Glass
	tube.Transparency = 0.35
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 10
	light.Color = Color3.fromRGB(120, 220, 255)
	light.Parent = tube
end
p(lab, "Bench", Vector3.new(14, 2.4, 3.2), CFrame.new(ORIGIN + Vector3.new(0, yLab + 1.2, 7)), Color3.fromRGB(45, 45, 52))
p(lab, "Generator", Vector3.new(5, 4.5, 3.5), CFrame.new(ORIGIN + Vector3.new(14, yLab + 2.25, 7)), Color3.fromRGB(35, 35, 40))
wood(lab, "Ladder", Vector3.new(0.4, H + 1.5, 0.4), CFrame.new(ORIGIN + Vector3.new(hatchX, yLab + H * 0.5, hatchZ)))

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
local home2 = mansion2:FindFirstChild("Home")
if not home2 then
	home2 = Instance.new("Folder")
	home2.Name = "Home"
	home2.Parent = mansion2
end
local door2 = home2:FindFirstChild("HomeDoor")
if not door2 then
	door2 = p(home2, "HomeDoor", Vector3.new(4, 7, 1), CFrame.new(50, 3.5, 40), Color3.fromRGB(70, 35, 95))
end
door2:SetAttribute("BaseId", 2)
door2:SetAttribute("InteriorId", "Base2")
promptOn(door2, "HomePrompt", "Войти", "Особняк")

local slots = mansion2:FindFirstChild("UpgradeSlots")
if not slots then
	slots = Instance.new("Folder")
	slots.Name = "UpgradeSlots"
	slots.Parent = mansion2
end
if not slots:FindFirstChild("Slot_Wall2") then
	local s = p(slots, "Slot_Wall2", Vector3.new(4, 1, 2), CFrame.new(50, 1.5, 36), Color3.fromRGB(80, 80, 80))
	s.Transparency = 1
	s.CanCollide = false
end
if not slots:FindFirstChild("Slot_Jeep") then
	local s = p(slots, "Slot_Jeep", Vector3.new(4, 1, 2), CFrame.new(54, 0.5, 44), Color3.fromRGB(80, 80, 80))
	s.Transparency = 1
	s.CanCollide = false
end
if not mansion2:FindFirstChild("Upgrades") then
	local u = Instance.new("Folder")
	u.Name = "Upgrades"
	u.Parent = mansion2
end

ChangeHistoryService:SetWaypoint("AfterInteriorBase2")
print("[build-interior-base2] OK", ORIGIN, "size", W, "x", D)
print("Segments: room1_extra room2_extra stairs floor2 floor2_room1 floor2_room2 basement_lab")
print("HomeDoor: Map.Mansions.Mansion_2.Home BaseId=2")
print("Тест: база #2 → книга покажет 7 пунктов (у Base1 по-прежнему 5)")

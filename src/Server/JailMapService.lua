local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)
local Config   = require(game.ReplicatedStorage.src.Shared.Config)

local JailMapService = {}

local function buildJailObject(floorPos: Vector3, baseId: number): Model
	local model = Instance.new("Model")
	model.Name = "Jail_Base" .. baseId
	model:SetAttribute("BaseId", baseId)

	local cage = Instance.new("Part")
	cage.Name = "Cage"
	cage.Size = Vector3.new(3, 3, 3)
	cage.CFrame = CFrame.new(floorPos + Vector3.new(0, 1.5, 0))
	cage.Anchored = true
	cage.Material = Enum.Material.Metal
	cage.Color = Color3.fromRGB(80, 80, 90)
	cage.Transparency = 0.4
	cage.CastShadow = false
	cage:SetAttribute("BaseId", baseId)
	cage.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "JailPrompt"
	prompt.ActionText = "Освободить"
	prompt.ObjectText = "Клетка"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.LAB_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = cage

	return model
end

local function findBasementLab(interior: Instance): Instance?
	local segments = interior:FindFirstChild("Segments")
	if not segments then
		return nil
	end
	return segments:FindFirstChild("basement_lab")
end

local function buildInteriorJail(interior: Instance, baseId: number): (Model?, BasePart?)
	local basement = findBasementLab(interior)
	if not basement then
		return nil, nil
	end

	local old = basement:FindFirstChild("JailCage")
	if old then
		old:Destroy()
	end

	local floor = basement:FindFirstChild("LabFloor", true)
	local bench = basement:FindFirstChild("Bench", true)
	local origin: Vector3? = nil
	if floor and floor:IsA("BasePart") then
		origin = floor.Position
	elseif bench and bench:IsA("BasePart") then
		origin = bench.Position
	else
		local any = basement:FindFirstChildWhichIsA("BasePart", true)
		if any then
			origin = any.Position
		end
	end
	if not origin then
		return nil, nil
	end

	local cage = Instance.new("Part")
	cage.Name = "JailCage"
	cage.Size = Vector3.new(3.2, 3.5, 3.2)
	cage.CFrame = CFrame.new(origin + Vector3.new(8, 2.2, 4))
	cage.Anchored = true
	cage.CanCollide = false
	cage.CastShadow = false
	cage.Material = Enum.Material.Metal
	cage.Color = Color3.fromRGB(90, 70, 50)
	cage.Transparency = 0.35
	cage:SetAttribute("BaseId", baseId)
	cage.Parent = basement

	local bars = Instance.new("Part")
	bars.Name = "JailBars"
	bars.Size = Vector3.new(2.8, 3.2, 0.3)
	bars.CFrame = cage.CFrame * CFrame.new(0, 0, 1.6)
	bars.Anchored = true
	bars.CanCollide = false
	bars.Material = Enum.Material.Metal
	bars.Color = Color3.fromRGB(40, 40, 45)
	bars.Parent = cage

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "JailPrompt"
	prompt.ActionText = "Освободить"
	prompt.ObjectText = "Клетка"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.LAB_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = cage

	local model = Instance.new("Model")
	model.Name = "Jail_Base" .. baseId
	model:SetAttribute("BaseId", baseId)

	local bind = Instance.new("ObjectValue")
	bind.Name = "JailCage"
	bind.Value = cage
	bind.Parent = model

	return model, cage
end

function JailMapService.init()
	local existing = workspace:FindFirstChild("Jails")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Jails"
	folder.Parent = workspace

	if Config.STUDIO_MAP_MODE then
		local map = workspace:FindFirstChild("Map")
		local interiors = map and map:FindFirstChild("Interiors")
		if not interiors then
			warn("[JailMapService] Нет Map.Interiors")
			return
		end

		for _, interior in ipairs(interiors:GetChildren()) do
			local interiorId = tostring(interior:GetAttribute("InteriorId") or interior.Name)
			local baseId = BaseUtil.normalizeId(string.match(interiorId, "(%d+)$"))
				or BaseUtil.normalizeId(string.match(interior.Name, "(%d+)$"))
			if baseId then
				local jail = buildInteriorJail(interior, baseId)
				if jail then
					jail.Parent = folder
				else
					warn("[JailMapService] Нет basement_lab в", interior.Name)
				end
			end
		end
		return
	end

	for baseId = 1, Config.BASE_COUNT do
		local pos = BaseUtil.getJailFloorPos(baseId)
		if not pos then
			warn("[JailMapService] Missing base", baseId)
			continue
		end
		buildJailObject(pos, baseId).Parent = folder
	end
end

return JailMapService

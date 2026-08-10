local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)
local Config   = require(game.ReplicatedStorage.src.Shared.Config)

local LabService = {}

local function buildCapsule(floorPos: Vector3, baseId: number): Model
	local model = Instance.new("Model")
	model.Name = "Lab_Base" .. baseId
	model:SetAttribute("BaseId", baseId)

	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Size = Vector3.new(3, 0.5, 3)
	pedestal.CFrame = CFrame.new(floorPos + Vector3.new(0, 0.25, 0))
	pedestal.Anchored = true
	pedestal.Material = Enum.Material.SmoothPlastic
	pedestal.Color = Color3.fromRGB(60, 60, 80)
	pedestal.Parent = model

	local glass = Instance.new("Part")
	glass.Name = "Glass"
	glass.Shape = Enum.PartType.Cylinder
	glass.Size = Vector3.new(3, 2, 2)
	glass.CFrame = CFrame.new(floorPos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	glass.Anchored = true
	glass.CanCollide = false
	glass.CanQuery = false
	glass.Material = Enum.Material.Glass
	glass.Color = Color3.fromRGB(120, 200, 255)
	glass.Transparency = 0.6
	glass.Parent = model

	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.9, 0.9, 0.9)
	orb.CFrame = CFrame.new(floorPos + Vector3.new(0, 2, 0))
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.Material = Enum.Material.Neon
	orb.Color = Color3.fromRGB(80, 220, 80)
	orb.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LabPrompt"
	prompt.ActionText = "Открыть"
	prompt.ObjectText = "Лаборатория"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.LAB_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = orb

	return model
end

local function stripOutdoorLabPrompts()
	local map = workspace:FindFirstChild("Map")
	if not map then
		return
	end
	for _, inst in ipairs(map:GetDescendants()) do
		if inst.Name == "LabPrompt" and inst:IsA("ProximityPrompt") then
			local interior = inst:FindFirstAncestor("Interiors")
			if not interior then
				inst:Destroy()
			end
		end
	end
	for _, spawn in ipairs(workspace:GetDescendants()) do
		if spawn:IsA("SpawnLocation") then
			local p = spawn:FindFirstChild("LabPrompt")
			if p then
				p:Destroy()
			end
		end
	end
end

local function findBasementLab(interior: Instance): Instance?
	local segments = interior:FindFirstChild("Segments")
	if not segments then
		return nil
	end
	return segments:FindFirstChild("basement_lab")
end

local function findLabHost(basement: Instance): BasePart?
	local bench = basement:FindFirstChild("Bench", true)
	if bench and bench:IsA("BasePart") then
		return bench
	end
	local capsule = basement:FindFirstChild("Capsule_1", true)
	if capsule and capsule:IsA("BasePart") then
		return capsule
	end
	return basement:FindFirstChildWhichIsA("BasePart", true)
end

local function attachLabPrompt(host: BasePart, baseId: number, folder: Folder)
	host:SetAttribute("BaseId", baseId)

	local existing = host:FindFirstChild("LabPrompt")
	if existing then
		existing:Destroy()
	end

	local modelName = "Lab_Base" .. baseId .. "_" .. host.Name
	local oldModel = folder:FindFirstChild(modelName)
	if oldModel then
		oldModel:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = modelName
	model:SetAttribute("BaseId", baseId)
	model.Parent = folder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LabPrompt"
	prompt.ActionText = "Открыть"
	prompt.ObjectText = "Лаборатория"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.LAB_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = host

	local bind = Instance.new("ObjectValue")
	bind.Name = "LabHost"
	bind.Value = host
	bind.Parent = model
end

local function initStudioLabs(folder: Folder)
	stripOutdoorLabPrompts()

	local map = workspace:FindFirstChild("Map")
	local interiors = map and map:FindFirstChild("Interiors")
	if not interiors then
		warn("[LabService] Нет Map.Interiors")
		return
	end

	local placed = {}
	for _, interior in ipairs(interiors:GetChildren()) do
		local interiorId = tostring(interior:GetAttribute("InteriorId") or interior.Name)
		local baseId = BaseUtil.normalizeId(string.match(interiorId, "(%d+)$"))
			or BaseUtil.normalizeId(string.match(interior.Name, "(%d+)$"))
		if baseId and not placed[baseId] then
			placed[baseId] = true
			local basement = findBasementLab(interior)
			local host = basement and findLabHost(basement)
			if host then
				attachLabPrompt(host, baseId, folder)
			end
			local spawn = interior:FindFirstChild("Spawn", true)
			if spawn and spawn:IsA("BasePart") and spawn ~= host then
				attachLabPrompt(spawn, baseId, folder)
			elseif not host then
				warn("[LabService] Нет места для Lab в", interior.Name)
			end
		end
	end
end

function LabService.init()
	local existing = workspace:FindFirstChild("Labs")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Labs"
	folder.Parent = workspace

	if Config.STUDIO_MAP_MODE then
		initStudioLabs(folder)
		return
	end

	for baseId = 1, Config.BASE_COUNT do
		local floorPos = BaseUtil.getLabFloorPos(baseId)
		if not floorPos then
			warn("[LabService] Missing base", baseId)
			continue
		end
		buildCapsule(floorPos, baseId).Parent = folder
	end
end

return LabService

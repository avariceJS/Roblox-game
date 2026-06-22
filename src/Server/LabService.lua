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

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.new(0, 120, 0, 36)
	sign.StudsOffset = Vector3.new(0, 2.2, 0)
	sign.Adornee = glass
	sign.Parent = model

	local signText = Instance.new("TextLabel", sign)
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "⚗️ Лаборатория"
	signText.TextColor3 = Color3.fromRGB(220, 240, 255)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold

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

function LabService.init()
	local existing = workspace:FindFirstChild("Labs")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Labs"
	folder.Parent = workspace

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

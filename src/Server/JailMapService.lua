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
	cage.Parent = model

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.new(0, 140, 0, 36)
	sign.StudsOffset = Vector3.new(0, 2.2, 0)
	sign.Adornee = cage
	sign.Parent = model

	local signText = Instance.new("TextLabel", sign)
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "⛓️ Клетка"
	signText.TextColor3 = Color3.fromRGB(200, 150, 80)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold

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

function JailMapService.init()
	local existing = workspace:FindFirstChild("Jails")
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "Jails"
	folder.Parent = workspace

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

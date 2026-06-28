local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)
local Config   = require(game.ReplicatedStorage.src.Shared.Config)

local ShopMapService = {}

local function buildShop(floorPos: Vector3, baseId: number): Model
	local model = Instance.new("Model")
	model.Name = "Shop_Base" .. baseId
	model:SetAttribute("BaseId", baseId)

	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Size = Vector3.new(4, 1, 2)
	counter.CFrame = CFrame.new(floorPos + Vector3.new(0, 0.5, 0))
	counter.Anchored = true
	counter.Material = Enum.Material.WoodPlanks
	counter.Color = Color3.fromRGB(140, 90, 50)
	counter.Parent = model

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.new(0, 140, 0, 36)
	sign.StudsOffset = Vector3.new(0, 1.5, 0)
	sign.Adornee = counter
	sign.Parent = model

	local signText = Instance.new("TextLabel", sign)
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "🏪 Магазин"
	signText.TextColor3 = Color3.fromRGB(255, 230, 180)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Открыть"
	prompt.ObjectText = "Магазин"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.LAB_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	return model
end

function ShopMapService.init()
	local existing = workspace:FindFirstChild("Shops")
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "Shops"
	folder.Parent = workspace

	for baseId = 1, Config.BASE_COUNT do
		local pos = BaseUtil.getShopFloorPos(baseId)
		if not pos then
			warn("[ShopMapService] Missing base", baseId)
			continue
		end
		buildShop(pos, baseId).Parent = folder
	end
end

return ShopMapService

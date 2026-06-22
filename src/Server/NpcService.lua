local Config = require(game.ReplicatedStorage.src.Shared.Config)

local NpcService = {}

function NpcService.init()
	local existing = workspace:FindFirstChild("NpcHomes")
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "NpcHomes"
	folder.Parent = workspace

	local house = Instance.new("Part")
	house.Name     = "House"
	house.Size     = Config.BASE_SIZE
	house.Position = Config.NPC_HOME_POSITION
	house.Anchored = true
	house.Color    = Color3.fromRGB(120, 80, 40)
	house.Material = Enum.Material.Wood
	house:SetAttribute("BaseId", Config.NPC_HOME_ID)
	house.Parent = folder
end

return NpcService

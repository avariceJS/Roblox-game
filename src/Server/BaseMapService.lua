local Config = require(game.ReplicatedStorage.src.Shared.Config)

local BaseMapService = {}

function BaseMapService.ensure()
	local old = workspace:FindFirstChild("Bases")
	if old then
		old:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Bases"
	folder.Parent = workspace

	for _, entry in Config.BASE_LAYOUT do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Base" .. entry.id
		spawn.Size = Config.BASE_SIZE
		spawn.Position = entry.position
		spawn.Anchored = true
		spawn.Neutral = false
		spawn.CanCollide = true
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.Color = entry.color
		spawn:SetAttribute("BaseId", entry.id)
		spawn.Parent = folder
	end
end

return BaseMapService

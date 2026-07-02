local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local Remotes = game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Remotes")
local fnGetData = Remotes:WaitForChild("GetPlayerData") :: RemoteFunction
local evBaseAssigned = Remotes:WaitForChild("BaseAssigned") :: RemoteEvent

local markerFolder: Folder? = nil
local activeBaseId: number? = nil

local function buildMarker(baseId: number, platform: BasePart)
	if markerFolder then
		markerFolder:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "MyBaseMarker"
	folder.Parent = workspace
	markerFolder = folder

	local topY = platform.Position.Y + platform.Size.Y * 0.5
	local center = Vector3.new(platform.Position.X, topY, platform.Position.Z)

	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.05, 0.05, 0.05)
	anchor.CFrame = CFrame.new(center + Vector3.new(0, 16, 0))
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Parent = folder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 280, 0, 64)
	billboard.AlwaysOnTop = true
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel", billboard)
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "▼  ВАШ ОСОБНЯК #" .. baseId
	label.TextColor3 = Color3.fromRGB(100, 255, 120)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(0, 40, 0)
end

local function showMarker(baseId: number)
	if activeBaseId == baseId and markerFolder then
		return
	end
	activeBaseId = baseId

	task.spawn(function()
		workspace:WaitForChild("Bases", 30)

		for _ = 1, 40 do
			local platform = BaseUtil.getSpawn(baseId)
			if platform then
				buildMarker(baseId, platform)
				return
			end
			task.wait(0.25)
		end

		warn("[BaseMarker] Missing platform for base", baseId)
	end)
end

evBaseAssigned.OnClientEvent:Connect(function(payload: { baseId: any })
	local baseId = BaseUtil.normalizeId(payload.baseId)
	if baseId then
		showMarker(baseId)
	end
end)

task.spawn(function()
	for _ = 1, 40 do
		if activeBaseId and markerFolder then
			return
		end

		local result = fnGetData:InvokeServer()
		if result.ok and result.baseId then
			showMarker(BaseUtil.normalizeId(result.baseId))
			return
		end

		task.wait(0.25)
	end
end)

return nil

local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local Remotes = game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Remotes")
local fnGetData = Remotes:WaitForChild("GetPlayerData") :: RemoteFunction
local evBaseAssigned = Remotes:WaitForChild("BaseAssigned") :: RemoteEvent

local markerFolder: Folder? = nil
local activeBaseId: number? = nil

local function findHomeAnchor(baseId: number): BasePart?
	local map = workspace:FindFirstChild("Map")
	local roots = { map, workspace }
	for _, root in ipairs(roots) do
		if root then
			for _, inst in ipairs(root:GetDescendants()) do
				if inst.Name == "HomeDoor" and inst:IsA("BasePart") then
					local id = BaseUtil.normalizeId(inst:GetAttribute("BaseId"))
					if id == baseId then
						return inst
					end
				end
			end
		end
	end

	local mansions = map and map:FindFirstChild("Mansions")
	if mansions then
		local named = mansions:FindFirstChild("Mansion_" .. baseId)
		if named then
			local door = named:FindFirstChild("HomeDoor", true)
			if door and door:IsA("BasePart") then
				return door
			end
			local part = named:FindFirstChildWhichIsA("BasePart", true)
			if part then
				return part
			end
		end
	end

	local build = map and map:FindFirstChild("Build")
	local edit = build and build:FindFirstChild("MansionEdit")
	if edit and baseId == 1 then
		local door = edit:FindFirstChild("HomeDoor", true)
		if door and door:IsA("BasePart") then
			return door
		end
	end

	return BaseUtil.getSpawn(baseId)
end

local function buildMarker(baseId: number, anchorPart: BasePart)
	if markerFolder then
		markerFolder:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "MyBaseMarker"
	folder.Parent = workspace
	markerFolder = folder

	local topY = anchorPart.Position.Y + math.max(anchorPart.Size.Y * 0.5, 4)
	local center = Vector3.new(anchorPart.Position.X, topY, anchorPart.Position.Z)

	local anchor = Instance.new("Part")
	anchor.Name = "MarkerAnchor"
	anchor.Size = Vector3.new(0.05, 0.05, 0.05)
	anchor.CFrame = CFrame.new(center + Vector3.new(0, 22, 0))
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

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "▼  ВАШ ОСОБНЯК #" .. baseId
	label.TextColor3 = Color3.fromRGB(100, 255, 120)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(0, 40, 0)
	label.Parent = billboard
end

local function showMarker(baseId: number)
	if activeBaseId == baseId and markerFolder then
		return
	end
	activeBaseId = baseId

	task.spawn(function()
		for _ = 1, 50 do
			local anchor = findHomeAnchor(baseId)
			if anchor then
				buildMarker(baseId, anchor)
				return
			end
			task.wait(0.25)
		end

		warn("[BaseMarker] Нет HomeDoor/дома для базы", baseId)
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

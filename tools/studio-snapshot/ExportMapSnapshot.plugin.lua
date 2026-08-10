local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local PLUGIN_NAME = "Map Snapshot"
local URLS = {
	"http://127.0.0.1:8765/snapshot",
	"http://localhost:8765/snapshot",
}
local MAX_DEPTH = 40

local INTERESTING = {
	Folder = true,
	Model = true,
	Part = true,
	MeshPart = true,
	UnionOperation = true,
	WedgePart = true,
	CornerWedgePart = true,
	TrussPart = true,
	SpawnLocation = true,
	Seat = true,
	VehicleSeat = true,
	Decal = true,
	Texture = true,
	SurfaceGui = true,
	BillboardGui = true,
	ProximityPrompt = true,
	Attachment = true,
	ClickDetector = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
	SpecialMesh = true,
	BlockMesh = true,
	CylinderMesh = true,
	Fire = true,
	Smoke = true,
	Sparkles = true,
	ParticleEmitter = true,
	Beam = true,
	Trail = true,
	StringValue = true,
	NumberValue = true,
	BoolValue = true,
	IntValue = true,
	ObjectValue = true,
	CFrameValue = true,
	Vector3Value = true,
	Color3Value = true,
	Configuration = true,
}

local function log(msg)
	print("[" .. PLUGIN_NAME .. "] " .. msg)
end

local function logWarn(msg)
	warn("[" .. PLUGIN_NAME .. "] " .. msg)
end

local function round(n, places)
	if typeof(n) ~= "number" then
		return 0
	end
	local m = 10 ^ (places or 3)
	return math.floor(n * m + 0.5) / m
end

local function vec3(v)
	return { round(v.X), round(v.Y), round(v.Z) }
end

local function color3(c)
	return { round(c.R, 4), round(c.G, 4), round(c.B, 4) }
end

local function prop(inst, name)
	local ok, value = pcall(function()
		return inst[name]
	end)
	if ok then
		return value
	end
	return nil
end

local function enumName(value)
	if value == nil then
		return nil
	end
	local ok, name = pcall(function()
		return value.Name
	end)
	if ok then
		return name
	end
	return tostring(value)
end

local function asTextureUri(value)
	if value == nil then
		return nil
	end
	local t = typeof(value)
	if t == "string" then
		return value
	end
	local ok, s = pcall(function()
		return tostring(value)
	end)
	if ok then
		return s
	end
	return nil
end

local function encodeAttr(value)
	local t = typeof(value)
	if t == "string" or t == "number" or t == "boolean" then
		return value
	elseif t == "Vector3" then
		return vec3(value)
	elseif t == "Color3" then
		return color3(value)
	elseif t == "BrickColor" then
		return value.Name
	elseif t == "EnumItem" then
		return tostring(value)
	end
	return tostring(value)
end

local function attributesOf(inst)
	local ok, attrs = pcall(function()
		return inst:GetAttributes()
	end)
	if not ok or not attrs or not next(attrs) then
		return nil
	end
	local out = {}
	for k, v in pairs(attrs) do
		out[k] = encodeAttr(v)
	end
	return out
end

local function tagsOf(inst)
	local ok, tags = pcall(function()
		return CollectionService:GetTags(inst)
	end)
	if not ok or not tags or #tags == 0 then
		return nil
	end
	table.sort(tags)
	return tags
end

local function basePartFields(part, node)
	local size = prop(part, "Size")
	if size then
		node.size = vec3(size)
	end
	local position = prop(part, "Position")
	if position then
		node.position = vec3(position)
	end
	local orientation = prop(part, "Orientation")
	if orientation then
		node.orientation = vec3(orientation)
	end
	node.material = enumName(prop(part, "Material"))
	local color = prop(part, "Color")
	if color then
		node.color = color3(color)
	end
	local transparency = prop(part, "Transparency")
	if transparency ~= nil then
		node.transparency = round(transparency, 3)
	end
	local reflectance = prop(part, "Reflectance")
	if reflectance ~= nil then
		node.reflectance = round(reflectance, 3)
	end
	node.anchored = prop(part, "Anchored")
	node.canCollide = prop(part, "CanCollide")
	node.canQuery = prop(part, "CanQuery")
	node.canTouch = prop(part, "CanTouch")
	node.castShadow = prop(part, "CastShadow")
	node.shape = enumName(prop(part, "Shape"))
	if part:IsA("MeshPart") then
		node.meshId = asTextureUri(prop(part, "MeshId"))
		node.textureId = asTextureUri(prop(part, "TextureID"))
	end
end

local function decalFields(d, node)
	node.face = enumName(prop(d, "Face"))
	node.texture = asTextureUri(prop(d, "Texture")) or asTextureUri(prop(d, "TextureContent")) or asTextureUri(prop(d, "ColorMapContent"))
	local transparency = prop(d, "Transparency")
	if transparency ~= nil then
		node.transparency = round(transparency, 3)
	end
	local color = prop(d, "Color3")
	if color then
		node.color = color3(color)
	end
	node.zIndex = prop(d, "ZIndex")
end

local function textureFields(t, node)
	decalFields(t, node)
	node.studsPerTileU = prop(t, "StudsPerTileU")
	node.studsPerTileV = prop(t, "StudsPerTileV")
	node.offsetStudsU = prop(t, "OffsetStudsU")
	node.offsetStudsV = prop(t, "OffsetStudsV")
end

local function promptFields(p, node)
	node.actionText = prop(p, "ActionText")
	node.objectText = prop(p, "ObjectText")
	node.enabled = prop(p, "Enabled")
	node.holdDuration = prop(p, "HoldDuration")
	node.maxActivationDistance = prop(p, "MaxActivationDistance")
	node.requiresLineOfSight = prop(p, "RequiresLineOfSight")
	node.style = enumName(prop(p, "Style"))
end

local function valueFields(v, node)
	local value = prop(v, "Value")
	if v:IsA("ObjectValue") then
		node.value = value and value:GetFullName() or nil
	elseif typeof(value) == "Vector3" then
		node.value = vec3(value)
	elseif typeof(value) == "Color3" then
		node.value = color3(value)
	elseif typeof(value) == "CFrame" then
		node.value = { position = vec3(value.Position) }
	else
		node.value = value
	end
end

local function dumpInstance(inst, depth)
	if depth > MAX_DEPTH then
		return { name = inst.Name, className = inst.ClassName, truncated = true }
	end

	if not INTERESTING[inst.ClassName] and not inst:IsA("BasePart") and not inst:IsA("Model") and not inst:IsA("Folder") then
		local hasInterestingDescendant = false
		for _, d in ipairs(inst:GetDescendants()) do
			if INTERESTING[d.ClassName] or d:IsA("BasePart") then
				hasInterestingDescendant = true
				break
			end
		end
		if not hasInterestingDescendant then
			return nil
		end
	end

	local node = {
		name = inst.Name,
		className = inst.ClassName,
		path = inst:GetFullName(),
	}

	local attrs = attributesOf(inst)
	if attrs then
		node.attributes = attrs
	end

	local tags = tagsOf(inst)
	if tags then
		node.tags = tags
	end

	if inst:IsA("BasePart") then
		basePartFields(inst, node)
	elseif inst:IsA("Texture") then
		textureFields(inst, node)
	elseif inst:IsA("Decal") then
		decalFields(inst, node)
	elseif inst:IsA("ProximityPrompt") then
		promptFields(inst, node)
	elseif inst:IsA("ValueBase") then
		valueFields(inst, node)
	elseif inst:IsA("SpecialMesh") or inst:IsA("BlockMesh") or inst:IsA("CylinderMesh") then
		if inst:IsA("SpecialMesh") then
			node.meshType = enumName(prop(inst, "MeshType"))
			node.meshId = asTextureUri(prop(inst, "MeshId"))
			node.textureId = asTextureUri(prop(inst, "TextureId"))
		end
		local scale = prop(inst, "Scale")
		if scale then
			node.scale = vec3(scale)
		end
	elseif inst:IsA("Light") then
		local brightness = prop(inst, "Brightness")
		if brightness ~= nil then
			node.brightness = round(brightness, 3)
		end
		local color = prop(inst, "Color")
		if color then
			node.color = color3(color)
		end
		local range = prop(inst, "Range")
		if range ~= nil then
			node.range = round(range, 3)
		end
		node.enabled = prop(inst, "Enabled")
	end

	local children = {}
	for _, child in ipairs(inst:GetChildren()) do
		local dumped = dumpInstance(child, depth + 1)
		if dumped then
			table.insert(children, dumped)
		end
	end
	if #children > 0 then
		node.children = children
	end

	return node
end

local function addRoot(roots, seen, inst)
	if not inst or seen[inst] then
		return
	end
	seen[inst] = true
	table.insert(roots, inst)
end

local function defaultRoots()
	local roots = {}
	local seen = {}
	local map = workspace:FindFirstChild("Map")
	addRoot(roots, seen, map)
	addRoot(roots, seen, workspace:FindFirstChild("Bases"))
	addRoot(roots, seen, workspace:FindFirstChild("Interiors"))
	if map then
		addRoot(roots, seen, map:FindFirstChild("Interiors"))
	end
	local rs = game:GetService("ReplicatedStorage")
	addRoot(roots, seen, rs:FindFirstChild("Assets"))
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "Terrain" or child.Name == "Camera" then
			continue
		end
		if child:IsA("Model") or child:IsA("Folder") then
			addRoot(roots, seen, child)
		end
	end
	return roots
end

local function buildPayload(roots, mode)
	local trees = {}
	for _, root in ipairs(roots) do
		log("dump " .. root:GetFullName())
		table.insert(trees, dumpInstance(root, 0))
	end
	return {
		exportedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		mode = mode,
		placeId = game.PlaceId,
		placeName = game.Name,
		roots = trees,
	}
end

local function tryPost(json)
	local lastErr = nil
	for _, url in ipairs(URLS) do
		local ok, result = pcall(function()
			return HttpService:RequestAsync({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = json,
			})
		end)
		if ok and result and (result.Success or result.StatusCode == 200) then
			return true, url, nil
		end
		if ok and result then
			lastErr = "HTTP " .. tostring(result.StatusCode) .. " " .. tostring(result.StatusMessage) .. " @ " .. url
		else
			lastErr = tostring(result) .. " @ " .. url
		end
	end
	return false, nil, lastErr
end

local function writeServerStorage(json)
	local folder = ServerStorage:FindFirstChild("_MapSnapshot")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "_MapSnapshot"
		folder.Parent = ServerStorage
	end

	local maxChunk = 180000
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end

	local index = 1
	for i = 1, #json, maxChunk do
		local chunk = string.sub(json, i, i + maxChunk - 1)
		local sv = Instance.new("StringValue")
		sv.Name = string.format("Part_%02d", index)
		sv.Value = chunk
		sv.Parent = folder
		index += 1
	end

	local meta = Instance.new("StringValue")
	meta.Name = "Meta"
	meta.Value = HttpService:JSONEncode({
		bytes = #json,
		parts = index - 1,
		updatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	})
	meta.Parent = folder
	return folder
end

local function exportRoots(roots, mode)
	log("старт mode=" .. mode .. " roots=" .. tostring(#roots))
	if #roots == 0 then
		logWarn("Нечего экспортировать. Нет Workspace.Map / Bases / Interiors / Assets. Выдели объект и нажми Snapshot Selection.")
		local names = {}
		for _, child in ipairs(workspace:GetChildren()) do
			table.insert(names, child.Name)
		end
		logWarn("Дети Workspace: " .. table.concat(names, ", "))
		return
	end

	for _, root in ipairs(roots) do
		log("root: " .. root:GetFullName())
	end

	local payload = buildPayload(roots, mode)
	log("JSONEncode…")
	local json = HttpService:JSONEncode(payload)
	log("json bytes=" .. tostring(#json))

	local folder = writeServerStorage(json)
	log("backup → ServerStorage." .. folder.Name)

	local posted, url, postErr = tryPost(json)
	if posted then
		log("OK HTTP → " .. tostring(url))
		return
	end

	logWarn("HTTP не прошёл: " .. tostring(postErr))
	logWarn("Если всплыло окно разрешения плагина — нажми Allow для 127.0.0.1 / localhost")

	local clipOk = pcall(function()
		setclipboard(json)
	end)
	if clipOk then
		logWarn("JSON в буфере обмена → вставь в docs/snapshots/latest.json")
	else
		logWarn("Буфер недоступен. Скопируй ServerStorage._MapSnapshot Part_* вручную")
	end
end

local function safeExport(roots, mode)
	local ok, err = pcall(function()
		exportRoots(roots, mode)
	end)
	if not ok then
		logWarn("ОШИБКА: " .. tostring(err))
	end
end

log("плагин загружен. Открой View → Output, затем нажми Snapshot Map")

local toolbar = plugin:CreateToolbar(PLUGIN_NAME)

local btnMap = toolbar:CreateButton(
	"Snapshot Map",
	"Workspace.Map + Bases + Interiors + Assets",
	"rbxasset://textures/StudioSharedUI/ViewCube.png"
)
btnMap.ClickableWhenViewportHidden = true

local btnSel = toolbar:CreateButton(
	"Snapshot Selection",
	"Только выделенные объекты",
	"rbxasset://textures/StudioSharedUI/Search.png"
)
btnSel.ClickableWhenViewportHidden = true

btnMap.Click:Connect(function()
	log("клик Snapshot Map")
	safeExport(defaultRoots(), "map")
end)

btnSel.Click:Connect(function()
	log("клик Snapshot Selection")
	local sel = Selection:Get()
	if #sel == 0 then
		logWarn("Ничего не выделено в Explorer")
		return
	end
	safeExport(sel, "selection")
end)

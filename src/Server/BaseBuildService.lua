local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseBuildDefs = require(game.ReplicatedStorage.src.Shared.BaseBuildDefs)
local Config        = require(game.ReplicatedStorage.src.Shared.Config)

local BaseBuildService = {}

local function getMansion(baseId: number): Instance?
	local map = workspace:FindFirstChild("Map")
	if not map then
		return nil
	end
	local build = map:FindFirstChild("Build")
	if build then
		local edit = build:FindFirstChild("MansionEdit")
		if edit and (edit:IsA("Model") or edit:IsA("Folder")) then
			return edit
		end
	end
	local mansions = map:FindFirstChild("Mansions")
	if mansions then
		local named = mansions:FindFirstChild("Mansion_" .. baseId)
		if named and (named:IsA("Model") or named:IsA("Folder")) then
			return named
		end
	end
	local home = map:FindFirstChild("Home")
	if home and (home:IsA("Model") or home:IsA("Folder")) then
		return home
	end
	return nil
end

local function findSlot(mansion: Instance, slotName: string): (CFrame?, BasePart?)
	for _, desc in mansion:GetDescendants() do
		if desc.Name ~= slotName then
			continue
		end
		if desc:IsA("BasePart") then
			return desc.CFrame, desc
		end
		if desc:IsA("Model") then
			local part = desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart", true)
			if part then
				return desc:GetPivot(), part
			end
		end
	end
	return nil, nil
end

local function getTemplate(templateName: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("BaseUpgrades")
	local found = folder and folder:FindFirstChild(templateName, true)
	if found and found:IsA("Model") then
		return found
	end
	return nil
end

local function getInstalledFolder(mansion: Instance): Folder
	local folder = mansion:FindFirstChild("Installed")
	if folder and folder:IsA("Folder") then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = "Installed"
	created.Parent = mansion
	return created
end

local function anchorModel(model: Model)
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
		end
	end
end

local function hideSlotPart(part: BasePart)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
end

local function getModelParts(root: Instance): { BasePart }
	local parts: { BasePart } = {}
	if root:IsA("BasePart") then
		table.insert(parts, root)
	end
	for _, desc in root:GetDescendants() do
		if desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end
	return parts
end

local function applySlotAppearance(slotPart: BasePart, clone: Model)
	local parts = getModelParts(clone)
	if #parts == 0 then
		return
	end
	if #parts == 1 then
		local part = parts[1]
		part.Size = slotPart.Size
		part.Color = slotPart.Color
		part.Material = slotPart.Material
		part.Reflectance = slotPart.Reflectance
		part.Transparency = 0
		if slotPart:IsA("Part") and part:IsA("Part") then
			part.Shape = slotPart.Shape
		end
		return
	end
	for _, part in parts do
		part.Color = slotPart.Color
		part.Material = slotPart.Material
		part.Reflectance = slotPart.Reflectance
		part.Transparency = 0
	end
end

local function collectMansions(): { Instance }
	local result: { Instance } = {}
	local map = workspace:FindFirstChild("Map")
	if not map then
		return result
	end
	local build = map:FindFirstChild("Build")
	if build then
		local edit = build:FindFirstChild("MansionEdit")
		if edit and (edit:IsA("Model") or edit:IsA("Folder")) then
			table.insert(result, edit)
		end
	end
	local mansions = map:FindFirstChild("Mansions")
	if mansions then
		for _, child in mansions:GetChildren() do
			if child:IsA("Model") or child:IsA("Folder") then
				table.insert(result, child)
			end
		end
	end
	local home = map:FindFirstChild("Home")
	if home and (home:IsA("Model") or home:IsA("Folder")) then
		table.insert(result, home)
	end
	return result
end

function BaseBuildService.prepareMap()
	for _, mansion in collectMansions() do
		for _, def in BaseBuildDefs do
			local _, slotPart = findSlot(mansion, def.slot)
			if slotPart then
				hideSlotPart(slotPart)
			end
		end
	end
end

function BaseBuildService.apply(baseId: number, buildKey: string): (boolean, string?)
	local def = BaseBuildDefs[buildKey]
	if not def then
		return false, "Неизвестное улучшение"
	end
	local mansion = getMansion(baseId)
	if not mansion then
		return false, "Нет дома в Map (Home или Mansions/Mansion_" .. baseId .. ")"
	end
	local slotCf, slotPart = findSlot(mansion, def.slot)
	if not slotCf or not slotPart then
		return false, "Нет слота " .. def.slot .. " в MansionEdit — Part в UpgradeSlots"
	end
	local template = getTemplate(def.template)
	if not template then
		return false, "Нет Assets/BaseUpgrades/" .. def.template
	end
	local installed = getInstalledFolder(mansion)
	local existing = installed:FindFirstChild(buildKey)
	if existing then
		existing:Destroy()
	end
	local clone = template:Clone()
	clone.Name = buildKey
	if def.drivable then
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	else
		anchorModel(clone)
		applySlotAppearance(slotPart, clone)
	end
	clone:PivotTo(slotCf)
	clone.Parent = installed
	hideSlotPart(slotPart)
	return true, nil
end

function BaseBuildService.remove(baseId: number, buildKey: string): (boolean, string?)
	local def = BaseBuildDefs[buildKey]
	if not def then
		return false, "Неизвестное улучшение"
	end
	local mansion = getMansion(baseId)
	if not mansion then
		return false, "Нет дома на базе"
	end
	local installed = mansion:FindFirstChild("Installed")
	local existing = installed and installed:FindFirstChild(buildKey)
	if existing then
		existing:Destroy()
	end
	local _, slotPart = findSlot(mansion, def.slot)
	if slotPart then
		hideSlotPart(slotPart)
	end
	return true, nil
end

function BaseBuildService.syncForPlayer(player, data)
	local baseId = tonumber(data.baseId)
	if not baseId then
		return
	end
	for buildKey, _ in BaseBuildDefs do
		if (data.baseUpgrades or {})[buildKey] then
			local ok, err = BaseBuildService.apply(baseId, buildKey)
			if not ok then
				warn("[BaseBuildService] sync", player.Name, buildKey, err)
			end
		end
	end
end

function BaseBuildService.purchase(player, data, buildKey: string, evMonsterUpdated): { ok: boolean, message: string? }
	local def = BaseBuildDefs[buildKey]
	if not def then
		return { ok = false, message = "Улучшение не найдено" }
	end
	local price = Config.UPGRADE_PRICES[buildKey]
	if price == nil then
		return { ok = false, message = "Цена не задана" }
	end
	if (data.baseUpgrades or {})[buildKey] then
		return { ok = false, message = "Уже куплено" }
	end
	if data.coins < price then
		return { ok = false, message = "Недостаточно монет (нужно " .. price .. ")" }
	end
	local baseId = tonumber(data.baseId)
	if not baseId then
		return { ok = false, message = "База не назначена" }
	end
	data.coins = data.coins - price
	data.baseUpgrades = data.baseUpgrades or {}
	data.baseUpgrades[buildKey] = true
	local ok, err = BaseBuildService.apply(baseId, buildKey)
	if not ok then
		data.baseUpgrades[buildKey] = nil
		data.coins = data.coins + price
		return { ok = false, message = err or "Не удалось установить" }
	end
	local PlayerDataService = require(script.Parent.PlayerDataService)
	PlayerDataService.save(player)
	evMonsterUpdated:FireClient(player, {
		coins    = data.coins,
		upgrades = data.baseUpgrades,
		toast    = "Куплено: " .. def.displayName .. "! " .. def.emoji,
	})
	return { ok = true }
end

function BaseBuildService.sell(player, data, buildKey: string, evMonsterUpdated): { ok: boolean, message: string? }
	local def = BaseBuildDefs[buildKey]
	if not def then
		return { ok = false, message = "Улучшение не найдено" }
	end
	if not (data.baseUpgrades or {})[buildKey] then
		return { ok = false, message = "Не куплено" }
	end
	local baseId = tonumber(data.baseId)
	if not baseId then
		return { ok = false, message = "База не назначена" }
	end
	local ok, err = BaseBuildService.remove(baseId, buildKey)
	if not ok then
		return { ok = false, message = err or "Не удалось убрать" }
	end
	local refund = Config.UPGRADE_PRICES[buildKey] or 0
	data.baseUpgrades[buildKey] = nil
	data.coins = data.coins + refund
	local PlayerDataService = require(script.Parent.PlayerDataService)
	PlayerDataService.save(player)
	evMonsterUpdated:FireClient(player, {
		coins    = data.coins,
		upgrades = data.baseUpgrades,
		toast    = "Продано: " .. def.displayName,
	})
	return { ok = true }
end

return BaseBuildService

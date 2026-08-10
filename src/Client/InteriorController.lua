local Players                = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local src          = game.ReplicatedStorage:WaitForChild("src")
local Remotes      = src:WaitForChild("Remotes")
local InteriorDefs = require(src.Shared.InteriorDefs)
local UiUtil       = require(src.Client.UiUtil)

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

local fnGetData            = Remotes:WaitForChild("GetPlayerData")      :: RemoteFunction
local fnBuyInteriorUpgrade = Remotes:WaitForChild("BuyInteriorUpgrade") :: RemoteFunction
local evMonsterUpdated     = Remotes:WaitForChild("MonsterUpdated")     :: RemoteEvent

local ROW_H   = 58
local PANEL_W = 420

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "InteriorShopGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = playerGui

local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel        = 0
overlay.Visible                = false
overlay.ZIndex                 = 10
overlay.Parent                 = screenGui

local panel = Instance.new("Frame")
panel.Size                   = UDim2.new(0, PANEL_W, 0, 200)
panel.Position               = UDim2.new(0.5, -PANEL_W / 2, 0.5, -100)
panel.BackgroundColor3       = Color3.fromRGB(18, 18, 26)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel        = 0
panel.ZIndex                 = 11
panel.Parent                 = overlay
UiUtil.corner(panel, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, -60, 0, 46)
titleLabel.Position           = UDim2.new(0, 16, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "🏛  Улучшения особняка"
titleLabel.TextColor3         = Color3.fromRGB(235, 215, 155)
titleLabel.TextScaled         = true
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.ZIndex             = 12
titleLabel.Parent             = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size                   = UDim2.new(0, 36, 0, 36)
closeBtn.Position               = UDim2.new(1, -48, 0, 10)
closeBtn.BackgroundColor3       = Color3.fromRGB(70, 35, 35)
closeBtn.BackgroundTransparency = 0.1
closeBtn.BorderSizePixel        = 0
closeBtn.Text                   = "✕"
closeBtn.TextColor3             = Color3.fromRGB(235, 175, 175)
closeBtn.TextScaled             = true
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.ZIndex                 = 12
closeBtn.Parent                 = panel
UiUtil.corner(closeBtn, 8)

local showToast = UiUtil.makeToast(screenGui, UDim2.new(0.5, -185, 1, -96), 370)

local currentCoins: number             = 0
local currentInteriorId: string?       = nil
local currentUpgrades: { [string]: boolean } = {}
local availableDefs: { any }           = {}
local rowFrames: { Frame }             = {}

local function attrFromAncestors(instance: Instance, name: string): any
	local cur: Instance? = instance
	while cur and cur ~= workspace do
		local v = cur:GetAttribute(name)
		if v ~= nil then
			return v
		end
		cur = cur.Parent
	end
	return nil
end

local function getSegmentsFolder(interiorId: string): Folder?
	local map = workspace:FindFirstChild("Map")
	local interiors = map and map:FindFirstChild("Interiors")
	if not interiors then
		return nil
	end
	local interior = interiors:FindFirstChild("Interior_" .. interiorId)
	if not interior then
		for _, child in interiors:GetChildren() do
			if tostring(child:GetAttribute("InteriorId")) == interiorId then
				interior = child
				break
			end
		end
	end
	if not interior then
		return nil
	end
	local segments = interior:FindFirstChild("Segments")
	if segments and segments:IsA("Folder") then
		return segments
	end
	return nil
end

local function defsForInterior(interiorId: string?): { any }
	local list = {}
	if not interiorId then
		return list
	end
	local segments = getSegmentsFolder(interiorId)
	if not segments then
		return list
	end
	for _, def in InteriorDefs do
		if segments:FindFirstChild(def.segment) then
			table.insert(list, def)
		end
	end
	return list
end

local function hasDependent(key: string): boolean
	for _, d in availableDefs do
		if d.requires == key and currentUpgrades[d.key] == true then
			return true
		end
	end
	return false
end

local function renderRows()
	for _, row in rowFrames do row:Destroy() end
	table.clear(rowFrames)

	local count = #availableDefs
	local panelH = 60 + math.max(count, 1) * (ROW_H + 8) + 20
	panel.Size = UDim2.new(0, PANEL_W, 0, panelH)
	panel.Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -panelH / 2)

	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -24, 0, ROW_H)
		empty.Position = UDim2.new(0, 12, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Text = "Нет сегментов для этого дома"
		empty.TextColor3 = Color3.fromRGB(140, 140, 160)
		empty.TextScaled = true
		empty.Font = Enum.Font.Gotham
		empty.ZIndex = 12
		empty.Parent = panel
		table.insert(rowFrames, empty :: any)
		return
	end

	for i, def in availableDefs do
		local bought    = currentUpgrades[def.key] == true
		local reqOk     = not def.requires or currentUpgrades[def.requires] == true
		local canAfford = currentCoins >= def.price
		local y         = 60 + (i - 1) * (ROW_H + 8)

		local row = Instance.new("Frame")
		row.Size              = UDim2.new(1, -24, 0, ROW_H)
		row.Position          = UDim2.new(0, 12, 0, y)
		row.BackgroundColor3  = Color3.fromRGB(26, 28, 38)
		row.BorderSizePixel   = 0
		row.ZIndex            = 12
		row.Parent            = panel
		UiUtil.corner(row, 8)
		table.insert(rowFrames, row)

		local label = Instance.new("TextLabel")
		label.Size                   = UDim2.new(1, -118, 1, 0)
		label.Position               = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.TextScaled             = true
		label.Font                   = Enum.Font.Gotham
		label.TextXAlignment         = Enum.TextXAlignment.Left
		label.ZIndex                 = 13
		label.Parent                 = row

		local action = Instance.new("TextButton")
		action.Size             = UDim2.new(0, 100, 0, 40)
		action.Position         = UDim2.new(1, -108, 0.5, -20)
		action.BorderSizePixel  = 0
		action.TextScaled       = true
		action.Font             = Enum.Font.GothamBold
		action.ZIndex           = 13
		action.Parent           = row
		UiUtil.corner(action, 8)

		if bought then
			label.TextColor3 = Color3.fromRGB(130, 215, 120)
			label.Text       = def.emoji .. "  " .. def.displayName .. "  ✅"
			local blocked = hasDependent(def.key)
			action.Text = blocked and "🔒" or ("Продать\n💰" .. def.price)
			action.BackgroundColor3 = blocked and Color3.fromRGB(40, 40, 48) or Color3.fromRGB(72, 38, 38)
			action.TextColor3 = blocked and Color3.fromRGB(120, 120, 130) or Color3.fromRGB(235, 175, 175)
			action.Active = not blocked
			action.AutoButtonColor = not blocked
			if not blocked then
				local capturedDef = def
				action.MouseButton1Click:Connect(function()
					if not action.Active then return end
					action.Active = false
					action.Text = "..."
					local result = fnBuyInteriorUpgrade:InvokeServer({ key = capturedDef.key, sell = true })
					if not result or not result.ok then
						showToast((result and result.message) or "Ошибка продажи")
						action.Active = true
						action.Text = "Продать\n💰" .. capturedDef.price
					end
				end)
			end
		elseif not reqOk then
			local reqDef = nil
			for _, d in availableDefs do
				if d.key == def.requires then reqDef = d; break end
			end
			local reqName = (reqDef and reqDef.displayName) or def.requires
			label.TextColor3 = Color3.fromRGB(100, 100, 120)
			label.Text = "🔒  " .. def.displayName .. " — нужно: " .. reqName
			action.Text = "—"
			action.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
			action.TextColor3 = Color3.fromRGB(90, 90, 100)
			action.Active = false
			action.AutoButtonColor = false
		else
			label.TextColor3 = canAfford and Color3.fromRGB(200, 210, 230) or Color3.fromRGB(100, 100, 120)
			label.Text = def.emoji .. "  " .. def.displayName
			action.Text = "Купить\n💰" .. def.price
			action.BackgroundColor3 = canAfford and Color3.fromRGB(36, 56, 88) or Color3.fromRGB(36, 36, 44)
			action.TextColor3 = canAfford and Color3.fromRGB(175, 195, 240) or Color3.fromRGB(100, 100, 120)
			action.Active = canAfford
			action.AutoButtonColor = canAfford
			if canAfford then
				local capturedDef = def
				action.MouseButton1Click:Connect(function()
					if not action.Active then return end
					action.Active = false
					action.Text = "..."
					local result = fnBuyInteriorUpgrade:InvokeServer({ key = capturedDef.key })
					if not result or not result.ok then
						showToast((result and result.message) or "Ошибка покупки")
						action.Active = true
						action.Text = "Купить\n💰" .. capturedDef.price
					end
				end)
			end
		end
	end
end

local function openPanel(fromPrompt: ProximityPrompt?)
	local data = fnGetData:InvokeServer()
	if not data or not data.ok then
		showToast((data and data.message) or "Не удалось загрузить данные")
		return
	end
	currentCoins = data.coins or 0
	currentUpgrades = {}
	for k, v in (data.upgrades or {}) do
		currentUpgrades[k] = v
	end

	local interiorId = nil
	if fromPrompt then
		interiorId = attrFromAncestors(fromPrompt, "InteriorId")
	end
	if not interiorId and data.baseId then
		interiorId = "Base" .. tostring(data.baseId)
	end
	currentInteriorId = if interiorId then tostring(interiorId) else nil
	availableDefs = defsForInterior(currentInteriorId)
	renderRows()
	overlay.Visible = true
end

closeBtn.MouseButton1Click:Connect(function()
	overlay.Visible = false
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if player ~= localPlayer or prompt.Name ~= "BookPrompt" then return end
	openPanel(prompt)
end)

evMonsterUpdated.OnClientEvent:Connect(function(payload)
	if payload.upgrades ~= nil then
		currentUpgrades = {}
		for k, v in payload.upgrades do
			currentUpgrades[k] = v
		end
	end
	if payload.coins ~= nil then
		currentCoins = payload.coins
	end
	if overlay.Visible then
		availableDefs = defsForInterior(currentInteriorId)
		renderRows()
	end
end)

return nil

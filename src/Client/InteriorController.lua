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

local ROW_H    = 50
local PANEL_W  = 390
local PANEL_H  = 60 + #InteriorDefs * (ROW_H + 8) + 20

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
panel.Size                   = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position               = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2)
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
local currentUpgrades: { [string]: boolean } = {}
local rowButtons: { TextButton }       = {}

local function renderRows()
	for _, btn in rowButtons do btn:Destroy() end
	table.clear(rowButtons)

	for i, def in InteriorDefs do
		local bought    = currentUpgrades[def.key] == true
		local reqOk     = not def.requires or currentUpgrades[def.requires] == true
		local canAfford = currentCoins >= def.price
		local y         = 60 + (i - 1) * (ROW_H + 8)

		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.new(1, -24, 0, ROW_H)
		btn.Position         = UDim2.new(0, 12, 0, y)
		btn.BorderSizePixel  = 0
		btn.TextScaled       = true
		btn.Font             = Enum.Font.Gotham
		btn.ZIndex           = 12
		btn.Parent           = panel
		UiUtil.corner(btn, 8)
		table.insert(rowButtons, btn)

		if bought then
			btn.BackgroundColor3 = Color3.fromRGB(28, 52, 28)
			btn.TextColor3       = Color3.fromRGB(130, 215, 120)
			btn.Text             = def.emoji .. "  " .. def.displayName .. "   ✅"
			btn.Active           = false
			btn.AutoButtonColor  = false
		elseif not reqOk then
			local reqDef = nil
			for _, d in InteriorDefs do
				if d.key == def.requires then reqDef = d; break end
			end
			local reqName = (reqDef and reqDef.displayName) or def.requires
			btn.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
			btn.TextColor3       = Color3.fromRGB(100, 100, 120)
			btn.Text             = "🔒  " .. def.displayName .. " — нужно: " .. reqName
			btn.Active           = false
			btn.AutoButtonColor  = false
		else
			btn.BackgroundColor3 = canAfford and Color3.fromRGB(36, 46, 68) or Color3.fromRGB(26, 26, 36)
			btn.TextColor3       = canAfford and Color3.fromRGB(175, 195, 240) or Color3.fromRGB(100, 100, 120)
			btn.Text             = def.emoji .. "  " .. def.displayName .. "   💰" .. def.price
			btn.Active           = canAfford
			btn.AutoButtonColor  = canAfford

			if canAfford then
				local capturedDef = def
				btn.MouseButton1Click:Connect(function()
					if not btn.Active then return end
					btn.Active = false
					btn.Text   = "..."
					local result = fnBuyInteriorUpgrade:InvokeServer({ key = capturedDef.key })
					if not result or not result.ok then
						showToast((result and result.message) or "Ошибка покупки")
						btn.Active = true
						btn.Text   = capturedDef.emoji .. "  " .. capturedDef.displayName .. "   💰" .. capturedDef.price
					end
				end)
			end
		end
	end
end

local function openPanel()
	local data = fnGetData:InvokeServer()
	if not data or not data.ok then
		showToast((data and data.message) or "Не удалось загрузить данные")
		return
	end
	currentCoins    = data.coins or 0
	currentUpgrades = {}
	for k, v in (data.upgrades or {}) do
		currentUpgrades[k] = v
	end
	renderRows()
	overlay.Visible = true
end

closeBtn.MouseButton1Click:Connect(function()
	overlay.Visible = false
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if player ~= localPlayer or prompt.Name ~= "BookPrompt" then return end
	openPanel()
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
		renderRows()
	end
end)

return nil

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local UiUtil = require(script.Parent.UiUtil)
local MonsterDisplay = require(game.ReplicatedStorage.src.Shared.MonsterDisplay)
local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local localPlayer = Players.LocalPlayer
local src = game.ReplicatedStorage:WaitForChild("src")
local Remotes = src:WaitForChild("Remotes")
local fnGetData = Remotes:WaitForChild("GetPlayerData") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "LabHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.IgnoreGuiInset = true
gui.Parent = localPlayer.PlayerGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.55
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 360, 0, 420)
panel.Position = UDim2.new(0.5, -180, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = overlay
UiUtil.corner(panel, 14)

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -50, 0, 44)
header.Position = UDim2.new(0, 16, 0, 10)
header.BackgroundTransparency = 1
header.Text = "⚗️  Лаборатория"
header.TextColor3 = Color3.fromRGB(210, 235, 255)
header.TextScaled = true
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -46, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = panel
UiUtil.corner(closeBtn, 8)

local slot = Instance.new("Frame")
slot.Size = UDim2.new(1, -32, 0, 110)
slot.Position = UDim2.new(0, 16, 0, 70)
slot.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
slot.BackgroundTransparency = 0.2
slot.BorderSizePixel = 0
slot.Parent = panel
UiUtil.corner(slot, 10)

local slotIcon = Instance.new("TextLabel")
slotIcon.Size = UDim2.new(0, 70, 1, 0)
slotIcon.BackgroundTransparency = 1
slotIcon.TextScaled = true
slotIcon.Font = Enum.Font.GothamBold
slotIcon.Parent = slot

local slotInfo = Instance.new("Frame")
slotInfo.Size = UDim2.new(1, -80, 1, -16)
slotInfo.Position = UDim2.new(0, 76, 0, 8)
slotInfo.BackgroundTransparency = 1
slotInfo.Parent = slot

local slotName = Instance.new("TextLabel")
slotName.Size = UDim2.new(1, 0, 0.36, 0)
slotName.BackgroundTransparency = 1
slotName.TextColor3 = Color3.fromRGB(255, 255, 255)
slotName.TextScaled = true
slotName.Font = Enum.Font.GothamBold
slotName.TextXAlignment = Enum.TextXAlignment.Left
slotName.Parent = slotInfo

local slotRarity = Instance.new("TextLabel")
slotRarity.Size = UDim2.new(1, 0, 0.28, 0)
slotRarity.Position = UDim2.new(0, 0, 0.36, 0)
slotRarity.BackgroundTransparency = 1
slotRarity.TextColor3 = Color3.fromRGB(160, 160, 160)
slotRarity.TextScaled = true
slotRarity.Font = Enum.Font.Gotham
slotRarity.TextXAlignment = Enum.TextXAlignment.Left
slotRarity.Parent = slotInfo

local slotState = Instance.new("TextLabel")
slotState.Size = UDim2.new(1, 0, 0.28, 0)
slotState.Position = UDim2.new(0, 0, 0.68, 0)
slotState.BackgroundTransparency = 1
slotState.TextScaled = true
slotState.Font = Enum.Font.Gotham
slotState.TextXAlignment = Enum.TextXAlignment.Left
slotState.Parent = slotInfo

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, -32, 0, 60)
emptyLabel.Position = UDim2.new(0, 16, 0, 70)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "Монстров пока нет"
emptyLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
emptyLabel.TextScaled = true
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.Visible = false
emptyLabel.Parent = panel

local dispatchBtn = Instance.new("TextButton")
dispatchBtn.Size = UDim2.new(1, -32, 0, 52)
dispatchBtn.Position = UDim2.new(0, 16, 1, -72)
dispatchBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
dispatchBtn.BackgroundTransparency = 0.15
dispatchBtn.BorderSizePixel = 0
dispatchBtn.Text = "Отправить  —  скоро"
dispatchBtn.TextColor3 = Color3.fromRGB(120, 120, 140)
dispatchBtn.TextScaled = true
dispatchBtn.Font = Enum.Font.GothamBold
dispatchBtn.AutoButtonColor = false
dispatchBtn.Active = false
dispatchBtn.Parent = panel
UiUtil.corner(dispatchBtn, 10)

local showToast = UiUtil.makeToast(gui, UDim2.new(0.5, -200, 0, 72), 400)

local monsterLabels = {
	icon = slotIcon,
	name = slotName,
	rarity = slotRarity,
	state = slotState,
}

local function setOpen(isOpen: boolean)
	overlay.Visible = isOpen
	panel.Visible = isOpen
end

local function render(monsters: { any }?)
	if MonsterDisplay.fill(monsterLabels, MonsterDisplay.first(monsters)) then
		slot.Visible = true
		emptyLabel.Visible = false
	else
		slot.Visible = false
		emptyLabel.Visible = true
	end
end

local function openLab(labBaseId: any)
	local labId = BaseUtil.normalizeId(labBaseId)
	local data = fnGetData:InvokeServer()

	if not data or not data.ok then
		showToast((data and data.message) or "Не удалось загрузить данные")
		return
	end

	local playerBaseId = BaseUtil.normalizeId(data.baseId)
	if not labId or not playerBaseId or playerBaseId ~= labId then
		showToast("Это особняк #" .. tostring(labId) .. ". Твой — #" .. tostring(playerBaseId))
		return
	end

	render(data.monsters)
	setOpen(true)
end

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Target == overlay then
		setOpen(false)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if player ~= localPlayer or prompt.Name ~= "LabPrompt" then
		return
	end

	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if model then
		openLab(model:GetAttribute("BaseId"))
	end
end)

return nil

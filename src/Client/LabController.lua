local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local UiUtil         = require(script.Parent.UiUtil)
local MonsterDisplay = require(game.ReplicatedStorage.src.Shared.MonsterDisplay)
local BaseUtil       = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local localPlayer = Players.LocalPlayer
local src     = game.ReplicatedStorage:WaitForChild("src")
local Remotes = src:WaitForChild("Remotes")
local fnGetData  = Remotes:WaitForChild("GetPlayerData")  :: RemoteFunction
local fnDispatch = Remotes:WaitForChild("DispatchMonster") :: RemoteFunction

-- ── GUI ────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "LabHUD"
gui.ResetOnSpawn   = false
gui.DisplayOrder   = 50
gui.IgnoreGuiInset = true
gui.Parent         = localPlayer.PlayerGui

local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.fromScale(1, 1)
overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.55
overlay.BorderSizePixel        = 0
overlay.Visible                = false
overlay.Parent                 = gui

local panel = Instance.new("Frame")
panel.Size                   = UDim2.new(0, 360, 0, 420)
panel.Position               = UDim2.new(0.5, -180, 0.5, -210)
panel.BackgroundColor3       = Color3.fromRGB(18, 18, 28)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.Parent                 = overlay
UiUtil.corner(panel, 14)

local header = Instance.new("TextLabel")
header.Size                   = UDim2.new(1, -50, 0, 44)
header.Position               = UDim2.new(0, 16, 0, 10)
header.BackgroundTransparency = 1
header.Text                   = "⚗️  Лаборатория"
header.TextColor3             = Color3.fromRGB(210, 235, 255)
header.TextScaled             = true
header.Font                   = Enum.Font.GothamBold
header.TextXAlignment         = Enum.TextXAlignment.Left
header.Parent                 = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size                   = UDim2.new(0, 36, 0, 36)
closeBtn.Position               = UDim2.new(1, -46, 0, 10)
closeBtn.BackgroundColor3       = Color3.fromRGB(60, 30, 30)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel        = 0
closeBtn.Text                   = "✕"
closeBtn.TextColor3             = Color3.fromRGB(255, 120, 120)
closeBtn.TextScaled             = true
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.Parent                 = panel
UiUtil.corner(closeBtn, 8)

local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -32, 0, 1)
divider.Position         = UDim2.new(0, 16, 0, 58)
divider.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
divider.BorderSizePixel  = 0
divider.Parent           = panel

-- ── Monster slot ───────────────────────────────────────────────────────────
local slot = Instance.new("Frame")
slot.Size                   = UDim2.new(1, -32, 0, 110)
slot.Position               = UDim2.new(0, 16, 0, 70)
slot.BackgroundColor3       = Color3.fromRGB(28, 28, 42)
slot.BackgroundTransparency = 0.2
slot.BorderSizePixel        = 0
slot.Parent                 = panel
UiUtil.corner(slot, 10)

local slotIcon = Instance.new("TextLabel")
slotIcon.Size                   = UDim2.new(0, 70, 1, 0)
slotIcon.BackgroundTransparency = 1
slotIcon.TextScaled             = true
slotIcon.Font                   = Enum.Font.GothamBold
slotIcon.Parent                 = slot

local slotInfo = Instance.new("Frame")
slotInfo.Size                   = UDim2.new(1, -80, 1, -16)
slotInfo.Position               = UDim2.new(0, 76, 0, 8)
slotInfo.BackgroundTransparency = 1
slotInfo.Parent                 = slot

local slotName = Instance.new("TextLabel")
slotName.Size                   = UDim2.new(1, 0, 0.36, 0)
slotName.BackgroundTransparency = 1
slotName.TextColor3             = Color3.fromRGB(255, 255, 255)
slotName.TextScaled             = true
slotName.Font                   = Enum.Font.GothamBold
slotName.TextXAlignment         = Enum.TextXAlignment.Left
slotName.Parent                 = slotInfo

local slotRarity = Instance.new("TextLabel")
slotRarity.Size                   = UDim2.new(1, 0, 0.28, 0)
slotRarity.Position               = UDim2.new(0, 0, 0.36, 0)
slotRarity.BackgroundTransparency = 1
slotRarity.TextColor3             = Color3.fromRGB(160, 160, 160)
slotRarity.TextScaled             = true
slotRarity.Font                   = Enum.Font.Gotham
slotRarity.TextXAlignment         = Enum.TextXAlignment.Left
slotRarity.Parent                 = slotInfo

local slotState = Instance.new("TextLabel")
slotState.Size                   = UDim2.new(1, 0, 0.28, 0)
slotState.Position               = UDim2.new(0, 0, 0.68, 0)
slotState.BackgroundTransparency = 1
slotState.TextScaled             = true
slotState.Font                   = Enum.Font.Gotham
slotState.TextXAlignment         = Enum.TextXAlignment.Left
slotState.Parent                 = slotInfo

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size                   = UDim2.new(1, -32, 0, 60)
emptyLabel.Position               = UDim2.new(0, 16, 0, 70)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text                   = "Монстров пока нет"
emptyLabel.TextColor3             = Color3.fromRGB(120, 120, 140)
emptyLabel.TextScaled             = true
emptyLabel.Font                   = Enum.Font.Gotham
emptyLabel.Visible                = false
emptyLabel.Parent                 = panel

-- ── Dispatch button ────────────────────────────────────────────────────────
local dispatchBtn = Instance.new("TextButton")
dispatchBtn.Size                   = UDim2.new(1, -32, 0, 52)
dispatchBtn.Position               = UDim2.new(0, 16, 1, -72)
dispatchBtn.BackgroundColor3       = Color3.fromRGB(50, 50, 70)
dispatchBtn.BackgroundTransparency = 0.15
dispatchBtn.BorderSizePixel        = 0
dispatchBtn.Text                   = "Нет монстров"
dispatchBtn.TextColor3             = Color3.fromRGB(120, 120, 140)
dispatchBtn.TextScaled             = true
dispatchBtn.Font                   = Enum.Font.GothamBold
dispatchBtn.AutoButtonColor        = false
dispatchBtn.Active                 = false
dispatchBtn.Parent                 = panel
UiUtil.corner(dispatchBtn, 10)

-- ── Target picker ──────────────────────────────────────────────────────────
local picker = Instance.new("Frame")
picker.Size                   = UDim2.new(1, -32, 0, 340)
picker.Position               = UDim2.new(0, 16, 0, 66)
picker.BackgroundColor3       = Color3.fromRGB(14, 14, 24)
picker.BackgroundTransparency = 0
picker.BorderSizePixel        = 0
picker.Visible                = false
picker.Parent                 = panel
UiUtil.corner(picker, 10)

local pickerTitle = Instance.new("TextLabel")
pickerTitle.Size                   = UDim2.new(1, -16, 0, 36)
pickerTitle.Position               = UDim2.new(0, 8, 0, 8)
pickerTitle.BackgroundTransparency = 1
pickerTitle.Text                   = "Выбери цель"
pickerTitle.TextColor3             = Color3.fromRGB(180, 210, 255)
pickerTitle.TextScaled             = true
pickerTitle.Font                   = Enum.Font.GothamBold
pickerTitle.Parent                 = picker

local baseButtons: { [number]: TextButton } = {}

for i = 1, 6 do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local btn = Instance.new("TextButton")
	btn.Size                   = UDim2.new(0.5, -6, 0, 64)
	btn.Position               = UDim2.new(col * 0.5, col == 0 and 4 or 2, 0, 54 + row * 72)
	btn.BackgroundColor3       = Color3.fromRGB(35, 45, 65)
	btn.BackgroundTransparency = 0.1
	btn.BorderSizePixel        = 0
	btn.Text                   = "🏚️  База #" .. i
	btn.TextColor3             = Color3.fromRGB(200, 220, 255)
	btn.TextScaled             = true
	btn.Font                   = Enum.Font.GothamBold
	btn.Parent                 = picker
	UiUtil.corner(btn, 8)
	baseButtons[i] = btn
end

local pickerBack = Instance.new("TextButton")
pickerBack.Size                   = UDim2.new(1, -16, 0, 40)
pickerBack.Position               = UDim2.new(0, 8, 1, -52)
pickerBack.BackgroundColor3       = Color3.fromRGB(50, 30, 30)
pickerBack.BackgroundTransparency = 0.2
pickerBack.BorderSizePixel        = 0
pickerBack.Text                   = "← Назад"
pickerBack.TextColor3             = Color3.fromRGB(255, 140, 140)
pickerBack.TextScaled             = true
pickerBack.Font                   = Enum.Font.GothamBold
pickerBack.Parent                 = picker
UiUtil.corner(pickerBack, 8)

local showToast = UiUtil.makeToast(gui, UDim2.new(0.5, -200, 0, 72), 400)

-- ── State ──────────────────────────────────────────────────────────────────
local playerBaseId:   number? = nil
local lastMonsters: { any }?  = nil

local monsterLabels = {
	icon   = slotIcon,
	name   = slotName,
	rarity = slotRarity,
	state  = slotState,
}

local function renderDispatch(monster: any?)
	if not monster then
		dispatchBtn.Active           = false
		dispatchBtn.AutoButtonColor  = false
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		dispatchBtn.TextColor3       = Color3.fromRGB(120, 120, 140)
		dispatchBtn.Text             = "Нет монстров"
	elseif monster.state == "Idle" then
		dispatchBtn.Active           = true
		dispatchBtn.AutoButtonColor  = true
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
		dispatchBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		dispatchBtn.Text             = "Отправить 🐸"
	elseif monster.state == "OnMission" then
		dispatchBtn.Active           = false
		dispatchBtn.AutoButtonColor  = false
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 20)
		dispatchBtn.TextColor3       = Color3.fromRGB(255, 200, 80)
		dispatchBtn.Text             = "На задании 🐸"
	else
		dispatchBtn.Active           = false
		dispatchBtn.AutoButtonColor  = false
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
		dispatchBtn.TextColor3       = Color3.fromRGB(140, 140, 255)
		dispatchBtn.Text             = "Отдыхает 💤"
	end
end

local function render(monsters: { any }?)
	lastMonsters = monsters
	local monster = MonsterDisplay.first(monsters)
	if MonsterDisplay.fill(monsterLabels, monster) then
		slot.Visible       = true
		emptyLabel.Visible = false
	else
		slot.Visible       = false
		emptyLabel.Visible = true
	end
	dispatchBtn.Visible = true
	renderDispatch(monster)
end

local function setPickerVisible(visible: boolean)
	picker.Visible      = visible
	dispatchBtn.Visible = not visible
	if visible then
		slot.Visible       = false
		emptyLabel.Visible = false
	else
		render(lastMonsters)
	end
end

local function setOpen(isOpen: boolean)
	overlay.Visible = isOpen
	panel.Visible   = isOpen
	if not isOpen then
		picker.Visible      = false
		dispatchBtn.Visible = true
	end
end

-- ── Picker open ─────────────────────────────────────────────────────────────
local function openPicker()
	for i, btn in baseButtons do
		if i == playerBaseId then
			btn.Active           = false
			btn.AutoButtonColor  = false
			btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
			btn.BackgroundTransparency = 0.5
			btn.TextColor3       = Color3.fromRGB(70, 70, 90)
		else
			btn.Active           = true
			btn.AutoButtonColor  = true
			btn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
			btn.BackgroundTransparency = 0.1
			btn.TextColor3       = Color3.fromRGB(200, 220, 255)
		end
	end
	setPickerVisible(true)
end

for i, btn in baseButtons do
	btn.MouseButton1Click:Connect(function()
		if not btn.Active then return end
		local tgtId = i
		setOpen(false)

		local result = fnDispatch:InvokeServer({ targetBaseId = tgtId })
		if result and result.ok then
			showToast("Гуппи отправился! 🐸")
		else
			showToast((result and result.message) or "Ошибка отправки")
		end
	end)
end

pickerBack.MouseButton1Click:Connect(function()
	setPickerVisible(false)
end)

dispatchBtn.MouseButton1Click:Connect(function()
	if dispatchBtn.Active then
		openPicker()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		and input.Target == overlay
	then
		setOpen(false)
	end
end)

-- ── Lab open trigger ────────────────────────────────────────────────────────
local function openLab(labBaseId: any)
	local labId = BaseUtil.normalizeId(labBaseId)
	local data  = fnGetData:InvokeServer()

	if not data or not data.ok then
		showToast((data and data.message) or "Не удалось загрузить данные")
		return
	end

	local myId = BaseUtil.normalizeId(data.baseId)
	if not labId or not myId or myId ~= labId then
		showToast("Это особняк #" .. tostring(labId) .. ". Твой — #" .. tostring(myId))
		return
	end

	playerBaseId = myId
	render(data.monsters)
	setOpen(true)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if player ~= localPlayer or prompt.Name ~= "LabPrompt" then return end
	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if model then
		openLab(model:GetAttribute("BaseId"))
	end
end)

return nil

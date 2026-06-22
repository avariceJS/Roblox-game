local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local UiUtil         = require(script.Parent.UiUtil)
local MonsterDisplay = require(game.ReplicatedStorage.src.Shared.MonsterDisplay)
local BaseUtil       = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local localPlayer = Players.LocalPlayer
local src     = game.ReplicatedStorage:WaitForChild("src")
local Remotes = src:WaitForChild("Remotes")
local fnGetData  = Remotes:WaitForChild("GetPlayerData")  :: RemoteFunction
local fnDispatch = Remotes:WaitForChild("DispatchMonster") :: RemoteFunction
local evMonsterUpdated = Remotes:WaitForChild("MonsterUpdated") :: RemoteEvent

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
local slot = Instance.new("TextButton")
slot.Size                   = UDim2.new(1, -32, 0, 110)
slot.Position               = UDim2.new(0, 16, 0, 70)
slot.BackgroundColor3       = Color3.fromRGB(28, 28, 42)
slot.BackgroundTransparency = 0.2
slot.BorderSizePixel        = 0
slot.Text                   = ""
slot.AutoButtonColor        = false
slot.Parent                 = panel
UiUtil.corner(slot, 10)

local slotStroke = Instance.new("UIStroke")
slotStroke.Color       = Color3.fromRGB(80, 220, 80)
slotStroke.Thickness   = 2
slotStroke.Transparency = 1
slotStroke.Parent      = slot

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
local playerBaseId:      number? = nil
local lastMonsters:     { any }? = nil
local selectedMonsterId: string? = nil
local fatigueTickConn: RBXScriptConnection? = nil

local monsterLabels = {
	icon   = slotIcon,
	name   = slotName,
	rarity = slotRarity,
	state  = slotState,
}

local function getMonsterById(id: string?): any?
	if not id or not lastMonsters then
		return nil
	end
	for _, m in lastMonsters do
		if m.id == id then
			return m
		end
	end
	return nil
end

local function getSelectedMonster(): any?
	return getMonsterById(selectedMonsterId)
end

local function setSlotSelected(selected: boolean)
	slotStroke.Transparency = if selected then 0 else 1
	slot.BackgroundColor3 = if selected
		then Color3.fromRGB(34, 48, 38)
		else Color3.fromRGB(28, 28, 42)
end

local function stopFatigueTick()
	if fatigueTickConn then
		fatigueTickConn:Disconnect()
		fatigueTickConn = nil
	end
end

local function hasFatiguedMonster(monsters: { any }?): boolean
	if not monsters then
		return false
	end
	for _, m in monsters do
		if m.state == "Fatigued" then
			return true
		end
	end
	return false
end

local function fatigueButtonSuffix(monster: any): string
	local left = MonsterDisplay.fatigueSecondsLeft(monster)
	if left == nil then
		return ""
	end
	return " · " .. left .. " сек"
end

local function renderDispatch()
	local hasMonster = MonsterDisplay.first(lastMonsters) ~= nil
	local selected = getSelectedMonster()

	if not hasMonster then
		dispatchBtn.Active           = false
		dispatchBtn.AutoButtonColor  = false
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		dispatchBtn.TextColor3       = Color3.fromRGB(120, 120, 140)
		dispatchBtn.Text             = "Нет монстров"
	elseif not selected then
		dispatchBtn.Active           = false
		dispatchBtn.AutoButtonColor  = false
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		dispatchBtn.TextColor3       = Color3.fromRGB(120, 120, 140)
		dispatchBtn.Text             = "Выберите монстра для отправки"
	elseif selected.state == "Idle" then
		dispatchBtn.Active           = true
		dispatchBtn.AutoButtonColor  = true
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
		dispatchBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		dispatchBtn.Text             = "Отправить 🐸"
	elseif selected.state == "OnMission" then
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
		dispatchBtn.Text             = "Отдыхает 💤" .. fatigueButtonSuffix(selected)
	end
end

local function refreshFatigueLabels()
	local monster = MonsterDisplay.first(lastMonsters)
	if monster then
		MonsterDisplay.fill(monsterLabels, monster)
	end
	renderDispatch()
end

local function startFatigueTickIfNeeded()
	stopFatigueTick()
	if not overlay.Visible or not hasFatiguedMonster(lastMonsters) then
		return
	end

	local elapsed = 0
	fatigueTickConn = RunService.Heartbeat:Connect(function(dt)
		if not overlay.Visible then
			stopFatigueTick()
			return
		end
		elapsed += dt
		if elapsed < 1 then
			return
		end
		elapsed = 0
		refreshFatigueLabels()
		if not hasFatiguedMonster(lastMonsters) then
			stopFatigueTick()
		end
	end)
end

local function render(monsters: { any }?)
	lastMonsters = monsters
	if selectedMonsterId and not getMonsterById(selectedMonsterId) then
		selectedMonsterId = nil
	end
	local monster = MonsterDisplay.first(monsters)
	if MonsterDisplay.fill(monsterLabels, monster) then
		slot.Visible       = true
		emptyLabel.Visible = false
	else
		slot.Visible       = false
		emptyLabel.Visible = true
		selectedMonsterId  = nil
	end
	setSlotSelected(selectedMonsterId ~= nil)
	dispatchBtn.Visible = true
	renderDispatch()
	startFatigueTickIfNeeded()
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
		selectedMonsterId   = nil
		stopFatigueTick()
	else
		startFatigueTickIfNeeded()
	end
end

slot.MouseButton1Click:Connect(function()
	local monster = MonsterDisplay.first(lastMonsters)
	if not monster then
		return
	end
	selectedMonsterId = monster.id
	setSlotSelected(true)
	renderDispatch()
end)

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

		local result = fnDispatch:InvokeServer({ targetBaseId = tgtId, monsterId = selectedMonsterId })
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
	selectedMonsterId = nil
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

evMonsterUpdated.OnClientEvent:Connect(function(payload: { monsters: { any }? })
	if not payload.monsters then
		return
	end
	lastMonsters = payload.monsters
	if overlay.Visible and not picker.Visible then
		render(payload.monsters)
	end
end)

return nil

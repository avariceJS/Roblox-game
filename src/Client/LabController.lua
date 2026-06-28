local Players                = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService             = game:GetService("RunService")
local TweenService           = game:GetService("TweenService")
local MarketplaceService     = game:GetService("MarketplaceService")

local UiUtil         = require(script.Parent.UiUtil)
local MonsterDisplay = require(game.ReplicatedStorage.src.Shared.MonsterDisplay)
local MonsterDefs    = require(game.ReplicatedStorage.src.Shared.MonsterDefs)
local BaseUtil       = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local localPlayer = Players.LocalPlayer
local src     = game.ReplicatedStorage:WaitForChild("src")
local Remotes = src:WaitForChild("Remotes")
local fnGetData           = Remotes:WaitForChild("GetPlayerData")    :: RemoteFunction
local fnDispatch          = Remotes:WaitForChild("DispatchMonster")  :: RemoteFunction
local fnSetTrap           = Remotes:WaitForChild("SetTrap")          :: RemoteFunction
local fnSetRansom         = Remotes:WaitForChild("SetRansom")        :: RemoteFunction
local fnPayRansom         = Remotes:WaitForChild("PayRansom")        :: RemoteFunction
local fnAttemptJailBreak  = Remotes:WaitForChild("AttemptJailBreak") :: RemoteFunction
local fnAttemptSubjugate  = Remotes:WaitForChild("AttemptSubjugate")   :: RemoteFunction
local fnSetPurchaseIntent = Remotes:WaitForChild("SetPurchaseIntent")  :: RemoteFunction
local evMonsterUpdated    = Remotes:WaitForChild("MonsterUpdated")     :: RemoteEvent

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
panel.Size                   = UDim2.new(0, 360, 0, 590)
panel.Position               = UDim2.new(0.5, -180, 0.5, -295)
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

local monsterListFrame = Instance.new("ScrollingFrame")
monsterListFrame.Size                   = UDim2.new(1, -32, 0, 160)
monsterListFrame.Position               = UDim2.new(0, 16, 0, 68)
monsterListFrame.BackgroundTransparency = 1
monsterListFrame.BorderSizePixel        = 0
monsterListFrame.ScrollBarThickness     = 4
monsterListFrame.ScrollBarImageColor3   = Color3.fromRGB(80, 100, 140)
monsterListFrame.CanvasSize             = UDim2.new(0, 0, 0, 0)
monsterListFrame.ScrollingDirection     = Enum.ScrollingDirection.Y
monsterListFrame.Visible                = false
monsterListFrame.Parent                 = panel

local monsterListLayout = Instance.new("UIListLayout")
monsterListLayout.FillDirection = Enum.FillDirection.Vertical
monsterListLayout.Padding       = UDim.new(0, 4)
monsterListLayout.SortOrder     = Enum.SortOrder.LayoutOrder
monsterListLayout.Parent        = monsterListFrame

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size                   = UDim2.new(1, -32, 0, 60)
emptyLabel.Position               = UDim2.new(0, 16, 0, 68)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text                   = "Монстров пока нет"
emptyLabel.TextColor3             = Color3.fromRGB(120, 120, 140)
emptyLabel.TextScaled             = true
emptyLabel.Font                   = Enum.Font.Gotham
emptyLabel.Visible                = false
emptyLabel.Parent                 = panel

local dispatchBtn = Instance.new("TextButton")
dispatchBtn.Size                   = UDim2.new(1, -32, 0, 52)
dispatchBtn.Position               = UDim2.new(0, 16, 1, -66)
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

local robuxRansomBtn = Instance.new("TextButton")
robuxRansomBtn.Size                   = UDim2.new(1, -32, 0, 48)
robuxRansomBtn.Position               = UDim2.new(0, 16, 1, -124)
robuxRansomBtn.BackgroundColor3       = Color3.fromRGB(90, 35, 130)
robuxRansomBtn.BackgroundTransparency = 0.15
robuxRansomBtn.BorderSizePixel        = 0
robuxRansomBtn.Text                   = "💎 Выкупить за Robux"
robuxRansomBtn.TextColor3             = Color3.fromRGB(210, 160, 255)
robuxRansomBtn.TextScaled             = true
robuxRansomBtn.Font                   = Enum.Font.GothamBold
robuxRansomBtn.AutoButtonColor        = true
robuxRansomBtn.Visible                = false
robuxRansomBtn.Parent                 = panel
UiUtil.corner(robuxRansomBtn, 10)

local defenseSection = Instance.new("Frame")
defenseSection.Size                   = UDim2.new(1, -32, 0, 212)
defenseSection.Position               = UDim2.new(0, 16, 0, 242)
defenseSection.BackgroundTransparency = 1
defenseSection.BorderSizePixel        = 0
defenseSection.Parent                 = panel

local cageBtn = Instance.new("TextButton")
cageBtn.Size                   = UDim2.new(1, 0, 0, 44)
cageBtn.BackgroundColor3       = Color3.fromRGB(50, 50, 70)
cageBtn.BackgroundTransparency = 0.15
cageBtn.BorderSizePixel        = 0
cageBtn.Text                   = "🔒 Клетка: выкл"
cageBtn.TextColor3             = Color3.fromRGB(160, 160, 180)
cageBtn.TextScaled             = true
cageBtn.Font                   = Enum.Font.GothamBold
cageBtn.AutoButtonColor        = true
cageBtn.Parent                 = defenseSection
UiUtil.corner(cageBtn, 10)

local jailFrame = Instance.new("Frame")
jailFrame.Size                   = UDim2.new(1, 0, 0, 160)
jailFrame.Position               = UDim2.new(0, 0, 0, 52)
jailFrame.BackgroundColor3       = Color3.fromRGB(22, 14, 14)
jailFrame.BackgroundTransparency = 0.2
jailFrame.BorderSizePixel        = 0
jailFrame.Parent                 = defenseSection
UiUtil.corner(jailFrame, 8)

local jailTitle = Instance.new("TextLabel")
jailTitle.Size                   = UDim2.new(1, -12, 0, 26)
jailTitle.Position               = UDim2.new(0, 8, 0, 6)
jailTitle.BackgroundTransparency = 1
jailTitle.Text                   = "🔒 Клетка нарушителей"
jailTitle.TextColor3             = Color3.fromRGB(200, 140, 80)
jailTitle.TextScaled             = true
jailTitle.Font                   = Enum.Font.GothamBold
jailTitle.TextXAlignment         = Enum.TextXAlignment.Left
jailTitle.Parent                 = jailFrame

local jailCaptureStroke = Instance.new("UIStroke")
jailCaptureStroke.Thickness    = 3
jailCaptureStroke.Color        = Color3.fromRGB(255, 80, 40)
jailCaptureStroke.Transparency = 1
jailCaptureStroke.Parent       = jailFrame

local MAX_JAIL_SLOTS = 3
local jailSlots: { TextButton } = {}

for i = 1, MAX_JAIL_SLOTS do
	local btn = Instance.new("TextButton")
	btn.Size                   = UDim2.new(1, -16, 0, 36)
	btn.Position               = UDim2.new(0, 8, 0, 36 + (i - 1) * 42)
	btn.BackgroundColor3       = Color3.fromRGB(35, 18, 18)
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel        = 0
	btn.Text                   = ""
	btn.TextColor3             = Color3.fromRGB(200, 160, 80)
	btn.TextScaled             = true
	btn.Font                   = Enum.Font.Gotham
	btn.TextXAlignment         = Enum.TextXAlignment.Left
	btn.AutoButtonColor        = true
	btn.Visible                = false
	btn.Parent                 = jailFrame
	UiUtil.corner(btn, 6)
	jailSlots[i] = btn
end

local picker = Instance.new("Frame")
picker.Size                   = UDim2.new(1, -32, 0, 460)
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

local MAX_PICKER_BTNS = 7
local pickerBtns: { TextButton } = {}
local pickerBtnIds: { [number]: number } = {}

for i = 1, MAX_PICKER_BTNS do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local btn = Instance.new("TextButton")
	btn.Size                   = UDim2.new(0.5, -6, 0, 56)
	btn.Position               = UDim2.new(col * 0.5, col == 0 and 4 or 2, 0, 54 + row * 64)
	btn.BackgroundColor3       = Color3.fromRGB(35, 45, 65)
	btn.BackgroundTransparency = 0.1
	btn.BorderSizePixel        = 0
	btn.Text                   = ""
	btn.TextColor3             = Color3.fromRGB(200, 220, 255)
	btn.TextScaled             = true
	btn.Font                   = Enum.Font.GothamBold
	btn.Visible                = false
	btn.Parent                 = picker
	UiUtil.corner(btn, 8)
	pickerBtns[i] = btn
	pickerBtnIds[i] = -1
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

local pickerEmpty = Instance.new("TextLabel")
pickerEmpty.Size                   = UDim2.new(1, -16, 0, 36)
pickerEmpty.Position               = UDim2.new(0, 8, 0, 54)
pickerEmpty.BackgroundTransparency = 1
pickerEmpty.Text                   = "Нет доступных целей"
pickerEmpty.TextColor3             = Color3.fromRGB(120, 120, 140)
pickerEmpty.TextScaled             = true
pickerEmpty.Font                   = Enum.Font.Gotham
pickerEmpty.Visible                = false
pickerEmpty.Parent                 = picker

local ransomPanel = Instance.new("Frame")
ransomPanel.Size                   = UDim2.fromScale(1, 1)
ransomPanel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
ransomPanel.BackgroundTransparency = 0.35
ransomPanel.BorderSizePixel        = 0
ransomPanel.ZIndex                 = 8
ransomPanel.Visible                = false
ransomPanel.Parent                 = panel
UiUtil.corner(ransomPanel, 14)

local ransomCard = Instance.new("Frame")
ransomCard.Size                   = UDim2.new(0.82, 0, 0, 356)
ransomCard.Position               = UDim2.new(0.09, 0, 0.5, -178)
ransomCard.BackgroundColor3       = Color3.fromRGB(28, 16, 10)
ransomCard.BackgroundTransparency = 0.05
ransomCard.BorderSizePixel        = 0
ransomCard.ZIndex                 = 9
ransomCard.Parent                 = ransomPanel
UiUtil.corner(ransomCard, 12)

local ransomTitle = Instance.new("TextLabel")
ransomTitle.Size                   = UDim2.new(1, -16, 0, 36)
ransomTitle.Position               = UDim2.new(0, 8, 0, 10)
ransomTitle.BackgroundTransparency = 1
ransomTitle.Text                   = "Задать выкуп"
ransomTitle.TextColor3             = Color3.fromRGB(255, 200, 80)
ransomTitle.TextScaled             = true
ransomTitle.Font                   = Enum.Font.GothamBold
ransomTitle.ZIndex                 = 10
ransomTitle.Parent                 = ransomCard

local ransomInfo = Instance.new("TextLabel")
ransomInfo.Size                   = UDim2.new(1, -16, 0, 28)
ransomInfo.Position               = UDim2.new(0, 8, 0, 50)
ransomInfo.BackgroundTransparency = 1
ransomInfo.Text                   = ""
ransomInfo.TextColor3             = Color3.fromRGB(200, 180, 160)
ransomInfo.TextScaled             = true
ransomInfo.Font                   = Enum.Font.Gotham
ransomInfo.ZIndex                 = 10
ransomInfo.Parent                 = ransomCard

local RANSOM_PRESETS = { 25, 50, 100, 200 }
local ransomPriceBtns: { TextButton } = {}

for i, price in RANSOM_PRESETS do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local btn = Instance.new("TextButton")
	btn.Size                   = UDim2.new(0.5, col == 0 and -6 or -4, 0, 44)
	btn.Position               = UDim2.new(col * 0.5, col == 0 and 8 or -2, 0, 88 + row * 52)
	btn.BackgroundColor3       = Color3.fromRGB(80, 50, 20)
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel        = 0
	btn.Text                   = "💰 " .. price
	btn.TextColor3             = Color3.fromRGB(255, 200, 80)
	btn.TextScaled             = true
	btn.Font                   = Enum.Font.GothamBold
	btn.AutoButtonColor        = true
	btn.ZIndex                 = 10
	btn.Parent                 = ransomCard
	UiUtil.corner(btn, 8)
	ransomPriceBtns[i] = btn
end

local subjugateBtn = Instance.new("TextButton")
subjugateBtn.Size                   = UDim2.new(1, -16, 0, 44)
subjugateBtn.Position               = UDim2.new(0, 8, 0, 200)
subjugateBtn.BackgroundColor3       = Color3.fromRGB(60, 20, 80)
subjugateBtn.BackgroundTransparency = 0.15
subjugateBtn.BorderSizePixel        = 0
subjugateBtn.Text                   = "😈 Подчинить (50%)"
subjugateBtn.TextColor3             = Color3.fromRGB(200, 140, 255)
subjugateBtn.TextScaled             = true
subjugateBtn.Font                   = Enum.Font.GothamBold
subjugateBtn.AutoButtonColor        = true
subjugateBtn.ZIndex                 = 10
subjugateBtn.Parent                 = ransomCard
UiUtil.corner(subjugateBtn, 8)

local robuxSubjugateBtn = Instance.new("TextButton")
robuxSubjugateBtn.Size                   = UDim2.new(1, -16, 0, 44)
robuxSubjugateBtn.Position               = UDim2.new(0, 8, 0, 252)
robuxSubjugateBtn.BackgroundColor3       = Color3.fromRGB(80, 20, 110)
robuxSubjugateBtn.BackgroundTransparency = 0.15
robuxSubjugateBtn.BorderSizePixel        = 0
robuxSubjugateBtn.Text                   = "💎 Подчинить гарантированно"
robuxSubjugateBtn.TextColor3             = Color3.fromRGB(210, 160, 255)
robuxSubjugateBtn.TextScaled             = true
robuxSubjugateBtn.Font                   = Enum.Font.GothamBold
robuxSubjugateBtn.AutoButtonColor        = true
robuxSubjugateBtn.ZIndex                 = 10
robuxSubjugateBtn.Parent                 = ransomCard
UiUtil.corner(robuxSubjugateBtn, 8)

local ransomCancel = Instance.new("TextButton")
ransomCancel.Size                   = UDim2.new(1, -16, 0, 36)
ransomCancel.Position               = UDim2.new(0, 8, 0, 304)
ransomCancel.BackgroundColor3       = Color3.fromRGB(50, 30, 30)
ransomCancel.BackgroundTransparency = 0.2
ransomCancel.BorderSizePixel        = 0
ransomCancel.Text                   = "Отмена"
ransomCancel.TextColor3             = Color3.fromRGB(255, 120, 120)
ransomCancel.TextScaled             = true
ransomCancel.Font                   = Enum.Font.GothamBold
ransomCancel.AutoButtonColor        = true
ransomCancel.ZIndex                 = 10
ransomCancel.Parent                 = ransomCard
UiUtil.corner(ransomCancel, 8)

local showToast = UiUtil.makeToast(gui, UDim2.new(0.5, -200, 0, 72), 400)

local playerBaseId:      number? = nil
local lastMonsters:      { any }? = nil
local lastTargets:       { any }  = {}
local selectedMonsterId: string?  = nil
local hasCage:    boolean = false
local jailData:   { any } = {}
local selectedJailIdx: number = 0
local tickConn: RBXScriptConnection? = nil
local tickElapsed = 0

local activeSlotFrames: { Frame } = {}

local function stopTick()
	if tickConn then tickConn:Disconnect(); tickConn = nil end
	tickElapsed = 0
end

local function hasFatiguedMonster(monsters: { any }?): boolean
	if not monsters then return false end
	for _, m in monsters do
		if m.state == "Fatigued" then return true end
	end
	return false
end

local function fatigueButtonSuffix(monster: any): string
	local left = MonsterDisplay.fatigueSecondsLeft(monster)
	if left == nil then return "" end
	return " · " .. left .. " сек"
end

local function getMonsterById(id: string?): any?
	if not id or not lastMonsters then return nil end
	for _, m in lastMonsters do
		if m.id == id then return m end
	end
	return nil
end

local function getSelectedMonster(): any?
	return getMonsterById(selectedMonsterId)
end

local function getMonsterIcon(monster: any): string
	local def = MonsterDefs[monster.type or "Slime"]
	return (def and def.icon) or "🐸"
end

local function updateCageButton(active: boolean)
	hasCage = active
	if active then
		cageBtn.Text             = "🔒 Клетка: вкл"
		cageBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 40)
		cageBtn.TextColor3       = Color3.fromRGB(100, 255, 120)
	else
		cageBtn.Text             = "🔒 Клетка: выкл"
		cageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		cageBtn.TextColor3       = Color3.fromRGB(160, 160, 180)
	end
end

local function updateJailSlots()
	for i = 1, MAX_JAIL_SLOTS do
		local entry = jailData[i]
		local btn = jailSlots[i]
		if entry then
			btn.Visible = true
			local priceStr = entry.ransomPrice and ("💰" .. entry.ransomPrice) or "нет цены"
			btn.Text = "⛓ " .. (entry.monsterName or "?") .. " (" .. (entry.ownerName or "?") .. ")  " .. priceStr
		else
			btn.Visible = false
		end
	end
end

local function flashJail()
	jailCaptureStroke.Transparency = 0
	TweenService:Create(
		jailCaptureStroke,
		TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 1 }
	):Play()
end

local function renderJail(jail: { any }?)
	jailData = jail or {}
	updateJailSlots()
end

local function renderDispatch()
	local hasMonster = lastMonsters and #lastMonsters > 0
	local selected = getSelectedMonster()
	robuxRansomBtn.Visible = selected ~= nil and selected.state == "Captured"

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
		dispatchBtn.Text             = "Отправить " .. getMonsterIcon(selected)
	elseif selected.state == "OnMission" then
		dispatchBtn.Active           = false
		dispatchBtn.AutoButtonColor  = false
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 20)
		dispatchBtn.TextColor3       = Color3.fromRGB(255, 200, 80)
		dispatchBtn.Text             = "На задании " .. getMonsterIcon(selected)
	elseif selected.state == "Captured" then
		local price = selected.ransomPrice
		if price and price > 0 then
			dispatchBtn.Active           = true
			dispatchBtn.AutoButtonColor  = true
			dispatchBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 20)
			dispatchBtn.TextColor3       = Color3.fromRGB(255, 210, 100)
			dispatchBtn.Text             = "Выкупить 💰 " .. price
		else
			dispatchBtn.Active           = false
			dispatchBtn.AutoButtonColor  = false
			dispatchBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
			dispatchBtn.TextColor3       = Color3.fromRGB(255, 100, 100)
			dispatchBtn.Text             = "Пойман ⛓️ · нет цены"
		end
	else
		dispatchBtn.Active           = false
		dispatchBtn.AutoButtonColor  = false
		dispatchBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
		dispatchBtn.TextColor3       = Color3.fromRGB(140, 140, 255)
		dispatchBtn.Text             = getMonsterIcon(selected) .. " Отдыхает 💤" .. fatigueButtonSuffix(selected)
	end
end

local function clearMonsterSlots()
	for _, f in activeSlotFrames do
		f:Destroy()
	end
	activeSlotFrames = {}
end

local render: (({ any }?) -> ())

local function makeMonsterSlot(monster: any): Frame
	local isSelected = selectedMonsterId == monster.id
	local frame = Instance.new("Frame")
	frame.Size                   = UDim2.new(1, 0, 0, 72)
	frame.BackgroundColor3       = if isSelected then Color3.fromRGB(34, 48, 38) else Color3.fromRGB(28, 28, 42)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel        = 0
	UiUtil.corner(frame, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color        = Color3.fromRGB(80, 220, 80)
	stroke.Thickness    = 2
	stroke.Transparency = if isSelected then 0 else 1
	stroke.Parent       = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size                   = UDim2.new(0, 54, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.TextScaled             = true
	iconLabel.Font                   = Enum.Font.GothamBold
	iconLabel.Parent                 = frame

	local infoFrame = Instance.new("Frame")
	infoFrame.Size                   = UDim2.new(1, -64, 1, -12)
	infoFrame.Position               = UDim2.new(0, 60, 0, 6)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent                 = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size                   = UDim2.new(1, 0, 0.36, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled             = true
	nameLabel.Font                   = Enum.Font.GothamBold
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
	nameLabel.Parent                 = infoFrame

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size                   = UDim2.new(1, 0, 0.28, 0)
	rarityLabel.Position               = UDim2.new(0, 0, 0.36, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.TextColor3             = Color3.fromRGB(160, 160, 160)
	rarityLabel.TextScaled             = true
	rarityLabel.Font                   = Enum.Font.Gotham
	rarityLabel.TextXAlignment         = Enum.TextXAlignment.Left
	rarityLabel.Parent                 = infoFrame

	local stateLabel = Instance.new("TextLabel")
	stateLabel.Size                   = UDim2.new(1, 0, 0.28, 0)
	stateLabel.Position               = UDim2.new(0, 0, 0.68, 0)
	stateLabel.BackgroundTransparency = 1
	stateLabel.TextScaled             = true
	stateLabel.Font                   = Enum.Font.Gotham
	stateLabel.TextXAlignment         = Enum.TextXAlignment.Left
	stateLabel.Parent                 = infoFrame

	MonsterDisplay.fill({
		icon   = iconLabel,
		name   = nameLabel,
		rarity = rarityLabel,
		state  = stateLabel,
	}, monster)

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size                   = UDim2.fromScale(1, 1)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text                   = ""
	clickBtn.ZIndex                 = 2
	clickBtn.Parent                 = frame

	local mId = monster.id
	clickBtn.MouseButton1Click:Connect(function()
		selectedMonsterId = mId
		render(lastMonsters)
	end)

	return frame
end

render = function(monsters: { any }?)
	lastMonsters = monsters

	if selectedMonsterId and not getMonsterById(selectedMonsterId) then
		selectedMonsterId = nil
	end

	clearMonsterSlots()

	if not monsters or #monsters == 0 then
		monsterListFrame.Visible = false
		emptyLabel.Visible       = true
		selectedMonsterId        = nil
	else
		monsterListFrame.Visible = true
		emptyLabel.Visible       = false

		local totalH = 0
		for _, monster in monsters do
			local frame = makeMonsterSlot(monster)
			frame.Parent = monsterListFrame
			table.insert(activeSlotFrames, frame)
			totalH += 76
		end
		monsterListFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
	end

	dispatchBtn.Visible = true
	renderDispatch()
end

local function startTickIfNeeded()
	stopTick()
	if not overlay.Visible then return end
	if not hasFatiguedMonster(lastMonsters) then return end
	tickElapsed = 0
	tickConn = RunService.Heartbeat:Connect(function(dt)
		if not overlay.Visible then stopTick(); return end
		tickElapsed += dt
		if tickElapsed < 1 then return end
		tickElapsed = 0
		render(lastMonsters)
		renderDispatch()
		if not hasFatiguedMonster(lastMonsters) then stopTick() end
	end)
end

local function setPickerVisible(visible: boolean)
	picker.Visible         = visible
	dispatchBtn.Visible    = not visible
	defenseSection.Visible = not visible
	if visible then
		robuxRansomBtn.Visible   = false
		monsterListFrame.Visible = false
		emptyLabel.Visible       = false
	else
		render(lastMonsters)
	end
end

local function closeRansomPanel()
	ransomPanel.Visible = false
	selectedJailIdx = 0
end

local function openRansomPanel(idx: number)
	local entry = jailData[idx]
	if not entry then return end
	selectedJailIdx = idx
	ransomInfo.Text = (entry.monsterName or "?") .. " игрока " .. (entry.ownerName or "?")
	ransomPanel.Visible = true
end

local function setOpen(isOpen: boolean)
	overlay.Visible = isOpen
	panel.Visible   = isOpen
	if not isOpen then
		picker.Visible         = false
		dispatchBtn.Visible    = true
		robuxRansomBtn.Visible = false
		defenseSection.Visible = true
		ransomPanel.Visible    = false
		selectedMonsterId      = nil
		selectedJailIdx        = 0
		stopTick()
	else
		defenseSection.Visible = true
		startTickIfNeeded()
	end
end

local function openPicker()
	closeRansomPanel()
	local hasAny = false
	for slotIdx = 1, MAX_PICKER_BTNS do
		local target = lastTargets[slotIdx]
		local btn    = pickerBtns[slotIdx]
		if target then
			hasAny                     = true
			pickerBtnIds[slotIdx]      = target.id
			btn.Text                   = target.label
			btn.Visible                = true
			btn.Active                 = true
			btn.AutoButtonColor        = true
			btn.BackgroundColor3       = if target.targetType == "npc"
				then Color3.fromRGB(80, 45, 20)
				else Color3.fromRGB(35, 45, 65)
			btn.BackgroundTransparency = 0.1
			btn.TextColor3             = Color3.fromRGB(200, 220, 255)
		else
			btn.Visible           = false
			pickerBtnIds[slotIdx] = -1
		end
	end
	pickerEmpty.Visible = not hasAny
	setPickerVisible(true)
end

for slotIdx = 1, MAX_PICKER_BTNS do
	local btn = pickerBtns[slotIdx]
	btn.MouseButton1Click:Connect(function()
		if not btn.Active then return end
		local tgtId = pickerBtnIds[slotIdx]
		if tgtId == -1 then return end
		setOpen(false)
		local result = fnDispatch:InvokeServer({ targetBaseId = tgtId, monsterId = selectedMonsterId })
		if result and result.ok then
			showToast("Монстр отправился! 🐸")
		else
			showToast((result and result.message) or "Ошибка отправки")
		end
	end)
end

pickerBack.MouseButton1Click:Connect(function()
	setPickerVisible(false)
end)

for i = 1, MAX_JAIL_SLOTS do
	local btn = jailSlots[i]
	local idx = i
	btn.MouseButton1Click:Connect(function()
		openRansomPanel(idx)
	end)
end

for i, price in RANSOM_PRESETS do
	local btn = ransomPriceBtns[i]
	local p = price
	btn.MouseButton1Click:Connect(function()
		if selectedJailIdx == 0 then return end
		local entry = jailData[selectedJailIdx]
		if not entry then return end
		local result = fnSetRansom:InvokeServer({ monsterId = entry.monsterId, price = p })
		closeRansomPanel()
		if not (result and result.ok) then
			showToast((result and result.message) or "Ошибка задания выкупа")
		end
	end)
end

subjugateBtn.MouseButton1Click:Connect(function()
	if selectedJailIdx == 0 then return end
	local entry = jailData[selectedJailIdx]
	if not entry then return end
	closeRansomPanel()
	local result = fnAttemptSubjugate:InvokeServer({ monsterId = entry.monsterId })
	if result and result.ok then
		showToast("Монстр подчинён! 😈")
	else
		showToast((result and result.message) or "Провал подчинения")
	end
end)

robuxRansomBtn.MouseButton1Click:Connect(function()
	local selected = getSelectedMonster()
	if not selected or selected.state ~= "Captured" then return end
	local result = fnSetPurchaseIntent:InvokeServer({ productKey = "instantRansom", monsterId = selected.id })
	if not (result and result.ok) then
		showToast((result and result.message) or "Ошибка")
		return
	end
	if result.immediate then return end
	MarketplaceService:PromptProductPurchase(localPlayer, result.productId)
end)

robuxSubjugateBtn.MouseButton1Click:Connect(function()
	if selectedJailIdx == 0 then return end
	local entry = jailData[selectedJailIdx]
	if not entry then return end
	local result = fnSetPurchaseIntent:InvokeServer({ productKey = "forceSubjugate", monsterId = entry.monsterId })
	closeRansomPanel()
	if not (result and result.ok) then
		showToast((result and result.message) or "Ошибка")
		return
	end
	if result.immediate then return end
	MarketplaceService:PromptProductPurchase(localPlayer, result.productId)
end)

ransomCancel.MouseButton1Click:Connect(closeRansomPanel)

cageBtn.MouseButton1Click:Connect(function()
	local result = fnSetTrap:InvokeServer({ active = not hasCage })
	if not result or not result.ok then
		showToast((result and result.message) or "Ошибка активации ловушки")
	end
end)

dispatchBtn.MouseButton1Click:Connect(function()
	if not dispatchBtn.Active then return end
	local selected = getSelectedMonster()
	if selected and selected.state == "Captured" then
		local result = fnPayRansom:InvokeServer({ monsterId = selected.id })
		if result and result.ok then
			showToast("Монстр выкуплен! 🐸")
		else
			showToast((result and result.message) or "Ошибка выкупа")
		end
	else
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

	playerBaseId      = myId
	lastTargets       = data.targets or {}
	selectedMonsterId = nil
	updateCageButton(data.hasCage == true)
	renderJail(data.jail)
	render(data.monsters)
	setOpen(true)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if player ~= localPlayer then return end
	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if not model then return end
	if prompt.Name == "LabPrompt" then
		openLab(model:GetAttribute("BaseId"))
	elseif prompt.Name == "JailPrompt" then
		local targetBaseId = BaseUtil.normalizeId(model:GetAttribute("BaseId"))
		local result = fnAttemptJailBreak:InvokeServer({ targetBaseId = targetBaseId })
		if result and result.ok then
			showToast("Монстр освобождён! 🔓")
		else
			showToast((result and result.message) or "Ошибка влома")
		end
	end
end)

evMonsterUpdated.OnClientEvent:Connect(function(payload)
	if payload.hasCage ~= nil then
		updateCageButton(payload.hasCage == true)
	end
	if payload.jail then
		local prevCount = #jailData
		renderJail(payload.jail)
		if #payload.jail > prevCount and overlay.Visible then
			flashJail()
		end
	end
	if payload.monsters then
		lastMonsters = payload.monsters
		if overlay.Visible and not picker.Visible then
			render(payload.monsters)
		end
	end
end)

return nil

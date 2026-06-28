local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local UiUtil         = require(script.Parent.UiUtil)
local MonsterDisplay = require(game.ReplicatedStorage.src.Shared.MonsterDisplay)
local BaseUtil       = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local localPlayer = Players.LocalPlayer
local src     = game.ReplicatedStorage:WaitForChild("src")
local Remotes = src:WaitForChild("Remotes")
local fnGetData        = Remotes:WaitForChild("GetPlayerData")   :: RemoteFunction
local fnDispatch       = Remotes:WaitForChild("DispatchMonster") :: RemoteFunction
local fnSetTrap        = Remotes:WaitForChild("SetTrap")         :: RemoteFunction
local fnSetRansom      = Remotes:WaitForChild("SetRansom")       :: RemoteFunction
local fnPayRansom      = Remotes:WaitForChild("PayRansom")       :: RemoteFunction
local fnBuyMonster     = Remotes:WaitForChild("BuyMonster")      :: RemoteFunction
local fnDoQuest        = Remotes:WaitForChild("DoQuest")         :: RemoteFunction
local evMonsterUpdated = Remotes:WaitForChild("MonsterUpdated")  :: RemoteEvent

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
panel.Size                   = UDim2.new(0, 360, 0, 600)
panel.Position               = UDim2.new(0.5, -180, 0.5, -300)
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
slotStroke.Color        = Color3.fromRGB(80, 220, 80)
slotStroke.Thickness    = 2
slotStroke.Transparency = 1
slotStroke.Parent       = slot

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

local defenseSection = Instance.new("Frame")
defenseSection.Size                   = UDim2.new(1, -32, 0, 212)
defenseSection.Position               = UDim2.new(0, 16, 0, 192)
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

local shopSection = Instance.new("Frame")
shopSection.Size                   = UDim2.new(1, -32, 0, 64)
shopSection.Position               = UDim2.new(0, 16, 0, 412)
shopSection.BackgroundTransparency = 1
shopSection.BorderSizePixel        = 0
shopSection.Parent                 = panel

local shopTitle = Instance.new("TextLabel")
shopTitle.Size                   = UDim2.new(1, 0, 0, 18)
shopTitle.BackgroundTransparency = 1
shopTitle.Text                   = "🏪 Магазин монстров"
shopTitle.TextColor3             = Color3.fromRGB(180, 210, 255)
shopTitle.TextScaled             = true
shopTitle.Font                   = Enum.Font.GothamBold
shopTitle.TextXAlignment         = Enum.TextXAlignment.Left
shopTitle.Parent                 = shopSection

local buySlimeBtn = Instance.new("TextButton")
buySlimeBtn.Size                   = UDim2.new(1, 0, 0, 40)
buySlimeBtn.Position               = UDim2.new(0, 0, 0, 22)
buySlimeBtn.BackgroundColor3       = Color3.fromRGB(30, 60, 90)
buySlimeBtn.BackgroundTransparency = 0.15
buySlimeBtn.BorderSizePixel        = 0
buySlimeBtn.Text                   = "🐸 Гуппи (Слизень) — 50💰"
buySlimeBtn.TextColor3             = Color3.fromRGB(180, 220, 255)
buySlimeBtn.TextScaled             = true
buySlimeBtn.Font                   = Enum.Font.GothamBold
buySlimeBtn.AutoButtonColor        = true
buySlimeBtn.Parent                 = shopSection
UiUtil.corner(buySlimeBtn, 8)

local questBtn = Instance.new("TextButton")
questBtn.Size                   = UDim2.new(1, -32, 0, 44)
questBtn.Position               = UDim2.new(0, 16, 0, 484)
questBtn.BackgroundColor3       = Color3.fromRGB(60, 40, 20)
questBtn.BackgroundTransparency = 0.15
questBtn.BorderSizePixel        = 0
questBtn.Text                   = "💼 Мелкая работа  +25💰"
questBtn.TextColor3             = Color3.fromRGB(255, 200, 80)
questBtn.TextScaled             = true
questBtn.Font                   = Enum.Font.GothamBold
questBtn.AutoButtonColor        = true
questBtn.Active                 = true
questBtn.Parent                 = panel
UiUtil.corner(questBtn, 10)

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
ransomCard.Size                   = UDim2.new(0.82, 0, 0, 250)
ransomCard.Position               = UDim2.new(0.09, 0, 0.5, -125)
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

local ransomCancel = Instance.new("TextButton")
ransomCancel.Size                   = UDim2.new(1, -16, 0, 36)
ransomCancel.Position               = UDim2.new(0, 8, 0, 200)
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

local playerBaseId:       number?  = nil
local lastMonsters:      { any }?  = nil
local lastTargets:        { any }  = {}
local selectedMonsterId:  string?  = nil
local hasCage:  boolean = false
local jailData: { any } = {}
local nextQuestAt: number = 0
local selectedJailIdx: number = 0
local tickConn: RBXScriptConnection? = nil
local tickElapsed = 0

local monsterLabels = {
	icon   = slotIcon,
	name   = slotName,
	rarity = slotRarity,
	state  = slotState,
}

local function stopTick()
	if tickConn then
		tickConn:Disconnect()
		tickConn = nil
	end
	tickElapsed = 0
end

local function hasFatiguedMonster(monsters: { any }?): boolean
	if not monsters then return false end
	for _, m in monsters do
		if m.state == "Fatigued" then return true end
	end
	return false
end

local function needsTick(): boolean
	if hasFatiguedMonster(lastMonsters) then return true end
	if nextQuestAt > 0 and os.time() < nextQuestAt then return true end
	return false
end

local function updateQuestBtn()
	local now = os.time()
	if nextQuestAt <= now then
		questBtn.Active           = true
		questBtn.AutoButtonColor  = true
		questBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
		questBtn.TextColor3       = Color3.fromRGB(255, 200, 80)
		questBtn.Text             = "💼 Мелкая работа  +25💰"
	else
		local left = nextQuestAt - now
		questBtn.Active           = false
		questBtn.AutoButtonColor  = false
		questBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		questBtn.TextColor3       = Color3.fromRGB(120, 120, 140)
		questBtn.Text             = "💼 Перезарядка... " .. left .. " сек"
	end
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

local function setSlotSelected(selected: boolean)
	slotStroke.Transparency = if selected then 0 else 1
	slot.BackgroundColor3 = if selected
		then Color3.fromRGB(34, 48, 38)
		else Color3.fromRGB(28, 28, 42)
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
		dispatchBtn.Text             = "Отдыхает 💤" .. fatigueButtonSuffix(selected)
	end
end

local function refreshTimedLabels()
	local monster = MonsterDisplay.first(lastMonsters)
	if monster then
		MonsterDisplay.fill(monsterLabels, monster)
	end
	renderDispatch()
	updateQuestBtn()
end

local function startTickIfNeeded()
	stopTick()
	if not overlay.Visible or not needsTick() then return end
	tickElapsed = 0
	tickConn = RunService.Heartbeat:Connect(function(dt)
		if not overlay.Visible then stopTick(); return end
		tickElapsed += dt
		if tickElapsed < 1 then return end
		tickElapsed = 0
		refreshTimedLabels()
		if not needsTick() then stopTick() end
	end)
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

local function renderJail(jail: { any }?)
	jailData = jail or {}
	updateJailSlots()
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
	startTickIfNeeded()
end

local function setPickerVisible(visible: boolean)
	picker.Visible         = visible
	dispatchBtn.Visible    = not visible
	defenseSection.Visible = not visible
	shopSection.Visible    = not visible
	questBtn.Visible       = not visible
	if visible then
		slot.Visible       = false
		emptyLabel.Visible = false
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
		defenseSection.Visible = true
		shopSection.Visible    = true
		questBtn.Visible       = true
		ransomPanel.Visible    = false
		selectedMonsterId      = nil
		selectedJailIdx        = 0
		stopTick()
	else
		defenseSection.Visible = true
		shopSection.Visible    = true
		questBtn.Visible       = true
		startTickIfNeeded()
	end
end

slot.MouseButton1Click:Connect(function()
	local monster = MonsterDisplay.first(lastMonsters)
	if not monster then return end
	selectedMonsterId = monster.id
	setSlotSelected(true)
	renderDispatch()
end)

local function openPicker()
	for slotIdx = 1, MAX_PICKER_BTNS do
		local target = lastTargets[slotIdx]
		local btn    = pickerBtns[slotIdx]
		if target then
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
			btn.Visible        = false
			pickerBtnIds[slotIdx] = -1
		end
	end
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
			showToast("Гуппи отправился! 🐸")
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

buySlimeBtn.MouseButton1Click:Connect(function()
	local result = fnBuyMonster:InvokeServer({ monsterType = "Slime" })
	if result and result.ok then
		showToast("Купил нового Гуппи! 🐸")
	else
		showToast((result and result.message) or "Ошибка покупки")
	end
end)

questBtn.MouseButton1Click:Connect(function()
	if not questBtn.Active then return end
	local result = fnDoQuest:InvokeServer()
	if not (result and result.ok) then
		showToast((result and result.message) or "Ошибка квеста")
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
	nextQuestAt       = data.nextQuestAt or 0
	selectedMonsterId = nil
	updateCageButton(data.hasCage == true)
	renderJail(data.jail)
	updateQuestBtn()
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

evMonsterUpdated.OnClientEvent:Connect(function(payload)
	if payload.hasCage ~= nil then
		updateCageButton(payload.hasCage == true)
	end
	if payload.jail then
		renderJail(payload.jail)
	end
	if payload.monsters then
		lastMonsters = payload.monsters
		if overlay.Visible and not picker.Visible then
			render(payload.monsters)
		end
	end
	if payload.nextQuestAt ~= nil then
		nextQuestAt = payload.nextQuestAt
		updateQuestBtn()
		startTickIfNeeded()
	end
end)

return nil

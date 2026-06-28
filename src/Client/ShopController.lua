local Players                = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService             = game:GetService("RunService")

local UiUtil   = require(script.Parent.UiUtil)
local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local localPlayer = Players.LocalPlayer
local src     = game.ReplicatedStorage:WaitForChild("src")
local Remotes = src:WaitForChild("Remotes")

local fnGetData        = Remotes:WaitForChild("GetPlayerData")  :: RemoteFunction
local fnBuyMonster     = Remotes:WaitForChild("BuyMonster")     :: RemoteFunction
local fnDoQuest        = Remotes:WaitForChild("DoQuest")        :: RemoteFunction
local fnBuyUpgrade     = Remotes:WaitForChild("BuyUpgrade")     :: RemoteFunction
local evMonsterUpdated = Remotes:WaitForChild("MonsterUpdated") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name           = "ShopHUD"
gui.ResetOnSpawn   = false
gui.DisplayOrder   = 51
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
panel.Size                   = UDim2.new(0, 360, 0, 540)
panel.Position               = UDim2.new(0.5, -180, 0.5, -270)
panel.BackgroundColor3       = Color3.fromRGB(18, 18, 28)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel        = 0
panel.Parent                 = overlay
UiUtil.corner(panel, 14)

local header = Instance.new("TextLabel")
header.Size                   = UDim2.new(1, -50, 0, 44)
header.Position               = UDim2.new(0, 16, 0, 10)
header.BackgroundTransparency = 1
header.Text                   = "🏪 Магазин монстров"
header.TextColor3             = Color3.fromRGB(255, 230, 180)
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

local monstersLabel = Instance.new("TextLabel")
monstersLabel.Size                   = UDim2.new(1, -32, 0, 22)
monstersLabel.Position               = UDim2.new(0, 16, 0, 66)
monstersLabel.BackgroundTransparency = 1
monstersLabel.Text                   = "Монстры"
monstersLabel.TextColor3             = Color3.fromRGB(180, 210, 255)
monstersLabel.TextScaled             = true
monstersLabel.Font                   = Enum.Font.GothamBold
monstersLabel.TextXAlignment         = Enum.TextXAlignment.Left
monstersLabel.Parent                 = panel

local MONSTER_DEFS = {
	{ type = "Slime",     label = "🐸 Гуппи (Слизень)",   price = 50,  color = Color3.fromRGB(30, 60, 90) },
	{ type = "Gremlin",   label = "👺 Гремлин",            price = 100, color = Color3.fromRGB(50, 30, 60) },
	{ type = "ShadowRat", label = "🐀 Теневая Крыса",     price = 150, color = Color3.fromRGB(20, 40, 40) },
	{ type = "Homunculus",label = "🧿 Гомункул",           price = 250, color = Color3.fromRGB(40, 10, 50) },
}

local monsterBtns: { TextButton } = {}
for i, def in MONSTER_DEFS do
	local btn = Instance.new("TextButton")
	btn.Size                   = UDim2.new(1, -32, 0, 44)
	btn.Position               = UDim2.new(0, 16, 0, 94 + (i - 1) * 52)
	btn.BackgroundColor3       = def.color
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel        = 0
	btn.Text                   = def.label .. " — " .. def.price .. "💰"
	btn.TextColor3             = Color3.fromRGB(180, 220, 255)
	btn.TextScaled             = true
	btn.Font                   = Enum.Font.GothamBold
	btn.AutoButtonColor        = true
	btn.Parent                 = panel
	UiUtil.corner(btn, 8)
	monsterBtns[i] = btn
end

local yAfterMonsters = 94 + #MONSTER_DEFS * 52 + 8

local divider2 = Instance.new("Frame")
divider2.Size             = UDim2.new(1, -32, 0, 1)
divider2.Position         = UDim2.new(0, 16, 0, yAfterMonsters)
divider2.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
divider2.BorderSizePixel  = 0
divider2.Parent           = panel

local contractsLabel = Instance.new("TextLabel")
contractsLabel.Size                   = UDim2.new(1, -32, 0, 22)
contractsLabel.Position               = UDim2.new(0, 16, 0, yAfterMonsters + 8)
contractsLabel.BackgroundTransparency = 1
contractsLabel.Text                   = "Контракты"
contractsLabel.TextColor3             = Color3.fromRGB(180, 210, 255)
contractsLabel.TextScaled             = true
contractsLabel.Font                   = Enum.Font.GothamBold
contractsLabel.TextXAlignment         = Enum.TextXAlignment.Left
contractsLabel.Parent                 = panel

local questBtn = Instance.new("TextButton")
questBtn.Size                   = UDim2.new(1, -32, 0, 44)
questBtn.Position               = UDim2.new(0, 16, 0, yAfterMonsters + 36)
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

local yAfterQuest = yAfterMonsters + 36 + 52

local divider3 = Instance.new("Frame")
divider3.Size             = UDim2.new(1, -32, 0, 1)
divider3.Position         = UDim2.new(0, 16, 0, yAfterQuest)
divider3.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
divider3.BorderSizePixel  = 0
divider3.Parent           = panel

local upgradesLabel = Instance.new("TextLabel")
upgradesLabel.Size                   = UDim2.new(1, -32, 0, 22)
upgradesLabel.Position               = UDim2.new(0, 16, 0, yAfterQuest + 8)
upgradesLabel.BackgroundTransparency = 1
upgradesLabel.Text                   = "Улучшения базы"
upgradesLabel.TextColor3             = Color3.fromRGB(180, 210, 255)
upgradesLabel.TextScaled             = true
upgradesLabel.Font                   = Enum.Font.GothamBold
upgradesLabel.TextXAlignment         = Enum.TextXAlignment.Left
upgradesLabel.Parent                 = panel

local upgradeBtn = Instance.new("TextButton")
upgradeBtn.Size                   = UDim2.new(1, -32, 0, 44)
upgradeBtn.Position               = UDim2.new(0, 16, 0, yAfterQuest + 36)
upgradeBtn.BackgroundColor3       = Color3.fromRGB(40, 55, 30)
upgradeBtn.BackgroundTransparency = 0.15
upgradeBtn.BorderSizePixel        = 0
upgradeBtn.Text                   = "🔩 Усиленная ловушка  150💰"
upgradeBtn.TextColor3             = Color3.fromRGB(140, 220, 100)
upgradeBtn.TextScaled             = true
upgradeBtn.Font                   = Enum.Font.GothamBold
upgradeBtn.AutoButtonColor        = true
upgradeBtn.Active                 = true
upgradeBtn.Parent                 = panel
UiUtil.corner(upgradeBtn, 8)

local showToast = UiUtil.makeToast(gui, UDim2.new(0.5, -200, 0, 72), 400)

local nextQuestAt: number = 0
local hasReinforcedTrap: boolean = false
local tickConn: RBXScriptConnection? = nil
local tickElapsed = 0

local function stopTick()
	if tickConn then tickConn:Disconnect(); tickConn = nil end
	tickElapsed = 0
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

local function updateUpgradeBtn()
	if hasReinforcedTrap then
		upgradeBtn.Active           = false
		upgradeBtn.AutoButtonColor  = false
		upgradeBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 20)
		upgradeBtn.TextColor3       = Color3.fromRGB(80, 140, 60)
		upgradeBtn.Text             = "🔩 Усиленная ловушка  ✓ куплено"
	else
		upgradeBtn.Active           = true
		upgradeBtn.AutoButtonColor  = true
		upgradeBtn.BackgroundColor3 = Color3.fromRGB(40, 55, 30)
		upgradeBtn.TextColor3       = Color3.fromRGB(140, 220, 100)
		upgradeBtn.Text             = "🔩 Усиленная ловушка  150💰"
	end
end

local function startTickIfNeeded()
	stopTick()
	if not overlay.Visible then return end
	if nextQuestAt <= os.time() then return end
	tickElapsed = 0
	tickConn = RunService.Heartbeat:Connect(function(dt)
		if not overlay.Visible then stopTick(); return end
		tickElapsed += dt
		if tickElapsed < 1 then return end
		tickElapsed = 0
		updateQuestBtn()
		if nextQuestAt <= os.time() then stopTick() end
	end)
end

local function setOpen(isOpen: boolean)
	overlay.Visible = isOpen
	if not isOpen then
		stopTick()
	else
		updateQuestBtn()
		updateUpgradeBtn()
		startTickIfNeeded()
	end
end

local function openShop(shopBaseId: any)
	local shopId = BaseUtil.normalizeId(shopBaseId)
	local data   = fnGetData:InvokeServer()
	if not data or not data.ok then
		showToast((data and data.message) or "Не удалось загрузить данные")
		return
	end
	local myId = BaseUtil.normalizeId(data.baseId)
	if not shopId or not myId or myId ~= shopId then
		showToast("Это чужой магазин — только на своей базе")
		return
	end
	nextQuestAt       = data.nextQuestAt or 0
	hasReinforcedTrap = (data.upgrades or {}).reinforcedTrap == true
	setOpen(true)
end

for i, def in MONSTER_DEFS do
	local btn = monsterBtns[i]
	local monsterType = def.type
	btn.MouseButton1Click:Connect(function()
		local result = fnBuyMonster:InvokeServer({ monsterType = monsterType })
		if result and result.ok then
			showToast("Купил " .. def.label .. "! 🎉")
		else
			showToast((result and result.message) or "Ошибка покупки")
		end
	end)
end

questBtn.MouseButton1Click:Connect(function()
	if not questBtn.Active then return end
	local result = fnDoQuest:InvokeServer()
	if not (result and result.ok) then
		showToast((result and result.message) or "Ошибка квеста")
	end
end)

upgradeBtn.MouseButton1Click:Connect(function()
	if not upgradeBtn.Active then return end
	local result = fnBuyUpgrade:InvokeServer({ upgradeKey = "reinforcedTrap" })
	if result and result.ok then
		hasReinforcedTrap = true
		updateUpgradeBtn()
	else
		showToast((result and result.message) or "Ошибка покупки апгрейда")
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

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if player ~= localPlayer or prompt.Name ~= "ShopPrompt" then return end
	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if not model then return end
	openShop(model:GetAttribute("BaseId"))
end)

evMonsterUpdated.OnClientEvent:Connect(function(payload)
	if payload.nextQuestAt ~= nil then
		nextQuestAt = payload.nextQuestAt
		if overlay.Visible then
			updateQuestBtn()
			startTickIfNeeded()
		end
	end
	if payload.upgrades ~= nil then
		hasReinforcedTrap = payload.upgrades.reinforcedTrap == true
		if overlay.Visible then
			updateUpgradeBtn()
		end
	end
end)

return nil

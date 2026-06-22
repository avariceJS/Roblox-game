local Players = game:GetService("Players")

local UiUtil = require(script.Parent.UiUtil)
local MonsterDisplay = require(game.ReplicatedStorage.src.Shared.MonsterDisplay)

local localPlayer = Players.LocalPlayer
local src = game.ReplicatedStorage:WaitForChild("src")
local Remotes = src:WaitForChild("Remotes")
local fnGetData = Remotes:WaitForChild("GetPlayerData") :: RemoteFunction
local evMonsterUpdated = Remotes:WaitForChild("MonsterUpdated") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name         = "MonsterHUD"
gui.ResetOnSpawn = false
gui.Parent       = localPlayer.PlayerGui

local showToast = UiUtil.makeToast(gui, UDim2.new(0.5, -200, 0, 16), 400)

local card = Instance.new("Frame")
card.Size = UDim2.new(0, 200, 0, 90)
card.Position = UDim2.new(0, 16, 1, -110)
card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
card.BackgroundTransparency = 0.25
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
UiUtil.corner(card, 10)

local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(0, 52, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.TextScaled = true
iconLabel.Font = Enum.Font.GothamBold
iconLabel.Parent = card

local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, -60, 1, -10)
infoFrame.Position = UDim2.new(0, 56, 0, 5)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = card

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0.38, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = infoFrame

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
rarityLabel.Position = UDim2.new(0, 0, 0.38, 0)
rarityLabel.BackgroundTransparency = 1
rarityLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
rarityLabel.TextScaled = true
rarityLabel.Font = Enum.Font.Gotham
rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
rarityLabel.Parent = infoFrame

local stateLabel = Instance.new("TextLabel")
stateLabel.Size = UDim2.new(1, 0, 0.32, 0)
stateLabel.Position = UDim2.new(0, 0, 0.68, 0)
stateLabel.BackgroundTransparency = 1
stateLabel.TextScaled = true
stateLabel.Font = Enum.Font.Gotham
stateLabel.TextXAlignment = Enum.TextXAlignment.Left
stateLabel.Parent = infoFrame

local monsterLabels = {
	icon = iconLabel,
	name = nameLabel,
	rarity = rarityLabel,
	state = stateLabel,
}

local function refresh(monsters: { any }?)
	local visible = MonsterDisplay.fill(monsterLabels, MonsterDisplay.first(monsters))
	card.Visible = visible == true
end

evMonsterUpdated.OnClientEvent:Connect(function(payload: { [string]: any })
	if payload.monsters then
		refresh(payload.monsters)
	end
	if payload.toast then
		showToast(payload.toast)
	end
end)

local result = fnGetData:InvokeServer()
if result.ok and result.monsters then
	refresh(result.monsters)
end

return nil

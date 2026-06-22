local Players = game:GetService("Players")

local UiUtil = require(script.Parent.UiUtil)

local localPlayer = Players.LocalPlayer
local Remotes = game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Remotes")
local fnGetData = Remotes:WaitForChild("GetPlayerData") :: RemoteFunction
local evBaseAssigned   = Remotes:WaitForChild("BaseAssigned")   :: RemoteEvent
local evMonsterUpdated = Remotes:WaitForChild("MonsterUpdated") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = localPlayer.PlayerGui

local badge = Instance.new("Frame")
badge.Size = UDim2.new(0, 300, 0, 48)
badge.Position = UDim2.new(0, 16, 0, 16)
badge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
badge.BackgroundTransparency = 0.35
badge.BorderSizePixel = 0
badge.Parent = gui
UiUtil.corner(badge, 10)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(0.38, 0, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "🪙 …"
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBold
coinLabel.Parent = badge

local chaosLabel = Instance.new("TextLabel")
chaosLabel.Size = UDim2.new(0.28, 0, 1, 0)
chaosLabel.Position = UDim2.new(0.38, 0, 0, 0)
chaosLabel.BackgroundTransparency = 1
chaosLabel.Text = "🌀 …"
chaosLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
chaosLabel.TextScaled = true
chaosLabel.Font = Enum.Font.GothamBold
chaosLabel.Parent = badge

local baseLabel = Instance.new("TextLabel")
baseLabel.Size = UDim2.new(0.34, -4, 1, 0)
baseLabel.Position = UDim2.new(0.66, 4, 0, 0)
baseLabel.BackgroundTransparency = 1
baseLabel.TextColor3 = Color3.fromRGB(80, 255, 110)
baseLabel.TextScaled = true
baseLabel.Font = Enum.Font.GothamBold
baseLabel.TextXAlignment = Enum.TextXAlignment.Right
baseLabel.Parent = badge

local banner = Instance.new("Frame")
banner.Size = UDim2.new(0, 340, 0, 90)
banner.Position = UDim2.new(0.5, -170, 0.5, -45)
banner.BackgroundColor3 = Color3.fromRGB(80, 10, 10)
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui
UiUtil.corner(banner, 14)

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Size = UDim2.new(1, -24, 1, 0)
bannerLabel.Position = UDim2.new(0, 12, 0, 0)
bannerLabel.BackgroundTransparency = 1
bannerLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
bannerLabel.TextScaled = true
bannerLabel.TextWrapped = true
bannerLabel.Font = Enum.Font.Gotham
bannerLabel.Parent = banner

local function setBase(id: number?)
	baseLabel.Text = if id then "🏠 #" .. id else ""
end

local function setBalances(coins: number?, chaos: number?)
	if coins ~= nil then
		coinLabel.Text = "🪙 " .. coins
	end
	if chaos ~= nil then
		chaosLabel.Text = "🌀 " .. chaos
	end
end

local function showError(message: string)
	bannerLabel.Text = message
	banner.Visible = true
end

evMonsterUpdated.OnClientEvent:Connect(function(payload: { coins: number?, chaos: number? })
	setBalances(payload.coins, payload.chaos)
end)

evBaseAssigned.OnClientEvent:Connect(function(payload: { baseId: number })
	setBase(payload.baseId)
end)

task.spawn(function()
	for _ = 1, 40 do
		local result = fnGetData:InvokeServer()
		if result.ok then
			setBalances(result.coins, result.chaos)
			setBase(result.baseId)
			return
		end
		task.wait(0.25)
	end

	local result = fnGetData:InvokeServer()
	if result and not result.ok then
		showError(result.message)
	end
end)

return nil

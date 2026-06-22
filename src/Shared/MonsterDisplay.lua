local MonsterDefs = require(script.Parent.MonsterDefs)

local STATE_TEXT = {
	Idle = "Свободен",
	OnMission = "На задании",
	Fatigued = "Отдыхает",
	Captured = "Пойман",
}

local STATE_COLOR = {
	Idle = Color3.fromRGB(80, 220, 80),
	OnMission = Color3.fromRGB(255, 200, 0),
	Fatigued = Color3.fromRGB(130, 130, 255),
	Captured = Color3.fromRGB(255, 80, 80),
}

local MonsterDisplay = {}

function MonsterDisplay.fatigueSecondsLeft(monster: any): number?
	if monster.state ~= "Fatigued" then
		return nil
	end
	local untilTs = monster.fatigueUntil
	if not untilTs or untilTs <= 0 then
		return nil
	end
	return math.max(0, untilTs - os.time())
end

function MonsterDisplay.stateText(monster: any): string
	local base = STATE_TEXT[monster.state] or monster.state
	local left = MonsterDisplay.fatigueSecondsLeft(monster)
	if left ~= nil then
		return base .. " · " .. left .. " сек"
	end
	return base
end

function MonsterDisplay.first(monsters: { any }?): any?
	return monsters and monsters[1]
end

function MonsterDisplay.fill(labels: {
	icon: TextLabel,
	name: TextLabel,
	rarity: TextLabel,
	state: TextLabel,
}, monster: any?)
	if not monster then
		return false
	end

	local def = MonsterDefs[monster.type] or MonsterDefs.Slime
	labels.icon.Text = def.icon
	labels.name.Text = def.displayName
	labels.rarity.Text = def.rarityDisplay
	labels.state.Text = MonsterDisplay.stateText(monster)
	labels.state.TextColor3 = STATE_COLOR[monster.state] or Color3.new(1, 1, 1)
	return true
end

return MonsterDisplay

local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.src.Shared.Config)
local BaseUtil = require(game.ReplicatedStorage.src.Shared.BaseUtil)

local occupied: { [number]: Player } = {}

local BaseService = {}

function BaseService.assign(player: Player, preferred: number?): number?
	local pref = BaseUtil.normalizeId(preferred)
	if pref then
		local occupant = occupied[pref]
		if not occupant or occupant == player then
			occupied[pref] = player
			return pref
		end
	end
	for i = 1, Config.BASE_COUNT do
		if not occupied[i] then
			occupied[i] = player
			return i
		end
	end
	return nil
end

function BaseService.release(player: Player)
	for id, occupant in occupied do
		if occupant == player then
			occupied[id] = nil
			return
		end
	end
end

function BaseService.setupSpawn(player: Player, baseId: number)
	local spawn = BaseUtil.getSpawn(baseId)
	if not spawn then
		warn("[BaseService] SpawnLocation not found for Base" .. baseId)
		return
	end

	spawn.Neutral = false
	player.RespawnLocation = spawn

	local function onCharacter(character: Model)
		local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if hrp then
			hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
		end
		if RunService:IsStudio() then
			local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
			if hum then
				hum.WalkSpeed = Config.STUDIO_WALK_SPEED
			end
		end
	end

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

function BaseService.getOccupied(): { [number]: Player }
	return occupied
end

function BaseService.getOccupant(baseId: number): Player?
	return occupied[baseId]
end

return BaseService

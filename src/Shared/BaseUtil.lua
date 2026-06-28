local BaseUtil = {}

function BaseUtil.normalizeId(baseId: any): number?
	local n = tonumber(baseId)
	if n and n >= 1 then
		return math.floor(n)
	end
	return nil
end

function BaseUtil.getBasesFolder(): Folder?
	return workspace:FindFirstChild("Bases") :: Folder?
end

function BaseUtil.getBaseRoot(baseId: number): Instance?
	local bases = BaseUtil.getBasesFolder()
	if not bases then
		return nil
	end
	return bases:FindFirstChild("Base" .. baseId)
end

function BaseUtil.getSpawn(baseId: number): SpawnLocation?
	local root = BaseUtil.getBaseRoot(baseId)
	if not root then
		return nil
	end
	if root:IsA("SpawnLocation") then
		return root
	end
	return root:FindFirstChildWhichIsA("SpawnLocation") :: SpawnLocation?
end

function BaseUtil.getLabFloorPos(baseId: number): Vector3?
	local spawn = BaseUtil.getSpawn(baseId)
	if not spawn then
		return nil
	end
	local topY = spawn.Position.Y + spawn.Size.Y * 0.5
	local side = spawn.CFrame.RightVector * (spawn.Size.X * 0.5 + 3.5)
	return Vector3.new(spawn.Position.X, topY, spawn.Position.Z) + side
end

function BaseUtil.getShopFloorPos(baseId: number): Vector3?
	local spawn = BaseUtil.getSpawn(baseId)
	if not spawn then return nil end
	local topY = spawn.Position.Y + spawn.Size.Y * 0.5
	local side = spawn.CFrame.RightVector * (spawn.Size.X * 0.5 + 3.5)
	return Vector3.new(spawn.Position.X, topY, spawn.Position.Z) - side
end

function BaseUtil.getJailFloorPos(baseId: number): Vector3?
	local spawn = BaseUtil.getSpawn(baseId)
	if not spawn then return nil end
	local topY = spawn.Position.Y + spawn.Size.Y * 0.5
	local front = spawn.CFrame.LookVector * (spawn.Size.Z * 0.5 + 3.5)
	return Vector3.new(spawn.Position.X, topY, spawn.Position.Z) + front
end

function BaseUtil.getNpcHome(): BasePart?
	local folder = workspace:FindFirstChild("NpcHomes")
	return folder and folder:FindFirstChild("House") :: BasePart?
end

function BaseUtil.getMissionPlatform(targetId: number): BasePart?
	if targetId < 1 then
		return BaseUtil.getNpcHome()
	end
	return BaseUtil.getSpawn(targetId)
end

return BaseUtil

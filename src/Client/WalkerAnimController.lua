local ContentProvider = game:GetService("ContentProvider")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")

local Config = require(game.ReplicatedStorage.src.Shared.Config)

local started: { [Model]: boolean } = {}

local function findWalkAnimation(container: Instance): Animation?
	local fallback: Animation? = nil
	for _, d in container:GetDescendants() do
		if d:IsA("Animation") then
			local id = d.AnimationId
			if id == "" or id == "rbxassetid://0" then
				continue
			end
			local n = string.lower(d.Name)
			if string.find(n, "walk") or string.find(n, "run") or string.find(n, "crouch") then
				return d
			end
			if not fallback then
				fallback = d
			end
		end
	end
	return fallback
end

local function playWalk(model: Model): boolean
	local ac = model:FindFirstChildWhichIsA("AnimationController", true)
	if not ac then
		return false
	end

	local animator = ac:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = ac
	end

	local anim = findWalkAnimation(model)
	if not anim and Config.WALKER_WRAITH_ANIM_ID ~= "" then
		anim = Instance.new("Animation")
		anim.Name = "Walk"
		anim.AnimationId = Config.WALKER_WRAITH_ANIM_ID
	end
	if not anim then
		return false
	end

	pcall(function()
		ContentProvider:PreloadAsync({ anim })
	end)

	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not track then
		return false
	end

	track.Looped = true
	track:Play(0.1, 1, 1)
	task.wait(0.15)
	return track.Length > 0 and track.IsPlaying
end

local function startProceduralWalk(model: Model, duration: number)
	local rest: { [Bone]: CFrame } = {}
	local limbs: { Bone } = {}

	for _, d in model:GetDescendants() do
		if d:IsA("Bone") then
			local n = d.Name
			if string.find(n, "Arm")
				or string.find(n, "Leg")
				or string.find(n, "Hand")
				or string.find(n, "Foot")
			then
				rest[d] = d.Transform
				table.insert(limbs, d)
			end
		end
	end

	if #limbs == 0 then
		return
	end

	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not model.Parent or os.clock() - t0 > duration then
			conn:Disconnect()
			for bone, cf in rest do
				if bone.Parent then
					bone.Transform = cf
				end
			end
			return
		end
		local phase = (os.clock() - t0) * 7
		for i, bone in limbs do
			local base = rest[bone]
			local swing = math.sin(phase + i * 0.8) * 0.4
			bone.Transform = base * CFrame.Angles(swing, 0, 0)
		end
	end)
end

local function tweenModelPivot(model: Model, toPos: Vector3, duration: number)
	local start = model:GetPivot()
	local finish = start + (toPos - start.Position)
	local alpha = Instance.new("NumberValue")
	alpha.Value = 0
	local conn = alpha.Changed:Connect(function(v)
		model:PivotTo(start:Lerp(finish, v))
	end)
	local tween = TweenService:Create(
		alpha,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Value = 1 }
	)
	tween:Play()
	tween.Completed:Wait()
	conn:Disconnect()
	alpha:Destroy()
end

local function runWalkerVisual(model: Model)
	if started[model] then
		return
	end
	started[model] = true

	task.spawn(function()
		local deadline = os.clock() + 3
		while model.Parent and model:GetAttribute("TargetX") == nil and os.clock() < deadline do
			task.wait()
		end
		if not model.Parent then
			started[model] = nil
			return
		end

		local tx = model:GetAttribute("TargetX")
		if tx == nil then
			started[model] = nil
			return
		end

		local target = Vector3.new(
			tx,
			model:GetAttribute("TargetY") or model:GetPivot().Position.Y,
			model:GetAttribute("TargetZ") or 0
		)
		local duration = model:GetAttribute("TravelTime") or Config.TRAVEL_TIME

		local usedClip = playWalk(model)
		if not usedClip then
			startProceduralWalk(model, duration)
		end

		tweenModelPivot(model, target, duration)
		started[model] = nil
	end)

	model.Destroying:Connect(function()
		started[model] = nil
	end)
end

local function tryModel(inst: Instance)
	if inst:IsA("Model") and inst:FindFirstChildWhichIsA("AnimationController", true) then
		runWalkerVisual(inst)
	end
end

local missions = workspace:WaitForChild("Missions")

for _, child in missions:GetChildren() do
	tryModel(child)
end

missions.ChildAdded:Connect(tryModel)

return nil

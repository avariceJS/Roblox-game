local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local Config            = require(game.ReplicatedStorage.src.Shared.Config)
local PlayerDataService = require(game.ReplicatedStorage.src.Server.PlayerDataService)
local MonsterDefs       = require(game.ReplicatedStorage.src.Shared.MonsterDefs)

local _pds = nil
local _ev  = nil
local _pendingIntent: { [number]: { productKey: string, monsterId: string? } } = {}

local MonetizationService = {}

local function makeId(): string
	return tostring(math.floor(os.clock() * 1000)) .. tostring(math.random(100, 999))
end

local function freeMonster(player: Player, data: any, monsterId: string?): boolean
	if not monsterId then return false end
	local monster = nil
	for _, m in data.monsters do
		if m.id == monsterId then monster = m; break end
	end
	if not monster or monster.state ~= "Captured" then return false end

	local capturedByUserId = monster.capturedByUserId
	if not capturedByUserId then
		capturedByUserId = PlayerDataService.findCaptorUserIdForMonster(monsterId)
	end

	monster.state            = "Idle"
	monster.fatigueUntil     = 0
	monster.capturedByBaseId = nil
	monster.capturedByName   = nil
	monster.capturedByUserId = nil
	monster.ransomPrice      = nil

	if capturedByUserId then
		PlayerDataService.modifyByUserId(capturedByUserId, function(capData)
			for i, entry in capData.jail do
				if entry.monsterId == monsterId then
					table.remove(capData.jail, i)
					break
				end
			end
		end)
		local capPlayer = Players:GetPlayerByUserId(capturedByUserId)
		if capPlayer and capPlayer.Parent then
			local capData = PlayerDataService.get(capPlayer)
			if capData then
				_ev:FireClient(capPlayer, {
					jail  = capData.jail,
					toast = "Монстр выкуплен за Robux — сбежал из клетки! 💎",
				})
			end
		end
	end

	_ev:FireClient(player, {
		monsters = data.monsters,
		toast    = "💎 Монстр выкуплен мгновенно!",
	})
	return true
end

local function forceSubjugate(player: Player, data: any, monsterId: string?): boolean
	if not monsterId then return false end
	local entry, jailIdx = nil, nil
	for i, e in data.jail do
		if e.monsterId == monsterId then entry = e; jailIdx = i; break end
	end
	if not entry then return false end

	local ownerUserId = entry.ownerUserId
	local monsterType = entry.monsterType or "Slime"
	local def = MonsterDefs[monsterType] or MonsterDefs["Slime"]

	table.remove(data.jail, jailIdx)
	table.insert(data.monsters, {
		id           = makeId(),
		type         = monsterType,
		level        = 1,
		xp           = 0,
		state        = "Idle",
		fatigueUntil = 0,
	})

	PlayerDataService.modifyByUserId(ownerUserId, function(ownerData)
		for i, m in ownerData.monsters do
			if m.id == monsterId then
				table.remove(ownerData.monsters, i)
				break
			end
		end
	end)

	local ownerPlayer = Players:GetPlayerByUserId(ownerUserId)
	if ownerPlayer and ownerPlayer.Parent then
		local ownerData = PlayerDataService.get(ownerPlayer)
		if ownerData then
			_ev:FireClient(ownerPlayer, {
				monsters = ownerData.monsters,
				toast    = def.icon .. " " .. def.displayName .. " подчинён захватчиком за Robux! 💎",
			})
		end
	end

	_ev:FireClient(player, {
		monsters = data.monsters,
		jail     = data.jail,
		toast    = "💎 Подчинил " .. def.icon .. " " .. def.displayName .. " гарантированно!",
	})
	return true
end

local function fastRecovery(player: Player, data: any, monsterId: string?): boolean
	for _, m in data.monsters do
		local matches = (monsterId and m.id == monsterId) or (not monsterId and m.state == "Fatigued")
		if matches and m.state == "Fatigued" then
			m.state        = "Idle"
			m.fatigueUntil = 0
			_ev:FireClient(player, {
				monsters = data.monsters,
				toast    = "💎 Монстр восстановлен мгновенно!",
			})
			return true
		end
	end
	return false
end

function MonetizationService.setPurchaseIntent(
	player: Player, productKey: string, monsterId: string?
): { ok: boolean, immediate: boolean?, productId: number?, message: string? }
	local VALID = { instantRansom = true, forceSubjugate = true, fastRecovery = true }
	if not VALID[productKey] then
		return { ok = false, message = "Неверный продукт" }
	end

	local data = _pds.get(player)
	if not data then return { ok = false, message = "Данные не загружены" } end

	if productKey == "instantRansom" then
		local found = false
		for _, m in data.monsters do
			if m.id == monsterId and m.state == "Captured" then found = true; break end
		end
		if not found then return { ok = false, message = "Монстр не захвачен" } end
	elseif productKey == "forceSubjugate" then
		local found = false
		for _, e in data.jail do
			if e.monsterId == monsterId then found = true; break end
		end
		if not found then return { ok = false, message = "Монстр не в клетке" } end
	elseif productKey == "fastRecovery" then
		local found = false
		for _, m in data.monsters do
			if m.state == "Fatigued" then found = true; break end
		end
		if not found then return { ok = false, message = "Нет уставших монстров" } end
	end

	local productId =
		productKey == "instantRansom"  and Config.PRODUCT_INSTANT_RANSOM or
		productKey == "forceSubjugate" and Config.PRODUCT_FORCE_SUBJUGATE or
		Config.PRODUCT_FAST_RECOVERY

	if productId == 0 then
		local success = false
		if productKey == "instantRansom" then
			success = freeMonster(player, data, monsterId)
		elseif productKey == "forceSubjugate" then
			success = forceSubjugate(player, data, monsterId)
		else
			success = fastRecovery(player, data, monsterId)
		end
		if success then _pds.save(player) end
		return { ok = success, immediate = true, message = not success and "Не удалось выполнить" or nil }
	end

	_pendingIntent[player.UserId] = { productKey = productKey, monsterId = monsterId }
	return { ok = true, immediate = false, productId = productId }
end

function MonetizationService.checkGamePasses(player: Player, data: any)
	local changed = false
	if Config.GAMEPASS_VIP ~= 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GAMEPASS_VIP)
		end)
		if ok and owns and not data.hasVip then
			data.hasVip = true
			changed = true
		end
	end
	if Config.GAMEPASS_EXTRA_SLOT ~= 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.GAMEPASS_EXTRA_SLOT)
		end)
		if ok and owns and not data.hasExtraSlot then
			data.hasExtraSlot = true
			changed = true
		end
	end
	if changed then
		_pds.save(player)
		_ev:FireClient(player, { hasVip = data.hasVip, hasExtraSlot = data.hasExtraSlot })
	end
end

function MonetizationService.init(pds, ev)
	_pds = pds
	_ev  = ev

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
		if not wasPurchased then return end
		local data = _pds.get(player)
		if not data then return end
		local changed = false
		if gamePassId == Config.GAMEPASS_VIP and not data.hasVip then
			data.hasVip = true
			changed = true
		elseif gamePassId == Config.GAMEPASS_EXTRA_SLOT and not data.hasExtraSlot then
			data.hasExtraSlot = true
			changed = true
		end
		if changed then
			_pds.save(player)
			_ev:FireClient(player, {
				hasVip       = data.hasVip,
				hasExtraSlot = data.hasExtraSlot,
				toast        = "💎 Покупка успешна!",
			})
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local purchaseId = tostring(receiptInfo.PurchaseId)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local data = _pds.get(player)
		if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end

		data.processedPurchases = data.processedPurchases or {}
		for _, pid in data.processedPurchases do
			if pid == purchaseId then return Enum.ProductPurchaseDecision.PurchaseGranted end
		end

		local pid = receiptInfo.ProductId
		local productKey = nil
		if pid ~= 0 and pid == Config.PRODUCT_INSTANT_RANSOM then
			productKey = "instantRansom"
		elseif pid ~= 0 and pid == Config.PRODUCT_FORCE_SUBJUGATE then
			productKey = "forceSubjugate"
		elseif pid ~= 0 and pid == Config.PRODUCT_FAST_RECOVERY then
			productKey = "fastRecovery"
		end
		if not productKey then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local intent = _pendingIntent[receiptInfo.PlayerId]
		_pendingIntent[receiptInfo.PlayerId] = nil
		local monsterId = intent and intent.monsterId

		local success = false
		if productKey == "instantRansom" then
			success = freeMonster(player, data, monsterId)
		elseif productKey == "forceSubjugate" then
			success = forceSubjugate(player, data, monsterId)
		elseif productKey == "fastRecovery" then
			success = fastRecovery(player, data, monsterId)
		end

		if not success then return Enum.ProductPurchaseDecision.NotProcessedYet end

		table.insert(data.processedPurchases, purchaseId)
		if #data.processedPurchases > 50 then
			table.remove(data.processedPurchases, 1)
		end
		_pds.save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return MonetizationService

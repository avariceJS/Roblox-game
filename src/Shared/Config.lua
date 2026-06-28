return {
	START_COINS = 100,
	START_CHAOS = 0,
	BASE_COUNT = 6,
	DATASTORE_KEY = "PlayerData_v1",

	BASE_SIZE = Vector3.new(14, 1, 14),

	TRAVEL_TIME     = 8,
	DISPATCH_COINS  = 25,
	DISPATCH_CHAOS  = 10,
	FATIGUE_TIME    = 10,
	PUDDLE_RADIUS        = 6,
	PUDDLE_DURATION      = 10,
	SLOW_SPEED           = 8,
	SLOW_DURATION        = 4,
	LAB_PROMPT_DISTANCE  = 14,
	STUDIO_WALK_SPEED    = 64,
	CAGE_COST           = 0,
	TRAP_CATCH_CHANCE   = 1.0,

	RANSOM_MIN          = 10,
	RANSOM_MAX          = 500,
	SHOP_PRICES         = { Slime = 50 },
	QUEST_REWARD        = 25,
	QUEST_COOLDOWN      = 120,

	NPC_HOME_ID       = 0,
	NPC_HOME_POSITION = Vector3.new(90, 0.5, 35),

	BASE_LAYOUT = {
		{ id = 1, position = Vector3.new(-45, 0.5, 35), color = Color3.fromRGB(220, 55, 55) },
		{ id = 2, position = Vector3.new(-22, 0.5, 35), color = Color3.fromRGB(35, 35, 40) },
		{ id = 3, position = Vector3.new(0, 0.5, 35), color = Color3.fromRGB(235, 235, 235) },
		{ id = 4, position = Vector3.new(22, 0.5, 35), color = Color3.fromRGB(255, 140, 40) },
		{ id = 5, position = Vector3.new(45, 0.5, 35), color = Color3.fromRGB(255, 210, 50) },
		{ id = 6, position = Vector3.new(68, 0.5, 35), color = Color3.fromRGB(55, 120, 255) },
	},
}

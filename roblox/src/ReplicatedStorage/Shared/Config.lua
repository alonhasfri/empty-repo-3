-- Config: every number, ID and setting for the game lives here.
-- Fill in the "0" IDs after you create them on the Roblox Creator Dashboard.

local Config = {}

Config.GameName = "Lose a Brain Cell / Gain a Brain Cell"
Config.Version = "1.4"

---------------------------------------------------------------------
-- COMMUNITY (GROUP) RANKS -> IN-GAME RANKS
---------------------------------------------------------------------
-- Put the ID of "Cult of the 39" here. Find it in the community page link:
-- roblox.com/communities/1234567/... -> the number is the ID.
Config.GroupId = 0

-- In-game rank levels
Config.Levels = { Player = 0, Tester = 1, Moderator = 2, HeadModerator = 3, Owner = 4 }
Config.RankNames = { [0] = "Player", [1] = "Tester", [2] = "Moderator", [3] = "Head Moderator", [4] = "Owner" }
Config.RankColors = {
	[1] = Color3.fromRGB(120, 200, 255),
	[2] = Color3.fromRGB(120, 255, 140),
	[3] = Color3.fromRGB(255, 170, 60),
	[4] = Color3.fromRGB(255, 80, 80),
}

-- Community rank NUMBER -> in-game level. Checked from the top down.
-- Only rank 255 (the real community owner) becomes Owner.
Config.GroupRankMap = {
	{ minRank = 100, level = 3 }, -- Head Moderator
	{ minRank = 50, level = 2 }, -- Moderator
	{ minRank = 10, level = 1 }, -- Tester
}

-- If true, whoever presses Play in Roblox Studio becomes Owner (only for testing an
-- unpublished file). Keep it false: once the game is published under the community,
-- Studio uses everyone's real community rank (Owner, Head Moderator, ...).
Config.StudioIsOwner = false

-- Extra Owners by Roblox user ID (optional). The community owner (rank 255) is always Owner.
Config.OwnerUserIds = {}

---------------------------------------------------------------------
-- BRAIN NUMBERS (based on real neuroscience)
---------------------------------------------------------------------
Config.AverageCells = 86e9 -- average adult human
Config.CellsPerSD = 8e9 -- every 8 billion cells = 15 IQ points
Config.LoseStartCells = 86e9
Config.GainStartCells = 70e9 -- 80 IQ, slightly below average
Config.HumanFloorCells = 45e9 -- "dumbest man alive"
Config.OverflowCells = 140e9 -- about 200 IQ
Config.ElephantCells = 257e9

-- How fast cells change. These can be changed live by Head Moderators.
Config.Rates = {
	GainRate = 0.002, -- fraction of your cells gained per activity point (Gain path)
	LoseRate = 0.014, -- fraction of your cells lost per activity point (Lose path; lower = harder to lose)
	MinLoss = 1, -- the smallest loss per point (so you can actually reach 0)
}

-- Multipliers shrink as you climb. Applied to each gain, never to your total.
Config.GainMultipliers = {
	{ below = 1e6, mult = 999, label = "🔥🔥 MEGA ULTRA ×999 BRAIN BOOST 🔥🔥" },
	{ below = 1e9, mult = 100, label = "SUPER BOOST ×100!!" },
	{ below = 50e9, mult = 10, label = "Boost ×10" },
	{ below = 86e9, mult = 2, label = "Learning bonus: ×2" },
	{ below = 110e9, mult = 1.1, label = "Retention coefficient: 1.1" },
	{ below = 140e9, mult = 1.01, label = "Marginal cognitive gain factor: 1.01" },
	{ below = math.huge, mult = 999, label = "Overflow ×999 (it doesn't matter anymore)" },
}

---------------------------------------------------------------------
-- SKILL GATES (the PLAYER must be smart)
---------------------------------------------------------------------
Config.Gates = {
	{ id = "gate1", iq = 100, tier = 1, name = "The Average Gate" },
	{ id = "gate2", iq = 115, tier = 2, name = "The Coder's Gate" },
	{ id = "gate3", iq = 130, tier = 3, name = "The Gifted Gate" },
	{ id = "gate4", iq = 145, tier = 4, name = "The Genius Gate" },
}
Config.GateQuestionCount = 3
Config.GateSeconds = 60
Config.GateExtraTimeMultiplier = 1.5 -- accessibility setting
Config.GateFailCooldown = 30
Config.GateHints = 1 -- hints per attempt (Extra Hints pass adds 2)
Config.HintCostFraction = 0.01 -- a hint costs 1% of your cells

---------------------------------------------------------------------
-- LOSE PATH
---------------------------------------------------------------------
Config.ReadingSeconds = 10 -- reading this long = you actually read it
Config.ReadingPopupMin = 25
Config.ReadingPopupMax = 45
Config.TOSChance = 0.05 -- chance a reading popup is the giant Terms of Service
Config.TOSSeconds = 60

Config.Embarrassment = {
	Max = 100,
	HideAt = 50, -- over half -> run and hide behind a bush
	HideSeconds = 10,
	DecayPerSecond = 0.5,
	BreaksBelowCells = 50e6, -- too dumb to care
}

Config.PetBelowCells = 20e9
Config.LeakBelowCells = 20e9
Config.ViralBadgeCount = 5

---------------------------------------------------------------------
-- GAIN PATH
---------------------------------------------------------------------
Config.Stress = { Max = 100, FreezeAt = 100 }
Config.EurekaTasks = 6 -- job tasks needed to fill the idea meter (Eureka cutscene)
Config.WorkRadius = 45 -- how close to your workplace you must be to work
Config.TaxiCooldown = 8
Config.ElectionMinutes = 20 -- an election starts this often (update 1.2)
Config.ComebackMakeoverIQ = 145 -- Comeback players who reach this get Complete Makeover

---------------------------------------------------------------------
-- SAVING
---------------------------------------------------------------------
Config.DataStoreName = "BrainCellData_v1"
Config.AutosaveSeconds = 60

---------------------------------------------------------------------
-- SOUNDS AND MUSIC
-- Upload the sound files on create.roblox.com (Development Items -> Audio),
-- then paste each asset ID number here. 0 = silent.
---------------------------------------------------------------------
Config.Sounds = {
	GameShowJingle = 0,
	LibrarianChime = 0,
	CartoonBoing = 0,
	KazooTune = 0,
	LevelUp = 0,
	SadTrombone = 0,
	AirHorn = 0,
	CavemanBonk = 0,
	BrainCellLost = 0,
	BrainCellGained = 0,
	NotificationPing = 0,
	DeathBoom = 0,
	BadgeSparkle = 0,
	RecordScratch = 0,
	-- 1.4
	Whoosh = 0, -- rocket launch, falling into the void
	TypeTick = 0, -- tutorial typewriter (very short, quiet click)
	ImportantSlam = 0, -- tutorial "IMPORTANT" title slam
}

-- One music track per art style (from the Creator Store audio library).
Config.Music = {
	genius = 0, -- search "lofi" / "piano"
	smart = 0, -- search "calm" / "classical"
	average = 0, -- search "casual" / "happy"
	cashgrab = 0, -- search "hype" / "arcade"
	nonsense = 0, -- search "kazoo" / "silly"
}

---------------------------------------------------------------------
-- GAME PASSES (create them on the Creator Dashboard, paste the IDs)
---------------------------------------------------------------------
Config.GamePasses = {
	GoldenSkip = {
		id = 0,
		price = 75,
		path = "Lose",
		cellsLost = 1e9,
		name = "Golden Skip Button",
		desc = "Your skip button turns gold and goes cha-ching. Cosmetic.",
	},
	BuyBrain = {
		id = 0,
		price = 5,
		path = "Lose",
		cellsLost = 10e9,
		name = "BUY BRAIN 🧠🔥",
		desc = "Gives you a dunce cap. That's it. That's the pass.",
	},
	ExtraLoudDeath = {
		id = 0,
		price = 25,
		path = "Lose",
		cellsLost = 0,
		name = "Extra Loud Death",
		desc = "Even more sounds when you hit 0.",
	},
	VIPLibrary = {
		id = 0,
		price = 199,
		path = "Gain",
		cellsLost = 0,
		name = "VIP Library Card",
		desc = "VIP tag and +10% from the library. Never helps with Skill Gates.",
	},
	ExtraHints = {
		id = 0,
		price = 99,
		path = "Gain",
		cellsLost = 0,
		name = "Extra Hints",
		desc = "+2 hints per Skill Gate attempt. Still limited.",
	},
	-- Update 1.4. Only offered at IQ 160+ while NOBODY has invented Space Travel yet.
	-- Once anyone invents it, every player gets Astronaut free, so the pass disappears.
	AstronautEarly = {
		id = 0,
		price = 100,
		path = "Gain",
		cellsLost = 0,
		name = "Astronaut Early Access",
		desc = "Unlocks the Astronaut job right now, for every run. Heads up: once ANY player invents Space Travel, Astronaut becomes free for everyone.",
	},
}

-- Update 1.4: Space and secrets
Config.Space = {
	AstronautIQ = 160,
	SmartestIQ = 200,
	MoonGravity = 35, -- normal Roblox gravity is 196.2
}
Config.Castle = {
	Steps = 6, -- lefts/rights in a row to reach the brick wall
	BoostMinutes = 30,
	RewardPoints = 40,
}

---------------------------------------------------------------------
-- UPDATE 1.5: REAL PLACES
---------------------------------------------------------------------
Config.Rooms = {
	SpotCooldown = 4, -- seconds between uses of the same room spot (per player)
	PromptDistance = 9, -- how close you must be to use a room spot
	SeatPromptDistance = 6,
	-- brain points for the small things to do in rooms
	Actions = {
		arcade = { path = "Lose", lose = 2 },
		plushie = { path = "Lose", lose = 1.5 },
		cereal = { path = "Lose", lose = 1 },
	},
	BoardPoints = { Lose = 0.5, Gain = 0.3 }, -- writing on a whiteboard
	FridgeOpenAngle = 110, -- degrees
}

---------------------------------------------------------------------
-- FEATURE SWITCHES (Head Moderators can flip these live)
---------------------------------------------------------------------
Config.Features = {
	ReadingTests = true,
	Clickbait = true,
	StealA = true,
	Comments = true,
	Scroller = true,
	Zones = true,
	Library = true,
	Theater = true,
	Gates = true,
	Jobs = true,
	Habits = true,
	Pets = true,
	Purchases = true,
}

---------------------------------------------------------------------
-- ADMIN COMMANDS
-- min = lowest rank level that can use it.
-- target = needs a selected player. self = can be used on yourself only below Head Moderator.
-- arg = what goes in the panel's text box.
---------------------------------------------------------------------
Config.Commands = {
	-- Tester (self only)
	setcells = { min = 1, cat = "Players", label = "Set Brain Cells", target = true, selfBelow = 3, arg = "number" },
	setpath = { min = 1, cat = "Players", label = "Set Path", target = true, selfBelow = 3, arg = "Lose / Gain" },
	resetme = { min = 1, cat = "Server", label = "Reset My Progress" },
	replaydeath = { min = 1, cat = "Server", label = "Replay Death Ending" },
	teleportme = { min = 1, cat = "Server", label = "Teleport Me", arg = "lobby / lose / gain" },
	debug = { min = 1, cat = "Server", label = "Debug Overlay" },
	bug = { min = 1, cat = "Server", label = "Report Bug", arg = "text" },
	refreshrank = { min = 0, cat = "Server", label = "Refresh My Rank" },

	-- Moderator
	kick = { min = 2, cat = "Players", label = "Kick", target = true, arg = "reason" },
	warn = { min = 2, cat = "Players", label = "Warn", target = true, arg = "reason" },
	mute = { min = 2, cat = "Players", label = "Mute", target = true },
	unmute = { min = 2, cat = "Players", label = "Unmute", target = true },
	ban = { min = 2, cat = "Players", label = "Ban", target = true, arg = "1d / 7d / 30d / perm" },
	tp = { min = 2, cat = "Players", label = "Go To Player", target = true },
	bring = { min = 2, cat = "Players", label = "Bring Player", target = true },
	freeze = { min = 2, cat = "Players", label = "Freeze", target = true },
	unfreeze = { min = 2, cat = "Players", label = "Unfreeze", target = true },
	viewstats = { min = 2, cat = "Players", label = "View Stats", target = true },
	smsg = { min = 2, cat = "Server", label = "Server Message", arg = "text" },
	secretanimals = { min = 2, cat = "Game", label = "Toggle Secret Animals" },
	rubberduck = { min = 2, cat = "Game", label = "Secret Invention: Rubber Duck" },

	-- Head Moderator
	unban = { min = 3, cat = "Players", label = "Unban", arg = "user ID" },
	setrank = { min = 3, cat = "Players", label = "Set Rank", target = true, arg = "0-3" },
	givepass = { min = 3, cat = "Players", label = "Give Pass Perk", target = true, arg = "pass name" },
	lock = { min = 3, cat = "Server", label = "Lock Server" },
	unlock = { min = 3, cat = "Server", label = "Unlock Server" },
	shutdown = { min = 3, cat = "Server", label = "Shut Down This Server" },
	announce = { min = 3, cat = "Game", label = "Global Announcement", arg = "text" },
	feature = { min = 3, cat = "Game", label = "Toggle Feature", arg = "feature name" },
	liveconfig = { min = 3, cat = "Game", label = "Set Rate", arg = "GainRate 0.002" },
	election = { min = 3, cat = "Game", label = "🗳 Start Election Now" },
	invent = { min = 3, cat = "Game", label = "🔬 Global Invention Hour", arg = "teleport / space / fusion / robots / …" },
	quiz = { min = 3, cat = "Fun", label = "❓ Server Quiz" },

	-- More player tools
	pm = { min = 2, cat = "Players", label = "Private Message", target = true, arg = "text" },
	spectate = { min = 2, cat = "Players", label = "Spectate", target = true },
	unspectate = { min = 2, cat = "Players", label = "Stop Spectating" },
	jail = { min = 2, cat = "Players", label = "Jail (cage)", target = true },
	unjail = { min = 2, cat = "Players", label = "Unjail", target = true },
	respawn = { min = 2, cat = "Players", label = "Respawn", target = true },
	clearjunk = { min = 2, cat = "Server", label = "Clear Rain / Junk" },
	speed = { min = 3, cat = "Players", label = "Set Walk Speed", target = true, arg = "number (16 = normal)" },
	jump = { min = 3, cat = "Players", label = "Set Jump Power", target = true, arg = "number (50 = normal)" },
	size = { min = 3, cat = "Players", label = "Set Size", target = true, arg = "0.3 – 3" },
	coins = { min = 3, cat = "Players", label = "Give Coins", target = true, arg = "number" },
	stress = { min = 3, cat = "Players", label = "Set Stress", target = true, arg = "0 – 100" },
	embarrass = { min = 3, cat = "Players", label = "Set Embarrassment", target = true, arg = "0 – 100" },
	givegadget = { min = 3, cat = "Players", label = "Give Secret Invention", target = true, arg = "duck / coffee / pigeons / rain / boots / remote / goggles / rewind / robot" },
	skipgate = { min = 3, cat = "Players", label = "Pass Next Skill Gate", target = true },
	resettutorial = { min = 3, cat = "Players", label = "Reset Tutorial", target = true },
	bringall = { min = 3, cat = "Server", label = "Bring Everyone" },
	muteall = { min = 3, cat = "Server", label = "Mute Everyone (not staff)" },
	unmuteall = { min = 3, cat = "Server", label = "Unmute Everyone" },
	logs = { min = 3, cat = "Logs", label = "Refresh Logs" },

	-- Fun (Head Moderator and Owner)
	brainrain = { min = 3, cat = "Fun", label = "🧠 Brain Rain" },
	chicken = { min = 3, cat = "Fun", label = "🐔 Rubber Chicken" },
	laugh = { min = 3, cat = "Fun", label = "😂 Everyone Laughs" },
	narrator = { min = 3, cat = "Fun", label = "🎤 Dr. Wrinkles Says", arg = "text" },
	weather = { min = 3, cat = "Fun", label = "🌦 Weather", arg = "sun / rain / duckstorm" },
	bighead = { min = 3, cat = "Fun", label = "🎈 Big Head", target = true },
	crayon = { min = 3, cat = "Fun", label = "🖍 Crayon Avatar", target = true },
	kazoo = { min = 3, cat = "Fun", label = "🎺 Kazoo Mode" },
	confetti = { min = 3, cat = "Fun", label = "🎉 Confetti" },
	gravity = { min = 3, cat = "Fun", label = "🪐 Gravity", arg = "low / normal / high" },
	swapdoors = { min = 3, cat = "Fun", label = "🚪 Swap Door Signs" },

	-- Owner only
	shutdownall = { min = 4, cat = "Server", label = "Shut Down ALL Servers" },
	wipedata = { min = 4, cat = "Players", label = "Delete Player Data", arg = "user ID" },
	killswitch = { min = 4, cat = "Game", label = "Pause Purchases" },
}

-- Longest ban each level may give (seconds). -1 = permanent allowed.
Config.BanLimits = {
	[2] = 86400, -- Moderator: up to 1 day
	[3] = -1, -- Head Moderator: any, including permanent
	[4] = -1, -- Owner
}

-- Highest rank each level may hand out with setrank.
Config.RankGiveLimit = {
	[3] = 2, -- Head Moderator can give Tester and Moderator
	[4] = 3, -- Owner can give up to Head Moderator
}

return Config

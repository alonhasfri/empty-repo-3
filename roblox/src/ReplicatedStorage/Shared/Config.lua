-- Config: every number, ID and setting for the game lives here.
-- Fill in the "0" IDs after you create them on the Roblox Creator Dashboard.

local Config = {}

Config.GameName = "Lose a Brain Cell / Gain a Brain Cell"
Config.Version = "1.7.4"

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
-- 1.6 careers: XP to reach level 2/3/4 of a job's ladder, and the IQ each level needs:
-- job.minIQ + StartIQ + (level-1) * IQPerLevel (+ TopBonusIQ for the top level).
Config.Careers = {
	XPNeed = { 0, 4, 10, 18 }, -- total XP for level 1, 2, 3, 4 (1 XP per task done right)
	StartIQ = -14,
	IQPerLevel = 7,
	TopBonusIQ = 1,
	PayPerLevel = 0.5, -- each promotion adds +50% pay (tasks and per-minute pay)
	TaskPay = 2, -- coins per task = coinsPerMinute * TaskPay * level bonus
	ReportEvery = 3, -- a report card every 3 shifts
	PromotionDelay = 0.9,
	Uniforms = {
		cashier = Color3.fromRGB(232, 66, 63),
		office = Color3.fromRGB(59, 74, 107),
		teacher = Color3.fromRGB(47, 154, 88),
		professor = Color3.fromRGB(107, 63, 138),
		doctor = Color3.fromRGB(242, 246, 255),
		lawyer = Color3.fromRGB(32, 34, 42),
		scientist = Color3.fromRGB(230, 251, 255),
		janitor = Color3.fromRGB(90, 122, 154),
		sweeper = Color3.fromRGB(240, 138, 36),
	},
}
Config.TaxiCooldown = 8 -- (old instant taxi; now only teleport pads and the Castle Map are instant)
-- 1.7 audit (E1, E2): minigames the server can time, so a script can't skip them
Config.MinigameMinSeconds = {
	Coffee = 8, -- counting 60 beans takes longer than this
	Astro = 4, -- each astronaut training round
}

-- 1.7.2: plaza leaderboards (OrderedDataStore; every call is pcall'd, the board just rests if the store is down)
Config.Boards = {
	Refresh = 60, -- seconds between saving new scores and redrawing the boards
	WeeklyPay = { Store = "WeeklyPay", Top = 10, Pos = Vector3.new(-30, 7, 16), Facing = Vector3.new(1, 0, 0.15) }, -- left of spawn, facing it
	Speedrun = { Store = "SpeedrunIQ200", Top = 10, Pos = Vector3.new(30, 7, 16), Facing = Vector3.new(-1, 0, 0.15) }, -- right of spawn
}

-- 1.8: Life Pack life stages (only for Life Pack owners who start a new life)
Config.LifeStages = {
	SecondsPerYear = 120, -- about 2 minutes of play per year
	CrossroadsFrom = 8, -- pick your path at the fountain from this age...
	CrossroadsTo = 20, -- ...up to this age (after that you get reminders)
	LegacyAge = 80, -- retire and start a new baby who inherits a small bonus
	LegacyCoins = 50,
	Stages = {
		{ key = "baby", emoji = "👶", from = 0, to = 2, scale = 0.55, walk = 8 },
		{ key = "kinder", emoji = "🧸", from = 3, to = 5, scale = 0.7, walk = 12 },
		{ key = "kid", emoji = "🎒", from = 6, to = 12, scale = 0.82 },
		{ key = "teen", emoji = "🛹", from = 13, to = 19, scale = 0.95 },
		{ key = "adult", emoji = "💼", from = 20, to = 64, scale = 1 },
		{ key = "grandparent", emoji = "👴", from = 65, to = 999, scale = 0.97, walk = 12 },
	},
}

-- 1.8: free new places on the west (Lose) side. Free to use; the fortune odds are shown on screen.
Config.Fun = {
	Radius = 30, -- studs from the counter
	slime = { Cooldown = 20, Lose = 1.2, Gain = 0.6 },
	-- 1.8 Life Pack places (NeedsPass: owners, or anyone during their one free 2-minute preview)
	party = { Cooldown = 20, Lose = 1.5, Stress = 20, NeedsPass = true }, -- Gain: NO cells, a big stress drop
	kindergarten = { Cooldown = 20, Lose = 1, Gain = 0.5, NeedsPass = true },
	daycare = { Cooldown = 20, Lose = 0.8, Stress = 10, NeedsPass = true },
	retirement = { Cooldown = 20, Lose = 1, Gain = 0.8, NeedsPass = true },
	toystore = { Cooldown = 20, Lose = 1, Gain = 0.5, NeedsPass = true },
	PreviewSeconds = 120, -- the free Life Pack preview tour, once per player
	trampoline = { Cooldown = 15, Lose = 1, Stress = 6 },
	fortune = {
		Cooldown = 30,
		SillyLose = 0.8,
		WiseGain = 0.8,
		Odds = { -- weights add up to 100, shown exactly as percentages
			{ kind = "silly", weight = 60 },
			{ kind = "wise", weight = 30 },
			{ kind = "weird", weight = 10 },
		},
	},
}

-- 1.8: the free Phone Shop (in-game coins only)
Config.PhoneShop = {
	MaxStickers = 4,
	MaxRot = 15, -- top of the Brainrot meter (colour + 4 stickers)
	ShowCooldown = 45, -- seconds between "show off my case"
	ShowLosePerRot = 0.4, -- Lose: brain points lost per meter point
	CalmMaxRot = 1, -- Gain: a case this calm counts as relaxing
	CalmStress = 8,
	ScamPrice = 300, -- the "iBrainz 99 MEGA" (a calculator)
	ScamUseCooldown = 30,
	ScamUseLose = 1.5,
	ReportCooldown = 600, -- Gain: report the scammer once per 10 min
	ReportGain = 4,
	ShopPos = Vector3.new(-340, 0.6, 70), -- replaces a locked house on the empty west side
}

Config.VsLobbySignPos = Vector3.new(0, 9, 34) -- 1.7.3: plaza, behind the spawn

-- 1.7.3: "The Average Files" part 1 (notes + sightings). Kid-safe; Settings → Horror: Off / Spooky / Full.
Config.Horror = {
	Stage1After = 200, -- seconds on a path before the mystery starts
	Stage1AfterTalk = 70, -- ...or this soon after you talked to the Perfectly Average guy
	NotesForStage2 = 3,
	NotesForStage3 = 5,
	NoteGate = { 1, 1, 1, 2, 2, 3, 3, 1 }, -- the stage each note appears at
	NoteSpots = { -- next to existing things (found by name), so they move with the town
		{ near = "Station_library", offset = Vector3.new(3, -2.4, 3) },
		{ near = "Station_clickbait", offset = Vector3.new(-3, -2.4, 3) },
		{ near = "Station_coffee", offset = Vector3.new(3, -2.4, -3) },
		{ near = "Station_jobs", offset = Vector3.new(-3, -2.4, 3) },
		{ near = "Station_theater", offset = Vector3.new(4, -2.4, 2) },
		{ near = "Station_gate", offset = Vector3.new(-4, -2.4, 2) },
		{ near = "Station_steal", offset = Vector3.new(3, -2.4, 3) },
		{ near = "FountainBase", offset = Vector3.new(0, 1, 15) },
	},
	SightingEvery = 90, -- seconds (plus jitter) between far-away sightings, from stage 1
	SightingJitter = 60,
	SightingDistance = 70, -- studs away: always far, never in your face
	SightingSeconds = 6,
	SightingVanishAt = 35, -- walk this close and he isn't there
}

-- 1.7.3: the first "wow" of a new run (a big brain drop or boost, with a big counter)
Config.FirstWow = {
	Delay = 20, -- seconds after picking a door
	LosePoints = 3, -- about -4% of your cells
	GainPoints = 10, -- about +2% of your cells
}

Config.Bus = {
	WaitSeconds = 6, -- 1.7.2 map review: the town is ~15 s across, so a 20 s wait was slower than walking anywhere
	Cooldown = 10, -- after a trip
}
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
	-- 1.8: Life Pack (create a 100-Robux pass called "Life Pack" on create.roblox.com and paste its ID here)
	LifePack = {
		id = 0,
		price = 100,
		path = "Any",
		cellsLost = 0,
		name = "Life Pack",
		desc = "Grow up from baby to grandparent: life stages, birthdays, the Crossroads Ceremony where you pick your path (age 8–20), + 5 new buildings only you can enter. The base game stays fully playable without it.",
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
	LampSpacing = 22, -- 1.7.3: warm ceiling lamps, one per this many studs
	LampHeight = 12.5,
	LampBrightness = 1.4,
	LampRange = 20,
	SpotCooldown = 4, -- seconds between uses of the same room spot (per player)
	PromptDistance = 9, -- how close you must be to use a room spot
	SeatPromptDistance = 6,
	-- brain points for the small things to do in rooms
	Actions = {
		arcade = { path = "Lose", lose = 2 },
		plushie = { path = "Lose", lose = 1.5 },
		cereal = { path = "Lose", lose = 1 },
		sleep = { path = "Lose", lose = 1.5, humanOnly = true }, -- 1.6 school
		paper = { path = "Lose", lose = 1, embarrass = 5, humanOnly = true },
	},
	BoardPoints = { Lose = 0.5, Gain = 0.3 }, -- writing on a whiteboard
	FridgeOpenAngle = 110, -- degrees
	StandUpDelay = 0.25, -- seconds between standing up from a seat and being moved
}

-- 1.6 animal forms: body size, jump height and power per animal (walk speed is in Brain.lua stages).
Config.Animals = {
	HumanJump = 7.2, -- normal jump height (studs)
	Jump = { dog = 8, fly = 16, bee = 16, mouse = 6, worm = 0, dead = 0, octopus = 4, tardigrade = 2, microbe = 0 },
	BodyScale = { dog = 1.1, fly = 0.75, bee = 0.9, mouse = 0.9, worm = 1, dead = 1 },
	Powers = { dog = "bark", fly = "buzz", bee = "buzz", worm = "dig" },
	PowerCooldown = 6, -- seconds
	BarkRadius = 40, -- studs
	BuzzUp = 55, -- upward push (studs per second)
}

-- 1.6 school (Lose path): the bell rings every BellEvery seconds for human Lose players.
Config.School = {
	FirstBellAfter = 240, -- seconds after joining
	BellEvery = 600,
	LateAfter = 90, -- seconds to reach the School before the truant officer comes
	ChaseSeconds = 30, -- survive this long and you escaped
	OfficerSpeed = 13, -- studs per second (a bit slower than you)
	OfficerStartDistance = 45,
	CatchDistance = 5,
	ClassSeconds = 60,
	CaughtEmbarrass = 10,
}

-- Unstuck button (1.5): takes you outside the building you're in, or to the nearest street.
Config.Unstuck = {
	Cooldown = 10, -- seconds
}

-- Conversation scenes (1.5). For every choice: { meter change, brain points }.
-- Brain points > 0 = gain brain cells, < 0 = lose brain cells (times BrainScale).
-- Endings: good if the meter ends >= GoodAt, bad if <= BadAt, otherwise mid.
-- Ending rewards: coins, gain, lose, path (gain on Gain / lose on Lose), stress, embarrass, idea, confetti.
Config.Conversations = {
	BrainScale = 0.6,
	GoodAt = 65,
	BadAt = 25,
	StartRadius = 14, -- you must be this close to the spot to start
	Cooldown = 3, -- seconds between conversations
	CoinRewardEvery = 600, -- 1.7.2: a scene pays coins at most once per 10 min (so talking never beats working)
	RepeatBrainFactor = 0.1, -- 1.7.3: repeating the same scene within that time gives 10% of the brain cells
	TypeSpeed = 38, -- letters per second
	SmartTypeSpeed = 60, -- smart players (IQ >= SmartIQ) read faster
	SmartIQ = 120,
	CameraTween = 0.55, -- seconds for each camera cut
	PauseAfterLine = 0.5, -- seconds after a line finishes
	OpenDelay = 0.9, -- seconds of the wide shot before the first line
	Scenes = {
		therapist = { meter = 50, allowFrozen = true,
			a = { { 15, 1 }, { -5, -1 }, { -10, 0 } }, b = { { 15, 1 }, { -10, -2 }, { 5, 0 } }, c = { { 20, 1 }, { 10, 0 }, { -10, -2 } },
			good = { stress = -45, embarrass = -30 }, mid = { stress = -15 }, bad = {} },
		doctorG = { meter = 50,
			a = { { 20, 2 }, { -25, -1 }, { -15, -1 } }, b = { { 25, 2 }, { -15, -1 }, { 5, 0 } }, c = { { 20, 1 }, { -20, 0 }, { -5, -1 } },
			good = { coins = 30 }, mid = { coins = 10 }, bad = { stress = 10 } },
		doctorL = { meter = 60,
			a = { { -5, -1 }, { -10, -2 }, { 5, 1 } }, b = { { -10, -2 }, { 10, 1 }, { -5, -1 } }, c = { { -15, -2 }, { 15, 2 }, { -5, -1 } },
			good = {}, mid = {}, bad = { lose = 2 } },
		courtL = { meter = 60,
			a = { { 15, 1 }, { -15, -2 }, { -10, -1 } }, b = { { 15, 1 }, { -15, -2 }, { -5, -1 } }, c = { { 15, 1 }, { -20, -2 }, { -10, -1 } },
			good = {}, mid = {}, bad = { embarrass = 35 } },
		courtG = { meter = 50,
			a = { { 30, 2 }, { -20, -1 }, { -10, -1 } }, b = { { 25, 2 }, { -25, -1 }, { -5, 0 } }, c = { { 25, 2 }, { -10, 0 }, { 5, 0 } },
			good = { coins = 40, gain = 2 }, mid = { coins = 10 }, bad = { stress = 15 } },
		debate = { meter = 50,
			a = { { 20, 2 }, { -10, -2 }, { 5, -1 } }, b = { { 20, 2 }, { -15, -1 }, { -5, -1 } }, c = { { 20, 1 }, { -10, -2 }, { 0, -1 } },
			good = { confetti = true }, mid = {}, bad = { embarrass = 20 } },
		journalistL = { meter = 40,
			a = { { 20, -2 }, { -15, 1 }, { 10, -1 } }, b = { { 15, -2 }, { -10, 2 }, { 5, -1 } }, c = { { 20, -2 }, { -15, 1 }, { 10, -1 } },
			good = { lose = 3 }, mid = { lose = 1 }, bad = {} },
		journalistG = { meter = 50,
			a = { { 25, 2 }, { -20, -1 }, { -15, -1 } }, b = { { 25, 2 }, { -15, -1 }, { -5, 0 } }, c = { { 25, 2 }, { -20, -1 }, { -5, 0 } },
			good = { coins = 30, gain = 1.5 }, mid = { coins = 10 }, bad = { stress = 10 } },
		election = { meter = 40,
			a = { { 20, 0 }, { -15, -1 }, { 10, 0 } }, b = { { 20, 1 }, { 5, -1 }, { -15, -1 } }, c = { { 20, 1 }, { -5, -1 }, { 15, 0 } },
			good = { confetti = true, path = 3 }, mid = {}, bad = {} },
		classroomL = { meter = 60, noAnimals = true, -- 1.6: no animals in school
			a = { { -15, -2 }, { 15, 2 }, { -10, -2 } }, b = { { -10, -2 }, { 15, 2 }, { -15, -1 } }, c = { { -10, -2 }, { 15, 2 }, { -15, -2 } },
			good = {}, mid = {}, bad = { lose = 2 } },
		classroomG = { meter = 50,
			a = { { 25, 1 }, { -10, 0 }, { -20, -1 } }, b = { { 25, 1 }, { -20, -2 }, { -10, 0 } }, c = { { 20, 1 }, { -15, 0 }, { 25, 1 } },
			good = { coins = 35, idea = 1 }, mid = { coins = 15 }, bad = { stress = 12 } },
		experiment = { meter = 40,
			a = { { 25, 1 }, { -15, -1 }, { -10, -2 } }, b = { { 25, 2 }, { -15, -1 }, { 0, 0 } }, c = { { 25, 2 }, { -10, -1 }, { -15, -2 } },
			good = { gain = 2, idea = 1 }, mid = { gain = 0.5 }, bad = {} },
	},
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
	schoolbell = { min = 1, cat = "Game", label = "🔔 Ring the School Bell (1.6)", target = true },
	lifepack = { min = 4, cat = "Players", label = "👶 Give Life Pack (testing, owner only)", target = true },

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

---------------------------------------------------------------------
-- 1.7: Brain-scaled UI, life systems and map (see docs/Brain scaled UI and map design.md)
---------------------------------------------------------------------
Config.UI = {
	BigDeltaShare = 0.02, -- 1.7.3: a brain change this big (share of your cells) gets the big centre counter
	MinDeviceScale = 0.7, -- the whole HUD never shrinks below this on small phones
	PhoneShortSide = 500, -- a screen whose short side is under this many pixels counts as a phone
	MinPhoneText = 14, -- smallest text size on phones
	MinTouch = 48, -- smallest tappable button (pixels), Google's 48dp rule
	LandscapePhoneAspect = 1.05, -- the in-game phone on a sideways phone screen (portrait 0.52 is only ~146 px wide there)
}

-- Which phone you get. IQ only matters on the Gain path; the Lose path always gets the toy phone.
Config.PhoneTiers = {
	CozyIQ = 95, -- clean 3x3 phone
	RealIQ = 120, -- full phone OS: status bar, swipe pages, Hoppr, Brain Bank, Shifts
}

Config.Life = {
	Ride = { -- Hoppr ride-hail (every ride is paid with coins you earn in-game, never Robux)
		BaseFare = 4,
		PerHundredStuds = 3,
		BusyMultiplier = 1.5, -- busy hours: shown BEFORE you confirm, never random
		BusyEverySeconds = 600, -- busy for the first 2 minutes of every 10 minutes
		BusyLengthSeconds = 120,
		EtaMin = 3, -- seconds until the car arrives
		EtaMax = 7,
		RideSeconds = 3, -- the short ride scene
		Cooldown = 4,
		MaxFriends = 3, -- 1.7.3: group rides: up to 3 friends can join one Hoppr ride
		GroupRadius = 20, -- studs: friends this close to the booker get an invite
	},
	Shift = {
		EverySeconds = 300, -- a shift starts every 5 minutes (on the real clock)
		GraceSeconds = 60, -- clock in up to 60 s after the start and you're on time
		OnTimeBonus = 15, -- coins, paid on your payslip
		MinShiftSeconds = 60, -- clock out after at least 1 minute for a payslip
		BonusMinTasks = 1, -- the on-time bonus needs at least this many tasks done on the shift
		WagesNeedShift = true, -- per-minute wages are only paid while clocked in AND at the workplace
	},
	Bank = {
		SavingsRatePercent = 0.5, -- fixed and shown: +0.5% of the LOWEST savings balance since the last tick...
		InterestEverySeconds = 600, -- ...every 10 minutes you're online
		MaxInterestPerTick = 25, -- so saving never beats working (best job pays 20/min)
		MaxMove = 1e9, -- biggest single save or take (anything bigger is refused)
		Bill = 10, -- "harder life" only (opt-in): a small bill every interest tick, never goes below 0
	},
}

Config.LoseFX = {
	AdEverySeconds = 75, -- silly fake ads (jokes only, never real purchases) on the Lose path
	AdMinCells = 0, -- ads stop while you're an animal (no reading)
	LagSeconds = 0.25, -- "brain lag" before a phone app opens at full intensity
	WarnSeconds = 1.2, -- the "uh oh…" warning shows this long before an effect
	ScrambleBelowCells = 45e9, -- app labels scramble below this (icons always stay right)
}

Config.Map = {
	LandmarkHeight = 70, -- the Brain Tower in the plaza, seen from every street
	TrailSeconds = 20, -- animal smell trail lasts this long
	SmallDecorSize = 2, -- parts this small (every side) lose shadows and collision (phone speed)
	NoShadowSize = 4, -- parts this small lose shadows
	-- Lighting per look. Roblox only lets Studio change Lighting.LightingStyle (scripts get
	-- "lacking capability PluginOrOpenCloud"), so the low-brain looks get their soft feel from
	-- these instead (soft = cute/cash-grab/cozy/nonsense, sharp = realistic/fancy/future).
	GrassColor = Color3.fromRGB(104, 178, 70), -- 1.7.3: bright natural green terrain grass
	EdgeWallHeight = 120, -- 1.7.4: invisible walls at the edge of the ground
	SoftLight = { ShadowSoftness = 0.9, EnvironmentDiffuseScale = 0.35, EnvironmentSpecularScale = 0.15 },
	SharpLight = { ShadowSoftness = 0.2, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1 },
}

return Config

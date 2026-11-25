-- Badges: the ONE combined list of every badge in the game.
-- Create each badge on create.roblox.com (your experience -> Engagement -> Badges)
-- and paste its ID into "id". Badges with id = 0 are tracked in save data only.
-- "version" = which update the badge arrives in.

local Badges = {
	-- Lose path
	SmoothBrain = { id = 0, version = "1.0", secret = false, name = "Certified Smooth Brain", desc = "Reach 0 brain cells." },
	ReadTOS = { id = 0, version = "1.0", secret = true, name = "Read the Terms of Service", desc = "Actually read the whole Terms of Service." },
	ClickedEverything = { id = 0, version = "1.0", secret = true, name = "Clicked Every Clickbait", desc = "Click 25 clickbait headlines." },
	Ratiod = { id = 0, version = "1.0", secret = false, name = "Ratio'd", desc = "Go viral 5 times with dumb comments." },
	WhereAmI = { id = 0, version = "1.0", secret = true, name = "Where am I?", desc = "Become a microbe (secret animal)." },
	PerfectlyAverage = { id = 0, version = "1.0", secret = true, name = "Perfectly Average", desc = "Talk to the Perfectly Average guy." },
	Speedrun = { id = 0, version = "1.0", secret = false, name = "Speedrun Smooth Brain", desc = "Reach 0 brain cells in under 60 minutes." },

	-- Gain path
	Gate1 = { id = 0, version = "1.0", secret = false, name = "The Average Gate", desc = "Pass the first Skill Gate." },
	Gate2 = { id = 0, version = "1.0", secret = false, name = "The Coder's Gate", desc = "Pass the second Skill Gate." },
	Gate3 = { id = 0, version = "1.0", secret = false, name = "The Gifted Gate", desc = "Pass the third Skill Gate." },
	Gate4 = { id = 0, version = "1.0", secret = false, name = "The Genius Gate", desc = "Pass the fourth Skill Gate." },
	FirstJob = { id = 0, version = "1.0", secret = false, name = "Employed", desc = "Get your first job." },
	Eureka = { id = 0, version = "1.0", secret = false, name = "Eureka!", desc = "Unlock your first secret invention." },
	AllInventions = { id = 0, version = "1.0", secret = true, name = "Mad Scientist", desc = "Unlock every secret invention." },
	Coffee60 ={ id = 0, version = "1.0", secret = true, name = "Beethoven Would Be Proud", desc = "Count exactly 60 coffee beans." },

	-- Comeback (1.1, basic version already in 1.0)
	CompleteMakeover = { id = 0, version = "1.1", secret = true, name = "Complete Makeover", desc = "Gain back your brain cells from zero." },

	-- Later updates (listed so everything is in one place)
	Inventor = { id = 0, version = "1.3", secret = false, name = "Inventor", desc = "Finish a Major Project." },
	FirstInvented = { id = 0, version = "1.3", secret = false, name = "First Invented", desc = "Be the first player ever to invent something." },
	RefusedPrize = { id = 0, version = "1.3", secret = true, name = "Perelman", desc = "Refuse your Noble Prize." },
	MaybeNextTime = { id = 0, version = "1.3", secret = true, name = "Maybe Next Time", desc = "Fail the Time Machine 10 times." },
	WorldsSmartest = { id = 0, version = "1.4", secret = true, name = "World's Smartest", desc = "Reach 200 IQ." },
	TooMuchBrain = { id = 0, version = "1.4", secret = true, name = "Too Much Brain", desc = "Reach 1 trillion brain cells. +1 IQ. Worth it?" },
	LostAndFound = { id = 0, version = "1.4", secret = true, name = "Lost and Found", desc = "Solve the Endless Castle." },
	SmallTalk = { id = 0, version = "1.5", secret = false, name = "Small Talk", desc = "Finish a conversation scene." },
	FooledYou ={ id = 0, version = "event", secret = false, name = "Fooled You", desc = "Find the April Fools rubber chicken." },
	-- 1.9 Genius Crossroads: finish a genius storyline
	GeniusMath = { id = 0, version = "1.9", secret = false, name = "Vault Cracker", desc = "Finish the Math genius story." },
	GeniusPhysics = { id = 0, version = "1.9", secret = false, name = "Moonshot", desc = "Finish the Physics genius story." },
	GeniusCoding = { id = 0, version = "1.9", secret = false, name = "Bug Squasher", desc = "Finish the Coding genius story." },
	GeniusBusiness = { id = 0, version = "1.9", secret = false, name = "Lemonade Tycoon", desc = "Finish the Business genius story." },
	GeniusChess = { id = 0, version = "1.9", secret = false, name = "Grand Brain Champion", desc = "Finish the Chess genius story." },
}

return Badges

-- BrainService: brain cells, IQ, stages, meters, badges, narrator and character looks.

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Brain = require(Shared.Brain)
local Badges = require(Shared.Badges)
local Content = require(Shared.Content)
local Narration = require(Shared.Narration)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local AnimalForms = require(script.Parent.AnimalForms)

local BrainService = {}

BrainService.secretAnimals = false
BrainService.hooks = {} -- onDeath(player), onPathReset(player)
BrainService.boost = { Gain = 1, Lose = 1 } -- election boosts (update 1.2)
BrainService.spaceInvented = function()
	return false
end -- set by SpaceService (update 1.4)
BrainService.isAstronaut = function(_player)
	return false
end -- set by SpaceService (update 1.4)

-- Endless Castle reward (update 1.4): 2x speed in YOUR path's direction for 30 minutes
local function castleMult(data): number
	return (data.castleBoostUntil or 0) > os.time() and 2 or 1
end
BrainService.extraSpeed = function()
	return 0
end -- set by ProjectService (superconductor invention)

local runtime = {} -- [player] = { hidingUntil, frozen, lastStage, lastTier, gateNotified, dirty }

local function rt(player)
	local r = runtime[player]
	if not r then
		r = { hidingUntil = 0, frozen = false, lastStage = nil, lastTier = nil, gateNotified = false, dirty = true }
		runtime[player] = r
	end
	return r
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
function BrainService.data(player)
	return DataService.get(player)
end

function BrainService.feature(name: string): boolean
	return Config.Features[name] ~= false
end

function BrainService.toast(player, text, sound)
	Net.send(player, "toast", { text = text, sound = sound })
end

function BrainService.narrate(player, event)
	local data = DataService.get(player)
	if not data then
		return
	end
	local mood = Brain.narratorMood(data.cells)
	Net.send(player, "narrator", { text = Narration.line(mood, event), mood = mood })
end

function BrainService.say(player, text)
	local data = DataService.get(player)
	local mood = data and Brain.narratorMood(data.cells) or "host"
	Net.send(player, "narrator", { text = text, mood = mood })
end

function BrainService.awardBadge(player, badgeKey: string)
	local data = DataService.get(player)
	local badge = Badges[badgeKey]
	if not data or not badge or data.badges[badgeKey] then
		return
	end
	data.badges[badgeKey] = true
	if badge.id and badge.id > 0 then
		task.spawn(function()
			pcall(function()
				BadgeService:AwardBadge(player.UserId, badge.id)
			end)
		end)
	end
	Net.send(player, "badge", { name = badge.name, desc = badge.desc })
end

---------------------------------------------------------------------
-- Gates
---------------------------------------------------------------------
function BrainService.nextGate(player)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" or not BrainService.feature("Gates") then
		return nil
	end
	for _, gate in ipairs(Config.Gates) do
		if not data.gatesPassed[gate.id] then
			return gate
		end
	end
	return nil
end

function BrainService.gateCap(player): number?
	local gate = BrainService.nextGate(player)
	if gate then
		return Brain.cellsForIQ(gate.iq)
	end
	return nil
end

function BrainService.resetGateNotice(player)
	rt(player).gateNotified = false
end

function BrainService.atGate(player): boolean
	local cap = BrainService.gateCap(player)
	local data = DataService.get(player)
	return cap ~= nil and data ~= nil and data.cells >= cap - 1
end

---------------------------------------------------------------------
-- Glasses
---------------------------------------------------------------------
function BrainService.currentGlasses(player)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" then
		return nil
	end
	local iq = Brain.iq(data.cells)
	local best = nil
	for _, g in ipairs(Content.Glasses) do
		if iq >= g.minIQ then
			best = g
		end
	end
	return best
end

---------------------------------------------------------------------
-- State sent to the client
---------------------------------------------------------------------
function BrainService.state(player)
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local r = rt(player)
	local cells = data.cells
	local stage = Brain.stage(cells, BrainService.secretAnimals)
	local mult, multLabel = Brain.gainMultiplier(cells)
	local gate = BrainService.nextGate(player)
	local glasses = BrainService.currentGlasses(player)
	local job, jobPlace = nil, nil
	for _, j in ipairs(Content.Jobs) do
		if j.id == data.job then
			job, jobPlace = j.name, j.place
		end
	end
	return {
		jobPlace = jobPlace, -- 1.7.2: the "What do I do now?" guide points at Work_<jobPlace>
		runStart = data.runStart, -- 1.7.3: the optional speedrun timer counts from here (server time)
		badges = data.badges, -- 1.7.3: the badge checklist in Settings
		life = BrainService.hooks.lifeInfo and BrainService.hooks.lifeInfo(data) or nil, -- 1.8: Life Pack age/stage
		career = BrainService.hooks.careerInfo and BrainService.hooks.careerInfo(data) or nil, -- 1.9: the progress path strip
		eventInvite = data.eventInvite, -- 1.9 big life events (nil for old saves)
		geniusOpen = (BrainService.hooks.geniusOpen and BrainService.hooks.geniusOpen(data)) or nil, -- 1.9 Genius Crossroads
		genius = data.genius,
		eventsDone = (typeof(data.eventsDone) == "table" and #data.eventsDone > 0) and #data.eventsDone or nil,
		serverNow = os.time(),
		cells = cells,
		cellsText = Brain.shortNumber(cells),
		path = data.path,
		iq = Brain.iq(cells),
		iqText = Brain.iqText(cells, data.path),
		rarity = Brain.rarityText(cells, data.path),
		tier = Brain.artTier(cells),
		mood = Brain.narratorMood(cells),
		stage = stage.key,
		stageName = stage.name,
		stageEmoji = stage.emoji,
		mult = mult,
		multLabel = data.path == "Gain" and multLabel or "",
		embarrass = data.embarrass,
		meterBroken = data.path == "Lose" and cells < Config.Embarrassment.BreaksBelowCells,
		hiding = os.clock() < r.hidingUntil,
		stress = data.stress,
		frozen = r.frozen,
		coins = data.coins,
		job = job,
		glasses = glasses and glasses.name or nil,
		glassesDesc = glasses and glasses.desc or nil,
		gate = gate and gate.name or nil,
		atGate = BrainService.atGate(player),
		rank = player:GetAttribute("Rank") or 0,
		settings = data.settings,
		perks = data.perks,
		comeback = data.comeback,
		dead = data.dead == true,
		canSave = DataService.canSave(player),
		-- 1.4
		astronaut = BrainService.isAstronaut(player),
		spaceInvented = BrainService.spaceInvented(),
		retired = data.retired == true,
		smartestTitle = data.smartestTitle,
		castleMap = data.castleMap == true,
		castleBoostLeft = math.max(0, (data.castleBoostUntil or 0) - os.time()),
		overflow = data.cells > Config.OverflowCells,
		tutNotes = data.settings and data.settings.tutNotes or 0,
	}
end

function BrainService.push(player)
	rt(player).dirty = true
end

local function flush(player)
	local st = BrainService.state(player)
	if st then
		Net.send(player, "state", st)
		player:SetAttribute("BrainCells", st.cells)
		player:SetAttribute("Path", st.path)
		player:SetAttribute("ArtTier", st.tier)
		player:SetAttribute("Stage", st.stage)
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			ls["Brain Cells"].Value = st.cellsText
			ls.Path.Value = st.path or "Lobby"
		end
	end
	rt(player).dirty = false
end

---------------------------------------------------------------------
-- Character looks: animal stage, scale, glasses, labels
---------------------------------------------------------------------
local function makeOverhead(player, char)
	local head = char:FindFirstChild("Head")
	if not head then
		return nil
	end
	local gui = head:FindFirstChild("Overhead")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "Overhead"
		gui.Size = UDim2.new(8, 0, 1.4, 0) -- studs, so it shrinks with distance
		gui.StudsOffset = Vector3.new(0, 2.4, 0)
		gui.AlwaysOnTop = false
		gui.MaxDistance = 80
		gui.Parent = head
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextStrokeTransparency = 0.4
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
	end
	return gui
end

local function weldTo(part, head, offset)
	part.CanCollide = false
	part.Massless = true
	part.Anchored = false
	part.CFrame = head.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
	part.Parent = head.Parent
end

function BrainService.applyCharacter(player)
	local char = player.Character
	local data = DataService.get(player)
	if not char or not data then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")
	if not humanoid or not head then
		return
	end
	local stage = Brain.stage(data.cells, BrainService.secretAnimals)
	if data.cells > 0 and humanoid.Health > 0 then
		humanoid.WalkSpeed = (rt(player).frozen and Config.Stress.FrozenWalk) or (stage.walk + BrainService.extraSpeed()) -- 1.8.8: slow, never 0
	end

	-- scale (animals are smaller)
	local wantScale = stage.scale
	if char:GetAttribute("AppliedScale") ~= wantScale then
		char:SetAttribute("AppliedScale", wantScale)
		pcall(function()
			char:ScaleTo(wantScale)
		end)
	end

	-- Overflow zone (1.4): too much brain, your head gets HUGE
	local headScale = humanoid:FindFirstChild("HeadScale")
	if headScale and headScale:IsA("NumberValue") then
		local want = 1
		if data.path == "Gain" and data.cells > Config.OverflowCells then
			want = math.clamp(1 + math.log10(data.cells / Config.OverflowCells) * 2, 1, 3)
		end
		if math.abs(headScale.Value - want) > 0.05 then
			headScale.Value = want
		end
	end

	-- glasses (Gain path)
	local old = char:FindFirstChild("BrainGlasses")
	if old then
		old:Destroy()
	end
	local glasses = BrainService.currentGlasses(player)
	if glasses then
		local g = Instance.new("Part")
		g.Name = "BrainGlasses"
		g.Size = Vector3.new(1.1, 0.25, 0.1) * (char:GetAttribute("AppliedScale") or 1)
		g.Color = glasses.color
		g.Material = Enum.Material.SmoothPlastic
		weldTo(g, head, CFrame.new(0, 0.15, -0.6 * (char:GetAttribute("AppliedScale") or 1)))
	end

	-- dunce cap (BUY BRAIN pass or the joke shop)
	local cap = char:FindFirstChild("DunceCap")
	if data.perks.DunceCap and not cap then
		local c = Instance.new("Part")
		c.Name = "DunceCap"
		c.Size = Vector3.new(0.8, 1.6, 0.8)
		c.Color = Color3.new(1, 1, 1)
		c.Material = Enum.Material.SmoothPlastic
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.Parent = c
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "D"
		t.TextScaled = true
		t.Font = Enum.Font.GothamBlack
		t.Parent = sg
		weldTo(c, head, CFrame.new(0, 1.2, 0))
	end

	-- Comeback "scars of stupidity": a bandage from all that wall-walking
	if data.comeback and not char:FindFirstChild("Bandage") then
		local b = Instance.new("Part")
		b.Name = "Bandage"
		b.Size = Vector3.new(0.9, 0.3, 0.2)
		b.Color = Color3.fromRGB(245, 220, 190)
		b.Material = Enum.Material.Fabric
		weldTo(b, head, CFrame.new(0.3, 0.45, -0.6) * CFrame.Angles(0, 0, math.rad(30)))
	elseif not data.comeback and char:FindFirstChild("Bandage") then
		char.Bandage:Destroy()
	end

	-- 1.6: physically become the animal (blocky body, avatar hidden) and move like one
	AnimalForms.apply(char, stage.key)
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = Config.Animals.Jump[stage.key] or Config.Animals.HumanJump

	-- punishment sign from court (update 1.2)
	local punished = player:GetAttribute("PunishSign")

	-- overhead label: rank tag, animal stage, VIP
	local gui = makeOverhead(player, char)
	if gui then
		local parts = {}
		local rank = player:GetAttribute("Rank") or 0
		if rank > 0 then
			table.insert(parts, "[" .. Config.RankNames[rank] .. "]")
		end
		if data.perks.VIPLibrary then
			table.insert(parts, "[VIP]")
		end
		if stage.key ~= "human" then
			table.insert(parts, stage.emoji .. " " .. stage.name)
		end
		if data.smartestTitle then
			table.insert(parts, "\n👑 World's Smartest " .. tostring(data.smartestTitle))
		elseif data.astronaut and data.path == "Gain" then
			table.insert(parts, "[🧑‍🚀 Astronaut]")
		end
		if punished then
			table.insert(parts, "\n📋 " .. tostring(punished))
		end
		gui.Text.Text = table.concat(parts, " ")
		gui.Text.TextColor3 = Config.RankColors[rank] or Color3.new(1, 1, 1)
	end
end

---------------------------------------------------------------------
-- After any brain cell change
---------------------------------------------------------------------
local function afterChange(player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local r = rt(player)
	local stage = Brain.stage(data.cells, BrainService.secretAnimals)
	local tier = Brain.artTier(data.cells)

	if r.lastStage and r.lastStage ~= stage.key then
		BrainService.narrate(player, "stage")
		local form = Content.Animals.Forms[stage.key]
		if form and stage.key ~= "dead" then -- (at 0 the death ending plays instead)
			-- 1.6: the transformation moment (with a tip about the new body)
			Net.send(player, "transform", { emoji = stage.emoji, name = stage.name, sub = form.sub, tip = form.tip, power = Config.Animals.Powers[stage.key] })
		elseif stage.key ~= "human" and stage.key ~= "dead" then
			BrainService.toast(player, "You are now: " .. stage.emoji .. " " .. stage.name, "CartoonBoing")
		end
		if BrainService.hooks.onStageChange then
			task.spawn(BrainService.hooks.onStageChange, player)
		end
		if stage.key == "microbe" then
			BrainService.awardBadge(player, "WhereAmI")
		end
		BrainService.applyCharacter(player)
	end
	if r.lastTier and r.lastTier ~= tier then
		BrainService.applyCharacter(player)
	end
	-- Lose path: meter breaks when you're too dumb to care
	if data.path == "Lose" and data.cells < Config.Embarrassment.BreaksBelowCells and not data.meterBrokenShown then
		data.meterBrokenShown = true
		data.embarrass = 0
		BrainService.narrate(player, "meterBroken")
	end
	-- Comeback (update 1.1): friends apologize at milestones, then Complete Makeover
	if data.comeback and data.path == "Gain" then
		local iq = Brain.iq(data.cells)
		data.apologies = data.apologies or {}
		local APOLOGIES = {
			{ iq = 85, lines = { "wait… you can read now?", "ok that's actually kinda cool", "sorry we laughed 😅" } },
			{ iq = 100, lines = { "you're AVERAGE now?!", "we were wrong about you", "sorry for filming you 📸" } },
			{ iq = 115, lines = { "you're smarter than us 😳", "sorry, for real", "teach me?" } },
			{ iq = 130, lines = { "can u help with my homework?", "pls 🙏", "we're proud of you" } },
		}
		for _, a in ipairs(APOLOGIES) do
			if iq >= a.iq and not data.apologies[tostring(a.iq)] then
				data.apologies[tostring(a.iq)] = true
				Net.send(player, "friendVisit", { lines = a.lines, seconds = 12 })
			end
		end
		if iq >= Config.ComebackMakeoverIQ and not data.badges.CompleteMakeover then
			BrainService.awardBadge(player, "CompleteMakeover")
			Net.send(player, "makeover", { cells = Brain.formatNumber(data.cells), iq = math.floor(iq) })
			Net.broadcast("announce", { text = player.DisplayName .. " completed their COMPLETE MAKEOVER! 🧠✨ (0 → genius)", by = "Dr. Wrinkles", global = false })
		end
	end
	-- Update 1.4: Astronaut at 160, World's Smartest at 200, the Overflow zone
	if data.path == "Gain" and not data.dead then
		local iq = Brain.iq(data.cells)
		if iq >= Config.Space.AstronautIQ and not data.astroNotified and BrainService.hooks.onAstronautIQ then
			data.astroNotified = true
			task.spawn(BrainService.hooks.onAstronautIQ, player)
		end
		if iq >= Config.Space.SmartestIQ and not data.worldsSmartest and BrainService.hooks.onSmartest then
			data.worldsSmartest = true
			task.spawn(BrainService.hooks.onSmartest, player)
			-- 1.7.3: speedrun board (server-timed from the start of this run; the client can't send a time)
			local secs = math.max(1, os.time() - (data.runStart or os.time()))
			if not data.bestIQ200Seconds or secs < data.bestIQ200Seconds then
				data.bestIQ200Seconds = secs
			end
			if not data.adminTouched then -- admin-set brains never reach the boards
				require(script.Parent.BoardService).submitBest("Speedrun", player, secs)
			end
		end
		if data.cells >= 257e9 and not data.elephantJoke then
			data.elephantJoke = true
			BrainService.toast(player, "🐘 Congrats, you're as smart as an elephant. Wait…", "CartoonBoing")
		end
		if data.cells >= 1e12 and not data.badges.TooMuchBrain then
			BrainService.awardBadge(player, "TooMuchBrain")
			BrainService.toast(player, "🧠🧠🧠 1 TRILLION brain cells. +1 IQ. Worth it?", "BadgeSparkle")
		end
		if data.cells > Config.OverflowCells and not r.overflowHead then
			r.overflowHead = true
			BrainService.applyCharacter(player)
		end
	end
	if r.overflowHead and data.cells > Config.OverflowCells then
		local bucket = math.floor(math.log10(data.cells / Config.OverflowCells) * 10)
		if bucket ~= r.headBucket then
			r.headBucket = bucket
			BrainService.applyCharacter(player)
		end
	end
	r.lastStage = stage.key
	r.lastTier = tier
	BrainService.push(player)

	if data.path == "Lose" and data.cells <= 0 and not data.dead then
		data.cells = 0
		data.dead = true
		if BrainService.hooks.onDeath then
			task.spawn(BrainService.hooks.onDeath, player)
		end
	end
end

---------------------------------------------------------------------
-- Changing brain cells
---------------------------------------------------------------------
-- Gain points: the "good" direction for Gain players, the "bad" one for Lose players.
function BrainService.gain(player, points: number, reason: string?)
	local data = DataService.get(player)
	if not data or data.dead then
		return 0
	end
	local amount
	if data.path == "Gain" then
		local mult = Brain.gainMultiplier(data.cells)
		local glasses = BrainService.currentGlasses(player)
		local boost = glasses and glasses.boost or 1
		if reason == "library" and data.perks.VIPLibrary then
			boost *= 1.1
		end
		amount = math.max(1, data.cells * Config.Rates.GainRate) * mult * points * boost * BrainService.boost.Gain * castleMult(data)
		local cap = BrainService.gateCap(player)
		if cap and data.cells + amount > cap then
			amount = math.max(0, cap - data.cells)
			if not rt(player).gateNotified then
				rt(player).gateNotified = true
				BrainService.toast(player, "🚧 A Skill Gate blocks your way! Go to the Skill Gate to continue.", "NotificationPing")
			end
		end
	else
		amount = math.max(1, data.cells * Config.Rates.LoseRate) * points
	end
	data.cells += amount
	if amount >= 1 then
		Net.send(player, "delta", { amount = amount, up = true })
	end
	afterChange(player)
	return amount
end

-- Lose points: the goal on the Lose path.
function BrainService.lose(player, points: number, reason: string?)
	local data = DataService.get(player)
	if not data or data.dead then
		return 0
	end
	local amount
	if data.path == "Lose" then
		amount = math.max(data.cells * Config.Rates.LoseRate * points, Config.Rates.MinLoss * points) * BrainService.boost.Lose * castleMult(data)
	else
		amount = data.cells * 0.002 * points
	end
	amount = math.min(amount, data.cells)
	data.cells -= amount
	if amount >= 1 then
		Net.send(player, "delta", { amount = amount, up = false })
	end
	afterChange(player)
	return amount
end

function BrainService.setCells(player, value: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.cells = math.max(0, value)
	if data.cells > 0 then
		data.dead = false
	end
	rt(player).gateNotified = false
	afterChange(player)
	BrainService.applyCharacter(player)
end

-- Start or restart a path
function BrainService.startPath(player, path: string, comeback: boolean?)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.path = path
	data.dead = false
	data.comeback = comeback == true
	data.meterBrokenShown = false
	data.embarrass = 0
	data.stress = 0
	data.runStart = os.time()
	data.gatesPassed = {}
	data.job = nil
	data.astroNotified = nil
	data.worldsSmartest = nil
	data.retired = nil
	data.elephantJoke = nil
	data.astroTrained = nil
	if path == "Lose" then
		data.cells = Config.LoseStartCells
	elseif comeback then
		data.cells = 1
	else
		data.cells = Config.GainStartCells
	end
	local r = rt(player)
	r.gateNotified = false
	r.frozen = false
	r.hidingUntil = 0
	r.lastStage = nil
	r.lastTier = nil
	r.overflowHead = nil
	r.headBucket = nil
	afterChange(player)
	BrainService.applyCharacter(player)
	if BrainService.hooks.onPathReset then
		BrainService.hooks.onPathReset(player)
	end
	-- 1.7.3: a big "wow" moment within the first minute of a new run (YouTuber panel: faster first hook)
	local runId = data.runStart
	local FW = Config.FirstWow
	if FW and not comeback then
		task.delay(FW.Delay, function()
			local d = DataService.get(player)
			if not d or d.dead or d.runStart ~= runId or d.path ~= path then
				return -- left, died, or started another run meanwhile
			end
			if path == "Lose" then
				BrainService.lose(player, FW.LosePoints, "firstWow")
			else
				BrainService.gain(player, FW.GainPoints, "firstWow")
			end
			Net.send(player, "firstWow", { up = path == "Gain" })
		end)
	end
end

---------------------------------------------------------------------
-- Meters
---------------------------------------------------------------------
function BrainService.embarrass(player, amount: number, moment: string?)
	local data = DataService.get(player)
	if not data or data.path ~= "Lose" or data.cells < Config.Embarrassment.BreaksBelowCells then
		return
	end
	data.embarrass = math.clamp(data.embarrass + amount, 0, Config.Embarrassment.Max)
	if moment then
		table.insert(data.embarrassingMoments, 1, moment)
		while #data.embarrassingMoments > 3 do
			table.remove(data.embarrassingMoments)
		end
	end
	Net.send(player, "friendsLaugh", {})
	BrainService.narrate(player, "embarrassed")
	local r = rt(player)
	if data.embarrass > Config.Embarrassment.HideAt and os.clock() >= r.hidingUntil then
		r.hidingUntil = os.clock() + Config.Embarrassment.HideSeconds
		BrainService.narrate(player, "hiding")
		Net.send(player, "hide", { seconds = Config.Embarrassment.HideSeconds })
	end
	BrainService.push(player)
end

function BrainService.stress(player, amount: number)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" then
		return
	end
	data.stress = math.clamp(data.stress + amount, 0, Config.Stress.Max)
	local r = rt(player)
	if data.stress >= Config.Stress.FreezeAt and not r.frozen then
		r.frozen = true
		BrainService.narrate(player, "stressed")
		BrainService.toast(player, string.format(Content.StressFreeze.Frozen, Config.Stress.FreezeSeconds), "SadTrombone")
		BrainService.applyCharacter(player)
		-- 1.8.8 fix (user: "sometimes you get stuck and can't move"): the freeze used to last until a habit
		-- calmed you down, but you couldn't walk to one. Now it always ends by itself after a few seconds.
		local myFreeze = os.clock()
		r.frozenAt = myFreeze
		task.delay(Config.Stress.FreezeSeconds, function()
			local d2 = DataService.get(player)
			if player.Parent and d2 and r.frozen and r.frozenAt == myFreeze then
				d2.stress = math.min(d2.stress, Config.Stress.CalmTo)
				r.frozen = false
				BrainService.toast(player, Content.StressFreeze.Calm, "LibrarianChime")
				BrainService.applyCharacter(player)
				BrainService.push(player)
			end
		end)
	elseif r.frozen and data.stress <= 70 then
		r.frozen = false
		BrainService.toast(player, "😌 You feel calm again.", "LibrarianChime")
		BrainService.applyCharacter(player)
	end
	BrainService.push(player)
end

-- Returns a reason string if the player can't do activities right now.
function BrainService.blocked(player): string?
	local data = DataService.get(player)
	if not data then
		return "Loading…"
	end
	if data.dead then
		return "You're dead. (You won!)"
	end
	local r = rt(player)
	if os.clock() < r.hidingUntil then
		return "You're hiding behind a bush from embarrassment!"
	end
	if r.frozen then
		return "😵 You're too stressed for a few seconds. Breathe… or do a habit."
	end
	return nil
end

-- 1.5: frozen from stress? (the therapist still lets you in)
function BrainService.isFrozen(player): boolean
	return rt(player).frozen == true
end

---------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------
function BrainService.setup(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cellsValue = Instance.new("StringValue")
	cellsValue.Name = "Brain Cells"
	cellsValue.Parent = ls
	local pathValue = Instance.new("StringValue")
	pathValue.Name = "Path"
	pathValue.Parent = ls
	ls.Parent = player

	rt(player)
	afterChange(player)
	flush(player)
end

function BrainService.cleanup(player)
	runtime[player] = nil
end

function BrainService.start()
	-- meter decay + pushing state to clients
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.get(player)
				local r = runtime[player]
				if data and r then
					if data.path == "Lose" and data.embarrass > 0 then
						data.embarrass = math.max(0, data.embarrass - Config.Embarrassment.DecayPerSecond * 0.5)
						r.dirty = true
					end
					if r.dirty then
						flush(player)
					end
				end
			end
		end
	end)
end

return BrainService

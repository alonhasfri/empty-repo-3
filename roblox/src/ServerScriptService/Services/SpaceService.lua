-- SpaceService (update 1.4: Space and secrets)
--   * Astronaut job: IQ 160+ AND Space Travel has been invented by anyone, ever
--     (or the honest 100 R$ Early Access pass, only offered while nobody has invented it)
--   * Launch Pad east of town -> rocket launch -> the Moon (low gravity)
--   * Space Lab: astronaut training minigames, Space Gates, space-only Major Projects
--   * World's Smartest (IQ 200): cutscene, title choice, badge, statue, Retired Genius
--   * Retired Genius: random people walk up and ask you questions

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Brain = require(Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local ProjectService = require(script.Parent.ProjectService)
local Props = require(script.Parent.Props)

local SpaceService = {}

-- The Moon is far away from town (absolute position, not scaled)
local MOON = Vector3.new(6000, 1500, 0)
SpaceService.MoonCenter = MOON
local MOON_RADIUS = 160
local PAD_RAW = Vector3.new(400, 0.6, 0)

local folder = Instance.new("Folder")
folder.Name = "Space"
folder.Parent = workspace

local smartestStore = nil
pcall(function()
	smartestStore = DataStoreService:GetDataStore("BrainWorldsSmartest_v1")
end)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or folder
	return p
end

local function sign(cf: CFrame, text: string, size: Vector3?, color: Color3?)
	local p = part({ Name = "SpaceSign", Size = size or Vector3.new(14, 3, 0.4), CFrame = cf, Color = color or Color3.fromRGB(25, 30, 45), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local sg = Instance.new("SurfaceGui")
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.fromRGB(220, 240, 255)
	l.Text = text
	l.Parent = sg
	return p
end

local function prompt(p: BasePart, action: string, object: string, fn)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0.3
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 14
	pp.Parent = p
	pp.Triggered:Connect(fn)
	return pp
end

---------------------------------------------------------------------
-- Who is an Astronaut?
---------------------------------------------------------------------
local function spaceInvented(): boolean
	return ProjectService.everInvented("space")
end

local function isAstronaut(player): boolean
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" or data.dead then
		return false
	end
	if Brain.iq(data.cells) < Config.Space.AstronautIQ then
		return false
	end
	return spaceInvented() or data.perks.AstronautEarly == true or (data.projectsDone ~= nil and data.projectsDone.space == true)
end
SpaceService.isAstronaut = isAstronaut

local function inSpace(player): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - MOON).Magnitude < 420
end
SpaceService.inSpace = inSpace

---------------------------------------------------------------------
-- Building: Launch Pad (town) + the Moon + Space Lab
---------------------------------------------------------------------
local function rocket(cf: CFrame, parent)
	local m = Instance.new("Model")
	m.Name = "Rocket"
	m.Parent = parent or folder
	part({ Name = "Body", Shape = Enum.PartType.Cylinder, Size = Vector3.new(30, 8, 8), CFrame = cf * CFrame.new(0, 17, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 240, 245), Material = Enum.Material.Metal, Parent = m })
	part({ Name = "Stripe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 8.2, 8.2), CFrame = cf * CFrame.new(0, 24, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 90, 200), Material = Enum.Material.SmoothPlastic, Parent = m })
	part({ Name = "Nose", Shape = Enum.PartType.Ball, Size = Vector3.new(8, 8, 8), CFrame = cf * CFrame.new(0, 32, 0), Color = Color3.fromRGB(220, 40, 40), Material = Enum.Material.SmoothPlastic, Parent = m })
	part({ Name = "Window", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = cf * CFrame.new(0, 26, -3.6), Color = Color3.fromRGB(120, 200, 255), Material = Enum.Material.Glass, Transparency = 0.2, Parent = m })
	for i = 0, 3 do
		local a = i * math.pi / 2
		part({ Name = "Fin", Size = Vector3.new(0.6, 7, 4), CFrame = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 4.5, -5.5), Color = Color3.fromRGB(220, 40, 40), Material = Enum.Material.SmoothPlastic, Parent = m })
	end
	part({ Name = "Engine", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 5, 5), CFrame = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 60, 65), Material = Enum.Material.DiamondPlate, Parent = m })
	return m
end

local launchPad: BasePart = nil

local function buildLaunchPad()
	local c = WorldService.sp(PAD_RAW)
	local base = CFrame.new(c)
	launchPad = part({ Name = "LaunchPad", Size = Vector3.new(34, 1, 34), CFrame = base, Color = Color3.fromRGB(150, 150, 150), Material = Enum.Material.Concrete })
	part({ Name = "PadMark", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 16, 16), CFrame = base * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	-- gantry tower
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			part({ Name = "Gantry", Size = Vector3.new(0.8, 40, 0.8), CFrame = base * CFrame.new(12 + x * 2, 20, z * 2), Color = Color3.fromRGB(220, 90, 30), Material = Enum.Material.Metal })
		end
	end
	for y = 4, 36, 8 do
		part({ Name = "GantryBar", Size = Vector3.new(5, 0.5, 5), CFrame = base * CFrame.new(12, y, 0), Color = Color3.fromRGB(220, 90, 30), Material = Enum.Material.DiamondPlate })
	end
	rocket(base * CFrame.new(0, 0.5, 0))
	local s = sign(base * CFrame.new(0, 4, 17.5) * CFrame.Angles(0, math.pi, 0), "🚀 LAUNCH PAD\nAstronauts only (IQ 160+)", Vector3.new(16, 6, 0.4))
	prompt(s, "Launch to the Moon", "🚀 Rocket", function(player)
		SpaceService.launch(player)
	end)
	prompt(launchPad, "Launch to the Moon", "🚀 Rocket", function(player)
		SpaceService.launch(player)
	end)
	WorldService.Spots.launchpad = PAD_RAW + Vector3.new(0, 3, 28)
	table.insert(WorldService.Places, { key = "launchpad", name = "🚀 Launch Pad", path = "Gain" })
end

local moonParts = {}
local function buildMoon()
	-- ground: a huge flat disc with craters
	local ground = part({ Name = "MoonGround", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, MOON_RADIUS * 2, MOON_RADIUS * 2), CFrame = CFrame.new(MOON - Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(175, 175, 180), Material = Enum.Material.Slate })
	moonParts.ground = ground
	local rng = Random.new(1969)
	for _ = 1, 28 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(40, MOON_RADIUS - 20)
		local size = rng:NextNumber(6, 22)
		part({ Name = "Crater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, size, size), CFrame = CFrame.new(MOON + Vector3.new(math.cos(a) * r, 0.05, math.sin(a) * r)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(135, 135, 142), Material = Enum.Material.Slate, CanCollide = false })
		part({ Name = "CraterRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, size + 2, size + 2), CFrame = CFrame.new(MOON + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(195, 195, 200), Material = Enum.Material.Slate, CanCollide = false })
	end
	-- Earth in the sky
	part({ Name = "Earth", Shape = Enum.PartType.Ball, Size = Vector3.new(120, 120, 120), CFrame = CFrame.new(MOON + Vector3.new(-200, 260, -520)), Color = Color3.fromRGB(60, 120, 220), Material = Enum.Material.SmoothPlastic, CanCollide = false, CastShadow = false })
	part({ Name = "EarthLand", Shape = Enum.PartType.Ball, Size = Vector3.new(121, 70, 90), CFrame = CFrame.new(MOON + Vector3.new(-190, 270, -520)), Color = Color3.fromRGB(80, 170, 90), Material = Enum.Material.SmoothPlastic, CanCollide = false, CastShadow = false })
	-- flag
	part({ Name = "FlagPole", Size = Vector3.new(0.3, 10, 0.3), CFrame = CFrame.new(MOON + Vector3.new(30, 5, 30)), Color = Color3.fromRGB(220, 220, 220), Material = Enum.Material.Metal })
	sign(CFrame.new(MOON + Vector3.new(32.6, 8.5, 30)), "🧠 BRAINVILLE", Vector3.new(5, 3, 0.1), Color3.fromRGB(255, 255, 255)).SurfaceGui.TextLabel.TextColor3 = Color3.fromRGB(230, 60, 120)

	-- landing pad + return capsule
	local landing = CFrame.new(MOON + Vector3.new(0, 0.2, 70))
	part({ Name = "MoonPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 26, 26), CFrame = landing * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 90, 100), Material = Enum.Material.DiamondPlate })
	rocket(landing * CFrame.new(-18, 0, 0))
	local ret = sign(landing * CFrame.new(-18, 3, -6), "🌍 Back to Earth", Vector3.new(8, 2.5, 0.4))
	prompt(ret, "Fly home", "🚀 Rocket", function(player)
		SpaceService.returnHome(player)
	end)

	-- THE SPACE LAB: a glass dome with real lab furniture
	local dome = CFrame.new(MOON)
	part({ Name = "LabFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 70, 70), CFrame = dome * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(235, 238, 245), Material = Enum.Material.SmoothPlastic })
	local glass = part({ Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(72, 72, 72), CFrame = dome, Color = Color3.fromRGB(170, 220, 255), Material = Enum.Material.Glass, Transparency = 0.75, CanCollide = false, CastShadow = false })
	local _ = glass
	sign(dome * CFrame.new(0, 26, -20), "🔬 SPACE LAB", Vector3.new(20, 4, 0.4), Color3.fromRGB(20, 40, 70))
	for i, x in ipairs({ -18, 0, 18 }) do
		local bench = Props.labBench(dome * CFrame.new(x, 0.6, 8) * CFrame.Angles(0, math.pi, 0))
		bench.Parent = folder
		local _ = i
	end
	-- stations inside the dome
	local function terminal(cf: CFrame, title: string, action: string, fn)
		local t = part({ Name = "Terminal", Size = Vector3.new(4, 5, 2), CFrame = cf * CFrame.new(0, 2.5, 0), Color = Color3.fromRGB(50, 55, 70), Material = Enum.Material.Metal })
		local screen = part({ Name = "Screen", Size = Vector3.new(3.4, 2.4, 0.2), CFrame = cf * CFrame.new(0, 3.6, -1.05), Color = Color3.fromRGB(40, 200, 255), Material = Enum.Material.Neon, CanCollide = false })
		local _ = screen
		sign(cf * CFrame.new(0, 7, 0), title, Vector3.new(8, 2, 0.3))
		prompt(t, action, title, fn)
	end
	terminal(dome * CFrame.new(-22, 0.6, -14), "🧑‍🚀 Training", "Train", function(player)
		Net.send(player, "openStation", { station = "astroTraining" })
	end)
	terminal(dome * CFrame.new(0, 0.6, -24), "🚧 Space Gate", "Answer", function(player)
		Net.send(player, "openStation", { station = "spaceGate" })
	end)
	terminal(dome * CFrame.new(22, 0.6, -14), "🔬 Space Projects", "Open", function(player)
		Net.send(player, "openStation", { station = "lab" })
	end)
	-- Tesla's pigeons somehow followed you to space
	for i = 1, 5 do
		local a = i * 1.2
		local p = part({ Name = "SpacePigeon", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.2, 1.8), CFrame = dome * CFrame.new(math.cos(a) * 10, 1.4, math.sin(a) * 10 + 20), Color = Color3.fromRGB(150, 150, 165), Material = Enum.Material.SmoothPlastic })
		part({ Name = "Helmet", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = p.CFrame * CFrame.new(0, 0.6, -0.7), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false })
		if i == 1 then
			sign(p.CFrame * CFrame.new(0, 3, 0), "🐦 Tesla's pigeons. How did they get here?", Vector3.new(10, 1.6, 0.2))
		end
	end
end

-- Space project effects (shown on the Moon)
ProjectService.EFFECTS.spacefarm = function(on)
	if not on then
		return
	end
	for row = -2, 2 do
		part({ Name = "MoonLettuceBed", Size = Vector3.new(14, 1, 2.5), CFrame = CFrame.new(MOON + Vector3.new(0, 1.1, -6 + row * 3.5)), Color = Color3.fromRGB(110, 75, 50), Material = Enum.Material.Ground })
		for k = -3, 3 do
			part({ Name = "MoonLettuce", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.2, 1.4), CFrame = CFrame.new(MOON + Vector3.new(k * 2, 2, -6 + row * 3.5)), Color = Color3.fromRGB(110, 210, 90), Material = Enum.Material.Grass, CanCollide = false })
		end
	end
end
ProjectService.EFFECTS.asteroid = function(on)
	if not on then
		return
	end
	local rock = part({ Name = "Asteroid", Shape = Enum.PartType.Ball, Size = Vector3.new(40, 34, 38), CFrame = CFrame.new(MOON + Vector3.new(120, 60, -90)), Color = Color3.fromRGB(110, 95, 85), Material = Enum.Material.Rock, CanCollide = false })
	for i = 1, 12 do
		local a = i * 0.52
		part({ Name = "Ore", Size = Vector3.new(3, 3, 3), CFrame = rock.CFrame * CFrame.Angles(a, a * 2, 0) * CFrame.new(0, 0, -18), Color = Color3.fromRGB(255, 210, 90), Material = Enum.Material.Neon, CanCollide = false })
	end
end
ProjectService.EFFECTS.marshab = function(on)
	if not on then
		return
	end
	part({ Name = "MarsPlanet", Shape = Enum.PartType.Ball, Size = Vector3.new(50, 50, 50), CFrame = CFrame.new(MOON + Vector3.new(300, 140, 260)), Color = Color3.fromRGB(200, 90, 50), Material = Enum.Material.Sand, CanCollide = false, CastShadow = false })
	part({ Name = "MarsDome", Shape = Enum.PartType.Ball, Size = Vector3.new(12, 12, 12), CFrame = CFrame.new(MOON + Vector3.new(300, 166, 260)), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass, Transparency = 0.4, CanCollide = false })
end

---------------------------------------------------------------------
-- Launch / return
---------------------------------------------------------------------
local launching = {}

function SpaceService.launch(player)
	if launching[player] then
		return
	end
	local data = DataService.get(player)
	if not data then
		return
	end
	if not isAstronaut(player) then
		if data.path == "Gain" and Brain.iq(data.cells) >= Config.Space.AstronautIQ and not spaceInvented() then
			Net.send(player, "openStation", { station = "space" })
		else
			BrainService.toast(player, "🧑‍🚀 Astronauts only: Gain path, IQ " .. Config.Space.AstronautIQ .. "+, and someone has to invent 🚀 Space Travel first.", "NotificationPing")
		end
		return
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		BrainService.toast(player, blocked)
		return
	end
	launching[player] = true
	data.timesLaunched = (data.timesLaunched or 0) + 1
	Net.send(player, "launch", { first = data.timesLaunched == 1 })
	task.delay(6.5, function()
		launching[player] = nil
		local char = player.Character
		if char and player.Parent then
			char:PivotTo(CFrame.new(MOON + Vector3.new(math.random(-4, 4), 4, 66)))
			BrainService.toast(player, "🌙 Welcome to the Moon. Gravity is 1/6 here. Jump!", "LevelUp")
		end
	end)
end

function SpaceService.returnHome(player)
	local char = player.Character
	if not char then
		return
	end
	Net.send(player, "launch", { home = true })
	task.delay(3.5, function()
		if char.Parent then
			char:PivotTo(CFrame.new(WorldService.sp(PAD_RAW) + Vector3.new(0, 4, 26)))
		end
	end)
end

---------------------------------------------------------------------
-- Net
---------------------------------------------------------------------
Net.on("space_info", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local iq = Brain.iq(data.cells)
	local pass = Config.GamePasses.AstronautEarly
	return {
		ok = true,
		astronaut = isAstronaut(player),
		invented = spaceInvented(),
		iq = math.floor(iq),
		needIQ = Config.Space.AstronautIQ,
		path = data.path,
		passOwned = data.perks.AstronautEarly == true,
		-- honest: the pass is ONLY offered while nobody has invented space travel
		passOffered = (not spaceInvented()) and data.perks.AstronautEarly ~= true and data.path == "Gain" and iq >= Config.Space.AstronautIQ,
		passPrice = pass.price,
		passId = pass.id,
		trained = data.astroTrained or {},
		inSpace = inSpace(player),
	}
end)

Net.on("space_launch", function(player)
	if not WorldService.near(player, WorldService.sp(PAD_RAW), 40) then
		local data = DataService.get(player)
		if data and isAstronaut(player) then
			WorldService.teleport(player, "launchpad")
			return { ok = true, msg = "🚀 Shuttle to the Launch Pad. Walk up to the rocket and launch!" }
		end
	end
	SpaceService.launch(player)
	return { ok = true }
end)

local trainCooldown = {}
local trainStart = {} -- [userId .. key] = when the round was opened (server time)
Net.on("astro_train_start", function(player, d)
	trainStart[player.UserId .. tostring(d and d.key)] = os.clock()
	return { ok = true }
end)

Net.on("astro_train_done", function(player, d)
	local data = DataService.get(player)
	if not data or not isAstronaut(player) then
		return { ok = false, msg = "Only Astronauts can train here." }
	end
	if not inSpace(player) then
		return { ok = false, msg = "Training happens in the Space Lab on the Moon." }
	end
	local key = tostring(d.key)
	local valid = false
	for _, t in ipairs(Content.AstroTraining) do
		if t.key == key then
			valid = true
		end
	end
	if not valid then
		return { ok = false }
	end
	local cdKey = player.UserId .. key
	if (trainCooldown[cdKey] or 0) > os.clock() then
		return { ok = false, msg = "Catch your breath first (" .. math.ceil(trainCooldown[cdKey] - os.clock()) .. "s)." }
	end
	trainCooldown[cdKey] = os.clock() + 15
	-- a success only counts if the round was really played (opened on the server, and long enough)
	local started = trainStart[cdKey]
	trainStart[cdKey] = nil
	local played = started ~= nil and os.clock() - started >= Config.MinigameMinSeconds.Astro
	if d.success ~= true or not played then
		BrainService.stress(player, 4)
		return { ok = true, msg = "💫 Bonk. Try again, space cadet." }
	end
	data.astroTrained = data.astroTrained or {}
	local firstTime = not data.astroTrained[key]
	data.astroTrained[key] = true
	BrainService.gain(player, firstTime and 2 or 0.6, "astro")
	BrainService.stress(player, -6)
	local all = true
	for _, t in ipairs(Content.AstroTraining) do
		if not data.astroTrained[t.key] then
			all = false
		end
	end
	if all and firstTime then
		Net.send(player, "confetti", {})
		return { ok = true, msg = "🧑‍🚀 FULLY TRAINED ASTRONAUT! The Space Agency would hire you on the spot!" }
	end
	return { ok = true, msg = "✅ Training complete!" }
end)

local gateQ = {}
Net.on("space_gate", function(player)
	if not isAstronaut(player) or not inSpace(player) then
		return { ok = false, msg = "Space Gates are in the Space Lab on the Moon (Astronauts only)." }
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		return { ok = false, msg = blocked }
	end
	local q = Content.SpaceGates[math.random(1, #Content.SpaceGates)]
	gateQ[player] = q
	return { ok = true, q = q.q, options = q.options }
end)

Net.on("space_gate_answer", function(player, d)
	local q = gateQ[player]
	gateQ[player] = nil
	if not q then
		return { ok = false }
	end
	if tonumber(d.choice) == q.answer then
		BrainService.gain(player, 2.5, "spacegate")
		BrainService.stress(player, 6)
		return { ok = true, correct = true, msg = "✅ Correct! Orbital mechanics: understood." }
	end
	BrainService.stress(player, 10)
	return { ok = true, correct = false, msg = "❌ Wrong. The right answer was: " .. q.options[q.answer] }
end)

---------------------------------------------------------------------
-- World's Smartest (IQ 200) + Retired Genius
---------------------------------------------------------------------
local TITLES = { Man = true, Woman = true, Person = true }

local function onSmartest(player)
	local spots = WorldService.Spots
	local lib = spots.library and WorldService.sp(spots.library) or nil
	Net.send(player, "worldsSmartest", { name = player.DisplayName, headlines = Content.SmartestHeadlines, library = lib })
end

local smartestStatues = 0
Net.on("smartest_title", function(player, d)
	local data = DataService.get(player)
	if not data or not data.worldsSmartest or data.smartestTitle then
		return { ok = false }
	end
	local title = tostring(d.title)
	if not TITLES[title] then
		title = "Person"
	end
	data.smartestTitle = title
	data.retired = true
	BrainService.awardBadge(player, "WorldsSmartest")
	BrainService.applyCharacter(player)
	BrainService.push(player)
	Net.broadcast("announce", { text = "👑 " .. player.DisplayName .. " is now THE WORLD'S SMARTEST " .. string.upper(title) .. "!", by = "Dr. Wrinkles", global = false })
	if smartestStatues < 12 then
		smartestStatues += 1
		ProjectService.addStatue(player.UserId, player.DisplayName, "👑", "World's Smartest " .. title)
	end
	if smartestStore and not data.adminTouched then
		task.spawn(function()
			pcall(function()
				smartestStore:UpdateAsync("list", function(old)
					old = old or {}
					for _, e in ipairs(old) do
						if e.userId == player.UserId then
							return nil
						end
					end
					if #old >= 12 then
						return nil
					end
					table.insert(old, { userId = player.UserId, name = player.DisplayName, title = title })
					return old
				end)
			end)
		end)
	end
	return { ok = true, msg = "You are now Retired Genius. People will ask you things. Constantly." }
end)

local retiredQ = {}
Net.on("retired_answer", function(player, d)
	local q = retiredQ[player]
	retiredQ[player] = nil
	if not q then
		return { ok = false }
	end
	if tonumber(d.choice) == q.answer then
		BrainService.gain(player, 0.5, "retired")
		return { ok = true, msg = q.who .. ": \"Wow. Thank you, genius!\"" }
	end
	return { ok = true, msg = q.who .. ": \"…are you sure you're the smartest?\"" }
end)

local function retiredLoop()
	while true do
		task.wait(150 + math.random(0, 90))
		for _, player in ipairs(Players:GetPlayers()) do
			local data = DataService.get(player)
			if data and data.retired and data.path == "Gain" and not BrainService.blocked(player) then
				local q = Content.RetiredQuestions[math.random(1, #Content.RetiredQuestions)]
				retiredQ[player] = q
				Net.send(player, "retiredQuestion", { who = q.who, q = q.q, options = q.options })
			end
		end
	end
end

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
function SpaceService.start()
	BrainService.isAstronaut = isAstronaut
	BrainService.spaceInvented = spaceInvented
	ProjectService.spaceCheck = function(player)
		if not isAstronaut(player) then
			return false, "🧑‍🚀 Space projects are for Astronauts (IQ " .. Config.Space.AstronautIQ .. "+)."
		end
		if not inSpace(player) then
			return false, "🌙 Space projects happen in the Space Lab on the Moon. Launch from the Launch Pad!"
		end
		return true
	end
	BrainService.hooks.onAstronautIQ = function(player)
		if isAstronaut(player) then
			BrainService.toast(player, "🧑‍🚀 IQ " .. Config.Space.AstronautIQ .. "! You're an ASTRONAUT now. 🚀 Launch Pad is east of town.", "LevelUp")
			Net.send(player, "confetti", {})
		else
			Net.send(player, "openStation", { station = "space" })
		end
		BrainService.push(player)
	end
	BrainService.hooks.onSmartest = onSmartest
	ProjectService.onInvented = function(key)
		if key ~= "space" then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if isAstronaut(player) then
				BrainService.toast(player, "🚀 Someone invented SPACE TRAVEL! The Astronaut job is unlocked for you. Launch Pad: east of town.", "LevelUp")
				BrainService.push(player)
			end
		end
	end
	buildLaunchPad()
	buildMoon()
	Players.PlayerRemoving:Connect(function(p)
		launching[p] = nil
		gateQ[p] = nil
		retiredQ[p] = nil
	end)
	task.spawn(retiredLoop)
	task.spawn(function()
		if not smartestStore then
			return
		end
		local ok, list = pcall(function()
			return smartestStore:GetAsync("list")
		end)
		if ok and typeof(list) == "table" then
			for _, e in ipairs(list) do
				if smartestStatues < 12 and typeof(e) == "table" and e.userId then
					smartestStatues += 1
					ProjectService.addStatue(e.userId, tostring(e.name), "👑", "World's Smartest " .. tostring(e.title or "Person"))
				end
			end
		end
	end)
	local _ = moonParts
end

return SpaceService

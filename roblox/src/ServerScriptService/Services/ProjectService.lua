-- ProjectService (update 1.3): Major Projects, the Noble Prize, the Hall of Inventors,
-- world firsts, and inventions that change the world.
--
-- Who gets an invention:
--   inventor          -> permanent (their own record)
--   inventor's server -> active until that server closes
--   every server      -> active for 1 hour; each extra inventor of the same thing adds 15 minutes
--   world first       -> "First Invented" badge + a statue in the Hall of Inventors (permanent)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Content = require(Shared.Content)
local Brain = require(Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local FriendService = require(script.Parent.FriendService)
local Props = require(script.Parent.Props)
local MinigameService = require(script.Parent.MinigameService) -- 1.9.1: research phases are minigames now
local Rooms = require(script.Parent.Rooms) -- 1.9.1: the Invention Hall stands in the Science Lab
local Config = require(Shared.Config)
local CI = Config.Inventions
local TI = Content.Inventions

local ProjectService = {}

local firstsStore, activeStore = nil, nil
pcall(function()
	firstsStore = DataStoreService:GetDataStore("BrainWorldFirsts_v1")
	activeStore = DataStoreService:GetDataStore("BrainActiveInventions_v1")
end)

local GLOBAL_HOUR = 3600
local EXTRA = 900
local MAX_GLOBAL = 3 * 3600

local active = {} -- [key] = expiry unix time (global hour)
local serverForever = {} -- [key] = true: invented in THIS server (until it closes)
local applied = {} -- [key] = true when the world effect is built
local steps = {} -- [player] = current step { kind, answer, ... }

local function projectByKey(key)
	for _, p in ipairs(Content.Projects) do
		if p.key == key then
			return p
		end
	end
	for _, p in ipairs(Content.SpaceProjects or {}) do
		if p.key == key then
			return p
		end
	end
	return nil
end

-- World firsts that have EVER happened (any player, any server). Used by 1.4:
-- once anyone invents Space Travel, the Astronaut job unlocks for everybody.
local everInvented = {}
function ProjectService.everInvented(key: string): boolean
	return everInvented[key] == true
end
-- Space projects need an Astronaut standing in the Space Lab (set by SpaceService)
ProjectService.spaceCheck = function(_player): (boolean, string?)
	return false, "Space projects are done in the Space Lab on the Moon."
end

local function isActive(key: string): boolean
	return serverForever[key] == true or (active[key] or 0) > os.time()
end
ProjectService.isActive = isActive

-- 1.9.1 (user: "you have to slowly work into it, and then you get to the scientist level"):
-- Major Projects unlock only when you reach the Scientist rank on the scientist career ladder
-- (Lab Assistant → Researcher → Scientist → Lead Scientist).
local function sciLevel(data): number
	local c = data.career
	if data.job == "scientist" and typeof(c) == "table" and c.id == "scientist" then
		return c.level or 1
	end
	return 0
end
ProjectService.sciLevel = sciLevel

local function canDoProjects(player): (boolean, string?)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" then
		return false, "Major Projects are on the Gain path."
	end
	local lvl = sciLevel(data)
	if lvl == 0 then
		return false, TI.NotScientist
	end
	if lvl < CI.NeedLevel then
		local titles = Content.Careers.Ladders.scientist
		return false, string.format(TI.KeepWorking, titles[lvl] or "?", titles[CI.NeedLevel] or "Scientist")
	end
	return true
end

---------------------------------------------------------------------
-- World effects of active inventions
---------------------------------------------------------------------
local effectFolder = Instance.new("Folder")
effectFolder.Name = "Inventions"
effectFolder.Parent = workspace

local function sp(v: Vector3): Vector3
	return WorldService.sp(v)
end

local function signPart(cf: CFrame, text: string, size: Vector3?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = size or Vector3.new(10, 3, 0.4)
	p.CFrame = cf
	p.Color = Color3.fromRGB(30, 30, 45)
	p.Parent = effectFolder
	local sg = Instance.new("SurfaceGui")
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(255, 235, 150)
	l.Text = text
	l.Parent = sg
	return p
end

local function promptOn(part: BasePart, action: string, object: string, fn)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 12
	pp.Parent = part
	pp.Triggered:Connect(fn)
end

local robots = {}

local EFFECTS = {}
EFFECTS.teleport = function(on)
	for _, spot in ipairs({ Vector3.new(0, 0.6, 50), Vector3.new(-100, 0.6, -40), Vector3.new(100, 0.6, -40), Vector3.new(300, 0.6, 240) }) do
		if on then
			local pad = Instance.new("Part")
			pad.Name = "TeleportPad"
			pad.Anchored = true
			pad.Shape = Enum.PartType.Cylinder
			pad.Size = Vector3.new(0.6, 8, 8)
			pad.CFrame = CFrame.new(sp(spot) + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
			pad.Color = Color3.fromRGB(120, 80, 255)
			pad.Material = Enum.Material.ForceField
			pad.Parent = effectFolder
			promptOn(pad, "Teleport", "🌀 Teleport Pad", function(player)
				Net.send(player, "freeTaxi", {})
			end)
		end
	end
end
EFFECTS.space = function(on)
	if not on then
		return
	end
	local base = CFrame.new(sp(Vector3.new(-30, 0.6, 50)))
	local body = Instance.new("Part")
	body.Anchored = true
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(26, 7, 7)
	body.CFrame = base * CFrame.new(0, 13, 0) * CFrame.Angles(0, 0, math.rad(90))
	body.Color = Color3.fromRGB(235, 235, 240)
	body.Material = Enum.Material.Metal
	body.Parent = effectFolder
	local nose = Instance.new("Part")
	nose.Anchored = true
	nose.Shape = Enum.PartType.Ball
	nose.Size = Vector3.new(7, 7, 7)
	nose.CFrame = base * CFrame.new(0, 26, 0)
	nose.Color = Color3.fromRGB(220, 40, 40)
	nose.Parent = effectFolder
	signPart(base * CFrame.new(0, 3, -6), "🚀 SPACE TRAVEL IS REAL. Astronauts (IQ 160+) launch from the Launch Pad, east of town")
end
EFFECTS.fusion = function(on)
	for _, d in ipairs(workspace:GetDescendants()) do
		if d.Name == "LampHead" and d:IsA("BasePart") then
			d.Color = on and Color3.fromRGB(150, 230, 255) or Color3.fromRGB(255, 240, 200)
			local l = d:FindFirstChildOfClass("PointLight")
			if l then
				l.Range = on and 40 or 26
				l.Brightness = on and 1.6 or 0.8
			end
		end
	end
end
local function foodStand(spot: Vector3, label: string)
	local m = Props.vending(CFrame.new(sp(spot)), label, Color3.fromRGB(60, 170, 80))
	m.Parent = effectFolder
	local hit = Instance.new("Part")
	hit.Anchored = true
	hit.CanCollide = false
	hit.Transparency = 1
	hit.Size = Vector3.new(4, 4, 1)
	hit.CFrame = CFrame.new(sp(spot)) * CFrame.new(0, 3, -2.5)
	hit.Parent = effectFolder
	promptOn(hit, "Eat", label, function(player)
		BrainService.stress(player, -10)
		BrainService.toast(player, "😋 Free food from the inventors! Stress down.")
	end)
end
EFFECTS.hunger = function(on)
	if on then
		foodStand(Vector3.new(-40, 0.6, -45), "🌾 FREE FOOD")
	end
end
EFFECTS.labfood = function(on)
	if on then
		foodStand(Vector3.new(40, 0.6, -45), "🍔 LAB SNACKS")
	end
end
EFFECTS.water = function(on)
	local water = workspace:FindFirstChild("Town") and workspace.Town:FindFirstChild("FountainWater")
	if water and on then
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 30
		pe.Speed = NumberRange.new(6, 10)
		pe.Lifetime = NumberRange.new(1, 1.6)
		pe.Color = ColorSequence.new(Color3.fromRGB(160, 220, 255))
		pe.Size = NumberSequence.new(0.4)
		pe.Parent = water
	end
end
EFFECTS.cure = function(on)
	if on then
		signPart(CFrame.new(sp(Vector3.new(300, 0.6, 40))) * CFrame.new(0, 12, 0), "🧬 CANCER: CURED ✅", Vector3.new(16, 4, 0.4))
		for _, p in ipairs(Players:GetPlayers()) do
			BrainService.stress(p, -20)
		end
	end
end
EFFECTS.translator = function(on)
	if on then
		signPart(CFrame.new(sp(Vector3.new(0, 0.6, -70))) * CFrame.new(0, 22, 0), "🗣 Hola • Bonjour • Shalom • 你好 • Hello", Vector3.new(20, 3, 0.4))
	end
end
EFFECTS.climate = function(on)
	if on then
		Net.broadcast("weather", { kind = "sun", seconds = 3600 })
	end
end
EFFECTS.robots = function(on)
	if not on then
		return
	end
	for i = 1, 3 do
		local bot = FriendService.npc("Robot" .. i, Color3.fromRGB(180, 185, 195), Color3.fromRGB(90, 100, 120), Color3.fromRGB(60, 65, 80))
		if bot then
			bot:PivotTo(CFrame.new(sp(Vector3.new(-20 + i * 10, 4, 20))))
			bot.Parent = effectFolder
			table.insert(robots, bot)
		end
	end
	task.spawn(function()
		while #robots > 0 do
			for _, bot in ipairs(robots) do
				local hum = bot:FindFirstChildOfClass("Humanoid")
				if hum and bot.Parent then
					hum:MoveTo(sp(Vector3.new(math.random(-60, 60), 1, math.random(-60, 60))))
				end
			end
			task.wait(4)
		end
	end)
end
EFFECTS.superconductor = function()
	for _, p in ipairs(Players:GetPlayers()) do
		BrainService.applyCharacter(p)
	end
end
-- battery is checked by GainService (gadget cooldowns)

ProjectService.EFFECTS = EFFECTS
ProjectService.effectFolder = effectFolder
ProjectService.signPart = signPart

local function applyEffect(key: string)
	if applied[key] or not EFFECTS[key] then
		applied[key] = true
		workspace:SetAttribute("Inv_" .. key, true)
		return
	end
	applied[key] = true
	workspace:SetAttribute("Inv_" .. key, true) -- 1.9.1: other services and clients react to active inventions
	pcall(EFFECTS[key], true)
end

ProjectService.speedBonus = function(): number
	return isActive("superconductor") and Config.InventionPerks.MaglevSpeed or 0
end

---------------------------------------------------------------------
-- Hall of Inventors (statues of world firsts)
---------------------------------------------------------------------
local hallCount = 0
local function addStatue(userId: number, name: string, project)
	hallCount += 1
	local i = hallCount
	local x = -66 + ((i - 1) % 12) * 12
	local base = CFrame.new(sp(Vector3.new(x, 0.6, -95))) * CFrame.Angles(0, math.pi, 0)
	local plinth = Instance.new("Part")
	plinth.Anchored = true
	plinth.Size = Vector3.new(5, 3, 5)
	plinth.CFrame = base * CFrame.new(0, 1.5, 0)
	plinth.Color = Color3.fromRGB(235, 232, 225)
	plinth.Material = Enum.Material.Marble
	plinth.Parent = effectFolder
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.Parent = plinth
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.Garamond
	l.TextColor3 = Color3.fromRGB(60, 50, 30)
	l.Text = project.icon .. " " .. project.name .. "\nFirst invented by\n" .. name
	l.Parent = sg
	task.spawn(function()
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		local model = ok and desc and FriendService.makeModel(desc, "Statue_" .. name)
		if model then
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.Material = Enum.Material.Marble
					d.Color = Color3.fromRGB(230, 228, 220)
				elseif d:IsA("Decal") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
					d:Destroy()
				end
			end
			model:PivotTo(base * CFrame.new(0, 6, 0))
			model.Parent = effectFolder
		end
	end)
end

ProjectService.addStatue = function(userId: number, name: string, icon: string, title: string)
	addStatue(userId, name, { icon = icon, name = title })
end

local function loadHall()
	if not firstsStore then
		return
	end
	local ok, firsts = pcall(function()
		return firstsStore:GetAsync("firsts")
	end)
	if ok and typeof(firsts) == "table" then
		for k in pairs(firsts) do
			everInvented[k] = true
		end
		for _, project in ipairs(Content.Projects) do
			local f = firsts[project.key]
			if f then
				addStatue(f.userId, f.name, project)
			end
		end
	end
end

-- Atomic world-first claim (two players can't both get it)
local function claimWorldFirst(player, project): boolean
	if not firstsStore then
		return false
	end
	local won = false
	pcall(function()
		firstsStore:UpdateAsync("firsts", function(old)
			old = old or {}
			if old[project.key] then
				won = false
				return nil
			end
			old[project.key] = { userId = player.UserId, name = player.DisplayName, time = os.time() }
			won = true
			return old
		end)
	end)
	return won
end

---------------------------------------------------------------------
-- Global invention hour
---------------------------------------------------------------------
local function extendGlobal(key: string): number
	local now = os.time()
	local newExpiry = now + GLOBAL_HOUR
	if activeStore then
		pcall(function()
			activeStore:UpdateAsync("active", function(old)
				old = old or {}
				local cur = old[key] or 0
				if cur > now then
					cur = math.min(cur + EXTRA, now + MAX_GLOBAL)
				else
					cur = now + GLOBAL_HOUR
				end
				old[key] = cur
				newExpiry = cur
				return old
			end)
		end)
	end
	return newExpiry
end

local function onGlobal(key: string, expiry: number, by: string?)
	if (active[key] or 0) < expiry then
		active[key] = expiry
	end
	applyEffect(key)
	if by then
		local p = projectByKey(key)
		Net.broadcast("announce", { text = "🎉 " .. by .. " just invented " .. (p and (p.icon .. " " .. p.name) or key) .. "! " .. (p and p.unlock or "") .. " (every server, for a while)", by = "Dr. Wrinkles", global = true })
	end
end

---------------------------------------------------------------------
-- Project steps
---------------------------------------------------------------------
-- phases: 1-2 grant, 3-4 research, 5 peer review, 6 test day
local PHASES = 6
local PHASE_NAMES = { "💰 Grant proposal", "💰 Grant proposal", "🔬 Research", "🔬 Research", "📝 Peer review", "🚀 Test day" }

local function makeStep(project, phase: number)
	if phase <= 2 then
		local args = {}
		for _, a in ipairs(Content.GrantArguments) do
			table.insert(args, a)
		end
		for i = #args, 2, -1 do
			local j = math.random(1, i)
			args[i], args[j] = args[j], args[i]
		end
		local opts, best = {}, 1
		for i = 1, 3 do
			opts[i] = args[i].text
			if args[i].strength > args[best].strength then
				best = i
			end
		end
		return { prompt = "Convince the funding committee. Pick your STRONGEST argument.", options = opts, answer = best }
	elseif phase <= 4 then
		local q = project.qs[phase - 2] or project.qs[1]
		return { prompt = q.q, options = q.options, answer = q.answer }
	elseif phase == 5 then
		local pr = Content.PeerReview[math.random(1, #Content.PeerReview)]
		return { prompt = "Another scientist reviewed your paper. Tap the line with the FLAW.", options = pr.lines, answer = pr.wrong }
	end
	return { prompt = "Everything is ready. The whole server is watching. Launch the prototype?", options = { "🚀 LAUNCH!" }, answer = 1 }
end

Net.on("project_list", function(player)
	local ok, why = canDoProjects(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	data.projectsDone = data.projectsDone or {}
	local list = {}
	for _, p in ipairs(Content.Projects) do
		table.insert(list, { key = p.key, icon = p.icon, name = p.name, unlock = p.unlock, done = data.projectsDone[p.key] == true, globalActive = isActive(p.key) })
	end
	local spaceOk = ProjectService.spaceCheck(player)
	for _, p in ipairs(Content.SpaceProjects or {}) do
		table.insert(list, { key = p.key, icon = p.icon, name = p.name, unlock = "🌙 SPACE LAB ONLY. " .. p.unlock, space = true, locked = not spaceOk, done = data.projectsDone[p.key] == true, globalActive = isActive(p.key) })
	end
	local act = data.project and projectByKey(data.project.key)
	return {
		ok = true,
		allowed = ok,
		why = why,
		projects = list,
		active = act and { key = act.key, name = act.name, icon = act.icon, phase = data.project.phase, phases = PHASES, phaseName = PHASE_NAMES[data.project.phase] } or nil,
		timeMachineFails = data.timeMachineFails or 0,
		ladder = { level = sciLevel(data), need = CI.NeedLevel, titles = Content.Careers.Ladders.scientist }, -- 1.9.1
	}
end)

Net.on("project_start", function(player, d)
	local ok, why = canDoProjects(player)
	if not ok then
		return { ok = false, msg = why }
	end
	local data = DataService.get(player)
	if d.key == "timemachine" then
		data.timeMachineFails = (data.timeMachineFails or 0) + 1
		BrainService.stress(player, 5)
		if data.timeMachineFails >= 10 then
			BrainService.awardBadge(player, "MaybeNextTime")
		end
		return { ok = true, timeMachine = true, msg = "⏳ " .. Content.TimeMachineFails[math.random(1, #Content.TimeMachineFails)] .. "  (fail #" .. data.timeMachineFails .. ")" }
	end
	if data.project then
		return { ok = false, msg = "Finish your current project first." }
	end
	local p = projectByKey(d.key)
	if not p then
		return { ok = false }
	end
	if p.space then
		local okSpace, whySpace = ProjectService.spaceCheck(player)
		if not okSpace then
			return { ok = false, msg = whySpace }
		end
	end
	data.project = { key = p.key, phase = 1 }
	return { ok = true }
end)

Net.on("project_abandon", function(player)
	local data = DataService.get(player)
	if data then
		data.project = nil
	end
	return { ok = true, msg = "Project abandoned. The lab is quiet again." }
end)

Net.on("project_step", function(player)
	local data = DataService.get(player)
	if not data or not data.project then
		return { ok = false, msg = "No active project." }
	end
	if BrainService.blocked(player) then
		return { ok = false, msg = BrainService.blocked(player) }
	end
	local p = projectByKey(data.project.key)
	-- 1.9.1: research phases are real minigames (no quiz questions)
	local game = CI.ResearchGames[data.project.phase]
	if game then
		steps[player] = nil
		local info = MinigameService.begin(player, game, "project", CI.ResearchLevel, { key = p.key, phase = data.project.phase })
		if info then
			info.icon, info.name, info.phase, info.phases, info.phaseName = p.icon, p.name, data.project.phase, PHASES, PHASE_NAMES[data.project.phase]
			info.story = string.format(TI.ResearchStory, p.icon, p.name)
			return info
		end
	end
	local step = makeStep(p, data.project.phase)
	steps[player] = step
	return { ok = true, icon = p.icon, name = p.name, phase = data.project.phase, phases = PHASES, phaseName = PHASE_NAMES[data.project.phase], prompt = step.prompt, options = step.options }
end)

local function complete(player, p)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.project = nil
	data.projectsDone = data.projectsDone or {}
	data.projectsDone[p.key] = true
	BrainService.awardBadge(player, "Inventor")
	BrainService.gain(player, 6, "project")
	serverForever[p.key] = true
	local real = not data.adminTouched -- staff-boosted accounts don't count as real inventions
	if real then
		everInvented[p.key] = true
	end
	applyEffect(p.key)
	local expiry = extendGlobal(p.key)
	onGlobal(p.key, expiry, player.DisplayName)
	pcall(function()
		MessagingService:PublishAsync("BrainInvention", { key = p.key, expiry = expiry, by = player.DisplayName, from = game.JobId, real = real })
	end)
	if real and ProjectService.onInvented then
		task.spawn(ProjectService.onInvented, p.key)
	end
	local first = (not data.adminTouched) and claimWorldFirst(player, p)
	if first then
		BrainService.awardBadge(player, "FirstInvented")
		addStatue(player.UserId, player.DisplayName, p)
	end
	Net.send(player, "prize", { icon = p.icon, name = p.name, unlock = p.unlock, first = first })
end

Net.on("project_answer", function(player, d)
	local data = DataService.get(player)
	local step = steps[player]
	if not data or not data.project or not step then
		return { ok = false }
	end
	steps[player] = nil
	local p = projectByKey(data.project.key)
	local correct = tonumber(d.choice) == step.answer
	if not correct then
		BrainService.stress(player, 12)
		return { ok = true, correct = false, msg = "💥 KABOOM. The experiment exploded. Your hair is singed. Try again." }
	end
	BrainService.gain(player, 1, "project")
	BrainService.stress(player, 5)
	if data.project.phase >= PHASES then
		-- test day: the whole server gets a countdown
		Net.broadcast("announce", { text = "🚀 " .. player.DisplayName .. " is testing " .. p.icon .. " " .. p.name .. " at the Science Lab!", by = "Dr. Wrinkles" })
		Net.broadcast("testDay", { name = p.name, icon = p.icon, by = player.DisplayName })
		task.delay(6, function()
			if player.Parent then
				complete(player, p)
			end
		end)
		return { ok = true, correct = true, testDay = true }
	end
	data.project.phase += 1
	return { ok = true, correct = true, phase = data.project.phase }
end)

MinigameService.handlers.project = function(player, round, _score, passed)
	local data = DataService.get(player)
	local x = round.extra or {}
	if not data or not data.project or data.project.key ~= x.key or data.project.phase ~= x.phase then
		return {}
	end
	if not passed then
		BrainService.stress(player, 6)
		return { project = true, msg = TI.Kaboom }
	end
	BrainService.gain(player, 1, "project")
	data.project.phase += 1
	return { project = true, phase = data.project.phase }
end

Net.on("prize_refuse", function(player)
	BrainService.awardBadge(player, "RefusedPrize")
	return { ok = true, msg = "You refused the Noble Prize. Like Perelman. Legendary." }
end)

-- Admin: start a global invention hour without the project
function ProjectService.adminInvent(key: string, by: string): boolean
	local p = projectByKey(key)
	if not p then
		return false
	end
	serverForever[key] = true
	local expiry = extendGlobal(key)
	onGlobal(key, expiry, by)
	pcall(function()
		MessagingService:PublishAsync("BrainInvention", { key = key, expiry = expiry, by = by, from = game.JobId })
	end)
	return true
end
---------------------------------------------------------------------
-- 1.9.1 Invention Hall: one glowing exhibit per invention along the back wall of the Science Lab.
-- Hover (mouse) or tap 🔍 Look (phone) to see what it does and whether it's active right now
-- (Client/InventionHall.lua). Reaching the Scientist rank plays a camera tour that floats above them.
---------------------------------------------------------------------
local exhibits = {}
local function allProjects()
	local list = {}
	for _, p in ipairs(Content.Projects) do
		table.insert(list, p)
	end
	for _, p in ipairs(Content.SpaceProjects or {}) do
		table.insert(list, p)
	end
	return list
end

local function buildHall()
	local lab = Rooms.Buildings.lab
	if not lab then
		return
	end
	local list = allProjects()
	local span = math.min(lab.half.X * 2 - 12, CI.HallSpacing * (#list - 1))
	for i, p in ipairs(list) do
		local x = -span / 2 + (i - 1) * (span / math.max(1, #list - 1))
		local base = lab.cf * CFrame.new(x, 0.5, lab.half.Z - CI.HallFromBack)
		local plinth = Instance.new("Part")
		plinth.Name = "Exhibit_" .. p.key
		plinth.Anchored = true
		plinth.Size = Vector3.new(3, 3, 3)
		plinth.CFrame = base * CFrame.new(0, 1.5, 0)
		plinth.Color = Color3.fromRGB(60, 70, 90)
		plinth.Material = Enum.Material.Metal
		plinth.Parent = effectFolder
		local holo = Instance.new("Part")
		holo.Name = "Hologram"
		holo.Anchored = true
		holo.CanCollide = false
		holo.Shape = Enum.PartType.Ball
		holo.Size = Vector3.new(2.2, 2.2, 2.2)
		holo.CFrame = base * CFrame.new(0, 4.6, 0)
		holo.Material = Enum.Material.ForceField
		holo.Color = Color3.fromRGB(90, 200, 255)
		holo.Parent = plinth
		local bb = Instance.new("BillboardGui")
		bb.Name = "Icon"
		bb.Size = UDim2.fromOffset(70, 90)
		bb.StudsOffset = Vector3.new(0, 1.2, 0)
		bb.MaxDistance = 90
		bb.Parent = holo
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.fromScale(1, 0.7)
		icon.BackgroundTransparency = 1
		icon.TextScaled = true
		icon.Text = p.icon
		icon.Parent = bb
		local state = Instance.new("TextLabel")
		state.Name = "State"
		state.Position = UDim2.fromScale(0, 0.7)
		state.Size = UDim2.fromScale(1, 0.3)
		state.BackgroundTransparency = 1
		state.TextScaled = true
		state.Font = Enum.Font.FredokaOne
		state.TextColor3 = Color3.new(1, 1, 1)
		state.TextStrokeTransparency = 0.3
		state.Text = ""
		state.Parent = bb
		plinth:SetAttribute("Key", p.key)
		plinth:SetAttribute("Order", i)
		plinth:SetAttribute("Icon", p.icon)
		plinth:SetAttribute("Title", p.name)
		plinth:SetAttribute("Unlock", p.unlock)
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 60
		cd.Parent = plinth
		local pp = Instance.new("ProximityPrompt")
		pp.Name = "ExhibitPrompt"
		pp.ActionText = TI.Look
		pp.ObjectText = p.name
		pp.HoldDuration = 0
		pp.RequiresLineOfSight = false
		pp.MaxActivationDistance = 8
		pp.Parent = plinth
		game:GetService("CollectionService"):AddTag(plinth, "InventionExhibit")
		exhibits[p.key] = { plinth = plinth, holo = holo, state = state }
	end
	-- the tour sign at the start of the hall
	local first = lab.cf * CFrame.new(-span / 2 - 5, 0.5, lab.half.Z - CI.HallFromBack)
	local sign = signPart(first * CFrame.new(0, 5, 0), TI.HallSign, Vector3.new(7, 3, 0.4))
	if sign then
		sign.Name = "InventionHallSign"
		sign:SetAttribute("GuideMain", true) -- the room guide points here first
		promptOn(sign, TI.TourAction, TI.HallSign, function(player)
			Net.send(player, "inventionTour", { reason = "replay" })
		end)
	end
end

local function refreshHall()
	for key, e in pairs(exhibits) do
		local on = isActive(key)
		local ever = everInvented[key] == true
		e.plinth:SetAttribute("Status", on and "active" or (ever and "invented" or "locked"))
		e.holo.Color = on and Color3.fromRGB(255, 210, 80) or (ever and Color3.fromRGB(90, 200, 255) or Color3.fromRGB(110, 110, 120))
		e.holo.Transparency = (on or ever) and 0 or 0.5
		e.state.Text = on and TI.StateActive or (ever and TI.StateInvented or TI.StateLocked)
	end
end
ProjectService.buildHall = buildHall

---------------------------------------------------------------------
-- 1.9.1 (user: "make the invention rewards actually do something, like clean water or clean energy"):
-- stronger effects on top of the old ones. Every active invention also sets workspace "Inv_<key>",
-- which other services read (free rides with clean energy, clear skies with climate, the real phone for
-- animals with the translator, less stress with the cure).
---------------------------------------------------------------------
local oldWater = EFFECTS.water
EFFECTS.water = function(on)
	pcall(oldWater, on)
	if not on then
		return
	end
	-- the river turns crystal clear
	local river = workspace:FindFirstChild("River", true)
	if river then
		for _, d in ipairs(river:GetDescendants()) do
			if d:IsA("BasePart") and (d.Material == Enum.Material.Glass or d.Material == Enum.Material.Water or string.find(d.Name, "Water") ~= nil) then
				d.Color = Color3.fromRGB(80, 200, 255)
				d.Reflectance = 0.25
			end
		end
	end
	-- drinking fountains around town
	for _, spot in ipairs(CI.WaterFountains) do
		local f = Instance.new("Part")
		f.Name = "CleanWaterFountain"
		f.Anchored = true
		f.Size = Vector3.new(2, 3.4, 2)
		f.CFrame = CFrame.new(sp(spot) + Vector3.new(0, 1.7, 0))
		f.Color = Color3.fromRGB(200, 230, 255)
		f.Material = Enum.Material.Marble
		f.Parent = effectFolder
		local drop = Instance.new("ParticleEmitter")
		drop.Rate = 12
		drop.Speed = NumberRange.new(3, 5)
		drop.Lifetime = NumberRange.new(0.6, 0.9)
		drop.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
		drop.Size = NumberSequence.new(0.25)
		drop.Parent = f
		promptOn(f, TI.Drink, TI.FountainName, function(player)
			local d = DataService.get(player)
			if d and d.path == "Gain" then
				BrainService.stress(player, -CI.WaterCalm)
				BrainService.gain(player, CI.WaterGain, "cleanwater")
				BrainService.toast(player, TI.DrankGain)
			else
				BrainService.toast(player, TI.DrankLose)
			end
		end)
	end
end

local oldFusion = EFFECTS.fusion
EFFECTS.fusion = function(on)
	pcall(oldFusion, on)
	if not on then
		return
	end
	-- a solar farm at the edge of town; while clean energy is active, rides are free (LifeService, GainService)
	for i, spot in ipairs(CI.SolarSpots) do
		local panel = Instance.new("Part")
		panel.Name = "SolarPanel"
		panel.Anchored = true
		panel.Size = Vector3.new(10, 0.4, 6)
		panel.CFrame = CFrame.new(sp(spot) + Vector3.new(0, 2.4, 0)) * CFrame.Angles(math.rad(25), 0, 0)
		panel.Color = Color3.fromRGB(40, 70, 140)
		panel.Material = Enum.Material.Glass
		panel.Parent = effectFolder
		if i == 1 then
			signPart(CFrame.new(sp(spot)) * CFrame.new(0, 7, -4), TI.EnergySign, Vector3.new(14, 3, 0.4))
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		BrainService.toast(p, TI.EnergyToast)
	end
end

local oldCure = EFFECTS.cure
EFFECTS.cure = function(on)
	pcall(oldCure, on)
	if not on then
		return
	end
	-- a free check-up at the hospital: stress back to zero (stress gains are also lower: BrainService)
	local spot = WorldService.Spots.hospital
	if spot then
		local desk = Instance.new("Part")
		desk.Name = "FreeCheckup"
		desk.Anchored = true
		desk.Size = Vector3.new(5, 3, 2)
		desk.CFrame = CFrame.new(spot + Vector3.new(6, -1.5, 0))
		desk.Color = Color3.fromRGB(240, 245, 255)
		desk.Parent = effectFolder
		promptOn(desk, TI.Checkup, TI.CheckupName, function(player)
			BrainService.stress(player, -100)
			BrainService.toast(player, TI.CheckupDone)
		end)
	end
end

local oldClimate = EFFECTS.climate
EFFECTS.climate = function(on)
	pcall(oldClimate, on)
	if not on then
		return
	end
	-- the park blooms (WeatherService keeps the sky clear while this is active)
	local P = Config.Map.Park
	local colors = { Color3.fromRGB(255, 120, 160), Color3.fromRGB(255, 220, 80), Color3.fromRGB(180, 120, 255), Color3.fromRGB(255, 255, 255) }
	for _ = 1, CI.ParkFlowers do
		local f = Instance.new("Part")
		f.Name = "Bloom"
		f.Anchored = true
		f.CanCollide = false
		f.Shape = Enum.PartType.Ball
		f.Size = Vector3.new(1.2, 1.2, 1.2)
		f.Color = colors[math.random(1, #colors)]
		f.Position = sp(Vector3.new(math.random(P.X1 + 5, P.X2 - 5), 1.2, math.random(P.Z1 + 5, P.Z2 - 5)))
		f.Parent = effectFolder
	end
	pcall(function()
		require(script.Parent.WeatherService).set("clear")
	end)
end

local oldRobots = EFFECTS.robots
EFFECTS.robots = function(on)
	pcall(oldRobots, on)
	if not on then
		return
	end
	-- the helper robots give rides: tap one to be carried to your workplace (or the plaza)
	task.wait(1)
	for _, bot in ipairs(robots) do
		local root = bot:FindFirstChild("HumanoidRootPart") or bot.PrimaryPart
		if root and not root:FindFirstChild("RobotRide") then
			local pp = Instance.new("ProximityPrompt")
			pp.Name = "RobotRide"
			pp.ActionText = TI.RobotRide
			pp.ObjectText = "🤖"
			pp.HoldDuration = 0
			pp.RequiresLineOfSight = false
			pp.MaxActivationDistance = 10
			pp.Parent = root
			pp.Triggered:Connect(function(player)
				local d = DataService.get(player)
				local job = nil
				for _, j in ipairs(Content.Jobs) do
					if d and j.id == d.job then
						job = j
					end
				end
				local pos = job and WorldService.workPos(player, job.place)
				local char = player.Character
				if pos and char then
					char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 4)))
				else
					WorldService.teleport(player, "lobby")
				end
				BrainService.toast(player, TI.RobotDone, "CartoonBoing")
			end)
		end
	end
end


function ProjectService.start()
	BrainService.extraSpeed = ProjectService.speedBonus
	-- 1.9.1: solved world hunger = free coins for everyone every few minutes
	task.spawn(function()
		while true do
			task.wait(Config.InventionPerks.HungerEvery)
			if isActive("hunger") then
				for _, p in ipairs(Players:GetPlayers()) do
					local d = DataService.get(p)
					if d then
						d.coins = (d.coins or 0) + Config.InventionPerks.HungerCoins
						BrainService.toast(p, string.format(Content.Inventions.HungerToast, Config.InventionPerks.HungerCoins))
						BrainService.push(p)
					end
				end
			end
		end
	end)
	-- 1.9.1 Invention Hall in the Science Lab (after the town is built), refreshed every half minute
	task.delay(6, function()
		pcall(buildHall)
		while true do
			pcall(refreshHall)
			task.wait(30)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		steps[p] = nil
	end)
	task.spawn(loadHall)
	task.spawn(function()
		while true do
			task.wait(300)
			if firstsStore then
				local ok, firsts = pcall(function()
					return firstsStore:GetAsync("firsts")
				end)
				if ok and typeof(firsts) == "table" then
					for k in pairs(firsts) do
						if not everInvented[k] then
							everInvented[k] = true
							if ProjectService.onInvented then
								task.spawn(ProjectService.onInvented, k)
							end
						end
					end
				end
			end
		end
	end)
	-- inventions still running from other servers
	task.spawn(function()
		if not activeStore then
			return
		end
		local ok, cur = pcall(function()
			return activeStore:GetAsync("active")
		end)
		if ok and typeof(cur) == "table" then
			for key, expiry in pairs(cur) do
				if typeof(expiry) == "number" and expiry > os.time() then
					onGlobal(key, expiry, nil)
				end
			end
		end
	end)
	pcall(function()
		MessagingService:SubscribeAsync("BrainInvention", function(msg)
			local d = msg.Data
			if typeof(d) == "table" and d.from ~= game.JobId then
				if d.real then
					everInvented[d.key] = true
					if ProjectService.onInvented then
						task.spawn(ProjectService.onInvented, d.key)
					end
				end
				onGlobal(d.key, d.expiry, d.by)
			end
		end)
	end)
	local _ = Debris
end

return ProjectService

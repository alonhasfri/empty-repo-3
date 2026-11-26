-- GainService: everything on the Gain path (library, Jack B Movies,
-- Skill Gates, jobs, genius habits, the cash-grab joke shop).

local Players = game:GetService("Players")
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
local ConversationService = require(script.Parent.ConversationService)
local BoardService = require(script.Parent.BoardService)
local HorrorService = require(script.Parent.HorrorService)
local MinigameService = require(script.Parent.MinigameService) -- 1.9

local GainService = {}

local sessions = {} -- [player] = { library, theater, gate, gateCooldown, job, nap, pigeons }

local function s(player)
	local x = sessions[player]
	if not x then
		x = {}
		sessions[player] = x
	end
	return x
end

local function onGain(player): boolean
	local data = DataService.get(player)
	return data ~= nil and data.path == "Gain"
end

local function guard(player, feature: string, allowFrozen: boolean?)
	if not onGain(player) then
		return { ok = false, msg = "This is for the Gain path." }
	end
	if not BrainService.feature(feature) then
		return { ok = false, msg = "This is turned off right now." }
	end
	local blocked = BrainService.blocked(player)
	if blocked and not (allowFrozen and string.find(blocked, "stressed")) then
		return { ok = false, msg = blocked }
	end
	return nil
end

local function pick(list)
	return list[math.random(1, #list)]
end

---------------------------------------------------------------------
-- Library and Jack B Movies
---------------------------------------------------------------------
Net.on("library_get", function(player)
	local bad = guard(player, "Library")
	if bad then
		return bad
	end
	local item = pick(Content.Library)
	s(player).library = { item = item, issued = os.clock() }
	return { ok = true, text = item.text, q = item.q, options = item.options, wait = Config.ReadingSeconds }
end)

Net.on("library_answer", function(player, d)
	local sess = s(player).library
	if not sess then
		return { ok = false }
	end
	if os.clock() - sess.issued < Config.ReadingSeconds - 0.5 then
		return { ok = false, msg = "Read it first! (10 seconds)" }
	end
	s(player).library = nil
	local correct = tonumber(d.choice) == sess.item.answer
	if correct then
		local data = DataService.get(player)
		local points = 2
		if data.focusCharges and data.focusCharges > 0 then
			data.focusCharges -= 1
			points = 3
		end
		BrainService.gain(player, points, "library")
		BrainService.stress(player, 2)
		BrainService.narrate(player, "gained")
	else
		BrainService.stress(player, 4)
	end
	return { ok = true, correct = correct, answer = sess.item.answer }
end)

Net.on("theater_get", function(player)
	local bad = guard(player, "Theater")
	if bad then
		return bad
	end
	local item = pick(Content.Theater)
	s(player).theater = { item = item, issued = os.clock() }
	return { ok = true, text = item.text, q = item.q, options = item.options, wait = 6 }
end)

Net.on("theater_answer", function(player, d)
	local sess = s(player).theater
	if not sess then
		return { ok = false }
	end
	if os.clock() - sess.issued < 5.5 then
		return { ok = false, msg = "Watch the video first!" }
	end
	s(player).theater = nil
	local correct = tonumber(d.choice) == sess.item.answer
	if correct then
		local data = DataService.get(player)
		local points = 2
		if data.focusCharges and data.focusCharges > 0 then
			data.focusCharges -= 1
			points = 3
		end
		BrainService.gain(player, points, "theater")
		BrainService.stress(player, 2)
	else
		BrainService.stress(player, 3)
	end
	return { ok = true, correct = correct, answer = sess.item.answer }
end)

---------------------------------------------------------------------
-- Skill Gates
---------------------------------------------------------------------
Net.on("gate_status", function(player)
	local gate = BrainService.nextGate(player)
	local cd = s(player).gateCooldown or 0
	return {
		ok = true,
		gate = gate and gate.name or nil,
		iq = gate and gate.iq or nil,
		atGate = BrainService.atGate(player),
		cooldown = math.max(0, math.ceil(cd - os.clock())),
	}
end)

-- 1.8.9 (user: "Skill Gates must be VERY easy, basically fun facts"): the gate reads a short fact and asks
-- an easy question about it. Config.GateUseFacts switches back to the old hard questions.
local function gateBank()
	return (Config.GateUseFacts and Content.GateFacts) or Content.GateQuestions
end
Net.on("gate_start", function(player)
	local bad = guard(player, "Gates")
	if bad then
		return bad
	end
	local gate = BrainService.nextGate(player)
	if not gate then
		return { ok = false, msg = "No gate ahead. You've passed them all (for now)!" }
	end
	if not BrainService.atGate(player) then
		return { ok = false, msg = "Reach " .. gate.iq .. " IQ first. Keep learning!" }
	end
	local sess = s(player)
	if sess.gateCooldown and os.clock() < sess.gateCooldown then
		return { ok = false, msg = "Cool down for " .. math.ceil(sess.gateCooldown - os.clock()) .. " more seconds." }
	end
	local pool = {}
	for i, q in ipairs(gateBank()) do
		if q.tier == gate.tier then
			table.insert(pool, i)
		end
	end
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local chosen = {}
	for i = 1, math.min(Config.GateQuestionCount, #pool) do
		chosen[i] = pool[i]
	end
	local data = DataService.get(player)
	local seconds = Config.GateSeconds * (data.settings.extraTime and Config.GateExtraTimeMultiplier or 1)
	local hints = Config.GateHints + (data.perks.ExtraHints and 2 or 0) + (data.bonusHints or 0)
	data.bonusHints = 0
	sess.gate = { gate = gate, questions = chosen, started = os.clock(), seconds = seconds, hints = hints }
	BrainService.stress(player, Config.GateStartStress) -- 1.8.8: 0 (gates are friendly now; stress here helped freeze players)
	local out = {}
	for i, qi in ipairs(chosen) do
		local q = gateBank()[qi]
		out[i] = { q = q.q, options = q.options, fact = q.fact, icon = q.icon }
	end
	return { ok = true, name = gate.name, questions = out, seconds = seconds, hints = hints }
end)

Net.on("gate_hint", function(player, d)
	local sess = s(player).gate
	if not sess or sess.hints <= 0 then
		return { ok = false, msg = "No hints left." }
	end
	local qi = sess.questions[tonumber(d.index) or 0]
	if not qi then
		return { ok = false }
	end
	local q = gateBank()[qi]
	local wrong = {}
	for i = 1, #q.options do
		if i ~= q.answer then
			table.insert(wrong, i)
		end
	end
	sess.hints -= 1
	BrainService.lose(player, Config.HintCostFraction / 0.002, "hint")
	return { ok = true, remove = wrong[math.random(1, #wrong)], hints = sess.hints }
end)

Net.on("gate_submit", function(player, d)
	local sess = s(player)
	local g = sess.gate
	if not g then
		return { ok = false }
	end
	sess.gate = nil
	local data = DataService.get(player)
	local inTime = os.clock() - g.started <= g.seconds + 3
	local correctCount = 0
	if typeof(d) == "table" and typeof(d.answers) == "table" then
		for i, qi in ipairs(g.questions) do
			-- A table answered out of order (or with gaps) crosses the remote as a
			-- dictionary with STRING keys ("1", "2"...), so read both forms.
			local a = d.answers[i]
			if a == nil then
				a = d.answers[tostring(i)]
			end
			if tonumber(a) == gateBank()[qi].answer then
				correctCount += 1
			end
		end
	end
	if inTime and correctCount == #g.questions then
		data.gatesPassed[g.gate.id] = true
		BrainService.resetGateNotice(player)
		local badgeKey = "Gate" .. string.sub(g.gate.id, 5)
		BrainService.awardBadge(player, badgeKey)
		BrainService.narrate(player, "gatePass")
		BrainService.push(player)
		return { ok = true, passed = true, correct = correctCount }
	end
	data.stats.gatesFailed += 1
	sess.gateCooldown = os.clock() + Config.GateFailCooldown
	BrainService.stress(player, Config.GateFailStress) -- 1.8.8: 0
	BrainService.narrate(player, "gateFail")
	return { ok = true, passed = false, correct = correctCount, total = #g.questions, late = not inTime }
end)

---------------------------------------------------------------------
-- Jobs (done at real workplaces in town)
---------------------------------------------------------------------
local function jobById(id)
	for _, j in ipairs(Content.Jobs) do
		if j.id == id then
			return j
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Careers (1.6): every job is a ladder of 4 titles. 1 XP per task done right;
-- enough XP + enough IQ = promotion (more pay, new uniform).
---------------------------------------------------------------------
local CC = Config.Careers
local CT = Content.Careers

-- IQ needed for ladder level (1-4)
local function levelIQ(job, level: number): number
	return job.minIQ + CC.StartIQ + (level - 1) * CC.IQPerLevel + (level == 4 and CC.TopBonusIQ or 0)
end

local function ladderOf(job)
	return CT.Ladders[job.id] or { job.name, job.name, job.name, job.name }
end

-- The career record for your current job (made fresh when you switch jobs)
local function careerOf(data)
	if not data.job then
		return nil
	end
	local c = data.career
	if typeof(c) ~= "table" or c.id ~= data.job then
		c = { id = data.job, level = 1, xp = 0, shift = 0, ok = 0 }
		data.career = c
	end
	return c
end

local function payMult(c): number
	return 1 + ((c and c.level or 1) - 1) * CC.PayPerLevel
end

local function titleOf(job, c): string
	return ladderOf(job)[c and c.level or 1]
end

-- Uniform: a colored vest and your job title over your head (Gain path, human form only)
local function applyUniform(player)
	local char = player.Character
	if not char then
		return
	end
	local old = char:FindFirstChild("Uniform")
	if old then
		old:Destroy()
	end
	local data = DataService.get(player)
	local job = data and jobById(data.job)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not job or not torso or data.path ~= "Gain" or data.dead then
		return
	end
	local stage = Brain.stage(data.cells, BrainService.secretAnimals).key
	if stage ~= "human" and stage ~= "barelyhuman" then
		return
	end
	local c = careerOf(data)
	local folder = Instance.new("Folder")
	folder.Name = "Uniform"
	local vest = Instance.new("Part")
	vest.Name = "Vest"
	vest.Size = Vector3.new(torso.Size.X + 0.12, torso.Size.Y * 0.8, torso.Size.Z + 0.12)
	vest.Color = CC.Uniforms[job.id] or Color3.fromRGB(120, 120, 130)
	vest.Material = Enum.Material.Fabric
	vest.CanCollide = false
	vest.CanQuery = false
	vest.CanTouch = false
	vest.Massless = true
	vest.CFrame = torso.CFrame * CFrame.new(0, -torso.Size.Y * 0.1, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = vest
	weld.Parent = vest
	vest.Parent = folder
	local head = char:FindFirstChild("Head")
	if head then
		local g = Instance.new("BillboardGui")
		g.Name = "JobTitle"
		g.Size = UDim2.new(5, 0, 0.8, 0)
		g.StudsOffset = Vector3.new(0, 3.2, 0)
		g.MaxDistance = 60
		g.Adornee = head
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = Color3.fromRGB(255, 240, 170)
		l.TextStrokeTransparency = 0.3
		l.Text = "💼 " .. titleOf(job, c)
		l.Parent = g
		g.Parent = folder
	end
	folder.Parent = char
end
GainService.applyUniform = applyUniform

local function jobAvailable(data, job): boolean
	if job.comebackOnly and not data.comeback then
		return false
	end
	return Brain.iq(data.cells) >= levelIQ(job, 1)
end

local function atWork(player, job): boolean
	local pos = WorldService.workPos(player, job.place)
	return pos ~= nil and WorldService.near(player, pos, Config.WorkRadius)
end

Net.on("jobs_list", function(player)
	local bad = guard(player, "Jobs")
	if bad then
		return bad
	end
	local data = DataService.get(player)
	local list = {}
	for _, j in ipairs(Content.Jobs) do
		if not j.comebackOnly or data.comeback then
			local ladder = ladderOf(j)
			table.insert(list, {
				id = j.id,
				name = j.name,
				first = ladder[1],
				top = ladder[4],
				coins = j.coinsPerMinute,
				available = jobAvailable(data, j),
				current = data.job == j.id,
				minIQ = levelIQ(j, 1),
				placeName = j.placeName,
			})
		end
	end
	local current = jobById(data.job)
	local career = nil
	if current then
		local c = careerOf(data)
		local ladder = ladderOf(current)
		career = { ladder = table.concat(ladder, " → "), title = ladder[c.level], level = c.level, xp = c.xp }
		if c.level < 4 then
			career.nextXP = CC.XPNeed[c.level + 1]
			career.nextIQ = levelIQ(current, c.level + 1)
		end
	end
	return {
		ok = true,
		jobs = list,
		career = career,
		atWork = current ~= nil and atWork(player, current),
		workplace = current and current.placeName or nil,
		idea = data.ideaMeter,
		ideaMax = Config.EurekaTasks,
	}
end)

Net.on("job_take", function(player, d)
	local data = DataService.get(player)
	local job = jobById(d.id)
	if not data or not job or not onGain(player) or not jobAvailable(data, job) then
		return { ok = false, msg = "You can't take that job right now." }
	end
	data.job = job.id
	local c = careerOf(data) -- a new job starts at the bottom of its ladder
	BrainService.awardBadge(player, "FirstJob")
	BrainService.push(player)
	applyUniform(player)
	Net.send(player, "workMarker", { pos = WorldService.workPos(player, job.place), name = job.placeName })
	return { ok = true, msg = string.format(CT.Taken, titleOf(job, c), job.placeName) }
end)

-- Taxi: quick travel around town (both paths)
Net.on("taxi", function(player, d)
	local sess = s(player)
	-- standing on a 🌀 teleport pad (Teleportation invention) = free, instant taxi
	local onPad = false
	if d.free then
		local inv = workspace:FindFirstChild("Inventions")
		for _, pad in ipairs(inv and inv:GetChildren() or {}) do
			if pad.Name == "TeleportPad" and WorldService.near(player, pad.Position, 14) then
				onPad = true
			end
		end
	end
	local tdata = DataService.get(player)
	local instant = onPad or (tdata and tdata.castleMap) -- teleport pad, or the Endless Castle Map (1.4): no waiting
	local key = tostring(d.key)
	local dest, destName
	if key == "work" then
		local job = tdata and jobById(tdata.job)
		if not job then
			return { ok = false, msg = "You don't have a job yet." }
		end
		dest, destName = WorldService.workPos(player, job.place), job.placeName
		if not dest then
			return { ok = false, msg = "Unknown place." }
		end
	elseif WorldService.Spots[key] then
		destName = key
		for _, p in ipairs((WorldService.placeList())) do
			if p.key == key then
				destName = p.name
			end
		end
	else
		return { ok = false, msg = "Unknown place." }
	end
	local function go()
		if dest then
			if player.Character then
				player.Character:PivotTo(CFrame.new(dest + Vector3.new(0, 3, -8)))
			end
		else
			WorldService.teleport(player, key)
		end
	end
	if instant then
		go()
		return { ok = true, msg = "🌀 Here you go!" }
	end
	-- 1.7 fix: the free map ride is a slow bus (Hoppr costs coins but is fast, walking is free)
	local now = os.clock()
	if sess.busAt then
		return { ok = false, msg = string.format(Content.Bus.Waiting, math.max(1, math.ceil(sess.busAt - now))) }
	end
	if sess.taxi and now < sess.taxi then
		return { ok = false, msg = string.format(Content.Bus.Cooldown, math.ceil(sess.taxi - now)) }
	end
	local wait = Config.Bus.WaitSeconds
	sess.busAt = now + wait
	task.delay(wait, function()
		sess.busAt = nil
		sess.taxi = os.clock() + Config.Bus.Cooldown
		if not player.Parent then
			return
		end
		if not ConversationService.readyToTravel(player) then
			BrainService.toast(player, Content.Bus.Missed)
			return
		end
		go()
		BrainService.toast(player, string.format(Content.Bus.Arrived, tostring(destName)))
	end)
	return { ok = true, msg = string.format(Content.Bus.Coming, wait) }
end)

Net.on("places", function(player)
	local list, extent = WorldService.placeList()
	local me = nil
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		me = { x = root.Position.X, z = root.Position.Z }
	end
	return { ok = true, places = list, extent = extent, me = me }
end)

local function makeTask(job)
	-- 1.9: the cashier's maths question is gone (cashiers play Scan & bag now: Config.Minigames.ByJob)
	local t = { kind = job.task }
	if job.task == "office" then
		local words = { "Banana", "Apple", "Cherry", "Mango", "Kiwi", "Grape", "Lemon", "Peach" }
		local chosen = {}
		for i = 1, 4 do
			chosen[i] = table.remove(words, math.random(1, #words))
		end
		local first = 1
		for i = 2, 4 do
			if chosen[i] < chosen[first] then
				first = i
			end
		end
		t.title = "🏢 Sort the files"
		t.prompt = "Which file comes FIRST alphabetically?"
		t.options = chosen
		t.answer = first
	elseif job.task == "teacher" then
		local hw = pick(Content.HomeworkMistakes)
		t.title = "📝 Grade the homework"
		t.prompt = "Tap the WRONG line."
		t.options = hw.lines
		t.answer = hw.wrong
	elseif job.task == "lawyer" then
		local w = pick(Content.Testimony)
		t.title = "⚖️ Cross-examination"
		t.prompt = "Find the contradiction in the witness's story."
		t.options = w.lines
		t.answer = w.wrong
	elseif job.task == "doctor" then
		local dx = pick(Content.Diagnoses)
		t.title = "🩺 Diagnose the patient"
		t.prompt = dx.symptoms
		t.options = dx.options
		t.answer = dx.answer
	elseif job.task == "scientist" then
		local ex = pick(Content.LabExperiments)
		t.title = "🔬 Run the experiment"
		t.prompt = ex.q
		t.options = ex.options
		t.answer = ex.answer
	else -- janitor / sweeper
		local spot = math.random(1, 4)
		t.title = "🧹 Clean up"
		t.prompt = "Tap the dirty spot!"
		t.options = { "✨", "✨", "✨", "✨" }
		t.options[spot] = "🟫 dirty"
		t.answer = spot
	end
	return t
end

Net.on("job_task", function(player)
	local bad = guard(player, "Jobs")
	if bad then
		return bad
	end
	local data = DataService.get(player)
	local job = jobById(data.job)
	if not job then
		return { ok = false, msg = "Get a job at the Job Center first." }
	end
	if not atWork(player, job) then
		Net.send(player, "workMarker", { pos = WorldService.workPos(player, job.place), name = job.placeName })
		return { ok = false, msg = "You're not at work! Go to " .. job.placeName .. " (Hoppr or the 🚌 bus can take you).", notAtWork = true }
	end
	-- 1.9 Gain path redesign: most jobs are a real minigame now (no maths questions)
	local game = Config.Minigames.ByJob[job.id]
	if game then
		s(player).job = nil
		local c = careerOf(data)
		local lvl = c and c.level or 1
		if typeof(game) == "table" then -- 1.9.1: a different minigame per career level (restaurant: dishes, then serving)
			game = game[lvl] or game[#game]
		end
		local extra = { jobId = job.id }
		if job.place == "restaurant" then -- the menu of the restaurant you are standing in
			local rk = WorldService.restaurantAt(player)
			local P = rk and Content.Restaurants.Places[rk]
			extra.client = P and { menu = P.menu, name = P.name } or nil
		end
		return MinigameService.begin(player, game, "job", lvl, extra)
	end
	local t = makeTask(job)
	s(player).job = t
	return { ok = true, title = t.title, prompt = t.prompt, options = t.options, kind = t.kind }
end)

local function eureka(player, data)
	local locked = {}
	for _, inv in ipairs(Content.Inventions) do
		if not data.inventions[inv.key] then
			table.insert(locked, inv)
		end
	end
	if #locked == 0 then
		data.coins += 100
		BrainService.toast(player, "💡 Eureka! …but you've invented everything already. +100 coins instead.", "LevelUp")
		return
	end
	for i = #locked, 2, -1 do
		local j = math.random(1, i)
		locked[i], locked[j] = locked[j], locked[i]
	end
	local choices = {}
	for i = 1, math.min(3, #locked) do
		choices[i] = locked[i].key
	end
	data.eurekaChoices = choices
	local cards = {}
	for i, key in ipairs(choices) do
		for _, inv in ipairs(Content.Inventions) do
			if inv.key == key then
				cards[i] = { key = inv.key, icon = inv.icon, name = inv.name, desc = inv.desc }
			end
		end
	end
	Net.send(player, "eureka", { choices = cards })
end

local function promote(player, data, job, c)
	c.level += 1
	c.waitTold = false
	local title = titleOf(job, c)
	applyUniform(player)
	Net.send(player, "promoted", { title = title, cells = data.cells, payPercent = math.floor(CC.PayPerLevel * 100 + 0.5) })
	BrainService.toast(player, string.format(CT.Boss, title), "LevelUp")
	BrainService.push(player)
end

-- After every shift: XP, promotions and report cards
local function careerShift(player, data, job, correct: boolean)
	local c = careerOf(data)
	c.shift += 1
	if correct then
		c.ok += 1
		c.xp += 1
	end
	local nextLevel = c.level + 1
	if correct and nextLevel <= 4 and c.xp >= CC.XPNeed[nextLevel] then
		if Brain.iq(data.cells) >= levelIQ(job, nextLevel) then
			task.delay(CC.PromotionDelay, function()
				if data.career == c and c.level + 1 == nextLevel then
					promote(player, data, job, c)
				end
			end)
		elseif not c.waitTold then
			c.waitTold = true
			BrainService.toast(player, string.format(CT.EarnedWait, levelIQ(job, nextLevel)))
		end
	end
	if c.shift % CC.ReportEvery == 0 then
		local need = c.level < 4 and CC.XPNeed[c.level + 1] or nil
		Net.send(player, "reportCard", {
			title = titleOf(job, c),
			accuracy = CT.Accuracy[math.min(c.ok, 3)],
			speed = CT.Speed[math.random(1, #CT.Speed)],
			vibes = CT.Vibes[math.random(1, #CT.Vibes)],
			xp = c.xp,
			need = need,
		})
		c.ok = 0
	end
end

local function finishTask(player, data, job, correct)
	careerShift(player, data, job, correct)
	if correct then
		local pay = math.floor(job.coinsPerMinute * CC.TaskPay * payMult(data.career) + 0.5)
		data.coins += pay
		BoardService.addPay(player, pay)
		data.jobTasksDone += 1
		BrainService.gain(player, 0.5, "job")
		BrainService.stress(player, 4)
		data.ideaMeter += 1
		if data.ideaMeter >= Config.EurekaTasks then
			data.ideaMeter = 0
			eureka(player, data)
		end
	else
		BrainService.stress(player, 4)
	end
	BrainService.push(player)
end

Net.on("job_answer", function(player, d)
	local t = s(player).job
	if not t then
		return { ok = false }
	end
	s(player).job = nil
	local data = DataService.get(player)
	local job = jobById(data.job)
	if not job then
		return { ok = false }
	end
	local correct = tonumber(d.choice) == t.answer
	finishTask(player, data, job, correct)
	return { ok = true, correct = correct, answer = t.answer, idea = data.ideaMeter, ideaMax = Config.EurekaTasks }
end)

-- 1.9: a finished job minigame counts as one task (a good score = done right), plus bonus coins
MinigameService.handlers.job = function(player, round, score, passed)
	local data = DataService.get(player)
	local job = data and jobById(data.job)
	if not job or job.id ~= (round.extra and round.extra.jobId) then
		return {}
	end
	local before = data.coins
	finishTask(player, data, job, passed)
	if passed then
		local bonus = (score - round.pass) * Config.Minigames.BonusCoinsPerPoint
		if bonus > 0 then
			data.coins += bonus
			BrainService.push(player)
		end
	end
	return { coins = data.coins - before, idea = data.ideaMeter, ideaMax = Config.EurekaTasks }
end

-- 1.9: the progress path strip reads this (BrainService.state → career)
BrainService.hooks.careerInfo = function(data)
	local job = jobById(data.job)
	if not job or data.path ~= "Gain" then
		return nil
	end
	local c = careerOf(data)
	local info = { title = titleOf(job, c), level = c.level, xp = c.xp }
	if c.level < 4 then
		info.nextXP = CC.XPNeed[c.level + 1]
		info.nextIQ = levelIQ(job, c.level + 1)
	end
	return info
end

-- Re-offer a Eureka choice if the player left during the cutscene
Net.on("eureka_pending", function(player)
	local data = DataService.get(player)
	if data and data.eurekaChoices then
		local cards = {}
		for i, key in ipairs(data.eurekaChoices) do
			for _, inv in ipairs(Content.Inventions) do
				if inv.key == key then
					cards[i] = { key = inv.key, icon = inv.icon, name = inv.name, desc = inv.desc }
				end
			end
		end
		return { ok = true, choices = cards }
	end
	return { ok = false }
end)

---------------------------------------------------------------------
-- Secret inventions
---------------------------------------------------------------------
local function inventionByKey(key)
	for _, inv in ipairs(Content.Inventions) do
		if inv.key == key then
			return inv
		end
	end
	return nil
end

Net.on("invention_choose", function(player, d)
	local data = DataService.get(player)
	if not data or not data.eurekaChoices or not table.find(data.eurekaChoices, d.key) then
		return { ok = false }
	end
	local inv = inventionByKey(d.key)
	data.eurekaChoices = nil
	data.inventions[inv.key] = true
	BrainService.awardBadge(player, "Eureka")
	local count = 0
	for _ in pairs(data.inventions) do
		count += 1
	end
	if count >= #Content.Inventions then
		BrainService.awardBadge(player, "AllInventions")
	end
	if inv.key == "duck" then
		player:SetAttribute("DuckPet", true)
	end
	BrainService.push(player)
	return { ok = true, icon = inv.icon, name = inv.name, desc = inv.desc }
end)

Net.on("inventions_list", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local sess = s(player)
	sess.cooldowns = sess.cooldowns or {}
	local list = {}
	for _, inv in ipairs(Content.Inventions) do
		local owned = data.inventions[inv.key] == true
		table.insert(list, {
			key = inv.key,
			icon = owned and inv.icon or "❓",
			name = owned and inv.name or "??? (secret)",
			desc = owned and inv.desc or "Work jobs to fill your idea meter and unlock secret inventions.",
			owned = owned,
			cooldown = math.max(0, math.ceil((sess.cooldowns[inv.key] or 0) - os.clock())),
		})
	end
	return { ok = true, inventions = list, idea = data.ideaMeter, ideaMax = Config.EurekaTasks, places = WorldService.Places }
end)

Net.on("invention_use", function(player, d)
	local data = DataService.get(player)
	local inv = inventionByKey(d.key)
	if not data or not inv or not data.inventions[inv.key] then
		return { ok = false, msg = "You don't own that invention." }
	end
	local sess = s(player)
	sess.cooldowns = sess.cooldowns or {}
	if (sess.cooldowns[inv.key] or 0) > os.clock() then
		return { ok = false, msg = "Recharging… " .. math.ceil(sess.cooldowns[inv.key] - os.clock()) .. "s" }
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local msg
	if inv.key == "duck" then
		data.bonusHints = math.min(3, (data.bonusHints or 0) + 1)
		msg = "🦆 *quack* You explained your problem out loud. +1 Skill Gate hint (" .. data.bonusHints .. "/3)."
	elseif inv.key == "coffee" then
		if data.path ~= "Gain" then
			return { ok = false, msg = "Coffee only helps on the Gain path." }
		end
		BrainService.stress(player, -40)
		msg = "☕ Infinite coffee! Stress way down."
	elseif inv.key == "pigeons" then
		if root then
			WorldService.pigeonBurst(root.Position)
		end
		msg = "🐦 PIGEONS LAUNCHED."
	elseif inv.key == "rain" then
		if root then
			WorldService.brainRain(10, root.Position)
		end
		msg = "🧠 It's raining brains!"
	elseif inv.key == "boots" then
		Net.send(player, "lowGravity", { seconds = 30 })
		msg = "🥾 Anti-gravity ON for 30 seconds."
	elseif inv.key == "remote" then
		local key = tostring(d.place)
		if not WorldService.Spots[key] then
			return { ok = false, msg = "Pick a place." }
		end
		WorldService.teleport(player, key)
		msg = "📡 Bzzzt! Teleported."
	elseif inv.key == "goggles" then
		data.focusCharges = 3
		msg = "🥽 Focus! Your next 3 library/cinema answers give 1.5× brain cells."
	elseif inv.key == "rewind" then
		local hist = sess.history
		if char and hist and #hist >= 5 then
			char:PivotTo(hist[#hist - 4])
		end
		msg = "⏪ Rewound 5 seconds."
	elseif inv.key == "robot" then
		local job = jobById(data.job)
		if not job then
			return { ok = false, msg = "The robot needs you to have a job first." }
		end
		finishTask(player, data, job, true)
		msg = "🤖 Beep boop. Job task done. +" .. math.floor(job.coinsPerMinute * CC.TaskPay * payMult(data.career) + 0.5) .. " coins."
	end
	sess.cooldowns[inv.key] = os.clock() + inv.cooldown * (ProjectService.isActive("battery") and 0.5 or 1)
	return { ok = true, msg = msg }
end)

---------------------------------------------------------------------
-- Genius habits (lower stress)
---------------------------------------------------------------------
Net.on("habit_coffee_start", function(player)
	s(player).coffeeAt = os.clock()
	return { ok = true }
end)

Net.on("habit_coffee", function(player, d)
	local bad = guard(player, "Habits", true)
	if bad then
		return bad
	end
	local count = tonumber(d.count) or 0
	-- the server times the counting (opened with habit_coffee_start), so a script can't just send 60
	local started = s(player).coffeeAt
	s(player).coffeeAt = nil
	if not started or os.clock() - started < Config.MinigameMinSeconds.Coffee then
		return { ok = true, msg = "Too fast! Beethoven counts every bean slowly. No stress relief." }
	end
	if count == 60 then
		BrainService.stress(player, -35)
		BrainService.awardBadge(player, "Coffee60")
		return { ok = true, msg = "Exactly 60 beans. Beethoven nods approvingly. ☕ Stress down!" }
	end
	return { ok = true, msg = "You counted " .. count .. ". Beethoven counted EXACTLY 60. No stress relief." }
end)

Net.on("habit_nap_start", function(player)
	local bad = guard(player, "Habits", true)
	if bad then
		return bad
	end
	local delay = math.random(30, 80) / 10
	s(player).nap = { issued = os.clock(), delay = delay }
	return { ok = true, delay = delay }
end)

Net.on("habit_nap_tap", function(player)
	local nap = s(player).nap
	if not nap then
		return { ok = false }
	end
	s(player).nap = nil
	local elapsed = os.clock() - nap.issued
	if elapsed < nap.delay - 0.25 then
		return { ok = true, msg = "Too early! You didn't even fall asleep." }
	elseif elapsed > nap.delay + 1.5 then
		return { ok = true, msg = "You overslept! Edison is disappointed." }
	end
	BrainService.stress(player, -30)
	return { ok = true, msg = "Perfect power nap! 😴 Stress down!" }
end)

Net.on("habit_pigeons", function(player)
	local bad = guard(player, "Habits", true)
	if bad then
		return bad
	end
	local sess = s(player)
	if sess.pigeons and os.clock() < sess.pigeons then
		return { ok = true, msg = "The pigeons are full. Come back in " .. math.ceil(sess.pigeons - os.clock()) .. "s." }
	end
	sess.pigeons = os.clock() + 45
	BrainService.stress(player, -15)
	return { ok = true, msg = "🐦 The pigeons love you. Tesla would be proud. Stress down!" }
end)

---------------------------------------------------------------------
-- Cash-grab joke shop and the Perfectly Average guy
---------------------------------------------------------------------
function GainService.cashGrab(player, btn)
	local data = DataService.get(player)
	if not data then
		return
	end
	if btn.key == "iq" then
		data.perks.DunceCap = true
		BrainService.applyCharacter(player)
	end
	BrainService.toast(player, btn.result, "SadTrombone")
	if Brain.artTier(data.cells) == "cashgrab" then
		BrainService.say(player, "Imagine falling for a BUY NOW button. 💀")
	else
		BrainService.say(player, "You can read the disclaimer now. It says the button does nothing.")
	end
end

local averageVisits = {} -- [player] = how many times they talked to him this session
function GainService.averageGuy(player)
	BrainService.awardBadge(player, "PerfectlyAverage")
	local n = (averageVisits[player] or 0) + 1
	averageVisits[player] = n
	local lines = Content.AverageGuy
	BrainService.toast(player, lines[math.min(n, #lines)], "NotificationPing")
	HorrorService.talked(player)
end
Players.PlayerRemoving:Connect(function(p)
	averageVisits[p] = nil
end)

---------------------------------------------------------------------
-- Loops
---------------------------------------------------------------------
function GainService.reset(player)
	sessions[player] = nil
	task.defer(applyUniform, player) -- path changed: put the uniform on or take it off
end

function GainService.start()
	-- 1.6: put the work uniform back on after respawning
	local function watch(p)
		p.CharacterAdded:Connect(function()
			task.delay(1.5, applyUniform, p)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
		task.delay(1.5, applyUniform, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
	end)
	-- position history for the Pocket Time Machine
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					local sess = s(player)
					sess.history = sess.history or {}
					table.insert(sess.history, root.CFrame)
					if #sess.history > 10 then
						table.remove(sess.history, 1)
					end
				end
			end
		end
	end)
	-- passive job pay + slow stress recovery
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.get(player)
				if data and data.path == "Gain" then
					local job = jobById(data.job)
					-- wages only while actually working: clocked in (LifeService sets OnShift) and at the workplace
					local working = job ~= nil
					if job and Config.Life.Shift.WagesNeedShift then
						local pos = WorldService.workPos(player, job.place)
						working = player:GetAttribute("OnShift") == true
							and pos ~= nil
							and WorldService.near(player, pos, Config.WorkRadius)
					end
					if job and working then
						local pay = math.floor(job.coinsPerMinute * payMult(careerOf(data)) + 0.5)
						data.coins += pay
						BoardService.addPay(player, pay)
						BrainService.push(player)
					end
					if data.stress > 0 then
						BrainService.stress(player, -3)
					end
				end
			end
		end
	end)
end

return GainService

-- SocialService (update 1.2): Smart vs Dumb.
-- Players join an activity as a role (opt-in). If nobody joins the other role
-- within a few seconds, an NPC plays it. Every activity uses preset choices only.
--   Classroom, Courtroom, Debate Show, Doctor, Therapist, Animal Experiments,
--   Journalist (solo) and the Election (server event).

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
local LoseService = require(script.Parent.LoseService)

local SocialService = {}

local STEP_SECONDS = 15
local NPC_WAIT = 10

local function pick(list)
	return list[math.random(1, #list)]
end

local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function iqOf(player): number
	local d = DataService.get(player)
	return d and Brain.iq(d.cells) or 0
end

local function stageOf(player): string
	local d = DataService.get(player)
	return d and Brain.stage(d.cells, BrainService.secretAnimals).key or "human"
end

local function pathOf(player): string?
	local d = DataService.get(player)
	return d and not d.dead and d.path or nil
end

local function jobOf(player): string?
	local d = DataService.get(player)
	return d and d.job or nil
end

---------------------------------------------------------------------
-- Content for the activities
---------------------------------------------------------------------
local TRICK_QUESTIONS = Content.SocialText.TrickQuestions

local CASES = {
	"left a banana peel in the hallway",
	"microwaved a fork",
	"drove a shopping cart into the fountain",
	"tried to pay for pizza with a leaf",
	"walked into the mayor. Twice.",
}

local STATEMENTS = {
	{ text = "The banana told me to do it.", kind = "dumb", dumb = 3 },
	{ text = "I thought the fork was a spoon.", kind = "dumb", dumb = 2 },
	{ text = "I wasn't even there. I was a rock that day.", kind = "deny", dumb = 2 },
	{ text = "That wasn't me, that was my twin, Me 2.", kind = "deny", dumb = 3 },
	{ text = "Here is my evidence: a sock.", kind = "weird", dumb = 3 },
	{ text = "I have a video of a cat. It proves nothing.", kind = "weird", dumb = 2 },
}

local MOVES = {
	{ text = "🗣 OBJECTION!", best = "deny" },
	{ text = "🧠 \"Your Honor, my client has the brain of a fruit fly. Literally.\"", best = "dumb" },
	{ text = "📁 \"Let's look at that evidence very closely…\"", best = "weird" },
}

local DEBATE_TOPICS = {
	"Should homework be optional?",
	"Is a hot dog a sandwich?",
	"Should we build the teleporter?",
	"Are pigeons secretly geniuses?",
}

local ARGUMENTS = {
	{ text = "Here's the evidence, and here's why it matters.", strength = 3 },
	{ text = "Let's compare both sides fairly.", strength = 2 },
	{ text = "Because I said so.", strength = 1 },
	{ text = "My cousin told me.", strength = 1 },
	{ text = "Studies show both pros and cons; on balance, yes.", strength = 3 },
	{ text = "What if… we just didn't?", strength = 1 },
}

local SYMPTOMS = {
	{ text = "🧠💧 Brain cells are leaking out of the ears.", treat = "🧩 Brain-builder puzzle pill" },
	{ text = "😵 Keeps walking into walls on purpose.", treat = "📚 Two chapters of a book, twice a day" },
	{ text = "📱 Can't stop scrolling.", treat = "📵 Phone-free afternoon" },
}

local FEELINGS = {
	{ text = "😰 Stressed about the Skill Gate", answer = "🌬 Slow breathing: in 4, out 6" },
	{ text = "🥱 Exhausted from work", answer = "😴 A short nap, like Edison" },
	{ text = "🤯 Overwhelmed by too many facts", answer = "📝 Write things down, one at a time" },
}

local EXPERIMENTS = {
	dog = { title = "🐶 Pavlov's Bell", scientist = { "🔔 Ring the bell", "🍖 Show food", "🔔🍖 Bell, then food" }, animal = { smart = "🤤 Drool at the bell", dumb = "🐕 Chase your tail", other = "🐾 Sit" } },
	octopus = { title = "🐙 The Escape Tank", scientist = { "🔓 Leave the lid open", "🔒 Lock the lid", "🍤 Put a shrimp outside" }, animal = { smart = "🚪 Escape", dumb = "💦 Stay stuck forever", other = "🎨 Change color" } },
	mouse = { title = "🐭 The Maze", scientist = { "🧀 Cheese on the left", "🧀 Cheese on the right", "🧀 Cheese straight ahead" }, animal = { smart = "👃 Follow the smell", dumb = "🌀 Run in circles", other = "😴 Nap" } },
	bee = { title = "🐝 The Waggle Dance", scientist = { "🌸 Point at the flowers", "📝 Take notes", "🎥 Film the dance" }, animal = { smart = "💃 Dance the real directions", dumb = "🌀 Dance total nonsense", other = "🍯 Make honey" } },
	fly = { title = "🦟 The Genetics Lab", scientist = { "🔬 Use the microscope", "🧬 Check the DNA", "🍌 Offer a banana" }, animal = { smart = "🍌 Go to the banana", dumb = "💡 Fly into the lamp", other = "🖼 Bump the window" } },
	worm = { title = "🐛 Darwin's Worm Concert", scientist = { "🎺 Play the bassoon", "🎹 Play the piano", "📣 Shout" }, animal = { smart = "🕺 Wiggle to the beat", dumb = "😐 Ignore the music", other = "🌱 Dig" } },
	microbe = { title = "🦠 The Microscope", scientist = { "🔬 Zoom in", "💧 Add a drop", "🧫 New petri dish" }, animal = { smart = "➡️ Swim to the food", dumb = "🌀 Spin aimlessly", other = "💦 Split in two" } },
	tardigrade = { title = "🐛 Extreme Survival Test", scientist = { "🧊 Freeze it", "🔥 Heat it", "🚀 Space vacuum" }, animal = { smart = "🛡 Survive cleverly", dumb = "😴 Just sleep through it", other = "🐾 Walk away" } },
}

---------------------------------------------------------------------
-- Activity definitions: role a = smart side, role b = dumb side
---------------------------------------------------------------------
local ACT = {}

ACT.classroom = {
	name = "🏫 Classroom",
	desc = "The teacher asks trick questions. The student must FAIL.",
	a = { label = "Teacher", path = "Gain", minIQ = 105, jobs = { "teacher", "professor" } },
	b = { label = "Student", path = "Lose", humanOnly = true },
	rounds = 3,
	round = function(sess)
		return {
			{
				role = "a",
				prompt = function()
					sess.cands = { TRICK_QUESTIONS[math.random(1, #TRICK_QUESTIONS)], TRICK_QUESTIONS[math.random(1, #TRICK_QUESTIONS)], TRICK_QUESTIONS[math.random(1, #TRICK_QUESTIONS)] }
					return "Pick a trick question. Make it HARD for them to fail."
				end,
				options = function()
					return { sess.cands[1].q, sess.cands[2].q, sess.cands[3].q }
				end,
				onPick = function(i)
					sess.q = sess.cands[i]
				end,
			},
			{
				role = "b",
				prompt = function()
					return "❓ " .. sess.q.q .. "\n(You want to get it WRONG.)"
				end,
				options = function()
					return sess.q.options
				end,
				onPick = function(i)
					if i == sess.q.correct then
						sess:gain("b", 1)
						sess:gain("a", 1.5)
						sess:line("😭 The student accidentally got it RIGHT. Teacher wins this round.")
					else
						sess:lose("b", 2)
						sess:line("✅ The student failed perfectly. 🧠📉")
					end
				end,
			},
		}
	end,
}

ACT.courtroom = {
	name = "⚖️ Courtroom",
	desc = "A dumb player gets sued. The lawyer defends them. The defendant says dumb things.",
	a = { label = "Lawyer", path = "Gain", minIQ = 120, jobs = { "lawyer" } },
	b = { label = "Defendant", path = "Lose" },
	rounds = 3,
	setup = function(sess)
		sess.case = pick(CASES)
		sess.wins = 0
		sess:line("👨‍⚖️ Case: the defendant " .. sess.case .. ".")
	end,
	round = function(sess)
		return {
			{
				role = "b",
				prompt = function()
					sess.st = shuffle({ STATEMENTS[1], STATEMENTS[3], STATEMENTS[5], pick(STATEMENTS) })
					return "🧑‍⚖️ The judge asks what happened. Say something DUMB."
				end,
				options = function()
					return { sess.st[1].text, sess.st[2].text, sess.st[3].text }
				end,
				onPick = function(i)
					sess.said = sess.st[i]
					sess:lose("b", 1 + sess.said.dumb / 2)
					sess:line("🗣 Defendant: \"" .. sess.said.text .. "\"")
				end,
			},
			{
				role = "a",
				prompt = function()
					return "Your client just said: \"" .. sess.said.text .. "\"\nPick the best defense move."
				end,
				options = function()
					return { MOVES[1].text, MOVES[2].text, MOVES[3].text }
				end,
				onPick = function(i)
					if MOVES[i].best == sess.said.kind then
						sess.wins += 1
						sess:line("⚖️ Lawyer: " .. MOVES[i].text .. "  (the jury nods)")
					else
						sess:line("⚖️ Lawyer: " .. MOVES[i].text .. "  (the jury is confused)")
					end
				end,
			},
		}
	end,
	finish = function(sess)
		if sess.wins >= 2 then
			sess:gain("a", 4)
			sess:line("🔨 NOT GUILTY! The lawyer wins big.")
		else
			sess:line("🔨 GUILTY! Community service: picking up banana peels.")
			local p = sess.players.b
			if p then
				p:SetAttribute("PunishSign", "I " .. string.upper(sess.case))
				BrainService.applyCharacter(p)
				task.delay(60, function()
					if p.Parent then
						p:SetAttribute("PunishSign", nil)
						BrainService.applyCharacter(p)
					end
				end)
			end
		end
	end,
}

ACT.debate = {
	name = "🎙 Debate Show",
	desc = "Live TV! The smart one wants to win the argument. The dumb one wins by losing it badly.",
	a = { label = "Smart Debater", path = "Gain", minIQ = 95 },
	b = { label = "Dumb Debater", path = "Lose" },
	rounds = 3,
	setup = function(sess)
		sess.topic = pick(DEBATE_TOPICS)
		sess.aScore, sess.bScore = 0, 0
		sess:line("📺 Tonight's topic: " .. sess.topic)
	end,
	round = function(sess)
		local function opts()
			local o = shuffle({ ARGUMENTS[1], ARGUMENTS[3], ARGUMENTS[math.random(1, #ARGUMENTS)] })
			return o
		end
		return {
			{
				role = "a",
				prompt = function()
					sess.ao = opts()
					return "Make your strongest argument."
				end,
				options = function()
					return { sess.ao[1].text, sess.ao[2].text, sess.ao[3].text }
				end,
				onPick = function(i)
					local s = sess.ao[i].strength
					sess.aScore += s
					sess:gain("a", s * 0.6)
					sess:line("🤓 \"" .. sess.ao[i].text .. "\"")
				end,
			},
			{
				role = "b",
				prompt = function()
					sess.bo = opts()
					return "Make your WORST argument."
				end,
				options = function()
					return { sess.bo[1].text, sess.bo[2].text, sess.bo[3].text }
				end,
				onPick = function(i)
					local weak = 4 - sess.bo[i].strength
					sess.bScore += weak
					sess:lose("b", weak * 0.8)
					sess:line("🤪 \"" .. sess.bo[i].text .. "\"")
				end,
			},
		}
	end,
	finish = function(sess)
		local total = math.max(1, sess.aScore + (9 - sess.bScore))
		local pct = math.floor(sess.aScore / total * 100 + 0.5)
		sess:line("🗳 Audience vote: Smart " .. pct .. "% • Dumb " .. (100 - pct) .. "%. Everyone got what they wanted.")
	end,
}

ACT.doctor = {
	name = "🏥 Doctor",
	desc = "The doctor treats a leaking brain. The patient must avoid the medicine.",
	a = { label = "Doctor", path = "Gain", minIQ = 115, jobs = { "doctor" } },
	b = { label = "Patient", path = "Lose" },
	rounds = 2,
	round = function(sess)
		return {
			{
				role = "a",
				prompt = function()
					sess.sym = pick(SYMPTOMS)
					local opts = { sess.sym.treat }
					for _, s in ipairs(SYMPTOMS) do
						if s ~= sess.sym then
							table.insert(opts, s.treat)
						end
					end
					sess.treats = shuffle(opts)
					return "Patient symptoms: " .. sess.sym.text .. "\nPrescribe the right treatment."
				end,
				options = function()
					return sess.treats
				end,
				onPick = function(i)
					sess.correct = sess.treats[i] == sess.sym.treat
					sess:line("🩺 Doctor prescribes: " .. sess.treats[i])
				end,
			},
			{
				role = "b",
				prompt = function()
					return "The doctor hands you medicine. What do you do?"
				end,
				options = function()
					return { "💊 Take it", "🙈 Hide it in your sock", "🤮 Spit it out" }
				end,
				onPick = function(i)
					if i == 1 and sess.correct then
						sess:gain("b", 1)
						sess:gain("a", 2)
						sess:line("✅ The patient took the right medicine. Brain cells restored (oops).")
					elseif i == 1 then
						sess:line("🤷 The patient took the wrong medicine. Nothing happened.")
					else
						sess:lose("b", 1.5)
						if sess.correct then
							sess:gain("a", 0.5)
						end
						sess:line("🙈 The patient refused the medicine. Classic.")
					end
				end,
			},
		}
	end,
}

ACT.therapist = {
	name = "🛋 Therapist",
	desc = "Smart players help each other lower stress.",
	a = { label = "Therapist", path = "Gain", minIQ = 110 },
	b = { label = "Client", path = "Gain", minStress = 15 },
	rounds = 2,
	round = function(sess)
		return {
			{
				role = "b",
				prompt = function()
					return "How are you feeling?"
				end,
				options = function()
					return { FEELINGS[1].text, FEELINGS[2].text, FEELINGS[3].text }
				end,
				onPick = function(i)
					sess.feel = FEELINGS[i]
					sess:line("🛋 Client: " .. sess.feel.text)
				end,
			},
			{
				role = "a",
				prompt = function()
					return "Your client says: " .. sess.feel.text .. "\nWhat do you suggest?"
				end,
				options = function()
					return { FEELINGS[1].answer, FEELINGS[2].answer, FEELINGS[3].answer }
				end,
				onPick = function(i)
					if FEELINGS[i].answer == sess.feel.answer then
						sess:stress("b", -25)
						sess:gain("a", 1.5)
						sess:line("💚 Great advice. The client feels much better.")
					else
						sess:stress("b", -5)
						sess:line("🤔 Okay advice. A little better.")
					end
				end,
			},
		}
	end,
}

ACT.experiment = {
	name = "🔬 Animal Experiments",
	desc = "A scientist studies a player who turned into an animal. The animal must act dumb.",
	a = { label = "Scientist", path = "Gain", minIQ = 130, jobs = { "scientist" } },
	b = { label = "Animal", path = "Lose", animalOnly = true },
	rounds = 3,
	setup = function(sess)
		local stage = sess.players.b and stageOf(sess.players.b) or pick({ "dog", "mouse", "octopus", "bee", "worm" })
		sess.exp = EXPERIMENTS[stage] or EXPERIMENTS.dog
		sess:line(sess.exp.title)
	end,
	round = function(sess)
		return {
			{
				role = "a",
				prompt = function()
					return sess.exp.title .. "\nRun the experiment."
				end,
				options = function()
					return sess.exp.scientist
				end,
				onPick = function(i)
					sess:line("🔬 Scientist: " .. sess.exp.scientist[i])
				end,
			},
			{
				role = "b",
				prompt = function()
					sess.ao = shuffle({ "smart", "dumb", "other" })
					return "React! (The dumbest reaction is best for you.)"
				end,
				options = function()
					local out = {}
					for i, k in ipairs(sess.ao) do
						out[i] = sess.exp.animal[k]
					end
					return out
				end,
				onPick = function(i)
					local kind = sess.ao[i]
					if kind == "smart" then
						sess:gain("b", 1)
						sess:gain("a", 2)
						sess:line("📈 The animal LEARNED something. Science wins.")
					elseif kind == "dumb" then
						sess:lose("b", 2)
						sess:gain("a", 0.3)
						sess:line("📉 " .. sess.exp.animal.dumb .. ". Perfectly dumb.")
					else
						sess:line("🤷 " .. sess.exp.animal.other .. ". Inconclusive.")
					end
				end,
			},
		}
	end,
}

---------------------------------------------------------------------
-- Eligibility and queues
---------------------------------------------------------------------
local queues = {} -- [act][roleKey] = { player... }
local inSession = {} -- [player] = session
local sessions = {} -- [id] = session
local nextId = 0

for key in pairs(ACT) do
	queues[key] = { a = {}, b = {} }
end

local function eligible(player, actKey: string, roleKey: string): (boolean, string?)
	local act = ACT[actKey]
	local role = act and act[roleKey]
	if not role then
		return false, "Unknown role."
	end
	if pathOf(player) ~= role.path then
		return false, "Needs the " .. role.path .. " path."
	end
	if role.minIQ then
		local hasJob = role.jobs and table.find(role.jobs, jobOf(player) or "") ~= nil
		if iqOf(player) < role.minIQ and not hasJob then
			return false, "Needs IQ " .. role.minIQ .. "+" .. (role.jobs and (" or the right job") or "")
		end
	end
	local stage = stageOf(player)
	if role.humanOnly and stage ~= "human" and stage ~= "barelyhuman" then
		return false, "You're a " .. stage .. ". Animals can't go to school."
	end
	if role.animalOnly and (stage == "human" or stage == "barelyhuman" or stage == "dead") then
		return false, "Only players who turned into animals."
	end
	if role.minStress then
		local d = DataService.get(player)
		if not d or d.stress < role.minStress then
			return false, "You're not stressed enough to need therapy. 😎"
		end
	end
	return true
end

local function removeFromQueues(player)
	for _, q in pairs(queues) do
		for _, list in pairs(q) do
			local i = table.find(list, player)
			if i then
				table.remove(list, i)
			end
		end
	end
end

---------------------------------------------------------------------
-- Session engine
---------------------------------------------------------------------
local Session = {}
Session.__index = Session

function Session:line(text: string)
	table.insert(self.transcript, text)
end
function Session:gain(role: string, points: number)
	local p = self.players[role]
	if p and p.Parent then
		BrainService.gain(p, points, "social")
	end
end
function Session:lose(role: string, points: number)
	local p = self.players[role]
	if p and p.Parent then
		BrainService.lose(p, points, "social")
	end
end
function Session:stress(role: string, amount: number)
	local p = self.players[role]
	if p and p.Parent then
		BrainService.stress(p, amount)
	end
end

local function partnerName(sess, role: string): string
	local other = role == "a" and "b" or "a"
	local p = sess.players[other]
	return p and p.DisplayName or (sess.act[other].label .. " (NPC)")
end

local function sendTo(sess, role: string, kind: string, payload)
	local p = sess.players[role]
	if p and p.Parent then
		payload.sessionId = sess.id
		payload.title = sess.act.name
		payload.role = sess.act[role].label
		payload.partner = partnerName(sess, role)
		payload.transcript = { table.unpack(sess.transcript, math.max(1, #sess.transcript - 5)) }
		Net.send(p, kind, payload)
	end
end

local function runSession(sess)
	local act = sess.act
	for _, role in ipairs({ "a", "b" }) do
		sendTo(sess, role, "social_start", { text = act.desc })
	end
	if act.setup then
		act.setup(sess)
	end
	for r = 1, act.rounds do
		local okRound, steps = pcall(act.round, sess)
		for _, step in ipairs(okRound and steps or {}) do
			local okP, prompt = pcall(step.prompt)
			local okO, options = pcall(step.options)
			if not okP or not okO or typeof(options) ~= "table" or #options == 0 then
				warn("[Social] skipped a broken step in " .. act.name)
				continue
			end
			local human = sess.players[step.role]
			local choice = nil
			if human and human.Parent then
				sess.waiting = { role = step.role, count = #options }
				sess.answer = nil
				sendTo(sess, step.role, "social_step", { prompt = prompt, options = options, seconds = STEP_SECONDS, round = r, rounds = act.rounds })
				local other = step.role == "a" and "b" or "a"
				sendTo(sess, other, "social_wait", { text = "Waiting for " .. partnerName(sess, other) .. "…", round = r, rounds = act.rounds })
				local t = os.clock()
				while sess.answer == nil and os.clock() - t < STEP_SECONDS + 1 and human.Parent do
					task.wait(0.2)
				end
				choice = sess.answer
			else
				task.wait(1.2) -- NPC "thinks"
			end
			if not choice or choice < 1 or choice > #options then
				choice = math.random(1, #options)
			end
			sess.waiting = nil
			pcall(step.onPick, choice)
		end
	end
	if act.finish then
		pcall(act.finish, sess)
	end
	for _, role in ipairs({ "a", "b" }) do
		sendTo(sess, role, "social_end", { lines = sess.transcript })
		local p = sess.players[role]
		if p then
			inSession[p] = nil
		end
	end
	sessions[sess.id] = nil
end

local function startSession(actKey: string, a: Player?, b: Player?)
	nextId += 1
	local sess = setmetatable({
		id = nextId,
		act = ACT[actKey],
		players = { a = a, b = b },
		transcript = {},
	}, Session)
	sessions[sess.id] = sess
	if a then
		inSession[a] = sess
	end
	if b then
		inSession[b] = sess
	end
	task.spawn(runSession, sess)
end

local function tryMatch(actKey: string)
	local q = queues[actKey]
	while #q.a > 0 and #q.b > 0 do
		local a = table.remove(q.a, 1)
		local b = table.remove(q.b, 1)
		if a.Parent and b.Parent and a ~= b then
			startSession(actKey, a, b)
		end
	end
end

Net.on("social_list", function(player)
	local list = {}
	for key, act in pairs(ACT) do
		local roles = {}
		for _, roleKey in ipairs({ "a", "b" }) do
			local ok, why = eligible(player, key, roleKey)
			table.insert(roles, { key = roleKey, label = act[roleKey].label, ok = ok, why = why, waiting = #queues[key][roleKey] })
		end
		table.insert(list, { key = key, name = act.name, desc = act.desc, roles = roles })
	end
	table.sort(list, function(x, y)
		return x.name < y.name
	end)
	local queued = nil
	for key, q in pairs(queues) do
		for roleKey, l in pairs(q) do
			if table.find(l, player) then
				queued = ACT[key].name .. " as " .. ACT[key][roleKey].label
			end
		end
	end
	return {
		ok = true,
		activities = list,
		queued = queued,
		canJournal = pathOf(player) == "Gain" and iqOf(player) >= 100,
	}
end)

Net.on("social_join", function(player, d)
	local actKey, roleKey = tostring(d.act), tostring(d.role)
	if inSession[player] then
		return { ok = false, msg = "You're already in an activity." }
	end
	local ok, why = eligible(player, actKey, roleKey)
	if not ok then
		return { ok = false, msg = why }
	end
	if BrainService.blocked(player) then
		return { ok = false, msg = BrainService.blocked(player) }
	end
	removeFromQueues(player)
	table.insert(queues[actKey][roleKey], player)
	tryMatch(actKey)
	if not inSession[player] then
		-- nobody else? an NPC takes the other role after a few seconds
		task.delay(NPC_WAIT, function()
			local list = queues[actKey][roleKey]
			local i = table.find(list, player)
			if i and player.Parent and not inSession[player] then
				table.remove(list, i)
				if roleKey == "a" then
					startSession(actKey, player, nil)
				else
					startSession(actKey, nil, player)
				end
			end
		end)
		return { ok = true, msg = "Looking for a partner… (an NPC joins in " .. NPC_WAIT .. "s if nobody does)" }
	end
	return { ok = true, msg = "Matched!" }
end)

Net.on("social_leave", function(player)
	removeFromQueues(player)
	return { ok = true, msg = "Left the queue." }
end)

Net.on("social_answer", function(player, d)
	local sess = inSession[player]
	if not sess or tonumber(d.sessionId) ~= sess.id or not sess.waiting then
		return { ok = false }
	end
	if sess.players[sess.waiting.role] ~= player then
		return { ok = false }
	end
	local c = tonumber(d.choice)
	if c and c >= 1 and c <= sess.waiting.count then
		sess.answer = c
	end
	return { ok = true }
end)

-- Get sued (called by the Lose path after a dumb action)
function SocialService.maybeSue(player)
	if inSession[player] or math.random() > 0.06 then
		return
	end
	Net.send(player, "sued", { case = pick(CASES) })
end

Net.on("sued_accept", function(player)
	local ok, why = eligible(player, "courtroom", "b")
	if not ok then
		return { ok = false, msg = why }
	end
	removeFromQueues(player)
	table.insert(queues.courtroom.b, player)
	tryMatch("courtroom")
	if not inSession[player] then
		task.delay(4, function()
			local i = table.find(queues.courtroom.b, player)
			if i and player.Parent and not inSession[player] then
				table.remove(queues.courtroom.b, i)
				startSession("courtroom", nil, player)
			end
		end)
	end
	return { ok = true, msg = "⚖️ Court is in session…" }
end)

---------------------------------------------------------------------
-- Journalist (solo): write headlines that become clickbait for dumb players
---------------------------------------------------------------------
local HEADLINE_PARTS = {
	starts = { "You Won't BELIEVE", "Scientists HATE", "Doctors Don't Want You to Know", "This One Weird Trick:", "BREAKING:", "Top 10 Reasons" },
	subjects = { "This Pigeon", "A Local Toaster", "The Mayor's Sock", "Your Brain Cells", "A Banana", "This Microwave" },
	endings = { "(GONE WRONG) 😱", "Will SHOCK You", "…Number 7 Is Crazy", "In Just 5 Seconds", "(NOT CLICKBAIT)", "And Nobody Noticed" },
}

Net.on("journal_parts", function(player)
	if pathOf(player) ~= "Gain" or iqOf(player) < 100 then
		return { ok = false, msg = "Journalists need the Gain path and IQ 100+." }
	end
	return { ok = true, parts = HEADLINE_PARTS }
end)

Net.on("journal_publish", function(player, d)
	if pathOf(player) ~= "Gain" or iqOf(player) < 100 then
		return { ok = false }
	end
	local s = HEADLINE_PARTS.starts[tonumber(d.s) or 0]
	local m = HEADLINE_PARTS.subjects[tonumber(d.m) or 0]
	local e = HEADLINE_PARTS.endings[tonumber(d.e) or 0]
	if not s or not m or not e then
		return { ok = false, msg = "Pick all three parts." }
	end
	local headline = s .. " " .. m .. " " .. e
	LoseService.addJournalistHeadline(headline, player.UserId)
	BrainService.gain(player, 0.5, "journal")
	return { ok = true, msg = "📰 Published: \"" .. headline .. "\". You'll get brain cells every time a dumb player clicks it." }
end)

---------------------------------------------------------------------
-- The Election (server event)
---------------------------------------------------------------------
local SPEECHES = Content.SocialText.Speeches
local election = nil

local function runElection()
	if election then
		return false
	end
	local gainers, losers = {}, {}
	for _, p in ipairs(Players:GetPlayers()) do
		local path = pathOf(p)
		if path == "Gain" then
			table.insert(gainers, p)
		elseif path == "Lose" then
			table.insert(losers, p)
		end
	end
	local cands = {
		{ path = "Gain", player = #gainers > 0 and pick(gainers) or nil, npc = "Professor Noodle (NPC)" },
		{ path = "Lose", player = #losers > 0 and pick(losers) or nil, npc = "Mayor McBrainface (NPC)" },
	}
	election = { cands = cands, votes = { 0, 0 }, voted = {} }
	for i, c in ipairs(cands) do
		c.name = c.player and c.player.DisplayName or c.npc
		c.speech = pick(SPEECHES[c.path])
		if c.player then
			Net.send(c.player, "election_speech", { options = SPEECHES[c.path], index = i })
		end
	end
	Net.broadcast("announce", { text = "🗳 ELECTION TIME! " .. cands[1].name .. " (smart) vs " .. cands[2].name .. " (dumb). Speeches in 15s, then vote!", by = "Dr. Wrinkles" })
	task.wait(15)
	Net.broadcast("election_vote", {
		cands = { { name = cands[1].name, speech = cands[1].speech, path = "Gain" }, { name = cands[2].name, speech = cands[2].speech, path = "Lose" } },
		seconds = 20,
	})
	task.wait(21)
	-- a few NPC voters keep it interesting
	for _ = 1, 3 do
		local i = math.random(1, 2)
		election.votes[i] += 1
	end
	local winner = election.votes[1] >= election.votes[2] and 1 or 2
	local w = cands[winner]
	BrainService.boost.Gain, BrainService.boost.Lose = 1, 1
	if w.path == "Gain" then
		BrainService.boost.Gain = 1.25
	else
		BrainService.boost.Lose = 1.25
	end
	WorldService.setBanner("🏆 MAYOR " .. string.upper(w.name), w.path == "Gain" and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(255, 50, 170))
	Net.broadcast("election_result", {
		text = "🏆 " .. w.name .. " wins (" .. election.votes[1] .. " – " .. election.votes[2] .. ")! " .. (w.path == "Gain" and "Gain path: +25% brain cells for 10 minutes." or "Lose path: losing brain cells is 25% faster for 10 minutes."),
	})
	election = nil
	task.delay(600, function()
		BrainService.boost.Gain, BrainService.boost.Lose = 1, 1
	end)
	return true
end
SocialService.runElection = runElection

Net.on("election_speech", function(player, d)
	if not election then
		return { ok = false }
	end
	for _, c in ipairs(election.cands) do
		if c.player == player then
			local s = SPEECHES[c.path][tonumber(d.choice) or 0]
			if s then
				c.speech = s
			end
		end
	end
	return { ok = true }
end)

Net.on("election_cast", function(player, d)
	if not election or election.voted[player] then
		return { ok = false, msg = "You already voted." }
	end
	local i = tonumber(d.choice)
	if i ~= 1 and i ~= 2 then
		return { ok = false }
	end
	election.voted[player] = true
	election.votes[i] += 1
	return { ok = true, msg = "🗳 Vote counted!" }
end)

-- 1.7.3: Vs Mode lobby sign near spawn, so friends can see who is waiting and for which side
local function lobbySign()
	local TV = Content.VsLobby
	local p = Instance.new("Part")
	p.Name = "VsLobbySign"
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = Config.VsLobbySignPos
	p.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 100)
	bb.MaxDistance = 60
	bb.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
	l.BackgroundTransparency = 0.2
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Parent = bb
	local c = Instance.new("UICorner")
	c.Parent = l
	task.spawn(function()
		while true do
			local lines = { TV.Title }
			for key, act in pairs(ACT) do
				for _, roleKey in ipairs({ "a", "b" }) do
					local n = #queues[key][roleKey]
					if n > 0 then
						local other = roleKey == "a" and "b" or "a"
						table.insert(lines, string.format(TV.Waiting, n, act.name, act[roleKey].label, act[other].label))
					end
				end
			end
			if #lines == 1 then
				table.insert(lines, TV.Nobody)
			end
			l.Text = table.concat(lines, "\n")
			task.wait(3)
		end
	end)
end

function SocialService.start()
	lobbySign()
	LoseService.onDumbAction = SocialService.maybeSue
	Players.PlayerRemoving:Connect(function(p)
		removeFromQueues(p)
		inSession[p] = nil
	end)
	task.spawn(function()
		while true do
			task.wait((Config.ElectionMinutes or 20) * 60)
			if #Players:GetPlayers() >= 1 then
				pcall(runElection)
			end
		end
	end)
end

return SocialService

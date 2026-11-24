-- LoseService: everything on the Lose path (reading popups, clickbait,
-- Steal A / Fix A / Make A, comments, scroller, zones, the death ending).

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

local LoseService = {}

local sessions = {} -- [player] = { reading, nextReading, clickbait, steal, comment, lastSwipe }
local journalistHeadlines = {} -- { text, author } written by Gain players (update 1.2)
LoseService.onDumbAction = nil -- set by SocialService: maybe get sued

function LoseService.addJournalistHeadline(text: string, author: number)
	table.insert(journalistHeadlines, 1, { text = text, author = author })
	while #journalistHeadlines > 20 do
		table.remove(journalistHeadlines)
	end
end

local function dumbAction(player)
	if LoseService.onDumbAction then
		LoseService.onDumbAction(player)
	end
end
local nextId = 0

local function s(player)
	local x = sessions[player]
	if not x then
		x = { nextReading = os.clock() + math.random(Config.ReadingPopupMin, Config.ReadingPopupMax) }
		sessions[player] = x
	end
	return x
end

local function newId(): number
	nextId += 1
	return nextId
end

local function onLose(player): boolean
	local data = DataService.get(player)
	return data ~= nil and data.path == "Lose" and not data.dead
end

local function tierFor(cells: number): number
	if cells >= 70e9 then
		return 1
	elseif cells >= Config.HumanFloorCells then
		return 2
	elseif cells >= 1e9 then
		return 3
	end
	return 4
end

local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function guard(player, feature: string)
	if not onLose(player) then
		return { ok = false, msg = "This is for the Lose path." }
	end
	if not BrainService.feature(feature) then
		return { ok = false, msg = "This is turned off right now." }
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		return { ok = false, msg = blocked }
	end
	return nil
end

---------------------------------------------------------------------
-- Reading popups
---------------------------------------------------------------------
local function sendReading(player)
	local data = DataService.get(player)
	local sess = s(player)
	if not data or sess.reading then
		return
	end
	local isTOS = math.random() < Config.TOSChance and not data.badges.ReadTOS
	local text = isTOS and Content.TermsOfService or Content.ReadingTexts[math.random(1, #Content.ReadingTexts)]
	local id = newId()
	sess.reading = { id = id, issued = os.clock(), tos = isTOS }
	Net.send(player, "reading", {
		id = id,
		text = isTOS and text or Brain.degradeText(text, data.cells, data.settings and tonumber(data.settings.fxIntensity) or 1),
		tos = isTOS,
		tier = tierFor(data.cells),
	})
end

Net.on("reading_done", function(player, d)
	local sess = s(player)
	local r = sess.reading
	if not r or r.id ~= d.id then
		return { ok = false }
	end
	sess.reading = nil
	sess.nextReading = os.clock() + math.random(Config.ReadingPopupMin, Config.ReadingPopupMax)
	local data = DataService.get(player)
	if not data or not onLose(player) then
		return { ok = true }
	end
	local elapsed = os.clock() - r.issued
	if r.tos then
		if elapsed >= Config.TOSSeconds then
			BrainService.awardBadge(player, "ReadTOS")
			BrainService.gain(player, 1, "reading")
			return { ok = true, result = "You read the whole Terms of Service. Respect. (+brain cells, oops)" }
		end
		BrainService.lose(player, 2, "reading")
		data.stats.textsSkipped += 1
		return { ok = true, result = "Skipped the Terms of Service. Classic." }
	end
	if elapsed < Config.ReadingSeconds then
		data.stats.textsSkipped += 1
		BrainService.lose(player, 1.5, "reading")
		if math.random() < 0.3 then
			BrainService.narrate(player, "lost")
		end
		return { ok = true, result = "Skipped! 🧠📉" }
	end
	data.stats.textsRead += 1
	BrainService.gain(player, 1, "reading")
	BrainService.narrate(player, "gained")
	return { ok = true, result = "You actually READ it… you got smarter. 😭" }
end)

---------------------------------------------------------------------
-- Clickbait cards
---------------------------------------------------------------------
Net.on("clickbait_get", function(player)
	local bad = guard(player, "Clickbait")
	if bad then
		return bad
	end
	local data = DataService.get(player)
	local tier = tierFor(data.cells)
	local pool = {}
	for _, h in ipairs(Content.Headlines) do
		if h.tier == tier then
			table.insert(pool, h)
		end
	end
	shuffle(pool)
	local cards = {}
	local hasBait = false
	for i = 1, math.min(3, #pool) do
		cards[i] = pool[i]
		hasBait = hasBait or pool[i].bait
	end
	if not hasBait then
		for _, h in ipairs(pool) do
			if h.bait then
				cards[1] = h
				break
			end
		end
	end
	if tier <= 2 and #journalistHeadlines > 0 and math.random() < 0.4 then
		local j = journalistHeadlines[math.random(1, #journalistHeadlines)]
		cards[math.random(1, #cards)] = { tier = tier, bait = true, text = j.text, article = "Written by a journalist from the Gain path. It's bait. You clicked it.", author = j.author }
	end
	if tier == 4 then
		cards = { cards[1] }
	end
	local sess = s(player)
	sess.clickbait = { cards = cards, open = nil }
	local out = {}
	for i, c in ipairs(cards) do
		out[i] = { id = i, text = c.text }
	end
	return { ok = true, cards = out }
end)

Net.on("clickbait_open", function(player, d)
	local sess = s(player)
	local cb = sess.clickbait
	if not cb or not cb.cards[d.id] then
		return { ok = false }
	end
	cb.open = { id = d.id, t = os.clock() }
	return { ok = true, article = cb.cards[d.id].article, text = cb.cards[d.id].text }
end)

Net.on("clickbait_close", function(player)
	local sess = s(player)
	local cb = sess.clickbait
	if not cb or not cb.open then
		return { ok = false }
	end
	local data = DataService.get(player)
	local card = cb.cards[cb.open.id]
	local elapsed = os.clock() - cb.open.t
	sess.clickbait = nil
	if not data or not onLose(player) then
		return { ok = true }
	end
	if card.bait then
		data.clickbaitClicks += 1
		data.stats.clickbaitClicked += 1
		if data.clickbaitClicks >= 25 then
			BrainService.awardBadge(player, "ClickedEverything")
		end
		if card.author then
			local author = Players:GetPlayerByUserId(card.author)
			if author and author ~= player then
				BrainService.gain(author, 0.5, "journal")
				BrainService.toast(author, "📰 Someone clicked your clickbait headline! +brain cells")
			end
		end
		dumbAction(player)
		if elapsed < Config.ReadingSeconds then
			BrainService.lose(player, 3, "clickbait")
			BrainService.embarrass(player, 8, "You believed \"" .. card.text .. "\"")
			return { ok = true, result = "You fell for it! 🧠📉" }
		end
		BrainService.gain(player, 1, "clickbait")
		return { ok = true, result = "You clicked the bait… but then READ it. Smart. Ew." }
	end
	if elapsed < Config.ReadingSeconds then
		BrainService.lose(player, 1, "clickbait")
		return { ok = true, result = "That one was real news. You skipped it anyway. 📉" }
	end
	BrainService.gain(player, 1, "clickbait")
	return { ok = true, result = "You read real news. Your brain grew. Gross." }
end)

Net.on("clickbait_ignore", function(player)
	local sess = s(player)
	sess.clickbait = nil
	if onLose(player) then
		BrainService.gain(player, 0.3, "clickbait")
	end
	return { ok = true, result = "You ignored the clickbait. That was… smart. 🤢" }
end)

---------------------------------------------------------------------
-- Steal A / Fix A / Make A
---------------------------------------------------------------------
Net.on("steal_get", function(player)
	local bad = guard(player, "StealA")
	if bad then
		return bad
	end
	local data = DataService.get(player)
	local tier = tierFor(data.cells)
	local word = Content.StealWords[math.random(1, #Content.StealWords)]
	local options
	if tier == 1 and math.random() < 0.6 then
		local t = Content.StealTricky[math.random(1, #Content.StealTricky)]
		options = { { kind = "steal", text = t.steal }, { kind = "fix", text = t.fix }, { kind = "make", text = t.make } }
	elseif tier == 4 then
		options = { { kind = "steal", text = "STEEL A" } }
	elseif tier == 3 then
		options = { { kind = "steal", text = "Steal A Rock" }, { kind = "steal", text = "Steal A Rock 2" } }
	else
		options = {
			{ kind = "steal", text = "Steal A " .. word },
			{ kind = "fix", text = "Fix A " .. word },
			{ kind = "make", text = "Make A " .. word },
		}
	end
	shuffle(options)
	s(player).steal = { options = options, word = word }
	local out = {}
	for i, o in ipairs(options) do
		out[i] = { id = i, text = o.text }
	end
	return { ok = true, options = out }
end)

Net.on("steal_choose", function(player, d)
	local sess = s(player)
	local st = sess.steal
	if not st or not st.options[d.id] then
		return { ok = false }
	end
	sess.steal = nil
	local opt = st.options[d.id]
	if not onLose(player) then
		return { ok = true }
	end
	if opt.kind == "steal" then
		dumbAction(player)
		BrainService.lose(player, 3, "steal")
		return { ok = true, kind = "steal", word = st.word, result = "Another copycat game! 🧠📉" }
	end
	BrainService.gain(player, 0.5, "steal")
	BrainService.say(player, "Wow, original! (You gained a few brain cells by accident.)")
	return { ok = true, kind = opt.kind, result = "Wow, original! 📈 (that's bad)" }
end)

---------------------------------------------------------------------
-- Dumb internet comments
---------------------------------------------------------------------
Net.on("comments_get", function(player)
	local bad = guard(player, "Comments")
	if bad then
		return bad
	end
	local data = DataService.get(player)
	local tier = tierFor(data.cells)
	local words = {}
	for i, w in ipairs(Content.CommentWords) do
		if tier < 3 or w.dumb >= 2 or #w.text <= 4 then
			table.insert(words, { id = i, text = w.text })
		end
	end
	local post = Content.Posts[math.random(1, #Content.Posts)]
	s(player).comment = true
	return { ok = true, post = post, words = words }
end)

Net.on("comments_post", function(player, d)
	local sess = s(player)
	if not sess.comment then
		return { ok = false }
	end
	sess.comment = nil
	local data = DataService.get(player)
	if not data or not onLose(player) or typeof(d.ids) ~= "table" then
		return { ok = false }
	end
	local textParts = {}
	local score = 0
	for i, id in ipairs(d.ids) do
		if i > 5 then
			break
		end
		local w = Content.CommentWords[tonumber(id) or -1]
		if w then
			table.insert(textParts, w.text)
			score += w.dumb
		end
	end
	if #textParts == 0 then
		return { ok = false, msg = "Pick some words first." }
	end
	local comment = table.concat(textParts, " ")
	data.stats.commentsPosted += 1
	BrainService.lose(player, 1 + score / 3, "comment")
	local viral = math.random() < math.min(0.5, score * 0.03)
	if viral then
		data.viralCount += 1
		if data.viralCount >= Config.ViralBadgeCount then
			BrainService.awardBadge(player, "Ratiod")
		end
		BrainService.narrate(player, "viral")
		BrainService.embarrass(player, 40, "Your comment \"" .. comment .. "\" went viral")
		Net.send(player, "viral", { comment = comment, youtuber = Content.ReactionYoutuber })
	end
	return { ok = true, comment = comment, viral = viral }
end)

---------------------------------------------------------------------
-- Short video scroller
---------------------------------------------------------------------
Net.on("scroll_swipe", function(player)
	local bad = guard(player, "Scroller")
	if bad then
		return bad
	end
	local sess = s(player)
	local now = os.clock()
	if sess.lastSwipe and now - sess.lastSwipe < 0.25 then
		return { ok = false }
	end
	sess.lastSwipe = now
	BrainService.lose(player, 0.25, "scroll")
	return { ok = true }
end)

---------------------------------------------------------------------
-- Death ending
---------------------------------------------------------------------
function LoseService.death(player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local seconds = math.max(0, os.time() - (data.runStart or os.time()))
	if not data.bestRunSeconds or seconds < data.bestRunSeconds then
		data.bestRunSeconds = seconds
	end
	BrainService.awardBadge(player, "SmoothBrain")
	if seconds < 3600 then
		BrainService.awardBadge(player, "Speedrun")
	end
	Net.send(player, "death", {
		seconds = seconds,
		best = data.bestRunSeconds,
		clickbait = data.stats.clickbaitClicked,
		skipped = data.stats.textsSkipped,
		moments = data.embarrassingMoments,
		loud = data.perks.ExtraLoudDeath == true,
	})
	task.delay(5, function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
	end)
end

Net.on("death_again", function(player)
	local data = DataService.get(player)
	if not data or not data.dead then
		return { ok = false }
	end
	data.stats = { textsSkipped = 0, textsRead = 0, clickbaitClicked = 0, commentsPosted = 0, gatesFailed = 0 }
	data.embarrassingMoments = {}
	BrainService.startPath(player, "Lose")
	task.delay(1, function()
		WorldService.teleport(player, "lose")
	end)
	return { ok = true }
end)

Net.on("death_comeback", function(player)
	local data = DataService.get(player)
	if not data or not data.dead then
		return { ok = false }
	end
	Net.send(player, "comebackCutscene", {})
	BrainService.startPath(player, "Gain", true)
	task.delay(6, function()
		WorldService.teleport(player, "gain")
		BrainService.say(player, "i wnt 2 be smrt")
	end)
	return { ok = true }
end)

Net.on("switch_path", function(player, d)
	local data = DataService.get(player)
	if not data or (d.path ~= "Lose" and d.path ~= "Gain") then
		return { ok = false }
	end
	BrainService.startPath(player, d.path)
	BrainService.narrate(player, d.path == "Lose" and "choseLose" or "choseGain")
	WorldService.teleport(player, string.lower(d.path))
	return { ok = true }
end)

---------------------------------------------------------------------
-- Loops: reading popups and slow-loss zones
---------------------------------------------------------------------
function LoseService.reset(player)
	sessions[player] = nil
end

function LoseService.start()
	BrainService.hooks.onDeath = LoseService.death
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				if onLose(player) and BrainService.feature("ReadingTests") and not BrainService.blocked(player) then
					local sess = s(player)
					if not sess.reading and os.clock() >= sess.nextReading then
						sendReading(player)
					elseif sess.reading and os.clock() - sess.reading.issued > 120 then
						-- left it open forever: that counts as reading it
						sess.reading = nil
						sess.nextReading = os.clock() + Config.ReadingPopupMin
						BrainService.gain(player, 1, "reading")
					end
				end
			end
		end
	end)
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(5)
			tick += 1
			if BrainService.feature("Zones") then
				for _, player in ipairs(Players:GetPlayers()) do
					if onLose(player) and not BrainService.blocked(player) then
						if WorldService.inZone(player, "microwave") then
							BrainService.lose(player, 0.5, "microwave")
							if tick % 4 == 0 then
								BrainService.say(player, "🍿 *mmmmmmmmmm* (the microwave hums)")
							end
						elseif WorldService.inZone(player, "wall") then
							BrainService.lose(player, 0.5, "wall")
							if tick % 4 == 0 then
								BrainService.say(player, "🧱 The wall is winning.")
							end
						end
					end
				end
			end
		end
	end)
end

return LoseService

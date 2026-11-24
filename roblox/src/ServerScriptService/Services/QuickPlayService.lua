-- QuickPlayService.lua (1.8.5, tester feedback: "a button next to Phone and Library that gives
-- multiple-choice questions and points"). A quick optional round of Config.QuickPlay.Questions
-- questions from the Library and Jack B fact pools.
--   Gain: right answers give brain cells.   Lose: the WRONG (dumbest) answer wins and drops cells.
-- The server keeps the answers, checks timing, and shuffles questions with a per-player bag so
-- nothing repeats until the pool is used up.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local QuickPlayService = {}
local QP = Config.QuickPlay

local POOL = {}
for _, src in ipairs({ Content.Library, Content.Theater }) do
	for _, item in ipairs(src or {}) do
		if item.q and item.options and item.answer then
			table.insert(POOL, item)
		end
	end
end

local bags = {} -- [player] = { index, ... } still to draw
local rounds = {} -- [player] = { items = {...}, i = 1, score = 0, last = os.clock(), started = os.clock() }
local nextAt = {} -- [player] = os.clock() when the next round may start

local function draw(player: Player)
	local bag = bags[player]
	if not bag or #bag == 0 then
		bag = {}
		for i = 1, #POOL do
			bag[i] = i
		end
		for i = #bag, 2, -1 do -- shuffle
			local j = math.random(1, i)
			bag[i], bag[j] = bag[j], bag[i]
		end
		bags[player] = bag
	end
	return POOL[table.remove(bag)]
end

local function public(item)
	return { q = item.q, options = item.options }
end

Net.on("qp_start", function(player)
	local data = DataService.get(player)
	if not data or data.dead or not data.path then
		return { ok = false, msg = Content.QuickPlay.PickDoor }
	end
	if player:GetAttribute("Stage") and player:GetAttribute("Stage") ~= "human" then
		return { ok = false, msg = Content.QuickPlay.Animal }
	end
	local wait = (nextAt[player] or 0) - os.clock()
	if wait > 0 then
		return { ok = false, msg = string.format(Content.QuickPlay.Cooldown, math.ceil(wait)) }
	end
	local items = {}
	for i = 1, math.min(QP.Questions, #POOL) do
		items[i] = draw(player)
	end
	rounds[player] = { items = items, i = 1, score = 0, last = os.clock(), started = os.clock() }
	return { ok = true, total = #items, question = public(items[1]), seconds = QP.SecondsPerQuestion, lose = data.path == "Lose" }
end)

Net.on("qp_answer", function(player, d)
	local r = rounds[player]
	local data = DataService.get(player)
	if not r or not data or typeof(d) ~= "table" then
		return { ok = false }
	end
	local now = os.clock()
	if now - r.last < QP.MinAnswerSeconds then
		return { ok = false, msg = Content.QuickPlay.TooFast }
	end
	local item = r.items[r.i]
	local choice = tonumber(d.choice)
	local inTime = now - r.last <= QP.SecondsPerQuestion + 1
	local right = choice == item.answer
	local lose = data.path == "Lose"
	local win = inTime and choice ~= nil and (lose and not right or (not lose and right))
	if win then
		r.score += 1
	end
	r.i += 1
	r.last = now
	local res = { ok = true, win = win, answer = item.answer, fact = item.text, timeUp = not inTime }
	if r.i <= #r.items then
		res.question = public(r.items[r.i])
		return res
	end
	-- round over: reward from the score
	rounds[player] = nil
	nextAt[player] = now + QP.Cooldown
	res.done = true
	res.score = r.score
	res.total = #r.items
	if r.score > 0 then
		local pts = r.score * QP.PointsPerWin
		if lose then
			BrainService.lose(player, pts, "quickplay")
		else
			BrainService.gain(player, pts, "quickplay")
		end
	end
	return res
end)

Players.PlayerRemoving:Connect(function(p)
	bags[p] = nil
	rounds[p] = nil
	nextAt[p] = nil
end)

function QuickPlayService.start() end

return QuickPlayService

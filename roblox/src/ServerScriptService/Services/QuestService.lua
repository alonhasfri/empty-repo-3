-- QuestService (1.9.3, judges' #6 "no reason to come back tomorrow"): 3 small DAILY QUESTS per day, picked
-- for your path (Config.Quests.Pools: Gain / Lose / Animal). Progress counts automatically from the reward
-- reasons BrainService already uses ("bits", "library", "clickbait"…), so no other system needs changing.
-- Each finished quest pays coins; all 3 pay a bonus. Saved in data.quests (new saves start empty).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local CQ = Config.Quests
local TQ = Content.Quests
local QuestService = {}

local function today(): number
	return math.floor(os.time() / 86400)
end

local function poolFor(data)
	local stage = Brain.stage(data.cells or 0, BrainService.secretAnimals).key
	if stage ~= "human" and stage ~= "barelyhuman" then
		return CQ.Pools.Animal
	end
	return CQ.Pools[data.path or ""] or CQ.Pools.Gain
end

local function ensure(data)
	local q = data.quests
	if typeof(q) ~= "table" or q.day ~= today() or q.path ~= data.path then
		local pool = table.clone(poolFor(data))
		local list = {}
		for _ = 1, math.min(CQ.PerDay, #pool) do
			local pick = table.remove(pool, math.random(1, #pool))
			table.insert(list, { key = pick.key, goal = pick.goal, count = 0 })
		end
		data.quests = { day = today(), path = data.path, list = list, bonus = false, seen = false }
	end
	return data.quests
end

local function view(data)
	local q = ensure(data)
	local list = {}
	for _, it in ipairs(q.list) do
		table.insert(list, { text = string.format(TQ.Text[it.key] or it.key, it.goal), count = math.min(it.count, it.goal), goal = it.goal, done = it.count >= it.goal })
	end
	return { list = list, bonus = q.bonus, coins = CQ.Coins, allBonus = CQ.AllBonus, seen = q.seen }
end

local function send(player)
	local data = DataService.get(player)
	if data and data.path then
		Net.send(player, "quests", view(data))
	end
end

-- called for every brain reward (BrainService.gain / lose) with its reason
function QuestService.progress(player: Player, reason: string?)
	local data = DataService.get(player)
	if not data or not data.path or not reason then
		return
	end
	local q = ensure(data)
	local changed = false
	for _, it in ipairs(q.list) do
		if it.key == reason and it.count < it.goal then
			it.count += 1
			changed = true
			if it.count >= it.goal then
				data.coins = (data.coins or 0) + CQ.Coins
				q.seen = false -- the red dot: something new to look at
				BrainService.toast(player, string.format(TQ.Done, string.format(TQ.Text[it.key] or it.key, it.goal), CQ.Coins), "LevelUp")
			end
		end
	end
	if changed then
		local all = true
		for _, it in ipairs(q.list) do
			if it.count < it.goal then
				all = false
			end
		end
		if all and not q.bonus then
			q.bonus = true
			data.coins = (data.coins or 0) + CQ.AllBonus
			BrainService.toast(player, string.format(TQ.AllDone, CQ.AllBonus), "BadgeSparkle")
		end
		BrainService.push(player)
		send(player)
	end
end

Net.on("quests_get", function(player)
	local data = DataService.get(player)
	if not data or not data.path then
		return { ok = false }
	end
	local v = view(data)
	data.quests.seen = true
	v.ok = true
	return v
end)

BrainService.onReward = QuestService.progress

Players.PlayerAdded:Connect(function(player)
	task.delay(6, function()
		if player.Parent then
			send(player)
		end
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(send, p)
end

return QuestService

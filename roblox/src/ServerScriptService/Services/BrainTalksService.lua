-- BrainTalksService.lua (1.9): the smart scroll for Gain players.
-- The server picks every clip (smart talk or brainrot) and checks every choice:
--   skip brainrot  = focus streak +1, a little calmer
--   watch a talk   = must really watch (Config.BrainTalks.WatchSeconds), big stress drop + brain cells, streak +1
--   skip a talk    = streak back to 0 (no penalty)
--   watch brainrot = the first time each session is only a warning; after that a small penalty
-- Lose players use BrainTok (the normal doomscroll); animals can't use phones like this.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Brain = require(Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local BrainTalksService = {}

local CB = Config.BrainTalks
local T = Content.BrainTalks
local sessions = {} -- [player] = { clip, nextId, streak, best, warned, lastAction }

local function sess(player)
	local x = sessions[player]
	if not x then
		x = { nextId = 0, streak = 0, best = 0, warned = false, lastAction = 0 }
		sessions[player] = x
	end
	return x
end

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)

local function problem(player): string?
	local data = DataService.get(player)
	if not data then
		return T.Loading
	end
	if data.path ~= "Gain" then
		return T.GainOnly
	end
	if not BrainService.feature("BrainTalks") then
		return T.Off
	end
	local stage = Brain.stage(data.cells, BrainService.secretAnimals)
	if stage.key ~= "human" and stage.key ~= "barelyhuman" then
		return T.NoAnimals
	end
	-- stressed players may still use it (it is how you calm down), anything else blocks
	local blocked = BrainService.blocked(player)
	if blocked and not string.find(blocked, "stressed") then
		return blocked
	end
	return nil
end

local function newClip(player)
	local x = sess(player)
	x.nextId += 1
	local smart = math.random() < CB.SmartChance
	local list = smart and T.Smart or T.Rot
	local c = list[math.random(1, #list)]
	x.clip = { id = x.nextId, smart = smart, shownAt = os.clock() }
	-- the client only gets what the player sees, never whether it is smart
	return { id = x.nextId, title = c.title, creator = c.creator, icon = c.icon }
end

local function streakInfo(x)
	return { streak = x.streak, best = x.best }
end

Net.on("talks_next", function(player)
	local bad = problem(player)
	if bad then
		return { ok = false, msg = bad }
	end
	local x = sess(player)
	return { ok = true, clip = newClip(player), streak = streakInfo(x), watchSeconds = CB.WatchSeconds }
end)

Net.on("talks_act", function(player, d)
	local bad = problem(player)
	if bad then
		return { ok = false, msg = bad }
	end
	local x = sess(player)
	local now = os.clock()
	if now - x.lastAction < CB.MinGap then
		return { ok = false }
	end
	local clip = x.clip
	if type(d) ~= "table" or not clip or d.id ~= clip.id then
		return { ok = false, msg = T.Stale }
	end
	local action = d.action
	local result
	if action == "skip" then
		x.lastAction = now
		if clip.smart then
			x.streak = 0
			result = { kind = "missed", msg = T.Missed }
		else
			x.streak = math.min(x.streak + 1, CB.StreakMax)
			BrainService.stress(player, -CB.SkipRotCalm)
			result = { kind = "dodged", msg = T.Dodged }
		end
	elseif action == "watch" then
		if now - clip.shownAt < CB.WatchSeconds - 0.3 then
			return { ok = false, msg = T.TooFast } -- the server checks you really watched
		end
		x.lastAction = now
		if clip.smart then
			local bonus = 1 + x.streak * CB.StreakBonus
			BrainService.stress(player, -CB.StressDrop * bonus)
			BrainService.gain(player, CB.GainPoints * bonus, "braintalks")
			x.streak = math.min(x.streak + 1, CB.StreakMax)
			result = { kind = "learned", msg = T.Learned }
		elseif not x.warned then
			-- warn before any penalty: the first brainrot watched each session is free
			x.warned = true
			result = { kind = "warned", msg = T.Warning }
		else
			x.streak = 0
			BrainService.lose(player, CB.RotPenaltyPoints, "braintalks")
			BrainService.stress(player, CB.RotStress)
			result = { kind = "rotted", msg = T.Rotted }
		end
	else
		return { ok = false }
	end
	x.best = math.max(x.best, x.streak)
	result.ok = true
	result.streak = streakInfo(x)
	result.clip = newClip(player)
	return result
end)

return BrainTalksService

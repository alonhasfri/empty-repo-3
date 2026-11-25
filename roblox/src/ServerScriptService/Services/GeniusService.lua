-- GeniusService (1.9): the Genius Crossroads and its 5 branches (math, physics, coding, business, chess).
-- * Opens at the top of a career ladder (level 4) or at Config.Genius.OpenIQ (Gain path only).
-- * data.genius = "math" | "physics" | ... (nil for old saves). Switching keeps your brain cells.
-- * data.geniusStory = { [branch] = chapters done } (nil for old saves).
-- * Each branch has 2 genius jobs and a signature minigame (MinigameService, server-checked),
--   and a 3-chapter story: every chapter is a round of the signature minigame; the last one gives a badge.
-- Text: Content.Genius. Numbers: Config.Genius (+ Config.Minigames.Games for the minigames).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local MinigameService = require(script.Parent.MinigameService)

local GeniusService = {}
local CG = Config.Genius
local TG = Content.Genius

function GeniusService.isOpen(data): boolean
	if not data or data.path ~= "Gain" or data.dead then
		return false
	end
	if typeof(data.career) == "table" and (data.career.level or 1) >= 4 then
		return true
	end
	return Brain.iq(data.cells or 0) >= CG.OpenIQ
end

local function story(data)
	if typeof(data.geniusStory) ~= "table" then
		data.geniusStory = {}
	end
	return data.geniusStory
end

-- the phone's 🌟 Genius app reads this
Net.on("genius_get", function(player)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" then
		return { ok = false, msg = TG.NotGain }
	end
	local open = GeniusService.isOpen(data)
	local done = (typeof(data.geniusStory) == "table" and data.genius) and (data.geniusStory[data.genius] or 0) or 0
	return { ok = true, open = open, openIQ = CG.OpenIQ, genius = data.genius, chapter = done, chapters = CG.Chapters }
end)

Net.on("genius_pick", function(player, d)
	local data = DataService.get(player)
	local branch = typeof(d) == "table" and d.branch
	if not data or not GeniusService.isOpen(data) or not table.find(CG.Branches, branch) then
		return { ok = false }
	end
	data.genius = branch
	BrainService.push(player)
	return { ok = true, msg = string.format(TG.Picked, TG.Branches[branch].name) }
end)

-- kind = "job" (work a genius job) or "story" (play the next chapter)
Net.on("genius_play", function(player, d)
	local data = DataService.get(player)
	if not data or not data.genius or not GeniusService.isOpen(data) or typeof(d) ~= "table" then
		return { ok = false }
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		return { ok = false, msg = blocked }
	end
	local branch = data.genius
	local game = CG.Games[branch]
	if d.kind == "story" then
		local doneCh = story(data)[branch] or 0
		if doneCh >= CG.Chapters then
			return { ok = false, msg = TG.AllDone }
		end
		return MinigameService.begin(player, game, "genius", doneCh + 1, { branch = branch, kind = "story", chapter = doneCh + 1 })
	end
	local job = tonumber(d.job) == 2 and 2 or 1
	return MinigameService.begin(player, game, "genius", job == 2 and 2 or 1, { branch = branch, kind = "job" })
end)

BrainService.hooks.geniusOpen = GeniusService.isOpen -- BrainService.state → geniusOpen (the phone app and path strip)

MinigameService.handlers.genius = function(player, round, score, passed)
	local data = DataService.get(player)
	local x = round.extra
	if not data or not x or data.genius ~= x.branch then
		return {}
	end
	if x.kind == "job" then
		if passed then
			local pay = score * CG.JobPayPerPoint
			data.coins = (data.coins or 0) + pay
			BrainService.gain(player, CG.JobPoints, "genius")
			BrainService.push(player)
			return { coins = pay }
		end
		return {}
	end
	-- story chapter
	if not passed then
		return {}
	end
	local st = story(data)
	if (st[x.branch] or 0) + 1 ~= x.chapter then
		return {}
	end
	st[x.branch] = x.chapter
	BrainService.gain(player, CG.ChapterPoints, "genius")
	local result = { chapterDone = x.chapter }
	if x.chapter >= CG.Chapters then
		data.coins = (data.coins or 0) + CG.FinalCoins
		BrainService.awardBadge(player, CG.Badges[x.branch])
		BrainService.toast(player, string.format(TG.StoryDone, TG.Branches[x.branch].name, CG.FinalCoins), "LevelUp")
		result.coins = CG.FinalCoins
		result.storyDone = true
	else
		BrainService.toast(player, TG.ChapterDone, "LevelUp")
	end
	BrainService.push(player)
	return result
end

-- admin test command helper: open the Crossroads for this player right now
function GeniusService.forceOpen(player)
	local data = DataService.get(player)
	if not data then
		return
	end
	if typeof(data.career) == "table" then
		data.career.level = 4
	end
	BrainService.push(player)
	Net.send(player, "openStation", { station = "genius" })
end

return GeniusService

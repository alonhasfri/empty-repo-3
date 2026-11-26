-- LoseJobService (1.9.1, big ideas #14): joke jobs for the Lose path, in the 🤡 Jobs phone app.
--   🫧 Bubble-wrap popper · 🖼 Meme reviewer · 🪧 Upside-down sign holder
-- Each is a silly minigame (MinigameService, context "losejob"). A good shift pays a few coins and
-- costs a little brain (that's the Lose path's goal). Humans only: animals have their own jobs.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local MinigameService = require(script.Parent.MinigameService)
local Rooms = require(script.Parent.Rooms)

local LoseJobService = {}
local CJ = Config.LoseJobs
local TJ = Content.LoseJobs

Net.on("losejob_list", function(player)
	local d = DataService.get(player)
	if not d or d.path ~= "Lose" then
		return { ok = false, msg = TJ.LoseOnly }
	end
	local list = {}
	for _, id in ipairs(CJ.Order) do
		table.insert(list, { id = id, icon = TJ.Jobs[id].icon, name = TJ.Jobs[id].name, blurb = TJ.Jobs[id].blurb, coins = CJ.Jobs[id].coins })
	end
	return { ok = true, list = list }
end)

Net.on("losejob_start", function(player, d)
	local data = DataService.get(player)
	local id = typeof(d) == "table" and tostring(d.id) or ""
	local job = CJ.Jobs[id]
	if not data or data.path ~= "Lose" or not job then
		return { ok = false, msg = TJ.LoseOnly }
	end
	if Rooms.isAnimal(player) then
		return { ok = false, msg = TJ.Animal }
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		return { ok = false, msg = "⛔ " .. blocked }
	end
	return MinigameService.begin(player, job.game, "losejob", 1, { id = id })
end)

MinigameService.handlers.losejob = function(player, round, score, passed)
	local data = DataService.get(player)
	local id = round.extra and round.extra.id
	local job = id and CJ.Jobs[id]
	if not data or not job or data.path ~= "Lose" then
		return {}
	end
	if not passed then
		BrainService.toast(player, TJ.Fired[math.random(1, #TJ.Fired)])
		return {}
	end
	data.coins = (data.coins or 0) + job.coins
	BrainService.lose(player, job.lose, "losejob")
	BrainService.toast(player, string.format(TJ.Paid, TJ.Jobs[id].icon, job.coins), "CartoonBoing")
	BrainService.push(player)
	return { coins = job.coins }
end

return LoseJobService

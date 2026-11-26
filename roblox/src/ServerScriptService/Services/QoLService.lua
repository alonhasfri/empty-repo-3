-- QoLService (1.9.1, user: "add some quality of life changes… semi-harmless things that make the player's life better"):
--   * Daily reward: come back on a new day for free coins; a streak grows the reward (resets if you miss a day).
--   * AFK-safe: a player who hasn't touched anything for a while is marked AFK (Client/QoL.lua). While AFK the
--     school bell doesn't ring for them and no life-event invite arrives, so nothing bad happens while you're away.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local QoLService = {}
local CQ = Config.QoL
local TQ = Content.QoL

local function today(): number
	return math.floor(os.time() / 86400)
end

local function dailyReward(player: Player)
	local data
	for _ = 1, 40 do
		data = DataService.get(player)
		if data or not player.Parent then
			break
		end
		task.wait(0.5)
	end
	if not data or not data.path then
		return
	end
	local day = today()
	local last = tonumber(data.lastDaily) or 0
	if last == day then
		return
	end
	local streak = (last == day - 1) and ((tonumber(data.dailyStreak) or 0) + 1) or 1
	data.lastDaily = day
	data.dailyStreak = streak
	local coins = CQ.DailyCoins + math.min(streak - 1, CQ.DailyMaxStreak - 1) * CQ.DailyStreakBonus
	data.coins = (data.coins or 0) + coins
	task.delay(CQ.DailyDelay, function()
		if player.Parent then
			BrainService.toast(player, string.format(TQ.Daily, coins, streak), "LevelUp")
			BrainService.push(player)
		end
	end)
end

Players.PlayerAdded:Connect(function(p)
	task.spawn(dailyReward, p)
end)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(dailyReward, p)
end

-- AFK flag from the client (only a yes/no; nothing is saved)
Net.on("afk", function(player, d)
	player:SetAttribute("AFK", typeof(d) == "table" and d.afk == true or nil)
	return { ok = true }
end)

return QoLService

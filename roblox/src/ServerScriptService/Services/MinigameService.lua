-- MinigameService (1.9 Gain path redesign): one small framework for every minigame.
-- A feature (jobs, big life events, genius branches) starts a round with MinigameService.begin();
-- the client plays it and sends "mg_finish" with its score. The server checks:
--   * a round was really started, for this game
--   * it lasted long enough (Config.Minigames.MinShare) and not too long (seconds + Grace)
--   * the score is possible (score <= elapsed * maxPerSecond)
-- then calls the feature's handler: handlers[context](player, round, score, passed) -> result table.
-- Numbers: Config.Minigames. Text: Content.Minigames.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local Net = require(script.Parent.Net)

local MinigameService = {}
MinigameService.handlers = {} -- [context] = function(player, round, score, passed) -> table

local MG = Config.Minigames
local rounds = {} -- [player] = round

-- Start a round. level 1-4 makes it faster and raises the goal. extra = anything the handler needs.
function MinigameService.begin(player, game: string, context: string, level: number?, extra)
	local def = MG.Games[game]
	if not def then
		return nil
	end
	level = math.clamp(math.floor(level or 1), 1, 4)
	local seconds = math.max(MG.MinRound, def.seconds - (level - 1) * MG.LevelFaster)
	local round = {
		game = game,
		context = context,
		level = level,
		seconds = seconds,
		pass = def.pass + (level - 1),
		seed = math.random(1, 2 ^ 30),
		started = os.clock(),
		extra = extra,
	}
	rounds[player] = round
	return {
		ok = true,
		minigame = game,
		seconds = seconds,
		pass = round.pass,
		level = level,
		seed = round.seed,
		title = Content.Minigames.Games[game].title,
		how = Content.Minigames.Games[game].how,
	}
end

function MinigameService.cancel(player)
	rounds[player] = nil
end

Net.on("mg_finish", function(player, d)
	local round = rounds[player]
	if not round or typeof(d) ~= "table" or d.game ~= round.game then
		return { ok = false }
	end
	rounds[player] = nil
	local def = MG.Games[round.game]
	local elapsed = os.clock() - round.started
	local score = tonumber(d.score) or 0
	if score ~= score then -- NaN
		score = 0
	end
	score = math.max(0, math.floor(score))
	-- quitting early is fine, a WIN that came impossibly early is not
	local tooFast = elapsed < round.seconds * MG.MinShare and score >= round.pass
	local tooLate = elapsed > round.seconds + MG.Grace
	local impossible = score > math.ceil(elapsed * def.maxPerSecond) + 1
	if tooFast or tooLate or impossible then
		score = 0
	end
	local passed = score >= round.pass
	local handler = MinigameService.handlers[round.context]
	local result = handler and handler(player, round, score, passed) or {}
	result.ok = true
	result.score = score
	result.pass = round.pass
	result.passed = passed
	result.flagged = (tooFast or impossible) or nil
	return result
end)

Players.PlayerRemoving:Connect(function(player)
	rounds[player] = nil
end)

return MinigameService

-- EventService (1.9): big life events (a friend's wedding, Grandma's 80th, graduation, moving house,
-- a runaway pet, a blackout). Both paths: smart choices help on Gain, silly ones on Lose.
-- * Invites arrive in the phone (💌 Invites app) after ~10 minutes, then every 15-25 minutes.
-- * Events come from a shuffle bag (data.eventBag), so nothing repeats until all were seen.
-- * Nothing is forced mid-task: you accept from the phone whenever you like.
-- * Saved: data.eventsDone (list of ids), data.eventInvite (id), data.eventBag (ids left); all nil for old saves.
-- Animals don't get invites (they have no phone); a waiting invite stays until you're human again.
-- Text: Content.LifeEvents. Numbers: Config.Events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local MinigameService = require(script.Parent.MinigameService)

local EventService = {}
local CE = Config.Events
local TE = Content.LifeEvents

local active = {} -- [player] = { id, step } (the event you are in right now)

local function isHuman(data): boolean
	local cells = data.cells or 0
	local key = Brain.stage(cells, BrainService.secretAnimals).key
	return key == "human" or key == "barelyhuman"
end

-- next id from the shuffle bag (refilled and shuffled when empty)
local function draw(data): string
	if typeof(data.eventBag) ~= "table" or #data.eventBag == 0 then
		local bag = table.clone(CE.Ids)
		for i = #bag, 2, -1 do
			local j = math.random(1, i)
			bag[i], bag[j] = bag[j], bag[i]
		end
		data.eventBag = bag
	end
	return table.remove(data.eventBag, 1)
end

-- give an invite now (also used by the admin test commands)
function EventService.invite(player, id: string?)
	local data = DataService.get(player)
	if not data or not data.path or data.dead then
		return false
	end
	id = (id and TE.Events[id]) and id or draw(data)
	data.eventInvite = id
	BrainService.toast(player, string.format(TE.Invite, TE.Events[id].name), "NotificationPing")
	BrainService.push(player)
	return true
end

-- BrainService.state → inEvent, so the 💌 app stays on the phone while an event is half done
BrainService.hooks.inEvent = function(player)
	return active[player] ~= nil
end

-- what the phone shows for the current step
local function stepView(player, data, a)
	local ev = TE.Events[a.id]
	local step = ev.steps[a.step]
	local view = { ok = true, id = a.id, icon = ev.icon, name = ev.name, step = a.step, total = #ev.steps, text = step.text }
	if a.step == 1 and not a.introShown then
		a.introShown = true
		view.intro = ev.intro[data.path] or ev.intro.Gain
	end
	if step.game then
		view.minigame = MinigameService.begin(player, step.game, "event", 1, { id = a.id, step = a.step })
	else
		view.options = {}
		for i, o in ipairs(step.options) do
			view.options[i] = o[1]
		end
	end
	return view
end

local function reward(player, data, fits: boolean, points: number)
	local amount = fits and points or CE.OtherPoints
	if data.path == "Lose" then
		BrainService.lose(player, amount, "event")
	else
		BrainService.gain(player, amount, "event")
	end
end

-- move to the next step, or finish the event
local function advance(player, data, a)
	local ev = TE.Events[a.id]
	a.step += 1
	if a.step <= #ev.steps then
		return stepView(player, data, a)
	end
	active[player] = nil
	if typeof(data.eventsDone) ~= "table" then
		data.eventsDone = {}
	end
	table.insert(data.eventsDone, a.id)
	data.coins = (data.coins or 0) + CE.DoneCoins
	BrainService.push(player)
	return { ok = true, done = true, outro = ev.outro[data.path] or ev.outro.Gain, msg = string.format(TE.Done, ev.icon .. " " .. ev.name, CE.DoneCoins) }
end

Net.on("event_get", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local album = {}
	for _, id in ipairs(typeof(data.eventsDone) == "table" and data.eventsDone or {}) do
		local ev = TE.Events[id]
		if ev then
			table.insert(album, ev.icon .. " " .. ev.name)
		end
	end
	local inv = data.eventInvite and TE.Events[data.eventInvite]
	return { ok = true, invite = inv and { id = data.eventInvite, icon = inv.icon, name = inv.name } or nil, inEvent = active[player] ~= nil, album = album }
end)

Net.on("event_accept", function(player)
	local data = DataService.get(player)
	if not data or data.dead or not data.path then
		return { ok = false }
	end
	local a = active[player]
	if not a then
		if not data.eventInvite or not TE.Events[data.eventInvite] then
			return { ok = false, msg = TE.NoInvite }
		end
		if not isHuman(data) then
			return { ok = false, msg = TE.NoInvite }
		end
		a = { id = data.eventInvite, step = 1 }
		active[player] = a
		data.eventInvite = nil
		BrainService.push(player)
	end
	return stepView(player, data, a)
end)

Net.on("event_choose", function(player, d)
	local data = DataService.get(player)
	local a = active[player]
	if not data or not a or typeof(d) ~= "table" then
		return { ok = false }
	end
	local step = TE.Events[a.id].steps[a.step]
	local option = step.options and step.options[tonumber(d.choice) or 0]
	if not option then
		return { ok = false }
	end
	local smart = option[2] == true
	reward(player, data, (data.path == "Lose") ~= smart, CE.ChoicePoints)
	return advance(player, data, a)
end)

-- a minigame inside an event: a good score fits both paths (silly-on-purpose isn't a minigame thing)
MinigameService.handlers.event = function(player, round, _score, passed)
	local data = DataService.get(player)
	local a = active[player]
	if not data or not a or not round.extra or round.extra.id ~= a.id or round.extra.step ~= a.step then
		return {}
	end
	reward(player, data, passed, CE.MinigamePoints)
	local nextView = advance(player, data, a)
	return { event = nextView }
end

-- the invite timer: first after FirstAfter seconds of play, then every GapMin-GapMax
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local waitFor = CE.FirstAfter
		while player.Parent do
			task.wait(waitFor)
			if not player.Parent then
				return
			end
			local data = DataService.get(player)
			if data and data.path and not data.dead and not data.eventInvite and not active[player] and isHuman(data) then
				EventService.invite(player)
				waitFor = math.random(CE.GapMin, CE.GapMax)
			else
				waitFor = 60 -- not a good moment: look again in a minute
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	active[player] = nil
end)

return EventService

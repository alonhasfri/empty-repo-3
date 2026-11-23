-- ConversationService (update 1.5): CONVERSATION SCENES.
-- Walk up to someone in a room (Rooms.convSpot) and talk. The server keeps the
-- conversation (so choices can't be faked); the client (Client/Conversation) shows
-- the camera cuts, the typed lines and the choices in the bottom-left.
--
-- Text: Content.Conversations. Numbers: Config.Conversations.
-- Being dumb changes it: low-brain players get degraded choice text, animals only
-- get animal noises (same effects, so they're picking blind).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Brain = require(Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local Rooms = require(script.Parent.Rooms)

local ConversationService = {}

local CC = Config.Conversations
local UI = Content.ConvUI
local sessions = {} -- [player] = { key, scene, cfg, node, meter, opts = {text}, spotId }
local lastEnd = {} -- [player] = os.clock()

local function stageKey(data): string
	return Brain.stage(data.cells, BrainService.secretAnimals).key
end

local function isAnimal(data): boolean
	local k = stageKey(data)
	return k ~= "human" and k ~= "barelyhuman" and k ~= "dead"
end

-- The text the player sees for choice i
local function choiceText(data, opt, i: number): string
	if isAnimal(data) then
		local list = Content.AnimalTalk[stageKey(data)] or Content.AnimalTalk.default
		return list[i] or list[1]
	end
	local t = opt.t
	if typeof(t) == "table" then
		t = t[data.path] or t.Gain
	end
	return Brain.degradeText(t, data.cells, data.settings and tonumber(data.settings.fxIntensity) or 1)
end

local function nodePayload(data, s)
	local node = s.scene.nodes[s.node]
	s.opts = {}
	for i, o in ipairs(node.opts) do
		s.opts[i] = choiceText(data, o, i)
	end
	return { say = node.say, opts = s.opts }
end

-- Where the wide shot camera goes: beside the two people, toward the middle of the room
local function wideShot(spot): Vector3
	local stand, npc = spot.stand.Position, spot.npc.Position
	local mid = (stand + npc) / 2
	local key = Rooms.buildingAt(mid)
	local dir
	if key then
		local c = Rooms.Buildings[key].cf.Position
		local flat = Vector3.new(c.X - mid.X, 0, c.Z - mid.Z)
		if flat.Magnitude > 1 then
			dir = flat.Unit
		end
	end
	dir = dir or spot.stand.RightVector
	return mid + dir * 8 + Vector3.new(0, 6.5, 0)
end

local function sceneKeyFor(spot, path: string?): string?
	if typeof(spot.conv) == "table" then
		return spot.conv[path]
	end
	return spot.conv
end

local function start(player: Player, spotId: string)
	local spot = Rooms.ConvSpots[spotId]
	local data = DataService.get(player)
	if not spot or not data then
		return
	end
	if sessions[player] then
		BrainService.toast(player, UI.Busy)
		return
	end
	if not data.path then
		BrainService.toast(player, Content.Rooms.PickPath)
		return
	end
	local key = sceneKeyFor(spot, data.path)
	if not key then
		BrainService.toast(player, data.path == "Lose" and Content.Rooms.SmartOnly or Content.Rooms.DumbOnly)
		return
	end
	local scene, cfg = Content.Conversations[key], CC.Scenes[key]
	if not scene or not cfg then
		warn("[Conversation] missing scene " .. tostring(key))
		return
	end
	if cfg.noAnimals and isAnimal(data) then
		BrainService.toast(player, Content.School.NoAnimals)
		return
	end
	local blocked = BrainService.blocked(player)
	if blocked and not (cfg.allowFrozen and BrainService.isFrozen(player)) then
		BrainService.toast(player, "⛔ " .. blocked)
		return
	end
	if lastEnd[player] and os.clock() - lastEnd[player] < CC.Cooldown then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end
	if (root.Position - spot.stand.Position).Magnitude > CC.StartRadius then
		BrainService.toast(player, UI.TooFar)
		return
	end
	-- stand up from any seat, then stand at the spot facing them
	Rooms.standUp(hum)
	char:PivotTo(spot.stand * CFrame.new(0, 3, 0))

	local s = { key = key, scene = scene, cfg = cfg, node = "a", meter = cfg.meter, spotId = spotId }
	sessions[player] = s
	data.convSeen = data.convSeen or {}
	Net.send(player, "conv_open", {
		key = key,
		who = scene.who,
		meterName = scene.meter,
		meter = s.meter,
		stand = spot.stand,
		npc = spot.npc,
		wide = wideShot(spot),
		seen = data.convSeen[key] == true,
		node = nodePayload(data, s),
	})
end

local coinPaidAt = {} -- [player][scene key] = os.clock() of the last coin reward
local function giveRewards(player: Player, data, r, key: string?)
	-- 1.7.3: the same scene again within CoinRewardEvery: no coins and only RepeatBrainFactor of the brain cells
	-- (learning still counts a little, but the repeat loop dies)
	coinPaidAt[player] = coinPaidAt[player] or {}
	local last = key and coinPaidAt[player][key]
	local again = last ~= nil and os.clock() - last < CC.CoinRewardEvery
	local f = again and CC.RepeatBrainFactor or 1
	if again then
		BrainService.toast(player, Content.ConvUI.Again)
	elseif key then
		coinPaidAt[player][key] = os.clock()
	end
	if r.coins and not again then
		data.coins += r.coins
	end
	if r.gain then
		BrainService.gain(player, r.gain * f, "conversation")
	end
	if r.lose then
		BrainService.lose(player, r.lose * f, "conversation")
	end
	if r.path then
		if data.path == "Gain" then
			BrainService.gain(player, r.path * f, "conversation")
		else
			BrainService.lose(player, r.path * f, "conversation")
		end
	end
	if r.stress then
		BrainService.stress(player, r.stress) -- only does something on the Gain path
	end
	if r.embarrass then
		if r.embarrass > 0 then
			BrainService.embarrass(player, r.embarrass, UI.EmbarrassMoment)
		elseif data.path == "Lose" then
			data.embarrass = math.max(0, data.embarrass + r.embarrass)
		end
	end
	if r.idea then
		-- fills the idea meter; the next job task sets off the Eureka moment
		data.ideaMeter = math.min((data.ideaMeter or 0) + r.idea, Config.EurekaTasks - 1)
	end
	if r.confetti then
		Net.send(player, "confetti", {})
	end
	BrainService.push(player)
end

Net.on("conv_pick", function(player, d)
	local s = sessions[player]
	local data = DataService.get(player)
	if not s or not data or s.ended then
		return { ok = false }
	end
	local i = tonumber(d.i)
	local node = s.scene.nodes[s.node]
	local nums = s.cfg[s.node]
	if not i or i % 1 ~= 0 or not node.opts[i] or not nums or not nums[i] then
		return { ok = false }
	end
	local opt = node.opts[i]
	local m, b = nums[i][1], nums[i][2]
	local said = s.opts[i]
	s.meter = math.clamp(s.meter + m, 0, 100)
	if b > 0 then
		BrainService.gain(player, b * CC.BrainScale, "conversation")
	elseif b < 0 then
		BrainService.lose(player, -b * CC.BrainScale, "conversation")
	end
	local out = { ok = true, said = said, delta = m, meter = s.meter, slam = opt.slam == true }
	if opt.n then
		s.node = opt.n
		out.next = nodePayload(data, s)
	else
		s.ended = true
		local tier = s.meter >= CC.GoodAt and "good" or (s.meter <= CC.BadAt and "bad" or "mid")
		giveRewards(player, data, s.cfg[tier] or {}, s.key)
		data.convSeen = data.convSeen or {}
		data.convSeen[s.key] = true
		BrainService.awardBadge(player, "SmallTalk")
		out.ended = { tier = tier, line = s.scene.ends[tier].line, result = s.scene.ends[tier].result }
	end
	return out
end)

function ConversationService.stop(player: Player)
	if sessions[player] then
		sessions[player] = nil
		lastEnd[player] = os.clock()
		Net.send(player, "conv_close", {})
	end
end

function ConversationService.active(player: Player): boolean
	return sessions[player] ~= nil
end

-- Delayed travel (bus, Hoppr): false while the player is in a conversation scene;
-- otherwise stands them up from any seat (so a seat weld can't drag or fling them) and returns true.
function ConversationService.readyToTravel(player: Player): boolean
	if sessions[player] then
		return false
	end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	Rooms.standUp(hum)
	return true
end

Net.on("conv_close", function(player)
	if sessions[player] then
		sessions[player] = nil
		lastEnd[player] = os.clock()
	end
	return { ok = true }
end)

function ConversationService.start()
	Rooms.onConv = start
	-- prompt text per path (the client picks the one for its path)
	for _, spot in pairs(Rooms.ConvSpots) do
		if spot.prompt then
			for _, path in ipairs({ "Lose", "Gain" }) do
				local key = sceneKeyFor(spot, path)
				local scene = key and Content.Conversations[key]
				if scene then
					spot.prompt:SetAttribute(path .. "Action", scene.action)
				end
			end
		end
	end
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
		lastEnd[p] = nil
		coinPaidAt[p] = nil
	end)
	-- dying or respawning ends the conversation
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			ConversationService.stop(p)
		end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		p.CharacterAdded:Connect(function()
			ConversationService.stop(p)
		end)
	end
end

return ConversationService

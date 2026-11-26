-- AnimalLifeService (1.9.1, big ideas #9): things to DO as an animal, with no reading needed.
--   * Animal jobs: 🐶 fetch the newspaper to a door, 🦟/🐝 buzz the picnic / the flowers, 🐛 help a garden
--     grow, 🐭 find crumbs, 🐙 tidy the pond. A glowing icon in the world shows where to go (and the
--     client's smell trail leads there). Done = treats (coins) and a step back up.
--   * Animal friends: a cat, a squirrel and a duck in the park. Animals only. Each wants one thing
--     (shown as an icon); bring it back for a bigger step up and a friend heart.
--   * Climbing back up: every job and quest moves you a fixed share of the way to the next form
--     (worm → fly → bee → mouse → octopus → dog → human). The client shows a climb bar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local Rooms = require(script.Parent.Rooms)

local AnimalLifeService = {}
local CL = Config.AnimalLife
local TL = Content.AnimalLife
local S = Config.Map.Scale

local folder = Instance.new("Folder")
folder.Name = "AnimalLife"
folder.Parent = workspace

local quests = {} -- [player] = { kind, step, part, friend? }

local function stageOf(player: Player)
	local data = DataService.get(player)
	return data and Brain.stage(data.cells, BrainService.secretAnimals) or nil
end

local function isAnimalPlayer(player: Player): boolean
	return Rooms.isAnimal(player)
end

-- the share of the way from this stage's floor to the next form
local function climbInfo(cells: number)
	local stages = Brain.Stages
	for i, s in ipairs(stages) do
		if cells <= s.max then
			local floor = i > 1 and stages[i - 1].max or 0
			local nextStage = stages[i + 1]
			if not nextStage then
				return nil
			end
			local span = s.max - floor
			return { floor = floor, top = s.max, span = span, share = math.clamp((cells - floor) / math.max(1, span), 0, 1), next = nextStage }
		end
	end
	return nil
end

-- move the player a share of the way up (at least 1 cell, at most to just past the top)
local function climb(player: Player, share: number)
	local data = DataService.get(player)
	if not data or data.dead then
		return
	end
	local info = climbInfo(data.cells)
	if not info then
		return
	end
	local step = math.max(1, info.span * share)
	local rate = math.max(1, data.cells * (data.path == "Gain" and Config.Rates.GainRate or Config.Rates.LoseRate))
	-- BrainService.gain turns points into cells; ask for exactly `step`
	local before = data.cells
	if data.path == "Gain" then
		local mult = Brain.gainMultiplier(data.cells)
		BrainService.gain(player, step / (rate * math.max(0.01, mult)), "animal")
	else
		BrainService.gain(player, step / rate, "animal")
	end
	local after = DataService.get(player) and DataService.get(player).cells or before
	if Brain.stage(after, BrainService.secretAnimals).key ~= Brain.stage(before, BrainService.secretAnimals).key then
		BrainService.toast(player, TL.ClimbedUp, "LevelUp")
	end
end

local function realPos(design: Vector3): Vector3
	return Vector3.new(design.X * S, design.Y, design.Z * S)
end

-- a random outdoor spot: in front of a place, or somewhere in the park
local function randomSpot(): Vector3
	if math.random() < 0.4 then
		local P = Config.Map.Park
		return realPos(Vector3.new(math.random(P.X1 + 10, P.X2 - 10), 3, math.random(P.Z1 + 10, P.Z2 - 10)))
	end
	local list = {}
	for key, pos in pairs(WorldService.Spots) do
		if key ~= "lobby" then
			table.insert(list, pos)
		end
	end
	if #list == 0 then
		return Vector3.new(0, 3, 30)
	end
	return list[math.random(1, #list)] + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
end

local function clearQuest(player: Player)
	local q = quests[player]
	if q and q.part then
		q.part:Destroy()
	end
	quests[player] = nil
end

-- a glowing icon on the ground with a prompt only its owner can use
local function target(player: Player, pos: Vector3, icon: string, onReach)
	local p = Instance.new("Part")
	p.Name = "AnimalTarget_" .. player.UserId
	p.Anchored = true
	p.CanCollide = false
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2.4, 2.4, 2.4)
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 220, 90)
	p.Transparency = 0.3
	p.Position = pos + Vector3.new(0, 1, 0)
	p.Parent = folder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(70, 70)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 400
	bb.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = icon
	l.Parent = bb
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = icon
	pp.ObjectText = ""
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.Parent = p
	pp.Triggered:Connect(function(who)
		if who == player then
			onReach()
		end
	end)
	Net.send(player, "animalTarget", { x = p.Position.X, z = p.Position.Z, icon = icon })
	return p
end

-- 🐾 animal job for this stage
local function startJob(player: Player)
	local st = stageOf(player)
	local job = st and CL.Jobs[st.key]
	if not job then
		return { ok = false, msg = TL.NoJob }
	end
	clearQuest(player)
	local q = { kind = "job", job = st.key }
	quests[player] = q
	local icons = TL.Jobs[st.key]
	local function finish()
		clearQuest(player)
		local data = DataService.get(player)
		if data then
			data.coins = (data.coins or 0) + job.coins
			BrainService.stress(player, -5)
		end
		climb(player, CL.JobClimb)
		BrainService.toast(player, string.format(TL.JobDone, icons.done, job.coins), "CartoonBoing")
		BrainService.push(player)
	end
	if job.twoStep then
		-- fetch: pick it up here, drop it there
		q.part = target(player, randomSpot(), icons.pick, function()
			if quests[player] ~= q then
				return
			end
			q.part:Destroy()
			BrainService.toast(player, icons.pick .. " ➜ " .. icons.drop)
			q.part = target(player, randomSpot(), icons.drop, function()
				if quests[player] == q then
					finish()
				end
			end)
		end)
	else
		q.part = target(player, randomSpot(), icons.drop, function()
			if quests[player] == q then
				finish()
			end
		end)
	end
	return { ok = true, icon = icons.drop }
end

Net.on("animal_job", function(player)
	if not isAnimalPlayer(player) then
		return { ok = false, msg = TL.HumansNo }
	end
	return startJob(player)
end)

-- climb bar for the animal menu
Net.on("animal_climb", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local info = climbInfo(data.cells)
	local st = stageOf(player)
	return { ok = true, share = info and info.share or 1, now = st and st.emoji or "🧠", nextIcon = info and info.next.emoji or "🧠" }
end)

---------------------------------------------------------------------
-- Animal friends in the park
---------------------------------------------------------------------
local function buildFriend(key: string, def)
	local P = Config.Map.Park
	local pos = realPos(Vector3.new(P.X1 + (P.X2 - P.X1) * def.at[1], 0.6, P.Z1 + (P.Z2 - P.Z1) * def.at[2]))
	local m = Instance.new("Model")
	m.Name = "AnimalFriend_" .. key
	local body = Instance.new("Part")
	body.Anchored = true
	body.Size = def.size
	body.Color = def.color
	body.Material = Enum.Material.SmoothPlastic
	body.Position = pos + Vector3.new(0, def.size.Y / 2, 0)
	body.Parent = m
	local head = Instance.new("Part")
	head.Anchored = true
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1, 1, 1) * def.size.Y * 0.8
	head.Color = def.color
	head.Position = body.Position + Vector3.new(0, def.size.Y * 0.7, -def.size.Z / 2)
	head.Parent = m
	m.PrimaryPart = body
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(60, 60)
	bb.StudsOffset = Vector3.new(0, def.size.Y + 2.5, 0)
	bb.MaxDistance = 120
	bb.Parent = body
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = TL.Friends[key].icon
	l.Parent = bb
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "🐾"
	pp.ObjectText = TL.Friends[key].icon
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.Parent = body
	pp.Triggered:Connect(function(player)
		if not isAnimalPlayer(player) then
			BrainService.toast(player, string.format(TL.FriendHuman, TL.Friends[key].icon))
			return
		end
		local q = quests[player]
		if q and q.kind == "friend" and q.friend == key and q.has then
			-- bringing the thing back
			clearQuest(player)
			local data = DataService.get(player)
			if data then
				data.animalFriends = typeof(data.animalFriends) == "table" and data.animalFriends or {}
				data.animalFriends[key] = (data.animalFriends[key] or 0) + 1
				data.coins = (data.coins or 0) + CL.FriendCoins
			end
			climb(player, CL.FriendClimb)
			BrainService.toast(player, string.format(TL.FriendThanks, TL.Friends[key].icon, CL.FriendCoins), "LevelUp")
			BrainService.push(player)
			return
		end
		-- a new quest: show what they want, put it somewhere in town
		clearQuest(player)
		local nq = { kind = "friend", friend = key }
		quests[player] = nq
		local want = TL.Friends[key].wants
		BrainService.toast(player, TL.Friends[key].icon .. " 💭 " .. want, "NotificationPing")
		nq.part = target(player, randomSpot(), want, function()
			if quests[player] ~= nq then
				return
			end
			nq.has = true
			nq.part:Destroy()
			nq.part = nil
			BrainService.toast(player, want .. " ➜ " .. TL.Friends[key].icon)
			Net.send(player, "animalTarget", { x = body.Position.X, z = body.Position.Z, icon = TL.Friends[key].icon })
		end)
	end)
	m.Parent = folder
end

task.spawn(function()
	task.wait(4) -- after the town
	for key, def in pairs(CL.Friends) do
		pcall(buildFriend, key, def)
	end
end)

Players.PlayerRemoving:Connect(clearQuest)

return AnimalLifeService

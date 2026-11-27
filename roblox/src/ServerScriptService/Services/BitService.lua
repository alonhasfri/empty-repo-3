-- BitService (1.9.3, judges' #1 and #3: "the first goal is reading" / "dead time while walking"): little
-- glowing BRAIN BITS on the streets near each player (only that player sees theirs, Client/Bits.lua).
-- Walking into one = a small brain change in YOUR direction (up on Gain, down on Lose) + a coin.
-- Grabbing them quickly builds a 🔥 streak that pays more. New players' first goal is "grab 10 bits".
-- The server decides where bits are and checks you really stand next to one (no free grabs).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local CB = Config.Bits
local BitService = {}

local bits = {} -- [player] = { [id] = Vector3 }
local streak = {} -- [player] = { n, at }
local perMinute = {} -- [player] = { count, since }
local rng = Random.new()

local function spotNear(root: BasePart): Vector3?
	local params = RaycastParams.new()
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	for _ = 1, 10 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(CB.DistMin, CB.DistMax)
		local x, z = root.Position.X + math.cos(a) * d, root.Position.Z + math.sin(a) * d
		local hit = workspace:Raycast(Vector3.new(x, root.Position.Y + 60, z), Vector3.new(0, -120, 0), params)
		-- open ground roughly at your height (a street, not a roof), with nothing right above it
		if hit and math.abs(hit.Position.Y - root.Position.Y) < 6 and hit.Normal.Y > 0.8 then
			if not workspace:Raycast(hit.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, 12, 0), params) then
				return hit.Position + Vector3.new(0, 2, 0)
			end
		end
	end
	return nil
end

local function refill(player: Player)
	local data = DataService.get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not data or not data.path or data.dead or not root then
		return
	end
	bits[player] = bits[player] or {}
	local mine = bits[player]
	-- forget bits you walked far away from, so new ones appear where you are
	for id, pos in pairs(mine) do
		if (pos - root.Position).Magnitude > CB.DistMax * 2.5 then
			mine[id] = nil
		end
	end
	local n = 0
	for _ in pairs(mine) do
		n += 1
	end
	while n < CB.PerPlayer do
		local pos = spotNear(root)
		if not pos then
			break
		end
		mine[HttpService:GenerateGUID(false)] = pos
		n += 1
	end
	local list = {}
	for id, pos in pairs(mine) do
		table.insert(list, { id = id, x = pos.X, y = pos.Y, z = pos.Z })
	end
	Net.send(player, "bits", { list = list })
end

Net.on("bit_take", function(player, d)
	local id = typeof(d) == "table" and tostring(d.id) or ""
	local mine = bits[player]
	local pos = mine and mine[id]
	local data = DataService.get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not pos or not data or not root or data.dead then
		return { ok = false }
	end
	if (root.Position - pos).Magnitude > CB.GrabRange then
		return { ok = false }
	end
	mine[id] = nil
	-- a speed limit (no bot farming)
	local pm = perMinute[player]
	if not pm or os.clock() - pm.since > 60 then
		pm = { count = 0, since = os.clock() }
		perMinute[player] = pm
	end
	pm.count += 1
	if pm.count > CB.PerMinuteCap then
		return { ok = false, gone = true }
	end
	-- the streak: grabs within StreakSeconds of each other
	local s = streak[player]
	if s and os.clock() - s.at <= CB.StreakSeconds then
		s.n += 1
		s.at = os.clock()
	else
		s = { n = 1, at = os.clock() }
		streak[player] = s
	end
	local points = CB.Points * (1 + math.min(CB.MaxStreakBonus, (s.n - 1) * CB.StreakBonus))
	if data.path == "Lose" then
		BrainService.lose(player, points, "bits")
	else
		BrainService.gain(player, points, "bits")
	end
	data.coins = (data.coins or 0) + CB.Coins
	data.bitsTaken = (data.bitsTaken or 0) + 1
	BrainService.push(player)
	return { ok = true, streak = s.n }
end)

task.spawn(function()
	while true do
		task.wait(CB.Refill)
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(refill, p)
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		bits[player] = {}
		task.wait(3)
		refill(player)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(refill, p)
end
Players.PlayerRemoving:Connect(function(player)
	bits[player] = nil
	streak[player] = nil
	perMinute[player] = nil
end)

return BitService

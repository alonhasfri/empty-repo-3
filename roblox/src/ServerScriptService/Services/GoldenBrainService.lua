-- GoldenBrainService (1.9.1 fun fixes 2, docs/Fun review.md #9 "earlier surprises"):
-- every 60-90 s a glowing Golden Brain pops up on open ground near each player. Walking into it gives a big brain
-- change in YOUR direction (up on Gain, down on Lose) plus coins, so both paths (and animals) get a free surprise.
-- It vanishes after a while if nobody grabs it. Anyone can grab anyone's brain (a little race is fun).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local GoldenBrainService = {}
local CF = Config.FunFixes2
local TF = Content.FunFixes2

local folder = Instance.new("Folder")
folder.Name = "GoldenBrains"
folder.Parent = workspace

local rng = Random.new()

-- open ground near the player: straight down must hit something low (a street, not a roof), with nothing above
local function findSpot(root: BasePart): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { folder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	for _ = 1, 12 do
		local a = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(CF.GoldenDistMin, CF.GoldenDistMax)
		local x, z = root.Position.X + math.cos(a) * dist, root.Position.Z + math.sin(a) * dist
		local hit = workspace:Raycast(Vector3.new(x, root.Position.Y + 80, z), Vector3.new(0, -160, 0), params)
		if hit and math.abs(hit.Position.Y - root.Position.Y) < 8 and hit.Normal.Y > 0.8 then
			return hit.Position + Vector3.new(0, 3, 0)
		end
	end
	return nil
end

local function makeBrain(pos: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "GoldenBrain"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2.6, 2.6, 2.6)
	p.Material = Enum.Material.Foil -- shiny gold (flat Neon looked like a yellow blob)
	p.Color = Color3.fromRGB(255, 190, 40)
	p.Reflectance = 0.25
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Position = pos
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 90)
	light.Range = 14
	light.Brightness = 2
	light.Parent = p
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 240, 150)
	sparkles.Parent = p
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 40)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 225, 90)
	t.TextStrokeTransparency = 0
	t.Text = "🧠 " .. TF.GoldenName
	t.Parent = bb
	-- bob and spin
	TweenService:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = pos + Vector3.new(0, 1.2, 0) }):Play()
	p.Parent = folder
	return p
end

local function grab(player: Player, brain: BasePart)
	if brain:GetAttribute("Taken") then
		return
	end
	local data = DataService.get(player)
	if not data or not data.path or data.dead then
		return
	end
	brain:SetAttribute("Taken", true)
	data.coins = (data.coins or 0) + CF.GoldenCoins
	if data.path == "Lose" then
		BrainService.lose(player, CF.GoldenPoints, "golden")
		BrainService.toast(player, string.format(TF.GoldenLose, CF.GoldenCoins), "LevelUp")
	else
		BrainService.gain(player, CF.GoldenPoints, "golden")
		BrainService.toast(player, string.format(TF.GoldenGain, CF.GoldenCoins), "LevelUp")
	end
	BrainService.push(player)
	brain:Destroy()
end

local function spawnFor(player: Player)
	if player:GetAttribute("AFK") then
		return
	end
	local data = DataService.get(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not data.path or data.dead or not root then
		return
	end
	local pos = findSpot(root)
	if not pos then
		return
	end
	local brain = makeBrain(pos)
	brain.Touched:Connect(function(hit)
		local who = Players:GetPlayerFromCharacter(hit.Parent) or (hit.Parent and Players:GetPlayerFromCharacter(hit.Parent.Parent))
		if who then
			grab(who, brain)
		end
	end)
	-- Touched can miss on a non-colliding part when a tiny animal walks into it, so also check distance
	task.spawn(function()
		local t0 = os.clock()
		while brain.Parent and os.clock() - t0 < CF.GoldenLife do
			for _, p in ipairs(Players:GetPlayers()) do
				local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if r and (r.Position - brain.Position).Magnitude < 4.5 then
					grab(p, brain)
					break
				end
			end
			task.wait(0.25)
		end
		if brain.Parent then
			brain:Destroy()
		end
	end)
	Net.send(player, "toast", { text = TF.GoldenSpawn, sound = "NotificationPing" })
end

local function loop(player: Player)
	while player.Parent do
		task.wait(rng:NextNumber(CF.GoldenEveryMin, CF.GoldenEveryMax))
		if player.Parent then
			pcall(spawnFor, player)
		end
	end
end

Players.PlayerAdded:Connect(function(p)
	task.spawn(loop, p)
end)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(loop, p)
end

-- for testing: spawn one right now (admin only; see AdminService "golden")
GoldenBrainService.spawnFor = spawnFor

return GoldenBrainService

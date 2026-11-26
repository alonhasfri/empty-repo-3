-- WeatherService (1.9.1, big ideas #15): seasons and weather for the whole server.
--   * The season comes from the real date (winter = snow can fall; the last week of October = "spooky":
--     pumpkins around the plaza, kid-safe). The weather changes every few minutes, weighted by season.
--   * workspace attributes "Weather" (clear / rain / snow / fog) and "Season" tell every client
--     (Client/Weather.lua draws rain, snow, puddles and fog on your screen).
--   * ☂️ an umbrella (bought in the Home app, price shown) opens over your head while it rains.
--   * ❄️ while it snows: snowman spots in the park, and players can throw a snowball at each other
--     (a harmless white puff and a toast, with a cooldown).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)

local WeatherService = {}
local CW = Config.Weather
local TW = Content.Weather
local S = Config.Map.Scale

local folder = Instance.new("Folder")
folder.Name = "Seasonal"
folder.Parent = workspace

function WeatherService.season(): string
	local t = os.date("!*t")
	if t.month == 10 and t.day >= CW.SpookyFromDay then
		return "spooky"
	end
	if t.month == 12 or t.month <= 2 then
		return "winter"
	elseif t.month <= 5 then
		return "spring"
	elseif t.month <= 8 then
		return "summer"
	end
	return "autumn"
end

local function pickWeather(season: string): string
	local weights = CW.Weights[season] or CW.Weights.spring
	local total = 0
	for _, w in pairs(weights) do
		total += w
	end
	local r = math.random() * total
	for kind, w in pairs(weights) do
		r -= w
		if r <= 0 then
			return kind
		end
	end
	return "clear"
end

---------------------------------------------------------------------
-- umbrellas (rain only)
---------------------------------------------------------------------
local function hasUmbrella(p: Player): boolean
	local d = DataService.get(p)
	for _, k in ipairs(d and typeof(d.homeItems) == "table" and d.homeItems or {}) do
		if k == "umbrella" then
			return true
		end
	end
	return false
end

local function setUmbrella(p: Player, on: boolean)
	local char = p.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return
	end
	local old = char:FindFirstChild("Umbrella")
	if not on then
		if old then
			old:Destroy()
		end
		return
	end
	if old then
		return
	end
	local m = Instance.new("Model")
	m.Name = "Umbrella"
	local top = Instance.new("Part")
	top.Name = "Canopy"
	top.Shape = Enum.PartType.Ball
	top.Size = Vector3.new(6, 1.4, 6)
	top.Color = CW.UmbrellaColors[(p.UserId % #CW.UmbrellaColors) + 1]
	top.Material = Enum.Material.Fabric
	top.CanCollide = false
	top.Massless = true
	top.CFrame = head.CFrame * CFrame.new(0, 3.2, 0)
	top.Parent = m
	local stick = Instance.new("Part")
	stick.Name = "Stick"
	stick.Size = Vector3.new(0.2, 3, 0.2)
	stick.Color = Color3.fromRGB(60, 60, 60)
	stick.CanCollide = false
	stick.Massless = true
	stick.CFrame = head.CFrame * CFrame.new(0, 1.8, 0)
	stick.Parent = m
	for _, part in ipairs({ top, stick }) do
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = head, part
		w.Parent = part
	end
	m.Parent = char
end

---------------------------------------------------------------------
-- snow: snowman spots in the park
---------------------------------------------------------------------
local function clearSeasonal(tag: string)
	for _, c in ipairs(folder:GetChildren()) do
		if c:GetAttribute("Kind") == tag then
			c:Destroy()
		end
	end
end

local function snowmanSpots()
	local P = Config.Map.Park
	for i = 1, CW.SnowmanSpots do
		local x = P.X1 + (P.X2 - P.X1) * (i / (CW.SnowmanSpots + 1))
		local z = P.Z1 + (P.Z2 - P.Z1) * (0.35 + 0.3 * (i % 2))
		local pos = Vector3.new(x * S, 0.8, z * S)
		local pile = Instance.new("Part")
		pile.Name = "SnowPile"
		pile:SetAttribute("Kind", "snow")
		pile.Anchored = true
		pile.Shape = Enum.PartType.Ball
		pile.Size = Vector3.new(5, 2, 5)
		pile.Color = Color3.fromRGB(245, 248, 255)
		pile.Material = Enum.Material.Snow
		pile.Position = pos
		pile.Parent = folder
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = TW.BuildSnowman
		pp.ObjectText = "☃️"
		pp.HoldDuration = 1
		pp.RequiresLineOfSight = false
		pp.MaxActivationDistance = 10
		pp.Parent = pile
		pp.Triggered:Connect(function(player)
			if pile:GetAttribute("Built") then
				return
			end
			pile:SetAttribute("Built", true)
			pp.Enabled = false
			local m = Instance.new("Model")
			m.Name = "Snowman"
			m:SetAttribute("Kind", "snow")
			for j, r in ipairs({ 2.4, 1.8, 1.3 }) do
				local b = Instance.new("Part")
				b.Anchored = true
				b.Shape = Enum.PartType.Ball
				b.Size = Vector3.new(r * 2, r * 2, r * 2)
				b.Color = Color3.fromRGB(250, 252, 255)
				b.Material = Enum.Material.Snow
				b.Position = pos + Vector3.new(0, ({ 2.4, 5.8, 8.6 })[j], 0)
				b.Parent = m
			end
			local nose = Instance.new("Part")
			nose.Anchored = true
			nose.Size = Vector3.new(0.3, 0.3, 1.2)
			nose.Color = Color3.fromRGB(255, 130, 30)
			nose.Position = pos + Vector3.new(0, 8.6, -1.6)
			nose.Parent = m
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(180, 30)
			bb.StudsOffset = Vector3.new(0, 11, 0)
			bb.MaxDistance = 80
			bb.Parent = nose
			local l = Instance.new("TextLabel")
			l.Size = UDim2.fromScale(1, 1)
			l.BackgroundTransparency = 1
			l.TextScaled = true
			l.Font = Enum.Font.FredokaOne
			l.TextColor3 = Color3.new(1, 1, 1)
			l.TextStrokeTransparency = 0.4
			l.Text = string.format(TW.SnowmanBy, player.DisplayName)
			l.Parent = bb
			m.Parent = folder
			BrainService.toast(player, TW.SnowmanDone, "CartoonBoing")
		end)
	end
end

---------------------------------------------------------------------
-- spooky week: pumpkins around the plaza (kid-safe, friendly faces)
---------------------------------------------------------------------
local function pumpkins()
	for i = 1, CW.Pumpkins do
		local a = (i / CW.Pumpkins) * math.pi * 2
		local pos = Vector3.new(math.cos(a) * CW.PumpkinRing * S, 1.4, math.sin(a) * CW.PumpkinRing * S + 20)
		local p = Instance.new("Part")
		p.Name = "Pumpkin"
		p:SetAttribute("Kind", "spooky")
		p.Anchored = true
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(2.6, 2.2, 2.6)
		p.Color = Color3.fromRGB(240, 130, 30)
		p.Position = pos
		p.Parent = folder
		local face = Instance.new("BillboardGui")
		face.Size = UDim2.fromOffset(40, 40)
		face.MaxDistance = 60
		face.Parent = p
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Text = "🎃"
		l.Parent = face
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 60)
		light.Range = 10
		light.Brightness = 1
		light.Parent = p
	end
end

---------------------------------------------------------------------
-- snowballs (only while it snows)
---------------------------------------------------------------------
local lastThrow = {}
Net.on("snowball", function(player, d)
	if workspace:GetAttribute("Weather") ~= "snow" then
		return { ok = false, msg = TW.NoSnow }
	end
	local other = typeof(d) == "table" and Players:GetPlayerByUserId(tonumber(d.userId) or 0) or nil
	local oroot = other and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
	if not other or other == player or not oroot or not WorldService.near(player, oroot.Position, CW.SnowballRange) then
		return { ok = false, msg = TW.TooFar }
	end
	if (lastThrow[player] or 0) > os.clock() then
		return { ok = false }
	end
	lastThrow[player] = os.clock() + CW.SnowballCooldown
	local puff = Instance.new("Part")
	puff.Anchored = true
	puff.CanCollide = false
	puff.Shape = Enum.PartType.Ball
	puff.Size = Vector3.new(3, 3, 3)
	puff.Color = Color3.new(1, 1, 1)
	puff.Material = Enum.Material.Snow
	puff.Transparency = 0.2
	puff.Position = oroot.Position + Vector3.new(0, 1.5, 0)
	puff.Parent = folder
	task.delay(0.8, function()
		puff:Destroy()
	end)
	BrainService.toast(other, string.format(TW.HitYou, player.DisplayName), "CartoonBoing")
	return { ok = true, msg = string.format(TW.HitThem, other.DisplayName) }
end)

---------------------------------------------------------------------
-- the loop
---------------------------------------------------------------------
local function setWeather(kind: string)
	local before = workspace:GetAttribute("Weather")
	workspace:SetAttribute("Weather", kind)
	if before == kind then
		return
	end
	if before == "snow" then
		clearSeasonal("snow")
	end
	if kind == "snow" then
		snowmanSpots()
	end
	for _, p in ipairs(Players:GetPlayers()) do
		setUmbrella(p, kind == "rain" and hasUmbrella(p))
	end
	if TW.Start[kind] then
		for _, p in ipairs(Players:GetPlayers()) do
			BrainService.toast(p, TW.Start[kind])
		end
	end
end
WeatherService.set = setWeather

task.spawn(function()
	task.wait(6)
	local season = WeatherService.season()
	workspace:SetAttribute("Season", season)
	if season == "spooky" then
		pcall(pumpkins)
	end
	setWeather("clear")
	while true do
		task.wait(math.random(CW.ChangeMin, CW.ChangeMax))
		season = WeatherService.season()
		workspace:SetAttribute("Season", season)
		pcall(setWeather, pickWeather(season))
	end
end)

-- umbrellas also open for people who join (or respawn) while it rains
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.delay(2, function()
			setUmbrella(p, workspace:GetAttribute("Weather") == "rain" and hasUmbrella(p))
		end)
	end)
end)
Players.PlayerRemoving:Connect(function(p)
	lastThrow[p] = nil
end)

return WeatherService

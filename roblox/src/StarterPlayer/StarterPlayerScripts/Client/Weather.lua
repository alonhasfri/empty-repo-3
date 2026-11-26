-- Weather.lua (1.9.1, big ideas #15): draws the server's weather on your screen (workspace attribute "Weather").
--   rain: falling drops around the camera + puddles on the ground near you + a little haze
--   snow: soft flakes, a cold light; a "❄️ Snowball" prompt over other players
--   fog: thicker air
-- Low graphics / Effects slider at 0 = fewer particles (never none: it's how you know the weather).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local Weather = {}
local me = Players.LocalPlayer
local CW = Config.Weather
local TW = Content.Weather

local holder: Part? = nil
local emitter: ParticleEmitter? = nil
local puddles = {}
local atmo: Atmosphere? = nil
local baseDensity = nil

local function ensureHolder()
	if holder and holder.Parent then
		return holder
	end
	local p = Instance.new("Part")
	p.Name = "WeatherSky"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(CW.Area, 1, CW.Area)
	p.Parent = workspace.CurrentCamera
	holder = p
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if holder and cam then
			holder.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, CW.SkyHeight, 0))
		end
	end)
	return p
end

local function clearPuddles()
	for _, p in ipairs(puddles) do
		p:Destroy()
	end
	puddles = {}
end

local function makePuddles()
	clearPuddles()
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { me.Character, workspace.CurrentCamera }
	for _ = 1, CW.Puddles do
		local from = root.Position + Vector3.new(math.random(-CW.PuddleSpread, CW.PuddleSpread), 30, math.random(-CW.PuddleSpread, CW.PuddleSpread))
		local hit = workspace:Raycast(from, Vector3.new(0, -60, 0), params)
		if hit and hit.Normal.Y > 0.9 then
			local p = Instance.new("Part")
			p.Name = "Puddle"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Shape = Enum.PartType.Cylinder
			local r = math.random(3, 7)
			p.Size = Vector3.new(0.05, r, r * 0.8)
			p.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, math.random() * 6, math.pi / 2)
			p.Color = Color3.fromRGB(110, 140, 180)
			p.Material = Enum.Material.Glass
			p.Transparency = 0.35
			p.Reflectance = 0.3
			p.Parent = workspace.CurrentCamera
			table.insert(puddles, p)
		end
	end
end

local function apply(kind: string?)
	local h = ensureHolder()
	if emitter then
		emitter:Destroy()
		emitter = nil
	end
	clearPuddles()
	atmo = atmo or Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo and baseDensity == nil then
		baseDensity = atmo.Density
	end
	if atmo and baseDensity then
		atmo.Density = baseDensity + ((kind == "fog" and CW.FogDensity) or (kind == "rain" and CW.RainHaze) or (kind == "snow" and CW.SnowHaze) or 0)
	end
	local few = UI.effects() <= 0 or (UI.settings and UI.settings.lowGraphics)
	if kind == "rain" then
		local e = Instance.new("ParticleEmitter")
		e.Rate = few and CW.RainRate / 4 or CW.RainRate
		e.Lifetime = NumberRange.new(1.2, 1.6)
		e.Speed = NumberRange.new(60, 75)
		e.EmissionDirection = Enum.NormalId.Bottom
		e.SpreadAngle = Vector2.new(3, 3)
		e.Size = NumberSequence.new(0.3) -- test fix: drops were too thin to see
		e.Squash = NumberSequence.new(-1.5) -- long thin drops
		e.Color = ColorSequence.new(Color3.fromRGB(190, 210, 240))
		e.Transparency = NumberSequence.new(0.35)
		e.LightEmission = 0.2
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Parent = h
		emitter = e
		makePuddles()
	elseif kind == "snow" then
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate = few and CW.SnowRate / 4 or CW.SnowRate
		e.Lifetime = NumberRange.new(5, 7)
		e.Speed = NumberRange.new(6, 10)
		e.EmissionDirection = Enum.NormalId.Bottom
		e.SpreadAngle = Vector2.new(25, 25)
		e.Size = NumberSequence.new(0.35)
		e.Color = ColorSequence.new(Color3.new(1, 1, 1))
		e.Transparency = NumberSequence.new(0.1)
		e.RotSpeed = NumberRange.new(-60, 60)
		e.Parent = h
		emitter = e
	end
end

workspace:GetAttributeChangedSignal("Weather"):Connect(function()
	apply(workspace:GetAttribute("Weather"))
end)
task.defer(function()
	apply(workspace:GetAttribute("Weather"))
end)

-- ❄️ Snowball prompts over other players (only while it snows, only for humans)
local function promptFor(p: Player)
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local pp = root:FindFirstChild("SnowballPrompt")
	if not pp then
		pp = Instance.new("ProximityPrompt")
		pp.Name = "SnowballPrompt"
		pp.ActionText = TW.Snowball
		pp.ObjectText = p.DisplayName
		pp.HoldDuration = 0
		pp.RequiresLineOfSight = false
		pp.MaxActivationDistance = CW.SnowballRange
		pp.UIOffset = Vector2.new(0, -60)
		pp.Enabled = false
		pp.Parent = root
		pp.Triggered:Connect(function()
			local r = Remote.call("snowball", { userId = p.UserId })
			if r and r.msg then
				UI.toast(r.msg)
			end
		end)
	end
	return pp
end

task.spawn(function()
	while true do
		task.wait(2)
		local snowing = workspace:GetAttribute("Weather") == "snow" and me:GetAttribute("AnimalStage") == nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= me then
				local pp = promptFor(p)
				if pp then
					pp.Enabled = snowing
				end
			end
		end
	end
end)

return Weather

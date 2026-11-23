-- DayNight.lua (1.8.1): a smooth day-night cycle in town, the same clock for everyone (from server time).
-- Settings → ☀️ Always day turns it off. Streetlights switch on at dusk (unless Low graphics is on).
-- Night is never pitch black (a floor on the ambient light), and the moon, the white room and the castle
-- keep their own lighting (the cycle only runs in town). Each brain look keeps its colour mood on top.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.UI)
local LowGraphics = require(script.Parent.LowGraphics)

local CD = Config.DayNight
local player = Players.LocalPlayer
local DayNight = {}

local serverOffset = 0
function DayNight.onState(st)
	if st and st.serverNow then
		serverOffset = st.serverNow - os.time()
	end
end

local function inTown(): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return true
	end
	local p = root.Position
	return p.Y < CD.TownMaxY and math.abs(p.X) < CD.TownRadius and math.abs(p.Z) < CD.TownRadius
end

local function isNight(clock: number): boolean
	return clock >= CD.LightsOnAt or clock < CD.LightsOffAt
end

local lampsOn = nil
local function setLamps(on: boolean)
	if on == lampsOn or LowGraphics.isOn() then
		return
	end
	lampsOn = on
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("PointLight") and d.Parent and d.Parent.Name == "LampHead" then
			d.Enabled = on
		end
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		local s = UI.settings
		if inTown() then
			if s and s.alwaysDay then
				Lighting.ClockTime = Lighting:GetAttribute("LookClock") or 13
				setLamps(false)
			else
				local length = CD.DayMinutes * 60
				local t = ((os.time() + serverOffset) % length) / length -- 0..1
				local clock = (t * 24 + CD.StartHour) % 24
				Lighting.ClockTime = clock
				setLamps(isNight(clock))
				-- never pitch black at night
				if isNight(clock) then
					Lighting.Ambient = Lighting.Ambient:Lerp(CD.NightAmbient, 0.2)
					Lighting.OutdoorAmbient = CD.NightOutdoor
				end
			end
		end
	end
end)

return DayNight

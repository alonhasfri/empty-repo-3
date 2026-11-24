-- LowGraphics.lua (1.7.2): Settings → 🥔 Low graphics, for cheap phones.
-- Client only: turns off point/spot/surface lights, particles, sparkles, beams on decor,
-- global shadows, and hides small decoration parts (leaves, lamps, sills, bulbs…).
-- Everything is remembered and restored exactly when you switch it off again.
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local LowGraphics = {}

local on = false
local saved = {} -- [instance] = { prop = original value }
local conn = nil

-- decoration parts that are safe to hide (never floors, walls, doors, seats or anything with a prompt)
local DECOR = { "Leaf", "Leaves", "Lamp", "Bulb", "Sill", "Pilaster", "Flower", "Bush", "Sparkle", "Glow", "Decor" }

local function isDecor(p: BasePart): boolean
	if p:FindFirstChildWhichIsA("ProximityPrompt", true) or p:IsA("Seat") or p:IsA("VehicleSeat") then
		return false
	end
	if CollectionService:HasTag(p, "Solid") then
		return false
	end
	-- never hide something you can bump into (an invisible wall is worse than a slow phone), except tree tops
	if p.CanCollide and not string.find(p.Name, "Lea", 1, true) then
		return false
	end
	for _, w in ipairs(DECOR) do
		if string.find(p.Name, w, 1, true) then
			return true
		end
	end
	return false
end

local function remember(inst, prop: string, value)
	saved[inst] = saved[inst] or {}
	if saved[inst][prop] == nil then
		saved[inst][prop] = inst[prop]
	end
	inst[prop] = value
end

local function dim(inst)
	if inst:IsA("BasePart") and CollectionService:HasTag(inst, "FarSkyline") then
		remember(inst, "LocalTransparencyModifier", 1) -- 1.8.1: shorten the fake skyline on slow phones
		return
	end
	if inst:IsA("Light") or inst:IsA("ParticleEmitter") or inst:IsA("Sparkles") or inst:IsA("Fire") or inst:IsA("Smoke") then
		remember(inst, "Enabled", false)
	elseif inst:IsA("BasePart") and isDecor(inst) then
		remember(inst, "LocalTransparencyModifier", 1)
		remember(inst, "CastShadow", false)
	end
end

function LowGraphics.set(enabled: boolean)
	enabled = enabled == true
	if enabled == on then
		return
	end
	on = enabled
	if on then
		remember(Lighting, "GlobalShadows", false)
		for _, d in ipairs(workspace:GetDescendants()) do
			dim(d)
		end
		-- things the town builds later (rooms, effects) get dimmed too
		conn = workspace.DescendantAdded:Connect(function(d)
			task.defer(dim, d)
		end)
	else
		if conn then
			conn:Disconnect()
			conn = nil
		end
		for inst, props in pairs(saved) do
			if inst.Parent or inst == Lighting then
				for prop, value in pairs(props) do
					pcall(function()
						inst[prop] = value
					end)
				end
			end
		end
		saved = {}
	end
end

-- 1.8.2: automatic Low detail. If the player never chose a setting themselves, the client
-- measures the frame rate once, shortly after joining; a slow device gets Low detail by itself.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local autoOn = false
local probed = false
LowGraphics.onAuto = nil -- set by ClientMain: re-applies the style and shows a toast

local function probe()
	probed = true
	-- 1.8.3: phones and tablets only (a PC with the window in the background also drops frames)
	local UIS = game:GetService("UserInputService")
	if not UIS.TouchEnabled or UIS.KeyboardEnabled then
		return
	end
	task.delay(Config.UI.AutoLowDelay, function()
		local frames, t0 = 0, os.clock()
		local c = RunService.RenderStepped:Connect(function()
			frames += 1
		end)
		task.wait(Config.UI.AutoLowProbeSeconds)
		c:Disconnect()
		local fps = frames / math.max(os.clock() - t0, 0.001)
		if fps < Config.UI.AutoLowFps and not on then
			autoOn = true
			Players.LocalPlayer:SetAttribute("AutoLowDetail", true)
			LowGraphics.set(true)
			if LowGraphics.onAuto then
				LowGraphics.onAuto()
			end
		end
	end)
end

function LowGraphics.onState(st)
	local s = st and st.settings
	if s ~= nil and s.lowGraphicsChosen ~= true then
		if not probed then
			probe()
		end
		LowGraphics.set(s.lowGraphics == true or autoOn)
		return
	end
	autoOn = false
	Players.LocalPlayer:SetAttribute("AutoLowDetail", nil)
	LowGraphics.set(s ~= nil and s.lowGraphics == true)
end

function LowGraphics.isOn(): boolean
	return on
end

return LowGraphics

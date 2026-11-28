-- Guide.lua (1.7.2): "What do I do now?"
-- A short goal line at the top and glowing chevrons on the ground in front of you that point
-- at the next useful place for your path, brain level and animal stage.
-- Hidden by Settings → 🧭 guide OFF, while an objective banner (school bell) is showing,
-- and once you're standing at the target.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.UI)

local G = Content.Guide
local player = Players.LocalPlayer
local Guide = {}

local NEAR = 14 -- studs: close enough, hide the arrow
local state = nil
local targetName = nil -- the workspace part name we point at (found lazily: the map builds after we start)
local line = nil
local arrow = nil
local label = nil
local currentText = nil -- the goal text (the distance is added after it every frame)

-- the goal line (top centre, under the objective banner's spot)
line = UI.new("TextLabel", {
	Name = "GuideLine",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 74),
	Size = UDim2.fromOffset(420, UI.textSize(14) + 10), -- 1.8.3: a slim top line, not a big centre banner
	AutomaticSize = Enum.AutomaticSize.Y, -- long goals wrap instead of being cut off
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0.5,
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.FredokaOne,
	TextSize = UI.textSize(14),
	TextWrapped = true,
	Visible = false,
	Parent = UI.gui,
})
UI.corner(line, 10)
UI.autoScale(line)
UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = line })
-- 1.8 (screenshot check): sit under the title banner, not on top of it
UI.onScale(function(d)
		line.Position = UDim2.new(0.5, 0, 0, 10 + 26 * d) -- 1.8.3: just under the slim objective line at the top
end)

-- 1.9.3 (user: "the arrow should be BELOW you and clearly point where to go"): three glowing chevrons
-- lie flat on the ground in front of your feet, like a GPS, pulsing one after another toward the goal.
-- The distance is shown in the goal line at the top (no floating label).
local CHEVRONS = 3
local function makeArrow()
	local m = Instance.new("Model")
	m.Name = "GuideArrow"
	for i = 1, CHEVRONS do
		for side = -1, 1, 2 do
			local p = Instance.new("Part")
			p.Name = "Chevron" .. i
			p.Size = Vector3.new(0.7, 0.15, 2.6)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(255, 215, 60)
			p:SetAttribute("Index", i)
			p:SetAttribute("Side", side)
			p.Parent = m
		end
	end
	label = Instance.new("TextLabel") -- kept for the old code path; the distance goes in the goal line
	m.Parent = workspace.CurrentCamera -- client only
	return m
end

local function isAnimal(st): boolean
	return st.stage ~= nil and st.stage ~= "human" and st.stage ~= "barelyhuman"
end

-- What should this player do next? Returns (goal line, workspace part name or nil)
local function pick(st)
	if not st or st.dead then
		return nil, nil
	end
	if st.life and not st.path then
		-- 1.8 Life Pack: little kids grow up first, then the Crossroads Ceremony at the fountain
		if (st.life.age or 0) < 8 then
			return string.format(G.LifeGrow, st.life.emoji or "👶", st.life.age or 0), nil
		end
		return G.LifeCrossroads, "CrossroadsSpot"
	end
	if not st.path then
		return G.PickDoor, nil
	end
	if isAnimal(st) then
		return G.Animal, "Station_clickbait"
	end
	if st.path == "Lose" then
		return G.LoseStands, "Station_clickbait"
	end
	-- Gain path
	if st.atGate then
		return G.GainGate, "Station_gate"
	end
	if st.job and st.jobPlace then
		if player:GetAttribute("OnShift") then
			return G.GainTask, "Work_" .. st.jobPlace
		end
		return G.GainWork, "Work_" .. st.jobPlace
	end
	if (st.iq or 0) >= 75 then
		return G.GainJob, "Station_jobs"
	end
	return G.GainLibrary, "Station_library"
end

local function enabled(): boolean
	local s = state and state.settings
	return not (s and s.guide == false)
end

local function bannerBusy(): boolean
	local o = UI.gui:FindFirstChild("Objective")
	return o ~= nil and o.Visible
end

local function refresh()
	local text, target = pick(state)
	targetName = target
	local show = enabled() and text ~= nil and not bannerBusy()
	currentText = text
	line.Text = text or ""
	line.Visible = show
	if arrow then
		arrow.Parent = (show and target) and workspace.CurrentCamera or nil
	end
end

function Guide.onState(st)
	state = st
	if not arrow then
		arrow = makeArrow()
	end
	refresh()
end

player:GetAttributeChangedSignal("OnShift"):Connect(refresh)

-- point the arrow every frame (cheap: two parts)
local cache = {}
local function findTarget(name: string): BasePart?
	-- 1.9.1: the Restaurant Worker works at any restaurant, so point at the nearest one
	if name == "Work_restaurant" then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local best, bestD = nil, math.huge
		for _, key in ipairs({ "pizza", "burger", "sushi", "taco" }) do
			local w = findTarget("Work_" .. key)
			local d = (w and root) and (w.Position - root.Position).Magnitude or math.huge
			if w and d < bestD then
				best, bestD = w, d
			end
		end
		return best
	end
	local p = cache[name]
	if p and p.Parent then
		return p
	end
	p = workspace:FindFirstChild(name, true)
	if p and p:IsA("BasePart") then
		cache[name] = p
		return p
	end
	return nil
end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	if not arrow or not arrow.Parent or not targetName then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local target = findTarget(targetName)
	if not root or not target then
		return
	end
	local flat = Vector3.new(target.Position.X - root.Position.X, 0, target.Position.Z - root.Position.Z)
	local dist = flat.Magnitude
	t += dt
	-- ground under your feet
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char, arrow }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params)
	local groundY = hit and hit.Position.Y or (root.Position.Y - 3)
	local near = dist < NEAR
	local metres = math.floor(dist * 0.28 + 0.5) -- 1 stud ≈ 0.28 m
	line.Text = (currentText or "") .. (near and ("  •  " .. G.Near) or ("  •  " .. string.format(G.Meters, metres)))
	local dir = near and Vector3.new(0, 0, -1) or flat.Unit
	for _, p in ipairs(arrow:GetChildren()) do
		if p:IsA("BasePart") then
			local i = p:GetAttribute("Index")
			local side = p:GetAttribute("Side")
			p.Transparency = near and 1 or 0
			if not near then
				-- each chevron sits further ahead; a wave of brightness runs toward the goal
				local ahead = 4.5 + (i - 1) * 3
				local pulse = UI.reducedMotion() and 0.15 or (0.5 + 0.5 * math.sin(t * 6 - i * 1.3))
				p.Transparency = 0.05 + 0.55 * (1 - pulse)
				local centre = Vector3.new(root.Position.X, groundY + 0.12, root.Position.Z) + dir * ahead
				local base = CFrame.lookAt(centre, centre + dir)
				-- two bars make a ">" pointing forward
				p.CFrame = base * CFrame.new(side * 0.85, 0, 0.55) * CFrame.Angles(0, math.rad(side * 40), 0)
			end
		end
	end
end)

task.spawn(function()
	-- the objective banner can appear/disappear any time (school bell)
	while true do
		task.wait(1)
		if state then
			refresh()
		end
	end
end)

return Guide

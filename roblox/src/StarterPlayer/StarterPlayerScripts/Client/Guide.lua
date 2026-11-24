-- Guide.lua (1.7.2): "What do I do now?"
-- A short goal line at the top and a big friendly 3D arrow over your head that points
-- at the next useful place for your path, brain level and animal stage.
-- Hidden by Settings → 🧭 guide OFF, while an objective banner (school bell) is showing,
-- and once you're standing at the target.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
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

-- the goal line (top centre, under the objective banner's spot)
line = UI.new("TextLabel", {
	Name = "GuideLine",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 74),
	Size = UDim2.fromOffset(360, UI.textSize(16) + 14),
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0.25,
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.FredokaOne,
	TextSize = UI.textSize(16),
	TextWrapped = true,
	Visible = false,
	Parent = UI.gui,
})
UI.corner(line, 10)
UI.autoScale(line)

local function makeArrow()
	local m = Instance.new("Model")
	m.Name = "GuideArrow"
	local function piece(size: Vector3, offset: CFrame)
		local p = Instance.new("Part")
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 220, 60)
		p:SetAttribute("Offset", offset)
		p.Parent = m
		return p
	end
	-- shaft along -Z (the arrow's forward), wedge tip in front
	piece(Vector3.new(0.6, 0.35, 2.2), CFrame.new(0, 0, 0.6))
	piece(Vector3.new(1.2, 0.35, 1.2), CFrame.new(0, 0, -0.75) * CFrame.Angles(0, math.rad(45), 0)) -- diamond tip
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 34)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 200
	bb.Parent = m:GetChildren()[1]
	label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = ""
	label.Parent = bb
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
	local bob = UI.reducedMotion() and 0 or math.sin(t * 3) * 0.25
	local base = root.Position + Vector3.new(0, 4.2 + bob, 0)
	local cf
	if dist < NEAR then
		-- you're here: point down at your feet
		cf = CFrame.new(base) * CFrame.Angles(math.rad(-90), 0, 0)
		label.Text = G.Near
	else
		local dir = flat.Unit
		cf = CFrame.lookAt(base + dir * 2.2, base + dir * 3.2)
		label.Text = string.format(G.Meters, math.floor(dist * 0.28 + 0.5)) -- 1 stud ≈ 0.28 m
	end
	for _, p in ipairs(arrow:GetChildren()) do
		if p:IsA("BasePart") then
			p.CFrame = cf * p:GetAttribute("Offset")
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

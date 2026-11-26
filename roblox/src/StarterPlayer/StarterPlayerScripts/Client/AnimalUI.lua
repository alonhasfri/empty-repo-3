-- AnimalUI (1.7): animals can't hold a phone or read. Instead of the phone they get
-- a wordless, icon-only menu with giant buttons:
--   👃 sniff: pick a place by its icon and a glowing smell trail leads you there (no GPS)
--   ⚡ your animal power (same as the power button)
--   🏠 sniff the way back to the plaza
-- Text: Content.Life.Animal (emoji only). Numbers: Config.Map.TrailSeconds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local AnimalUI = {}
AnimalUI.onPower = nil -- function() (set by ClientMain)
AnimalUI.hasPower = nil -- function() -> boolean (set by ClientMain)

local player = Players.LocalPlayer
local TA = Content.Life.Animal

local trail = nil -- { part, beam, a0 }
local function clearTrail()
	if trail then
		for _, inst in pairs(trail) do
			if typeof(inst) == "Instance" then
				inst:Destroy()
			end
		end
		trail = nil
	end
end

-- A glowing scent line from your nose to the place
function AnimalUI.trail(x: number, z: number)
	clearTrail()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local target = Instance.new("Part")
	target.Name = "ScentTarget"
	target.Anchored = true
	target.CanCollide = false
	target.CanQuery = false
	target.CanTouch = false
	target.Transparency = 1
	target.Size = Vector3.new(1, 1, 1)
	target.Position = Vector3.new(x, root.Position.Y, z)
	target.Parent = workspace
	local a1 = Instance.new("Attachment")
	a1.Parent = target
	local a0 = Instance.new("Attachment")
	a0.Name = "ScentStart"
	a0.Parent = root
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 1.2
	beam.Width1 = 3
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Segments = 20
	beam.CurveSize0 = 6
	beam.CurveSize1 = -6
	beam.Color = ColorSequence.new(Color3.fromRGB(180, 255, 140), Color3.fromRGB(255, 220, 90))
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.6) })
	beam.Parent = target
	trail = { part = target, a0 = a0 }
	UI.sound("Whoosh", 0.3)
	local mine = trail
	task.delay(Config.Map.TrailSeconds, function()
		if trail == mine then
			clearTrail()
		end
	end)
	-- arriving clears it
	task.spawn(function()
		while trail == mine and target.Parent and root.Parent do
			local d = Vector2.new(root.Position.X - x, root.Position.Z - z).Magnitude
			if d < 14 then
				clearTrail()
				UI.sound("LevelUp", 0.3)
				return
			end
			task.wait(0.5)
		end
	end)
end

local function bigIcon(parent, icon: string, order: number, color: Color3, onClick)
	local b = UI.new("TextButton", {
		Text = icon,
		TextScaled = true,
		BackgroundColor3 = color,
		Size = UDim2.new(1, 0, 0, 110),
		LayoutOrder = order,
		Selectable = true,
		Parent = parent,
	}, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18) }) })
	UI.corner(b, 26)
	UI.stroke(b, Color3.new(0, 0, 0), 3, 0.2)
	b.Activated:Connect(function()
		UI.sound("CartoonBoing", 0.3)
		onClick()
	end)
	return b
end

local function sniffPicker()
	local r = Remote.call("places")
	if not r or not r.ok then
		return
	end
	local m = UI.modal(TA.Sniff, { color = Color3.fromRGB(120, 200, 90) })
	local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.31, 0, 0, 90), CellPadding = UDim2.new(0.03, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, p in ipairs(r.places) do
		-- only the place's emoji: animals can't read
		local icon = string.match(p.name, "^(%S+)") or "📍"
		bigIcon(grid, icon, i, Color3.fromRGB(250, 240, 210), function()
			m.close()
			AnimalUI.trail(p.x, p.z)
		end)
	end
	m.focus()
end

-- 1.7 fix: animals keep a way to the four Lose stands in the Mall (icons only, a sniff trail leads there)
local function standPicker()
	local m = UI.modal(TA.Stands, { color = Color3.fromRGB(255, 120, 200) })
	local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.47, 0, 0, 90), CellPadding = UDim2.new(0.03, 0, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, key in ipairs(TA.StandOrder) do
		local part = workspace:FindFirstChild("Station_" .. key, true)
		if part and part:IsA("BasePart") then
			bigIcon(grid, TA.StandIcons[key], i, Color3.fromRGB(255, 230, 245), function()
				m.close()
				AnimalUI.trail(part.Position.X, part.Position.Z)
			end)
		end
	end
	m.focus()
end

function AnimalUI.open()
	local m = UI.modal(TA.Title, { color = Color3.fromRGB(200, 140, 80) })
	-- 1.9.1 big ideas #9: climb bar (now → next form) and an animal job, all icons
	local c = Remote.call("animal_climb")
	if c and c.ok then
		local bar = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.fromRGB(60, 50, 40), LayoutOrder = 0, Parent = m.content })
		UI.corner(bar, 14)
		UI.new("Frame", { Size = UDim2.fromScale(math.clamp(c.share or 0, 0.03, 1), 1), BackgroundColor3 = Color3.fromRGB(120, 220, 110), Parent = bar }, { UI.new("UICorner", { CornerRadius = UDim.new(0, 14) }) })
		UI.new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextScaled = true, Text = tostring(c.now) .. "  ➜  " .. tostring(c.nextIcon), Parent = bar }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })
	end
	bigIcon(m.content, TA.Job, 0, Color3.fromRGB(255, 220, 120), function()
		m.close()
		local r = Remote.call("animal_job")
		if r and not r.ok and r.msg then
			UI.toast(r.msg)
		end
	end)
	bigIcon(m.content, TA.Sniff, 1, Color3.fromRGB(150, 220, 110), function()
		sniffPicker()
	end)
	bigIcon(m.content, TA.Stands, 2, Color3.fromRGB(255, 150, 210), function()
		m.close()
		standPicker()
	end)
	if AnimalUI.hasPower and AnimalUI.hasPower() then
		bigIcon(m.content, TA.Power, 3, Color3.fromRGB(255, 190, 60), function()
			m.close()
			if AnimalUI.onPower then
				AnimalUI.onPower()
			end
		end)
	end
	bigIcon(m.content, TA.Home, 4, Color3.fromRGB(140, 190, 255), function()
		m.close()
		local r = Remote.call("places")
		if r and r.ok then
			for _, p in ipairs(r.places) do
				if p.key == "lobby" or p.key == "plaza" then
					AnimalUI.trail(p.x, p.z)
					return
				end
			end
		end
		AnimalUI.trail(0, 30) -- the plaza
	end)
	m.focus()
end

-- 1.9.1: the server shows where an animal job / friend quest wants you to go
function AnimalUI.onTarget(d)
	if d and d.x and d.z then
		AnimalUI.trail(d.x, d.z)
	end
end

-- Becoming human again: no more scent trail
function AnimalUI.onState(st)
	if st and (st.stage == "human" or st.stage == "barelyhuman") then
		clearTrail()
	end
end

return AnimalUI

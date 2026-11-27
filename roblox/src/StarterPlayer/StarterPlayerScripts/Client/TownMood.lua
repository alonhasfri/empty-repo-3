-- TownMood (1.9.3, user: "the map doesn't really change with your brain level"): on top of Style.lua's
-- materials and lighting, each brain style gets BIG, obvious pieces around the plaza and main streets.
-- Client only, so every player sees the town their own brain sees. Low Detail mode skips it.
--   lowpoly  (really dumb): giant floating emoji balloons, pink goo puddles, crooked BRAINROT boards
--   toon     (dumb):        loud flashing joke billboards, bouncing emoji balloons
--   storybook(average):     bunting flags (the cozy start town)
--   textured (smart):       banners with book / science / cap icons, book-stack statues
--   realistic(smarter):     "Did you know?" fact screens, tidy flower beds
--   future   (genius):      floating hologram rings, drones circling the plaza, glowing street strips
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)

local TownMood = {}
local folder: Folder? = nil
local current: string? = nil
local movers = {} -- { part, base CFrame, kind, phase }

local PLAZA = Vector3.new(0, 0, 0)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = folder
	return p
end

local function sign(p: BasePart, text: string, color: Color3, face: Enum.NormalId?)
	for _, f in ipairs(face and { face } or { Enum.NormalId.Front, Enum.NormalId.Back }) do
		local g = Instance.new("SurfaceGui")
		g.Face = f
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 30
		g.MaxDistance = 220
		g.Parent = p
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = color
		l.TextStrokeTransparency = 0.2
		l.Parent = g
	end
end

local function balloon(pos: Vector3, emoji: string, size: number)
	local p = part({ Size = Vector3.new(1, 1, 1), Transparency = 1, CFrame = CFrame.new(pos) })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(size, 0, size, 0)
	bb.MaxDistance = 300
	bb.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = emoji
	l.TextScaled = true
	l.Parent = bb
	table.insert(movers, { part = p, base = p.CFrame, kind = "bob", phase = math.random() * 6 })
	return p
end

-- spots: a ring around the plaza and points along the two main streets
local function ring(n: number, r: number, y: number)
	local list = {}
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		table.insert(list, PLAZA + Vector3.new(math.cos(a) * r, y, math.sin(a) * r))
	end
	return list
end
local function streets(step: number, from: number, to: number, side: number, y: number)
	local list = {}
	for d = from, to, step do
		for _, s in ipairs({ -1, 1 }) do
			table.insert(list, Vector3.new(d * s, y, side))
			table.insert(list, Vector3.new(side, y, d * s))
		end
	end
	return list
end
local function ground(pos: Vector3): Vector3
	local hit = workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0))
	return hit and hit.Position or Vector3.new(pos.X, 0.5, pos.Z)
end

local BUILD = {}

function BUILD.lowpoly()
	for i, pos in ipairs(ring(6, 55, 38)) do
		balloon(pos, ({ "🤪", "💀", "🍌", "🗿", "😵", "🥴" })[i], 14)
	end
	for _, pos in ipairs(streets(45, 40, 160, 14, 0)) do
		local g = ground(pos)
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 7, 9), CFrame = CFrame.new(g + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Neon, Transparency = 0.25 })
	end
	for i, pos in ipairs(ring(4, 40, 0)) do
		local g = ground(pos)
		local board = part({ Size = Vector3.new(12, 6, 0.6), CFrame = CFrame.lookAt(g + Vector3.new(0, 7, 0), PLAZA + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 14 or -12)), Color = Color3.fromRGB(255, 60, 160) })
		sign(board, ({ "BRAINROT ZONE", "NO THOUGHTS", "HEAD EMPTY", "BRAIN.EXE STOPPED" })[i], Color3.new(1, 1, 1))
		part({ Size = Vector3.new(0.6, 8, 0.6), CFrame = CFrame.new(g + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 9 or -9)), Color = Color3.fromRGB(60, 60, 70) })
	end
end

function BUILD.toon()
	for i, pos in ipairs(ring(4, 48, 0)) do
		local g = ground(pos)
		local board = part({ Size = Vector3.new(16, 8, 0.6), CFrame = CFrame.lookAt(g + Vector3.new(0, 10, 0), PLAZA + Vector3.new(0, 10, 0)), Color = Color3.fromRGB(255, 210, 0), Material = Enum.Material.Neon })
		sign(board, ({ "🔥 MEGA DEAL 🔥", "CLICK HERE!!!", "99% OFF BRAINS", "SWIPE NOW 👆" })[i], Color3.fromRGB(230, 30, 120))
		part({ Size = Vector3.new(0.8, 10, 0.8), CFrame = CFrame.new(g + Vector3.new(0, 5, 0)), Color = Color3.fromRGB(40, 40, 50) })
		table.insert(movers, { part = board, base = board.CFrame, kind = "flash", phase = i })
	end
	for i, pos in ipairs(ring(5, 62, 30)) do
		balloon(pos, ({ "😂", "🤑", "🎉", "📱", "🔥" })[i], 11)
	end
end

function BUILD.storybook()
	-- bunting: little triangle flags strung around the plaza
	local pts = ring(12, 36, 9)
	local colors = { Color3.fromRGB(230, 70, 80), Color3.fromRGB(255, 200, 60), Color3.fromRGB(80, 160, 240), Color3.fromRGB(110, 200, 120) }
	for i = 1, #pts do
		local a, b = pts[i], pts[(i % #pts) + 1]
		for k = 1, 6 do
			local p = a:Lerp(b, k / 7) - Vector3.new(0, math.sin(k / 7 * math.pi) * 1.5, 0)
			part({ Size = Vector3.new(1.2, 1.4, 0.1), CFrame = CFrame.lookAt(p, p + (b - a).Unit:Cross(Vector3.yAxis)) * CFrame.Angles(0, 0, math.rad(180)), Color = colors[(k % #colors) + 1], Material = Enum.Material.Fabric })
		end
	end
end

function BUILD.textured()
	for i, pos in ipairs(ring(8, 42, 0)) do
		local g = ground(pos)
		part({ Size = Vector3.new(0.5, 12, 0.5), CFrame = CFrame.new(g + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(50, 55, 70), Material = Enum.Material.Metal })
		local banner = part({ Size = Vector3.new(3.2, 5, 0.15), CFrame = CFrame.lookAt(g + Vector3.new(1.8, 9, 0), PLAZA + Vector3.new(0, 9, 0)), Color = ({ Color3.fromRGB(40, 90, 180), Color3.fromRGB(150, 40, 50) })[(i % 2) + 1], Material = Enum.Material.Fabric })
		sign(banner, ({ "📚", "🔬", "🎓", "💡" })[(i % 4) + 1], Color3.new(1, 1, 1))
	end
	for _, x in ipairs({ -22, 22 }) do
		local g = ground(Vector3.new(x, 0, 26))
		for k = 0, 4 do
			part({ Size = Vector3.new(4 - k * 0.4, 1, 3), CFrame = CFrame.new(g + Vector3.new(0, 0.5 + k, 0)) * CFrame.Angles(0, math.rad(k * 9), 0), Color = ({ Color3.fromRGB(200, 70, 70), Color3.fromRGB(70, 120, 200), Color3.fromRGB(90, 170, 90) })[(k % 3) + 1] })
		end
	end
end

function BUILD.realistic()
	local facts = Content.MoodFacts or { "🐙 Octopuses have 3 hearts.", "🍯 Honey never goes bad.", "🌍 Earth is 4.5 billion years old." }
	for i, pos in ipairs(ring(4, 46, 0)) do
		local g = ground(pos)
		local screen = part({ Size = Vector3.new(12, 6, 0.4), CFrame = CFrame.lookAt(g + Vector3.new(0, 8, 0), PLAZA + Vector3.new(0, 8, 0)), Color = Color3.fromRGB(20, 25, 35) })
		sign(screen, "💡 DID YOU KNOW?\n" .. facts[((i - 1) % #facts) + 1], Color3.fromRGB(220, 235, 255), Enum.NormalId.Front)
		part({ Size = Vector3.new(0.6, 5, 0.6), CFrame = CFrame.new(g + Vector3.new(0, 2.5, 0)), Color = Color3.fromRGB(150, 155, 165), Material = Enum.Material.Metal })
	end
	for _, pos in ipairs(ring(6, 30, 0)) do
		local g = ground(pos)
		part({ Size = Vector3.new(5, 0.8, 2.4), CFrame = CFrame.new(g + Vector3.new(0, 0.4, 0)), Color = Color3.fromRGB(150, 150, 155), Material = Enum.Material.Concrete })
		for k = -1, 1 do
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = CFrame.new(g + Vector3.new(k * 1.5, 1.2, 0)), Color = ({ Color3.fromRGB(240, 90, 120), Color3.fromRGB(255, 220, 90), Color3.fromRGB(180, 120, 240) })[k + 2] })
		end
	end
end

function BUILD.future()
	for i, pos in ipairs(ring(6, 40, 14)) do
		local r = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 9, 9), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 230, 255), Material = Enum.Material.Neon, Transparency = 0.55 })
		table.insert(movers, { part = r, base = r.CFrame, kind = "spin", phase = i })
	end
	for i = 1, 4 do
		local d = part({ Size = Vector3.new(2.2, 0.5, 2.2), Color = Color3.fromRGB(120, 255, 200), Material = Enum.Material.Neon, CFrame = CFrame.new(PLAZA + Vector3.new(0, 22, 0)) })
		table.insert(movers, { part = d, base = CFrame.new(PLAZA + Vector3.new(0, 20 + i * 2, 0)), kind = "orbit", phase = i * 1.57 })
	end
	for _, pos in ipairs(streets(20, 20, 160, 9, 0)) do
		local g = ground(pos)
		part({ Size = Vector3.new(3, 0.1, 0.3), CFrame = CFrame.new(g + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, math.rad(math.abs(pos.X) > math.abs(pos.Z) and 0 or 90), 0), Color = Color3.fromRGB(90, 230, 255), Material = Enum.Material.Neon })
	end
end

function TownMood.apply(styleName: string, lowDetail: boolean)
	local key = lowDetail and "low" or styleName
	if key == current then
		return
	end
	current = key
	if folder then
		folder:Destroy()
	end
	movers = {}
	folder = Instance.new("Folder")
	folder.Name = "TownMood"
	if not lowDetail and BUILD[styleName] then
		local ok, err = pcall(BUILD[styleName])
		if not ok then
			warn("[TownMood] " .. tostring(err))
		end
	end
	folder.Parent = workspace
end

local t = 0
RunService.Heartbeat:Connect(function(dt)
	if #movers == 0 or UI.reducedMotion() then
		return
	end
	t += dt
	for _, m in ipairs(movers) do
		if m.part.Parent then
			if m.kind == "bob" then
				m.part.CFrame = m.base * CFrame.new(0, math.sin(t * 1.2 + m.phase) * 2, 0)
			elseif m.kind == "spin" then
				m.part.CFrame = m.base * CFrame.Angles(t * 0.8 + m.phase, 0, 0) * CFrame.new(0, math.sin(t + m.phase), 0)
			elseif m.kind == "orbit" then
				local a = t * 0.5 + m.phase
				m.part.CFrame = m.base * CFrame.new(math.cos(a) * 30, math.sin(t * 2 + m.phase), math.sin(a) * 30)
			elseif m.kind == "flash" then
				local h = (t * 0.25 + m.phase * 0.2) % 1
				m.part.Color = Color3.fromHSV(h, 0.85, 1)
			end
		end
	end
end)

return TownMood

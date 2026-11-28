-- GeniusIntro (1.9.4, user: "the genius has to pop up on you, and the whole genius thing should be a cutscene"):
-- a real 3D cutscene the first time the Genius Crossroads opens for you. Your avatar (a clone) stands on a
-- glowing platform in the sky; light pours out of its head; five roads fan out, each with a signpost and a
-- landmark (math cube, physics atom, coding screen, business tower, chess king) that lights up one by one;
-- then you point down the roads and the Crossroads chooser pops up. Letterbox, captions, Skip, Reduced Motion.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local VsStage = require(script.Parent.VsStage)

local TI = Content.GeniusIntro
local player = Players.LocalPlayer
local GeniusIntro = {}

local ORIGIN = Vector3.new(-400, 1600, 0)
local ORDER = { "math", "physics", "coding", "business", "chess" }
local COLORS = {
	math = Color3.fromRGB(90, 170, 255),
	physics = Color3.fromRGB(170, 110, 255),
	coding = Color3.fromRGB(70, 220, 140),
	business = Color3.fromRGB(255, 190, 60),
	chess = Color3.fromRGB(240, 240, 250),
}
local playing = false

function GeniusIntro.isPlaying(): boolean
	return playing
end

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function signText(p: BasePart, text: string, face: Enum.NormalId)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = g
end

-- a small landmark per branch, built from parts (returns the parts that light up)
local function landmark(folder, key: string, at: Vector3, color: Color3)
	local lit = {}
	if key == "math" then
		local c = part(folder, { Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(at + Vector3.new(0, 4, 0)) * CFrame.Angles(0.5, 0.6, 0), Color = color })
		signText(c, "π", Enum.NormalId.Front)
		signText(c, "∑", Enum.NormalId.Top)
		table.insert(lit, c)
	elseif key == "physics" then
		local core = part(folder, { Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(at + Vector3.new(0, 4.5, 0)), Color = color })
		table.insert(lit, core)
		for i = 0, 2 do
			local ring = part(folder, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 7, 7), CFrame = CFrame.new(at + Vector3.new(0, 4.5, 0)) * CFrame.Angles(i * 1.05, 0, math.pi / 2), Color = color, Transparency = 0.4 })
			table.insert(lit, ring)
		end
	elseif key == "coding" then
		part(folder, { Size = Vector3.new(0.6, 3, 0.6), CFrame = CFrame.new(at + Vector3.new(0, 1.5, 0)), Color = Color3.fromRGB(40, 40, 45) })
		local screen = part(folder, { Size = Vector3.new(7, 4.5, 0.4), CFrame = CFrame.new(at + Vector3.new(0, 5, 0)), Color = Color3.fromRGB(20, 25, 30) })
		signText(screen, "</>", Enum.NormalId.Back)
		signText(screen, "</>", Enum.NormalId.Front)
		table.insert(lit, screen)
	elseif key == "business" then
		for i = 0, 2 do
			local h = 4 + i * 3
			local b = part(folder, { Size = Vector3.new(2, h, 2), CFrame = CFrame.new(at + Vector3.new((i - 1) * 2.3, h / 2, 0)), Color = color, Material = Enum.Material.Glass, Transparency = 0.15 })
			table.insert(lit, b)
		end
	else
		local base = part(folder, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 4, 4), CFrame = CFrame.new(at + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = color })
		local body = part(folder, { Size = Vector3.new(2, 5, 2), CFrame = CFrame.new(at + Vector3.new(0, 3.5, 0)), Color = color })
		local crossV = part(folder, { Size = Vector3.new(0.6, 2, 0.6), CFrame = CFrame.new(at + Vector3.new(0, 7, 0)), Color = color })
		local crossH = part(folder, { Size = Vector3.new(1.8, 0.6, 0.6), CFrame = CFrame.new(at + Vector3.new(0, 7.2, 0)), Color = color })
		lit = { base, body, crossV, crossH }
	end
	return lit
end

-- the set: a round glowing platform in the sky, five roads fanning out ahead, signposts and landmarks
local function buildSet(folder)
	local o = ORIGIN
	part(folder, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 22, 22), CFrame = CFrame.new(o + Vector3.new(0, -0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(235, 225, 255), Material = Enum.Material.Marble })
	local ring = part(folder, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 23, 23), CFrame = CFrame.new(o + Vector3.new(0, -0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon })
	local l = Instance.new("PointLight")
	l.Range = 30
	l.Brightness = 1
	l.Color = ring.Color
	l.Parent = ring
	local roads = {}
	for i, key in ipairs(ORDER) do
		local ang = math.rad(-60 + (i - 1) * 30) -- a fan from left to right, all going "forward" (-Z)
		local dir = Vector3.new(math.sin(ang), 0, -math.cos(ang))
		local mid = o + dir * 30
		part(folder, { Size = Vector3.new(6, 0.6, 40), CFrame = CFrame.lookAt(mid + Vector3.new(0, -0.6, 0), mid + dir + Vector3.new(0, -0.6, 0)), Color = Color3.fromRGB(70, 70, 85), Material = Enum.Material.Slate })
		local stripe = part(folder, { Size = Vector3.new(0.5, 0.65, 40), CFrame = CFrame.lookAt(mid + Vector3.new(0, -0.55, 0), mid + dir + Vector3.new(0, -0.55, 0)), Color = COLORS[key], Material = Enum.Material.SmoothPlastic })
		local branch = Content.Genius.Branches[key]
		local postAt = o + dir * 13 + Vector3.new(dir.Z, 0, -dir.X) * 4
		part(folder, { Size = Vector3.new(0.5, 6, 0.5), CFrame = CFrame.new(postAt + Vector3.new(0, 3, 0)), Color = Color3.fromRGB(120, 90, 60), Material = Enum.Material.Wood })
		local board = part(folder, { Size = Vector3.new(6, 2, 0.4), CFrame = CFrame.lookAt(postAt + Vector3.new(0, 6, 0), postAt + Vector3.new(0, 6, 0) - dir), Color = Color3.fromRGB(60, 60, 75) })
		signText(board, branch.icon .. " " .. branch.name, Enum.NormalId.Back)
		signText(board, branch.icon .. " " .. branch.name, Enum.NormalId.Front)
		local lit = landmark(folder, key, o + dir * 50, COLORS[key])
		table.insert(roads, { key = key, dir = dir, stripe = stripe, lit = lit, board = board })
	end
	-- the arch over the platform
	for _, x in ipairs({ -10, 10 }) do
		part(folder, { Size = Vector3.new(1.5, 14, 1.5), CFrame = CFrame.new(o + Vector3.new(x, 7, -9)), Color = Color3.fromRGB(255, 215, 120), Material = Enum.Material.Neon })
	end
	-- turned so its Front face looks back at the camera (the Back-face text read upside down)
	local arch = part(folder, { Size = Vector3.new(21.5, 2.5, 1.5), CFrame = CFrame.new(o + Vector3.new(0, 14.5, -9)) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(70, 50, 120) })
	signText(arch, TI.Sign, Enum.NormalId.Front)
	return roads
end

local function sparkle(at: BasePart, color: Color3, calm: boolean)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Rate = 0
	e.Parent = at
	e:Emit(calm and 8 or 30)
end

function GeniusIntro.play(onDone)
	if playing then
		return
	end
	playing = true
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local calm = UI.reducedMotion()
	local cam = workspace.CurrentCamera
	local folder = Instance.new("Folder")
	folder.Name = "GeniusIntro"
	local roads = buildSet(folder)
	folder.Parent = cam
	local o = ORIGIN
	local me = VsStage.actorFrom(char)
	VsStage.place(me, CFrame.lookAt(o, o + Vector3.new(0, 0, -1)), folder)
	VsStage.play(me, "idle", true)
	if root then
		root.Anchored = true
	end
	if UI.gui then
		UI.gui.Enabled = false
	end
	GuiService.TouchControlsEnabled = false

	-- letterbox, caption, skip (same kit as the brain ending)
	local sg = Instance.new("ScreenGui")
	sg.Name = "GeniusIntroGui"
	sg.IgnoreGuiInset = true
	sg.ScreenInsets = Enum.ScreenInsets.None
	sg.DisplayOrder = 50
	sg.ResetOnSpawn = false
	sg.Parent = player:WaitForChild("PlayerGui")
	for _, top in ipairs({ true, false }) do
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.fromScale(1, 0.11)
		bar.Position = top and UDim2.fromScale(0, 0) or UDim2.fromScale(0, 0.89)
		bar.Parent = sg
	end
	local caption = Instance.new("TextLabel")
	caption.AnchorPoint = Vector2.new(0.5, 1)
	caption.Position = UDim2.fromScale(0.5, 0.86)
	caption.Size = UDim2.fromScale(0.8, 0.08)
	caption.BackgroundTransparency = 1
	caption.Font = Enum.Font.FredokaOne
	caption.TextScaled = true
	caption.TextColor3 = Color3.new(1, 1, 1)
	caption.TextStrokeTransparency = 0.3
	caption.Text = ""
	caption.Parent = sg
	local skipped = false
	local skip = Instance.new("TextButton")
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(0.95, 0, 0.015, 0)
	skip.Size = UDim2.fromOffset(120, 48)
	skip.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	skip.TextColor3 = Color3.new(1, 1, 1)
	skip.Font = Enum.Font.GothamBold
	skip.TextScaled = true
	skip.Text = TI.Skip
	skip.Parent = sg
	Instance.new("UICorner").Parent = skip
	skip.Activated:Connect(function()
		skipped = true
	end)
	local fade = Instance.new("Frame")
	fade.Size = UDim2.fromScale(1, 1)
	fade.BackgroundColor3 = Color3.new(1, 1, 1)
	fade.BackgroundTransparency = 1
	fade.BorderSizePixel = 0
	fade.ZIndex = 5
	fade.Parent = sg

	local fov0 = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	local function shot(eye: Vector3, at: Vector3, fov: number, seconds: number?)
		if seconds and seconds > 0 and not calm then
			TweenService:Create(cam, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(eye, at), FieldOfView = fov }):Play()
		else
			cam.CFrame = CFrame.lookAt(eye, at)
			cam.FieldOfView = fov
		end
	end
	local function wait(s)
		local t0 = os.clock()
		while os.clock() - t0 < s and not skipped do
			RunService.RenderStepped:Wait()
		end
	end
	local head = me and me:FindFirstChild("Head") :: BasePart?
	local headPos = head and head.Position or (o + Vector3.new(0, 4.5, 0))

	-- 1: from far below and behind, rising up to the platform in the sky
	shot(o + Vector3.new(30, -6, 34), headPos, 60)
	shot(o + Vector3.new(14, 6, 20), headPos, 55, 3)
	caption.Text = TI.Grow
	UI.sound("Whoosh", 0.4)
	wait(3)
	-- 2: close-up from the front: light pours out of your head, you cheer
	shot(headPos + Vector3.new(1.5, 0.5, -8), headPos, 45)
	caption.Text = TI.Genius
	local beam = part(folder, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(60, 2.4, 2.4), CFrame = CFrame.new(headPos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(255, 235, 150), Material = Enum.Material.Neon, Transparency = 1 })
	TweenService:Create(beam, TweenInfo.new(0.6), { Transparency = 0.35 }):Play()
	if head then
		sparkle(head, Color3.fromRGB(255, 230, 120), calm)
	end
	if not calm then
		fade.BackgroundTransparency = 0.3
		TweenService:Create(fade, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	end
	VsStage.play(me, "cheer", false)
	UI.sound("LevelUp", 0.6)
	wait(2.8)
	-- 3: over your shoulder: the five roads light up one by one
	caption.Text = TI.Roads
	beam:Destroy() -- (it filled the middle of the roads shot)
	shot(o + Vector3.new(0, 12, 16), o + Vector3.new(0, 2, -30), 70)
	shot(o + Vector3.new(0, 16, 10), o + Vector3.new(0, 0, -40), 70, 4.5)
	for _, r in ipairs(roads) do
		if skipped then
			break
		end
		r.stripe.Material = Enum.Material.Neon
		for _, p in ipairs(r.lit) do
			p.Material = Enum.Material.Neon
			local pl = Instance.new("PointLight")
			pl.Color = COLORS[r.key]
			pl.Range = 14
			pl.Parent = p
		end
		sparkle(r.lit[1], COLORS[r.key], calm)
		UI.sound("BadgeSparkle", 0.35)
		wait(0.8)
	end
	wait(0.6)
	-- 4: front-low hero shot: you point down the roads
	shot(headPos + Vector3.new(-5, -1.5, -10), headPos + Vector3.new(0, 1, 0), 50)
	VsStage.play(me, "point", false)
	caption.Text = TI.Pick
	UI.sound("NotificationPing", 0.4)
	wait(2.6)

	-- fade out, clean up, then the chooser pops up
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	TweenService:Create(fade, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
	task.wait(0.6)
	folder:Destroy()
	sg:Destroy()
	cam.FieldOfView = fov0
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraSubject = hum
	end
	if UI.gui then
		UI.gui.Enabled = true
	end
	GuiService.TouchControlsEnabled = true
	if root and root.Parent then
		root.Anchored = false
	end
	playing = false
	if onDone then
		onDone()
	end
end

return GeniusIntro

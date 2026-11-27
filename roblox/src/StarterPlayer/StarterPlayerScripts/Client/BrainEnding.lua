-- BrainEnding (1.9.3, user: "cutscenes aren't real cutscenes, they're emojis moving. Your brain explodes, your
-- actual Roblox character explodes, then your brain starts walking out"). The 0-cell ending as a real 3D
-- cutscene (docs/Cutscene research.md, shot list a), on a small street set built away from the town:
--   1 wide: your avatar on the street, "Brain cells: 0."      2 medium: it flails, "Uh oh."
--   3 close-up: the head swells                                4 BOOM: flash, confetti, stars, smoke, and the
--   avatar's pieces fly apart and fade (cartoon, never gory)   5 a little pink brain with eyes and legs pops up
--   6 close-up: it blinks, "Your brain is still here."         7 it hops up, "It gets up."
--   8 tracking shot: it walks to the town gate                 9 wide from behind: it leaves, fade out
-- Letterbox bars, captions and a Skip button. Reduced Motion: no shake, no flash, fewer particles.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local VsStage = require(script.Parent.VsStage)

local TE = Content.BrainEnding
local player = Players.LocalPlayer
local BrainEnding = {}

local ORIGIN = Vector3.new(400, 1600, 0)

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

-- the street set: road, sidewalks, lamp posts, a few houses and the town gate at the far end
local function buildSet(folder)
	local o = ORIGIN
	part(folder, { Size = Vector3.new(40, 1, 120), CFrame = CFrame.new(o + Vector3.new(0, -0.5, -40)), Color = Color3.fromRGB(70, 70, 78), Material = Enum.Material.Asphalt })
	for _, x in ipairs({ -26, 26 }) do
		part(folder, { Size = Vector3.new(12, 1.2, 120), CFrame = CFrame.new(o + Vector3.new(x, -0.4, -40)), Color = Color3.fromRGB(190, 180, 165), Material = Enum.Material.Pavement })
		for k = 0, 3 do
			local z = 10 - k * 28
			part(folder, { Size = Vector3.new(0.6, 10, 0.6), CFrame = CFrame.new(o + Vector3.new(x * 0.8, 5, z)), Color = Color3.fromRGB(35, 35, 40), Material = Enum.Material.Metal })
			local lamp = part(folder, { Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(o + Vector3.new(x * 0.8, 10.5, z)), Color = Color3.fromRGB(255, 225, 160), Material = Enum.Material.Neon })
			local l = Instance.new("PointLight")
			l.Range = 16
			l.Brightness = 1.5
			l.Parent = lamp
			local h = 14 + (k % 2) * 6
			part(folder, { Size = Vector3.new(14, h, 18), CFrame = CFrame.new(o + Vector3.new(x * 1.45, h / 2, z)), Color = ({ Color3.fromRGB(200, 120, 90), Color3.fromRGB(110, 150, 200), Color3.fromRGB(230, 200, 120), Color3.fromRGB(150, 190, 140) })[k + 1], Material = Enum.Material.Brick })
		end
	end
	-- the town gate at the end of the street
	for _, x in ipairs({ -9, 9 }) do
		part(folder, { Size = Vector3.new(2.5, 16, 2.5), CFrame = CFrame.new(o + Vector3.new(x, 8, -92)), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood })
	end
	local arch = part(folder, { Size = Vector3.new(22, 3, 2), CFrame = CFrame.new(o + Vector3.new(0, 16.5, -92)), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood })
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.Parent = arch
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = TE.Gate
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = g
end

-- the little brain: a pink body with folds, big eyes and two tiny legs (all parts, moved by CFrame)
local function buildBrain(folder)
	local m = Instance.new("Model")
	m.Name = "LittleBrain"
	local pink = Color3.fromRGB(255, 150, 185)
	local body = part(m, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 2.6, 3.6), Color = pink })
	local pieces = {}
	local function add(p, offset)
		table.insert(pieces, { part = p, offset = offset })
	end
	add(body, CFrame.new(0, 2.6, 0))
	-- the folds: round ridges along the top (flat slabs looked like ears)
	for k = -1, 1 do
		add(part(m, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.8, 0.55, 0.55), Color = Color3.fromRGB(235, 120, 160) }), CFrame.new(k * 0.75, 3.55 - math.abs(k) * 0.35, 0.1) * CFrame.Angles(0, math.rad(90), 0))
	end
	local eyes = {}
	for _, x in ipairs({ -0.6, 0.6 }) do
		local e = part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Color = Color3.new(1, 1, 1) })
		add(e, CFrame.new(x, 2.9, -1.5))
		local pupil = part(m, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Color = Color3.fromRGB(20, 20, 30) })
		add(pupil, CFrame.new(x, 2.9, -1.9))
		table.insert(eyes, e)
		table.insert(eyes, pupil)
	end
	local legs = {}
	for _, x in ipairs({ -0.6, 0.6 }) do
		local leg = part(m, { Size = Vector3.new(0.35, 1.4, 0.35), Color = pink })
		local foot = part(m, { Size = Vector3.new(0.6, 0.3, 0.8), Color = Color3.fromRGB(230, 110, 150) })
		table.insert(legs, { leg = leg, foot = foot, x = x })
	end
	m.Parent = folder
	local brain = { model = m, pieces = pieces, legs = legs, eyes = eyes, cf = CFrame.new(), scale = 1, step = 0, blink = 1 }
	function brain.draw()
		local s = brain.scale
		for _, p in ipairs(brain.pieces) do
			local o = p.offset
			p.part.CFrame = brain.cf * CFrame.new(o.Position * s) * (o - o.Position)
		end
		for i, l in ipairs(brain.legs) do
			local swing = math.sin(brain.step + (i == 1 and 0 or math.pi)) * 0.6
			l.leg.CFrame = brain.cf * CFrame.new(l.x * s, 0.9 * s, 0) * CFrame.Angles(swing, 0, 0)
			l.foot.CFrame = brain.cf * CFrame.new(l.x * s, 0.15 * s, -0.2 * s - math.sin(swing) * 0.5)
		end
	end
	function brain.setScale(s)
		brain.scale = s
		for _, p in ipairs(brain.pieces) do
			p.part.Size = p.part:GetAttribute("Base") * s
		end
		for _, l in ipairs(brain.legs) do
			l.leg.Size = l.leg:GetAttribute("Base") * s
			l.foot.Size = l.foot:GetAttribute("Base") * s
		end
	end
	for _, p in ipairs(pieces) do
		p.part:SetAttribute("Base", p.part.Size)
	end
	for _, l in ipairs(legs) do
		l.leg:SetAttribute("Base", l.leg.Size)
		l.foot:SetAttribute("Base", l.foot.Size)
	end
	return brain
end

local function burst(at: Vector3, folder, calm: boolean)
	local holder = part(folder, { Size = Vector3.new(1, 1, 1), Transparency = 1, CFrame = CFrame.new(at) })
	local function emitter(color: ColorSequence, n: number, speed: number, size: number, lifetime: number)
		local e = Instance.new("ParticleEmitter")
		e.Color = color
		e.Speed = NumberRange.new(speed * 0.6, speed)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Lifetime = NumberRange.new(lifetime * 0.6, lifetime)
		e.Size = NumberSequence.new(size, size * 0.4)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-200, 200)
		e.Acceleration = Vector3.new(0, -12, 0)
		e.Rate = 0
		e.Parent = holder
		e:Emit(calm and math.floor(n / 3) or n)
	end
	emitter(ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 200, 255)) }), 70, 30, 0.6, 2.2) -- confetti
	emitter(ColorSequence.new(Color3.fromRGB(255, 240, 120)), 25, 22, 1, 1.4) -- sparkles
	emitter(ColorSequence.new(Color3.fromRGB(235, 235, 240)), 18, 10, 3, 1.6) -- cartoon smoke puffs
end

local playing = false
function BrainEnding.isPlaying(): boolean
	return playing
end
function BrainEnding.play(d, onDone)
	if playing then
		return -- only one ending at a time (two at once fought over the camera and the HUD)
	end
	playing = true
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local calm = UI.reducedMotion()
	local cam = workspace.CurrentCamera
	local folder = Instance.new("Folder")
	folder.Name = "BrainEnding"
	buildSet(folder)
	folder.Parent = cam
	local o = ORIGIN
	local stand = CFrame.lookAt(o, o + Vector3.new(0, 0, -1))
	local me = VsStage.actorFrom(char)
	VsStage.place(me, stand, folder)
	VsStage.play(me, "idle", true)
	if root then
		root.Anchored = true
	end
	if UI.gui then
		UI.gui.Enabled = false
	end
	-- letterbox, caption, skip
	local sg = Instance.new("ScreenGui")
	sg.Name = "BrainEndingGui"
	sg.IgnoreGuiInset = true
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
	skip.Position = UDim2.new(1, -12, 0.015, 0)
	skip.Size = UDim2.fromOffset(110, 44)
	skip.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	skip.TextColor3 = Color3.new(1, 1, 1)
	skip.Font = Enum.Font.GothamBold
	skip.TextScaled = true
	skip.Text = TE.Skip
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
	local fov0 = cam.FieldOfView

	-- 1: wide, "Brain cells: 0."
	shot(o + Vector3.new(-14, 10, 20), headPos, 70)
	shot(o + Vector3.new(-11, 8, 16), headPos, 66, 2.5)
	caption.Text = TE.Zero
	UI.sound("SadTrombone", 0.4)
	wait(2.6)
	-- 2: medium front, "Uh oh."
	shot(headPos + Vector3.new(2, -0.5, -9), headPos, 55)
	VsStage.play(me, "wave", false)
	caption.Text = TE.UhOh
	UI.sound("Whoosh", 0.4)
	wait(2)
	-- 3: close-up, the head swells
	shot(headPos + Vector3.new(0, 0.3, -4.2), headPos, 42)
	caption.Text = ""
	if head then
		TweenService:Create(head, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = head.Size * 1.7 }):Play()
	end
	for i = 1, 7 do
		if skipped then
			break
		end
		if i % 2 == 0 then
			UI.sound("CartoonBoing", 0.35)
		end
		if not calm then
			cam.CFrame *= CFrame.new(math.random(-10, 10) / 100, math.random(-10, 10) / 100, 0)
		end
		wait(0.2)
	end
	-- 4: BOOM
	shot(o + Vector3.new(6, 2.5, 15), headPos, 80)
	if not calm then
		fade.BackgroundTransparency = 0.1
		TweenService:Create(fade, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	end
	UI.sound("DeathBoom", d and d.loud and 1 or 0.7)
	caption.Text = TE.Boom
	burst(headPos, folder, calm)
	if me then
		for _, j in ipairs(me:GetDescendants()) do
			if j:IsA("Motor6D") or j:IsA("Weld") or j:IsA("WeldConstraint") then
				j:Destroy()
			end
		end
		for _, p in ipairs(me:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true
				local dir = (p.Position - o + Vector3.new(math.random(-10, 10) / 10, 1.5, math.random(-10, 10) / 10)).Unit
				TweenService:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = p.CFrame * CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), 0) + dir * math.random(5, 9),
					Transparency = 1,
				}):Play()
			elseif p:IsA("Decal") then
				TweenService:Create(p, TweenInfo.new(1), { Transparency = 1 }):Play()
			end
		end
	end
	if not calm then
		for _ = 1, 8 do
			cam.CFrame *= CFrame.new(math.random(-25, 25) / 100, math.random(-25, 25) / 100, 0)
			wait(0.04)
		end
	end
	wait(1.4)
	-- 5: the little brain pops up where you stood and looks around
	local brain = buildBrain(folder)
	brain.cf = stand
	brain.setScale(0.05)
	brain.draw()
	UI.sound("Pop", 0.6)
	caption.Text = "…"
	local t = 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		brain.draw()
	end)
	for i = 1, 10 do
		brain.setScale(i / 10)
		RunService.RenderStepped:Wait()
	end
	for _, yaw in ipairs({ 35, -35, 0 }) do
		if skipped then
			break
		end
		brain.cf = stand * CFrame.Angles(0, math.rad(yaw), 0)
		wait(0.45)
	end
	-- 6: close-up, it blinks
	local face = stand.Position + Vector3.new(0, 2.9, 0)
	shot(face + Vector3.new(0, 0.4, -6), face, 45)
	caption.Text = TE.StillHere
	for _ = 1, 2 do
		for _, e in ipairs(brain.eyes) do
			e.Transparency = 1
		end
		wait(0.12)
		for _, e in ipairs(brain.eyes) do
			e.Transparency = 0
		end
		wait(0.35)
	end
	wait(0.8)
	-- 7: it hops up
	shot(stand.Position + Vector3.new(8, 3, -3), face, 60)
	caption.Text = TE.GetsUp
	UI.sound("CartoonBoing", 0.4)
	for k = 0, 10 do
		brain.cf = stand + Vector3.new(0, math.sin(k / 10 * math.pi) * 2, 0)
		RunService.RenderStepped:Wait()
	end
	brain.cf = stand
	wait(1)
	-- 8: tracking shot, it walks to the gate
	caption.Text = TE.WalksOff
	UI.sound("KazooTune", 0.4)
	local walkStart = os.clock()
	while os.clock() - walkStart < 4.5 and not skipped do
		local dt = RunService.RenderStepped:Wait()
		brain.step += dt * 9
		brain.cf = brain.cf * CFrame.new(0, 0, -dt * 11) + Vector3.new(0, 0, 0)
		local p = brain.cf.Position
		cam.CFrame = CFrame.lookAt(p + Vector3.new(9, 4, 4), p + Vector3.new(0, 2.5, -3))
	end
	-- 9: wide from behind, it leaves through the gate
	local p = brain.cf.Position
	shot(p + Vector3.new(0, 7, 22), p + Vector3.new(0, 3, -20), 70)
	local leave = os.clock()
	while os.clock() - leave < 2.2 and not skipped do
		local dt = RunService.RenderStepped:Wait()
		brain.step += dt * 9
		brain.cf = brain.cf * CFrame.new(0, 0, -dt * 11)
	end
	-- fade out and clean up
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	TweenService:Create(fade, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
	task.wait(0.7)
	conn:Disconnect()
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
	if root and root.Parent then
		root.Anchored = false -- (a real 0-cell ending respawns you anyway; a test replay must not leave you frozen)
	end
	local _ = t
	playing = false
	if onDone then
		onDone()
	end
end

return BrainEnding

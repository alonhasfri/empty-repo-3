-- VsStage (1.9.3, user: "Vs Mode has to be an actual cutscene, not emojis moving with camera effects"):
-- a real 3D debate stage for Conversation.vsStart, built client-side far above the town, with
--   * clones of BOTH players' real avatars at podiums (an NPC partner gets a stand-in avatar)
--   * a judge on a high bench with a gavel, and a small crowd on benches
--   * Roblox's own R15 animations (idle, point, wave, laugh, cheer) when someone speaks or wins
-- Conversation.lua still runs the typed lines, choices and camera cuts; this builds the set and the
-- actors and plays their gestures. Everything is destroyed when the scene closes.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local VsStage = {}

local ORIGIN = Vector3.new(0, 1400, 0) -- far above the map, so the town never gets in the shot
-- Roblox's own default R15 animations (free for every game)
local ANIM = {
	idle = "rbxassetid://507766388",
	point = "rbxassetid://507770453",
	wave = "rbxassetid://507770239",
	laugh = "rbxassetid://507770818",
	cheer = "rbxassetid://507770677",
}

local function part(parent: Instance, props)
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

local function sign(p: BasePart, text: string, color: Color3, bg: Color3?)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = bg and 0 or 1
	l.BackgroundColor3 = bg or Color3.new()
	l.Text = text
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = color
	l.Parent = g
end

-- an actor: a clone of a real character (or a stand-in) with its scripts removed and its root anchored
local function actorFrom(model: Model?, tint: Color3?): Model?
	if not model then
		return nil
	end
	local was = model.Archivable
	model.Archivable = true
	local ok, clone = pcall(function()
		return model:Clone()
	end)
	model.Archivable = was
	if not ok or not clone then
		return nil
	end
	for _, d in ipairs(clone:GetDescendants()) do
		-- scripts, tools, name tags and sounds go; a stand-in also loses its clothes, colours and hats (plain
		-- coloured body, so it reads as someone else)
		local standInExtra = tint and (d:IsA("BodyColors") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("Accessory"))
		if standInExtra or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Tool") or d:IsA("BillboardGui") or d:IsA("Sound") or d:IsA("ForceField") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			if tint and d.Name ~= "HumanoidRootPart" then
				d.Color = d.Name == "Head" and Color3.fromRGB(255, 220, 180) or tint
				local face = d:FindFirstChildOfClass("Decal")
				local _ = face
			end
		end
	end
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.PlatformStand = true
		if not hum:FindFirstChildOfClass("Animator") then
			Instance.new("Animator").Parent = hum
		end
	end
	local root = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = true
	end
	return clone
end

local function place(actor: Model?, cf: CFrame, parent: Instance)
	if not actor then
		return
	end
	actor.Parent = parent
	local root = actor:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = actor:FindFirstChildOfClass("Humanoid")
	local hip = (hum and hum.HipHeight or 2) + (root and root.Size.Y / 2 or 1)
	actor:PivotTo(cf + Vector3.new(0, hip, 0))
end

local function play(actor: Model?, name: string, looped: boolean?)
	if not actor then
		return
	end
	local hum = actor:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator or hum.RigType ~= Enum.HumanoidRigType.R15 then
		return -- the default animations are R15 only
	end
	local a = Instance.new("Animation")
	a.AnimationId = ANIM[name] or ANIM.idle
	local ok, track = pcall(function()
		return animator:LoadAnimation(a)
	end)
	if ok and track then
		track.Looped = looped == true
		track.Priority = looped and Enum.AnimationPriority.Idle or Enum.AnimationPriority.Action
		track:Play(0.15)
	end
end

-- Build the stage. me/other = the real characters (other may be nil for an NPC partner).
function VsStage.build(title: string, meChar: Model?, otherChar: Model?, otherLabel: string?)
	local folder = Instance.new("Folder")
	folder.Name = "VsStage"
	local o = ORIGIN
	-- the hall: floor, back wall with the show's name, side walls, spotlights
	part(folder, { Size = Vector3.new(70, 1, 90), CFrame = CFrame.new(o + Vector3.new(0, 0, 20)), Color = Color3.fromRGB(120, 78, 48), Material = Enum.Material.WoodPlanks })
	part(folder, { Size = Vector3.new(70, 30, 1), CFrame = CFrame.new(o + Vector3.new(0, 15, 64)), Color = Color3.fromRGB(70, 30, 90) }) -- the back of the room, behind the camera
	local back = part(folder, { Size = Vector3.new(70, 30, 1), CFrame = CFrame.new(o + Vector3.new(0, 15, -24)), Color = Color3.fromRGB(70, 30, 90) })
	local banner = part(folder, { Size = Vector3.new(40, 6, 0.4), CFrame = CFrame.new(o + Vector3.new(0, 22, -23.2)), Color = Color3.fromRGB(255, 200, 60) })
	sign(banner, "🧠 " .. string.upper(title) .. " 🧠", Color3.fromRGB(60, 20, 80))
	for _, x in ipairs({ -35, 35 }) do
		part(folder, { Size = Vector3.new(1, 30, 90), CFrame = CFrame.new(o + Vector3.new(x, 15, 20)), Color = Color3.fromRGB(90, 40, 110) })
	end
	part(folder, { Size = Vector3.new(70, 1, 90), CFrame = CFrame.new(o + Vector3.new(0, 30, 20)), Color = Color3.fromRGB(40, 20, 50) })
	for _, x in ipairs({ -10, 10 }) do
		local lamp = part(folder, { Size = Vector3.new(1, 1, 1), Transparency = 1, CFrame = CFrame.new(o + Vector3.new(x, 26, 4)) })
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Brightness = 4
		light.Range = 40
		light.Angle = 60
		light.Parent = lamp
	end
	-- two podiums facing each other, angled toward the audience
	local meSpot = CFrame.lookAt(o + Vector3.new(-9, 0.5, 2), o + Vector3.new(9, 0.5, -2))
	local otherSpot = CFrame.lookAt(o + Vector3.new(9, 0.5, 2), o + Vector3.new(-9, 0.5, -2))
	for i, spot in ipairs({ meSpot, otherSpot }) do
		local pod = part(folder, { Size = Vector3.new(4, 3.4, 2), CFrame = spot * CFrame.new(0, 1.7, -2.2), Color = i == 1 and Color3.fromRGB(60, 140, 255) or Color3.fromRGB(255, 80, 170) })
		local label = part(folder, { Size = Vector3.new(3.6, 1.2, 0.1), CFrame = pod.CFrame * CFrame.new(0, 0.6, -1.06) * CFrame.Angles(0, math.pi, 0), Transparency = 1 })
		sign(label, i == 1 and "YOU" or (otherLabel or "THEM"), Color3.new(1, 1, 1))
	end
	-- the judge's bench (back, high) with a gavel
	local bench = part(folder, { Size = Vector3.new(14, 6, 4), CFrame = CFrame.new(o + Vector3.new(0, 3.5, -16)), Color = Color3.fromRGB(90, 55, 30), Material = Enum.Material.Wood })
	local judgeSpot = CFrame.lookAt(o + Vector3.new(0, 6.5, -18.5), o + Vector3.new(0, 6.5, 0))
	local gavel = part(folder, { Size = Vector3.new(1.4, 0.6, 0.6), CFrame = bench.CFrame * CFrame.new(2.5, 3.4, 1), Color = Color3.fromRGB(110, 70, 35), Material = Enum.Material.Wood })
	-- crowd benches in front (the audience sits between the stage and the camera's wide shot)
	local crowdSpots = {}
	for k = 1, 5 do
		local x = -16 + (k - 1) * 8
		part(folder, { Size = Vector3.new(6, 1, 2), CFrame = CFrame.new(o + Vector3.new(x, 1.5, 16)), Color = Color3.fromRGB(80, 50, 35), Material = Enum.Material.Wood })
		table.insert(crowdSpots, CFrame.lookAt(o + Vector3.new(x, 0.5, 17), o + Vector3.new(x, 0.5, 0)))
	end

	-- actors
	local me = actorFrom(meChar)
	local other = actorFrom(otherChar)
	if not other then
		-- NPC partner: a stand-in made from your own avatar, recoloured so it reads as someone else
		other = actorFrom(meChar, Color3.fromRGB(255, 140, 200))
	end
	place(me, meSpot, folder)
	place(other, otherSpot, folder)
	local judge = actorFrom(meChar, Color3.fromRGB(30, 30, 40))
	if judge then
		place(judge, judgeSpot, folder)
		local head = judge:FindFirstChild("Head") :: BasePart?
		if head then
			-- a big white judge's wig
			part(judge, { Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2, 2.4), CFrame = head.CFrame * CFrame.new(0, 0.5, 0.3), Color = Color3.fromRGB(245, 245, 240), Material = Enum.Material.Fabric })
		end
	end
	local crowd = {}
	for k, spot in ipairs(crowdSpots) do
		local c = actorFrom(k % 2 == 0 and (otherChar or meChar) or meChar, Color3.fromHSV((k * 0.17) % 1, 0.5, 0.9))
		if c then
			place(c, spot * CFrame.new(0, 1, 0), folder)
			table.insert(crowd, c)
		end
	end
	folder.Parent = workspace.CurrentCamera -- client only
	for _, a in ipairs({ me, other, judge }) do
		play(a, "idle", true)
	end
	for _, c in ipairs(crowd) do
		play(c, "idle", true)
	end

	local stage = {
		folder = folder,
		me = me,
		other = other,
		judge = judge,
		crowd = crowd,
		gavel = gavel,
		meCF = meSpot,
		otherCF = otherSpot,
		-- establishing wide: from behind the crowd, high
		wideEye = o + Vector3.new(0, 14, 34),
		judgeEye = o + Vector3.new(0, 7, -6),
		judgeAt = o + Vector3.new(0, 9, -18.5),
	}
	function stage.gesture(who: string, name: string)
		play(stage[who], name, false)
	end
	function stage.crowdReact(name: string)
		for _, c in ipairs(stage.crowd) do
			play(c, name, false)
		end
	end
	function stage.bang()
		local g = stage.gavel
		if g and g.Parent then
			local base = g.CFrame
			local t = TweenService:Create(g, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), { CFrame = base * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(25)) })
			t:Play()
		end
	end
	function stage.destroy()
		folder:Destroy()
	end
	return stage
end

-- 1.9.3: shared with BrainEnding (the 0-cell cutscene)
VsStage.actorFrom = actorFrom
VsStage.place = place
VsStage.play = play
local _ = Players
return VsStage

-- Machines (1.9.3, user request + screen recording): the client side of the inventable hotbar items
-- (server: Services/MachineService.lua).
--   🌀 Trace Teleporter: your real character freezes and a glowing ghost appears. Steer the ghost with the
--      normal controls; it leaves a glowing line. Walls say BLOCKED!. UNDO steps back, CANCEL quits, GO
--      sends the path to the server, then you zoom along it with speed streaks and a studs counter.
--   🚀 Jetpack: blast off and glide for a few seconds.
--   🟢 Bounce Pad: the server drops a pad; touching it launches you (machineBounce).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local CM = Config.Machines
local TM = Content.Machines
local player = Players.LocalPlayer
local Machines = {}

local busy = false

local function controls()
	local ok, mod = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
	end)
	return ok and mod or nil
end

local function bigLabel(parent, text: string, y: number, color: Color3?)
	return UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, y),
		Size = UDim2.fromOffset(420, 40),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.FredokaOne,
		TextSize = UI.textSize(28),
		TextColor3 = color or Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.3,
		Parent = parent,
	})
end

---------------------------------------------------------------------
-- 🌀 Trace Teleporter
---------------------------------------------------------------------
local function zoomAlong(root: BasePart, points, onDone)
	local C = CM.teleporter
	local cam = workspace.CurrentCamera
	local gui = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = UI.gui })
	local studsL = bigLabel(gui, "", 70)
	-- speed streaks: a white trail behind you and a wider field of view
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.5, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1.5, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.35
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 230, 120))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = root
	local fov = cam.FieldOfView
	if not UI.reducedMotion() then
		TweenService:Create(cam, TweenInfo.new(0.3), { FieldOfView = math.min(100, fov + 25) }):Play()
	end
	local i, travelled = 1, 0
	local pos = points[1]
	-- unanchored, so the zoom replicates to other players (the client owns its character physics)
	root.Anchored = false
	busy = true
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local move = C.speed * dt
		while move > 0 and i < #points do
			local nextP = points[i + 1]
			local d = (nextP - pos).Magnitude
			if d <= move then
				move -= d
				travelled += d
				pos = nextP
				i += 1
			else
				pos += (nextP - pos).Unit * move
				travelled += move
				move = 0
			end
		end
		local dir = (points[math.min(i + 1, #points)] - pos)
		local look = dir.Magnitude > 0.1 and Vector3.new(dir.X, 0, dir.Z) or root.CFrame.LookVector
		if look.Magnitude < 0.01 then
			look = root.CFrame.LookVector
		end
		root.CFrame = CFrame.lookAt(pos, pos + look.Unit)
		root.AssemblyLinearVelocity = Vector3.zero
		studsL.Text = string.format(TM.Studs, math.floor(travelled))
		if i >= #points then
			conn:Disconnect()
			TweenService:Create(cam, TweenInfo.new(0.3), { FieldOfView = fov }):Play()
			task.delay(0.4, function()
				trail:Destroy()
				a0:Destroy()
				a1:Destroy()
				gui:Destroy()
			end)
			busy = false
			onDone()
		end
	end)
end

local function traceTeleport()
	local C = CM.teleporter
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end
	busy = true -- 1.9.3 audit: set BEFORE the server call, so a double tap can't open two ghosts
	local check = Remote.call("machine_check", { key = "teleporter" })
	if not check.ok or not char.Parent or hum.Health <= 0 then
		busy = false
		if check.msg then
			UI.toast(check.msg, UI.Colors.bad)
		end
		return
	end
	root.Anchored = true -- your real body waits here
	-- the glowing ghost (client only)
	char.Archivable = true
	local ghost = char:Clone()
	char.Archivable = false
	for _, d in ipairs(ghost:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Humanoid") or d:IsA("Sound") or d:IsA("Tool") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Material = Enum.Material.Neon
			d.Color = Color3.fromRGB(255, 225, 120)
			d.Transparency = d.Name == "HumanoidRootPart" and 1 or 0.45
		elseif d:IsA("Decal") then
			d.Transparency = 1
		end
	end
	ghost.Parent = workspace.CurrentCamera
	local gRoot = ghost:FindFirstChild("HumanoidRootPart") :: BasePart
	local cam = workspace.CurrentCamera
	cam.CameraSubject = gRoot

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char, ghost, workspace.CurrentCamera }
	local points = { root.Position }
	local lineParts = {}
	local lineFolder = Instance.new("Folder")
	lineFolder.Name = "TracePath"
	lineFolder.Parent = workspace.CurrentCamera
	local pos = root.Position
	local total = 0

	-- the UI: TAP GO, studs, BLOCKED!, and the UNDO / CANCEL / GO buttons
	local gui = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = UI.gui })
	local hint = bigLabel(gui, TM.TapGo, 70)
	local studsL = bigLabel(gui, string.format(TM.Studs, 0), 104, Color3.fromRGB(255, 230, 120))
	local blockedL = bigLabel(gui, TM.Blocked, 140, Color3.fromRGB(255, 90, 90))
	blockedL.Visible = false
	local row = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(330, 64), BackgroundTransparency = 1, Parent = gui }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10) }),
	})
	local finished = false
	local stepConn
	local function cleanup()
		finished = true
		if stepConn then
			stepConn:Disconnect()
		end
		ghost:Destroy()
		lineFolder:Destroy()
		gui:Destroy()
		if hum.Parent then
			cam.CameraSubject = hum
		end
		busy = false
	end
	local function blocked(text: string)
		blockedL.Text = text
		blockedL.Visible = true
		task.delay(0.6, function()
			if blockedL.Parent then
				blockedL.Visible = false
			end
		end)
	end
	local function addSegment(a: Vector3, b: Vector3)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(120, 255, 140)
		p.Size = Vector3.new(0.35, 0.15, (b - a).Magnitude)
		p.CFrame = CFrame.lookAt((a + b) / 2 - Vector3.new(0, 2.8, 0), b - Vector3.new(0, 2.8, 0))
		p.Parent = lineFolder
		table.insert(lineParts, p)
	end
	UI.button(row, TM.Undo, function()
		-- step back about 15 studs
		local back = 0
		while #points > 1 and back < 15 do
			local last = table.remove(points)
			back += (last - points[#points]).Magnitude
			local seg = table.remove(lineParts)
			if seg then
				seg:Destroy()
			end
		end
		pos = points[#points]
		total = math.max(0, total - back)
		studsL.Text = string.format(TM.Studs, math.floor(total))
	end, { Size = UDim2.fromOffset(100, 56), BackgroundColor3 = Color3.fromRGB(220, 60, 70) })
	UI.button(row, TM.Cancel, function()
		cleanup()
		root.Anchored = false
	end, { Size = UDim2.fromOffset(100, 56), BackgroundColor3 = Color3.fromRGB(110, 110, 125) })
	UI.button(row, TM.Go, function()
		if finished then
			return
		end
		if #points < 2 then
			blocked(TM.NoPath)
			return
		end
		local send = {}
		for _, v in ipairs(points) do
			table.insert(send, { v.X, v.Y, v.Z })
		end
		local r = Remote.call("machine_use", { key = "teleporter", points = send })
		if not r.ok then
			blocked(r.msg or TM.Blocked)
			return
		end
		local path = table.clone(points)
		cleanup()
		zoomAlong(root, path, function()
			root.Anchored = false
		end)
	end, { Size = UDim2.fromOffset(110, 56), BackgroundColor3 = Color3.fromRGB(70, 150, 255) })
	local _ = hint

	local ctl = controls()
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		if not char.Parent or hum.Health <= 0 then
			cleanup()
			return
		end
		local mv = ctl and ctl:GetMoveVector() or Vector3.zero
		if mv.Magnitude < 0.05 then
			return
		end
		local camCF = cam.CFrame
		local fwd = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
		local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
		if fwd.Magnitude < 0.01 then
			return
		end
		local dir = (fwd.Unit * -mv.Z + right.Unit * mv.X)
		if dir.Magnitude < 0.01 then
			return
		end
		dir = dir.Unit
		local stepV = dir * C.ghostSpeed * dt
		local target = pos + stepV
		-- walls
		if workspace:Raycast(pos + Vector3.new(0, 1, 0), stepV + dir * 1.2, params) then
			blocked(TM.Blocked)
			return
		end
		-- ground (follow slopes and stairs; no ground = blocked)
		local ground = workspace:Raycast(target + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), params)
		if not ground then
			blocked(TM.Blocked)
			return
		end
		target = Vector3.new(target.X, ground.Position.Y + 3, target.Z)
		local last = points[#points]
		if total + (target - last).Magnitude > C.maxStuds then
			blocked(TM.TooFar)
			return
		end
		pos = target
		gRoot.Parent:PivotTo(CFrame.lookAt(pos, pos + dir))
		if (pos - last).Magnitude >= C.step and #points < C.maxPoints then
			total += (pos - last).Magnitude
			table.insert(points, pos)
			addSegment(last, pos)
			studsL.Text = string.format(TM.Studs, math.floor(total))
		end
	end)
	ghost:PivotTo(root.CFrame)
end

---------------------------------------------------------------------
-- 🚀 Jetpack
---------------------------------------------------------------------
local function jetpack()
	local C = CM.jetpack
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local r = Remote.call("machine_use", { key = "jetpack" })
	if not r.ok then
		if r.msg then
			UI.toast(r.msg, UI.Colors.bad)
		end
		return
	end
	local att = Instance.new("Attachment")
	att.Parent = root
	local force = Instance.new("VectorForce")
	force.Attachment0 = att
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity * C.lift, 0)
	force.Parent = root
	local fire = Instance.new("ParticleEmitter")
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 80, 40))
	fire.Speed = NumberRange.new(8, 12)
	fire.Lifetime = NumberRange.new(0.2, 0.35)
	fire.Rate = UI.effects() > 0 and 60 or 0
	fire.EmissionDirection = Enum.NormalId.Bottom
	fire.Size = NumberSequence.new(0.8, 0)
	fire.Parent = att
	root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, C.thrust, root.AssemblyLinearVelocity.Z)
	if r.msg then
		UI.toast(r.msg, UI.Colors.good)
	end
	task.delay(C.seconds, function()
		force:Destroy()
		att:Destroy()
	end)
end

---------------------------------------------------------------------
-- hook every machine tool (they arrive in the Backpack from the server)
---------------------------------------------------------------------
local hooked = setmetatable({}, { __mode = "k" })
local function hook(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] or not tool:GetAttribute("Machine") then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		-- 1.9.3 audit: never during a cutscene / conversation (they hide the HUD and hold you still), while
		-- dead, or while something else already holds your character
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if busy or not hum or hum.Health <= 0 or not root or root.Anchored or (UI.gui and not UI.gui.Enabled) then
			return
		end
		local key = tool:GetAttribute("Machine")
		if key == "teleporter" then
			traceTeleport()
		elseif key == "jetpack" then
			jetpack()
		elseif key == "bouncepad" then
			local r = Remote.call("machine_use", { key = "bouncepad" })
			if r.msg then
				UI.toast(r.msg, r.ok and UI.Colors.good or UI.Colors.bad)
			end
		end
	end)
end

local function watch(holder: Instance)
	for _, t in ipairs(holder:GetChildren()) do
		hook(t)
	end
	holder.ChildAdded:Connect(hook)
end
task.spawn(function()
	watch(player:WaitForChild("Backpack"))
	player.CharacterAdded:Connect(function(c)
		watch(c)
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
	end
end)

Remote.on("machineBounce", function(d)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and not root.Anchored then
		root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, tonumber(d.power) or 120, root.AssemblyLinearVelocity.Z)
	end
end)

function Machines.isBusy(): boolean
	return busy
end

return Machines

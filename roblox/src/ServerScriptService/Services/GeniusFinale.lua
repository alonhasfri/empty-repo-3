-- GeniusFinale (1.9.1, big ideas #11): the big finish of a genius branch's story.
-- A real prop appears next to the player for everyone to see, the whole server hears about it,
-- and the player's client plays a short skippable cutscene and the Noble Prize ceremony card.
--   math: a giant board that says SOLVED     physics: a rocket that launches
--   coding: a robot that walks into town     business: your own shop stall (stays while you're here)
--   chess: a championship board vs Grandmaster Checkmate McGee
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Net = require(script.Parent.Net)
local BrainService = require(script.Parent.BrainService)

local GeniusFinale = {}
local CE = Config.GeniusEnd
local TE = Content.GeniusEnd

local folder = Instance.new("Folder")
folder.Name = "GeniusFinales"
folder.Parent = workspace
local shops = {} -- [player] = Model (the business stall stays until they leave)

local function part(parent, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, extra)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	for k, v in pairs(extra or {}) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function sign(p: BasePart, text: string, face: Enum.NormalId?)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 30
	g.LightInfluence = 0
	g.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.TextWrapped = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = text
	l.Parent = g
end

local BUILD = {}

function BUILD.math(m, cf, name)
	local board = part(m, cf * CFrame.new(0, 9, 0), Vector3.new(26, 14, 0.6), Color3.fromRGB(30, 70, 50), Enum.Material.Slate)
	sign(board, string.format(TE.Props.math, name), Enum.NormalId.Back)
	part(m, cf * CFrame.new(0, 1, 0), Vector3.new(28, 2, 2), Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
end

function BUILD.physics(m, cf, _name)
	local base = cf * CFrame.new(0, 0, 0)
	local body = part(m, base * CFrame.new(0, 8, 0), Vector3.new(4, 14, 4), Color3.fromRGB(240, 240, 245), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	body.CFrame = base * CFrame.new(0, 8, 0) * CFrame.Angles(0, 0, math.pi / 2)
	local nose = part(m, base * CFrame.new(0, 16, 0), Vector3.new(4, 4, 4), Color3.fromRGB(220, 50, 50), nil, { Shape = Enum.PartType.Ball })
	local flame = part(m, base * CFrame.new(0, 0.6, 0), Vector3.new(3, 3, 3), Color3.fromRGB(255, 160, 40), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Heat = 20
	fire.Parent = flame
	-- 3, 2, 1… lift off: everything flies up together
	task.delay(CE.LaunchAfter, function()
		for _, p in ipairs({ body, nose, flame }) do
			if p.Parent then
				TweenService:Create(p, TweenInfo.new(CE.LaunchSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = p.CFrame + Vector3.new(0, CE.LaunchHeight, 0) }):Play()
			end
		end
	end)
end

function BUILD.coding(m, cf, name)
	local root = cf * CFrame.new(0, 0, 0)
	local parts = {
		part(m, root * CFrame.new(0, 3.2, 0), Vector3.new(3, 3.4, 2), Color3.fromRGB(150, 160, 175), Enum.Material.Metal),
		part(m, root * CFrame.new(0, 5.8, 0), Vector3.new(2.2, 1.8, 1.8), Color3.fromRGB(170, 180, 195), Enum.Material.Metal),
		part(m, root * CFrame.new(-0.5, 6, -0.92), Vector3.new(0.4, 0.4, 0.1), Color3.fromRGB(60, 220, 255), Enum.Material.Neon),
		part(m, root * CFrame.new(0.5, 6, -0.92), Vector3.new(0.4, 0.4, 0.1), Color3.fromRGB(60, 220, 255), Enum.Material.Neon),
		part(m, root * CFrame.new(-0.8, 0.8, 0), Vector3.new(1, 1.6, 1), Color3.fromRGB(90, 95, 110), Enum.Material.Metal),
		part(m, root * CFrame.new(0.8, 0.8, 0), Vector3.new(1, 1.6, 1), Color3.fromRGB(90, 95, 110), Enum.Material.Metal),
	}
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.MaxDistance = 120
	bb.Parent = parts[2]
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(120, 230, 255)
	l.Text = string.format(TE.Props.coding, name)
	l.Parent = bb
	-- the robot walks off into town and back
	for _, p in ipairs(parts) do
		local there = p.CFrame * CFrame.new(0, 0, -CE.RobotWalk)
		TweenService:Create(p, TweenInfo.new(CE.RobotSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), { CFrame = there }):Play()
	end
end

function BUILD.business(m, cf, name)
	part(m, cf * CFrame.new(0, 1.5, 0), Vector3.new(12, 3, 4), Color3.fromRGB(150, 105, 65), Enum.Material.WoodPlanks)
	for _, x in ipairs({ -5.6, 5.6 }) do
		part(m, cf * CFrame.new(x, 4.5, 1.6), Vector3.new(0.5, 9, 0.5), Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
	end
	for i = 0, 5 do
		part(m, cf * CFrame.new(-5 + i * 2, 9.2, 0), Vector3.new(2, 0.4, 6), i % 2 == 0 and Color3.fromRGB(230, 60, 60) or Color3.fromRGB(250, 250, 250))
	end
	local s = part(m, cf * CFrame.new(0, 10.6, -1), Vector3.new(12, 2.4, 0.3), Color3.fromRGB(40, 40, 60))
	sign(s, string.format(TE.Props.business, name))
end

function BUILD.chess(m, cf, name)
	for x = 0, 7 do
		for z = 0, 7 do
			local dark = (x + z) % 2 == 1
			part(m, cf * CFrame.new(-7 + x * 2, 0.2, -7 + z * 2), Vector3.new(2, 0.3, 2), dark and Color3.fromRGB(70, 60, 50) or Color3.fromRGB(235, 225, 205))
		end
	end
	part(m, cf * CFrame.new(-3, 2, 7), Vector3.new(1.4, 3.4, 1.4), Color3.fromRGB(245, 245, 245), nil, { Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(-3, 2, 7) * CFrame.Angles(0, 0, math.pi / 2) })
	part(m, cf * CFrame.new(3, 2, -7), Vector3.new(1.4, 3.4, 1.4), Color3.fromRGB(30, 30, 35), nil, { Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(3, 2, -7) * CFrame.Angles(0, 0, math.pi / 2) })
	local s = part(m, cf * CFrame.new(0, 7, 9), Vector3.new(16, 3, 0.3), Color3.fromRGB(30, 30, 40))
	sign(s, string.format(TE.Props.chess, name), Enum.NormalId.Back)
end

function GeniusFinale.play(player: Player, branch: string)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not BUILD[branch] then
		return
	end
	-- 14 studs in front of the player, on the ground, facing them
	local ahead = root.CFrame * CFrame.new(0, -3, -14)
	local cf = CFrame.lookAt(ahead.Position, Vector3.new(root.Position.X, ahead.Position.Y, root.Position.Z))
	local m = Instance.new("Model")
	m.Name = "Finale_" .. branch .. "_" .. player.UserId
	pcall(BUILD[branch], m, cf, player.DisplayName)
	m.Parent = folder
	if branch == "business" then
		if shops[player] then
			shops[player]:Destroy()
		end
		shops[player] = m
	else
		task.delay(CE.PropSeconds, function()
			m:Destroy()
		end)
	end
	-- the whole server hears about it
	local field = TE.Fields[branch] or branch
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			BrainService.toast(p, string.format(TE.Announce, player.DisplayName, field), "LevelUp")
		end
	end
	Net.send(player, "geniusFinale", { branch = branch, x = cf.Position.X, y = cf.Position.Y, z = cf.Position.Z })
end

Players.PlayerRemoving:Connect(function(p)
	if shops[p] then
		shops[p]:Destroy()
		shops[p] = nil
	end
end)

return GeniusFinale

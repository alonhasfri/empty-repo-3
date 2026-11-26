-- DumbWorldService (1.9.1, big ideas #13): fake shortcuts. Glowing "SHORTCUT?!" holes on the Lose side.
-- Only really dumb brains (Lose path below Config.DumbWorld.FakeBelowCells, or animals) fall for them:
-- they land in a giant ball pit with an EXIT door back to the Brainrot Mall. Smart players just get a joke.
-- (The real dumb-only shortcut is still WorldService's crawl hole in the plaza.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local Rooms = require(script.Parent.Rooms)

local DumbWorldService = {}
local DW = Config.DumbWorld
local TD = Content.DumbWorld
local S = Config.Map.Scale

local folder = Instance.new("Folder")
folder.Name = "DumbWorld"
folder.Parent = workspace

local pitCF: CFrame? = nil

local function part(cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, extra)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	for k, v in pairs(extra or {}) do
		p[k] = v
	end
	p.Parent = folder
	return p
end

local function label(p: BasePart, text: string, offsetY: number)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 40)
	bb.StudsOffset = Vector3.new(0, offsetY, 0)
	bb.MaxDistance = 120
	bb.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(255, 230, 80)
	l.TextStrokeTransparency = 0.3
	l.Text = text
	l.Parent = bb
end

-- the ball pit: a closed room high up, full of colourful balls, with an exit door
local function buildPit()
	local cf = CFrame.new(DW.PitOrigin)
	local w, d, h = DW.PitSize.X, DW.PitSize.Z, DW.PitSize.Y
	part(cf * CFrame.new(0, -0.5, 0), Vector3.new(w, 1, d), Color3.fromRGB(80, 160, 255))
	part(cf * CFrame.new(0, h + 0.5, 0), Vector3.new(w, 1, d), Color3.fromRGB(255, 240, 120))
	part(cf * CFrame.new(0, h / 2, d / 2 + 0.5), Vector3.new(w + 2, h, 1), Color3.fromRGB(255, 120, 200))
	part(cf * CFrame.new(0, h / 2, -d / 2 - 0.5), Vector3.new(w + 2, h, 1), Color3.fromRGB(120, 230, 160))
	part(cf * CFrame.new(w / 2 + 0.5, h / 2, 0), Vector3.new(1, h, d), Color3.fromRGB(255, 180, 80))
	part(cf * CFrame.new(-w / 2 - 0.5, h / 2, 0), Vector3.new(1, h, d), Color3.fromRGB(180, 140, 255))
	local lamp = part(cf * CFrame.new(0, h - 0.3, 0), Vector3.new(4, 0.3, 4), Color3.new(1, 1, 1), Enum.Material.Neon, { CanCollide = false })
	local pl = Instance.new("PointLight")
	pl.Range = math.max(w, d)
	pl.Brightness = 1.5
	pl.Parent = lamp
	local colors = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(70, 170, 255), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 220, 120), Color3.fromRGB(220, 120, 255) }
	for i = 1, DW.Balls do
		local x = (math.random() - 0.5) * (w - 4)
		local z = (math.random() - 0.5) * (d - 8) + 2
		part(cf * CFrame.new(x, 1 + math.random() * 2, z), Vector3.new(1.6, 1.6, 1.6), colors[(i % #colors) + 1], nil, { Shape = Enum.PartType.Ball, Anchored = false, CanTouch = false })
	end
	local door = part(cf * CFrame.new(0, 3.5, -d / 2 + 0.2), Vector3.new(5, 7, 0.4), Color3.fromRGB(40, 200, 90), Enum.Material.Neon, { CanCollide = false })
	label(door, TD.Exit, 5)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = TD.ExitAction
	pp.ObjectText = TD.Exit
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.Parent = door
	pp.Triggered:Connect(function(player)
		WorldService.teleport(player, "lose")
	end)
	pitCF = cf
end

local function fooled(player: Player): boolean
	local d = DataService.get(player)
	if not d then
		return false
	end
	return Rooms.isAnimal(player) or (d.path == "Lose" and (d.cells or math.huge) < DW.FakeBelowCells)
end

local function hole(design: Vector3)
	local pos = Vector3.new(design.X * S, design.Y, design.Z * S)
	local h = part(CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.4, 8, 8), Color3.fromRGB(40, 10, 50), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	h.Name = "FakeShortcut"
	label(h, TD.Sign, 3)
	local cooldown = {}
	h.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or (cooldown[player] or 0) > os.clock() then
			return
		end
		cooldown[player] = os.clock() + 4
		if fooled(player) and pitCF then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				Rooms.standUp(hum)
				char:PivotTo(pitCF * CFrame.new(0, 4, -DW.PitSize.Z / 2 + 6))
				BrainService.toast(player, TD.Fell[math.random(1, #TD.Fell)], "CartoonBoing")
			end
		else
			BrainService.toast(player, TD.Smart)
		end
	end)
end

task.spawn(function()
	task.wait(5)
	pcall(buildPit)
	for _, pos in ipairs(DW.Holes) do
		pcall(hole, pos)
	end
end)

return DumbWorldService

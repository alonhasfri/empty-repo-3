-- WorldService: builds the TOWN with code.
--   Center: Town Plaza (spawn, the two doors, fountain, Perfectly Average guy)
--   West (Lose side): Brainrot Mall, Microwave Diner, Wall Alley, Supermarket, houses
--   East (Gain side): School, University, Jack B Cinema, Beethoven's Café, Hospital,
--                     Office Tower, Job Center, Courthouse, Science Lab, Park
-- Every decorative part is tagged "Styled" so each player's screen restyles it to
-- match their own brain (genius, average, cash grab, nonsense).

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local Config = require(ReplicatedStorage.Shared.Config)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local FriendService = require(script.Parent.FriendService)
local Props = require(script.Parent.Props)
local Rooms = require(script.Parent.Rooms)

local WorldService = {}

local mapFolder = Instance.new("Folder")
mapFolder.Name = "Town"
mapFolder.Parent = workspace

WorldService.Spots = { lobby = Vector3.new(0, 3, 30) }
WorldService.Places = {} -- taxi list: { key, name, path }
WorldService.Workplaces = {} -- [placeKey] = Vector3
WorldService.Zones = {}
WorldService.onStation = nil
WorldService.onCashGrab = nil
WorldService.onAverageGuy = nil
WorldService.onWork = nil

---------------------------------------------------------------------
-- Building helpers
---------------------------------------------------------------------
-- The whole town is designed at full size, then shrunk horizontally by S
-- so it's compact and quick to walk around. Heights are not shrunk.
local S = 0.55
WorldService.Scale = S
local function sp(v: Vector3): Vector3
	return Vector3.new(v.X * S, v.Y, v.Z * S)
end
local function scf(cf: CFrame): CFrame
	return CFrame.new(sp(cf.Position)) * cf.Rotation
end
WorldService.sp = sp

local SKIP = { Parent = true, ClassName = true, NoScale = true, NoScaleSize = true }
local function part(props, role: string?)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		if not SKIP[k] then
			p[k] = v
		end
	end
	if not props.NoScale then
		p.CFrame = scf(p.CFrame)
		if not props.NoScaleSize then
			if p.Shape == Enum.PartType.Cylinder then
				p.Size = Vector3.new(p.Size.X, p.Size.Y * S, p.Size.Z * S)
			elseif p.Shape ~= Enum.PartType.Ball then
				p.Size = Vector3.new(p.Size.X * S, p.Size.Y, p.Size.Z * S)
			end
		end
	end
	if role then
		p:SetAttribute("Role", role)
		CollectionService:AddTag(p, "Styled")
	end
	p.Parent = props.Parent or mapFolder
	return p
end

local function tagSign(label: TextLabel, text: string)
	label.Text = text
	label:SetAttribute("BaseText", text)
	CollectionService:AddTag(label, "Sign")
end

-- Billboard sign (sized in studs so it shrinks with distance)
local function sign(adornee: BasePart, text: string, offsetY: number, width: number?, height: number?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new((width or 260) / 20, 0, (height or 70) / 20, 0)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 150
	gui.LightInfluence = 0
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	tagSign(label, text)
	return label
end

-- Painted sign on a part's front face
local function surfaceSign(board: BasePart, text: string)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.LightInfluence = 0.3
	sg.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Parent = sg
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.1, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.Parent = label
	tagSign(label, text)
	return label
end

local function prompt(parentPart: BasePart, actionText: string, objectText: string, distance: number?)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = actionText
	pp.ObjectText = objectText
	pp.HoldDuration = 0
	pp.MaxActivationDistance = distance or 12
	pp.RequiresLineOfSight = false
	pp.Parent = parentPart
	return pp
end

-- A building with walls, a door gap facing local -Z, windows, roof and a painted sign.
-- Returns the building CFrame (origin at ground center, front = -Z) and size.
local function building(o)
	local cf = CFrame.new(o.center) * CFrame.Angles(0, o.yaw or 0, 0)
	local w, h, d = o.size.X, o.size.Y, o.size.Z
	local t = 1.2
	local wall = o.wall or Color3.fromRGB(220, 210, 190)
	local model = Instance.new("Model")
	model.Name = o.name
	model.Parent = mapFolder
	local function p(localCf, size, color, role, extra)
		local props = { CFrame = cf * localCf, Size = size, Color = color, Parent = model }
		for k, v in pairs(extra or {}) do
			props[k] = v
		end
		return part(props, role)
	end
	local doorW, doorH = o.door or 16, 13
	-- floor + walls
	local wm = { Material = o.wallMaterial or Enum.Material.Plaster }
	p(CFrame.new(0, 0.25, 0), Vector3.new(w, 0.5, d), o.floor or Color3.fromRGB(200, 195, 185), "floor", { Material = o.floorMaterial or Enum.Material.CeramicTiles })
	p(CFrame.new(0, h / 2, d / 2 - t / 2), Vector3.new(w, h, t), wall, "wall", wm)
	p(CFrame.new(-w / 2 + t / 2, h / 2, 0), Vector3.new(t, h, d), wall, "wall", wm)
	p(CFrame.new(w / 2 - t / 2, h / 2, 0), Vector3.new(t, h, d), wall, "wall", wm)
	local side = (w - doorW) / 2
	p(CFrame.new(-(doorW / 2 + side / 2), h / 2, -d / 2 + t / 2), Vector3.new(side, h, t), wall, "wall", wm)
	p(CFrame.new(doorW / 2 + side / 2, h / 2, -d / 2 + t / 2), Vector3.new(side, h, t), wall, "wall", wm)
	p(CFrame.new(0, doorH + (h - doorH) / 2, -d / 2 + t / 2), Vector3.new(doorW, h - doorH, t), wall, "wall", wm)
	-- base trim along the bottom of the front
	p(CFrame.new(0, 0.9, -d / 2 - 0.1), Vector3.new(w + 0.4, 1.8, 0.4), Color3.fromRGB(110, 105, 100), "trim", { Material = Enum.Material.Concrete })
	-- 1.7: wall depth: corner pilasters that stick out of the front, so walls aren't flat
	for _, sx in ipairs({ -1, 1 }) do
		p(CFrame.new(sx * (w / 2 - 1), h / 2, -d / 2 - 0.6), Vector3.new(2.4, h, 1.2), Color3.fromRGB(235, 232, 225), "trim", { Material = Enum.Material.Concrete })
	end
	-- windows (glass strips, outside)
	local glass = { Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false }
	local floors = math.max(1, math.floor(h / 14))
	for f = 1, floors do
		local y = (f - 1) * 14 + 8
		if y < h - 3 then
			p(CFrame.new(-(doorW / 2 + side / 2), y, -d / 2 - 0.05), Vector3.new(side * 0.75, 4, 0.2), Color3.fromRGB(150, 200, 230), nil, glass)
			p(CFrame.new(doorW / 2 + side / 2, y, -d / 2 - 0.05), Vector3.new(side * 0.75, 4, 0.2), Color3.fromRGB(150, 200, 230), nil, glass)
			-- 1.7: window sills (depth under each front window)
			for _, sx in ipairs({ -1, 1 }) do
				p(CFrame.new(sx * (doorW / 2 + side / 2), y - 2.3, -d / 2 - 0.5), Vector3.new(side * 0.8, 0.5, 1), Color3.fromRGB(235, 232, 225), "trim", { Material = Enum.Material.Concrete })
			end
			p(CFrame.new(-w / 2 - 0.05, y, 0), Vector3.new(0.2, 4, d * 0.7), Color3.fromRGB(150, 200, 230), nil, glass)
			p(CFrame.new(w / 2 + 0.05, y, 0), Vector3.new(0.2, 4, d * 0.7), Color3.fromRGB(150, 200, 230), nil, glass)
		end
	end
	-- roof with a little trim
	p(CFrame.new(0, h + 0.6, 0), Vector3.new(w + 3, 1.2, d + 3), o.roof or Color3.fromRGB(90, 80, 75), "trim", { Material = Enum.Material.RoofShingles })
	-- roof edge / parapet
	p(CFrame.new(0, h + 1.6, -d / 2 - 1.2), Vector3.new(w + 3, 1, 0.6), Color3.fromRGB(235, 235, 230), "trim", { Material = Enum.Material.Concrete })
	-- awning + painted sign above the door
	p(CFrame.new(0, doorH + 0.4, -d / 2 - 2), Vector3.new(doorW + 6, 0.6, 4), o.accent or Color3.fromRGB(200, 60, 60), "accent", { Material = Enum.Material.Fabric })
	-- glass doors (1.5: buildings with no use get a solid, locked door instead)
	if o.closed then
		local shut = p(CFrame.new(0, doorH / 2, -d / 2 + 0.6), Vector3.new(doorW - 1, doorH - 0.5, 0.6), Color3.fromRGB(120, 80, 55), "trim", { Material = Enum.Material.WoodPlanks })
		shut.Name = "ClosedDoor"
		sign(shut, Content.Rooms.Closed, 2, 200, 30)
	else
		p(CFrame.new(0, doorH / 2, -d / 2 + 0.6), Vector3.new(doorW - 1, doorH - 0.5, 0.2), Color3.fromRGB(170, 210, 230), nil, { Material = Enum.Material.Glass, Transparency = 0.6, CanCollide = false })
	end
	local boardH = math.max(4, math.min(8, h - doorH - 1.5))
	local board = p(CFrame.new(0, doorH + 1.2 + boardH / 2, -d / 2 - 0.4), Vector3.new(math.min(w - 6, 46), boardH, 0.5), o.signColor or Color3.fromRGB(40, 40, 60), "accent")
	surfaceSign(board, o.sign or o.name)
	-- interior light
	local lamp = p(CFrame.new(0, h - 0.6, 0), Vector3.new(4, 0.4, 4), Color3.fromRGB(255, 250, 230), nil, { Material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Range = math.min(60, math.max(w, d))
	light.Brightness = 1.2
	light.Parent = lamp
	return cf, o.size, model
end

local function addPlace(key: string, name: string, cf: CFrame, size: Vector3, path: string?)
	local spot = (cf * CFrame.new(0, 3, -size.Z / 2 - 10)).Position
	WorldService.Spots[key] = spot
	table.insert(WorldService.Places, { key = key, name = name, path = path })
	-- 1.5: furniture, people and things to do inside (only buildings that have a use)
	Rooms.furnish(key, scf(cf), Vector3.new(size.X * S / 2, size.Y, size.Z * S / 2), key)
end
-- 1.5 exit doors: step outside the front of the building
Rooms.onLeave = function(player, key)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		Rooms.standUp(hum)
	end
	WorldService.teleport(player, key)
end
Rooms.onJobs = function(player)
	if WorldService.onStation then
		WorldService.onStation(player, "jobs", "Gain")
	end
end

-- A kiosk/counter station inside a building, facing the building's front (-Z)
local STATION_PROPS = {
	clickbait = function(cf)
		return Props.newsstand(cf)
	end,
	steal = function(cf)
		Props.arcade(cf * CFrame.new(-2.2, 0, 0), "STEAL A ???")
		return Props.arcade(cf * CFrame.new(2.2, 0, 0), "STEAL A ROCK")
	end,
	comments = function(cf)
		return Props.desk(cf, true)
	end,
	scroller = function(cf)
		return Props.phoneTable(cf)
	end,
	shop = function(cf)
		return Props.shopCounter(cf)
	end,
	library = function(cf)
		Props.bookshelf(cf * CFrame.new(-4, 0, 3), 6)
		Props.bookshelf(cf * CFrame.new(4, 0, 3), 6)
		return Props.desk(cf * CFrame.new(0, 0, -1), false)
	end,
	theater = function(cf)
		return Props.ticketBooth(cf)
	end,
	gate = function(cf)
		return Props.examDesk(cf)
	end,
	jobs = function(cf)
		return Props.bulletinBoard(cf)
	end,
	coffee = function(cf)
		return Props.cafeCounter(cf)
	end,
	nap = function(cf)
		return Props.bench(cf)
	end,
	pigeons = function(cf)
		return Props.birdFeeder(cf)
	end,
	lab = function(cf)
		return Props.labBench(cf)
	end,
}

local function station(key: string, path: string, title: string, desc: string, cf: CFrame, color: Color3)
	local real = scf(cf)
	local builder = STATION_PROPS[key]
	if builder then
		builder(real)
	end
	-- invisible spot the prompt sits on, in front of the prop
	local counter = part({ Name = "Station_" .. key, CFrame = real * CFrame.new(0, 3, -2.5), Size = Vector3.new(4, 4, 1), Transparency = 1, CanCollide = false, NoScale = true })
	local board = sign(counter, title, 6.5, 300, 46)
	board.TextColor3 = Color3.fromRGB(255, 240, 160)
	sign(counter, desc, 4.6, 260, 28)
	local _ = color
	local pp = prompt(counter, "Open", title, 12)
	pp.Triggered:Connect(function(player)
		if WorldService.onStation then
			WorldService.onStation(player, key, path)
		end
	end)
	return counter
end

-- Where a job is done
local WORK_PROPS = {
	supermarket = function(cf)
		return Props.shopCounter(cf)
	end,
	hospital = function(cf)
		Props.hospitalBed(cf * CFrame.new(7, 0, 2))
		return Props.desk(cf, true)
	end,
	lab = function(cf)
		return Props.labBench(cf)
	end,
	street = function(cf)
		return Props.cleaningCart(cf)
	end,
}

local function workplace(placeKey: string, label: string, cf: CFrame)
	local real = scf(cf)
	local builder = WORK_PROPS[placeKey]
	if builder then
		builder(real)
	else
		Props.desk(real, true)
	end
	local desk = part({ Name = "Work_" .. placeKey, CFrame = real * CFrame.new(0, 3, -2.5), Size = Vector3.new(4, 4, 1), Transparency = 1, CanCollide = false, NoScale = true })
	sign(desk, "💼 " .. label, 5, 220, 34)
	WorldService.Workplaces[placeKey] = desk.Position
	prompt(desk, "Work", label, 12).Triggered:Connect(function(player)
		if WorldService.onWork then
			WorldService.onWork(player, placeKey)
		end
	end)
	return desk
end

local function tree(pos: Vector3, scale: number?)
	local s = scale or 1
	pos = sp(pos)
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(pos + Vector3.new(0, 5 * s, 0)) * CFrame.Angles(0, 0, math.rad(90)), Size = Vector3.new(10, 1.8, 1.8) * s, Color = Color3.fromRGB(105, 75, 50), Material = Enum.Material.Wood, NoScale = true }, "nature")
	local greens = { Color3.fromRGB(60, 130, 60), Color3.fromRGB(75, 145, 65), Color3.fromRGB(55, 120, 55) }
	for i, off in ipairs({ Vector3.new(0, 11, 0), Vector3.new(2.5, 9.5, 1.5), Vector3.new(-2.2, 9.8, -1.6), Vector3.new(0.5, 13, -0.5) }) do
		local size = (i == 1 and 9 or 6.5) * s
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), Position = pos + off * s, Color = greens[(i % #greens) + 1], Material = Enum.Material.LeafyGrass, NoScale = true }, "nature")
	end
end

local function streetLight(pos: Vector3)
	part({ Name = "LampPole", Size = Vector3.new(0.6, 14, 0.6), Position = pos + Vector3.new(0, 7, 0), Color = Color3.fromRGB(50, 50, 55), Material = Enum.Material.Metal, NoScaleSize = true }, "trim")
	part({ Name = "LampArm", Size = Vector3.new(0.3, 0.3, 2.4), Position = pos + Vector3.new(0, 13.8, -0.9), Color = Color3.fromRGB(50, 50, 55), Material = Enum.Material.Metal, NoScaleSize = true }, "trim")
	local head = part({ Name = "LampHead", Size = Vector3.new(1.4, 0.5, 1.4), Position = pos + Vector3.new(0, 13.6, -1.8), Color = Color3.fromRGB(255, 240, 200), Material = Enum.Material.Neon, NoScaleSize = true })
	local l = Instance.new("PointLight")
	l.Range = 26
	l.Brightness = 0.8
	l.Color = Color3.fromRGB(255, 230, 180)
	l.Parent = head
end

local function car(cf: CFrame)
	Props.car(scf(cf))
end

local function bench(cf: CFrame)
	Props.bench(scf(cf))
end

local function house(center: Vector3, yaw: number)
	local colors = { Color3.fromRGB(240, 220, 190), Color3.fromRGB(200, 225, 240), Color3.fromRGB(240, 200, 200), Color3.fromRGB(210, 235, 200) }
	building({
		name = "House",
		center = center,
		yaw = yaw,
		size = Vector3.new(30, 16, 26),
		wall = colors[math.random(1, #colors)],
		wallMaterial = math.random() < 0.5 and Enum.Material.Brick or Enum.Material.Plaster,
		floorMaterial = Enum.Material.WoodPlanks,
		roof = Color3.fromRGB(150, 70, 60),
		accent = Color3.fromRGB(120, 90, 70),
		door = 8,
		sign = "🏠",
		closed = true, -- 1.5: nothing to do in houses, so they stay closed
	})
end

---------------------------------------------------------------------
-- Ground and roads
---------------------------------------------------------------------
local function buildGround()
	local terrain = workspace.Terrain
	local ok = pcall(function()
		terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(940 * S + 40, 8, 940 * S + 40), Enum.Material.Grass)
		terrain:FillBlock(CFrame.new(0, -9, 0), Vector3.new(940 * S + 40, 4, 940 * S + 40), Enum.Material.Rock)
		if not terrain:FindFirstChildOfClass("Clouds") then
			local clouds = Instance.new("Clouds")
			clouds.Cover = 0.55
			clouds.Density = 0.6
			clouds.Parent = terrain
		end
	end)
	if not ok then
		part({ Name = "Grass", Size = Vector3.new(920, 2, 920), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(90, 170, 80), Material = Enum.Material.Grass }, "floor")
	end
	local asphalt = Color3.fromRGB(55, 55, 60)
	local function road(center: Vector3, length: number, alongX: boolean)
		local size = alongX and Vector3.new(length, 0.2, 28) or Vector3.new(28, 0.2, length)
		part({ Name = "Road", Size = size, Position = center + Vector3.new(0, 0.1, 0), Color = asphalt, Material = Enum.Material.Asphalt }, "trim")
		-- sidewalks
		local off = 17
		for _, sgn in ipairs({ -1, 1 }) do
			local sw = alongX and Vector3.new(length, 0.5, 6) or Vector3.new(6, 0.5, length)
			local pos = alongX and center + Vector3.new(0, 0.25, sgn * off) or center + Vector3.new(sgn * off, 0.25, 0)
			part({ Name = "Sidewalk", Size = sw, Position = pos, Color = Color3.fromRGB(190, 190, 185), Material = Enum.Material.Concrete }, "trim")
		end
		-- dashed center line
		local n = math.floor(length / 20)
		for i = 0, n - 1 do
			local offAlong = -length / 2 + 10 + i * 20
			local pos = alongX and center + Vector3.new(offAlong, 0.25, 0) or center + Vector3.new(0, 0.25, offAlong)
			local dash = alongX and Vector3.new(8, 0.1, 0.6) or Vector3.new(0.6, 0.1, 8)
			part({ Name = "Line", Size = dash, Position = pos, Color = Color3.fromRGB(240, 210, 60), CanCollide = false })
		end
		-- street lights every 60 studs
		for i = 0, math.floor(length / 60) do
			local a = -length / 2 + i * 60
			local pos = alongX and center + Vector3.new(a, 0, 21) or center + Vector3.new(21, 0, a)
			streetLight(pos)
		end
	end
	-- main avenue (west-east) and main street (north-south), split around the plaza
	road(Vector3.new(-237, 0, 0), 346, true)
	road(Vector3.new(237, 0, 0), 346, true)
	road(Vector3.new(0, 0, -237), 346, false)
	road(Vector3.new(0, 0, 237), 346, false)
	-- ring roads
	road(Vector3.new(-200, 0, -200), 400, false)
	road(Vector3.new(200, 0, -200), 400, false)
	road(Vector3.new(-200, 0, 200), 400, false)
	road(Vector3.new(200, 0, 200), 400, false)
	-- parked cars
	for i = 1, 14 do
		local x = math.random(-380, 380)
		if math.abs(x) > 80 then
			car(CFrame.new(x, 0, 9 * (i % 2 == 0 and 1 or -1)) * CFrame.Angles(0, math.rad(90), 0))
		end
	end
	for i = 1, 10 do
		local z = math.random(-380, 380)
		if math.abs(z) > 80 then
			car(CFrame.new(9 * (i % 2 == 0 and 1 or -1), 0, z))
		end
	end
end

---------------------------------------------------------------------
-- Town Plaza (lobby)
---------------------------------------------------------------------
local doorSigns = {}

local function buildDoor(path: string, x: number, color: Color3, title: string)
	part({ Name = path .. "PillarL", Size = Vector3.new(3, 24, 3), Position = Vector3.new(x, 12, -15), Color = color }, "accent")
	part({ Name = path .. "PillarR", Size = Vector3.new(3, 24, 3), Position = Vector3.new(x, 12, 15), Color = color }, "accent")
	local beam = part({ Name = path .. "Beam", Size = Vector3.new(4, 5, 33), Position = Vector3.new(x, 26, 0), Color = color }, "accent")
	local portal = part({
		Name = path .. "Portal",
		Size = Vector3.new(1, 22, 27),
		Position = Vector3.new(x, 11, 0),
		Color = color,
		Transparency = 0.2,
		CanCollide = false,
		Material = Enum.Material.ForceField,
	})
	doorSigns[path] = sign(beam, title, 5.5, 460, 80)
	local pp = prompt(portal, "Enter", title, 20)
	pp.Triggered:Connect(function(player)
		WorldService.enterDoor(player, path)
	end)
end

local function buildPlaza()
	part({ Name = "Plaza", Size = Vector3.new(146, 0.6, 146), Position = Vector3.new(0, 0.3, 0), Color = Color3.fromRGB(205, 200, 190), Material = Enum.Material.Cobblestone }, "floor")
	-- fountain
	part({ Name = "FountainBase", Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Size = Vector3.new(2, 26, 26), Color = Color3.fromRGB(180, 180, 175), Material = Enum.Material.Marble }, "trim")
	part({ Name = "FountainWater", Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Size = Vector3.new(0.4, 23, 23), Color = Color3.fromRGB(80, 170, 230), Material = Enum.Material.Glass, Transparency = 0.2 })
	local statue = part({ Name = "BrainStatue", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 7, 7), Position = Vector3.new(0, 7, 0), Color = Color3.fromRGB(255, 150, 190) }, "accent")
	-- (1.7: the Brain Tower now stands here with its own sign, so the old statue sign is gone)
	local _ = statue
	-- 1.7.2: plaza trees on open ground (the old ±55 corners were inside the Mall, School and Supermarket)
	for _, xz in ipairs({ { -33, -22 }, { 33, -22 }, { -30, 51 }, { 40, 51 } }) do
		tree(Vector3.new(xz[1], 0.6, xz[2]), 0.9)
	end
	bench(CFrame.new(-25, 0.6, 40))
	bench(CFrame.new(25, 0.6, 40))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = sp(Vector3.new(0, 0.6, 30))
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.Marble
	spawn.Color = Color3.fromRGB(230, 230, 235)
	spawn.Parent = mapFolder

	-- The two doors are on the SCREEN now (Hud door picker), not in the world.
	local _ = buildDoor

	local welcome = part({ Name = "WelcomeSign", Size = Vector3.new(60, 10, 1), Position = Vector3.new(0, 14, -60), Color = Color3.fromRGB(35, 30, 60) }, "accent")
	surfaceSign(welcome, "Are you smart enough to get smarter, or dumb enough to get dumber?")
	part({ Name = "WelcomePostL", Size = Vector3.new(1, 14, 1), Position = Vector3.new(-28, 7, -60), Color = Color3.fromRGB(60, 60, 60) }, "trim")
	part({ Name = "WelcomePostR", Size = Vector3.new(1, 14, 1), Position = Vector3.new(28, 7, -60), Color = Color3.fromRGB(60, 60, 60) }, "trim")

	-- Perfectly Average guy
	local guy
	local model = FriendService.npc("PerfectlyAverageGuy")
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		model:PivotTo(CFrame.new(sp(Vector3.new(30, 3.8, -35))) * CFrame.Angles(0, math.pi, 0))
		model.Parent = mapFolder
		guy = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	end
	if not guy then
		guy = part({ Name = "PerfectlyAverageGuy", Size = Vector3.new(2, 5, 1.5), Position = Vector3.new(30, 3.1, -35), Color = Color3.fromRGB(150, 150, 150) }, "accent")
	end
	-- (no name sign: he's a secret. Just a plain grey person you might walk past.)
	prompt(guy, "Talk", "Someone").Triggered:Connect(function(player)
		if WorldService.onAverageGuy then
			WorldService.onAverageGuy(player)
		end
	end)

	-- Cash-grab BUY NOW stands on the east side (Gain path joke)
	for i, btn in ipairs(Content.CashGrabButtons) do
		local base = CFrame.new(sp(Vector3.new(85 + i * 22, 0.6, 30)))
		local colors = { Color3.fromRGB(230, 40, 120), Color3.fromRGB(30, 160, 230), Color3.fromRGB(250, 170, 20) }
		local machine = Props.vending(base, "BUY NOW!!", colors[i])
		for _, d in ipairs(machine:GetDescendants()) do
			if d:IsA("BasePart") then
				CollectionService:AddTag(d, "CashGrabOnly")
			end
		end
		local stand = part({ Name = "CashGrab_" .. btn.key, CFrame = base * CFrame.new(0, 3, -2.5), Size = Vector3.new(4, 4, 1), Transparency = 1, CanCollide = false, NoScale = true })
		CollectionService:AddTag(stand, "CashGrabOnly")
		sign(stand, btn.label, 6, 260, 50)
		local disclaimer = sign(stand, "(This button does nothing.)", 1.5, 200, 24)
		CollectionService:AddTag(disclaimer, "Disclaimer")
		prompt(stand, "BUY NOW", btn.label).Triggered:Connect(function(player)
			if WorldService.onCashGrab then
				WorldService.onCashGrab(player, btn)
			end
		end)
	end
	table.insert(WorldService.Places, 1, { key = "lobby", name = "🏙 Town Plaza" })
end

---------------------------------------------------------------------
-- West: the Lose side
---------------------------------------------------------------------
local FACE_SOUTH = math.pi -- front faces +Z (for buildings north of the avenue)
local FACE_NORTH = 0 -- front faces -Z (for buildings south of the avenue)

local function buildLoseSide()
	-- Brainrot Mall
	local cf, size = building({
		name = "BrainrotMall",
		center = Vector3.new(-100, 0.6, -100),
		yaw = FACE_SOUTH,
		size = Vector3.new(150, 26, 120),
		wall = Color3.fromRGB(230, 205, 220),
		wallMaterial = Enum.Material.Concrete,
		roof = Color3.fromRGB(120, 40, 120),
		accent = Color3.fromRGB(255, 220, 0),
		floor = Color3.fromRGB(240, 230, 250),
		signColor = Color3.fromRGB(150, 0, 120),
		door = 22,
		sign = "🛍 BRAINROT MALL",
	})
	addPlace("lose", "🛍 Brainrot Mall", cf, size, "Lose")
	station("clickbait", "Lose", "📰 Clickbait Newsstand", "Click the bait. Don't read!", cf * CFrame.new(-48, 0.5, -20), Color3.fromRGB(255, 80, 80))
	station("steal", "Lose", "🎮 Steal A Arcade", "Pick the dumbest game", cf * CFrame.new(-16, 0.5, -20), Color3.fromRGB(255, 200, 40))
	station("comments", "Lose", "💬 Internet Café", "Post the dumbest comment", cf * CFrame.new(16, 0.5, -20), Color3.fromRGB(80, 200, 255))
	station("scroller", "Lose", "📱 Phone Store", "Swipe. Swipe. Swipe.", cf * CFrame.new(48, 0.5, -20), Color3.fromRGB(140, 80, 255))
	station("shop", "Lose", "🛒 Cash Grab Store", "Joke passes (always optional)", cf * CFrame.new(0, 0.5, 30), Color3.fromRGB(60, 220, 120))

	-- Microwave Diner: stand inside to lose cells slowly
	local dcf, dsize = building({
		name = "MicrowaveDiner",
		center = Vector3.new(-300, 0.6, -100),
		yaw = FACE_SOUTH,
		size = Vector3.new(80, 20, 64),
		wall = Color3.fromRGB(240, 238, 232),
		wallMaterial = Enum.Material.Plaster,
		roof = Color3.fromRGB(200, 40, 40),
		accent = Color3.fromRGB(200, 40, 40),
		sign = "🍿 MICROWAVE DINER",
	})
	addPlace("diner", "🍿 Microwave Diner", dcf, dsize, "Lose")
	local mwModel, mwLabel = Props.microwave(scf(dcf * CFrame.new(0, 0.5, 18)), 2.2)
	WorldService.microwaveLabel = mwLabel
	local microwave = part({ Name = "MicrowaveSpot", CFrame = scf(dcf * CFrame.new(0, 0.5, 18)) * CFrame.new(0, 6, 0), Size = Vector3.new(1, 1, 1), Transparency = 1, CanCollide = false, NoScale = true })
	sign(microwave, "🍿 Stand here and watch it spin", 6, 300, 34)
	local _ = mwModel
	-- diner tables
	for i = -1, 1 do
		Props.desk(scf(dcf * CFrame.new(i * 22, 0.5, -6)), false)
	end
	WorldService.Zones.microwave = { cframe = dcf * CFrame.new(0, 0.5, 0), size = Vector3.new(76, 18, 60) }

	-- Wall Alley: stare at the wall
	local wallPart = part({ Name = "StaringWall", Size = Vector3.new(60, 24, 3), Position = Vector3.new(-300, 12, 150), Color = Color3.fromRGB(150, 150, 150), Material = Enum.Material.Brick }, "wall")
	sign(wallPart, "🧱 Staring Contest With a Wall", 14, 340, 40)
	WorldService.Zones.wall = { cframe = CFrame.new(-300, 1, 128), size = Vector3.new(60, 14, 40) }
	WorldService.Spots.wall = Vector3.new(-300, 3, 110)
	table.insert(WorldService.Places, { key = "wall", name = "🧱 Wall Alley", path = "Lose" })
	house(Vector3.new(-340, 0.6, 70), FACE_NORTH)
	house(Vector3.new(-260, 0.6, 70), FACE_NORTH)

	-- Supermarket (cashier job)
	local smcf, ssize = building({
		name = "Supermarket",
		center = Vector3.new(-100, 0.6, 100),
		yaw = FACE_NORTH,
		size = Vector3.new(120, 22, 90),
		wall = Color3.fromRGB(235, 232, 222),
		wallMaterial = Enum.Material.Concrete,
		roof = Color3.fromRGB(40, 140, 70),
		accent = Color3.fromRGB(40, 140, 70),
		signColor = Color3.fromRGB(30, 110, 50),
		door = 20,
		sign = "🛒 SUPERMARKET",
	})
	addPlace("supermarket", "🛒 Supermarket", smcf, ssize, "Gain")
	workplace("supermarket", "Cashier Register", smcf * CFrame.new(0, 0.5, -20))
	for i = -2, 2 do
		Props.shopCounter(scf(smcf * CFrame.new(i * 22, 0.5, 18)))
	end

	-- houses
	for _, c in ipairs({ Vector3.new(-100, 0.6, -300), Vector3.new(-300, 0.6, -300) }) do
		house(c + Vector3.new(-40, 0, 0), FACE_SOUTH)
		house(c + Vector3.new(40, 0, 0), FACE_SOUTH)
		tree(c + Vector3.new(0, 0.6, 30))
	end
	for _, c in ipairs({ Vector3.new(-100, 0.6, 300), Vector3.new(-300, 0.6, 300) }) do
		house(c + Vector3.new(-40, 0, 0), FACE_NORTH)
		house(c + Vector3.new(40, 0, 0), FACE_NORTH)
		tree(c + Vector3.new(0, 0.6, -30))
	end
end

---------------------------------------------------------------------
-- East: the Gain side
---------------------------------------------------------------------
local function buildGainSide()
	-- School: library + teacher/janitor jobs + shop
	local cf, size = building({
		name = "School",
		center = Vector3.new(100, 0.6, -100),
		yaw = FACE_SOUTH,
		size = Vector3.new(140, 30, 120),
		wall = Color3.fromRGB(165, 85, 65),
		wallMaterial = Enum.Material.Brick,
		roof = Color3.fromRGB(80, 60, 60),
		accent = Color3.fromRGB(60, 90, 160),
		signColor = Color3.fromRGB(40, 60, 120),
		door = 20,
		sign = "🏫 BRAINVILLE SCHOOL",
	})
	addPlace("gain", "🏫 School", cf, size, "Gain")
	station("library", "Gain", "📚 School Library", "Read for 10 seconds, then answer", cf * CFrame.new(-40, 0.5, 20), Color3.fromRGB(120, 80, 50))
	station("shop", "Gain", "🏛 School Shop", "Fair passes", cf * CFrame.new(40, 0.5, 20), Color3.fromRGB(60, 200, 160))
	workplace("school", "Teachers' Lounge / Janitor Closet", cf * CFrame.new(0, 0.5, -15))
	for i = -2, 2 do
		Props.bookshelf(scf(cf * CFrame.new(-40 + i * 12, 0.5, 48)), 6)
	end

	-- University: the Skill Gate + professor job
	local ucf, usize = building({
		name = "University",
		center = Vector3.new(300, 0.6, -100),
		yaw = FACE_SOUTH,
		size = Vector3.new(120, 36, 110),
		wall = Color3.fromRGB(225, 218, 200),
		wallMaterial = Enum.Material.Marble,
		roof = Color3.fromRGB(60, 70, 90),
		accent = Color3.fromRGB(150, 30, 40),
		signColor = Color3.fromRGB(110, 20, 30),
		door = 22,
		sign = "🎓 BRAINVILLE UNIVERSITY",
	})
	addPlace("university", "🎓 University", ucf, usize, "Gain")
	station("gate", "Gain", "🚧 Exam Hall: The Skill Gate", "Prove YOU are smart", ucf * CFrame.new(0, 0.5, 25), Color3.fromRGB(240, 200, 60))
	workplace("university", "Professor's Office", ucf * CFrame.new(-40, 0.5, -10))
	for i = -2, 2 do
		part({ Name = "Column", CFrame = ucf * CFrame.new(i * 12, 12, -usize.Z / 2 - 6), Size = Vector3.new(3, 24, 3), Color = Color3.fromRGB(240, 238, 230), Material = Enum.Material.Marble }, "trim")
	end

	-- Jack B Cinema and Beethoven's Café
	local ccf, csize = building({
		name = "JackBCinema",
		center = Vector3.new(70, 0.6, 100),
		yaw = FACE_NORTH,
		size = Vector3.new(90, 26, 76),
		wall = Color3.fromRGB(120, 45, 45),
		wallMaterial = Enum.Material.Brick,
		roof = Color3.fromRGB(30, 20, 25),
		accent = Color3.fromRGB(220, 30, 30),
		signColor = Color3.fromRGB(180, 20, 20),
		door = 20,
		sign = "🎬 JACK B CINEMA",
	})
	addPlace("cinema", "🎬 Jack B Cinema", ccf, csize, "Gain")
	station("theater", "Gain", "🎬 Now Showing: Fun Facts", "Watch, then answer", ccf * CFrame.new(0, 0.5, 0), Color3.fromRGB(200, 40, 40))
	part({ Name = "Screen", CFrame = ccf * CFrame.new(0, 13, 36), Size = Vector3.new(60, 18, 0.5), Color = Color3.fromRGB(240, 240, 240) }, "accent")

	local kcf, ksize = building({
		name = "Cafe",
		center = Vector3.new(160, 0.6, 100),
		yaw = FACE_NORTH,
		size = Vector3.new(50, 18, 46),
		wall = Color3.fromRGB(150, 105, 70),
		wallMaterial = Enum.Material.WoodPlanks,
		roof = Color3.fromRGB(70, 45, 30),
		accent = Color3.fromRGB(220, 190, 140),
		door = 12,
		sign = "☕ BEETHOVEN'S CAFÉ",
	})
	addPlace("cafe", "☕ Beethoven's Café", kcf, ksize, "Gain")
	station("coffee", "Gain", "☕ Count 60 Beans", "Exactly 60. Not 59.", kcf * CFrame.new(0, 0.5, 8), Color3.fromRGB(110, 70, 40))

	-- Hospital: doctor job
	local hcf, hsize = building({
		name = "Hospital",
		center = Vector3.new(300, 0.6, 100),
		yaw = FACE_NORTH,
		size = Vector3.new(120, 40, 100),
		wall = Color3.fromRGB(240, 243, 245),
		wallMaterial = Enum.Material.Plaster,
		roof = Color3.fromRGB(180, 190, 200),
		accent = Color3.fromRGB(220, 40, 40),
		signColor = Color3.fromRGB(200, 30, 30),
		door = 22,
		sign = "🏥 BRAINVILLE HOSPITAL",
	})
	addPlace("hospital", "🏥 Hospital", hcf, hsize, "Gain")
	workplace("hospital", "Doctor's Office", hcf * CFrame.new(0, 0.5, -10))
	for i = -1, 1 do
		Props.hospitalBed(scf(hcf * CFrame.new(-35 + i * 16, 0.5, 30)))
	end

	-- Office Tower + Job Center
	local ocf, osize = building({
		name = "OfficeTower",
		center = Vector3.new(80, 0.6, -300),
		yaw = FACE_SOUTH,
		size = Vector3.new(70, 70, 70),
		wall = Color3.fromRGB(95, 125, 155),
		wallMaterial = Enum.Material.Glass,
		roof = Color3.fromRGB(60, 70, 80),
		accent = Color3.fromRGB(40, 60, 90),
		door = 16,
		sign = "🏢 OFFICE TOWER",
	})
	addPlace("office", "🏢 Office Tower", ocf, osize, "Gain")
	workplace("office", "Office Desk", ocf * CFrame.new(0, 0.5, 0))

	local jcf, jsize = building({
		name = "JobCenter",
		center = Vector3.new(160, 0.6, -300),
		yaw = FACE_SOUTH,
		size = Vector3.new(50, 20, 46),
		wall = Color3.fromRGB(225, 210, 160),
		wallMaterial = Enum.Material.Plaster,
		roof = Color3.fromRGB(70, 110, 70),
		accent = Color3.fromRGB(60, 160, 90),
		door = 12,
		sign = "💼 JOB CENTER",
	})
	addPlace("jobcenter", "💼 Job Center", jcf, jsize, "Gain")
	station("jobs", "Gain", "💼 Job Board", "Get a job", jcf * CFrame.new(0, 0.5, 6), Color3.fromRGB(60, 160, 90))

	-- Courthouse: lawyer job
	local tcf, tsize = building({
		name = "Courthouse",
		center = Vector3.new(300, 0.6, -300),
		yaw = FACE_SOUTH,
		size = Vector3.new(110, 34, 90),
		wall = Color3.fromRGB(230, 225, 210),
		wallMaterial = Enum.Material.Marble,
		roof = Color3.fromRGB(110, 100, 90),
		accent = Color3.fromRGB(90, 70, 50),
		door = 20,
		sign = "⚖️ COURTHOUSE",
	})
	addPlace("courthouse", "⚖️ Courthouse", tcf, tsize, "Gain")
	workplace("courthouse", "Lawyer's Desk", tcf * CFrame.new(0, 0.5, 0))
	for i = -3, 3 do
		part({ Name = "Column", CFrame = tcf * CFrame.new(i * 12, 12, -tsize.Z / 2 - 6), Size = Vector3.new(3, 24, 3), Color = Color3.fromRGB(240, 238, 230), Material = Enum.Material.Marble }, "trim")
	end

	-- Science Lab: scientist job
	local lcf, lsize = building({
		name = "ScienceLab",
		center = Vector3.new(300, 0.6, 300),
		yaw = FACE_NORTH,
		size = Vector3.new(110, 30, 90),
		wall = Color3.fromRGB(225, 235, 240),
		wallMaterial = Enum.Material.Concrete,
		roof = Color3.fromRGB(60, 80, 110),
		accent = Color3.fromRGB(60, 200, 220),
		signColor = Color3.fromRGB(20, 90, 120),
		door = 20,
		sign = "🔬 SCIENCE LAB",
	})
	addPlace("lab", "🔬 Science Lab", lcf, lsize, "Gain")
	workplace("lab", "Lab Bench", lcf * CFrame.new(0, 0.5, 0))
	station("lab", "Gain", "🔬 Major Projects", "Invent something for the world", lcf * CFrame.new(-30, 0.5, -10), Color3.fromRGB(40, 170, 200))
	for i = -1, 1 do
		Props.labBench(scf(lcf * CFrame.new(i * 22, 0.5, 30)))
	end

	-- Park: nap bench, pigeons, trees, pond
	local parkCenter = Vector3.new(100, 0.6, 300)
	part({ Name = "ParkPath", Size = Vector3.new(120, 0.3, 10), Position = parkCenter + Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(200, 180, 140), Material = Enum.Material.Sand }, "trim")
	pcall(function()
		workspace.Terrain:FillCylinder(CFrame.new(sp(parkCenter + Vector3.new(30, -1.6, 40))), 3, 20 * S, Enum.Material.Water)
	end)
	for i = 1, 8 do
		tree(parkCenter + Vector3.new(math.random(-70, 70), 0, math.random(-70, 70)), 0.8 + math.random() * 0.4)
	end
	local napBench = CFrame.new(parkCenter + Vector3.new(-30, 0, -25))
	bench(napBench)
	station("nap", "Gain", "😴 Edison's Nap Bench", "Wake up when the key drops", napBench * CFrame.new(0, 0, 6), Color3.fromRGB(90, 90, 160))
	station("pigeons", "Gain", "🐦 Tesla's Pigeons", "Feed the pigeons", CFrame.new(parkCenter + Vector3.new(-30, 0, 30)), Color3.fromRGB(150, 150, 150))
	WorldService.Spots.park = parkCenter + Vector3.new(0, 3, -60)
	table.insert(WorldService.Places, { key = "park", name = "🌳 Brainville Park", path = "Gain" })

	-- Street sweeper workplace: a cleaning cart on Main Street
	workplace("street", "Street Cleaning Cart", CFrame.new(18, 0.6, -120))
	WorldService.Spots.street = Vector3.new(10, 3, -110)
	table.insert(WorldService.Places, { key = "street", name = "🧹 Main Street", path = "Gain" })
end

---------------------------------------------------------------------
-- Doors, teleporting, zones
---------------------------------------------------------------------
function WorldService.teleport(player: Player, where: string)
	local char = player.Character
	local spot = WorldService.Spots[where]
	if char and spot then
		char:PivotTo(CFrame.new(sp(spot) + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))))
	end
end

function WorldService.enterDoor(player: Player, path: string)
	local data = DataService.get(player)
	if not data then
		return
	end
	if data.dead then
		Net.send(player, "deathScreen", {})
		return
	end
	if data.path == nil then
		BrainService.startPath(player, path)
		BrainService.narrate(player, path == "Lose" and "choseLose" or "choseGain")
		WorldService.teleport(player, string.lower(path))
	elseif data.path == path then
		WorldService.teleport(player, string.lower(path))
	else
		Net.send(player, "confirmSwitch", { path = path })
	end
end

function WorldService.inZone(player: Player, zoneName: string): boolean
	local zone = WorldService.Zones[zoneName]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not zone or not root then
		return false
	end
	local raw = Vector3.new(root.Position.X / S, root.Position.Y, root.Position.Z / S)
	local rel = zone.cframe:PointToObjectSpace(raw)
	local half = zone.size / 2
	return math.abs(rel.X) <= half.X and rel.Y >= -2 and rel.Y <= zone.size.Y and math.abs(rel.Z) <= half.Z
end

-- Places with their real (shrunk) map positions, for the drawn town map
function WorldService.placeList()
	local out = {}
	for _, p in ipairs(WorldService.Places) do
		local spot = WorldService.Spots[p.key]
		if spot then
			local pos = sp(spot)
			table.insert(out, { key = p.key, name = p.name, path = p.path, x = pos.X, z = pos.Z })
		end
	end
	return out, 260 * S + 20
end

function WorldService.near(player: Player, pos: Vector3, radius: number): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - pos).Magnitude <= radius
end

---------------------------------------------------------------------
-- Fun / admin / invention world effects
---------------------------------------------------------------------
function WorldService.swapDoors()
	local a, b = doorSigns.Lose, doorSigns.Gain
	if a and b then
		local ta, tb = a:GetAttribute("BaseText"), b:GetAttribute("BaseText")
		a:SetAttribute("BaseText", tb)
		b:SetAttribute("BaseText", ta)
		a.Text = tb
		b.Text = ta
	end
end

function WorldService.spawnChicken()
	local chicken = part({ Name = "RubberChicken", Size = Vector3.new(2, 3, 2), Position = Vector3.new(math.random(-60, 60), 2.1, math.random(-60, 60)), Color = Color3.fromRGB(255, 230, 40) })
	sign(chicken, "🐔", 3, 60, 60)
	Debris:AddItem(chicken, 300)
end

function WorldService.spawnRubberDuck()
	local duck = part({ Name = "GiantRubberDuck", Size = Vector3.new(12, 12, 12), Position = Vector3.new(0, 7, 55), Color = Color3.fromRGB(255, 220, 0), Shape = Enum.PartType.Ball })
	sign(duck, "🦆 The Rubber Duck (secret invention)\nExplain your problem to it.", 9, 340, 60)
	prompt(duck, "Talk", "Rubber Duck").Triggered:Connect(function(player)
		BrainService.say(player, "🦆 *quack* (You explained your problem out loud and suddenly understood it. That's rubber duck debugging!)")
	end)
	return duck
end

local function rain(center: Vector3, radius: number, seconds: number, color: Color3, label: string?)
	task.spawn(function()
		local t = os.clock()
		while os.clock() - t < seconds do
			for _ = 1, 5 do
				local b = Instance.new("Part")
				b.Name = "RainItem"
				b.Shape = Enum.PartType.Ball
				b.Size = Vector3.new(2, 2, 2)
				b.Color = color
				b.Material = Enum.Material.SmoothPlastic
				b.CanCollide = true
				b.Position = center + Vector3.new(math.random(-radius, radius), 70, math.random(-radius, radius))
				if label then
					local g = Instance.new("BillboardGui")
					g.Size = UDim2.new(2.5, 0, 2.5, 0)
					local l = Instance.new("TextLabel")
					l.Size = UDim2.fromScale(1, 1)
					l.BackgroundTransparency = 1
					l.TextScaled = true
					l.Text = label
					l.Parent = g
					g.Parent = b
				end
				b.Parent = workspace
				Debris:AddItem(b, 8)
			end
			task.wait(0.5)
		end
	end)
end

function WorldService.brainRain(seconds: number, center: Vector3?)
	rain(center or Vector3.zero, center and 30 or 70, seconds, Color3.fromRGB(255, 150, 190), "🧠")
end

function WorldService.pigeonBurst(origin: Vector3)
	for _ = 1, 12 do
		local p = Instance.new("Part")
		p.Name = "Pigeon"
		p.Size = Vector3.new(1, 1, 1.5)
		p.Color = Color3.fromRGB(140, 140, 150)
		p.CanCollide = false
		p.Position = origin + Vector3.new(0, 3, 0)
		p.AssemblyLinearVelocity = Vector3.new(math.random(-40, 40), math.random(40, 70), math.random(-40, 40))
		local g = Instance.new("BillboardGui")
		g.Size = UDim2.new(2, 0, 2, 0)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Text = "🐦"
		l.Parent = g
		g.Parent = p
		p.Parent = workspace
		Debris:AddItem(p, 6)
	end
end

local banner = nil
function WorldService.setBanner(text: string, color: Color3)
	if not banner then
		banner = part({ Name = "MayorBanner", Size = Vector3.new(40, 7, 0.6), Position = Vector3.new(0, 26, -60), Color = color }, "accent")
		banner:SetAttribute("BannerText", text)
		surfaceSign(banner, text)
	end
	banner.Color = color
	local label = banner:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
	label.Text = text
	label:SetAttribute("BaseText", text)
end

local function buildLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ShadowSoftness = 0.25
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.35
		bloom.Size = 24
		bloom.Threshold = 0.95
		bloom.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("SunRaysEffect") then
		local rays = Instance.new("SunRaysEffect")
		rays.Intensity = 0.06
		rays.Spread = 0.6
		rays.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.SunAngularSize = 14
		sky.Parent = Lighting
	end
end

---------------------------------------------------------------------
-- 1.7 map polish: one big landmark, district gates with a guide, streets that end
-- at something, a dumb-only shortcut, and a phone speed pass.
-- Landmarks never move between looks (only their paint changes), so players never get lost.
---------------------------------------------------------------------
local function buildPolish()
	local CM = Content.Map
	-- The Brain Tower: rises out of the fountain, seen from every street
	local H = Config.Map.LandmarkHeight
	part({ Name = "BrainTowerColumn", Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(0, 10 + (H - 14) / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Size = Vector3.new(H - 14, 5, 5), Color = Color3.fromRGB(240, 235, 225), Material = Enum.Material.Marble, NoScaleSize = true }, "trim")
	local top = part({ Name = "BrainTowerTop", Shape = Enum.PartType.Ball, Size = Vector3.new(16, 16, 16), Position = Vector3.new(0, H, 0), Color = Color3.fromRGB(255, 140, 185), Material = Enum.Material.SmoothPlastic, NoScaleSize = true }, "accent")
	local glow = Instance.new("PointLight")
	glow.Range = 40
	glow.Brightness = 1.5
	glow.Color = Color3.fromRGB(255, 170, 200)
	glow.Parent = top
	sign(top, CM.Tower, 12, 320, 50).Parent.MaxDistance = 2000

	-- District gates on the main avenue, each with its own color, sign and a guide
	for _, g in ipairs(CM.Gates) do
		local x = g.x
		local color = g.color
		for _, z in ipairs({ -23, 23 }) do
			part({ Name = "GatePost", Size = Vector3.new(3, 22, 3), Position = Vector3.new(x, 11, z), Color = color, Material = Enum.Material.Concrete }, "accent")
		end
		local beam = part({ Name = "GateBeam", Size = Vector3.new(4, 4, 50), Position = Vector3.new(x, 23, 0), Color = color, Material = Enum.Material.Concrete }, "accent")
		sign(beam, g.name, 5, 320, 46)
		local npc = FriendService.npc(g.guide, nil, color, Color3.fromRGB(60, 60, 70))
		local root
		if npc then
			for _, d in ipairs(npc:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			npc:PivotTo(CFrame.new(sp(Vector3.new(x, 3.8, 30))) * CFrame.Angles(0, x < 0 and -math.pi / 2 or math.pi / 2, 0))
			npc.Parent = mapFolder
			root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
		end
		if not root then
			root = part({ Name = g.guide, Size = Vector3.new(2, 5, 1.5), Position = Vector3.new(x, 3.1, 30), Color = color }, "accent")
		end
		sign(root, g.guide, 4, 200, 28)
		prompt(root, CM.Talk, g.guide).Triggered:Connect(function(player)
			BrainService.toast(player, g.tip)
		end)
	end

	-- Every street ends at something: a little lookout with trees, a bench and a sign
	for _, e in ipairs(CM.Ends) do
		local c = Vector3.new(e.x, 0.6, e.z)
		part({ Name = "LookoutFloor", Size = Vector3.new(40, 0.6, 40), Position = c, Color = Color3.fromRGB(200, 190, 170), Material = Enum.Material.Cobblestone }, "floor")
		tree(c + Vector3.new(-14, 0, -14), 1)
		tree(c + Vector3.new(14, 0, -14), 1)
		tree(c + Vector3.new(-14, 0, 14), 0.8)
		bench(CFrame.new(c + Vector3.new(0, 0, 8)))
		local board = part({ Name = "LookoutSign", Size = Vector3.new(24, 6, 1), Position = c + Vector3.new(0, 6, -10), Color = Color3.fromRGB(40, 70, 60) }, "accent")
		surfaceSign(board, e.name)
	end

	-- A dumb-only shortcut: a crawl hole in the plaza that only Lose-path brains fit through
	local function shortcut(name: string, from: Vector3, to: string)
		local hole = part({ Name = name, Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(from) * CFrame.Angles(0, 0, math.rad(90)), Size = Vector3.new(0.4, 9, 9), Color = Color3.fromRGB(30, 20, 30), Material = Enum.Material.Neon, CanCollide = false, NoScaleSize = true })
		sign(hole, CM.Hole, 3, 220, 30)
		local cooldown = {}
		hole.Touched:Connect(function(hit)
			local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if not player or (cooldown[player] and os.clock() < cooldown[player]) then
				return
			end
			cooldown[player] = os.clock() + 3
			local data = DataService.get(player)
			if data and data.path == "Lose" then
				BrainService.toast(player, CM.HoleYes)
				WorldService.teleport(player, to)
			else
				BrainService.toast(player, CM.HoleNo)
			end
		end)
	end
	shortcut("DumbHole", Vector3.new(-62, 0.9, -30), "lose") -- on the grass in front of the Mall (z -40 clipped into its front wall)

	-- Phone speed pass: tiny decor casts no shadows and has no collision
	local small, noShadow = Config.Map.SmallDecorSize, Config.Map.NoShadowSize
	local function pass(root: Instance)
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") and not d:IsA("Seat") and not d:IsA("VehicleSeat") and not d:IsA("SpawnLocation") and d.Anchored then
				local s = d.Size
				local maxSide = math.max(s.X, s.Y, s.Z)
				if maxSide <= noShadow then
					d.CastShadow = false
				end
				if maxSide <= small and d:GetAttribute("Role") ~= "floor" and not d:FindFirstChildWhichIsA("ProximityPrompt") then
					d.CanCollide = false
				end
			end
		end
	end
	pass(mapFolder)
	local rooms = workspace:FindFirstChild("Rooms")
	if rooms then
		pass(rooms)
	end
end

function WorldService.build()
	buildLighting()
	buildGround()
	buildPlaza()
	buildLoseSide()
	buildGainSide()
	local ok, err = pcall(buildPolish) -- 1.7 (a problem here must never stop the town from loading)
	if not ok then
		warn("[WorldService] 1.7 map polish failed: " .. tostring(err))
	end
	-- microwave countdown text
	task.spawn(function()
		local seconds = 600
		while true do
			task.wait(1)
			seconds -= 1
			if seconds < 0 then
				seconds = 600
			end
			if WorldService.microwaveLabel then
				WorldService.microwaveLabel.Text = string.format("%d:%02d", seconds // 60, seconds % 60)
			end
		end
	end)
end

return WorldService

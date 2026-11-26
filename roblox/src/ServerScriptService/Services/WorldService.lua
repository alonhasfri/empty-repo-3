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
WorldService.Restaurants = {} -- 1.9.1: restaurant keys that have a Restaurant Worker workplace
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
local S = Config.Map.Scale -- 1.8.8 (user: "everything is too small, especially the roads"): was 0.55
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
			local shape = p:IsA("Part") and p.Shape or Enum.PartType.Block -- WedgeParts have no Shape
			if shape == Enum.PartType.Cylinder then
				p.Size = Vector3.new(p.Size.X, p.Size.Y * S, p.Size.Z * S)
			elseif shape ~= Enum.PartType.Ball then
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
				-- 1.8.2: flower boxes under the front windows (the flowers hide in Low graphics)
				if o.flowers then
					local ST = Config.Map.Street
					p(CFrame.new(sx * (doorW / 2 + side / 2), y - 3.1, -d / 2 - 1.1), Vector3.new(side * 0.6, 1.1, 1.2), ST.Planter, nil, { Name = "FlowerBox", Material = Enum.Material.WoodPlanks, CanCollide = false })
					p(CFrame.new(sx * (doorW / 2 + side / 2), y - 2.3, -d / 2 - 1.1), Vector3.new(side * 0.55, 0.7, 0.9), ST.FlowerColors[math.random(1, #ST.FlowerColors)], nil, { Name = "Flower", Material = Enum.Material.Fabric, CanCollide = false })
				end
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
	-- 1.8.2: white stripes on shop awnings, and a pitched roof on houses
	if o.stripes then
		for i = -1, 1 do
			p(CFrame.new(i * (doorW + 6) / 3, doorH + 0.75, -d / 2 - 2), Vector3.new((doorW + 6) / 6, 0.1, 4), Config.Map.Street.Stripe, nil, { Name = "Decor", Material = Enum.Material.Fabric, CanCollide = false })
		end
	end
	if o.gable then
		local rise = Config.Map.Street.GableRise
		for _, back in ipairs({ false, true }) do
			local wedge = p(CFrame.new(0, h + 1.2 + rise / 2, back and d / 4 + 0.75 or -d / 4 - 0.75) * CFrame.Angles(0, back and math.pi or 0, 0), Vector3.new(w + 3, rise, d / 2 + 1.5), o.roof or Color3.fromRGB(150, 70, 60), "trim", { ClassName = "WedgePart", Material = Enum.Material.RoofShingles })
			wedge.Name = "Gable"
		end
	end
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
	Rooms.furnish(key, scf(cf), Vector3.new(size.X * S / 2, size.Y, size.Z * S / 2), key, name, path)
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
	if Props.tree(pos, s) then -- 1.9.1: a real tree model when ServerStorage > Props has one
		return
	end
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(pos + Vector3.new(0, 5 * s, 0)) * CFrame.Angles(0, 0, math.rad(90)), Size = Vector3.new(10, 1.8, 1.8) * s, Color = Color3.fromRGB(105, 75, 50), Material = Enum.Material.Wood, NoScale = true }, "nature")
	local greens = { Color3.fromRGB(60, 130, 60), Color3.fromRGB(75, 145, 65), Color3.fromRGB(55, 120, 55) }
	for i, off in ipairs({ Vector3.new(0, 11, 0), Vector3.new(2.5, 9.5, 1.5), Vector3.new(-2.2, 9.8, -1.6), Vector3.new(0.5, 13, -0.5) }) do
		local size = (i == 1 and 9 or 6.5) * s
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), Position = pos + off * s, Color = greens[(i % #greens) + 1], Material = Enum.Material.LeafyGrass, NoScale = true }, "nature")
	end
end

local function streetLight(pos: Vector3)
	if Props.streetLamp(sp(pos)) then -- 1.9.1: a real lamp model when ServerStorage > Props has one
		return
	end
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

local function house(center: Vector3, yaw: number, dlcKey: string?)
	local colors = { Color3.fromRGB(240, 220, 190), Color3.fromRGB(200, 225, 240), Color3.fromRGB(240, 200, 200), Color3.fromRGB(210, 235, 200) }
	local hcf, hsize = building({
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
		gable = true,
		flowers = true,
	})
	-- 1.8 Life Pack: some houses hide a Life Pack building. Everyone sees the same plain house;
	-- the knock prompt opens it for owners, or the honest pass card (and a free preview) for everyone else.
	if dlcKey then
		station(dlcKey, "Any", Content.LifePackPlaces.DoorTitle, Content.LifePackPlaces.DoorDesc, hcf * CFrame.new(0, 0.5, -hsize.Z / 2 - 3), Color3.fromRGB(150, 70, 60))
	end
end

---------------------------------------------------------------------
-- Ground and roads
---------------------------------------------------------------------
local function buildGround()
	local terrain = workspace.Terrain
	local ok = pcall(function()
		terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(940 * S + 40, 8, 940 * S + 40), Enum.Material.Grass)
		terrain:FillBlock(CFrame.new(0, -9, 0), Vector3.new(940 * S + 40, 4, 940 * S + 40), Enum.Material.Rock)
		-- 1.7.3 (user feedback "the grass looks uncanny"): a natural bright green instead of the default grey-green
		terrain:SetMaterialColor(Enum.Material.Grass, Config.Map.GrassColor)
		pcall(function()
			terrain.Decoration = false -- 1.8: off: the blades poked up through the pavement slabs
		end)
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
	-- 1.8.8 (user: "cars are inside each other and glitching"): fixed parking bays, evenly spaced,
	-- never on the river bridge or the plaza, instead of random spots that could overlap
	local R = Config.Map.River
	local i = 0
	for a = -380, 380, Config.Map.CarSpacing do
		i += 1
		local side = (i % 2 == 0) and 1 or -1
		if math.abs(a) > 90 and math.abs(a - R.X) > R.Width then
			car(CFrame.new(a, 0, 9 * side) * CFrame.Angles(0, math.rad(90), 0)) -- along the main avenue
		end
		if math.abs(a) > 90 and i % 2 == 0 then
			car(CFrame.new(9 * -side, 0, a)) -- along Main Street, every other bay
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

	-- Cash-grab BUY NOW stands: 1.9.1 moved from the smart side's main street to the front of the
	-- Brainrot Mall (Lose side), where the joke belongs
	for i, btn in ipairs(Content.CashGrabButtons) do
		local M = Config.Map.CashGrabRow
		local base = CFrame.new(sp(Vector3.new(M.X + (i - 1) * M.Step, 0.6, M.Z)))
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
		center = Config.Map.LoseLayout.Mall, -- 1.8 River City
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
		center = Config.Map.LoseLayout.Diner, -- 1.8 River City
		yaw = FACE_NORTH, -- 1.8: south of Main Street now, so it faces north
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
	local WP = Config.Map.LoseLayout.Wall -- 1.8 River City
	local wallPart = part({ Name = "StaringWall", Size = Vector3.new(60, 24, 3), Position = WP + Vector3.new(0, 12, 0), Color = Color3.fromRGB(150, 150, 150), Material = Enum.Material.Brick }, "wall")
	sign(wallPart, "🧱 Staring Contest With a Wall", 14, 340, 40)
	WorldService.Zones.wall = { cframe = CFrame.new(WP + Vector3.new(0, 1, -22)), size = Vector3.new(60, 14, 40) }
	WorldService.Spots.wall = WP + Vector3.new(0, 3, -40)
	table.insert(WorldService.Places, { key = "wall", name = "🧱 Wall Alley", path = "Lose" })
	-- 1.8: the free Phone Shop replaces a locked house (Life Pack plan step 1)
	local pcf, psize = building({
		name = "PhoneShop",
		center = Config.PhoneShop.ShopPos,
		yaw = FACE_NORTH,
		size = Vector3.new(54, 18, 40),
		wall = Color3.fromRGB(245, 245, 250),
		wallMaterial = Enum.Material.SmoothPlastic,
		roof = Color3.fromRGB(80, 60, 200),
		accent = Color3.fromRGB(255, 120, 220),
		door = 14,
		sign = Content.PhoneShop.Sign,
	})
	addPlace("phoneshop", Content.PhoneShop.Title, pcf, psize, nil)
	station("phoneshop", "Any", Content.PhoneShop.StationTitle, Content.PhoneShop.StationDesc, pcf * CFrame.new(0, 0.5, 6), Color3.fromRGB(120, 90, 255))
	-- the scam stall, outside by the door
	station("scam", "Any", Content.PhoneShop.ScamTitle, Content.PhoneShop.ScamDesc, pcf * CFrame.new(22, 0.5, -psize.Z / 2 - 12), Color3.fromRGB(255, 200, 40))
	-- 1.8 (Life Pack plan step 2): free new west-side places replace locked houses
	local function funPlace(key: string, center: Vector3, yaw: number, dims: Vector3, wall: Color3, roof: Color3)
		local T = Content.Fun[key]
		local fcf, fsize = building({
			name = string.gsub(T.Title, "^%S+%s", ""):gsub("%s", ""),
			center = center,
			yaw = yaw,
			size = dims,
			wall = wall,
			wallMaterial = Enum.Material.SmoothPlastic,
			roof = roof,
			accent = roof,
			door = 14,
			sign = T.Sign,
		})
		addPlace(key, T.Title, fcf, fsize, "Lose")
		station(key, "Any", T.Title, T.Desc, fcf * CFrame.new(0, 0.5, 4), roof)
		return fcf, fsize
	end
	WorldService.funPlace = funPlace
	funPlace("slime", Config.Map.LoseLayout.Slime, FACE_NORTH, Vector3.new(44, 16, 36), Color3.fromRGB(190, 255, 200), Color3.fromRGB(60, 220, 120))

	-- Supermarket (cashier job)
	local smcf, ssize = building({
		name = "Supermarket",
		center = Config.Map.LoseLayout.Supermarket, -- 1.8 River City: a Gain job, on the Gain side
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
	-- 1.8: the north-west block becomes the Trampoline Park; one house becomes the Fortune Teller
	local LL = Config.Map.LoseLayout -- 1.8 River City: every Lose place west of the river, in rows
	funPlace("trampoline", LL.Trampoline, FACE_SOUTH, Vector3.new(120, 20, 60), Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 120, 40))
	funPlace("fortune", LL.Fortune, FACE_SOUTH, Vector3.new(36, 16, 30), Color3.fromRGB(80, 50, 120), Color3.fromRGB(170, 80, 255))
	house(LL.Party, FACE_SOUTH, "party")
	-- these plain houses hide Life Pack places (kindergarten, daycare, retirement home, toy store)
	house(LL.Kindergarten, FACE_NORTH, "kindergarten")
	house(LL.Daycare, FACE_NORTH, "daycare")
	house(LL.Retirement, FACE_NORTH, "retirement")
	house(LL.ToyStore, FACE_NORTH, "toystore")
	for _, t in ipairs({ Vector3.new(-290, 0.6, -230), Vector3.new(-290, 0.6, 410), Vector3.new(-370, 0.6, 300) }) do
		tree(t)
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
	workplace("cafe", "Café Kitchen", kcf * CFrame.new(0, 0.5, -10)) -- 1.9: the Chef job

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
	-- 1.8: Life Pack little kids pick their path at the Crossroads Ceremony instead (hook set in Main)
	local blocked = data.path == nil and WorldService.doorGuard and WorldService.doorGuard(player)
	if blocked then
		BrainService.toast(player, blocked)
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

-- 1.9.1: where a job is done. "restaurant" = the nearest restaurant (the Restaurant Worker can work at any of them)
function WorldService.workPos(player: Player?, place: string): Vector3?
	if place ~= "restaurant" then
		return WorldService.Workplaces[place]
	end
	local char = player and player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local best, bestD = nil, math.huge
	for _, key in ipairs(WorldService.Restaurants) do
		local pos = WorldService.Workplaces[key]
		local d = (root and pos) and (root.Position - pos).Magnitude or 0
		if pos and d < bestD then
			best, bestD = pos, d
		end
	end
	return best
end

-- 1.9.1: which restaurant you are standing in (nil = none)
function WorldService.restaurantAt(player: Player): string?
	for _, key in ipairs(WorldService.Restaurants) do
		local pos = WorldService.Workplaces[key]
		if pos and WorldService.near(player, pos, Config.WorkRadius) then
			return key
		end
	end
	return nil
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
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.SunAngularSize = 14
		sky.Parent = Lighting
	end
	-- 1.8.1: a realistic clear sky (image IDs only, copied from a free Creator Store skybox; no model or script kept)
	local CS = Config.Map.Sky
	if CS then
		sky.SkyboxBk, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt = CS.Side, CS.Side, CS.Side, CS.Side
		sky.SkyboxUp, sky.SkyboxDn = CS.Up, CS.Down
		sky.StarCount = CS.Stars
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
		-- 1.9.1 map clean-up: brick posts and a wooden beam that match the town; the district colour is only on the sign
		for _, z in ipairs({ -23, 23 }) do
			part({ Name = "GatePost", Size = Vector3.new(3.4, 20, 3.4), Position = Vector3.new(x, 10, z), Color = Color3.fromRGB(150, 85, 65), Material = Enum.Material.Brick }, "trim")
			part({ Name = "GateCap", Size = Vector3.new(4.2, 1, 4.2), Position = Vector3.new(x, 20.5, z), Color = Color3.fromRGB(225, 215, 195), Material = Enum.Material.Concrete }, "trim")
		end
		local beam = part({ Name = "GateBeam", Size = Vector3.new(2.4, 2.4, 50), Position = Vector3.new(x, 21.5, 0), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.WoodPlanks }, "trim")
		local plate = part({ Name = "GateSign", Size = Vector3.new(1, 4, 24), Position = Vector3.new(x, 18.6, 0), Color = color:Lerp(Color3.fromRGB(40, 40, 50), 0.45), Material = Enum.Material.WoodPlanks }, "trim")
		local _ = beam
		sign(plate, g.name, 3, 280, 40)
		local npc = FriendService.npc(g.guide, nil, color, Color3.fromRGB(60, 60, 70))
		local root
		if npc then
			for _, d in ipairs(npc:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			npc:PivotTo(CFrame.new(sp(Vector3.new(x + (x < 0 and 5 or -5), 3.8, 27))) * CFrame.Angles(0, x < 0 and -math.pi / 2 or math.pi / 2, 0))
			npc.Parent = mapFolder
			root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
		end
		if not root then
			root = part({ Name = g.guide, Size = Vector3.new(2, 5, 1.5), Position = Vector3.new(x, 3.1, 30), Color = color }, "accent")
		end
		sign(root, g.guide, 3.4, 150, 22)
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

-- 1.8 (user: "it shouldn't be grass, it should be roads"): pave the town. One thin concrete layer in a few
-- big rectangles (design coordinates), leaving grass only for the river banks and the park.
local function buildPavement()
	local ST = Config.Map.Style
	local R = Config.Map.River
	local E = 506 -- the edge of town, in design studs
	local bankW = R.Width / 2 + ST.RiverBank
	local west, east = R.X - bankW, R.X + bankW
	local P = Config.Map.Park -- { X1, X2, Z1, Z2 }: the park stays green
	-- Terrain works in 4-stud blocks and can't sit exactly at street level, so lower it to y = -2
	-- inside town and lay solid slabs from -2 to 0 instead (roads and sidewalks sit right on top)
	local edgeReal = E * S + 4
	workspace.Terrain:FillBlock(CFrame.new(0, 1, 0), Vector3.new(edgeReal * 2, 10, edgeReal * 2), Enum.Material.Air)
	local function slab(name: string, x1: number, x2: number, z1: number, z2: number, color: Color3, mat: Enum.Material)
		if x2 > x1 and z2 > z1 then
			part({
				Name = name,
				Size = Vector3.new(x2 - x1, 4.1, z2 - z1), -- from -4 up to 0.1 (just under the roads)
				Position = Vector3.new((x1 + x2) / 2, -1.95, (z1 + z2) / 2),
				Color = color,
				Material = mat,
				CastShadow = false,
			})
		end
	end
	local paved = {
		{ -E, west, -E, E }, -- the whole Lose side
		{ east, E, -E, P.Z1 }, -- Gain side north of the park row
		{ east, P.X1, P.Z1, E }, -- west of the park
		{ P.X2, E, P.Z1, E }, -- east of the park
		{ P.X1, P.X2, P.Z2, E }, -- south of the park
	}
	for _, r in ipairs(paved) do
		slab("Pavement", r[1], r[2], r[3], r[4], ST.Pavement, ST.PavementMaterial)
	end
	-- green on purpose: the park and the two river banks
	slab("ParkGrass", P.X1, P.X2, P.Z1, P.Z2, ST.Grass, Enum.Material.Grass)
	slab("RiverBank", west, R.X - R.Width / 2, -E, E, ST.Grass, Enum.Material.Grass)
	slab("RiverBank", R.X + R.Width / 2, east, -E, E, ST.Grass, Enum.Material.Grass)
end

-- 1.8 (user: "there aren't enough buildings"): fill every free slot along the streets with closed
-- decorative shops and houses, so blocks look full like the style pictures. Only places with a use
-- open; these are scenery. Slots that touch roads, the river, the park, the plaza or any existing
-- building are skipped. Low graphics leaves them (they're cheap boxes), the far skyline is what it trims.
-- 1.9.1 restaurants (big ideas #2). r = an entry of Config.Restaurants.List; Rooms.lua furnishes it
-- (tables, customers, menu board, Eat here). Gain-side restaurants get a Restaurant Worker workplace.
function WorldService.buildRestaurant(r, center: Vector3, yaw: number)
	local RC = Config.Restaurants
	local T = Content.Restaurants.Places[r.key]
	local cf, size = building({
		name = "Restaurant_" .. r.key,
		center = center,
		yaw = yaw,
		size = Vector3.new(RC.W, 18, RC.D),
		wall = r.wall,
		wallMaterial = r.side == "Lose" and Enum.Material.SmoothPlastic or Enum.Material.Brick,
		floorMaterial = Enum.Material.WoodPlanks,
		roof = r.roof,
		accent = r.accent,
		door = 10,
		sign = T.sign,
		flowers = r.side ~= "Lose",
		stripes = true,
	})
	addPlace(r.key, T.name, cf, size, r.side == "Lose" and "Lose" or nil)
	if r.job then
		workplace(r.key, T.work, cf * CFrame.new(0, 0.5, size.Z / 2 - 9))
		table.insert(WorldService.Restaurants, r.key)
		if not WorldService.Workplaces.restaurant then
			WorldService.Workplaces.restaurant = WorldService.Workplaces[r.key] -- fallback for code without a player
		end
	end
end

local function fillTown()
	local CF = Config.Map.Fill
	local R = Config.Map.River
	local P = Config.Map.Park
	local taken = {}
	for _, m in ipairs(mapFolder:GetDescendants()) do
		if m:IsA("Model") and m.Parent == mapFolder then
			local ok, cf, size = pcall(function()
				return m:GetBoundingBox()
			end)
			if ok and size.Magnitude < 400 then
				table.insert(taken, { cf.X - size.X / 2, cf.X + size.X / 2, cf.Z - size.Z / 2, cf.Z + size.Z / 2 })
			end
		end
	end
	local function free(x: number, z: number, w: number, d: number): boolean
		-- design-space rules first
		if math.abs(x) > CF.Edge or math.abs(z) > CF.Edge then
			return false
		end
		if math.abs(x - R.X) < R.Width / 2 + Config.Map.Style.RiverBank + w / 2 + 6 then
			return false
		end
		if x + w / 2 > P.X1 - 6 and x - w / 2 < P.X2 + 6 and z + d / 2 > P.Z1 - 6 and z - d / 2 < P.Z2 + 6 then
			return false
		end
		if math.abs(x) < CF.PlazaClear and math.abs(z) < CF.PlazaClear then
			return false
		end
		for _, rx in ipairs(CF.RoadsX) do -- roads running north–south
			if math.abs(x - rx) < CF.RoadClear + w / 2 then
				return false
			end
		end
		for _, rz in ipairs(CF.RoadsZ) do -- roads running west–east
			if math.abs(z - rz) < CF.RoadClear + d / 2 then
				return false
			end
		end
		-- then real space against everything already built
		local c = sp(Vector3.new(x, 0, z))
		local hw, hd = (w / 2 + CF.Margin) * S, (d / 2 + CF.Margin) * S
		for _, t in ipairs(taken) do
			if c.X + hw > t[1] and c.X - hw < t[2] and c.Z + hd > t[3] and c.Z - hd < t[4] then
				return false
			end
		end
		table.insert(taken, { c.X - hw, c.X + hw, c.Z - hd, c.Z + hd })
		return true
	end
	-- 1.9.1 restaurants (big ideas #2): the free lots nearest the plaza become real restaurants
	local slots = {}
	for x = -CF.Edge, CF.Edge, CF.StepX do
		for z = -CF.Edge, CF.Edge, CF.StepZ do
			table.insert(slots, { x, z })
		end
	end
	table.sort(slots, function(a, b)
		return a[1] * a[1] + a[2] * a[2] < b[1] * b[1] + b[2] * b[2]
	end)
	local RC = Config.Restaurants
	for _, r in ipairs(RC.List) do
		for _, s in ipairs(slots) do
			local x, z = s[1], s[2]
			if (x < R.X) == (r.side == "Lose") and free(x, z, RC.W, RC.D) then
				local okR, errR = pcall(WorldService.buildRestaurant, r, Vector3.new(x, 0.6, z), z > 0 and 0 or math.pi)
				if not okR then
					warn("[World] restaurant " .. r.key .. ": " .. tostring(errR))
				end
				break
			end
		end
	end
	local count = 0
	for x = -CF.Edge, CF.Edge, CF.StepX do
		for z = -CF.Edge, CF.Edge, CF.StepZ do
			if count < CF.Max then
				local lose = x < R.X
				local w, d = CF.W, CF.D
				if free(x, z, w, d) then
					count += 1
					local yaw = z > 0 and FACE_NORTH or FACE_SOUTH -- face the nearest west–east street
					local colors = lose and CF.LoseColors or CF.GainColors
					local col = colors[(count % #colors) + 1]
					-- 1.9.1: a real house / shop model when ServerStorage > Props has one (else the code-built one)
					-- (it stays in the Props folder: the town style system must not repaint real models)
					local real = Props.filler(lose and "Shop" or "House", sp(Vector3.new(x, 0.6, z)), yaw, math.max(w, d) * S)
					if real then
						continue
					end
					building({
						name = lose and "ShopFront" or "House",
						center = Vector3.new(x, 0.6, z),
						yaw = yaw,
						size = Vector3.new(w, lose and 18 or 16, d),
						wall = col,
						wallMaterial = lose and Enum.Material.SmoothPlastic or Enum.Material.Brick,
						floorMaterial = Enum.Material.WoodPlanks,
						roof = lose and Color3.fromRGB(255, 90, 180) or Color3.fromRGB(150, 70, 60),
						accent = lose and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(120, 90, 70),
						door = 8,
						sign = lose and CF.LoseSigns[(count % #CF.LoseSigns) + 1] or "🏠",
						closed = true,
						gable = not lose,
						flowers = true,
						stripes = lose,
					})
				end
			end
		end
	end
	return count
end

-- 1.8.2: street dressing along every sidewalk (globe lamps, planters, benches, trees) and bunting
-- over Main Street, so streets look like the chosen style picture. Skips the plaza and the river.
local function dressStreets(): number
	local ST = Config.Map.Street
	local R = Config.Map.River
	local segs = {
		{ Vector3.new(-237, 0, 0), 346, true },
		{ Vector3.new(237, 0, 0), 346, true },
		{ Vector3.new(0, 0, -237), 346, false },
		{ Vector3.new(0, 0, 237), 346, false },
		{ Vector3.new(-200, 0, -200), 400, false },
		{ Vector3.new(200, 0, -200), 400, false },
		{ Vector3.new(-200, 0, 200), 400, false },
		{ Vector3.new(200, 0, 200), 400, false },
	}
	local n = 0
	local function ok(pos: Vector3): boolean
		if math.abs(pos.X - R.X) < R.Width / 2 + R.Width / 3 then
			return false
		end
		return not (math.abs(pos.X) < ST.SkipPlaza and math.abs(pos.Z) < ST.SkipPlaza)
	end
	for si, s in ipairs(segs) do
		local center, len, alongX = s[1], s[2], s[3]
		local k = 0
		for a = -len / 2 + ST.Step / 2, len / 2 - ST.Step / 2, ST.Step do
			k += 1
			for _, sgn in ipairs({ -1, 1 }) do
				local pos = alongX and center + Vector3.new(a, 0.5, sgn * ST.Offset) or center + Vector3.new(sgn * ST.Offset, 0.5, a)
				if n < ST.Max and ok(pos) then
					n += 1
					local kind = (k + si + (sgn > 0 and 2 or 0)) % 4
					local faceRoad = alongX and (sgn > 0 and 0 or math.pi) or (sgn > 0 and math.pi / 2 or -math.pi / 2)
					if kind == 0 and Props.streetLamp(sp(pos)) then -- luacheck: ignore
						-- 1.9.1: a real lamp model replaces the code-built globe lamp
					elseif kind == 0 then -- globe lamp (like the picture), only the globe glows
						part({ Name = "LampPost", Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Size = Vector3.new(12, 0.7, 0.7), Color = ST.Lamp, Material = Enum.Material.Metal, NoScaleSize = true }, "trim")
						part({ Name = "LampGlobe", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Position = pos + Vector3.new(0, 12.6, 0), Color = ST.Globe, Material = Enum.Material.Neon, CanCollide = false, NoScaleSize = true })
					elseif kind == 1 then -- planter with a round shrub
						part({ Name = "Planter", Size = Vector3.new(4, 1.6, 4), Position = pos + Vector3.new(0, 0.8, 0), Color = ST.Planter, Material = Enum.Material.WoodPlanks, NoScaleSize = true }, "trim")
						part({ Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3.4, 3.4), Position = pos + Vector3.new(0, 2.6, 0), Color = Color3.fromRGB(70, 140, 60), Material = Enum.Material.LeafyGrass, CanCollide = false, NoScaleSize = true }, "nature")
					elseif kind == 2 then -- bench facing the road
						bench(CFrame.new(pos) * CFrame.Angles(0, faceRoad, 0))
					else -- street tree
						tree(pos, 0.7)
					end
				end
			end
			-- bunting across Main Street (the north–south road through the plaza)
			if not alongX and center.X == 0 and k % ST.BuntingEvery == 0 then
				local mid = center + Vector3.new(0, 15, a)
				if ok(mid) then
					part({ Name = "Decor", Size = Vector3.new(2 * ST.Offset, 0.15, 0.15), Position = mid, Color = Color3.fromRGB(240, 240, 240), CanCollide = false, CastShadow = false })
					for f = 1, ST.BuntingFlags do
						local x = -ST.Offset + (f - 0.5) * (2 * ST.Offset / ST.BuntingFlags)
						part({ Name = "Decor", ClassName = "WedgePart", Size = Vector3.new(1.6, 1.8, 0.1), CFrame = CFrame.new(mid + Vector3.new(x, -1, 0)) * CFrame.Angles(math.pi, 0, 0), Color = ST.BuntingColors[(f % #ST.BuntingColors) + 1], Material = Enum.Material.Fabric, CanCollide = false, CastShadow = false, NoScaleSize = true })
					end
				end
			end
		end
	end
	return n
end

-- 1.8 River City: a real Terrain-water river between the Lose side (west) and the plaza (east).
-- Main Street crosses it on a bridge (the road deck + railings); two footbridges and a couple of boats.
local function buildRiver()
	local R = Config.Map.River
	local ST = Config.Map.Style
	local terrain = workspace.Terrain
	local edge = (940 * S + 40) / 2
	local c = sp(Vector3.new(R.X, 0, 0))
	local w = R.Width * S
	-- dig the channel, then fill it with water (top a little below the street)
	terrain:FillBlock(CFrame.new(c.X, -R.Depth / 2, 0), Vector3.new(w, R.Depth + 0.2, edge * 2), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(c.X, -R.Depth / 2 - 0.7, 0), Vector3.new(w, R.Depth - 1.2, edge * 2), Enum.Material.Water)
	pcall(function()
		terrain.WaterColor = ST.Water
		terrain.WaterTransparency = 0.35
		terrain.WaterWaveSize = 0.08
	end)
	local folder = Instance.new("Folder")
	folder.Name = "River"
	local function plank(name: string, pos: Vector3, size: Vector3, color: Color3, mat: Enum.Material?)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Parent = folder
		return p
	end
	-- Main Street bridge: a deck under the road (so it never looks like a road floating on water) + railings
	plank("MainBridgeDeck", Vector3.new(c.X, -0.4, 0), Vector3.new(w + 4, 1, 18), ST.Bridge, ST.BridgeMaterial)
	for _, z in ipairs({ -8.6, 8.6 }) do
		plank("MainBridgeRail", Vector3.new(c.X, 1.6, z), Vector3.new(w + 4, 2.2, 0.5), ST.Railing)
	end
	-- footbridges
	for _, bz in ipairs(R.Bridges) do
		local z = bz * S
		plank("FootBridge", Vector3.new(c.X, 0.4, z), Vector3.new(w + 6, 0.8, 8), ST.Bridge, ST.BridgeMaterial)
		for _, side in ipairs({ -3.8, 3.8 }) do
			plank("FootBridgeRail", Vector3.new(c.X, 1.9, z + side), Vector3.new(w + 6, 2.2, 0.4), ST.Railing)
		end
	end
	-- a couple of little boats (decor; no collision so nobody gets stuck on them)
	for _, bz in ipairs(R.Boats) do
		local z = bz * S
		local hull = plank("BoatHull", Vector3.new(c.X, -1.1, z), Vector3.new(5, 1.6, 12), ST.Boat)
		hull.CanCollide = false
		local trim = plank("BoatTrim", Vector3.new(c.X, -0.2, z), Vector3.new(5.2, 0.3, 12.2), ST.BoatTrim)
		trim.CanCollide = false
	end
	folder.Parent = mapFolder
end

-- 1.8.1 (user: "the city just ends"): a fake, unreachable city beyond the edge wall.
-- Rings of simple houses, then a skyline of tall towers, then hills. Anchored, no collision,
-- no shadows, no queries: cheap on phones. Low graphics hides the far rings (tag "FarSkyline").
local function buildSkyline()
	local CS = Config.Map.Skyline
	local folder = Instance.new("Folder")
	folder.Name = "Skyline"
	local rng = Random.new(42) -- the same skyline every server
	local edge = (940 * S + 40) / 2
	local function block(pos: Vector3, size: Vector3, color: Color3, far: boolean)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Size = size
		p.Position = pos + Vector3.new(0, size.Y / 2, 0)
		p.Color = color
		if far then
			game:GetService("CollectionService"):AddTag(p, "FarSkyline")
		end
		p.Parent = folder
		return p
	end
	-- ground under the fake city, so it never floats over the void
	for _, s in ipairs({ -1, 1 }) do
		block(Vector3.new(s * (edge + CS.Depth / 2), -0.5, 0), Vector3.new(CS.Depth, 1, (edge + CS.Depth) * 2), CS.Ground, false)
		block(Vector3.new(0, -0.5, s * (edge + CS.Depth / 2)), Vector3.new(edge * 2, 1, CS.Depth), CS.Ground, false)
	end
	-- each ring: walk around the square at distance d and drop buildings
	for ring, r in ipairs(CS.Rings) do
		local d = edge + r.at
		local step = r.spacing
		local n = math.floor((d * 2) / step)
		for side = 1, 4 do
			for i = 0, n do
				local t = -d + i * step + rng:NextNumber(-step * 0.2, step * 0.2)
				local x, z
				if side == 1 then
					x, z = t, -d
				elseif side == 2 then
					x, z = t, d
				elseif side == 3 then
					x, z = -d, t
				else
					x, z = d, t
				end
				local h = rng:NextNumber(r.minH, r.maxH)
				local w = rng:NextNumber(r.minW, r.maxW)
				local col = r.colors[rng:NextInteger(1, #r.colors)]
				local b = block(Vector3.new(x, 0, z), Vector3.new(w, h, w), col, ring > 1)
				if r.roofs then
					-- a simple dark roof slab makes rows of houses read as houses
					block(b.Position + Vector3.new(0, h / 2, 0), Vector3.new(w + 1, 1.2, w + 1), CS.Roof, ring > 1)
				end
				if r.windows then
					-- 1.9: window bands on the side facing town (DayNight.lua lights them at night)
					local W = CS.Windows
					local inward = (side == 1 and Vector3.new(0, 0, 1)) or (side == 2 and Vector3.new(0, 0, -1)) or (side == 3 and Vector3.new(1, 0, 0)) or Vector3.new(-1, 0, 0)
					local along = Vector3.new(math.abs(inward.Z), 0, math.abs(inward.X))
					local rows = 0
					local y = W.FirstAt
					while y < h - 6 and rows < W.MaxRows do
						if rng:NextNumber() > W.Skip then
							local frac = rng:NextNumber(0.45, 0.85)
							local shift = rng:NextNumber(-(1 - frac) / 2, (1 - frac) / 2) * w
							local size = along * (w * frac) + Vector3.new(0, W.Height, 0) + inward * 0.4
							size = Vector3.new(math.max(size.X, 0.4), size.Y, math.max(size.Z, 0.4))
							local pos = Vector3.new(x, y, z) + inward * (w / 2 + 0.2) + along * shift
							local win = block(pos, size, W.Day, true)
							win.Material = Enum.Material.Glass
							game:GetService("CollectionService"):AddTag(win, "SkylineWindow")
							rows += 1
						end
						y += W.Gap
					end
				end
			end
		end
	end
	-- 1.9: green hills at the very back
	local HL = CS.Hills
	local hd = edge + HL.at
	for side = 1, 4 do
		local n = math.floor((hd * 2) / HL.spacing)
		for i = 0, n do
			local t = -hd + i * HL.spacing + rng:NextNumber(-HL.spacing * 0.3, HL.spacing * 0.3)
			local x, z
			if side == 1 then
				x, z = t, -hd
			elseif side == 2 then
				x, z = t, hd
			elseif side == 3 then
				x, z = -hd, t
			else
				x, z = hd, t
			end
			local dia = rng:NextNumber(HL.minD, HL.maxD)
			local top = rng:NextNumber(HL.minTop, HL.maxTop)
			-- block() puts the bottom at pos.Y, so sink it until only "top" studs show
			local hill = block(Vector3.new(x, top - dia, z), Vector3.new(dia, dia, dia), HL.colors[rng:NextInteger(1, #HL.colors)], true)
			hill.Shape = Enum.PartType.Ball
			hill.Material = Enum.Material.Grass
		end
	end
	-- 1.9: a distant raised highway ring between the towers
	local HW = CS.Highway
	local d = edge + HW.at
	for side = 1, 4 do
		local horizontal = side <= 2
		local sgn = (side == 1 or side == 3) and -1 or 1
		local center = horizontal and Vector3.new(0, HW.y, sgn * d) or Vector3.new(sgn * d, HW.y, 0)
		local len = d * 2 + HW.width
		local roadSize = horizontal and Vector3.new(len, 1.5, HW.width) or Vector3.new(HW.width, 1.5, len)
		block(center, roadSize, HW.road, true)
		for _, e in ipairs({ -1, 1 }) do
			local off = (HW.width / 2) * e
			local edgePos = center + (horizontal and Vector3.new(0, 1.5, off) or Vector3.new(off, 1.5, 0))
			block(edgePos, horizontal and Vector3.new(len, 1.6, 0.8) or Vector3.new(0.8, 1.6, len), HW.side, true)
		end
		for k = -math.floor(d / HW.pillarEvery), math.floor(d / HW.pillarEvery) do
			local along = k * HW.pillarEvery
			local base = horizontal and Vector3.new(along, 0, sgn * d) or Vector3.new(sgn * d, 0, along)
			block(base, Vector3.new(4, HW.y, 4), HW.side, true)
			-- a lamp on the town-facing edge (lit at night like the windows)
			local lampPos = base + Vector3.new(0, HW.y + 1.5, 0) + (horizontal and Vector3.new(0, 0, -sgn * (HW.width / 2)) or Vector3.new(-sgn * (HW.width / 2), 0, 0))
			block(lampPos, Vector3.new(0.4, 6, 0.4), Color3.fromRGB(60, 60, 65), true)
			local bulb = block(lampPos + Vector3.new(0, 6, 0), Vector3.new(1.4, 0.8, 1.4), CS.Windows.Day, true)
			game:GetService("CollectionService"):AddTag(bulb, "SkylineWindow")
		end
	end
	folder.Parent = mapFolder
end

function WorldService.build()
	buildLighting()
	buildGround()
	buildPlaza()
	buildLoseSide()
	buildGainSide()
	pcall(buildPavement) -- 1.8: paved town (grass only for the park and river banks)
	local okF, filled = pcall(fillTown) -- 1.8: fill free street slots with closed shops and houses
	if not okF then
		warn("[WorldService] fill: " .. tostring(filled))
	end
	local okS, errS = pcall(dressStreets) -- 1.8.2 street dressing
	if not okS then
		warn("[WorldService] streets: " .. tostring(errS))
	end
	local okR, errR = pcall(buildRiver) -- 1.8 River City
	if not okR then
		warn("[WorldService] river: " .. tostring(errR))
	end
	pcall(buildSkyline) -- 1.8.1: the fake city beyond the edge (never stops the town from loading)
	local ok, err = pcall(buildPolish) -- 1.7 (a problem here must never stop the town from loading)
	if not ok then
		warn("[WorldService] 1.7 map polish failed: " .. tostring(err))
	end
	-- 1.7.4 (round 4, Hacker B): invisible walls at the edge of the ground, so nobody walks off into the void
	local edge = (940 * S + 40) / 2
	local wallH = Config.Map.EdgeWallHeight
	for _, w in ipairs({
		{ Vector3.new(edge + 1, wallH / 2, 0), Vector3.new(2, wallH, edge * 2 + 4) },
		{ Vector3.new(-edge - 1, wallH / 2, 0), Vector3.new(2, wallH, edge * 2 + 4) },
		{ Vector3.new(0, wallH / 2, edge + 1), Vector3.new(edge * 2 + 4, wallH, 2) },
		{ Vector3.new(0, wallH / 2, -edge - 1), Vector3.new(edge * 2 + 4, wallH, 2) },
	}) do
		local p = Instance.new("Part")
		p.Name = "EdgeWall"
		p.Anchored = true
		p.Transparency = 1
		p.CanQuery = false
		p.Position = w[1]
		p.Size = w[2]
		p.Parent = mapFolder
		-- 1.8.1: a friendly message instead of a silent invisible wall
		local told = {}
		p.Touched:Connect(function(hit)
			local pl = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if pl and (told[pl] or 0) < os.clock() then
				told[pl] = os.clock() + 8
				BrainService.toast(pl, Content.Settings17.EdgeOfTown)
			end
		end)
	end
	-- 1.9.1 room guide: tag every spot inside a building (later services add theirs; the guide catches those too)
	Rooms.startGuide()
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

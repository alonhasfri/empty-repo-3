-- CastleService (update 1.4): the secret Endless Castle
--
--   A plain default-looking house that doesn't fit the town -> a hole in the floor
--   -> the void (it catches you, no death) -> a white room with one cardboard box and
--   a "please $1 more" sign (a joke, nothing is for sale) -> climb in the box
--   -> the Endless Castle: an entrance hall with secret rooms + the Endless Hallway.
--
--   The hallway puzzle: every hallway ends in LEFT or RIGHT. Wrong turn = back to the
--   start (it looks the same, forever). Hints: graffiti, a painting and a humming knight,
--   all from our own rhyme. The route changes every season so guides go out of date.
--   Follow it exactly -> a brick wall -> knock -> it opens -> rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Brain = require(Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local FriendService = require(script.Parent.FriendService)

local CastleService = {}

local HOUSE_RAW = Vector3.new(0, 0.6, -410) -- just outside town, on the grass
local WHITE = Vector3.new(0, 3000, 9000)
local CASTLE = Vector3.new(0, 3000, 12000) -- entrance hall
local HALL = CASTLE + Vector3.new(0, 0, -300) -- the Endless Hallway (start)
local WALL_ROOM = CASTLE + Vector3.new(300, 0, 0)
CastleService.Center = CASTLE
CastleService.White = WHITE

local folder = Instance.new("Folder")
folder.Name = "EndlessCastle"
folder.Parent = workspace

local STONE = Color3.fromRGB(95, 90, 100)
local DARKSTONE = Color3.fromRGB(60, 56, 66)
local CARPET = Color3.fromRGB(140, 25, 40)
local GOLD = Color3.fromRGB(230, 180, 60)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or folder
	return p
end

local function text(p: BasePart, str: string, color: Color3?, font: Enum.Font?, face: Enum.NormalId?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face or Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.Parent = p
	local l = Instance.new("TextLabel")
	l.Name = "Text"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.TextWrapped = true
	l.Font = font or Enum.Font.Fantasy
	l.TextColor3 = color or Color3.fromRGB(240, 230, 210)
	l.Text = str
	l.Parent = sg
	return l
end

local function prompt(p: BasePart, action: string, object: string, fn, dist: number?)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0.2
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = dist or 10
	pp.Parent = p
	pp.Triggered:Connect(fn)
	return pp
end

local function candle(pos: Vector3)
	part({ Name = "Candle", Size = Vector3.new(0.5, 1.4, 0.5), CFrame = CFrame.new(pos), Color = Color3.fromRGB(245, 240, 220), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local flame = part({ Name = "CandleFlame", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), CFrame = CFrame.new(pos + Vector3.new(0, 0.95, 0)), Color = Color3.fromRGB(255, 190, 80), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 90)
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = flame
end

-- A closed stone box room
local function room(center: Vector3, size: Vector3, wall: Color3?, floor: Color3?, floorMat: Enum.Material?)
	local w = wall or STONE
	part({ Name = "Floor", Size = Vector3.new(size.X, 1, size.Z), CFrame = CFrame.new(center - Vector3.new(0, 0.5, 0)), Color = floor or DARKSTONE, Material = floorMat or Enum.Material.Cobblestone })
	part({ Name = "Ceiling", Size = Vector3.new(size.X, 1, size.Z), CFrame = CFrame.new(center + Vector3.new(0, size.Y + 0.5, 0)), Color = w, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(size.X, size.Y, 1), CFrame = CFrame.new(center + Vector3.new(0, size.Y / 2, size.Z / 2 + 0.5)), Color = w, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(size.X, size.Y, 1), CFrame = CFrame.new(center + Vector3.new(0, size.Y / 2, -size.Z / 2 - 0.5)), Color = w, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(1, size.Y, size.Z), CFrame = CFrame.new(center + Vector3.new(size.X / 2 + 0.5, size.Y / 2, 0)), Color = w, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(1, size.Y, size.Z), CFrame = CFrame.new(center + Vector3.new(-size.X / 2 - 0.5, size.Y / 2, 0)), Color = w, Material = Enum.Material.Brick })
end

local function tp(player, pos: Vector3, lookDir: Vector3?)
	local char = player.Character
	if char then
		local look = lookDir or Vector3.new(0, 0, -1)
		char:PivotTo(CFrame.lookAt(pos, pos + look))
	end
end

---------------------------------------------------------------------
-- The route (changes every season)
---------------------------------------------------------------------
local function seasonId(): number
	local t = os.date("!*t")
	return t.year * 4 + math.floor((t.month - 1) / 3)
end

local function route()
	local rng = Random.new(seasonId() * 7919)
	local r = {}
	for i = 1, Config.Castle.Steps do
		r[i] = rng:NextInteger(0, 1) == 0 and "L" or "R"
	end
	return r
end

local function hintFor(step: number): string
	local r = route()
	local dir = r[step + 1]
	if not dir then
		return Content.CastleEnd
	end
	local pool = dir == "L" and Content.CastleLeft or Content.CastleRight
	return pool[(step % #pool) + 1]
end

local castleStep = {} -- [player] = turns done correctly in a row
local solvedRun = {} -- [player] = true once they reach the brick wall

---------------------------------------------------------------------
-- Building
---------------------------------------------------------------------
local function buildHouse()
	-- A plain, default-looking house. Grey walls, red roof, nothing else. It does not belong here.
	local c = WorldService.sp(HOUSE_RAW)
	local base = CFrame.new(c)
	local grey = Color3.fromRGB(163, 162, 165)
	part({ Name = "OddHouseFloor", Size = Vector3.new(20, 1, 20), CFrame = base, Color = Color3.fromRGB(99, 95, 98), Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseWall", Size = Vector3.new(20, 12, 1), CFrame = base * CFrame.new(0, 6.5, 10), Color = grey, Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseWall", Size = Vector3.new(1, 12, 20), CFrame = base * CFrame.new(10, 6.5, 0), Color = grey, Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseWall", Size = Vector3.new(1, 12, 20), CFrame = base * CFrame.new(-10, 6.5, 0), Color = grey, Material = Enum.Material.SmoothPlastic })
	-- front wall with an open doorway (facing town)
	part({ Name = "OddHouseWall", Size = Vector3.new(7, 12, 1), CFrame = base * CFrame.new(-6.5, 6.5, -10), Color = grey, Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseWall", Size = Vector3.new(7, 12, 1), CFrame = base * CFrame.new(6.5, 6.5, -10), Color = grey, Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseWall", Size = Vector3.new(6, 4, 1), CFrame = base * CFrame.new(0, 10.5, -10), Color = grey, Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseRoof", Size = Vector3.new(22, 1.2, 22), CFrame = base * CFrame.new(0, 13, 0), Color = Color3.fromRGB(196, 40, 28), Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseRoof", Size = Vector3.new(16, 1.2, 16), CFrame = base * CFrame.new(0, 14.2, 0), Color = Color3.fromRGB(196, 40, 28), Material = Enum.Material.SmoothPlastic })
	part({ Name = "OddHouseRoof", Size = Vector3.new(10, 1.2, 10), CFrame = base * CFrame.new(0, 15.4, 0), Color = Color3.fromRGB(196, 40, 28), Material = Enum.Material.SmoothPlastic })
	-- the hole
	local hole = part({ Name = "TheHole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 7, 7), CFrame = base * CFrame.new(0, 0.55, 3) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local trigger = part({ Name = "HoleTrigger", Size = Vector3.new(5, 2, 5), CFrame = base * CFrame.new(0, 1.5, 3), Transparency = 1, CanCollide = false })
	local _ = hole
	local falling = {}
	trigger.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player or falling[player] then
			return
		end
		falling[player] = true
		Net.send(player, "voidFall", {})
		task.delay(2.4, function()
			tp(player, WHITE + Vector3.new(0, 4, 30))
			task.wait(1)
			falling[player] = nil
		end)
	end)
	WorldService.Spots.oddhouse = HOUSE_RAW + Vector3.new(0, 3, -24)
end

local boxPleas = 1
local function buildWhiteRoom()
	-- flat, empty, white. One box. One sign.
	part({ Name = "WhiteFloor", Size = Vector3.new(200, 1, 200), CFrame = CFrame.new(WHITE - Vector3.new(0, 0.5, 0)), Color = Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic })
	for _, d in ipairs({ Vector3.new(100, 0, 0), Vector3.new(-100, 0, 0), Vector3.new(0, 0, 100), Vector3.new(0, 0, -100) }) do
		part({ Name = "WhiteWall", Size = Vector3.new(d.X == 0 and 200 or 1, 120, d.Z == 0 and 200 or 1), CFrame = CFrame.new(WHITE + d + Vector3.new(0, 60, 0)), Color = Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic, Transparency = 0 })
	end
	local box = part({ Name = "CardboardBox", Size = Vector3.new(6, 4.5, 6), CFrame = CFrame.new(WHITE + Vector3.new(0, 2.25, 0)), Color = Color3.fromRGB(190, 145, 90), Material = Enum.Material.Cardboard })
	part({ Name = "BoxTape", Size = Vector3.new(6.05, 0.1, 1), CFrame = CFrame.new(WHITE + Vector3.new(0, 4.5, 0)), Color = Color3.fromRGB(210, 180, 130), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local post = part({ Name = "SignPost", Size = Vector3.new(0.3, 5, 0.3), CFrame = CFrame.new(WHITE + Vector3.new(6, 2.5, 0)), Color = Color3.fromRGB(120, 85, 50), Material = Enum.Material.Wood })
	local _ = post
	local board = part({ Name = "PleaseSign", Size = Vector3.new(5, 2.4, 0.2), CFrame = CFrame.new(WHITE + Vector3.new(6, 5.6, 0)), Color = Color3.fromRGB(250, 250, 245), Material = Enum.Material.SmoothPlastic })
	text(board, "please $1 more", Color3.fromRGB(40, 40, 40), Enum.Font.Cartoon, Enum.NormalId.Back)
	text(board, "please $1 more", Color3.fromRGB(40, 40, 40), Enum.Font.Cartoon, Enum.NormalId.Front)
	prompt(box, "Climb in", "📦 Cardboard Box", function(player)
		Net.send(player, "castleEnter", {})
		task.delay(1.2, function()
			tp(player, CASTLE + Vector3.new(0, 4, 18))
			BrainService.toast(player, "🏰 The Endless Castle. (The sign was a joke. Nothing here is for sale.)", "LibrarianChime")
		end)
	end)
end

local function door(pos: Vector3, facing: Vector3, label: string, fn)
	local cf = CFrame.lookAt(pos, pos + facing)
	local frame = part({ Name = "DoorArch", Size = Vector3.new(7, 10, 0.6), CFrame = cf * CFrame.new(0, 5, 0), Color = Color3.fromRGB(70, 45, 30), Material = Enum.Material.Wood })
	part({ Name = "DoorDark", Size = Vector3.new(5.6, 8.6, 0.2), CFrame = cf * CFrame.new(0, 4.4, -0.35), Color = Color3.fromRGB(15, 10, 20), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local plate = part({ Name = "DoorPlate", Size = Vector3.new(6, 1.2, 0.1), CFrame = cf * CFrame.new(0, 10.8, -0.4), Color = GOLD, Material = Enum.Material.Metal, CanCollide = false })
	text(plate, label, Color3.fromRGB(50, 30, 10), Enum.Font.Fantasy, Enum.NormalId.Front)
	prompt(frame, "Enter", label, fn)
	return frame
end

local function backDoor(roomCenter: Vector3, z: number)
	door(roomCenter + Vector3.new(0, 0, z), Vector3.new(0, 0, z > 0 and -1 or 1), "Back to the hall", function(player)
		tp(player, CASTLE + Vector3.new(0, 4, 10))
	end)
end

local function painting(cf: CFrame, str: string, size: Vector3?)
	local s = size or Vector3.new(5, 4, 0.3)
	part({ Name = "Frame", Size = s + Vector3.new(0.6, 0.6, -0.1), CFrame = cf, Color = GOLD, Material = Enum.Material.Metal, CanCollide = false })
	local canvas = part({ Name = "Canvas", Size = s, CFrame = cf * CFrame.new(0, 0, -0.15), Color = Color3.fromRGB(235, 225, 200), Material = Enum.Material.Fabric, CanCollide = false })
	return text(canvas, str, Color3.fromRGB(40, 30, 30), Enum.Font.Garamond, Enum.NormalId.Front)
end

local boxSign: TextLabel = nil

local function buildCastle()
	-- ENTRANCE HALL
	room(CASTLE, Vector3.new(80, 22, 50))
	part({ Name = "Carpet", Size = Vector3.new(8, 0.1, 48), CFrame = CFrame.new(CASTLE + Vector3.new(0, 0.05, 0)), Color = CARPET, Material = Enum.Material.Fabric, CanCollide = false })
	for x = -36, 36, 12 do
		candle(CASTLE + Vector3.new(x, 0.7, 23))
		candle(CASTLE + Vector3.new(x, 0.7, -23))
	end
	local chandelier = part({ Name = "Chandelier", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(CASTLE + Vector3.new(0, 17, 0)), Color = Color3.fromRGB(255, 220, 140), Material = Enum.Material.Neon, CanCollide = false })
	local cl = Instance.new("PointLight")
	cl.Range = 50
	cl.Brightness = 1.3
	cl.Color = Color3.fromRGB(255, 200, 130)
	cl.Parent = chandelier
	local title = part({ Name = "HallTitle", Size = Vector3.new(30, 4, 0.2), CFrame = CFrame.new(CASTLE + Vector3.new(0, 16, 24.4)) * CFrame.Angles(0, math.pi, 0), Color = DARKSTONE, CanCollide = false })
	text(title, "THE ENDLESS CASTLE", GOLD, Enum.Font.Fantasy)

	-- the Endless Hallway door (north wall)
	door(CASTLE + Vector3.new(0, 0, -24.6), Vector3.new(0, 0, 1), "The Endless Hallway", function(player)
		castleStep[player] = 0
		tp(player, HALL + Vector3.new(0, 4, -6))
		Net.send(player, "castleStep", { step = 0, steps = Config.Castle.Steps, hint = hintFor(0) })
	end)
	-- exit (south wall)
	door(CASTLE + Vector3.new(0, 0, 24.6), Vector3.new(0, 0, -1), "Back to Brainville", function(player)
		castleStep[player] = nil
		WorldService.teleport(player, "lobby")
	end)

	-- SECRET ROOMS (east + west walls of the hall)
	local ROOMS = {
		{ x = -39.6, z = -12, name = "The Upside-Down Room" },
		{ x = -39.6, z = 0, name = "The Gallery" },
		{ x = -39.6, z = 12, name = "The Clickbait Room" },
		{ x = 39.6, z = -12, name = "The Royal Chicken" },
		{ x = 39.6, z = 0, name = "Credits" },
		{ x = 39.6, z = 12, name = "The Box Room" },
	}
	local roomCenters = {}
	for i, r in ipairs(ROOMS) do
		local center = CASTLE + Vector3.new(-200 + i * 60, 0, 200)
		roomCenters[r.name] = center
		room(center, Vector3.new(36, 16, 36))
		candle(center + Vector3.new(15, 0.7, 15))
		candle(center + Vector3.new(-15, 0.7, 15))
		backDoor(center, 17.6)
		door(CASTLE + Vector3.new(r.x, 0, r.z), Vector3.new(r.x > 0 and -1 or 1, 0, 0), r.name, function(player)
			tp(player, center + Vector3.new(0, 4, 10))
		end)
	end

	-- Upside-Down Room: the furniture is on the ceiling
	do
		local c = roomCenters["The Upside-Down Room"]
		local top = c + Vector3.new(0, 16, 0)
		part({ Name = "CeilingRug", Size = Vector3.new(16, 0.1, 12), CFrame = CFrame.new(top - Vector3.new(0, 0.05, 0)), Color = Color3.fromRGB(60, 90, 160), Material = Enum.Material.Fabric, CanCollide = false })
		part({ Name = "CeilingTable", Size = Vector3.new(8, 0.6, 5), CFrame = CFrame.new(top - Vector3.new(0, 3, 0)), Color = Color3.fromRGB(120, 80, 50), Material = Enum.Material.Wood })
		for _, x in ipairs({ -3.5, 3.5 }) do
			for _, z in ipairs({ -2, 2 }) do
				part({ Name = "CeilingLeg", Size = Vector3.new(0.5, 2.7, 0.5), CFrame = CFrame.new(top + Vector3.new(x, -1.35, z)), Color = Color3.fromRGB(100, 65, 40), Material = Enum.Material.Wood })
			end
		end
		for _, x in ipairs({ -6, 6 }) do
			part({ Name = "CeilingChair", Size = Vector3.new(2.4, 0.4, 2.4), CFrame = CFrame.new(top + Vector3.new(x, -2, 0)), Color = Color3.fromRGB(150, 40, 40), Material = Enum.Material.Fabric })
			part({ Name = "CeilingChairBack", Size = Vector3.new(0.4, 3, 2.4), CFrame = CFrame.new(top + Vector3.new(x + (x > 0 and 1 or -1), -3.3, 0)), Color = Color3.fromRGB(150, 40, 40), Material = Enum.Material.Fabric })
		end
		local s = part({ Name = "Sign", Size = Vector3.new(14, 2.5, 0.2), CFrame = CFrame.new(c + Vector3.new(0, 7, -17.9)), Color = DARKSTONE, CanCollide = false })
		text(s, "Gravity is optional in here.", Color3.fromRGB(240, 230, 210))
	end
	-- The Gallery: every animal stage, and they watch you
	do
		local c = roomCenters["The Gallery"]
		local i = 0
		for _, st in ipairs(Brain.Stages) do
			if st.key ~= "human" and st.key ~= "dead" then
				i += 1
				local x = -14 + ((i - 1) % 5) * 7
				local y = (i <= 5) and 9 or 4
				painting(CFrame.new(c + Vector3.new(x, y, -17.6)), st.emoji .. "\n" .. st.name .. "\n👀")
			end
		end
		local s = part({ Name = "Sign", Size = Vector3.new(12, 1.5, 0.2), CFrame = CFrame.new(c + Vector3.new(0, 13.5, -17.8)), Color = DARKSTONE, CanCollide = false })
		text(s, "Their eyes follow you. That's normal. Probably.", Color3.fromRGB(240, 230, 210))
	end
	-- Clickbait Room: every clickbait ever shown… and here they're all true
	do
		local c = roomCenters["The Clickbait Room"]
		local baits = {}
		for _, h in ipairs(Content.Headlines or {}) do
			if typeof(h) == "table" and h.bait and #baits < 12 then
				table.insert(baits, h)
			end
		end
		for i, h in ipairs(baits) do
			local title = h.text
			local x = -14 + ((i - 1) % 4) * 9.3
			local y = 3 + math.floor((i - 1) / 4) * 4.2
			local card = part({ Name = "ClickbaitCard", Size = Vector3.new(8.4, 3.6, 0.2), CFrame = CFrame.new(c + Vector3.new(x, y, -17.8)), Color = Color3.fromRGB(255, 60, 60), CanCollide = false })
			text(card, "✅ TRUE: " .. tostring(title), Color3.new(1, 1, 1), Enum.Font.GothamBlack)
		end
	end
	-- The Royal Chicken: the rubber chicken's home, with a chicken-sized throne
	do
		local c = roomCenters["The Royal Chicken"]
		part({ Name = "ThroneSeat", Size = Vector3.new(2, 0.6, 2), CFrame = CFrame.new(c + Vector3.new(0, 1.2, -14)), Color = GOLD, Material = Enum.Material.Metal })
		part({ Name = "ThroneBack", Size = Vector3.new(2, 3, 0.4), CFrame = CFrame.new(c + Vector3.new(0, 2.6, -15)), Color = GOLD, Material = Enum.Material.Metal })
		for _, x in ipairs({ -0.9, 0.9 }) do
			part({ Name = "ThroneLeg", Size = Vector3.new(0.3, 0.9, 0.3), CFrame = CFrame.new(c + Vector3.new(x, 0.45, -14)), Color = GOLD, Material = Enum.Material.Metal })
		end
		local body = part({ Name = "RoyalChicken", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.3, 1.6), CFrame = CFrame.new(c + Vector3.new(0, 2.1, -14)), Color = Color3.fromRGB(255, 230, 60), Material = Enum.Material.SmoothPlastic })
		part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(c + Vector3.new(0, 3, -13.6)), Color = Color3.fromRGB(255, 230, 60), Material = Enum.Material.SmoothPlastic })
		part({ Name = "Crown", Size = Vector3.new(0.6, 0.4, 0.6), CFrame = CFrame.new(c + Vector3.new(0, 3.55, -13.6)), Color = GOLD, Material = Enum.Material.Neon })
		prompt(body, "Bow", "👑 The Royal Rubber Chicken", function(player)
			BrainService.toast(player, "🐔 The Royal Rubber Chicken accepts your bow. *squeak*", "CartoonBoing")
		end)
	end
	-- Credits room
	do
		local c = roomCenters["Credits"]
		local wall = part({ Name = "CreditsWall", Size = Vector3.new(30, 12, 0.2), CFrame = CFrame.new(c + Vector3.new(0, 7, -17.8)), Color = Color3.fromRGB(20, 18, 25), CanCollide = false })
		text(wall, "LOSE A BRAIN CELL / GAIN A BRAIN CELL\n\nMade by the Cult of the 39 community\nDesigned by the owner, built with the help of Claude\nHead Moderator: the friend whose computer this was made on\n\nThank you for finding this room.\nYou are officially too curious. 💛\n— the owner", Color3.fromRGB(240, 230, 210), Enum.Font.Garamond)
	end
	-- Box Room: the "please $1 more" box is back, and the sign keeps escalating
	do
		local c = roomCenters["The Box Room"]
		local box = part({ Name = "CardboardBox", Size = Vector3.new(5, 4, 5), CFrame = CFrame.new(c + Vector3.new(0, 2, -8)), Color = Color3.fromRGB(190, 145, 90), Material = Enum.Material.Cardboard })
		local board = part({ Name = "PleaseSign", Size = Vector3.new(6, 2.4, 0.2), CFrame = CFrame.new(c + Vector3.new(0, 6.5, -11)), Color = Color3.fromRGB(250, 250, 245) })
		boxSign = text(board, "please $2 more", Color3.fromRGB(40, 40, 40), Enum.Font.Cartoon)
		prompt(box, "Look inside", "📦 Box", function(player)
			boxPleas += 1
			local steps = { "please $2 more", "please $3 more", "please $4 more", "ok fine it's free", "it was always free", "please $1 more (again)" }
			boxSign.Text = steps[(boxPleas % #steps) + 1]
			BrainService.toast(player, "📦 Inside the box: another, smaller box. Inside that: a note that says \"lol\".", "CartoonBoing")
		end)
	end
	-- A tiny door only worm-stage (or tiny) players fit through
	do
		local tiny = part({ Name = "TinyDoor", Size = Vector3.new(1.2, 1.4, 0.3), CFrame = CFrame.new(CASTLE + Vector3.new(20, 0.7, -24.4)), Color = Color3.fromRGB(70, 45, 30), Material = Enum.Material.Wood })
		local wormRoom = CASTLE + Vector3.new(200, 0, 260)
		room(wormRoom, Vector3.new(10, 6, 10), Color3.fromRGB(120, 90, 60))
		local s = part({ Name = "Sign", Size = Vector3.new(8, 2, 0.2), CFrame = CFrame.new(wormRoom + Vector3.new(0, 3, -4.8)), Color = Color3.fromRGB(240, 220, 180), CanCollide = false })
		text(s, "🐛 WORMS ONLY. Congratulations, worm.", Color3.fromRGB(60, 40, 20), Enum.Font.Cartoon)
		backDoor(wormRoom, 4.4)
		prompt(tiny, "Squeeze in", "🚪 A very small door", function(player)
			local data = DataService.get(player)
			local stage = data and Brain.stage(data.cells)
			if stage and (stage.scale or 1) <= 0.5 then
				tp(player, wormRoom + Vector3.new(0, 2, 2))
			else
				BrainService.toast(player, "🚪 You're way too big. Something tiny could fit…", "CartoonBoing")
			end
		end, 6)
	end

	-- THE ENDLESS HALLWAY
	local H = HALL
	-- corridor: 14 wide, 80 long, running -Z, then a T junction
	part({ Name = "Floor", Size = Vector3.new(14, 1, 84), CFrame = CFrame.new(H + Vector3.new(0, -0.5, -40)), Color = DARKSTONE, Material = Enum.Material.Cobblestone })
	part({ Name = "Carpet", Size = Vector3.new(5, 0.1, 82), CFrame = CFrame.new(H + Vector3.new(0, 0.05, -40)), Color = CARPET, Material = Enum.Material.Fabric, CanCollide = false })
	part({ Name = "Ceiling", Size = Vector3.new(14, 1, 84), CFrame = CFrame.new(H + Vector3.new(0, 16.5, -40)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(1, 16, 84), CFrame = CFrame.new(H + Vector3.new(7.5, 8, -40)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(1, 16, 84), CFrame = CFrame.new(H + Vector3.new(-7.5, 8, -40)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(14, 16, 1), CFrame = CFrame.new(H + Vector3.new(0, 8, 2.5)), Color = STONE, Material = Enum.Material.Brick })
	-- junction (cross piece from x=-34 to x=34)
	local J = H + Vector3.new(0, 0, -90)
	part({ Name = "Floor", Size = Vector3.new(70, 1, 14), CFrame = CFrame.new(J + Vector3.new(0, -0.5, 0)), Color = DARKSTONE, Material = Enum.Material.Cobblestone })
	part({ Name = "Ceiling", Size = Vector3.new(70, 1, 14), CFrame = CFrame.new(J + Vector3.new(0, 16.5, 0)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(70, 16, 1), CFrame = CFrame.new(J + Vector3.new(0, 8, -7.5)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(28, 16, 1), CFrame = CFrame.new(J + Vector3.new(-21, 8, 7.5)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(28, 16, 1), CFrame = CFrame.new(J + Vector3.new(21, 8, 7.5)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(1, 16, 14), CFrame = CFrame.new(J + Vector3.new(35.5, 8, 0)), Color = STONE, Material = Enum.Material.Brick })
	part({ Name = "Wall", Size = Vector3.new(1, 16, 14), CFrame = CFrame.new(J + Vector3.new(-35.5, 8, 0)), Color = STONE, Material = Enum.Material.Brick })
	for z = -10, -75, -13 do
		candle(H + Vector3.new(6.4, 0.7, z))
		candle(H + Vector3.new(-6.4, 0.7, z))
	end
	candle(J + Vector3.new(-30, 0.7, -6))
	candle(J + Vector3.new(30, 0.7, -6))
	-- arrows painted above each arm
	local la = part({ Name = "ArrowLeft", Size = Vector3.new(6, 3, 0.2), CFrame = CFrame.new(J + Vector3.new(-14, 12, -6.9)), Color = DARKSTONE, CanCollide = false })
	text(la, "⬅", Color3.fromRGB(200, 190, 170))
	local ra = part({ Name = "ArrowRight", Size = Vector3.new(6, 3, 0.2), CFrame = CFrame.new(J + Vector3.new(14, 12, -6.9)), Color = DARKSTONE, CanCollide = false })
	text(ra, "➡", Color3.fromRGB(200, 190, 170))
	-- Hints: graffiti on the junction wall + a painting in the corridor (text is set
	-- on each player's own screen, so everyone sees the hint for THEIR next turn)
	local graffiti = part({ Name = "CastleGraffiti", Size = Vector3.new(26, 6, 0.2), CFrame = CFrame.new(J + Vector3.new(0, 6, -6.9)), Color = DARKSTONE, Transparency = 0.2, CanCollide = false })
	text(graffiti, "", Color3.fromRGB(255, 240, 120), Enum.Font.PermanentMarker)
	local hintPainting = painting(CFrame.new(H + Vector3.new(-6.9, 8, -45)) * CFrame.Angles(0, math.rad(90), 0), "", Vector3.new(9, 6, 0.3))
	hintPainting.Parent.Parent.Name = "CastleHintPainting"
	local counter = part({ Name = "CastleCounter", Size = Vector3.new(10, 2, 0.2), CFrame = CFrame.new(H + Vector3.new(0, 13, 1.9)) * CFrame.Angles(0, math.pi, 0), Color = DARKSTONE, CanCollide = false })
	text(counter, "", Color3.fromRGB(200, 190, 170))
	-- the humming knight
	local knightBase = H + Vector3.new(5, 0, -30)
	part({ Name = "KnightLegs", Size = Vector3.new(2, 3, 1), CFrame = CFrame.new(knightBase + Vector3.new(0, 1.5, 0)), Color = Color3.fromRGB(170, 170, 180), Material = Enum.Material.Metal })
	part({ Name = "KnightBody", Size = Vector3.new(2.6, 2.6, 1.4), CFrame = CFrame.new(knightBase + Vector3.new(0, 4.3, 0)), Color = Color3.fromRGB(180, 180, 190), Material = Enum.Material.Metal })
	local helm = part({ Name = "KnightHelm", Size = Vector3.new(1.6, 1.8, 1.6), CFrame = CFrame.new(knightBase + Vector3.new(0, 6.5, 0)), Color = Color3.fromRGB(190, 190, 200), Material = Enum.Material.Metal })
	part({ Name = "KnightPlume", Size = Vector3.new(0.3, 1.2, 1.4), CFrame = CFrame.new(knightBase + Vector3.new(0, 7.9, 0)), Color = CARPET, Material = Enum.Material.Fabric })
	prompt(helm, "Listen", "🛡 The Humming Knight", function(player)
		local step = castleStep[player] or 0
		BrainService.toast(player, "🛡🎵 The knight hums: \"" .. hintFor(step) .. "\"", "LibrarianChime")
	end, 12)

	-- turn triggers at the end of each arm
	local debounce = {}
	for _, side in ipairs({ { dir = "L", x = -32 }, { dir = "R", x = 32 } }) do
		local trig = part({ Name = "TurnTrigger" .. side.dir, Size = Vector3.new(4, 12, 12), CFrame = CFrame.new(J + Vector3.new(side.x, 6, 0)), Transparency = 1, CanCollide = false })
		part({ Name = "ArchDark", Size = Vector3.new(0.3, 10, 8), CFrame = CFrame.new(J + Vector3.new(side.x * 1.09, 5, 0)), Color = Color3.new(0, 0, 0), CanCollide = false })
		trig.Touched:Connect(function(hit)
			local char = hit.Parent
			local player = char and Players:GetPlayerFromCharacter(char)
			if not player or castleStep[player] == nil then
				return
			end
			if (debounce[player] or 0) > os.clock() then
				return
			end
			debounce[player] = os.clock() + 1.5
			local r = route()
			local step = castleStep[player]
			if r[step + 1] == side.dir then
				step += 1
				castleStep[player] = step
				if step >= #r then
					solvedRun[player] = true
					tp(player, WALL_ROOM + Vector3.new(0, 4, 14))
					Net.send(player, "castleStep", { step = step, steps = #r, hint = Content.CastleEnd, atWall = true })
				else
					tp(player, H + Vector3.new(0, 4, -6))
					Net.send(player, "castleStep", { step = step, steps = #r, hint = hintFor(step) })
				end
			else
				castleStep[player] = 0
				tp(player, H + Vector3.new(0, 4, -6))
				Net.send(player, "castleStep", { step = 0, steps = #r, hint = hintFor(0), wrong = Content.CastleWrong[math.random(1, #Content.CastleWrong)] })
			end
		end)
	end

	-- THE BRICK WALL ROOM
	room(WALL_ROOM, Vector3.new(30, 16, 36))
	candle(WALL_ROOM + Vector3.new(-12, 0.7, 14))
	candle(WALL_ROOM + Vector3.new(12, 0.7, 14))
	local bricks = Instance.new("Model")
	bricks.Name = "CastleBrickWall"
	bricks.Parent = folder
	for row = 0, 7 do
		for col = -3, 3 do
			local off = (row % 2 == 0) and 0 or 1
			part({ Name = "Brick", Size = Vector3.new(3.8, 1.8, 1.2), CFrame = CFrame.new(WALL_ROOM + Vector3.new(col * 4 + off, 1 + row * 2, -6)), Color = Color3.fromRGB(150, 70, 55), Material = Enum.Material.Brick, Parent = bricks })
		end
	end
	local knock = part({ Name = "KnockSpot", Size = Vector3.new(4, 4, 0.4), CFrame = CFrame.new(WALL_ROOM + Vector3.new(0, 4, -5.2)), Transparency = 1, CanCollide = false })
	prompt(knock, "Knock", "🧱 The old brick wall", function(player)
		if not solvedRun[player] then
			BrainService.toast(player, "🧱 *knock knock* … nothing. You didn't come the right way.", "CartoonBoing")
			return
		end
		Net.send(player, "castleWallOpen", {})
	end, 12)
	-- the treasure behind the wall
	local chest = part({ Name = "CastleChest", Size = Vector3.new(5, 3, 3.4), CFrame = CFrame.new(WALL_ROOM + Vector3.new(0, 1.5, -14)), Color = Color3.fromRGB(120, 70, 30), Material = Enum.Material.Wood })
	part({ Name = "ChestLid", Size = Vector3.new(5.2, 0.8, 3.6), CFrame = CFrame.new(WALL_ROOM + Vector3.new(0, 3.4, -14)), Color = GOLD, Material = Enum.Material.Metal })
	local glow = Instance.new("PointLight")
	glow.Color = GOLD
	glow.Range = 18
	glow.Parent = chest
	prompt(chest, "Open", "🗝 The Castle's Treasure", function(player)
		CastleService.reward(player)
	end, 10)
	door(WALL_ROOM + Vector3.new(0, 0, 17.6), Vector3.new(0, 0, -1), "Back to the hall", function(player)
		castleStep[player] = nil
		solvedRun[player] = nil
		tp(player, CASTLE + Vector3.new(0, 4, 10))
	end)
end

---------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------
function CastleService.reward(player)
	local data = DataService.get(player)
	if not data or not solvedRun[player] then
		BrainService.toast(player, "🔒 The chest is locked. Only people who found the brick wall the right way can open it.")
		return
	end
	solvedRun[player] = nil
	castleStep[player] = nil
	local season = seasonId()
	local first = not data.badges.LostAndFound
	data.castleMap = true
	BrainService.awardBadge(player, "LostAndFound")
	if data.path == nil or data.dead then
		-- 1.7.4 (round 4, castle explorer): no path yet = no reward, and the season's treasure is NOT used up
		BrainService.toast(player, Content.CastleNoPath, "LibrarianChime")
		BrainService.push(player)
		return
	end
	if data.castleSeason == season then
		BrainService.toast(player, "🗝 You already took this season's treasure. The route changes next season!", "LibrarianChime")
		return
	end
	data.castleSeason = season
	local minutes = Config.Castle.BoostMinutes
	if data.path == "Lose" and not data.dead then
		data.castleBoostUntil = os.time() + minutes * 60
		BrainService.lose(player, Config.Castle.RewardPoints, "castle")
		BrainService.toast(player, "🏰 The castle's treasure… was a brain vacuum. BIG brain cell loss + 2× LOSS speed for " .. minutes .. " minutes!", "RecordScratch")
	elseif data.path == "Gain" then
		data.castleBoostUntil = os.time() + minutes * 60
		BrainService.gain(player, Config.Castle.RewardPoints, "castle")
		BrainService.toast(player, "🏰 TREASURE! Big brain cell bonus + 2× brain cells for " .. minutes .. " minutes!", "BadgeSparkle")
	end
	Net.send(player, "confetti", {})
	if first then
		BrainService.toast(player, "🗺 You got the CASTLE MAP: the map bus never has to wait again (instant travel anywhere).", "LevelUp")
	end
	BrainService.push(player)
end

function CastleService.start()
	buildHouse()
	buildWhiteRoom()
	buildCastle()
	Players.PlayerRemoving:Connect(function(p)
		castleStep[p] = nil
		solvedRun[p] = nil
	end)
	-- the void: anything that falls under the castle/white room is caught, never killed
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in ipairs(Players:GetPlayers()) do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and root.Position.Y > 1500 and root.Position.Y < 2900 and (root.Position - WHITE).Magnitude < 4000 then
					tp(player, WHITE + Vector3.new(0, 4, 30))
				end
			end
		end
	end)
	local _ = FriendService
end

return CastleService

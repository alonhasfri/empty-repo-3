-- Rooms (update 1.5): REAL PLACES.
-- Furnishes the inside of every building that has a use, using web/src/rooms.js as the
-- reference: furniture, people with name tags, chairs you can sit on, and small things
-- to do. Buildings with no use (houses) stay closed (see WorldService.house).
--
-- Coordinates in the layouts are REAL studs from the building's center:
--   x = left/right, z = from the front door (negative) to the back wall (positive).
-- Every builder faces -Z (toward the door) at yaw 0. Yaw PI faces the back wall.
--
-- Conversation spots (feature 2) and exit doors (feature 3) are registered here too, so
-- other services can find them: Rooms.ConvSpots, Rooms.Buildings.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local Props = require(script.Parent.Props)
local FriendService = require(script.Parent.FriendService)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local Rooms = {}
Rooms.Buildings = {} -- [key] = { cf = CFrame (real, center on the floor), half = Vector3 (real), outside = Vector3 (design spot key) }
Rooms.ConvSpots = {} -- [id] = { id, stand = CFrame, npc = CFrame, conv = string | {Lose=, Gain=}, who = string, prompt = ProximityPrompt }
Rooms.onJobs = nil -- function(player) set by WorldService
Rooms.onConv = nil -- function(player, spotId) set by ConversationService
Rooms.onLeave = nil -- function(player, buildingKey) set by WorldService (exit doors)

local R = Content.Rooms
local C = Config.Rooms
local PI = math.pi

local folder = Instance.new("Folder")
folder.Name = "Rooms"
folder.Parent = workspace

local WOOD = Color3.fromRGB(154, 106, 66)
local DARKWOOD = Color3.fromRGB(106, 69, 40)
local METAL = Color3.fromRGB(170, 176, 184)
local WHITE = Color3.fromRGB(244, 244, 242)
local FABRIC = Color3.fromRGB(192, 72, 63)
local LEAF = Color3.fromRGB(70, 150, 70)

---------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------
local function box(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, extra)
	local p = Instance.new((extra and extra.ClassName) or "Part")
	p.Anchored = true
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(extra or {}) do
		if k ~= "ClassName" then
			p[k] = v
		end
	end
	p:SetAttribute("Role", "prop")
	CollectionService:AddTag(p, "Styled")
	p.Parent = parent
	return p
end

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = folder
	return m
end

-- Billboard name tag / sign (tagged "Sign" so dumb players see it scrambled)
local function tag(adornee: Instance, text: string, offsetY: number, width: number?, height: number?, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new((width or 200) / 20, 0, (height or 30) / 20, 0)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Parent = adornee
	local l = Instance.new("TextLabel")
	l.Name = "SignText"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.2
	l.Text = text
	l:SetAttribute("BaseText", text)
	CollectionService:AddTag(l, "Sign")
	l.Parent = gui
	return l
end

-- Painted text on a part's front face (whiteboards, screens)
local function painted(part: BasePart, text: string, bg: Color3, fg: Color3, font: Enum.Font?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0.2
	sg.Parent = part
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = bg
	l.TextColor3 = fg
	l.TextScaled = true
	l.Font = font or Enum.Font.FredokaOne
	l.Text = text
	l.Parent = sg
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
	pad.Parent = l
	return l
end

local lastUse = {} -- [player] = { [spotName] = os.clock() }
local function cooled(player: Player, name: string): boolean
	local t = lastUse[player]
	if not t then
		t = {}
		lastUse[player] = t
	end
	local now = os.clock()
	if t[name] and now - t[name] < C.SpotCooldown then
		return false
	end
	t[name] = now
	return true
end
game:GetService("Players").PlayerRemoving:Connect(function(p)
	lastUse[p] = nil
end)

-- Invisible part with a proximity prompt
local function spot(cf: CFrame, name: string, actionText: string, objectText: string, onUse, distance: number?)
	local p = box(folder, cf * CFrame.new(0, 3, 0), Vector3.new(2, 2, 2), WHITE, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	p.Name = "Spot_" .. name
	CollectionService:RemoveTag(p, "Styled")
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = actionText
	pp.ObjectText = objectText
	pp.HoldDuration = 0
	pp.MaxActivationDistance = distance or C.PromptDistance
	pp.RequiresLineOfSight = false
	pp.Parent = p
	pp.Triggered:Connect(function(player)
		if cooled(player, name) then
			onUse(player, pp)
		end
	end)
	return p, pp
end

-- Animals (and rocks) can't do human things like going to school (1.6)
function Rooms.isAnimal(player: Player): boolean
	local d = DataService.get(player)
	if not d then
		return false
	end
	local k = Brain.stage(d.cells, BrainService.secretAnimals).key
	return k ~= "human" and k ~= "barelyhuman"
end

local function pathOf(player: Player): string?
	local d = DataService.get(player)
	return d and d.path or nil
end

-- Is the player allowed here? Shows the reason if not.
local function guard(player: Player, path: string?): boolean
	local mine = pathOf(player)
	if not mine then
		BrainService.toast(player, R.PickPath)
		return false
	end
	if path and path ~= "Any" and mine ~= path then
		BrainService.toast(player, path == "Gain" and R.SmartOnly or R.DumbOnly)
		return false
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		BrainService.toast(player, "⛔ " .. blocked)
		return false
	end
	return true
end

---------------------------------------------------------------------
-- Furniture kit (real size, facing -Z)
---------------------------------------------------------------------
local K = {}

function K.table(cf: CFrame, w: number?, d: number?, color: Color3?)
	w, d = w or 5, d or 3
	local m = model("Table")
	box(m, cf * CFrame.new(0, 2.6, 0), Vector3.new(w, 0.3, d), color or WOOD, Enum.Material.WoodPlanks)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			box(m, cf * CFrame.new(sx * (w / 2 - 0.3), 1.3, sz * (d / 2 - 0.3)), Vector3.new(0.3, 2.6, 0.3), DARKWOOD, Enum.Material.Wood)
		end
	end
	return m
end

-- A real Seat. Walking into it doesn't sit you down (CanTouch off); use the prompt.
local function makeSeat(m: Model, cf: CFrame, size: Vector3, color: Color3, objectText: string)
	local seat = box(m, cf, size, color, Enum.Material.Fabric, { ClassName = "Seat", CanTouch = false })
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = R.Sit
	pp.ObjectText = objectText
	pp.HoldDuration = 0
	pp.MaxActivationDistance = C.SeatPromptDistance
	pp.RequiresLineOfSight = false
	pp.Parent = seat
	pp.Triggered:Connect(function(player)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and not seat.Occupant and hum.Health > 0 then
			seat:Sit(hum)
		end
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		pp.Enabled = seat.Occupant == nil
	end)
	return seat
end

function K.chair(cf: CFrame, color: Color3?)
	local m = model("Chair")
	local c = color or FABRIC
	makeSeat(m, cf * CFrame.new(0, 1.6, 0), Vector3.new(1.8, 0.3, 1.8), c, R.Seat)
	box(m, cf * CFrame.new(0, 2.7, 0.8), Vector3.new(1.8, 2, 0.3), c, Enum.Material.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			box(m, cf * CFrame.new(sx * 0.75, 0.75, sz * 0.75), Vector3.new(0.2, 1.5, 0.2), DARKWOOD, Enum.Material.Wood)
		end
	end
	return m
end

function K.couch(cf: CFrame, color: Color3?)
	local m = model("Couch")
	local c = color or Color3.fromRGB(91, 111, 179)
	makeSeat(m, cf * CFrame.new(0, 1.3, -0.2), Vector3.new(5.4, 0.8, 2.2), c, R.Couch)
	box(m, cf * CFrame.new(0, 0.5, 0), Vector3.new(6, 0.9, 2.6), c, Enum.Material.Fabric)
	box(m, cf * CFrame.new(0, 2.3, 1.1), Vector3.new(6, 2, 0.6), c, Enum.Material.Fabric)
	for _, sx in ipairs({ -1, 1 }) do
		box(m, cf * CFrame.new(sx * 3, 1.4, 0), Vector3.new(0.6, 1.8, 2.6), c, Enum.Material.Fabric)
	end
	return m
end

function K.counter(cf: CFrame, w: number, top: Color3?)
	local m = model("Counter")
	box(m, cf * CFrame.new(0, 1.5, 0), Vector3.new(w, 3, 2.2), DARKWOOD, Enum.Material.Wood)
	box(m, cf * CFrame.new(0, 3.1, 0), Vector3.new(w + 0.2, 0.25, 2.5), top or WHITE, Enum.Material.Marble)
	return m
end

function K.plant(cf: CFrame)
	local m = model("Plant")
	box(m, cf * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, PI / 2), Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(181, 101, 58), Enum.Material.Slate, { Shape = Enum.PartType.Cylinder })
	box(m, cf * CFrame.new(0, 2.3, 0), Vector3.new(2.6, 2.6, 2.6), LEAF, Enum.Material.LeafyGrass, { Shape = Enum.PartType.Ball })
	return m
end

function K.rug(cf: CFrame, w: number, d: number, color: Color3)
	local m = model("Rug")
	box(m, cf * CFrame.new(0, 0.03, 0), Vector3.new(w, 0.06, d), color, Enum.Material.Fabric, { CanCollide = false })
	return m
end

-- Whiteboard on a wall; returns the text label so it can be written on
function K.whiteboard(cf: CFrame, w: number, text: string)
	local m = model("Whiteboard")
	box(m, cf * CFrame.new(0, 5, 0), Vector3.new(w + 0.4, 4.8, 0.3), METAL, Enum.Material.Metal)
	local board = box(m, cf * CFrame.new(0, 5, -0.2), Vector3.new(w, 4.4, 0.1), Color3.fromRGB(253, 253, 251))
	return painted(board, text, Color3.fromRGB(253, 253, 251), Color3.fromRGB(29, 78, 216))
end

function K.fridge(cf: CFrame)
	local m = model("Fridge")
	box(m, cf * CFrame.new(0, 3.5, 0.15), Vector3.new(3, 7, 2.3), WHITE, Enum.Material.SmoothPlastic)
	box(m, cf * CFrame.new(0, 3.5, -0.95), Vector3.new(2.6, 6.4, 0.1), Color3.fromRGB(120, 200, 255), Enum.Material.Neon, { Transparency = 0.5 }) -- the light inside
	local hinge = cf * CFrame.new(-1.5, 0, -1.1) -- left front edge
	local door = box(m, hinge * CFrame.new(1.5, 3.5, -0.1), Vector3.new(3, 6.8, 0.2), Color3.fromRGB(232, 232, 232), Enum.Material.SmoothPlastic)
	local handle = box(m, hinge * CFrame.new(2.7, 4, -0.3), Vector3.new(0.15, 1.6, 0.15), METAL, Enum.Material.Metal)
	return { model = m, hinge = hinge, door = door, handle = handle, open = false }
end

function K.seatRow(cf: CFrame, n: number)
	local m = model("SeatRow")
	for i = 0, n - 1 do
		local c = cf * CFrame.new(-(n - 1) * 1.3 + i * 2.6, 0, 0)
		makeSeat(m, c * CFrame.new(0, 1.4, 0), Vector3.new(2.2, 0.5, 2), FABRIC, R.Seat)
		box(m, c * CFrame.new(0, 0.6, 0), Vector3.new(2.2, 1.2, 2), FABRIC, Enum.Material.Fabric)
		box(m, c * CFrame.new(0, 2.2, 0.9), Vector3.new(2.2, 2.4, 0.4), FABRIC, Enum.Material.Fabric)
	end
	return m
end

function K.stage(cf: CFrame, w: number, d: number, color: Color3)
	local m = model("Stage")
	box(m, cf * CFrame.new(0, 0.4, 0), Vector3.new(w, 0.8, d), color, Enum.Material.WoodPlanks)
	return m
end

function K.podium(cf: CFrame, color: Color3?)
	local m = model("Podium")
	box(m, cf * CFrame.new(0, 2, 0), Vector3.new(3, 4, 2), color or Color3.fromRGB(43, 58, 103), Enum.Material.Wood)
	box(m, cf * CFrame.new(0, 4.1, 0.1) * CFrame.Angles(math.rad(15), 0, 0), Vector3.new(3.2, 0.3, 2.2), DARKWOOD, Enum.Material.Wood)
	return m
end

function K.judgeBench(cf: CFrame)
	local m = model("JudgeBench")
	box(m, cf * CFrame.new(0, 2.5, 0), Vector3.new(10, 5, 3), DARKWOOD, Enum.Material.Wood)
	box(m, cf * CFrame.new(0, 5.1, 0), Vector3.new(10.4, 0.3, 3.4), WOOD, Enum.Material.WoodPlanks)
	box(m, cf * CFrame.new(0, 1, 3), Vector3.new(10, 2, 4), DARKWOOD, Enum.Material.Wood) -- platform behind for the judge
	box(m, cf * CFrame.new(3, 5.5, -0.6), Vector3.new(0.8, 0.4, 0.4), DARKWOOD, Enum.Material.Wood) -- gavel
	return m
end

-- Glass maze with a little mouse (lab experiment)
function K.maze(cf: CFrame)
	local m = model("MouseMaze")
	box(m, cf * CFrame.new(0, 1.2, 0), Vector3.new(5, 2.4, 5), DARKWOOD, Enum.Material.Wood)
	box(m, cf * CFrame.new(0, 3.2, 0), Vector3.new(5, 1.6, 5), Color3.fromRGB(200, 230, 255), Enum.Material.Glass, { Transparency = 0.7 })
	for i = -1, 1 do
		box(m, cf * CFrame.new(i * 1.2, 3, (i % 2 == 0) and 0.8 or -0.8), Vector3.new(0.15, 1.1, 3), WHITE)
	end
	box(m, cf * CFrame.new(1.8, 2.75, 1.6), Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(201, 201, 207), nil, { Shape = Enum.PartType.Ball })
	box(m, cf * CFrame.new(-1.8, 2.6, -1.8), Vector3.new(0.6, 0.4, 0.6), Color3.fromRGB(255, 210, 60), Enum.Material.SmoothPlastic) -- cheese
	return m
end

-- A person standing at cf (feet on the floor), with a name tag. Built in the background.
local function person(cf: CFrame, name: string, shirt: Color3, raise: number?)
	local holder = {}
	task.spawn(function()
		local m = FriendService.npc(name, Color3.fromRGB(232, 185, 143), shirt, Color3.fromRGB(43, 43, 58))
		local root
		if m then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			m:PivotTo(cf * CFrame.new(0, 3.2 + (raise or 0), 0))
			m.Parent = folder
			root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
		else
			m = model("Person")
			root = box(m, cf * CFrame.new(0, 2.5 + (raise or 0), 0), Vector3.new(2, 5, 1.2), shirt)
			m.PrimaryPart = root
		end
		m.Name = name
		if root then
			tag(root, name, 3.6, 150, 24)
		end
		holder.model = m
	end)
	return holder
end

---------------------------------------------------------------------
-- Interactions
---------------------------------------------------------------------
local function action(cf: CFrame, key: string)
	local text = R.Actions[key]
	local cfg = C.Actions[key]
	spot(cf, key, text.action, text.object, function(player)
		if not guard(player, cfg.path) then
			return
		end
		if cfg.humanOnly and Rooms.isAnimal(player) then
			BrainService.toast(player, Content.School.NoAnimals)
			return
		end
		if cfg.embarrass then
			BrainService.embarrass(player, cfg.embarrass, text.toast)
		end
		if cfg.lose then
			BrainService.lose(player, cfg.lose, key)
		end
		if cfg.gain then
			BrainService.gain(player, cfg.gain, key)
		end
		BrainService.toast(player, text.toast, "CartoonBoing")
	end)
end

local function writableBoard(cf: CFrame, label: TextLabel)
	spot(cf, "board", R.Board.action, R.Board.object, function(player)
		if not guard(player, "Any") then
			return
		end
		local path = pathOf(player)
		local lines = R.BoardLines[path]
		local line = lines[math.random(1, #lines)]
		label.Text = line
		label.TextColor3 = path == "Lose" and Color3.fromRGB(221, 17, 34) or Color3.fromRGB(29, 78, 216)
		if path == "Lose" then
			BrainService.lose(player, C.BoardPoints.Lose, "board")
		else
			BrainService.gain(player, C.BoardPoints.Gain, "board")
		end
		BrainService.toast(player, string.format(R.Board.toast, line))
	end)
end

local function fridgeSpot(cf: CFrame, fridge)
	local _, pp = spot(cf, "fridge", R.Fridge.open, R.Fridge.object, function(player, prompt)
		fridge.open = not fridge.open
		local angle = fridge.open and math.rad(C.FridgeOpenAngle) or 0
		local h = fridge.hinge * CFrame.Angles(0, angle, 0)
		fridge.door.CFrame = h * CFrame.new(1.5, 3.5, -0.1)
		fridge.handle.CFrame = h * CFrame.new(2.7, 4, -0.3)
		prompt.ActionText = fridge.open and R.Fridge.close or R.Fridge.open
		if fridge.open then
			BrainService.toast(player, R.Fridge.toast, "CartoonBoing")
		end
	end, 8)
	return pp
end

-- A conversation spot: a person at npcCf facing the player, who stands `dist` studs in front.
-- The prompt is switched on by ConversationService (feature 2).
local function convSpot(id: string, npcCf: CFrame, who: string, shirt: Color3, conv, signText: string?, opts)
	opts = opts or {}
	local dist = opts.dist or 6
	local standCf = npcCf * CFrame.new(0, 0, -dist) * CFrame.Angles(0, PI, 0) -- facing the person
	local npc = person(npcCf, who, shirt, opts.raise)
	if opts.table ~= false then
		K.table(npcCf * CFrame.new(0, 0, -dist / 2), 4, 2.2)
	end
	local p, pp = spot(standCf, "conv_" .. id, R.Talk, who, function(player)
		if Rooms.onConv then
			Rooms.onConv(player, id)
		end
	end)
	if signText then
		tag(p, signText, 5.5, 260, 36, Color3.fromRGB(255, 225, 120))
	end
	Rooms.ConvSpots[id] = { id = id, stand = standCf, npc = npcCf * CFrame.new(0, opts.raise or 0, 0), npcHolder = npc, conv = conv, who = who, prompt = pp, labels = opts.labels }
	return Rooms.ConvSpots[id]
end
Rooms.convSpot = convSpot

local function roomSign(cf: CFrame, text: string)
	local p = box(folder, cf * CFrame.new(0, 7.5, 0), Vector3.new(1, 1, 1), WHITE, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	CollectionService:RemoveTag(p, "Styled")
	tag(p, text, 0, 260, 38, Color3.fromRGB(255, 210, 60))
	return p
end

---------------------------------------------------------------------
-- Layouts: only buildings that have a use. Existing stations and workplaces
-- (WorldService) stay where they were; these fill the empty floor around them.
---------------------------------------------------------------------
local P = Content.Rooms.People
local LAYOUT = {}

-- 🛍 Brainrot Mall (Lose): arcade zone, product shelves, plushie display
LAYOUT.lose = function(at)
	for i, title in ipairs(R.ArcadeTitles) do
		Props.arcade(at(-36 + (i - 1) * 5, 29, 0), title)
	end
	roomSign(at(-28.5, 29, 0), R.Signs.arcade)
	action(at(-28.5, 24, 0), "arcade")
	Props.shopCounter(at(33, 0, PI / 2))
	Props.shopCounter(at(33, 12, PI / 2))
	K.counter(at(24, 26, 0), 8, Color3.fromRGB(255, 90, 180))
	Props.bench(at(-34, 2, -PI / 2))
	local plush = box(folder, at(24, 26, 0) * CFrame.new(0, 4.4, 0), Vector3.new(2.4, 2.4, 2.4), Color3.fromRGB(255, 210, 60), nil, { Shape = Enum.PartType.Ball })
	tag(plush, R.Signs.plushie, 2.5, 220, 30)
	action(at(24, 22, 0), "plushie")
	K.plant(at(-38, -30, 0))
	K.plant(at(38, -30, 0))
end

-- 🍿 Microwave Diner (Lose): counter, fridge, chairs at the tables
LAYOUT.diner = function(at)
	K.counter(at(-13, 14.5, 0), 10, Color3.fromRGB(255, 143, 163))
	local fridge = K.fridge(at(17, 14.5, 0))
	fridgeSpot(at(17, 10.5, 0), fridge)
	for _, x in ipairs({ -12.1, 0, 12.1 }) do
		K.chair(at(x - 1.8, -7.6, 0), Color3.fromRGB(230, 60, 80))
		K.chair(at(x + 1.8, -7.6, 0), Color3.fromRGB(230, 60, 80))
	end
	K.rug(at(0, -3.3, 0), 36, 9, Color3.fromRGB(34, 34, 34))
end

-- 🛒 Supermarket: aisles (Lose players shake the cereal; Gain players work the register)
LAYOUT.supermarket = function(at)
	for _, x in ipairs({ -24, -12, 12, 24 }) do
		Props.shopCounter(at(x, -1, 0))
	end
	action(at(-12, -5, 0), "cereal")
	K.plant(at(30, -21, 0))
end

-- 🏫 School: classroom with a whiteboard, students and the teacher
LAYOUT.gain = function(at)
	local board = K.whiteboard(at(16, 32.1, 0), 12, R.BoardStart.school.Gain)
	writableBoard(at(9, 29, 0), board)
	roomSign(at(16, 32, 0) * CFrame.new(0, 1.5, 0), R.Signs.classroom)
	Props.desk(at(16, 25.5, 0), true) -- teacher's desk
	local shirts = { Color3.fromRGB(255, 143, 163), Color3.fromRGB(143, 211, 255), Color3.fromRGB(255, 210, 122), Color3.fromRGB(168, 240, 176), Color3.fromRGB(208, 176, 255), Color3.fromRGB(255, 179, 138) }
	local i = 0
	for _, z in ipairs({ 11.5, 18.5 }) do
		for _, x in ipairs({ 4, 12, 30.5 }) do
			i += 1
			Props.desk(at(x, z, PI), false)
			if x ~= 12 then -- students stand beside the outer desks
				person(at(x == 4 and x - 5.5 or x + 5.4, z - 1, PI), P.student, shirts[i])
			end
		end
	end
	-- 1.6: Lose-path class actions at the middle desks
	action(at(12, 8.4, 0), "sleep")
	action(at(12, 15.4, 0), "paper")
	convSpot("classroom", at(16, 30.6, 0), P.teacher, Color3.fromRGB(58, 123, 255), { Lose = "classroomL", Gain = "classroomG" }, nil, { table = false, dist = 8, labels = true })
end

-- 🎓 University: lecture hall around the Skill Gate
LAYOUT.university = function(at)
	K.whiteboard(at(0, 29.4, 0), 14, R.BoardStart.university)
	roomSign(at(0, 29.4, 0) * CFrame.new(0, 1.5, 0), R.Signs.lecture)
	for _, z in ipairs({ 18, 24.5 }) do
		for _, x in ipairs({ -22, -13, 13, 22 }) do
			Props.desk(at(x, z, PI), false)
		end
	end
	K.plant(at(-30, 27, 0))
	K.plant(at(30, 27, 0))
end

-- 🎬 Jack B Cinema: seats facing the screen, the Debate Show stage, snacks
LAYOUT.cinema = function(at)
	for _, z in ipairs({ 5, 8.5, 12 }) do
		K.seatRow(at(0, z, PI), 6)
	end
	K.stage(at(-18, 13, 0), 10, 8, Color3.fromRGB(58, 42, 58))
	convSpot("debate", at(-18, 14, 0), P.host, Color3.fromRGB(210, 76, 76), "debate", R.Signs.debate, { table = false, raise = 0.8, dist = 8 })
	K.counter(at(19, 12, PI / 2), 8, Color3.fromRGB(255, 210, 60))
	roomSign(at(19, 12, 0), R.Signs.snacks)
end

-- ☕ Beethoven's Café: tables, couch, barista
LAYOUT.cafe = function(at)
	for _, x in ipairs({ -8, 8 }) do
		K.table(at(x, -4, 0), 3.4, 3.4)
		K.chair(at(x, -6.6, PI))
		K.chair(at(x, -1.4, 0))
	end
	K.couch(at(-8.5, 10.3, 0), Color3.fromRGB(150, 100, 70))
	person(at(0, 8, 0), P.barista, Color3.fromRGB(107, 66, 38))
	K.plant(at(11, 10, 0))
end

-- 🏥 Hospital: check-ups (Lose), a patient (Gain), and Dr. Calm's therapy corner (everyone)
LAYOUT.hospital = function(at)
	convSpot("doctor", at(-18, -4, 0), P.doctor, Color3.fromRGB(233, 242, 255), { Lose = "doctorL" }, R.Signs.checkup)
	convSpot("patient", at(-14.5, 10, 0), P.patient, Color3.fromRGB(255, 143, 163), { Gain = "doctorG" }, R.Signs.patient, { table = false })
	K.rug(at(22, 12, 0), 14, 12, Color3.fromRGB(127, 178, 160))
	convSpot("therapist", at(22, 17, 0), P.therapist, Color3.fromRGB(160, 200, 184), "therapist", R.Signs.therapy, { table = false })
	K.couch(at(29, 9, PI / 2), Color3.fromRGB(127, 178, 160))
	K.plant(at(30, 24, 0))
	K.plant(at(-30, -24, 0))
end

-- 🏢 Office Tower: desks and the Brainville Times newsroom
LAYOUT.office = function(at)
	for _, x in ipairs({ -11, 11 }) do
		for _, z in ipairs({ -8, 6 }) do
			Props.desk(at(x, z, 0), true)
		end
	end
	convSpot("journalist", at(0, 15, 0), P.editor, Color3.fromRGB(68, 68, 68), { Lose = "journalistL", Gain = "journalistG" }, R.Signs.newsroom)
	K.plant(at(-16, 16, 0))
	K.plant(at(16, 16, 0))
end

-- 💼 Job Center: counselor desk, waiting bench
LAYOUT.jobcenter = function(at)
	Props.desk(at(-8, 7, 0), true)
	person(at(-8, 11.4, 0), P.counselor, Color3.fromRGB(47, 154, 88))
	roomSign(at(-8, 7, 0), R.Signs.counselor)
	spot(at(-8, 3.5, 0), "counselor", R.Counselor.action, R.Counselor.object, function(player)
		if guard(player, "Gain") and Rooms.onJobs then
			Rooms.onJobs(player)
		end
	end)
	Props.desk(at(8, 7, 0), true)
	Props.bench(at(-10, -6, -PI / 2))
	K.plant(at(11, -10, 0))
end

-- ⚖️ Courthouse: judge, tables, gallery, election podium
LAYOUT.courthouse = function(at)
	K.judgeBench(at(0, 19, 0))
	convSpot("court", at(0, 21.5, 0), P.judge, Color3.fromRGB(29, 29, 36), { Lose = "courtL", Gain = "courtG" }, R.Signs.court, { table = false, raise = 2, dist = 9, labels = true })
	for _, x in ipairs({ -12, 12 }) do
		K.table(at(x, 9, 0), 7, 3)
		K.chair(at(x, 6.5, PI))
		Props.bench(at(x, -12, PI))
	end
	K.podium(at(-22, 2, 0))
	convSpot("election", at(-22, 8, 0), P.voter, Color3.fromRGB(85, 119, 170), "election", R.Signs.election, { table = false })
end

-- 🔬 Science Lab: the mouse maze experiment
LAYOUT.lab = function(at)
	K.maze(at(18, -6, 0))
	convSpot("experiment", at(18, -2.5, 0), P.assistant, Color3.fromRGB(230, 251, 255), "experiment", R.Signs.maze, { table = false, dist = 7 })
	K.plant(at(27, -22, 0))
	K.plant(at(-27, -22, 0))
end

-- Furnish one building. rcf = real CFrame at the building's center on the ground, half = real half size.
function Rooms.furnish(key: string, rcf: CFrame, half: Vector3, outsideKey: string?)
	Rooms.Buildings[key] = { cf = rcf, half = half, outside = outsideKey or key }
	local build = LAYOUT[key]
	if not build then
		return
	end
	local function at(x: number, z: number, yaw: number?): CFrame
		return rcf * CFrame.new(x, 0.5, z) * CFrame.Angles(0, yaw or 0, 0)
	end
	local ok, err = pcall(build, at)
	if not ok then
		warn("[Rooms] " .. key .. ": " .. tostring(err))
	end
	-- Exit door: a lit EXIT sign above the doorway (inside) and a Leave prompt by the door
	local exitSign = box(folder, rcf * CFrame.new(0, 14.6, -half.Z + 0.9) * CFrame.Angles(0, PI, 0), Vector3.new(6, 1.6, 0.3), Color3.fromRGB(40, 200, 90), Enum.Material.Neon)
	exitSign.Name = "ExitSign_" .. key
	CollectionService:RemoveTag(exitSign, "Styled")
	painted(exitSign, R.Exit.sign, Color3.fromRGB(30, 170, 70), Color3.new(1, 1, 1), Enum.Font.FredokaOne)
	spot(rcf * CFrame.new(0, 0.5, -half.Z + 3.5), "exit_" .. key, R.Exit.action, R.Exit.object, function(player)
		if Rooms.onLeave then
			Rooms.onLeave(player, key)
		end
	end)
end

-- Gets a player out of any seat (so teleports don't drag the seat along).
-- If they were sitting, waits a moment so the player's own game lets go of the seat
-- before anything moves them.
function Rooms.standUp(hum: Humanoid)
	local seat = hum.SeatPart
	hum.Sit = false
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		task.wait(Config.Rooms.StandUpDelay)
	end
end

-- Which furnished building is this position in? (nil = outside)
function Rooms.buildingAt(pos: Vector3): string?
	for key, b in pairs(Rooms.Buildings) do
		local rel = b.cf:PointToObjectSpace(pos)
		if math.abs(rel.X) <= b.half.X and math.abs(rel.Z) <= b.half.Z and rel.Y > -5 and rel.Y < 40 then
			return key
		end
	end
	return nil
end

return Rooms

-- Props: detailed, real-looking furniture and objects built from parts
-- (microwaves, cars, desks, arcade machines, bookshelves, vending machines...).
--
-- WANT REAL 3D MODELS? Drag any model from the Studio Toolbox into
-- ServerStorage > Props and name it exactly like a prop below (e.g. "Car",
-- "Microwave", "Desk"). The game will use YOUR model instead, sized to fit.
-- Scripts inside Toolbox models are removed automatically for safety.
--
-- Every builder takes a CFrame on the floor, facing -Z (the front), and returns a Model.

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config) -- 1.9.1 filler weights

local Props = {}

local folder = Instance.new("Folder")
folder.Name = "Props"
folder.Parent = workspace

local function newModel(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = folder
	return m
end

local function box(model: Model, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, extra)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(extra or {}) do
		p[k] = v
	end
	p:SetAttribute("Role", "prop")
	CollectionService:AddTag(p, "Styled")
	p.Parent = model
	return p
end

-- vertical cylinder standing on its base
local function cyl(model: Model, cf: CFrame, height: number, diameter: number, color: Color3, material: Enum.Material?, extra)
	local e = extra or {}
	e.Shape = Enum.PartType.Cylinder
	return box(model, cf * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(height, diameter, diameter), color, material, e)
end

local function ball(model: Model, cf: CFrame, d: number, color: Color3, material: Enum.Material?)
	return box(model, cf, Vector3.new(d, d, d), color, material, { Shape = Enum.PartType.Ball })
end

local function screen(part: BasePart, text: string, face: Enum.NormalId?, bg: Color3?, fg: Color3?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face or Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	sg.Parent = part
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = bg or Color3.fromRGB(10, 10, 14)
	l.BackgroundTransparency = bg and 0 or 1
	l.TextColor3 = fg or Color3.fromRGB(120, 255, 140)
	l.TextScaled = true
	l.Font = Enum.Font.Code
	l.Text = text
	l.Parent = sg
	return l
end

local WOOD = Color3.fromRGB(140, 95, 60)
local DARKWOOD = Color3.fromRGB(90, 60, 40)
local STEEL = Color3.fromRGB(170, 172, 178)
local BLACK = Color3.fromRGB(25, 25, 30)
local WHITE = Color3.fromRGB(240, 240, 240)

---------------------------------------------------------------------
-- Toolbox override: use the owner's model if one is in ServerStorage > Props
---------------------------------------------------------------------
local function custom(name: string, cf: CFrame, targetSize: number): Model?
	local src = ServerStorage:FindFirstChild("Props")
	local template = src and src:FindFirstChild(name)
	if not template or not template:IsA("Model") then
		return nil
	end
	local m = template:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local _, size = m:GetBoundingBox()
	local biggest = math.max(size.X, size.Z)
	if biggest > 0 then
		pcall(function()
			m:ScaleTo(m:GetScale() * targetSize / biggest)
		end)
	end
	m:PivotTo(cf)
	local bbCf, bbSize = m:GetBoundingBox()
	local bottom = bbCf.Position.Y - bbSize.Y / 2
	m:PivotTo(m:GetPivot() + Vector3.new(0, cf.Position.Y - bottom, 0))
	m.Parent = folder
	return m
end

---------------------------------------------------------------------
-- Builders
---------------------------------------------------------------------
function Props.microwave(cf: CFrame, s: number?)
	s = s or 1
	local m = custom("Microwave", cf, 6 * s)
	if m then
		return m, nil
	end
	m = newModel("Microwave")
	local c = cf * CFrame.new(0, 0, 0)
	box(m, c * CFrame.new(0, 2 * s, 0), Vector3.new(6, 4, 4) * s, Color3.fromRGB(215, 215, 220), Enum.Material.Metal)
	box(m, c * CFrame.new(-0.8 * s, 2 * s, -2.02 * s), Vector3.new(3.8, 3.2, 0.1) * s, Color3.fromRGB(20, 20, 25), Enum.Material.Glass, { Transparency = 0.25 })
	box(m, c * CFrame.new(1.25 * s, 2 * s, -2.03 * s), Vector3.new(0.15, 2.8, 0.2) * s, STEEL, Enum.Material.Metal) -- handle
	local panel = box(m, c * CFrame.new(2.2 * s, 2 * s, -2.02 * s), Vector3.new(1.4, 3.6, 0.1) * s, Color3.fromRGB(40, 40, 45))
	local display = box(m, c * CFrame.new(2.2 * s, 3.25 * s, -2.08 * s), Vector3.new(1.1, 0.5, 0.05) * s, BLACK)
	local label = screen(display, "10:00", Enum.NormalId.Front, BLACK, Color3.fromRGB(80, 255, 120))
	for row = 0, 3 do
		for col = 0, 2 do
			box(m, c * CFrame.new((1.85 + col * 0.35) * s, (2.6 - row * 0.4) * s, -2.08 * s), Vector3.new(0.25, 0.25, 0.05) * s, Color3.fromRGB(200, 200, 205))
		end
	end
	cyl(m, c * CFrame.new(-0.8 * s, 0.55 * s, 0), 0.1 * s, 3 * s, Color3.fromRGB(230, 230, 230), Enum.Material.Glass, { Transparency = 0.3 })
	local _ = panel
	return m, label
end

function Props.desk(cf: CFrame, withComputer: boolean?)
	local m = custom("Desk", cf, 7)
	if m then
		return m
	end
	m = newModel("Desk")
	box(m, cf * CFrame.new(0, 3.3, 0), Vector3.new(7, 0.3, 3.5), WOOD, Enum.Material.WoodPlanks)
	for _, x in ipairs({ -3.2, 3.2 }) do
		for _, z in ipairs({ -1.5, 1.5 }) do
			box(m, cf * CFrame.new(x, 1.6, z), Vector3.new(0.3, 3.2, 0.3), DARKWOOD, Enum.Material.Wood)
		end
	end
	box(m, cf * CFrame.new(2.2, 2.4, 0), Vector3.new(2, 1.6, 3.2), WOOD, Enum.Material.WoodPlanks) -- drawers
	box(m, cf * CFrame.new(2.2, 2.4, -1.62), Vector3.new(0.6, 0.12, 0.05), STEEL, Enum.Material.Metal)
	-- chair (behind the desk, facing it)
	box(m, cf * CFrame.new(0, 1.8, 2.8), Vector3.new(2, 0.3, 2), Color3.fromRGB(40, 40, 50), Enum.Material.Fabric)
	box(m, cf * CFrame.new(0, 3.1, 3.7), Vector3.new(2, 2.4, 0.3), Color3.fromRGB(40, 40, 50), Enum.Material.Fabric)
	cyl(m, cf * CFrame.new(0, 0.9, 2.8), 1.6, 0.3, BLACK, Enum.Material.Metal)
	cyl(m, cf * CFrame.new(0, 0.1, 2.8), 0.2, 1.8, BLACK, Enum.Material.Metal)
	if withComputer ~= false then
		box(m, cf * CFrame.new(-1, 3.6, 0.6), Vector3.new(0.6, 0.3, 0.5), BLACK)
		box(m, cf * CFrame.new(-1, 4.2, 0.7), Vector3.new(0.2, 1, 0.2), BLACK)
		local mon = box(m, cf * CFrame.new(-1, 5.1, 0.6), Vector3.new(3, 1.8, 0.15), BLACK)
		screen(mon, "C:\\>_", Enum.NormalId.Back, Color3.fromRGB(20, 60, 120), Color3.fromRGB(200, 230, 255))
		box(m, cf * CFrame.new(-1, 3.5, -0.6), Vector3.new(2.4, 0.1, 0.8), Color3.fromRGB(50, 50, 55))
	end
	return m
end

function Props.arcade(cf: CFrame, title: string)
	local m = custom("ArcadeMachine", cf, 4)
	if m then
		return m
	end
	m = newModel("ArcadeMachine")
	local body = Color3.fromRGB(40, 20, 70)
	box(m, cf * CFrame.new(0, 3.5, 0.3), Vector3.new(3.4, 7, 2.6), body)
	box(m, cf * CFrame.new(-1.75, 3.5, 0.3), Vector3.new(0.12, 7.1, 2.7), Color3.fromRGB(255, 60, 200), Enum.Material.Neon)
	box(m, cf * CFrame.new(1.75, 3.5, 0.3), Vector3.new(0.12, 7.1, 2.7), Color3.fromRGB(255, 60, 200), Enum.Material.Neon)
	local scr = box(m, cf * CFrame.new(0, 4.8, -1.05) * CFrame.Angles(math.rad(-12), 0, 0), Vector3.new(2.8, 2.2, 0.1), BLACK)
	screen(scr, "🎮 " .. title, Enum.NormalId.Front, Color3.fromRGB(10, 10, 40), Color3.fromRGB(255, 230, 80)).Font = Enum.Font.Arcade
	box(m, cf * CFrame.new(0, 3, -1.4), Vector3.new(3.2, 0.4, 1.2), Color3.fromRGB(30, 30, 35))
	cyl(m, cf * CFrame.new(-0.7, 3.4, -1.5), 0.6, 0.15, BLACK)
	ball(m, cf * CFrame.new(-0.7, 3.8, -1.5), 0.4, Color3.fromRGB(220, 30, 30))
	for i, col in ipairs({ Color3.fromRGB(255, 60, 60), Color3.fromRGB(60, 160, 255), Color3.fromRGB(255, 220, 60) }) do
		cyl(m, cf * CFrame.new(0.2 + i * 0.4, 3.25, -1.5), 0.15, 0.3, col)
	end
	local marquee = box(m, cf * CFrame.new(0, 7.3, -0.2), Vector3.new(3.4, 1, 1.4), BLACK)
	screen(marquee, title, Enum.NormalId.Front, Color3.fromRGB(255, 200, 0), Color3.fromRGB(40, 20, 70)).Font = Enum.Font.FredokaOne
	return m
end

function Props.newsstand(cf: CFrame)
	local m = custom("Newsstand", cf, 8)
	if m then
		return m
	end
	m = newModel("Newsstand")
	box(m, cf * CFrame.new(0, 1.8, 0), Vector3.new(8, 3.6, 3), Color3.fromRGB(30, 90, 60), Enum.Material.Metal)
	for _, x in ipairs({ -3.8, 3.8 }) do
		box(m, cf * CFrame.new(x, 4.5, 0.5), Vector3.new(0.3, 9, 0.3), Color3.fromRGB(30, 90, 60), Enum.Material.Metal)
	end
	box(m, cf * CFrame.new(0, 9.1, 0), Vector3.new(9, 0.4, 5), Color3.fromRGB(200, 40, 40), Enum.Material.Fabric)
	-- magazine rack on the front
	local covers = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 220, 60), Color3.fromRGB(120, 220, 120), Color3.fromRGB(240, 120, 240) }
	local headlines = { "SHOCKING!", "YOU WON'T BELIEVE", "BONKADOO?!", "FREE BRAIN", "😱 WOW" }
	for i = 1, 5 do
		local cover = box(m, cf * CFrame.new(-3.2 + i * 1.07, 5.5, 0.9) * CFrame.Angles(math.rad(-10), 0, 0), Vector3.new(0.9, 1.3, 0.08), covers[i], Enum.Material.SmoothPlastic)
		screen(cover, headlines[i], Enum.NormalId.Front, covers[i], Color3.new(1, 1, 1)).Font = Enum.Font.GothamBlack
	end
	for i = 1, 4 do
		box(m, cf * CFrame.new(-3 + i * 1.2, 3.75, -0.8), Vector3.new(1, 0.15, 1.4), Color3.fromRGB(235, 230, 220), Enum.Material.SmoothPlastic)
	end
	return m
end

function Props.phoneTable(cf: CFrame)
	local m = custom("PhoneDisplay", cf, 8)
	if m then
		return m
	end
	m = newModel("PhoneDisplay")
	box(m, cf * CFrame.new(0, 3, 0), Vector3.new(8, 0.3, 3.5), WHITE, Enum.Material.SmoothPlastic)
	box(m, cf * CFrame.new(0, 1.5, 0), Vector3.new(7.4, 3, 3), Color3.fromRGB(230, 230, 235), Enum.Material.SmoothPlastic)
	local emojis = { "🐱", "🕺", "🍜", "🦆", "🚀" }
	for i = 1, 5 do
		local stand = box(m, cf * CFrame.new(-3.6 + i * 1.2, 3.75, 0) * CFrame.Angles(math.rad(-20), 0, 0), Vector3.new(0.8, 1.5, 0.1), BLACK)
		screen(stand, emojis[i], Enum.NormalId.Front, Color3.fromRGB(math.random(60, 200), math.random(60, 200), 255), Color3.new(1, 1, 1))
	end
	return m
end

function Props.shopCounter(cf: CFrame, productColors: { Color3 }?)
	local m = custom("ShopCounter", cf, 9)
	if m then
		return m
	end
	m = newModel("ShopCounter")
	box(m, cf * CFrame.new(0, 1.8, 0), Vector3.new(9, 3.6, 2.6), Color3.fromRGB(240, 238, 230), Enum.Material.Marble)
	box(m, cf * CFrame.new(0, 3.65, 0), Vector3.new(9.4, 0.2, 3), DARKWOOD, Enum.Material.WoodPlanks)
	-- cash register
	box(m, cf * CFrame.new(2.5, 4.2, 0), Vector3.new(1.8, 0.9, 1.6), Color3.fromRGB(50, 50, 55))
	local reg = box(m, cf * CFrame.new(2.5, 5, 0.3) * CFrame.Angles(math.rad(-25), 0, 0), Vector3.new(1.4, 0.8, 0.1), BLACK)
	screen(reg, "$ 0.00", Enum.NormalId.Front, BLACK, Color3.fromRGB(100, 255, 120))
	-- shelves with products behind
	local colors = productColors or { Color3.fromRGB(230, 70, 70), Color3.fromRGB(70, 140, 230), Color3.fromRGB(250, 200, 50), Color3.fromRGB(90, 200, 120) }
	box(m, cf * CFrame.new(0, 4, 4), Vector3.new(9, 8, 1.2), WOOD, Enum.Material.WoodPlanks)
	for row = 0, 2 do
		box(m, cf * CFrame.new(0, 1.8 + row * 2.4, 3.3), Vector3.new(9, 0.2, 1.4), DARKWOOD, Enum.Material.Wood)
		for i = 0, 6 do
			box(m, cf * CFrame.new(-3.9 + i * 1.3, 2.5 + row * 2.4, 3.3), Vector3.new(0.9, 1.2, 0.8), colors[((i + row) % #colors) + 1], Enum.Material.SmoothPlastic)
		end
	end
	return m
end

function Props.bookshelf(cf: CFrame, width: number?)
	local w = width or 6
	local m = custom("Bookshelf", cf, w)
	if m then
		return m
	end
	m = newModel("Bookshelf")
	box(m, cf * CFrame.new(0, 4, 0.6), Vector3.new(w, 8, 0.2), DARKWOOD, Enum.Material.Wood)
	for _, x in ipairs({ -w / 2, w / 2 }) do
		box(m, cf * CFrame.new(x, 4, 0), Vector3.new(0.3, 8, 1.4), DARKWOOD, Enum.Material.Wood)
	end
	local bookColors = { Color3.fromRGB(150, 40, 40), Color3.fromRGB(40, 70, 140), Color3.fromRGB(40, 110, 60), Color3.fromRGB(180, 140, 40), Color3.fromRGB(90, 50, 110), Color3.fromRGB(200, 200, 190) }
	for row = 0, 3 do
		local y = 0.3 + row * 2
		box(m, cf * CFrame.new(0, y, 0), Vector3.new(w, 0.2, 1.4), DARKWOOD, Enum.Material.Wood)
		local x = -w / 2 + 0.3
		while x < w / 2 - 0.5 do
			local bw = 0.25 + math.random() * 0.25
			local bh = 1.2 + math.random() * 0.5
			box(m, cf * CFrame.new(x + bw / 2, y + 0.1 + bh / 2, 0), Vector3.new(bw, bh, 1), bookColors[math.random(1, #bookColors)], Enum.Material.Fabric)
			x += bw + 0.03
		end
	end
	return m
end

function Props.ticketBooth(cf: CFrame)
	local m = custom("TicketBooth", cf, 7)
	if m then
		return m
	end
	m = newModel("TicketBooth")
	box(m, cf * CFrame.new(0, 3.5, 0), Vector3.new(6, 7, 4), Color3.fromRGB(160, 30, 40), Enum.Material.Fabric)
	box(m, cf * CFrame.new(0, 4.2, -2.02), Vector3.new(3.5, 2.2, 0.1), Color3.fromRGB(180, 210, 230), Enum.Material.Glass, { Transparency = 0.4 })
	local top = box(m, cf * CFrame.new(0, 7.6, -0.5), Vector3.new(6.6, 1.2, 0.4), Color3.fromRGB(240, 200, 60), Enum.Material.Metal)
	screen(top, "🎟 TICKETS", Enum.NormalId.Front, Color3.fromRGB(240, 200, 60), Color3.fromRGB(120, 20, 30)).Font = Enum.Font.FredokaOne
	-- popcorn machine
	box(m, cf * CFrame.new(4.6, 1.5, 0), Vector3.new(2, 3, 2), Color3.fromRGB(200, 30, 30), Enum.Material.Metal)
	box(m, cf * CFrame.new(4.6, 4, 0), Vector3.new(2, 2, 2), Color3.fromRGB(230, 240, 250), Enum.Material.Glass, { Transparency = 0.5 })
	for _ = 1, 10 do
		ball(m, cf * CFrame.new(4.6 + (math.random() - 0.5) * 1.4, 3.3 + math.random() * 0.6, (math.random() - 0.5) * 1.4), 0.35, Color3.fromRGB(255, 240, 180))
	end
	return m
end

function Props.examDesk(cf: CFrame)
	local m = Props.desk(cf, false)
	box(m, cf * CFrame.new(-1, 3.48, 0), Vector3.new(1.2, 0.05, 1.6), WHITE)
	box(m, cf * CFrame.new(0, 3.5, 0.2) * CFrame.Angles(0, math.rad(30), 0), Vector3.new(0.1, 0.1, 1.2), Color3.fromRGB(240, 200, 40))
	local stand = box(m, cf * CFrame.new(0, 6.5, 0.9), Vector3.new(5, 2, 0.2), Color3.fromRGB(40, 40, 60))
	screen(stand, "📝 EXAM IN PROGRESS", Enum.NormalId.Front, Color3.fromRGB(40, 40, 60), Color3.fromRGB(255, 230, 120)).Font = Enum.Font.GothamBold
	return m
end

function Props.bulletinBoard(cf: CFrame)
	local m = custom("BulletinBoard", cf, 8)
	if m then
		return m
	end
	m = newModel("BulletinBoard")
	box(m, cf * CFrame.new(0, 4.5, 0), Vector3.new(8, 5, 0.3), Color3.fromRGB(170, 120, 70), Enum.Material.Fabric)
	box(m, cf * CFrame.new(0, 4.5, 0.1), Vector3.new(8.4, 5.4, 0.2), DARKWOOD, Enum.Material.Wood)
	for _, x in ipairs({ -3.8, 3.8 }) do
		box(m, cf * CFrame.new(x, 1.5, 0.1), Vector3.new(0.4, 3, 0.4), DARKWOOD, Enum.Material.Wood)
	end
	local notes = { "HIRING: CASHIER", "TEACHER WANTED", "LAB ASSISTANT", "LAWYER NEEDED", "DOCTOR 🩺", "OFFICE JOB" }
	for i, n in ipairs(notes) do
		local x = -2.7 + ((i - 1) % 3) * 2.7
		local y = 5.6 - math.floor((i - 1) / 3) * 2.2
		local paper = box(m, cf * CFrame.new(x, y, -0.2) * CFrame.Angles(0, 0, math.rad(math.random(-6, 6))), Vector3.new(2.2, 1.8, 0.05), Color3.fromRGB(250, 248, 235))
		screen(paper, n, Enum.NormalId.Front, Color3.fromRGB(250, 248, 235), Color3.fromRGB(40, 40, 40)).Font = Enum.Font.Gotham
	end
	return m
end

function Props.cafeCounter(cf: CFrame)
	local m = custom("CafeCounter", cf, 8)
	if m then
		return m
	end
	m = newModel("CafeCounter")
	box(m, cf * CFrame.new(0, 1.8, 0), Vector3.new(8, 3.6, 2.6), DARKWOOD, Enum.Material.WoodPlanks)
	box(m, cf * CFrame.new(0, 3.65, 0), Vector3.new(8.4, 0.2, 3), Color3.fromRGB(230, 225, 215), Enum.Material.Marble)
	-- espresso machine
	box(m, cf * CFrame.new(-2, 4.6, 0.4), Vector3.new(2.4, 1.8, 1.6), STEEL, Enum.Material.Metal)
	for i = 0, 1 do
		cyl(m, cf * CFrame.new(-2.5 + i, 3.95, -0.3), 0.5, 0.25, BLACK, Enum.Material.Metal)
	end
	-- cups
	for i = 0, 3 do
		cyl(m, cf * CFrame.new(1 + i * 0.6, 4, -0.5), 0.5, 0.4, WHITE, Enum.Material.SmoothPlastic)
	end
	-- coffee bean jar
	cyl(m, cf * CFrame.new(3.4, 4.3, 0.3), 1.1, 0.8, Color3.fromRGB(220, 230, 240), Enum.Material.Glass, { Transparency = 0.4 })
	for _ = 1, 8 do
		ball(m, cf * CFrame.new(3.4 + (math.random() - 0.5) * 0.4, 3.9 + math.random() * 0.4, 0.3 + (math.random() - 0.5) * 0.4), 0.18, Color3.fromRGB(70, 40, 20))
	end
	local menu = box(m, cf * CFrame.new(0, 8, 2.5), Vector3.new(6, 2.6, 0.2), BLACK)
	screen(menu, "☕ MENU\nEspresso • Latte • 60 Beans Special", Enum.NormalId.Front, Color3.fromRGB(30, 30, 30), WHITE).Font = Enum.Font.Gotham
	return m
end

function Props.birdFeeder(cf: CFrame)
	local m = newModel("BirdFeeder")
	cyl(m, cf * CFrame.new(0, 2.5, 0), 5, 0.3, DARKWOOD, Enum.Material.Wood)
	box(m, cf * CFrame.new(0, 5.1, 0), Vector3.new(3, 0.2, 3), WOOD, Enum.Material.WoodPlanks)
	for _ = 1, 10 do
		ball(m, cf * CFrame.new((math.random() - 0.5) * 2.6, 5.25, (math.random() - 0.5) * 2.6), 0.15, Color3.fromRGB(220, 190, 110))
	end
	-- pigeons on the ground
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local pcf = cf * CFrame.new(math.cos(a) * 3, 0, math.sin(a) * 3) * CFrame.Angles(0, -a, 0)
		box(m, pcf * CFrame.new(0, 0.5, 0), Vector3.new(0.6, 0.6, 1), Color3.fromRGB(140, 140, 150), Enum.Material.SmoothPlastic)
		ball(m, pcf * CFrame.new(0, 0.95, -0.5), 0.45, Color3.fromRGB(90, 110, 120))
		box(m, pcf * CFrame.new(0, 0.9, -0.8), Vector3.new(0.12, 0.1, 0.25), Color3.fromRGB(230, 170, 60))
	end
	return m
end

function Props.labBench(cf: CFrame)
	local m = custom("LabBench", cf, 8)
	if m then
		return m
	end
	m = newModel("LabBench")
	box(m, cf * CFrame.new(0, 1.7, 0), Vector3.new(8, 3.4, 3), WHITE, Enum.Material.SmoothPlastic)
	box(m, cf * CFrame.new(0, 3.5, 0), Vector3.new(8.2, 0.2, 3.2), BLACK, Enum.Material.Slate)
	local liquids = { Color3.fromRGB(90, 255, 160), Color3.fromRGB(255, 90, 200), Color3.fromRGB(90, 180, 255), Color3.fromRGB(255, 220, 80) }
	for i, col in ipairs(liquids) do
		cyl(m, cf * CFrame.new(-3 + i * 1.3, 4.3, -0.3), 1.4, 0.7, Color3.fromRGB(220, 235, 245), Enum.Material.Glass, { Transparency = 0.6 })
		cyl(m, cf * CFrame.new(-3 + i * 1.3, 4, -0.3), 0.7, 0.6, col, Enum.Material.Neon, { Transparency = 0.2 })
	end
	-- microscope
	box(m, cf * CFrame.new(3, 3.8, 0.6), Vector3.new(0.9, 0.3, 1.1), BLACK)
	box(m, cf * CFrame.new(3, 4.6, 0.9), Vector3.new(0.25, 1.5, 0.25), BLACK)
	cyl(m, cf * CFrame.new(3, 5, 0.5) * CFrame.Angles(math.rad(25), 0, 0), 1.1, 0.3, STEEL, Enum.Material.Metal)
	return m
end

function Props.hospitalBed(cf: CFrame)
	local m = custom("HospitalBed", cf, 9)
	if m then
		return m
	end
	m = newModel("HospitalBed")
	box(m, cf * CFrame.new(0, 2, 0), Vector3.new(4, 0.8, 8), Color3.fromRGB(235, 240, 255), Enum.Material.Fabric)
	box(m, cf * CFrame.new(0, 2.6, 3.2), Vector3.new(3, 0.6, 1.3), WHITE, Enum.Material.Fabric) -- pillow
	box(m, cf * CFrame.new(0, 2.5, 4.1), Vector3.new(4.2, 2.4, 0.3), STEEL, Enum.Material.Metal)
	for _, x in ipairs({ -1.8, 1.8 }) do
		for _, z in ipairs({ -3.6, 3.6 }) do
			box(m, cf * CFrame.new(x, 0.8, z), Vector3.new(0.2, 1.6, 0.2), STEEL, Enum.Material.Metal)
		end
	end
	box(m, cf * CFrame.new(2.6, 3.5, 3), Vector3.new(0.15, 7, 0.15), STEEL, Enum.Material.Metal) -- IV pole
	box(m, cf * CFrame.new(2.6, 6.3, 3), Vector3.new(0.6, 1, 0.3), Color3.fromRGB(220, 240, 255), Enum.Material.Glass, { Transparency = 0.4 })
	return m
end

function Props.cleaningCart(cf: CFrame)
	local m = newModel("CleaningCart")
	box(m, cf * CFrame.new(0, 2, 0), Vector3.new(3, 2.4, 2), Color3.fromRGB(240, 200, 40), Enum.Material.SmoothPlastic)
	cyl(m, cf * CFrame.new(-0.6, 3.6, 0), 1, 1, Color3.fromRGB(60, 120, 220), Enum.Material.SmoothPlastic) -- bucket
	box(m, cf * CFrame.new(0.9, 4.5, 0), Vector3.new(0.15, 5, 0.15), WOOD, Enum.Material.Wood) -- mop handle
	box(m, cf * CFrame.new(0.9, 2.1, 0), Vector3.new(0.9, 0.3, 0.6), Color3.fromRGB(230, 230, 220), Enum.Material.Fabric)
	for _, x in ipairs({ -1.2, 1.2 }) do
		for _, z in ipairs({ -0.8, 0.8 }) do
			ball(m, cf * CFrame.new(x, 0.35, z), 0.6, BLACK)
		end
	end
	return m
end

function Props.vending(cf: CFrame, label: string, color: Color3)
	local m = custom("VendingMachine", cf, 4)
	if m then
		return m
	end
	m = newModel("VendingMachine")
	box(m, cf * CFrame.new(0, 3.5, 0), Vector3.new(4, 7, 3), color, Enum.Material.Metal)
	box(m, cf * CFrame.new(-0.4, 4, -1.52), Vector3.new(2.8, 5, 0.1), Color3.fromRGB(200, 230, 255), Enum.Material.Glass, { Transparency = 0.45 })
	local snack = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 200, 255), Color3.fromRGB(255, 220, 60), Color3.fromRGB(120, 230, 120) }
	for row = 0, 3 do
		for col = 0, 3 do
			box(m, cf * CFrame.new(-1.4 + col * 0.65, 2.2 + row * 1.15, -1.2), Vector3.new(0.5, 0.7, 0.4), snack[((row + col) % 4) + 1])
		end
	end
	local panel = box(m, cf * CFrame.new(1.45, 4.5, -1.52), Vector3.new(0.8, 2.4, 0.1), BLACK)
	screen(panel, "R$", Enum.NormalId.Front, BLACK, Color3.fromRGB(80, 255, 120))
	local top = box(m, cf * CFrame.new(0, 7.4, -0.8), Vector3.new(4.2, 0.9, 0.3), Color3.fromRGB(255, 230, 40), Enum.Material.SmoothPlastic)
	screen(top, label, Enum.NormalId.Front, Color3.fromRGB(255, 230, 40), Color3.fromRGB(200, 0, 80)).Font = Enum.Font.FredokaOne
	return m
end

local CAR_COLORS = { Color3.fromRGB(190, 30, 35), Color3.fromRGB(30, 70, 170), Color3.fromRGB(235, 235, 235), Color3.fromRGB(30, 30, 35), Color3.fromRGB(230, 190, 40), Color3.fromRGB(70, 130, 90) }
function Props.car(cf: CFrame)
	local m = custom("Car", cf, 13)
	if m then
		-- 1.9.1 real models: every parked car gets its own paint (the model's red body parts are repainted)
		local paint = CAR_COLORS[math.random(1, #CAR_COLORS)]
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Color.R > 0.55 and d.Color.G < 0.35 and d.Color.B < 0.35 then
				d.Color = paint
			end
		end
		return m
	end
	m = newModel("Car")
	local color = CAR_COLORS[math.random(1, #CAR_COLORS)]
	box(m, cf * CFrame.new(0, 1.9, 0), Vector3.new(6, 1.8, 13), color, Enum.Material.Metal) -- lower body
	box(m, cf * CFrame.new(0, 3.4, 0.6), Vector3.new(5.6, 1.6, 6.5), color, Enum.Material.Metal) -- cabin
	box(m, cf * CFrame.new(0, 3.4, -2.75), Vector3.new(5.2, 1.4, 0.2), Color3.fromRGB(40, 50, 60), Enum.Material.Glass, { Transparency = 0.2 }) -- windshield
	box(m, cf * CFrame.new(0, 3.4, 3.9), Vector3.new(5.2, 1.3, 0.2), Color3.fromRGB(40, 50, 60), Enum.Material.Glass, { Transparency = 0.2 })
	for _, x in ipairs({ -2.82, 2.82 }) do
		box(m, cf * CFrame.new(x, 3.45, 0.6), Vector3.new(0.1, 1.2, 5.6), Color3.fromRGB(40, 50, 60), Enum.Material.Glass, { Transparency = 0.2 })
	end
	for _, x in ipairs({ -2.2, 2.2 }) do
		box(m, cf * CFrame.new(x, 2.1, -6.52), Vector3.new(1.1, 0.5, 0.1), Color3.fromRGB(255, 250, 220), Enum.Material.Neon) -- headlights
		box(m, cf * CFrame.new(x, 2.1, 6.52), Vector3.new(1.1, 0.4, 0.1), Color3.fromRGB(200, 20, 20), Enum.Material.Neon) -- taillights
	end
	box(m, cf * CFrame.new(0, 1.2, -6.6), Vector3.new(6.2, 0.6, 0.4), Color3.fromRGB(40, 40, 45)) -- bumpers
	box(m, cf * CFrame.new(0, 1.2, 6.6), Vector3.new(6.2, 0.6, 0.4), Color3.fromRGB(40, 40, 45))
	for _, x in ipairs({ -2.9, 2.9 }) do
		for _, z in ipairs({ -4, 4 }) do
			box(m, cf * CFrame.new(x, 1.15, z), Vector3.new(1, 2.3, 2.3), Color3.fromRGB(20, 20, 22), Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
			box(m, cf * CFrame.new(x + (x > 0 and 0.45 or -0.45), 1.15, z), Vector3.new(0.15, 1.2, 1.2), STEEL, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		end
	end
	return m
end

-- 1.9.1 real models: trees (two kinds, mixed) and street lamps. nil = no model, the caller builds blocks.
-- Only the trunk collides; the canopy is walk-through so trees on sidewalks never block anyone.
function Props.tree(pos: Vector3, s: number): Model?
	local name = (math.random() < 0.55) and "Tree1" or "Tree2"
	local m = custom(name, CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0), 13 * s)
	if not m then
		m = custom(name == "Tree1" and "Tree2" or "Tree1", CFrame.new(pos), 13 * s)
	end
	if m then
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CastShadow = true
				local bottom = d.Position.Y - d.Size.Y / 2
				if bottom > pos.Y + 3 then
					d.CanCollide = false
				end
				d.CanQuery = d.CanCollide
			end
		end
		CollectionService:AddTag(m, "RealModel")
	end
	return m
end

-- 1.9.1 real buildings for the closed filler lots: "House" (Gain side) or "Shop" (Lose side).
-- Picks one of ServerStorage > Props > House1, House2… / Shop1, Shop2… (weights in Config.Map.FillerWeights),
-- turns it so its front faces the street (FrontYaw attribute = the model's own front direction), fits it to the lot.
function Props.filler(kind: string, pos: Vector3, yaw: number, footprint: number): Model?
	local src = ServerStorage:FindFirstChild("Props")
	if not src then
		return nil
	end
	local pool, total = {}, 0
	local weights = (Config.Map.FillerWeights or {})
	for _, m in ipairs(src:GetChildren()) do
		if m:IsA("Model") and string.match(m.Name, "^" .. kind .. "%d+$") then
			local w = weights[m.Name] or 1
			table.insert(pool, { m = m, w = w })
			total += w
		end
	end
	if #pool == 0 then
		return nil
	end
	local r = math.random() * total
	local pick = pool[1].m
	for _, e in ipairs(pool) do
		r -= e.w
		if r <= 0 then
			pick = e.m
			break
		end
	end
	local m = custom(pick.Name, CFrame.new(pos) * CFrame.Angles(0, yaw + (pick:GetAttribute("FrontYaw") or 0), 0), footprint)
	if m then
		CollectionService:AddTag(m, "RealModel")
	end
	return m
end

function Props.streetLamp(pos: Vector3): Model?
	local m = custom("StreetLamp", CFrame.new(pos), 1.8)
	if m then
		CollectionService:AddTag(m, "RealModel")
	end
	return m
end

function Props.bench(cf: CFrame)
	local m = custom("Bench", cf, 7)
	if m then
		return m
	end
	m = newModel("Bench")
	for i = 0, 2 do
		box(m, cf * CFrame.new(0, 1.7, -0.6 + i * 0.6), Vector3.new(7, 0.2, 0.5), WOOD, Enum.Material.WoodPlanks)
	end
	for i = 0, 1 do
		box(m, cf * CFrame.new(0, 2.6 + i * 0.6, 1.1), Vector3.new(7, 0.45, 0.15), WOOD, Enum.Material.WoodPlanks)
	end
	for _, x in ipairs({ -3, 3 }) do
		box(m, cf * CFrame.new(x, 0.85, 0), Vector3.new(0.3, 1.7, 1.8), BLACK, Enum.Material.Metal)
		box(m, cf * CFrame.new(x, 2.4, 1.15), Vector3.new(0.3, 1.8, 0.2), BLACK, Enum.Material.Metal)
	end
	return m
end

return Props

-- HomeService (1.9.1, big ideas #4 + #5): your own home, and visiting other players' homes.
-- Homes are pocket rooms high above the town (one slot per player in this server), built when
-- someone goes in and removed when the owner leaves the game. The home grows with progress:
--   Gain: flat → house → penthouse (IQ)        Lose: cardboard box → messy room → pizza-box palace (lower brain)
--   Animals: a kennel
-- Furniture is bought with coins (price shown first, everything earnable) and saved as a small list
-- (data.homeItems). Visits are read-only: visitors can look at the trophy wall but can't change anything,
-- and the owner can close the door to visitors (data.homeClosed).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local Rooms = require(script.Parent.Rooms)

local HomeService = {}
local CH = Config.Homes
local TH = Content.Homes

local folder = Instance.new("Folder")
folder.Name = "Homes"
folder.Parent = workspace

local slots = {} -- [userId] = slot number
local built = {} -- [userId] = { model, cf, tier, sig }
local nextSlot = 1

local function slotOf(userId: number): number
	if not slots[userId] then
		slots[userId] = nextSlot
		nextSlot += 1
	end
	return slots[userId]
end

-- which home this player has right now
function HomeService.tierOf(player: Player): string
	local data = DataService.get(player)
	if not data then
		return "flat"
	end
	if Rooms.isAnimal(player) then
		return "kennel"
	end
	local cells = data.cells or 0
	if data.path == "Lose" then
		if cells <= CH.LosePalaceBelow then
			return "palace"
		elseif cells <= CH.LoseRoomBelow then
			return "messy"
		end
		return "box"
	end
	local iq = Brain.iq(cells)
	if iq >= CH.PenthouseIQ then
		return "penthouse"
	elseif iq >= CH.HouseIQ then
		return "house"
	end
	return "flat"
end

local function owned(data): { string }
	return typeof(data.homeItems) == "table" and data.homeItems or {}
end

local function has(data, key: string): boolean
	for _, k in ipairs(owned(data)) do
		if k == key then
			return true
		end
	end
	return false
end

local function part(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, extra)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
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

local function sign(p: BasePart, text: string, face: Enum.NormalId?, color: Color3?)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.TextWrapped = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Text = text
	l.Parent = g
	return l
end

-- one simple piece of furniture (a few blocks) at cf
local BUILD = {}
function BUILD.bed(m, cf)
	part(m, cf * CFrame.new(0, 1, 0), Vector3.new(5, 2, 8), Color3.fromRGB(120, 80, 50), Enum.Material.Wood)
	part(m, cf * CFrame.new(0, 2.2, 0.5), Vector3.new(4.6, 0.6, 7), Color3.fromRGB(90, 130, 220), Enum.Material.Fabric)
	part(m, cf * CFrame.new(0, 2.6, -3), Vector3.new(4, 0.6, 1.4), Color3.fromRGB(250, 250, 250), Enum.Material.Fabric)
end
function BUILD.sofa(m, cf)
	part(m, cf * CFrame.new(0, 1, 0), Vector3.new(8, 2, 3), Color3.fromRGB(190, 80, 70), Enum.Material.Fabric)
	part(m, cf * CFrame.new(0, 2.5, 1.2), Vector3.new(8, 3, 0.8), Color3.fromRGB(170, 70, 60), Enum.Material.Fabric)
end
function BUILD.tv(m, cf)
	part(m, cf * CFrame.new(0, 1, 0), Vector3.new(6, 2, 2), Color3.fromRGB(80, 60, 45), Enum.Material.Wood)
	local s = part(m, cf * CFrame.new(0, 4, 0), Vector3.new(6, 3.4, 0.3), Color3.fromRGB(20, 20, 25))
	sign(s, "📺", Enum.NormalId.Back)
end
function BUILD.bookshelf(m, cf)
	part(m, cf * CFrame.new(0, 3.5, 0), Vector3.new(6, 7, 1.6), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
	local colors = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 120, 200), Color3.fromRGB(60, 170, 90), Color3.fromRGB(230, 190, 60) }
	for row = 0, 2 do
		for i = 0, 4 do
			part(m, cf * CFrame.new(-2.2 + i * 1.1, 1.3 + row * 2.2, -0.5), Vector3.new(0.8, 1.6, 0.6), colors[(i + row) % 4 + 1])
		end
	end
end
function BUILD.desk(m, cf)
	part(m, cf * CFrame.new(0, 1.6, 0), Vector3.new(6, 0.4, 3), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
	part(m, cf * CFrame.new(-2.6, 0.7, 0), Vector3.new(0.4, 1.4, 2.6), Color3.fromRGB(120, 85, 55))
	part(m, cf * CFrame.new(2.6, 0.7, 0), Vector3.new(0.4, 1.4, 2.6), Color3.fromRGB(120, 85, 55))
	local s = part(m, cf * CFrame.new(0, 3, 0.6), Vector3.new(2.6, 1.8, 0.2), Color3.fromRGB(30, 30, 35))
	sign(s, "💻", Enum.NormalId.Front, Color3.fromRGB(120, 200, 255))
end
function BUILD.plant(m, cf)
	part(m, cf * CFrame.new(0, 0.9, 0), Vector3.new(1.8, 1.8, 1.8), Color3.fromRGB(170, 100, 60), Enum.Material.Slate)
	part(m, cf * CFrame.new(0, 3, 0), Vector3.new(3, 3, 3), Color3.fromRGB(70, 150, 70), Enum.Material.Grass, { Shape = Enum.PartType.Ball })
end
function BUILD.rug(m, cf)
	part(m, cf * CFrame.new(0, 0.08, 0), Vector3.new(10, 0.15, 7), Color3.fromRGB(150, 60, 90), Enum.Material.Fabric)
end
function BUILD.lamp(m, cf)
	part(m, cf * CFrame.new(0, 2.5, 0), Vector3.new(0.4, 5, 0.4), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	local shade = part(m, cf * CFrame.new(0, 5.3, 0), Vector3.new(1.8, 1.2, 1.8), Color3.fromRGB(255, 235, 180), Enum.Material.Neon)
	local l = Instance.new("PointLight")
	l.Range = 16
	l.Brightness = 1.2
	l.Color = Color3.fromRGB(255, 220, 170)
	l.Parent = shade
end
function BUILD.fishtank(m, cf)
	part(m, cf * CFrame.new(0, 1, 0), Vector3.new(5, 2, 2), Color3.fromRGB(60, 60, 70))
	part(m, cf * CFrame.new(0, 3, 0), Vector3.new(5, 2.4, 2), Color3.fromRGB(80, 170, 230), Enum.Material.Glass, { Transparency = 0.4 })
	part(m, cf * CFrame.new(-1, 3, 0), Vector3.new(0.7, 0.5, 0.3), Color3.fromRGB(255, 150, 40), Enum.Material.Neon)
end
function BUILD.piano(m, cf)
	part(m, cf * CFrame.new(0, 2, 0), Vector3.new(6, 4, 2.4), Color3.fromRGB(25, 25, 30))
	part(m, cf * CFrame.new(0, 2.6, -1.4), Vector3.new(5.6, 0.3, 0.8), Color3.fromRGB(245, 245, 245))
end
function BUILD.gamingchair(m, cf)
	part(m, cf * CFrame.new(0, 1.4, 0), Vector3.new(2.6, 0.6, 2.6), Color3.fromRGB(230, 40, 120))
	part(m, cf * CFrame.new(0, 3.2, 1.1), Vector3.new(2.6, 3.4, 0.5), Color3.fromRGB(40, 230, 200), Enum.Material.Neon)
end
function BUILD.pizzatower(m, cf)
	for i = 0, 7 do
		part(m, cf * CFrame.new(0, 0.25 + i * 0.5, 0) * CFrame.Angles(0, i * 0.3, 0), Vector3.new(3, 0.45, 3), Color3.fromRGB(205, 160, 100), Enum.Material.Cardboard)
	end
end
function BUILD.beanbag(m, cf)
	part(m, cf * CFrame.new(0, 1.2, 0), Vector3.new(3.4, 2.4, 3.4), Color3.fromRGB(255, 200, 40), Enum.Material.Fabric, { Shape = Enum.PartType.Ball })
end

-- room shell: floor, walls (no gaps), ceiling, a door with a Leave prompt, the owner's name, the trophy wall
local function shell(m, cf: CFrame, size: Vector3, style)
	local w, d, h = size.X, size.Z, size.Y
	part(m, cf * CFrame.new(0, -0.5, 0), Vector3.new(w, 1, d), style.floor, style.floorMat)
	part(m, cf * CFrame.new(0, h + 0.5, 0), Vector3.new(w, 1, d), style.ceiling or style.wall, style.wallMat)
	part(m, cf * CFrame.new(0, h / 2, d / 2 + 0.5), Vector3.new(w + 2, h, 1), style.wall, style.wallMat)
	part(m, cf * CFrame.new(0, h / 2, -d / 2 - 0.5), Vector3.new(w + 2, h, 1), style.wall, style.wallMat)
	part(m, cf * CFrame.new(w / 2 + 0.5, h / 2, 0), Vector3.new(1, h, d), style.wall, style.wallMat)
	part(m, cf * CFrame.new(-w / 2 - 0.5, h / 2, 0), Vector3.new(1, h, d), style.wall, style.wallMat)
	local light = part(m, cf * CFrame.new(0, h - 0.2, 0), Vector3.new(4, 0.3, 4), Color3.fromRGB(255, 245, 220), Enum.Material.Neon, { CanCollide = false })
	local pl = Instance.new("PointLight")
	pl.Range = math.max(w, d)
	pl.Brightness = 1.4
	pl.Color = Color3.fromRGB(255, 230, 190)
	pl.Parent = light
	if style.window then
		local win = part(m, cf * CFrame.new(0, h / 2 + 1, d / 2 - 0.05), Vector3.new(w * 0.6, h * 0.45, 0.2), Color3.fromRGB(120, 170, 230), Enum.Material.Glass, { Transparency = 0.2, CanCollide = false })
		sign(win, "🌆", Enum.NormalId.Front, Color3.fromRGB(255, 220, 160))
	end
end

local function build(owner: Player)
	local data = DataService.get(owner)
	if not data then
		return nil
	end
	local tier = HomeService.tierOf(owner)
	local style = CH.Tiers[tier]
	local sig = tier .. "|" .. table.concat(owned(data), ",") .. "|" .. tostring(#(data.badges or {}))
	local old = built[owner.UserId]
	if old and old.sig == sig and old.model.Parent then
		return old
	end
	local slot = slotOf(owner.UserId)
	local cf = CFrame.new(CH.Origin + Vector3.new((slot - 1) * CH.SlotSpacing, 0, 0))
	local m = Instance.new("Model")
	m.Name = "Home_" .. owner.UserId
	local size = style.size
	shell(m, cf, size, style)
	-- the door you came in by (front wall, -Z) with a Leave prompt
	local door = part(m, cf * CFrame.new(0, 3.5, -size.Z / 2 + 0.2), Vector3.new(4, 7, 0.4), Color3.fromRGB(120, 80, 50), Enum.Material.Wood, { CanCollide = false })
	door.Name = "HomeDoor"
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = TH.Leave
	pp.ObjectText = TH.Door
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.Parent = door
	pp.Triggered:Connect(function(p)
		WorldService.teleport(p, "lobby")
	end)
	-- the owner's name and the tier, over the door (inside)
	local nameBoard = part(m, cf * CFrame.new(0, size.Y - 1.6, -size.Z / 2 + 0.1), Vector3.new(math.min(size.X - 2, 18), 2, 0.2), style.accent)
	sign(nameBoard, string.format(TH.NameSign, owner.DisplayName, TH.Tiers[tier]), Enum.NormalId.Back)
	-- trophy wall: badges, inventions, photo album, job (read-only, for visitors too)
	local inventions = 0
	for _ in pairs(typeof(data.inventions) == "table" and data.inventions or {}) do
		inventions += 1
	end
	local photos = typeof(data.eventsDone) == "table" and #data.eventsDone or 0
	local badges = 0
	for _ in pairs(typeof(data.badges) == "table" and data.badges or {}) do
		badges += 1
	end
	local trophy = part(m, cf * CFrame.new(-size.X / 2 + 0.15, 5, 0), Vector3.new(0.2, 5, math.min(size.Z - 4, 14)), Color3.fromRGB(40, 44, 60))
	sign(trophy, string.format(TH.Trophies, badges, inventions, photos), Enum.NormalId.Right, Color3.fromRGB(255, 220, 120))
	-- furniture: each owned item has a fixed spot in the room (fractions of the room size)
	for _, key in ipairs(owned(data)) do
		local f = CH.Furniture[key]
		local fn = BUILD[key]
		if f and fn then
			local at = cf * CFrame.new(f.spot[1] * size.X / 2, 0, f.spot[2] * size.Z / 2) * CFrame.Angles(0, math.rad(f.spot[3] or 0), 0)
			pcall(fn, m, at)
		end
	end
	-- Lose homes are messy on purpose: free pizza boxes on the floor
	if style.mess then
		for i = 1, style.mess do
			local x = ((i * 37) % 100) / 100 - 0.5
			local z = ((i * 61) % 100) / 100 - 0.5
			part(m, cf * CFrame.new(x * size.X * 0.8, 0.2, z * size.Z * 0.8) * CFrame.Angles(0, i, 0), Vector3.new(2.6, 0.35, 2.6), Color3.fromRGB(205, 160, 100), Enum.Material.Cardboard)
		end
	end
	m.Parent = folder
	if old and old.model then
		old.model:Destroy()
	end
	local rec = { model = m, cf = cf, tier = tier, sig = sig, size = size }
	built[owner.UserId] = rec
	return rec
end

local function goInto(player: Player, owner: Player): boolean
	local rec = build(owner)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not rec or not char or not hum or hum.Health <= 0 then
		return false
	end
	Rooms.standUp(hum)
	char:PivotTo(rec.cf * CFrame.new(0, 3, -rec.size.Z / 2 + 5))
	return true
end

-- what the 🏠 Home app shows
Net.on("home_get", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local tier = HomeService.tierOf(player)
	local catalog = {}
	for _, key in ipairs(CH.Order) do
		local f = CH.Furniture[key]
		if f.path == nil or f.path == data.path then
			table.insert(catalog, { key = key, icon = TH.Furniture[key].icon, name = TH.Furniture[key].name, price = f.price, owned = has(data, key) })
		end
	end
	local others = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataService.get(p)
		if p ~= player and d and d.path then
			table.insert(others, { id = p.UserId, name = p.DisplayName, tier = TH.Tiers[HomeService.tierOf(p)], closed = d.homeClosed == true })
		end
	end
	return { ok = true, tier = TH.Tiers[tier], tierKey = tier, coins = data.coins or 0, catalog = catalog, others = others, closed = data.homeClosed == true }
end)

Net.on("home_go", function(player)
	local data = DataService.get(player)
	if not data or not data.path then
		return { ok = false, msg = TH.PickPath }
	end
	if BrainService.blocked(player) then
		return { ok = false, msg = "⛔ " .. BrainService.blocked(player) }
	end
	return { ok = goInto(player, player) }
end)

Net.on("home_buy", function(player, d)
	local data = DataService.get(player)
	local key = typeof(d) == "table" and tostring(d.key) or ""
	local f = CH.Furniture[key]
	if not data or not f then
		return { ok = false }
	end
	if f.path and f.path ~= data.path then
		return { ok = false, msg = TH.WrongPath }
	end
	if has(data, key) then
		return { ok = false, msg = TH.Owned }
	end
	if (data.coins or 0) < f.price then
		return { ok = false, msg = string.format(TH.Poor, f.price) }
	end
	data.coins -= f.price
	local list = owned(data)
	table.insert(list, key)
	data.homeItems = list
	BrainService.push(player)
	if built[player.UserId] then
		build(player) -- show it right away if the home is built
	end
	return { ok = true, msg = string.format(TH.Bought, TH.Furniture[key].icon, TH.Furniture[key].name, f.price) }
end)

local lastVisit = {} -- 1.9.3 audit: no flooding someone with "X is visiting" toasts
Net.on("home_visit", function(player, d)
	if (lastVisit[player] or 0) > os.clock() then
		return { ok = false, msg = "⏳ One moment…" }
	end
	lastVisit[player] = os.clock() + 10
	local id = typeof(d) == "table" and tonumber(d.id) or nil
	local owner = id and Players:GetPlayerByUserId(id)
	local od = owner and DataService.get(owner)
	if not owner or not od or owner == player then
		return { ok = false, msg = TH.Gone }
	end
	if od.homeClosed then
		return { ok = false, msg = string.format(TH.Closed, owner.DisplayName) }
	end
	if BrainService.blocked(player) then
		return { ok = false, msg = "⛔ " .. BrainService.blocked(player) }
	end
	if goInto(player, owner) then
		BrainService.toast(owner, string.format(TH.Visiting, player.DisplayName), "NotificationPing")
		return { ok = true, msg = string.format(TH.Welcome, owner.DisplayName) }
	end
	return { ok = false }
end)

Net.on("home_door", function(player, d)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	data.homeClosed = typeof(d) == "table" and d.closed == true or nil
	return { ok = true, closed = data.homeClosed == true }
end)

Players.PlayerRemoving:Connect(function(player)
	local rec = built[player.UserId]
	built[player.UserId] = nil
	if rec and rec.model then
		-- anyone still visiting goes back to the plaza first
		for _, p in ipairs(Players:GetPlayers()) do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if root and p ~= player then
				local rel = rec.cf:PointToObjectSpace(root.Position)
				if math.abs(rel.X) < rec.size.X / 2 + 2 and math.abs(rel.Z) < rec.size.Z / 2 + 2 and rel.Y > -5 and rel.Y < rec.size.Y + 5 then
					WorldService.teleport(p, "lobby")
				end
			end
		end
		rec.model:Destroy()
	end
end)

return HomeService

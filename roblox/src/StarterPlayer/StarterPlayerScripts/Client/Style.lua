-- Style: makes the world look like YOUR brain (on your screen only).
-- 1.9: one art style per brain level from Config.Styles (storybook, textured, realistic,
-- future, toon, lowpoly); see the ART STYLES block below.
-- Also: music, brain weather, dumb pets and your NPC friends.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Brain = require(Shared.Brain)

local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local Style = {}

local originals = {} -- [part] = { Color, Material }
local moneyTags = {} -- [part] = BillboardGui
local currentTier = nil
local currentCells = Config.AverageCells

local CASHGRAB_COLORS = {
	Color3.fromRGB(255, 50, 200),
	Color3.fromRGB(0, 255, 120),
	Color3.fromRGB(255, 230, 0),
	Color3.fromRGB(0, 200, 255),
	Color3.fromRGB(255, 120, 0),
}

local function remember(part: BasePart)
	if not originals[part] then
		originals[part] = { part.Color, part.Material }
	end
end

local function hashColor(part: BasePart): Color3
	local n = #part.Name + math.floor(part.Position.X + part.Position.Z)
	return CASHGRAB_COLORS[(n % #CASHGRAB_COLORS) + 1]
end

local function moneyTag(part: BasePart, enabled: boolean)
	local tag = moneyTags[part]
	if not tag and enabled then
		tag = Instance.new("BillboardGui")
		tag.Size = UDim2.new(5, 0, 1.4, 0)
		tag.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 1.5, 0)
		tag.AlwaysOnTop = false
		tag.MaxDistance = 90
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = Color3.fromRGB(80, 255, 80)
		l.TextStrokeTransparency = 0
		l.Text = "$" .. math.random(1, 999) .. "K/s 🔥"
		l.Parent = tag
		tag.Adornee = part
		tag.Parent = player:WaitForChild("PlayerGui")
		moneyTags[part] = tag
	end
	if tag then
		tag.Enabled = enabled
	end
end

-- 1.9: ART STYLES per brain level, all from ONE table: Config.Styles.List (see CLAUDE.md "Art style").
--   storybook = 5 Cozy storybook (lobby, start, IQ ~80-100)
--   textured  = 2 Semi-real textured (Gain IQ 100-135)
--   realistic = 3 Realistic in warm colours (Gain IQ 135+), future = + futuristic accents (200+)
--   toon      = 4 Toon with outlines (Lose 86B-45B)
--   lowpoly   = 6 Desaturated low-poly (below 45B, animals)
-- The old "look" (cozycash/cashgrab/nonsense/...) still drives the cash-grab overlays,
-- the music and the UI theme; the STYLE drives materials, colours, decor and light.
-- Low detail (Settings → 🥔) = the current style simplified: smooth plastic, no outlines, no decor.
local STYLES = Config.Styles.List
local currentStyle = nil
local lowDetail = false

function Style.pick(st): string
	local S = Config.Styles
	local cells = st.cells or Config.AverageCells
	if cells < S.LowPolyBelow then
		return "lowpoly"
	end
	if st.path == "Gain" then
		local iq = st.iq or 100
		if iq >= S.GainFuture then
			return "future"
		elseif iq >= S.GainRealistic then
			return "realistic"
		elseif iq >= S.GainTextured then
			return "textured"
		end
		return "storybook"
	end
	if st.path == "Lose" and cells < S.LoseToonBelow then
		return "toon"
	end
	return "storybook"
end

local function pick(list, part: BasePart)
	local n = #part.Name + math.floor(math.abs(part.Position.X) * 0.37 + math.abs(part.Position.Z) * 0.61)
	return list[(n % #list) + 1], n
end

-- the colour a wall gets is picked per BUILDING (its model), so one house is one colour
local function anchorFor(part: BasePart): BasePart
	local m = part.Parent
	if m and m:IsA("Model") and m ~= workspace then
		local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		if pp then
			return pp
		end
	end
	return part
end

local function desaturate(c: Color3, amount: number): Color3
	if amount <= 0 then
		return c
	end
	local grey = c.R * 0.3 + c.G * 0.59 + c.B * 0.11
	return c:Lerp(Color3.new(grey, grey, grey), amount)
end

local function slotFor(part: BasePart, role: string, orig): string?
	if part.Name == "Road" then
		return "road"
	elseif part.Name == "Sidewalk" or part.Name == "ParkPath" then
		return "sidewalk"
	elseif role == "nature" then
		return part.Shape == Enum.PartType.Ball and "leaves" or "trunk"
	elseif role == "prop" then
		return nil
	elseif orig[2] == Enum.Material.RoofShingles then
		return "roof"
	elseif role == "wall" then
		return "wall"
	elseif role == "floor" then
		return part.Name == "Grass" and nil or "floor"
	elseif role == "trim" then
		return "trim"
	end
	return "accent" -- accent + cashgrab
end

local function stylePart(part: BasePart, look: string, styleName: string)
	remember(part)
	local role = part:GetAttribute("Role") or "accent"
	local orig = originals[part]
	local s = STYLES[styleName] or STYLES.storybook
	local slot = slotFor(part, role, orig)
	local mat, color = orig[2], orig[1]
	local rule = slot and s[slot]
	if rule then
		local target, n = pick(rule.P, slot == "wall" and anchorFor(part) or part)
		color = orig[1]:Lerp(target, rule.A or 0)
		mat = rule.M or orig[2]
		if slot == "wall" then
			-- storybook/textured: every Nth house is plaster instead of brick; realistic: every Nth is glass-fronted
			if rule.plasterEvery and n % rule.plasterEvery == 0 then
				mat = Enum.Material.Plaster
			elseif rule.glassEvery and n % rule.glassEvery == 0 and part.Size.Y > 10 then
				mat = Enum.Material.Glass
				color = color:Lerp(Color3.fromRGB(140, 170, 190), 0.4)
			end
		end
	end
	if slot then
		color = desaturate(color, s.desaturate or 0)
	end
	if lowDetail and role ~= "prop" then
		mat = Enum.Material.SmoothPlastic
	end
	-- cash-grab overlay (Lose 45-86B and the lobby): loud accents on top of the style
	if (look == "cashgrab" or look == "cozycash") and (role == "accent" or role == "cashgrab") then
		mat = Enum.Material.SmoothPlastic
		color = hashColor(part)
	end
	part.Material = mat
	part.Color = color
	local money = (look == "cashgrab" or look == "cozycash") and role == "accent" and math.random() < 0.35
	moneyTag(part, money and not lowDetail)
end

local function styleSign(label: TextLabel, look: string, styleName: string)
	local base = label:GetAttribute("BaseText") or label.Text
	local text = Brain.degradeText(base, currentCells, UI.effects())
	local sg = (STYLES[styleName] or STYLES.storybook).sign
	label.Font = sg.font
	label.TextColor3 = sg.color
	label.TextStrokeColor3 = sg.stroke
	label.TextStrokeTransparency = sg.strokeT
	if look == "cashgrab" or look == "cozycash" then
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.fromRGB(255, 235, 60)
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0
		text = "🔥 " .. text .. " 🔥"
	end
	label.Text = text
end

local function applyLighting(styleName: string)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	local cc = Lighting:FindFirstChild("BrainCC")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "BrainCC"
		cc.Parent = Lighting
	end
	local L = (STYLES[styleName] or STYLES.storybook).light
	-- (shadows on/off belong to LowGraphics.lua, which remembers and restores them)
	-- 1.7.3 (user feedback "too dark and grey"): clear sky-blue air instead of grey fog
	atmosphere.Color = Color3.fromRGB(200, 222, 245)
	atmosphere.Decay = Color3.fromRGB(120, 150, 190)
	atmosphere.Glare = 0
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 145, 135)
	Lighting.ExposureCompensation = 0.15
	cc.Brightness = 0.03
	-- soft light for storybook/toon/low-poly, sharp light for the smart styles
	-- (game scripts can't change Lighting.LightingStyle, so this uses settings they can change)
	for prop, value in pairs(L.sharp and Config.Map.SharpLight or Config.Map.SoftLight) do
		local ok, err = pcall(function()
			Lighting[prop] = value
		end)
		if not ok then
			warn("[Style] lighting " .. prop .. ": " .. tostring(err))
		end
	end
	Lighting.ClockTime = L.clock
	Lighting.Brightness = L.brightness
	Lighting.Ambient = L.ambient
	atmosphere.Density = L.density
	atmosphere.Haze = L.haze
	cc.Saturation = L.sat
	cc.Contrast = L.contrast
	cc.TintColor = L.tint
	Lighting:SetAttribute("LookClock", Lighting.ClockTime) -- 1.8.1: "Always day" goes back to the style's own time
end

local function applyCashGrabParts(look: string)
	local cheap = look == "cashgrab" or look == "nonsense" or look == "cozycash"
	local hidden = look == "fancy" or look == "future"
	for _, p in ipairs(CollectionService:GetTagged("CashGrabOnly")) do
		if p:IsA("BasePart") then
			if p:GetAttribute("OrigT") == nil then
				p:SetAttribute("OrigT", p.Transparency)
				p:SetAttribute("OrigC", p.CanCollide)
			end
			p.Transparency = hidden and 1 or p:GetAttribute("OrigT")
			p.CanCollide = (not hidden) and p:GetAttribute("OrigC")
			local pp = p:FindFirstChildOfClass("ProximityPrompt")
			if pp then
				pp.Enabled = not hidden
			end
			for _, g in ipairs(p:GetChildren()) do
				if g:IsA("BillboardGui") then
					g.Enabled = not hidden
				end
			end
		end
	end
	for _, l in ipairs(CollectionService:GetTagged("Disclaimer")) do
		if l:IsA("TextLabel") then
			l.Visible = not cheap
		end
	end
end

-- Toon outlines: a black outline Highlight on the nearest buildings (Roblox draws at most 31 at once)
local outlineFolder = Instance.new("Folder")
outlineFolder.Name = "ToonOutlines"
local outlineModels = nil -- list of building models (found once)
local outlineOn = false

local function buildingModels()
	if outlineModels then
		return outlineModels
	end
	local seen, list = {}, {}
	for _, p in ipairs(CollectionService:GetTagged("Styled")) do
		if p:IsA("BasePart") and p:GetAttribute("Role") == "wall" then
			local m = p.Parent
			if m and m:IsA("Model") and not seen[m] then
				seen[m] = true
				table.insert(list, m)
			end
		end
	end
	if #list > 0 then
		outlineModels = list -- found once the town exists
	end
	return list
end

local function refreshOutlines()
	if not outlineOn then
		outlineFolder:ClearAllChildren()
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local here = cam.CFrame.Position
	local list = {}
	for _, m in ipairs(buildingModels()) do
		if m.Parent then
			local ok, pivot = pcall(m.GetPivot, m)
			if ok then
				table.insert(list, { m = m, d = (pivot.Position - here).Magnitude })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.d < b.d
	end)
	local want = {}
	for i = 1, math.min(Config.Styles.OutlineBuildings, #list) do
		want[list[i].m] = true
	end
	for _, h in ipairs(outlineFolder:GetChildren()) do
		if not want[h.Adornee] then
			h:Destroy()
		else
			want[h.Adornee] = nil
		end
	end
	for m in pairs(want) do
		local h = Instance.new("Highlight")
		h.Adornee = m
		h.FillTransparency = 1
		h.OutlineColor = Color3.new(0, 0, 0)
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = outlineFolder
	end
end

task.spawn(function()
	outlineFolder.Parent = workspace
	while true do
		task.wait(Config.Styles.OutlineEvery)
		refreshOutlines()
	end
end)

-- Little decorations outside every building, only on your screen:
-- storybook = flower boxes and bushes, textured/realistic = planters with topiary + lamps, future = + cyan lamps
local decorFolder = nil
local function applyDecor(styleName: string)
	if decorFolder then
		decorFolder:Destroy()
		decorFolder = nil
	end
	local kind = (STYLES[styleName] or {}).decor
	if not kind or lowDetail then
		return
	end
	decorFolder = Instance.new("Folder")
	decorFolder.Name = "LocalDecor"
	local function p(cf, size, color, material, shape)
		local d = Instance.new("Part")
		d.Name = "Decor"
		d.Anchored = true
		d.CanCollide = false
		d.CanQuery = false
		d.CastShadow = false
		d.CFrame = cf
		d.Size = size
		d.Color = color
		d.Material = material or Enum.Material.SmoothPlastic
		if shape then
			d.Shape = shape
		end
		d.Parent = decorFolder
	end
	local FLOWERS = { Color3.fromRGB(230, 70, 80), Color3.fromRGB(255, 200, 60), Color3.fromRGB(240, 130, 180), Color3.fromRGB(250, 250, 245) }
	for _, label in ipairs(CollectionService:GetTagged("Sign")) do
		local gui = label.Parent
		local board = gui and gui:IsA("SurfaceGui") and gui.Parent
		if board and board:IsA("BasePart") and board.Size.X >= 6 and board.Position.Y > 8 then
			for _, side in ipairs({ -1, 1 }) do
				local base = board.CFrame * CFrame.new(side * (board.Size.X / 2 + 1.5), 0, -2.5)
				local ground = CFrame.new(base.Position.X, 1.2, base.Position.Z) * board.CFrame.Rotation
				if kind == "planters" or kind == "future" then
					p(ground * CFrame.new(0, 0.9, 0), Vector3.new(2.4, 1.8, 2.4), Color3.fromRGB(70, 50, 35), Enum.Material.WoodPlanks)
					p(ground * CFrame.new(0, 3, 0), Vector3.new(2.6, 2.6, 2.6), Color3.fromRGB(50, 110, 55), Enum.Material.LeafyGrass, Enum.PartType.Ball)
					p(ground * CFrame.new(side * 2.2, 3.5, 0), Vector3.new(0.3, 7, 0.3), Color3.fromRGB(30, 30, 35), Enum.Material.Metal)
					p(ground * CFrame.new(side * 2.2, 7.2, 0), Vector3.new(0.8, 0.8, 0.8), kind == "future" and Color3.fromRGB(150, 240, 255) or Color3.fromRGB(255, 225, 160), Enum.Material.Neon)
				else -- storybook flower box under the sign + a round bush
					p(board.CFrame * CFrame.new(side * (board.Size.X / 4), -board.Size.Y / 2 - 0.6, -0.8), Vector3.new(board.Size.X / 2.4, 0.8, 1.2), Color3.fromRGB(120, 75, 45), Enum.Material.Wood)
					for i = 1, 4 do
						local x = side * (board.Size.X / 4) + (i - 2.5) * (board.Size.X / 12)
						p(board.CFrame * CFrame.new(x, -board.Size.Y / 2 - 0.05, -0.8), Vector3.new(0.7, 0.7, 0.7), FLOWERS[(i % #FLOWERS) + 1], Enum.Material.SmoothPlastic, Enum.PartType.Ball)
					end
					p(ground * CFrame.new(0, 1, 0), Vector3.new(2.6, 2.2, 2.6), Color3.fromRGB(95, 150, 70), Enum.Material.LeafyGrass, Enum.PartType.Ball)
				end
			end
		end
	end
	decorFolder.Parent = workspace
end

---------------------------------------------------------------------
-- Music
---------------------------------------------------------------------
local music = Instance.new("Sound")
music.Name = "BrainMusic"
music.Looped = true
music.Parent = SoundService
local kazooUntil = 0

local function updateMusic()
	local id
	if os.clock() < kazooUntil then
		id = Config.Sounds.KazooTune
	else
		local MUSIC_KEY = { future = "genius", fancy = "genius", realistic = "smart", cozy = "average", cozycash = "cashgrab", cashgrab = "cashgrab", nonsense = "nonsense" }
		id = Config.Music[MUSIC_KEY[currentTier or "cozy"] or "average"]
	end
	music.Volume = (UI.settings.music or 0.5) * 0.6
	local want = (id and id ~= 0) and ("rbxassetid://" .. tostring(id)) or ""
	if music.SoundId ~= want then
		music.SoundId = want
		if want ~= "" then
			music:Play()
		else
			music:Stop()
		end
	end
end

function Style.kazoo(seconds: number)
	kazooUntil = os.clock() + seconds
	updateMusic()
	task.delay(seconds + 0.1, updateMusic)
end

---------------------------------------------------------------------
-- Apply everything for a new tier / cell count
---------------------------------------------------------------------
function Style.apply(state)
	currentCells = state.cells
	local tier = state.look or state.tier
	local styleName = state.style or Style.pick(state)
	local low = state.settings ~= nil and state.settings.lowGraphics == true
	local changed = tier ~= currentTier or styleName ~= currentStyle or low ~= lowDetail
	local styleChanged = styleName ~= currentStyle or low ~= lowDetail
	currentTier = tier
	currentStyle = styleName
	lowDetail = low
	if changed then
		for _, p in ipairs(CollectionService:GetTagged("Styled")) do
			if p:IsA("BasePart") then
				stylePart(p, tier, styleName)
			end
		end
		if styleChanged then
			applyLighting(styleName)
			task.defer(applyDecor, styleName)
		end
		applyCashGrabParts(tier)
		outlineOn = (STYLES[styleName] or {}).outline == true and not lowDetail
		refreshOutlines()
	end
	for _, l in ipairs(CollectionService:GetTagged("Sign")) do
		if l:IsA("TextLabel") then
			styleSign(l, tier, styleName)
		end
	end
	updateMusic()
end

function Style.current(): (string?, boolean)
	return currentStyle, lowDetail
end

CollectionService:GetInstanceAddedSignal("Styled"):Connect(function(p)
	if currentTier and p:IsA("BasePart") then
		stylePart(p, currentTier, currentStyle)
	end
end)
CollectionService:GetInstanceAddedSignal("Sign"):Connect(function(l)
	if currentTier and l:IsA("TextLabel") then
		styleSign(l, currentTier, currentStyle)
		l:GetAttributeChangedSignal("BaseText"):Connect(function()
			styleSign(l, currentTier, currentStyle)
		end)
	end
end)
for _, l in ipairs(CollectionService:GetTagged("Sign")) do
	if l:IsA("TextLabel") then
		l:GetAttributeChangedSignal("BaseText"):Connect(function()
			if currentTier then
				styleSign(l, currentTier, currentStyle)
			end
		end)
	end
end

---------------------------------------------------------------------
-- Brain weather over every player's head, and dumb pets
---------------------------------------------------------------------
local WEATHER = { genius = "☀️", smart = "⛅", average = "☁️", cashgrab = "🌧️", nonsense = "⛈️🦆" }
local OVERRIDE_WEATHER = { sun = "☀️", rain = "🌧️", duckstorm = "⛈️🦆🦆🦆" }
local weatherOverride, weatherUntil = nil, 0
local clouds = {} -- [player] = BillboardGui
local pets = {} -- [player] = Part

function Style.weather(kind: string, seconds: number)
	weatherOverride = OVERRIDE_WEATHER[kind] or "⛈️🦆🦆🦆"
	weatherUntil = os.clock() + seconds
end

local function petEmoji(cells: number): string
	if cells > 10e9 then
		return "🗿👀"
	elseif cells > 1e9 then
		return "🧦"
	elseif cells > 1e6 then
		return "💬 bruh"
	end
	return "🥴"
end

local function updateExtras(dt: number)
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local head = char and char:FindFirstChild("Head")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		-- weather
		if head then
			local cloud = clouds[p]
			if not cloud or not cloud.Parent then
				cloud = Instance.new("BillboardGui")
				cloud.Size = UDim2.fromOffset(60, 36)
				cloud.StudsOffset = Vector3.new(0, 4.2, 0)
				cloud.MaxDistance = 70
				local l = Instance.new("TextLabel")
				l.Name = "T"
				l.BackgroundTransparency = 1
				l.Size = UDim2.fromScale(1, 1)
				l.TextScaled = true
				l.Parent = cloud
				cloud.Parent = player:WaitForChild("PlayerGui")
				clouds[p] = cloud
			end
			cloud.Adornee = head
			local tier = p:GetAttribute("ArtTier") or "average"
			cloud.T.Text = (os.clock() < weatherUntil and weatherOverride) or WEATHER[tier] or "☁️"
		end
		-- pets (Lose path, 20 billion and below)
		local cells = p:GetAttribute("BrainCells") or Config.AverageCells
		local wantPet = Config.Features.Pets ~= false and p:GetAttribute("Path") == "Lose" and cells <= Config.PetBelowCells and cells > 0 and root ~= nil
		local pet = pets[p]
		if wantPet then
			if not pet or not pet.Parent then
				pet = Instance.new("Part")
				pet.Name = "DumbPet"
				pet.Size = Vector3.new(1.2, 1.2, 1.2)
				pet.Anchored = true
				pet.CanCollide = false
				pet.CanQuery = false
				pet.Shape = Enum.PartType.Ball
				pet.Color = Color3.fromRGB(120, 110, 100)
				local g = Instance.new("BillboardGui")
				g.Name = "G"
				g.Size = UDim2.fromOffset(70, 40)
				g.StudsOffset = Vector3.new(0, 1.4, 0)
				local l = Instance.new("TextLabel")
				l.Name = "T"
				l.BackgroundTransparency = 1
				l.Size = UDim2.fromScale(1, 1)
				l.TextScaled = true
				l.Parent = g
				g.Parent = pet
				pet.Parent = workspace
				pets[p] = pet
				pet.CFrame = root.CFrame * CFrame.new(3, -2, 3)
			end
			pet.G.T.Text = petEmoji(cells)
			local target = root.CFrame * CFrame.new(3, -2 + math.sin(os.clock() * 4) * 0.3, 3)
			pet.CFrame = pet.CFrame:Lerp(target, math.clamp(dt * 6, 0, 1))
		elseif pet then
			pet:Destroy()
			pets[p] = nil
		end
	end
end

Players.PlayerRemoving:Connect(function(p)
	if clouds[p] then
		clouds[p]:Destroy()
		clouds[p] = nil
	end
	if pets[p] then
		pets[p]:Destroy()
		pets[p] = nil
	end
end)

---------------------------------------------------------------------
-- Your NPC friends: REAL avatars (your actual Roblox friends if available).
-- Only you see them. They follow you on the Lose path and laugh at you;
-- in Comeback mode they visit to apologize.
---------------------------------------------------------------------
local WALK_ANIM = "rbxassetid://507777826" -- Roblox default R15 walk
local IDLE_ANIM = "rbxassetid://507766388" -- Roblox default R15 idle
local friends = {} -- [i] = { model, humanoid, walk, idle, bubble }
local friendBubbleUntil = 0
local friendBubbleText = ""
local visitUntil = 0
local visitLines = nil

local function friendTemplates()
	local root = ReplicatedStorage:FindFirstChild("FriendModels")
	return root and root:FindFirstChild(tostring(player.UserId))
end

local function spawnFriend(i: number, near: CFrame)
	local templates = friendTemplates()
	local template = templates and templates:FindFirstChild("Friend" .. i)
	if not template then
		return nil
	end
	local model = template:Clone()
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not hum or not root then
		model:Destroy()
		return nil
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	model:PivotTo(near * CFrame.new(-4 + i * 2.5, 0, 6))
	model.Parent = workspace
	-- name + speech bubble
	local head = model:FindFirstChild("Head") or root
	local g = Instance.new("BillboardGui")
	g.Name = "Bubble"
	g.Size = UDim2.new(6, 0, 1.6, 0)
	g.StudsOffset = Vector3.new(0, 2.2, 0)
	g.Adornee = head
	local l = Instance.new("TextLabel")
	l.Name = "T"
	l.BackgroundColor3 = Color3.new(1, 1, 1)
	l.BackgroundTransparency = 0.15
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(30, 30, 40)
	l.Text = model:GetAttribute("FriendName") or "Friend"
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.3, 0)
	c.Parent = l
	l.Parent = g
	g.Parent = model
	-- animations
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	local walk, idle
	pcall(function()
		local a = Instance.new("Animation")
		a.AnimationId = WALK_ANIM
		walk = animator:LoadAnimation(a)
		local b = Instance.new("Animation")
		b.AnimationId = IDLE_ANIM
		idle = animator:LoadAnimation(b)
		idle:Play()
	end)
	hum.WalkSpeed = 18
	return { model = model, humanoid = hum, root = root, walk = walk, idle = idle, label = l, name = l.Text, nextMove = 0 }
end

local function clearFriends()
	for i, f in pairs(friends) do
		if f.model then
			f.model:Destroy()
		end
		friends[i] = nil
	end
end

function Style.friendsLaugh()
	local st = UI.state
	if st and st.meterBroken then
		friendBubbleText = "wut"
	else
		local lines = { "HAHAHA 😂", "bro 💀", "📸 *filming*", "LMAOOO", "nah 😭😭" }
		friendBubbleText = lines[math.random(1, #lines)]
	end
	friendBubbleUntil = os.clock() + 2.5
	for _, f in pairs(friends) do
		if f.humanoid then
			f.humanoid.Jump = true
		end
	end
end

-- Comeback mode: friends visit to apologize
function Style.friendVisit(lines, seconds: number)
	visitLines = lines
	visitUntil = os.clock() + seconds
end

local function updateFriends(dt: number)
	local st = UI.state
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local visiting = os.clock() < visitUntil
	local want = root ~= nil and st ~= nil and not st.dead and (st.path == "Lose" or visiting)
	if not want then
		if next(friends) then
			clearFriends()
		end
		return
	end
	for i = 1, 3 do
		local f = friends[i]
		if not f or not f.model.Parent then
			f = spawnFriend(i, root.CFrame)
			friends[i] = f
		end
		if f then
			local offset = CFrame.new(-4 + i * 2.5, 0, 7)
			if st.meterBroken and not visiting then
				-- they got dumb too: wander around and bonk into things
				offset = offset * CFrame.new(math.sin(os.clock() * 0.7 + i) * 8, 0, math.cos(os.clock() * 0.5 + i) * 6)
			end
			local target = (root.CFrame * offset).Position
			local dist = (f.root.Position - target).Magnitude
			if dist > 70 then
				f.model:PivotTo(CFrame.new(target))
			elseif os.clock() > f.nextMove then
				f.nextMove = os.clock() + 0.25
				if dist > 3 then
					f.humanoid:MoveTo(target)
				end
			end
			local moving = f.root.AssemblyLinearVelocity.Magnitude > 2
			if f.walk then
				if moving and not f.walk.IsPlaying then
					f.walk:Play()
				elseif not moving and f.walk.IsPlaying then
					f.walk:Stop()
				end
			end
			local text = f.name
			if visiting and visitLines then
				text = visitLines[i] or f.name
			elseif os.clock() < friendBubbleUntil then
				text = friendBubbleText
			end
			f.label.Text = text
		end
	end
end

---------------------------------------------------------------------
-- Work marker (floating "WORK HERE" over your workplace) and gadgets
---------------------------------------------------------------------
local marker = nil
function Style.workMarker(pos: Vector3?, name: string?)
	if marker then
		marker:Destroy()
		marker = nil
	end
	if not pos then
		return
	end
	marker = Instance.new("Part")
	marker.Name = "WorkMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.Transparency = 1
	marker.Size = Vector3.new(1, 1, 1)
	marker.Position = pos + Vector3.new(0, 8, 0)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(200, 60)
	g.AlwaysOnTop = true
	g.Parent = marker
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(255, 220, 60)
	l.TextStrokeTransparency = 0
	l.Text = "⬇ 💼 WORK HERE\n" .. tostring(name)
	l.Parent = g
	marker.Parent = workspace
end

function Style.lowGravity(seconds: number)
	workspace.Gravity = 50
	task.delay(seconds, function()
		workspace.Gravity = 196.2
	end)
end

local duck = nil
local function updateDuck(dt: number)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if player:GetAttribute("DuckPet") and root then
		if not duck or not duck.Parent then
			duck = Instance.new("Part")
			duck.Name = "DuckPet"
			duck.Shape = Enum.PartType.Ball
			duck.Size = Vector3.new(1.4, 1.4, 1.4)
			duck.Color = Color3.fromRGB(255, 220, 0)
			duck.Anchored = true
			duck.CanCollide = false
			duck.CanQuery = false
			local g = Instance.new("BillboardGui")
			g.Size = UDim2.fromScale(2, 2)
			g.Size = UDim2.new(2.4, 0, 2.4, 0)
			local l = Instance.new("TextLabel")
			l.Size = UDim2.fromScale(1, 1)
			l.BackgroundTransparency = 1
			l.TextScaled = true
			l.Text = "🦆"
			l.Parent = g
			g.Parent = duck
			duck.Parent = workspace
			duck.CFrame = root.CFrame
		end
		local target = root.CFrame * CFrame.new(-3, 1 + math.sin(os.clock() * 3) * 0.4, 2)
		duck.CFrame = duck.CFrame:Lerp(target, math.clamp(dt * 5, 0, 1))
	elseif duck then
		duck:Destroy()
		duck = nil
	end
end

RunService.RenderStepped:Connect(function(dt)
	updateDuck(dt)
	updateExtras(dt)
	updateFriends(dt)
end)

---------------------------------------------------------------------
-- UPDATE 1.4: special places (the Moon, the white void, the Endless Castle)
---------------------------------------------------------------------
local MOON = Vector3.new(6000, 1500, 0)
local WHITE = Vector3.new(0, 3000, 9000)
local zone = nil
local sky = nil

local function zoneAt(pos: Vector3): string?
	if (pos - MOON).Magnitude < 420 then
		return "moon"
	elseif (pos - WHITE).Magnitude < 160 then
		return "white"
	elseif pos.Y > 2900 and pos.Y < 3100 and pos.Z > 11000 and pos.Z < 13000 then
		return "castle"
	end
	return nil
end

local function applyZone(z: string?)
	local cc = Lighting:FindFirstChild("BrainCC")
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not sky then
		sky = Lighting:FindFirstChildOfClass("Sky")
	end
	if z == "moon" then
		workspace.Gravity = Config.Space and Config.Space.MoonGravity or 35
		Lighting.ClockTime = 0
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(120, 120, 135)
		if atmosphere then
			atmosphere.Density = 0
			atmosphere.Haze = 0
		end
		if sky then
			sky.StarCount = 5000
		end
	elseif z == "white" then
		Lighting.ClockTime = 12
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.new(1, 1, 1)
		if atmosphere then
			atmosphere.Density = 0.6
			atmosphere.Haze = 0
			atmosphere.Color = Color3.new(1, 1, 1)
		end
		if cc then
			cc.Saturation = -1
		end
	elseif z == "castle" then
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.6
		Lighting.Ambient = Color3.fromRGB(70, 55, 50)
		if atmosphere then
			atmosphere.Density = 0.45
			atmosphere.Haze = 1
			atmosphere.Color = Color3.fromRGB(60, 40, 40)
		end
		if cc then
			cc.Saturation = -0.15
			cc.TintColor = Color3.fromRGB(255, 225, 200)
		end
	else
		workspace.Gravity = 196.2
		if sky then
			sky.StarCount = 3000
		end
		if atmosphere then
			atmosphere.Color = Color3.fromRGB(199, 199, 199)
		end
		if currentStyle then
			applyLighting(currentStyle)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.3)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local z = root and zoneAt(root.Position) or nil
		if z ~= zone then
			zone = z
			applyZone(z)
		end
	end
end)

-- The Endless Castle: hints are written on YOUR screen only, for YOUR next turn
function Style.castleStep(d)
	local castle = workspace:FindFirstChild("EndlessCastle")
	if not castle then
		return
	end
	local g = castle:FindFirstChild("CastleGraffiti")
	local label = g and g:FindFirstChild("SurfaceGui") and g.SurfaceGui:FindFirstChild("Text")
	if label then
		label.Text = tostring(d.hint)
	end
	local painting = castle:FindFirstChild("CastleHintPainting")
	local plabel = painting and painting:FindFirstChild("SurfaceGui") and painting.SurfaceGui:FindFirstChild("Text")
	if plabel then
		plabel.Text = "🕯 " .. tostring(d.hint)
	end
	local counter = castle:FindFirstChild("CastleCounter")
	local clabel = counter and counter:FindFirstChild("SurfaceGui") and counter.SurfaceGui:FindFirstChild("Text")
	if clabel then
		clabel.Text = string.rep("🕯", d.step or 0) .. string.rep("·", math.max(0, (d.steps or 6) - (d.step or 0)))
	end
	if d.wrong then
		UI.toast("🏰 " .. tostring(d.wrong), Color3.fromRGB(90, 40, 40), 4)
		UI.sound("SadTrombone", 0.4)
	elseif d.atWall then
		UI.toast("🧱 A dead end. An old brick wall. The rhyme said to knock…", Color3.fromRGB(120, 70, 50), 6)
		UI.sound("LibrarianChime", 0.6)
	elseif (d.step or 0) > 0 then
		UI.sound("NotificationPing", 0.4)
	end
end

function Style.castleWallOpen()
	local castle = workspace:FindFirstChild("EndlessCastle")
	local wall = castle and castle:FindFirstChild("CastleBrickWall")
	if not wall then
		return
	end
	local TweenService = game:GetService("TweenService")
	UI.sound("LevelUp", 0.8)
	for i, b in ipairs(wall:GetChildren()) do
		if b:IsA("BasePart") then
			b.CanCollide = false
			task.delay(i * 0.02, function()
				TweenService:Create(b, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = b.CFrame * CFrame.new((math.random() - 0.5) * 6, 14, 0), Transparency = 1 }):Play()
			end)
		end
	end
	UI.toast("🧱✨ The wall opens…", UI.Colors.gold, 4)
end

return Style

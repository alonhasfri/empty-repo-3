-- RoomGuide.lua (1.9.1, user: "make the inside of the buildings better with clear places you need to go
-- when you walk into a building").
-- When you walk into a furnished building:
--   * a "📍 <building>" card says what the place is for and lists the spots you can use (tap one)
--   * every usable spot gets a glowing floor ring and a floating label
--   * a glowing path leads from you to the chosen spot and disappears when you arrive
-- The card folds into a small "📍 Where to go" pill after a few seconds. Spots come from the server
-- (Rooms.startGuide tags them "RoomSpot"); spots for the other path are hidden.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local CG = Config.RoomGuide
local TG = Content.RoomGuide
local GOLD = Color3.fromRGB(255, 200, 61)

local RoomGuide = {}

local current: string? = nil -- building key you're in
local visuals = {} -- local parts and labels for the current building
local card: Frame? = nil
local beam: Beam? = nil
local target: BasePart? = nil
local foldAt = 0

local function myPath(): string?
	return UI.state and UI.state.path or nil
end

local function isAnimal(): boolean
	return UI.state ~= nil and UI.state.stage ~= nil and Content.Animals.Forms[UI.state.stage] ~= nil
end

local function promptOf(part: Instance): ProximityPrompt?
	return part:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function labelOf(part: Instance): string
	local pp = promptOf(part)
	if not pp then
		return part.Name
	end
	if pp.ObjectText ~= "" then
		return pp.ActionText .. ": " .. pp.ObjectText
	end
	return pp.ActionText
end

local function root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- the spots in building `key` that this player can use, nearest first
local function spotsIn(key: string)
	local list = {}
	local r = root()
	local path = myPath()
	for _, p in ipairs(CollectionService:GetTagged("RoomSpot")) do
		if p:IsA("BasePart") and p:GetAttribute("GuideBuilding") == key then
			local gp = p:GetAttribute("GuidePath")
			local pp = promptOf(p)
			local animalOnly = p:GetAttribute("GuideAnimal") == true
			if (gp == nil or gp == path) and pp and pp.Enabled and animalOnly == isAnimal() then
				table.insert(list, p)
			end
		end
	end
	if r then
		table.sort(list, function(a, b)
			if (a:GetAttribute("GuideMain") == true) ~= (b:GetAttribute("GuideMain") == true) then
				return a:GetAttribute("GuideMain") == true
			end
			return (a.Position - r.Position).Magnitude < (b.Position - r.Position).Magnitude
		end)
	end
	return list
end

local function clearBeam()
	if beam then
		if beam.Attachment0 then
			beam.Attachment0:Destroy()
		end
		beam:Destroy()
		beam = nil
	end
	target = nil
end

local function clearAll()
	clearBeam()
	for _, v in ipairs(visuals) do
		v:Destroy()
	end
	visuals = {}
	if card then
		card:Destroy()
		card = nil
	end
end

-- a ring on the floor under the spot and a floating label above it (local only)
local function decorate(p: BasePart, floorY: number)
	local ring = Instance.new("Part")
	ring.Name = "GuideRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.15, CG.RingSize, CG.RingSize)
	ring.CFrame = CFrame.new(p.Position.X, floorY + 0.12, p.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = GOLD
	ring.Transparency = 0.55
	ring.Parent = workspace.CurrentCamera
	table.insert(visuals, ring)

	local bb = UI.new("BillboardGui", {
		Name = "GuideLabel",
		Adornee = ring,
		Size = UDim2.fromOffset(200, 30),
		StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0),
		MaxDistance = CG.LabelDistance,
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = workspace.CurrentCamera,
	})
	local l = UI.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.T.bg,
		BackgroundTransparency = 0.15,
		TextColor3 = Color3.new(1, 1, 1),
		Font = UI.T.font,
		TextScaled = true,
		Text = "📍 " .. labelOf(p),
		Parent = bb,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 9, Parent = l })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = l })
	UI.corner(l, 8)
	UI.stroke(l, GOLD, 1.5, 0.3)
	table.insert(visuals, bb)
end

-- a glowing path from your feet to the spot
function RoomGuide.pathTo(p: BasePart)
	clearBeam()
	local r = root()
	if not r then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "GuideFrom"
	a0.Position = Vector3.new(0, -2.6, 0)
	a0.Parent = r
	local a1 = Instance.new("Attachment")
	a1.Name = "GuideTo"
	a1.Parent = p
	a1.WorldPosition = Vector3.new(p.Position.X, r.Position.Y - 2.6, p.Position.Z)
	table.insert(visuals, a1)
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Width0 = 0.9
	b.Width1 = 0.9
	b.FaceCamera = true
	b.LightEmission = 1
	b.Color = ColorSequence.new(GOLD)
	b.Transparency = NumberSequence.new(0.25)
	b.Segments = 1
	b.Parent = r
	beam = b
	target = p
end

local function fold()
	if not card then
		return
	end
	card:FindFirstChild("Body").Visible = false
	card.Size = UDim2.fromOffset(170, 40)
	local head = card:FindFirstChild("Head") :: TextButton
	head.Text = TG.Pill
end

local function unfold()
	if not card then
		return
	end
	card:FindFirstChild("Body").Visible = true
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Size = UDim2.new(UI.isPhone() and 0.42 or 0.26, 0, 0, 40)
	local head = card:FindFirstChild("Head") :: TextButton
	head.Text = string.format(TG.Title, card:GetAttribute("Title") or "")
	foldAt = os.clock() + CG.PanelSeconds
end

local function showCard(key: string, title: string, spots)
	if not UI.gui then
		return
	end
	card = UI.new("Frame", {
		Name = "RoomGuide",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, UI.isPhone() and 52 or 64),
		Size = UDim2.new(UI.isPhone() and 0.42 or 0.26, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.T.panel,
		BackgroundTransparency = 0.05,
		ZIndex = 20,
		Parent = UI.gui,
	})
	card:SetAttribute("Title", title)
	UI.corner(card)
	UI.stroke(card, GOLD, 1.5, 0.35)
	UI.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = card })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), Parent = card })
	local head = UI.new("TextButton", {
		Name = "Head",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Font = UI.T.title,
		TextScaled = true,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.format(TG.Title, title),
		LayoutOrder = 1,
		ZIndex = 21,
		Parent = card,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 11, Parent = head })
	head.Activated:Connect(function()
		local body = card and card:FindFirstChild("Body")
		if body and body.Visible then
			fold()
		else
			unfold()
		end
	end)
	local body = UI.new("Frame", { Name = "Body", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = card })
	UI.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = body })
	local intro = TG.Intros[key]
	local function line(text: string, order: number, color: Color3?)
		local l = UI.new("TextLabel", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = UI.T.body,
			TextSize = UI.isPhone() and 13 or 15,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = color or UI.T.text,
			Text = text,
			LayoutOrder = order,
			ZIndex = 21,
			Parent = body,
		})
		return l
	end
	if intro then
		line(intro, 1)
	end
	if #spots == 0 then
		line(TG.Nothing, 2, UI.T.muted)
	else
		line(TG.What, 2, UI.T.muted)
	end
	for i, p in ipairs(spots) do
		if i > CG.MaxSpots then
			break
		end
		local b = UI.button(body, "📍 " .. labelOf(p), function()
			RoomGuide.pathTo(p)
			UI.sound("NotificationPing", 0.4)
			fold()
		end, { LayoutOrder = 2 + i, Size = UDim2.new(1, 0, 0, 36), TextSize = UI.isPhone() and 13 or 15, ZIndex = 21 })
		b.TextXAlignment = Enum.TextXAlignment.Left
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = b })
	end
	foldAt = os.clock() + CG.PanelSeconds
end

local function enter(zone: BasePart)
	clearAll()
	local key = zone:GetAttribute("Key")
	current = key
	local r = root()
	local floorY = r and (r.Position.Y - 3) or zone.Position.Y - 15
	local spots = spotsIn(key)
	for _, p in ipairs(spots) do
		decorate(p, floorY)
	end
	showCard(key, zone:GetAttribute("Title") or key, spots)
	if spots[1] then
		RoomGuide.pathTo(spots[1])
	end
end

local function zoneAt(pos: Vector3): BasePart?
	local folder = workspace:FindFirstChild("RoomZones")
	if not folder then
		return nil
	end
	for _, z in ipairs(folder:GetChildren()) do
		if z:IsA("BasePart") then
			local rel = z.CFrame:PointToObjectSpace(pos)
			local h = z.Size / 2
			if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y and math.abs(rel.Z) <= h.Z then
				return z
			end
		end
	end
	return nil
end

task.spawn(function()
	while true do
		task.wait(CG.Check)
		local r = root()
		local z = r and zoneAt(r.Position)
		local key = z and z:GetAttribute("Key")
		if key ~= current then
			if z then
				enter(z)
			else
				current = nil
				clearAll()
			end
		end
		if target and r and target.Parent then
			local flat = Vector3.new(target.Position.X - r.Position.X, 0, target.Position.Z - r.Position.Z)
			if flat.Magnitude <= CG.ArriveDistance then
				clearBeam()
				UI.toast(TG.Arrived)
			end
		elseif target then
			clearBeam()
		end
		if card and foldAt > 0 and os.clock() > foldAt then
			foldAt = 0
			fold()
		end
	end
end)

-- respawn: the old attachment went with the old character
player.CharacterAdded:Connect(function()
	clearBeam()
	current = nil
end)

return RoomGuide

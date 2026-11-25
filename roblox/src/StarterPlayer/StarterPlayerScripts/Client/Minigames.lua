-- Minigames (1.9 Gain path redesign): the client half of the minigame framework.
-- Minigames.play(info, opts) runs one round that the server started (MinigameService.begin):
--   start screen (how to play + goal) → timer + score → the server checks the score → result.
-- Every game is a function(area, ctx); ctx.add(points), ctx.feedback(ok), ctx.rng, ctx.level, ctx.alive().
-- Games: scan (cashier), colors (scientist), pipes (engineer), files (office), grade (teacher),
-- xray (doctor), order (chef), dash (courier). Never maths. Phone-friendly: big tap targets.
-- Text: Content.Minigames. Numbers: Config.Minigames (round length, goals, server limits).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Content = require(ReplicatedStorage.Shared.Content)

local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local Minigames = {}
local MG = Content.Minigames
local WHITE = Color3.new(1, 1, 1)

local function label(parent, text: string, props)
	local l = UI.new("TextLabel", { BackgroundTransparency = 1, Text = text, TextScaled = true, Font = UI.T.font, TextColor3 = UI.T.text, Parent = parent })
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

local function tapButton(parent, text: string, props, onClick)
	local b = UI.new("TextButton", { Text = text, TextScaled = true, Font = UI.T.font, TextColor3 = WHITE, BackgroundColor3 = UI.T.panel2, AutoButtonColor = true, Parent = parent }, {
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
	})
	UI.corner(b, 12)
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	b.Activated:Connect(onClick)
	return b
end

local function row(parent, y: number, h: number, n: number)
	return UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, y, 0), Size = UDim2.new(1, 0, h, 0), Parent = parent }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / n - 0.02, 0, 1, 0), CellPadding = UDim2.new(0.02, 0, 0, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
end

local GAMES = {}

---------------------------------------------------------------------
-- Cashier: scan & bag
---------------------------------------------------------------------
function GAMES.scan(area, ctx)
	local belt = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 64, 76), Position = UDim2.fromScale(0, 0.42), Size = UDim2.new(1, 0, 0, 10), Parent = area })
	UI.corner(belt, 5)
	local hint = label(area, MG.TapToScan, { Size = UDim2.new(1, 0, 0.12, 0), Font = UI.T.body })
	local item = tapButton(area, "", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(84, 84), BackgroundTransparency = 1, Position = UDim2.fromScale(-0.2, 0.42) }, function() end)
	local bags = row(area, 0.62, 0.3, 2)
	local soft = tapButton(bags, MG.SoftBag, { LayoutOrder = 1, BackgroundColor3 = Color3.fromRGB(90, 140, 200) }, function() end)
	local strong = tapButton(bags, MG.StrongBag, { LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(150, 110, 70) }, function() end)
	local fragile, scanned = false, false
	local function nextItem()
		fragile = ctx.rng:NextNumber() < 0.5
		local list = fragile and MG.Fragile or MG.Heavy
		item.Text = list[ctx.rng:NextInteger(1, #list)]
		scanned = false
		bags.Visible = false
		hint.Text = MG.TapToScan
		item.Position = UDim2.fromScale(-0.2, 0.42)
		local speed = math.max(0.5, 1.3 - ctx.level * 0.15)
		TweenService:Create(item, TweenInfo.new(speed, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0.5, 0.42) }):Play()
	end
	item.Activated:Connect(function()
		if not scanned and ctx.alive() then
			scanned = true
			bags.Visible = true
			hint.Text = "📟 BEEP!"
			UI.sound("NotificationPing", 0.3)
		end
	end)
	local function bag(isSoft: boolean)
		if not scanned or not ctx.alive() then
			return
		end
		local ok = isSoft == fragile
		ctx.feedback(ok)
		if ok then
			ctx.add(1)
		end
		nextItem()
	end
	soft.Activated:Connect(function()
		bag(true)
	end)
	strong.Activated:Connect(function()
		bag(false)
	end)
	nextItem()
end

---------------------------------------------------------------------
-- Scientist: mix colours (red, yellow, blue paint, like real paint)
---------------------------------------------------------------------
-- paint mixing: the corners of the RYB cube (Gossett & Chen), blended
local RYB = {
	{ 0, 0, 0, Color3.new(1, 1, 1) },
	{ 1, 0, 0, Color3.new(1, 0, 0) },
	{ 0, 1, 0, Color3.new(1, 1, 0) },
	{ 0, 0, 1, Color3.new(0.163, 0.373, 0.6) },
	{ 1, 1, 0, Color3.new(1, 0.5, 0) },
	{ 1, 0, 1, Color3.new(0.5, 0, 0.5) },
	{ 0, 1, 1, Color3.new(0, 0.66, 0.2) },
	{ 1, 1, 1, Color3.new(0.2, 0.094, 0) },
}
local function paint(r: number, y: number, b: number): Color3
	local m = math.max(r, y, b, 1)
	r, y, b = r / m, y / m, b / m
	local R, G, B = 0, 0, 0
	for _, c in ipairs(RYB) do
		local w = (c[1] == 1 and r or 1 - r) * (c[2] == 1 and y or 1 - y) * (c[3] == 1 and b or 1 - b)
		R += c[4].R * w
		G += c[4].G * w
		B += c[4].B * w
	end
	return Color3.new(R, G, B)
end
local function sameMix(a, b): boolean
	local ma, mb = math.max(a[1], a[2], a[3]), math.max(b[1], b[2], b[3])
	if ma == 0 or mb == 0 then
		return false
	end
	for i = 1, 3 do
		if math.abs(a[i] / ma - b[i] / mb) > 0.01 then
			return false
		end
	end
	return true
end

function GAMES.colors(area, ctx)
	local swatches = row(area, 0, 0.42, 2)
	local target = UI.new("Frame", { LayoutOrder = 1, Parent = swatches })
	UI.corner(target, 16)
	label(target, MG.Target, { Size = UDim2.new(1, 0, 0.3, 0), Position = UDim2.fromScale(0, 0.7), TextStrokeTransparency = 0.4 })
	local mix = UI.new("Frame", { LayoutOrder = 2, Parent = swatches })
	UI.corner(mix, 16)
	label(mix, MG.YourMix, { Size = UDim2.new(1, 0, 0.3, 0), Position = UDim2.fromScale(0, 0.7), TextStrokeTransparency = 0.4 })
	local pours = row(area, 0.48, 0.22, 3)
	local tools = row(area, 0.74, 0.22, 2)
	local want, have = { 0, 0, 0 }, { 0, 0, 0 }
	local maxPart = ctx.level >= 3 and 3 or 2
	local function show()
		target.BackgroundColor3 = paint(want[1], want[2], want[3])
		mix.BackgroundColor3 = (have[1] + have[2] + have[3] == 0) and Color3.fromRGB(240, 240, 240) or paint(have[1], have[2], have[3])
	end
	local function newTarget()
		repeat
			want = { ctx.rng:NextInteger(0, maxPart), ctx.rng:NextInteger(0, maxPart), ctx.rng:NextInteger(0, maxPart) }
		until (want[1] + want[2] + want[3]) > 0 and not (want[1] == want[2] and want[2] == want[3])
		have = { 0, 0, 0 }
		show()
	end
	for i, name in ipairs({ MG.Red, MG.Yellow, MG.Blue }) do
		tapButton(pours, name, { LayoutOrder = i, BackgroundColor3 = ({ Color3.fromRGB(210, 50, 50), Color3.fromRGB(220, 180, 20), Color3.fromRGB(40, 90, 200) })[i] }, function()
			if ctx.alive() and have[i] < 6 then
				have[i] += 1
				show()
			end
		end)
	end
	tapButton(tools, MG.Empty, { LayoutOrder = 1 }, function()
		have = { 0, 0, 0 }
		show()
	end)
	tapButton(tools, MG.Done, { LayoutOrder = 2, BackgroundColor3 = UI.Colors.good }, function()
		if not ctx.alive() then
			return
		end
		local ok = sameMix(want, have)
		ctx.feedback(ok)
		if ok then
			ctx.add(1)
			newTarget()
		end
	end)
	newTarget()
end

---------------------------------------------------------------------
-- Engineer: pipe puzzle (turn the pipes so water reaches the town)
---------------------------------------------------------------------
-- sides as bits: N = 1, E = 2, S = 4, W = 8
local DIRS = { { 1, 0, -1, 4 }, { 2, 1, 0, 8 }, { 4, 0, 1, 1 }, { 8, -1, 0, 2 } } -- bit, dx, dy, opposite bit
local function rot(m: number): number
	return bit32.band(bit32.bor(bit32.lshift(m, 1), bit32.rshift(m, 3)), 15)
end

function GAMES.pipes(area, ctx)
	local n = ctx.level >= 3 and 5 or 4
	label(area, "💧", { Size = UDim2.new(0.1, 0, 0.12, 0), Position = UDim2.fromScale(0, 0.44) })
	label(area, "🏘", { Size = UDim2.new(0.1, 0, 0.12, 0), Position = UDim2.fromScale(0.9, 0.44) })
	local board = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.98), BackgroundColor3 = Color3.fromRGB(30, 34, 46), Parent = area }, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / n - 0.01, 0, 1 / n - 0.01, 0), CellPadding = UDim2.fromScale(0.01, 0.01), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.corner(board, 12)
	local masks, need, tiles = {}, {}, {}
	local function draw(i: number)
		local t = tiles[i]
		for _, c in ipairs(t:GetChildren()) do
			if c.Name == "Arm" then
				c:Destroy()
			end
		end
		local color = need[i] and Color3.fromRGB(80, 170, 255) or Color3.fromRGB(150, 155, 170)
		for _, d in ipairs(DIRS) do
			if bit32.band(masks[i], d[1]) ~= 0 then
				local horiz = d[2] ~= 0
				UI.new("Frame", {
					Name = "Arm",
					BorderSizePixel = 0,
					BackgroundColor3 = color,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5 + d[2] * 0.25, 0.5 + d[3] * 0.25),
					Size = horiz and UDim2.fromScale(0.54, 0.26) or UDim2.fromScale(0.26, 0.54),
					Parent = t,
				})
			end
		end
	end
	local function solved(): boolean
		for i, m in pairs(need) do
			if masks[i] ~= m then
				return false
			end
		end
		return true
	end
	local function newPuzzle()
		need = {}
		-- a random path from the left edge to the right edge (never loops back)
		local y = ctx.rng:NextInteger(1, n)
		local x = 1
		local entry = 8 -- comes in from the West
		local lastVert = 0
		while true do
			local options = { 2 } -- East
			if lastVert ~= 4 and y > 1 then
				table.insert(options, 1)
			end
			if lastVert ~= 1 and y < n then
				table.insert(options, 4)
			end
			local exit = options[ctx.rng:NextInteger(1, #options)]
			if exit ~= 2 and ctx.rng:NextNumber() < 0.45 then
				exit = 2
			end
			local idx = (y - 1) * n + x
			need[idx] = bit32.bor(need[idx] or 0, entry, exit)
			if exit == 2 then
				if x == n then
					break
				end
				x += 1
				entry = 8
				lastVert = 0
			else
				y += exit == 1 and -1 or 1
				entry = exit == 1 and 4 or 1
				lastVert = exit
			end
		end
		for i = 1, n * n do
			local m = need[i] or ((ctx.rng:NextNumber() < 0.5) and 5 or 3)
			for _ = 1, ctx.rng:NextInteger(0, 3) do
				m = rot(m)
			end
			masks[i] = m
		end
		if solved() then -- never start already solved
			for i in pairs(need) do
				masks[i] = rot(masks[i])
				break
			end
		end
		for i = 1, n * n do
			draw(i)
		end
	end
	for i = 1, n * n do
		local t = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(46, 52, 70), LayoutOrder = i, Parent = board })
		UI.corner(t, 6)
		tiles[i] = t
		t.Activated:Connect(function()
			if not ctx.alive() then
				return
			end
			masks[i] = rot(masks[i])
			draw(i)
			UI.sound("CartoonBoing", 0.1)
			if solved() then
				ctx.feedback(true)
				ctx.add(1)
				newPuzzle()
			end
		end)
	end
	newPuzzle()
end

---------------------------------------------------------------------
-- Office: file sorting (by colour)
---------------------------------------------------------------------
local FILE_COLORS = { Color3.fromRGB(220, 60, 60), Color3.fromRGB(50, 110, 220), Color3.fromRGB(50, 170, 90), Color3.fromRGB(230, 190, 30) }

function GAMES.files(area, ctx)
	local count = ctx.level >= 2 and 4 or 3
	local card = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(0.6, 0.4), Parent = area })
	UI.corner(card, 12)
	local name = label(card, "", { Size = UDim2.fromScale(0.9, 0.5), Position = UDim2.fromScale(0.05, 0.25), TextColor3 = WHITE, TextStrokeTransparency = 0.5 })
	local folders = row(area, 0.56, 0.36, count)
	local want = 1
	local function nextFile()
		want = ctx.rng:NextInteger(1, count)
		card.BackgroundColor3 = FILE_COLORS[want]
		name.Text = "📄 " .. MG.FileNames[ctx.rng:NextInteger(1, #MG.FileNames)]
	end
	for i = 1, count do
		tapButton(folders, "📁 " .. MG.FileColors[i], { LayoutOrder = i, BackgroundColor3 = FILE_COLORS[i] }, function()
			if not ctx.alive() then
				return
			end
			local ok = i == want
			ctx.feedback(ok)
			if ok then
				ctx.add(1)
			end
			nextFile()
		end)
	end
	nextFile()
end

---------------------------------------------------------------------
-- Teacher: grade papers (right or silly? tap or swipe)
---------------------------------------------------------------------
function GAMES.grade(area, ctx)
	local card = UI.new("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromScale(0.9, 0.5), BackgroundColor3 = Color3.fromRGB(250, 246, 230), Parent = area })
	UI.corner(card, 12)
	local text = label(card, "", { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = Color3.fromRGB(30, 30, 40), Font = UI.T.body, TextWrapped = true })
	local buttons = row(area, 0.62, 0.32, 2)
	local isRight = true
	local function nextPaper()
		isRight = ctx.rng:NextNumber() < 0.5
		local list = isRight and MG.GradeRight or MG.GradeSilly
		text.Text = list[ctx.rng:NextInteger(1, #list)]
		card.Position = UDim2.fromScale(0.5, 0.02)
	end
	local function answer(saysRight: boolean)
		if not ctx.alive() then
			return
		end
		local ok = saysRight == isRight
		ctx.feedback(ok)
		if ok then
			ctx.add(1)
		end
		nextPaper()
	end
	tapButton(buttons, MG.Silly, { LayoutOrder = 1, BackgroundColor3 = UI.Colors.bad }, function()
		answer(false)
	end)
	tapButton(buttons, MG.Right, { LayoutOrder = 2, BackgroundColor3 = UI.Colors.good }, function()
		answer(true)
	end)
	-- swipe: right = ✅, left = ❌
	local startX = nil
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			startX = input.Position.X
		end
	end)
	card.InputEnded:Connect(function(input)
		if startX and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			local dx = input.Position.X - startX
			startX = nil
			if math.abs(dx) > 60 then
				answer(dx > 0)
			end
		end
	end)
	nextPaper()
end

---------------------------------------------------------------------
-- Doctor: X-ray spot (find what shouldn't be there)
---------------------------------------------------------------------
function GAMES.xray(area, ctx)
	local n = ctx.level >= 3 and 5 or 4
	local film = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.98), BackgroundColor3 = Color3.fromRGB(14, 30, 60), Parent = area }, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / n - 0.01, 0, 1 / n - 0.01, 0), CellPadding = UDim2.fromScale(0.01, 0.01), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.corner(film, 12)
	local odd = 1
	local cells = {}
	local function newFilm()
		odd = ctx.rng:NextInteger(1, n * n)
		for i, c in ipairs(cells) do
			c.Text = i == odd and MG.Odd[ctx.rng:NextInteger(1, #MG.Odd)] or MG.Bone
			c.Rotation = ctx.rng:NextInteger(-30, 30)
		end
	end
	for i = 1, n * n do
		local c = UI.new("TextButton", { Text = "", TextScaled = true, BackgroundTransparency = 1, TextTransparency = 0.15, LayoutOrder = i, Parent = film })
		cells[i] = c
		c.Activated:Connect(function()
			if not ctx.alive() then
				return
			end
			local ok = i == odd
			ctx.feedback(ok)
			if ok then
				ctx.add(1)
				newFilm()
			end
		end)
	end
	newFilm()
end

---------------------------------------------------------------------
-- Chef: order up (build the burger on the ticket)
---------------------------------------------------------------------
function GAMES.order(area, ctx)
	local ticketRow = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(250, 246, 230), Size = UDim2.fromScale(1, 0.2), Parent = area }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.corner(ticketRow, 10)
	local plateRow = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 44, 56), Position = UDim2.fromScale(0, 0.25), Size = UDim2.fromScale(1, 0.2), Parent = area }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.corner(plateRow, 10)
	local pantry = row(area, 0.56, 0.36, #MG.Ingredients)
	local ticket, plate = {}, {}
	local function fill(frame, list, prefix: string)
		for _, c in ipairs(frame:GetChildren()) do
			if c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		label(frame, prefix, { Size = UDim2.new(0, 70, 0.7, 0), LayoutOrder = 0, TextColor3 = frame == ticketRow and Color3.fromRGB(30, 30, 40) or WHITE, Font = UI.T.body })
		for i, ing in ipairs(list) do
			label(frame, ing, { Size = UDim2.new(0, 40, 0.8, 0), LayoutOrder = i })
		end
	end
	local function newTicket()
		local middle = math.min(4, 1 + ctx.level)
		ticket = { MG.Ingredients[1] }
		for _ = 1, middle do
			table.insert(ticket, MG.Ingredients[ctx.rng:NextInteger(2, #MG.Ingredients)])
		end
		table.insert(ticket, MG.Ingredients[1])
		plate = {}
		fill(ticketRow, ticket, MG.Ticket)
		fill(plateRow, plate, MG.Plate)
	end
	for i, ing in ipairs(MG.Ingredients) do
		tapButton(pantry, ing, { LayoutOrder = i }, function()
			if not ctx.alive() then
				return
			end
			if ticket[#plate + 1] == ing then
				table.insert(plate, ing)
				fill(plateRow, plate, MG.Plate)
				if #plate == #ticket then
					ctx.feedback(true)
					ctx.add(1)
					newTicket()
				end
			else
				ctx.feedback(false)
				plate = {}
				fill(plateRow, plate, MG.Plate)
			end
		end)
	end
	newTicket()
end

---------------------------------------------------------------------
-- Courier: Hoppr dash (drive to the parcel, then to the house)
---------------------------------------------------------------------
function GAMES.dash(area, ctx)
	local n = 5
	local map = UI.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.02, 0.5), Size = UDim2.fromScale(0.6, 0.98), BackgroundColor3 = Color3.fromRGB(70, 120, 70), Parent = area }, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / n - 0.01, 0, 1 / n - 0.01, 0), CellPadding = UDim2.fromScale(0.01, 0.01), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.corner(map, 10)
	local cells = {}
	for i = 1, n * n do
		cells[i] = label(map, "", { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(90, 90, 100), LayoutOrder = i })
		UI.corner(cells[i], 4)
	end
	local van, parcel, house = { 1, 1 }, { 1, 1 }, { 1, 1 }
	local carrying = false
	local function spot()
		return { ctx.rng:NextInteger(1, n), ctx.rng:NextInteger(1, n) }
	end
	local function same(a, b)
		return a[1] == b[1] and a[2] == b[2]
	end
	local function draw()
		for _, c in ipairs(cells) do
			c.Text = ""
		end
		local function put(p, t)
			cells[(p[2] - 1) * n + p[1]].Text = t
		end
		put(house, MG.House)
		if not carrying then
			put(parcel, MG.Parcel)
		end
		put(van, carrying and (MG.Van .. MG.Parcel) or MG.Van)
	end
	local function newJob()
		carrying = false
		repeat
			parcel, house = spot(), spot()
		until not same(parcel, house) and not same(parcel, van) and not same(house, van)
		draw()
	end
	local pad = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.66, 0.05), Size = UDim2.fromScale(0.33, 0.9), Parent = area })
	local function arrow(text: string, x: number, y: number, dx: number, dy: number)
		tapButton(pad, text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(0.36, 0.3) }, function()
			if not ctx.alive() then
				return
			end
			van = { math.clamp(van[1] + dx, 1, n), math.clamp(van[2] + dy, 1, n) }
			if not carrying and same(van, parcel) then
				carrying = true
				UI.sound("NotificationPing", 0.3)
			elseif carrying and same(van, house) then
				ctx.feedback(true)
				ctx.add(1)
				newJob()
				return
			end
			draw()
		end)
	end
	arrow(MG.Up, 0.5, 0.17, 0, -1)
	arrow(MG.Left, 0.2, 0.5, -1, 0)
	arrow(MG.Right2, 0.8, 0.5, 1, 0)
	arrow(MG.Down, 0.5, 0.83, 0, 1)
	newJob()
end

---------------------------------------------------------------------
-- 1.9 Genius signature minigames (Content.Genius)
---------------------------------------------------------------------
local TG = Content.Genius

-- Math genius: what comes next in the pattern? (shapes, never sums)
function GAMES.pattern(area, ctx)
	local seqRow = UI.new("Frame", { BackgroundColor3 = UI.T.panel, Size = UDim2.fromScale(1, 0.3), Parent = area }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4) }),
	})
	UI.corner(seqRow, 12)
	label(area, TG.WhatNext, { Position = UDim2.fromScale(0, 0.33), Size = UDim2.fromScale(1, 0.12), Font = UI.T.body })
	local answers = row(area, 0.5, 0.4, 3)
	local want = ""
	local buttons = {}
	local RULES = { { 1, 2 }, { 1, 2, 3 }, { 1, 1, 2 }, { 1, 2, 2 }, { 1, 2, 3, 2 } }
	local function newPattern()
		local shapes = table.clone(TG.Shapes)
		for i = #shapes, 2, -1 do
			local j = ctx.rng:NextInteger(1, i)
			shapes[i], shapes[j] = shapes[j], shapes[i]
		end
		local rule = RULES[ctx.rng:NextInteger(1, math.min(#RULES, 2 + ctx.level))]
		local len = 5 + math.min(2, ctx.level - 1)
		for _, c in ipairs(seqRow:GetChildren()) do
			if c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		for i = 1, len do
			label(seqRow, shapes[rule[(i - 1) % #rule + 1]], { Size = UDim2.new(0, 40, 0.8, 0) })
		end
		label(seqRow, "❓", { Size = UDim2.new(0, 40, 0.8, 0) })
		want = shapes[rule[len % #rule + 1]]
		local options = { want }
		for _, s in ipairs(shapes) do
			if #options < 3 and s ~= want then
				table.insert(options, s)
			end
		end
		for i = #options, 2, -1 do
			local j = ctx.rng:NextInteger(1, i)
			options[i], options[j] = options[j], options[i]
		end
		for i, b in ipairs(buttons) do
			b.Text = options[i]
		end
	end
	for i = 1, 3 do
		buttons[i] = tapButton(answers, "", { LayoutOrder = i }, function()
			if not ctx.alive() then
				return
			end
			local ok = buttons[i].Text == want
			ctx.feedback(ok)
			if ok then
				ctx.add(1)
			end
			newPattern()
		end)
	end
	newPattern()
end

-- Physics genius: angle and power (range = power² × sin 2θ)
function GAMES.launch(area, ctx)
	local field = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 120, 70), Size = UDim2.fromScale(1, 0.3), Parent = area })
	UI.corner(field, 10)
	local target = label(field, "🎯", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(36, 36), Position = UDim2.fromScale(0.5, 0.5) })
	local landed = label(field, "💥", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(30, 30), Position = UDim2.fromScale(0, 0.5), Visible = false })
	label(field, "🚀", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromScale(0, 0.3) })
	local angle, power = 45, 3
	local goal = 0.5
	local controls = row(area, 0.36, 0.25, 4)
	local angleL, powerL
	local function refresh()
		angleL.Text = string.format(TG.Angle, angle)
		powerL.Text = string.format(TG.Power, power)
	end
	tapButton(controls, "➖", { LayoutOrder = 1 }, function()
		angle = math.max(15, angle - 15)
		refresh()
	end)
	angleL = label(controls, "", { LayoutOrder = 2, Font = UI.T.body })
	tapButton(controls, "➕", { LayoutOrder = 3 }, function()
		angle = math.min(75, angle + 15)
		refresh()
	end)
	local controls2 = row(area, 0.63, 0.15, 3)
	tapButton(controls2, "➖", { LayoutOrder = 1 }, function()
		power = math.max(1, power - 1)
		refresh()
	end)
	powerL = label(controls2, "", { LayoutOrder = 2, Font = UI.T.body })
	tapButton(controls2, "➕", { LayoutOrder = 3 }, function()
		power = math.min(5, power + 1)
		refresh()
	end)
	local function newTarget()
		-- a target you can really hit: pick a real angle/power and aim there
		local a = ({ 15, 30, 45, 60, 75 })[ctx.rng:NextInteger(1, 5)]
		local p = ctx.rng:NextInteger(2, 5)
		goal = math.clamp((p * p * math.sin(math.rad(2 * a))) / 25, 0.08, 0.98)
		target.Position = UDim2.fromScale(goal, 0.5)
		landed.Visible = false
	end
	local controls3 = row(area, 0.82, 0.17, 1)
	tapButton(controls3, TG.Launch, { BackgroundColor3 = UI.Colors.good }, function()
		if not ctx.alive() then
			return
		end
		local dist = math.clamp((power * power * math.sin(math.rad(2 * angle))) / 25, 0, 1)
		landed.Visible = true
		landed.Position = UDim2.fromScale(dist, 0.5)
		local ok = math.abs(dist - goal) <= 0.05
		ctx.feedback(ok)
		if ok then
			ctx.add(1)
			task.delay(0.5, newTarget)
		end
	end)
	refresh()
	newTarget()
end

-- Coding genius: tap arrow blocks to build a program, RUN moves the robot
function GAMES.robot(area, ctx)
	local n = 5
	local grid = UI.new("Frame", { Position = UDim2.fromScale(0.01, 0), Size = UDim2.fromScale(0.5, 0.75), BackgroundColor3 = Color3.fromRGB(30, 34, 46), Parent = area }, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / n - 0.01, 0, 1 / n - 0.01, 0), CellPadding = UDim2.fromScale(0.01, 0.01), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.corner(grid, 10)
	local cells = {}
	for i = 1, n * n do
		cells[i] = label(grid, "", { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(50, 56, 74), LayoutOrder = i })
	end
	local programL = label(area, "", { Position = UDim2.fromScale(0.55, 0), Size = UDim2.fromScale(0.44, 0.2), TextXAlignment = Enum.TextXAlignment.Left })
	local pad = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.55, 0.22), Size = UDim2.fromScale(0.44, 0.5), Parent = area })
	local bottom = row(area, 0.8, 0.18, 2)
	local start, flag, walls, program = { 1, 1 }, { 5, 5 }, {}, {}
	local busy = false
	local function idx(p)
		return (p[2] - 1) * n + p[1]
	end
	local function draw(bot)
		for i, c in ipairs(cells) do
			c.Text = walls[i] and TG.Wall or ""
		end
		cells[idx(flag)].Text = TG.Flag
		cells[idx(bot)].Text = TG.Robot
		local arrows = {}
		for _, step in ipairs(program) do
			table.insert(arrows, step[3])
		end
		programL.Text = table.concat(arrows, "")
	end
	local function newLevel()
		walls = {}
		start = { 1, ctx.rng:NextInteger(1, n) }
		flag = { n, ctx.rng:NextInteger(1, n) }
		local count = math.min(4, 1 + ctx.level)
		for _ = 1, count do
			local w = { ctx.rng:NextInteger(2, n - 1), ctx.rng:NextInteger(1, n) }
			walls[idx(w)] = true
		end
		program = {}
		draw(start)
	end
	local function add(dx, dy, icon)
		if not busy and #program < 10 then
			table.insert(program, { dx, dy, icon })
			draw(start)
		end
	end
	local function arrow(text, x, y, dx, dy)
		tapButton(pad, text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(0.32, 0.3) }, function()
			add(dx, dy, text)
		end)
	end
	arrow(MG.Up, 0.5, 0.17, 0, -1)
	arrow(MG.Left, 0.17, 0.5, -1, 0)
	arrow(MG.Right2, 0.83, 0.5, 1, 0)
	arrow(MG.Down, 0.5, 0.83, 0, 1)
	tapButton(bottom, TG.Clear, { LayoutOrder = 1 }, function()
		if not busy then
			program = {}
			draw(start)
		end
	end)
	tapButton(bottom, TG.Run, { LayoutOrder = 2, BackgroundColor3 = UI.Colors.good }, function()
		if busy or not ctx.alive() then
			return
		end
		busy = true
		local bot = { start[1], start[2] }
		local ok = false
		for _, step in ipairs(program) do
			local nx, ny = bot[1] + step[1], bot[2] + step[2]
			if nx < 1 or nx > n or ny < 1 or ny > n or walls[idx({ nx, ny })] then
				break -- bonk
			end
			bot = { nx, ny }
			draw(bot)
			task.wait(0.25)
			if bot[1] == flag[1] and bot[2] == flag[2] then
				ok = true
				break
			end
		end
		busy = false
		if not ctx.alive() then
			return
		end
		ctx.feedback(ok)
		if ok then
			ctx.add(1)
			newLevel()
		else
			draw(start)
		end
	end)
	newLevel()
end

-- Business genius: lemonade stand (weather × price × cups → profit; no sums for the player)
function GAMES.lemonade(area, ctx)
	local weatherL = label(area, "", { Size = UDim2.fromScale(1, 0.16) })
	local resultL = label(area, "", { Position = UDim2.fromScale(0, 0.17), Size = UDim2.fromScale(1, 0.12), Font = UI.T.body, TextColor3 = UI.T.muted })
	local priceRow = row(area, 0.32, 0.18, 3)
	local cupsRow = row(area, 0.54, 0.18, 3)
	local openRow = row(area, 0.78, 0.2, 1)
	local weather, price, cups = 1, 2, 2
	local priceB, cupsB = {}, {}
	local function refresh()
		weatherL.Text = TG.Weather[weather]
		for i, b in ipairs(priceB) do
			b.BackgroundColor3 = i == price and UI.T.accent or UI.T.panel2
		end
		for i, b in ipairs(cupsB) do
			b.BackgroundColor3 = i == cups and UI.T.accent or UI.T.panel2
		end
	end
	for i, name in ipairs(TG.Prices) do
		priceB[i] = tapButton(priceRow, name, { LayoutOrder = i }, function()
			price = i
			refresh()
		end)
	end
	for i, c in ipairs(TG.Cups) do
		cupsB[i] = tapButton(cupsRow, string.format(TG.CupsLabel, c), { LayoutOrder = i }, function()
			cups = i
			refresh()
		end)
	end
	tapButton(openRow, TG.OpenStand, { BackgroundColor3 = UI.Colors.good }, function()
		if not ctx.alive() then
			return
		end
		-- sunny = lots of thirsty people; fancy prices scare some away
		local demand = ({ 32, 20, 9 })[weather] * ({ 1.2, 1, 0.6 })[price]
		local made = TG.Cups[cups]
		local sold = math.floor(math.min(made, demand))
		local profit = sold * ({ 1, 2, 3 })[price] - made
		resultL.Text = string.format(TG.DayResult, sold, profit)
		local good = profit >= 15
		ctx.feedback(good)
		if good then
			ctx.add(1)
		end
		weather = ctx.rng:NextInteger(1, 3)
		refresh()
	end)
	weather = ctx.rng:NextInteger(1, 3)
	refresh()
end

-- Chess genius: mate in one (white to move). Pieces are letters in circles (no missing glyphs).
function GAMES.mate(area, ctx)
	label(area, TG.ChessHint, { Size = UDim2.fromScale(1, 0.1), Font = UI.T.body })
	local board = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(1, 0.88), BackgroundTransparency = 1, Parent = area }, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		UI.new("UIGridLayout", { CellSize = UDim2.fromScale(0.125, 0.125), CellPadding = UDim2.new(), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local squares = {}
	local puzzle, chosen = nil, nil
	local function sq(file: number, rank: number): string
		return string.sub("abcdefgh", file, file) .. rank
	end
	local function draw()
		for name, b in pairs(squares) do
			local p = puzzle.pieces[name]
			b.Text = p and string.upper(p) or ""
			b.TextColor3 = (p and p == string.upper(p)) and Color3.new(1, 1, 1) or Color3.new(0.08, 0.08, 0.1)
			b.BackgroundColor3 = b:GetAttribute("Light") and Color3.fromRGB(235, 220, 190) or Color3.fromRGB(150, 110, 80)
			if name == chosen then
				b.BackgroundColor3 = UI.T.accent
			end
			b.TextStrokeTransparency = p and 0.2 or 1
			b.TextStrokeColor3 = (p and p == string.upper(p)) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		end
	end
	local order = 0
	for rank = 8, 1, -1 do
		for file = 1, 8 do
			order += 1
			local name = sq(file, rank)
			local b = UI.new("TextButton", { Text = "", TextScaled = true, Font = UI.T.title, AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = order, Parent = board })
			b:SetAttribute("Light", (file + rank) % 2 == 1)
			squares[name] = b
			b.Activated:Connect(function()
				if not ctx.alive() or not puzzle then
					return
				end
				local p = puzzle.pieces[name]
				if p and p == string.upper(p) then
					chosen = name
				elseif chosen then
					local ok = chosen == puzzle.solution[1] and name == puzzle.solution[2]
					ctx.feedback(ok)
					chosen = nil
					if ok then
						ctx.add(1)
						puzzle = TG.ChessPuzzles[ctx.rng:NextInteger(1, #TG.ChessPuzzles)]
					end
				end
				draw()
			end)
		end
	end
	puzzle = TG.ChessPuzzles[ctx.rng:NextInteger(1, #TG.ChessPuzzles)]
	draw()
end

---------------------------------------------------------------------
-- The framework: start screen, timer, score, server check, result
---------------------------------------------------------------------
-- info: what MinigameService.begin returned. opts.onAgain() = play another; opts.onResult(result)
function Minigames.play(info, opts)
	opts = opts or {}
	local run = GAMES[info.minigame]
	if not run then
		return
	end
	local m = UI.modal(info.title or "", { color = UI.T.accent, big = true })
	UI.label(m.content, info.how or "", { LayoutOrder = 1 })
	UI.label(m.content, string.format(MG.Goal, info.pass or 0) .. "   " .. string.format(MG.Time, info.seconds or 30), { LayoutOrder = 2, TextColor3 = UI.T.muted })
	local finished = false
	local score = 0
	local running = false
	local function finish()
		if finished then
			return
		end
		finished = true
		running = false
		local r = Remote.call("mg_finish", { game = info.minigame, score = score })
		if opts.onResult then
			pcall(opts.onResult, r)
		end
		if not m.alive() or not r or not r.ok then
			return
		end
		m.clear()
		local good = r.passed == true
		UI.label(m.content, good and string.format(MG.ResultGood, r.score) or string.format(MG.ResultMeh, r.score or 0, r.pass or 0), { LayoutOrder = 1, Font = UI.T.title, TextSize = UI.textSize(22), TextColor3 = good and UI.Colors.good or UI.T.text })
		if r.flagged then
			UI.label(m.content, MG.TooFast, { LayoutOrder = 2, TextColor3 = UI.Colors.bad })
		end
		if (r.coins or 0) > 0 then
			UI.label(m.content, string.format(MG.Pay, r.coins), { LayoutOrder = 3, TextColor3 = UI.Colors.gold })
		end
		UI.sound(good and "LevelUp" or "SadTrombone", 0.5)
		if opts.onAgain then
			UI.button(m.content, MG.Again, function()
				m.close()
				opts.onAgain()
			end, { LayoutOrder = 10, BackgroundColor3 = UI.Colors.good })
		end
		UI.button(m.content, MG.Break, function()
			m.close()
		end, { LayoutOrder = 11 })
		m.focus()
	end
	UI.button(m.content, MG.Start, function()
		if running or finished then
			return
		end
		running = true
		m.clear()
		local top = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1, Parent = m.content })
		local timeL = label(top, "", { Size = UDim2.fromScale(0.33, 1), TextXAlignment = Enum.TextXAlignment.Left })
		local scoreL = label(top, "", { Size = UDim2.fromScale(0.33, 1), Position = UDim2.fromScale(0.33, 0) })
		label(top, string.format(MG.Goal, info.pass or 0), { Size = UDim2.fromScale(0.33, 1), Position = UDim2.fromScale(0.66, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UI.T.muted })
		local barBack = UI.new("Frame", { BackgroundColor3 = UI.T.panel2, Size = UDim2.new(1, 0, 0, 8), LayoutOrder = 2, Parent = m.content })
		UI.corner(barBack, 4)
		local barFill = UI.new("Frame", { BackgroundColor3 = UI.T.accent, Size = UDim2.fromScale(1, 1), Parent = barBack })
		UI.corner(barFill, 4)
		local area = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 260), LayoutOrder = 3, Parent = m.content })
		local flash = UI.new("Frame", { BackgroundColor3 = UI.Colors.good, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 30, Parent = area })
		local ctx = {
			level = info.level or 1,
			rng = Random.new(info.seed or os.time()),
		}
		function ctx.alive(): boolean
			return running and m.alive()
		end
		function ctx.add(n: number)
			score += n
			scoreL.Text = string.format(MG.Score, score)
		end
		function ctx.feedback(ok: boolean)
			UI.sound(ok and "BrainCellGained" or "CartoonBoing", 0.3)
			if UI.effects() > 0 and not UI.reducedMotion() then
				flash.BackgroundColor3 = ok and UI.Colors.good or UI.Colors.bad
				flash.BackgroundTransparency = 0.6
				TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			end
		end
		ctx.add(0)
		run(area, ctx)
		local seconds = info.seconds or 30
		local t0 = os.clock()
		task.spawn(function()
			while running and m.alive() do
				local left = math.max(0, seconds - (os.clock() - t0))
				timeL.Text = string.format(MG.Time, math.ceil(left))
				barFill.Size = UDim2.fromScale(left / seconds, 1)
				if left <= 0 then
					break
				end
				task.wait(0.1)
			end
			finish()
		end)
	end, { LayoutOrder = 5, BackgroundColor3 = UI.Colors.good, Size = UDim2.new(1, 0, 0, 56) })
	m.focus()
end

return Minigames

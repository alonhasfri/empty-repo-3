-- Effects: cutscenes and screen effects (death ending, Brain Shredder ban,
-- confetti, viral video, badges).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local C = UI.Colors

local Effects = {}

local function overlay(color: Color3, transparency: number, z: number?)
	return UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		ZIndex = z or 60,
		Parent = UI.gui,
	})
end

local function bigText(parent, text: string, z: number?)
	return UI.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		ZIndex = (z or 60) + 1,
		Parent = parent,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = 120 }) })
end

---------------------------------------------------------------------
-- Confetti
---------------------------------------------------------------------
function Effects.confetti()
	local colors = { C.bad, C.good, C.gold, C.accent, Color3.fromRGB(80, 200, 255) }
	for _ = 1, (UI.settings.reduceFlashing and 25 or 70) do
		local p = UI.new("Frame", {
			Size = UDim2.fromOffset(math.random(6, 12), math.random(10, 18)),
			Position = UDim2.new(math.random(), 0, 0, -20),
			BackgroundColor3 = colors[math.random(1, #colors)],
			Rotation = math.random(0, 360),
			ZIndex = 70,
			Parent = UI.gui,
		})
		local t = TweenService:Create(p, TweenInfo.new(math.random(20, 40) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(p.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1.1, 0),
			Rotation = p.Rotation + math.random(-360, 360),
		})
		t:Play()
		t.Completed:Connect(function()
			p:Destroy()
		end)
	end
end

---------------------------------------------------------------------
-- Death ending
---------------------------------------------------------------------
function Effects.death(d, onDone)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	-- zoom in
	if head then
		camera.CameraType = Enum.CameraType.Scriptable
		local from = camera.CFrame
		local to = CFrame.lookAt(head.Position + head.CFrame.LookVector * 6 + Vector3.new(0, 1, 0), head.Position)
		TweenService:Create(camera, TweenInfo.new(1.2), { CFrame = to }):Play()
		local _ = from
	end
	local o = overlay(Color3.new(0, 0, 0), 1)
	local label = bigText(o, "")
	for _, n in ipairs({ "3", "2", "1" }) do
		label.Text = n
		UI.sound("NotificationPing")
		task.wait(0.9)
	end
	-- half a second of silence
	label.Text = ""
	task.wait(0.5)
	-- EVERYTHING AT ONCE
	for _, s in ipairs({ "AirHorn", "RecordScratch", "DeathBoom", "KazooTune", "SadTrombone", "CartoonBoing" }) do
		UI.sound(s, d.loud and 1.5 or 1)
	end
	if d.loud then
		task.delay(0.3, function()
			UI.sound("AirHorn", 1.5)
			UI.sound("DeathBoom", 1.5)
		end)
	end
	if not UI.settings.reduceFlashing then
		o.BackgroundTransparency = 0.2
		o.BackgroundColor3 = Color3.new(1, 1, 1)
		TweenService:Create(o, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	end
	label.Text = "💀"
	-- the tiny brain floats away
	local brain = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(90, 90),
		BackgroundTransparency = 1,
		Text = "🧠👋",
		TextScaled = true,
		ZIndex = 62,
		Parent = UI.gui,
	})
	TweenService:Create(brain, TweenInfo.new(3, Enum.EasingStyle.Sine), { Position = UDim2.fromScale(0.7, -0.2), Rotation = 30 }):Play()
	task.wait(3)
	brain:Destroy()
	o:Destroy()
	camera.CameraType = Enum.CameraType.Custom
	Effects.confetti()
	if onDone then
		onDone()
	end
end

---------------------------------------------------------------------
-- Ban: the Brain Shredder
---------------------------------------------------------------------
function Effects.banCutscene(d)
	local o = overlay(Color3.fromRGB(20, 0, 30), 0.1, 80)
	local machine = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(260, 180),
		BackgroundColor3 = Color3.fromRGB(60, 60, 80),
		Text = "⚙️ BRAIN SHREDDER ⚙️",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 80, 80),
		ZIndex = 81,
		Parent = o,
	})
	UI.corner(machine, 20)
	local you = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.15, 0.2),
		Size = UDim2.fromOffset(80, 80),
		BackgroundTransparency = 1,
		Text = "🧍",
		TextScaled = true,
		ZIndex = 82,
		Parent = o,
	})
	UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.05),
		Size = UDim2.fromScale(0.9, 0.08),
		BackgroundTransparency = 1,
		Text = tostring(d.by) .. " throws you into the machine…",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 82,
		Parent = o,
	})
	TweenService:Create(you, TweenInfo.new(1.4, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0.5, 0.5), Rotation = 720, Size = UDim2.fromOffset(10, 10) }):Play()
	task.wait(1.5)
	UI.sound("DeathBoom")
	for i = 1, 8 do
		machine.Rotation = (i % 2 == 0) and 4 or -4
		task.wait(0.08)
	end
	machine.Rotation = 0
	local stamp = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 140),
		BackgroundTransparency = 1,
		Text = "BANNED",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 40, 40),
		TextStrokeTransparency = 0,
		Rotation = -12,
		ZIndex = 85,
		Parent = o,
	})
	stamp.Size = UDim2.fromOffset(900, 300)
	TweenService:Create(stamp, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(420, 140) }):Play()
	local tiny = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.75),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		Text = "🧠",
		TextScaled = true,
		ZIndex = 83,
		Parent = o,
	})
	TweenService:Create(tiny, TweenInfo.new(1.5, Enum.EasingStyle.Bounce), { Position = UDim2.fromScale(0.85, 0.95) }):Play()
end

---------------------------------------------------------------------
-- Viral video banner
---------------------------------------------------------------------
function Effects.viral(d)
	local f = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 110),
		Size = UDim2.fromScale(0.8, 0.2),
		BackgroundColor3 = Color3.fromRGB(200, 0, 0),
		ZIndex = 55,
		Parent = UI.gui,
	}, { UI.new("UISizeConstraint", { MaxSize = Vector2.new(520, 140) }) })
	UI.corner(f, 12)
	bigText(f, "📹 " .. tostring(d.youtuber) .. " made a video laughing at your comment:\n\"" .. tostring(d.comment) .. "\"", 55)
	UI.sound("RecordScratch")
	task.delay(5, function()
		f:Destroy()
	end)
end

---------------------------------------------------------------------
-- EUREKA cutscene: pick one of several secret inventions
---------------------------------------------------------------------
local function rays(parent, z: number)
	local holder = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(900, 900),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = parent,
	})
	for i = 1, 12 do
		local ray = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 60, 1, 0),
			Rotation = i * 15,
			BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(255, 220, 60) or Color3.fromRGB(255, 120, 200),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = holder,
		})
		local _ = ray
	end
	task.spawn(function()
		while holder.Parent do
			holder.Rotation += UI.settings.reduceFlashing and 0.2 or 1
			task.wait(0.03)
		end
	end)
	return holder
end

function Effects.eureka(choices, onPick)
	UI.closeModal()
	local o = overlay(Color3.fromRGB(8, 6, 20), 0.05, 90)
	UI.sound("RecordScratch")
	local bulb = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		Text = "💡",
		TextScaled = true,
		ZIndex = 92,
		Parent = o,
	})
	TweenService:Create(bulb, TweenInfo.new(0.8, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(200, 200) }):Play()
	task.wait(0.9)
	local title = bigText(o, "EUREKA!", 92)
	title.Size = UDim2.fromScale(1, 0.15)
	title.Position = UDim2.fromScale(0, 0.06)
	title.TextColor3 = Color3.fromRGB(255, 230, 80)
	UI.sound("GameShowJingle")
	task.wait(1)
	TweenService:Create(bulb, TweenInfo.new(0.4), { Position = UDim2.fromScale(0.5, -0.3) }):Play()
	title.Text = "Choose your secret invention"
	-- cards
	local row = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.new(0.94, 0, 0.55, 0),
		BackgroundTransparency = 1,
		ZIndex = 92,
		Parent = o,
	}, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0.02, 0) }),
		UI.new("UISizeConstraint", { MaxSize = Vector2.new(780, 360) }),
	})
	local picked = false
	for i, inv in ipairs(choices) do
		local card = UI.new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(0.31, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(40, 30, 80),
			Selectable = true,
			ZIndex = 93,
			Parent = row,
		})
		UI.corner(card, 18)
		UI.stroke(card, Color3.fromRGB(255, 220, 80), 3, 0)
		UI.gradient(card, Color3.fromRGB(120, 90, 255), Color3.fromRGB(40, 20, 90), 90)
		local scale = UI.new("UIScale", { Scale = 0, Parent = card })
		task.delay(i * 0.15, function()
			TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end)
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.1, 0.05), Size = UDim2.fromScale(0.8, 0.4), TextScaled = true, Text = inv.icon, ZIndex = 94, Parent = card })
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.47), Size = UDim2.fromScale(0.9, 0.14), TextScaled = true, Font = Enum.Font.FredokaOne, TextColor3 = Color3.new(1, 1, 1), Text = inv.name, ZIndex = 94, Parent = card })
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.06, 0.63), Size = UDim2.fromScale(0.88, 0.32), TextScaled = true, TextWrapped = true, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(220, 215, 255), Text = inv.desc, ZIndex = 94, Parent = card }, {
			UI.new("UITextSizeConstraint", { MaxTextSize = 16 }),
		})
		card.MouseEnter:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
		end)
		card.MouseLeave:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end)
		card.Activated:Connect(function()
			if picked then
				return
			end
			picked = true
			o:Destroy()
			onPick(inv.key)
		end)
		if i == 1 and game:GetService("UserInputService").GamepadEnabled then
			game:GetService("GuiService").SelectedObject = card
		end
	end
end

-- The crazy "SECRET INVENTION UNLOCKED!" popup
function Effects.inventionUnlocked(inv)
	local o = overlay(Color3.fromRGB(10, 0, 30), 0.15, 95)
	rays(o, 96)
	UI.sound("AirHorn")
	UI.sound("LevelUp")
	UI.sound("BadgeSparkle")
	local icon = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		Text = inv.icon,
		TextScaled = true,
		ZIndex = 98,
		Parent = o,
	})
	TweenService:Create(icon, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(220, 220), Rotation = 360 }):Play()
	local top = bigText(o, "SECRET INVENTION UNLOCKED!", 98)
	top.Size = UDim2.fromScale(1, 0.13)
	top.Position = UDim2.fromScale(0, 0.08)
	top.TextColor3 = Color3.fromRGB(255, 230, 60)
	local topScale = UI.new("UIScale", { Parent = top })
	task.spawn(function()
		local i = 0
		while top.Parent do
			i += 1
			topScale.Scale = 1 + math.sin(i / 3) * (UI.settings.reduceFlashing and 0.02 or 0.08)
			if not UI.settings.reduceFlashing then
				top.TextColor3 = Color3.fromHSV((i % 60) / 60, 0.7, 1)
			end
			task.wait(0.03)
		end
	end)
	local name = bigText(o, inv.name, 98)
	name.Size = UDim2.fromScale(1, 0.08)
	name.Position = UDim2.fromScale(0, 0.68)
	local desc = bigText(o, inv.desc .. "\n(Use it from 🎒 Gadgets)", 98)
	desc.Size = UDim2.fromScale(0.9, 0.08)
	desc.Position = UDim2.fromScale(0.05, 0.78)
	desc.Font = Enum.Font.GothamMedium
	Effects.confetti()
	task.delay(1.2, Effects.confetti)
	local close = Instance.new("TextButton")
	close.Size = UDim2.fromScale(1, 1)
	close.BackgroundTransparency = 1
	close.Text = ""
	close.ZIndex = 99
	close.Parent = o
	local done = false
	local function finish()
		if not done then
			done = true
			o:Destroy()
		end
	end
	close.Activated:Connect(finish)
	task.delay(6, finish)
end

---------------------------------------------------------------------
-- COMEBACK cutscene (update 1.1): chase your brain, catch it, pop it back in
---------------------------------------------------------------------
function Effects.comeback()
	UI.closeModal()
	local o = overlay(Color3.fromRGB(30, 40, 70), 0, 88)
	UI.gradient(o, Color3.fromRGB(120, 170, 255), Color3.fromRGB(40, 60, 120), 90)
	local ground = UI.new("Frame", { Position = UDim2.fromScale(0, 0.72), Size = UDim2.fromScale(1, 0.28), BackgroundColor3 = Color3.fromRGB(70, 150, 70), BorderSizePixel = 0, ZIndex = 89, Parent = o })
	local _ = ground
	local function sprite(text, x, y, size)
		return UI.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
			Text = text,
			TextScaled = true,
			ZIndex = 90,
			Parent = o,
		})
	end
	local caption = bigText(o, "", 90)
	caption.Size = UDim2.fromScale(1, 0.12)
	caption.Position = UDim2.fromScale(0, 0.05)
	local ghost = sprite("👻", 0.1, 0.72, 90)
	local brain = sprite("🧠", 0.35, 0.6, 60)
	caption.Text = "Wait… is that MY brain?"
	task.wait(1.5)
	caption.Text = "GET BACK HERE!"
	TweenService:Create(brain, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { Position = UDim2.fromScale(0.85, 0.5) }):Play()
	TweenService:Create(ghost, TweenInfo.new(1, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0.45, 0.72) }):Play()
	task.wait(1)
	-- trip
	TweenService:Create(ghost, TweenInfo.new(0.3), { Rotation = 90 }):Play()
	local bonk = sprite("💥", 0.47, 0.7, 50)
	UI.sound("CavemanBonk")
	task.wait(0.6)
	bonk:Destroy()
	ghost.Rotation = 0
	caption.Text = "*slow-motion dive*"
	TweenService:Create(ghost, TweenInfo.new(1.6, Enum.EasingStyle.Quint), { Position = UDim2.fromScale(0.83, 0.55), Rotation = -25 }):Play()
	task.wait(1.6)
	brain:Destroy()
	ghost.Rotation = 0
	ghost.Text = "🧍"
	UI.sound("CartoonBoing")
	caption.Text = "*squish* 🧠➡️🗣"
	task.wait(1.2)
	caption.Text = "\"i wnt 2 be smrt\""
	UI.sound("LevelUp")
	task.wait(1.8)
	caption.Text = "1 brain cell. Let's go."
	task.wait(1.2)
	o:Destroy()
end

-- Complete Makeover: before / after
function Effects.makeover(d)
	local o = overlay(Color3.fromRGB(10, 10, 25), 0.1, 95)
	rays(o, 96)
	local title = bigText(o, "COMPLETE MAKEOVER", 98)
	title.Size = UDim2.fromScale(1, 0.12)
	title.Position = UDim2.fromScale(0, 0.08)
	title.TextColor3 = Color3.fromRGB(255, 220, 80)
	local before = bigText(o, "BEFORE\n🪨\n0 brain cells", 98)
	before.Size = UDim2.fromScale(0.4, 0.4)
	before.Position = UDim2.fromScale(0.05, 0.3)
	local after = bigText(o, "AFTER\n🧠✨\n" .. tostring(d.cells) .. "\nIQ " .. tostring(d.iq), 98)
	after.Size = UDim2.fromScale(0.4, 0.4)
	after.Position = UDim2.fromScale(0.55, 0.3)
	UI.sound("AirHorn")
	UI.sound("LevelUp")
	Effects.confetti()
	task.delay(1.5, Effects.confetti)
	task.delay(7, function()
		o:Destroy()
	end)
end

---------------------------------------------------------------------
-- UPDATE 1.3: the Noble Prize ceremony + the fake ending
---------------------------------------------------------------------
function Effects.prize(d, onRefuse)
	UI.closeModal()
	local o = overlay(Color3.fromRGB(10, 6, 20), 0, 96)
	-- spotlight
	local light = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 1.2), BackgroundColor3 = Color3.fromRGB(255, 240, 200), BackgroundTransparency = 0.85, ZIndex = 96, Parent = o })
	UI.corner(light, 400)
	local title = bigText(o, "THE NOBLE PRIZE", 97)
	title.Size = UDim2.fromScale(1, 0.12)
	title.Position = UDim2.fromScale(0, 0.06)
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.Font = Enum.Font.Garamond
	local medal = UI.new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Text = "🏅", TextScaled = true, ZIndex = 98, Parent = o })
	TweenService:Create(medal, TweenInfo.new(0.8, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(180, 180) }):Play()
	local line = bigText(o, "for " .. tostring(d.icon) .. " " .. tostring(d.name), 97)
	line.Size = UDim2.fromScale(1, 0.08)
	line.Position = UDim2.fromScale(0, 0.62)
	local sub = bigText(o, (d.first and "🌍 WORLD FIRST! Your statue joins the Hall of Inventors.\n" or "") .. tostring(d.unlock), 97)
	sub.Size = UDim2.fromScale(0.9, 0.1)
	sub.Position = UDim2.fromScale(0.05, 0.71)
	sub.Font = Enum.Font.GothamMedium
	UI.sound("GameShowJingle")
	UI.sound("BadgeSparkle")
	Effects.confetti()
	task.wait(4)
	-- the credits roll… then glitch
	medal:Destroy()
	line:Destroy()
	sub:Destroy()
	light:Destroy()
	title.Text = "THE END"
	local credits = bigText(o, "Created by Cult of the 39\nNarrated by Dr. Wrinkles\nPigeons provided by Tesla\nCoffee beans counted by Beethoven\n\nThank you for playing!", 97)
	credits.Size = UDim2.fromScale(0.8, 0.6)
	credits.Position = UDim2.fromScale(0.1, 1)
	credits.Font = Enum.Font.Garamond
	TweenService:Create(credits, TweenInfo.new(4, Enum.EasingStyle.Linear), { Position = UDim2.fromScale(0.1, 0.25) }):Play()
	task.wait(3.5)
	for _ = 1, 6 do
		if not UI.settings.reduceFlashing then
			o.BackgroundColor3 = Color3.fromRGB(math.random(0, 255), 0, math.random(0, 255))
		end
		credits.Position = UDim2.fromScale(0.1 + (math.random() - 0.5) * 0.05, 0.25)
		task.wait(0.08)
	end
	o.BackgroundColor3 = Color3.fromRGB(10, 6, 20)
	UI.sound("RecordScratch")
	credits.Text = "Wait."
	title.Text = ""
	task.wait(1.2)
	credits.Text = "You're not done yet."
	task.wait(1.6)
	credits.Text = "Next: 🚀 Astronauts, the Space Lab and the World's Smartest… (update 1.4)"
	credits.TextColor3 = Color3.fromRGB(150, 220, 255)
	task.wait(1.5)
	-- accept or refuse (like Perelman)
	local row = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.fromOffset(460, 56), BackgroundTransparency = 1, ZIndex = 98, Parent = o }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12) }),
	})
	UI.autoScale(row)
	local function btn(textValue, color, fn)
		local b = UI.new("TextButton", { Text = textValue, Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = color, Size = UDim2.fromOffset(220, 56), ZIndex = 99, Parent = row }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }) })
		UI.corner(b, 14)
		b.Activated:Connect(fn)
	end
	btn("🏅 Accept the prize", Color3.fromRGB(200, 160, 40), function()
		o:Destroy()
	end)
	btn("🙅 Refuse it (like Perelman)", Color3.fromRGB(90, 60, 140), function()
		o:Destroy()
		if onRefuse then
			onRefuse()
		end
	end)
end

function Effects.testDay(d)
	local f = UI.new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.3, 0), Size = UDim2.fromOffset(460, 70), BackgroundColor3 = Color3.fromRGB(20, 30, 60), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.FredokaOne, TextScaled = true, ZIndex = 60, Parent = UI.gui })
	UI.corner(f, 14)
	UI.autoScale(f)
	for i = 5, 1, -1 do
		f.Text = "🚀 " .. tostring(d.by) .. " tests " .. tostring(d.icon) .. " " .. tostring(d.name) .. "…  " .. i
		task.wait(1)
	end
	f.Text = "✅ IT WORKS!"
	Effects.confetti()
	task.wait(2)
	f:Destroy()
end

---------------------------------------------------------------------
-- Badge popup
---------------------------------------------------------------------
function Effects.badge(d)
	UI.sound("BadgeSparkle")
	UI.toast("🏅 BADGE: " .. tostring(d.name) .. "\n" .. tostring(d.desc), Color3.fromRGB(120, 90, 20), 6)
end

---------------------------------------------------------------------
-- UPDATE 1.4: rocket launch, World's Smartest, the void, the box
---------------------------------------------------------------------
local Remote = require(script.Parent.Remote)

local function fadeOut(frame, seconds: number)
	TweenService:Create(frame, TweenInfo.new(seconds), { BackgroundTransparency = 1 }):Play()
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") then
			TweenService:Create(d, TweenInfo.new(seconds), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, TweenInfo.new(seconds), { BackgroundTransparency = 1 }):Play()
		end
	end
	task.delay(seconds, function()
		frame:Destroy()
	end)
end

local function shake(seconds: number, power: number)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum or UI.settings.reduceFlashing then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < seconds do
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * power, (math.random() - 0.5) * power, 0)
			task.wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end

function Effects.launch(d)
	if d.home then
		local o = overlay(Color3.new(0, 0, 0), 1, 80)
		TweenService:Create(o, TweenInfo.new(0.8), { BackgroundTransparency = 0 }):Play()
		bigText(o, "🌍 Flying home…", 80)
		UI.sound("Whoosh", 0.6)
		task.delay(3.6, function()
			fadeOut(o, 0.8)
		end)
		return
	end
	local o = overlay(Color3.fromRGB(120, 190, 255), 1, 80)
	local label = bigText(o, "", 80)
	TweenService:Create(o, TweenInfo.new(0.5), { BackgroundTransparency = 0.6 }):Play()
	for _, n in ipairs({ "3", "2", "1" }) do
		label.Text = n
		UI.sound("NotificationPing", 0.7)
		task.wait(0.8)
	end
	label.Text = "🚀 LIFTOFF!"
	UI.sound("Whoosh", 1)
	shake(2.2, 0.8)
	-- sky turns to space, stars stream past
	TweenService:Create(o, TweenInfo.new(2), { BackgroundColor3 = Color3.fromRGB(2, 2, 12), BackgroundTransparency = 0 }):Play()
	for _ = 1, (UI.settings.reduceFlashing and 20 or 60) do
		local star = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromOffset(2, math.random(8, 30)), Position = UDim2.new(math.random(), 0, -0.1, 0), ZIndex = 81, Parent = o })
		TweenService:Create(star, TweenInfo.new(math.random(5, 12) / 10, Enum.EasingStyle.Linear), { Position = UDim2.new(star.Position.X.Scale, 0, 1.1, 0) }):Play()
		task.wait(0.03)
	end
	label.Text = d.first and "🧑‍🚀 Your first trip to space!" or "🌌 Space."
	task.wait(1.2)
	label.Text = "🌙 Landing on the Moon…"
	task.wait(1)
	fadeOut(o, 1)
end

function Effects.worldsSmartest(d)
	UI.closeModal()
	local o = overlay(Color3.new(0, 0, 0), 1, 80)
	TweenService:Create(o, TweenInfo.new(1), { BackgroundTransparency = 0.25 }):Play()
	local caption = UI.new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromScale(0.9, 0.1), BackgroundTransparency = 1, Font = Enum.Font.Garamond, TextScaled = true, TextColor3 = Color3.fromRGB(255, 240, 200), TextStrokeTransparency = 0.5, Text = "", ZIndex = 85, Parent = o })
	UI.sound("GameShowJingle", 0.4)
	-- 1) every book in the library flies off the shelves… with your name in it
	local books = {}
	local oldType, oldCF = camera.CameraType, camera.CFrame
	if d.library then
		local lib = d.library
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(lib + Vector3.new(0, 18, 34), lib + Vector3.new(0, 8, 0))
		local colors = { Color3.fromRGB(150, 40, 40), Color3.fromRGB(40, 70, 140), Color3.fromRGB(40, 110, 60), Color3.fromRGB(140, 100, 40) }
		for i = 1, 36 do
			local b = Instance.new("Part")
			b.Anchored = true
			b.CanCollide = false
			b.Size = Vector3.new(1.6, 2.2, 0.5)
			b.Color = colors[(i % #colors) + 1]
			b.Material = Enum.Material.Fabric
			b.CFrame = CFrame.new(lib + Vector3.new(math.random(-16, 16), 1, math.random(-10, 10)))
			b.Parent = workspace
			local sg = Instance.new("SurfaceGui")
			sg.Parent = b
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundColor3 = Color3.fromRGB(250, 245, 230)
			t.Text = tostring(d.name)
			t.TextScaled = true
			t.Font = Enum.Font.Garamond
			t.Parent = sg
			table.insert(books, b)
			local a = i / 36 * math.pi * 2
			TweenService:Create(b, TweenInfo.new(2.5 + math.random(), Enum.EasingStyle.Quad), {
				CFrame = CFrame.new(lib + Vector3.new(math.cos(a) * 14, 10 + math.sin(i) * 4, math.sin(a) * 14)) * CFrame.Angles(0, -a, math.rad(math.random(-20, 20))),
			}):Play()
		end
	end
	caption.Text = "Every book in the library flies off the shelves…"
	task.wait(3)
	caption.Text = "…and opens. Your name is written in every single one."
	task.wait(3)
	-- 2) newspapers + TV
	camera.CameraType = oldType
	camera.CFrame = oldCF
	for _, b in ipairs(books) do
		b:Destroy()
	end
	caption.Text = ""
	for i, h in ipairs(d.headlines or {}) do
		local paper = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.05, 0.05), BackgroundColor3 = Color3.fromRGB(245, 240, 225), Rotation = 720, ZIndex = 82 + i, Parent = o }, {
			UI.new("UIAspectRatioConstraint", { AspectRatio = 1.5 }),
		})
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.04), Size = UDim2.fromScale(0.9, 0.14), Text = "THE BRAINVILLE TIMES", Font = Enum.Font.Garamond, TextScaled = true, TextColor3 = Color3.fromRGB(30, 30, 30), ZIndex = 83 + i, Parent = paper })
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.22), Size = UDim2.fromScale(0.9, 0.36), Text = tostring(h), Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.fromRGB(20, 20, 20), ZIndex = 83 + i, Parent = paper })
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.62), Size = UDim2.fromScale(0.9, 0.3), Text = "📸 " .. tostring(d.name), Font = Enum.Font.Garamond, TextScaled = true, TextColor3 = Color3.fromRGB(60, 60, 60), ZIndex = 83 + i, Parent = paper })
		TweenService:Create(paper, TweenInfo.new(0.7, Enum.EasingStyle.Back), { Size = UDim2.fromScale(0.62, 0.62), Rotation = (i % 2 == 0) and 4 or -4, Position = UDim2.fromScale(0.5 + (i - 2.5) * 0.03, 0.45 + (i - 2.5) * 0.02) }):Play()
		UI.sound("RecordScratch", 0.3)
		task.wait(1.6)
	end
	local tv = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.7, 0.5), BackgroundColor3 = Color3.fromRGB(20, 20, 30), ZIndex = 95, Parent = o })
	UI.corner(tv, 12)
	UI.new("TextLabel", { BackgroundColor3 = Color3.fromRGB(200, 30, 30), Size = UDim2.fromScale(1, 0.2), Text = "🔴 BREAKING NEWS", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 96, Parent = tv })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.28), Size = UDim2.fromScale(0.9, 0.6), Text = tostring(d.name) .. "\nis officially the smartest person in the world.", Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 96, Parent = tv })
	UI.sound("GameShowJingle", 0.8)
	Effects.confetti()
	task.wait(3.5)
	-- 3) choose your title
	tv:Destroy()
	local pick = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.5), BackgroundTransparency = 1, ZIndex = 96, Parent = o }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Text = "👑 The World's Smartest…", Font = Enum.Font.Garamond, TextScaled = true, TextColor3 = C.gold, ZIndex = 97, LayoutOrder = 0, Parent = pick })
	for i, title in ipairs({ "Man", "Woman", "Person" }) do
		local b = UI.button(pick, title, function()
			local r = Remote.call("smartest_title", { title = title })
			if r and r.msg then
				UI.toast(r.msg, C.gold, 6)
			end
			fadeOut(o, 1)
		end, { LayoutOrder = i, Size = UDim2.new(0.6, 0, 0, 50) })
		b.ZIndex = 98
		for _, c in ipairs(b:GetDescendants()) do
			if c:IsA("GuiObject") then
				c.ZIndex = 99
			end
		end
	end
end

function Effects.voidFall()
	local o = overlay(Color3.new(0, 0, 0), 1, 80)
	TweenService:Create(o, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
	local label = bigText(o, "", 80)
	UI.sound("Whoosh", 0.8)
	for _ = 1, 40 do
		local streak = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(80, 80, 90), BorderSizePixel = 0, Size = UDim2.fromOffset(2, math.random(20, 60)), Position = UDim2.new(math.random(), 0, 1.1, 0), ZIndex = 81, Parent = o })
		TweenService:Create(streak, TweenInfo.new(math.random(4, 9) / 10, Enum.EasingStyle.Linear), { Position = UDim2.new(streak.Position.X.Scale, 0, -0.2, 0) }):Play()
	end
	label.Text = "you fall…"
	task.wait(0.8)
	label.Text = "and fall…"
	task.wait(0.8)
	label.Text = "and…"
	task.wait(0.8)
	TweenService:Create(o, TweenInfo.new(0.4), { BackgroundColor3 = Color3.new(1, 1, 1) }):Play()
	label.Text = ""
	task.wait(0.5)
	fadeOut(o, 1.2)
end

function Effects.castleEnter()
	local o = overlay(Color3.fromRGB(150, 110, 60), 1, 80)
	TweenService:Create(o, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
	bigText(o, "📦 *rustle rustle*", 80)
	UI.sound("CartoonBoing", 0.6)
	task.wait(1.4)
	TweenService:Create(o, TweenInfo.new(0.6), { BackgroundColor3 = Color3.fromRGB(20, 10, 15) }):Play()
	task.wait(0.4)
	fadeOut(o, 1)
end

---------------------------------------------------------------------
-- UPDATE 1.6: PROMOTED! (a new staff name tag prints out, coworkers clap)
---------------------------------------------------------------------
function Effects.promoted(d)
	local CT = require(game:GetService("ReplicatedStorage").Shared.Content).Careers
	UI.closeModal()
	local bg = overlay(Color3.fromRGB(11, 13, 26), 0.08, 70)
	UI.gradient(bg, Color3.fromRGB(42, 59, 107), Color3.fromRGB(11, 13, 26), 90)
	local title = bigText(bg, CT.Promoted, 70)
	title.TextColor3 = Color3.fromRGB(255, 216, 74)
	title.Size = UDim2.fromScale(0.8, 0.16)
	title.Position = UDim2.fromScale(0.1, 0.08)
	local sc = UI.new("UIScale", { Scale = 2.5, Parent = title })
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	UI.sound("LevelUp", 0.8)
	-- the staff name tag
	local card = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.42, 0.26), BackgroundColor3 = Color3.fromRGB(250, 250, 245), ZIndex = 72, Parent = bg })
	UI.corner(card, 12)
	UI.new("UIAspectRatioConstraint", { AspectRatio = 2.4, Parent = card })
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.22), Text = "BRAINVILLE • STAFF", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.fromRGB(90, 90, 110), ZIndex = 73, Parent = card })
	local name = UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.25), Size = UDim2.fromScale(0.9, 0.45), Text = d.title or "", MaxVisibleGraphemes = 0, Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.fromRGB(28, 30, 50), ZIndex = 73, Parent = card })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.74), Size = UDim2.fromScale(1, 0.2), Text = "🧠 " .. require(game:GetService("ReplicatedStorage").Shared.Brain).formatNumber(d.cells or 0) .. " brain cells", Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(90, 90, 110), ZIndex = 73, Parent = card })
	local claps = UI.new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.8, 0.1), Text = "", Font = Enum.Font.FredokaOne, TextScaled = true, ZIndex = 72, Parent = bg })
	UI.new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.71), Size = UDim2.fromScale(0.8, 0.06), Text = string.format(CT.PromotedSub, d.payPercent or 50), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 72, Parent = bg })
	local done = false
	local btn = UI.button(bg, CT.BackToWork, function()
		if not done then
			done = true
			fadeOut(bg, 0.3)
		end
	end, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.8), Size = UDim2.new(0.3, 0, 0, 46), ZIndex = 74, BackgroundColor3 = C.good })
	btn.Name = "BackToWork"
	task.spawn(function()
		local total = utf8.len(d.title or "") or 0
		for i = 1, total do
			name.MaxVisibleGraphemes = i
			UI.sound("TypeTick", 0.3)
			task.wait(0.07)
		end
		name.MaxVisibleGraphemes = -1
		claps.Text = string.rep("🧑‍💼", 7)
		task.wait(0.8)
		claps.Text = string.rep("👏", 7)
		Effects.confetti()
	end)
	-- close by itself after a while too
	task.delay(9, function()
		if not done and bg.Parent then
			done = true
			fadeOut(bg, 0.4)
		end
	end)
	if UI.isGamepad() then
		game:GetService("GuiService").SelectedObject = btn
	end
end

---------------------------------------------------------------------
-- UPDATE 1.6: "You are now: 🐶 Dog" (you physically turned into an animal)
---------------------------------------------------------------------
function Effects.transform(d)
	local AT = require(game:GetService("ReplicatedStorage").Shared.Content).Animals
	UI.sound("CartoonBoing", 0.8)
	local bg = overlay(Color3.new(0, 0, 0), 1, 65)
	bg.Active = false
	local big = bigText(bg, string.format(AT.Transform, d.emoji or "", d.name or ""), 65)
	big.Size = UDim2.fromScale(0.8, 0.14)
	big.Position = UDim2.fromScale(0.1, 0.3)
	local sc = UI.new("UIScale", { Scale = 2, Parent = big })
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local sub = bigText(bg, d.sub or "", 65)
	sub.Size = UDim2.fromScale(0.7, 0.06)
	sub.Position = UDim2.fromScale(0.15, 0.46)
	sub.Font = Enum.Font.GothamBold
	task.delay(3.5, function()
		fadeOut(bg, 0.5)
		if d.tip then
			UI.toast(d.tip, nil, 7)
		end
	end)
end

return Effects

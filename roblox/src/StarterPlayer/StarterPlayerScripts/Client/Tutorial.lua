-- Tutorial (update 1.4): a guided, cinematic tutorial for each path.
--
-- Shorter since 1.5: fast typing, NEXT shows as soon as the text is typed, and a
-- "Skip tutorial" button is always there (you can replay it from Settings). The first time:
--   * NOTE cards take over the screen: letterbox bars, the camera flies over the town,
--     music goes quiet, "⚠️ IMPORTANT" slams in, Dr. Wrinkles talks, the text types
--     itself out word by word, key words light up and bounce, a little animation plays.
--     The NEXT button appears as soon as the text is typed.
--   * Key notes have a quick question. Wrong answer = the note plays again.
--   * DO-IT steps: "STEP X OF Y" with a bouncing arrow on the real button. You learn by
--     actually doing it.
-- Progress is saved, so leaving and coming back continues where you were.
-- Settings -> "📖 Replay the tutorial" plays it again (replays CAN be skipped).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Tutorial = {}
Tutorial.target = nil -- function(key) -> GuiObject (set by ClientMain: Hud.target)
Tutorial.save = nil -- function(changes) (set by ClientMain)
Tutorial.openPractice = nil

---------------------------------------------------------------------
-- The notes. Words between ** ** light up.
---------------------------------------------------------------------
local NOTES = {
	loseIntro = {
		bit = 0,
		title = "⚠️ IMPORTANT",
		top = "This is the ONLY text in this game you're allowed to read. Read it.",
		text = "Your goal: lose **all 86 billion** brain cells and reach **0**. Every dumb thing you do takes cells away. Every boring text you READ gives them back. So after this… **skip everything**.",
		art = { "🧠", "➡️", "🥴", "➡️", "💀" },
		color = Color3.fromRGB(255, 70, 140),
	},
	town = {
		bit = 1,
		title = "⚠️ IMPORTANT",
		text = "This game **doesn't really look like a cash grab**. That's on purpose. **The town changes with your brain cells**: it gets louder and cheaper as you get dumber, and fancier and more real as you get smarter. Watch the buildings.",
		textGain = "This game **doesn't really look like a cash grab**. That's on purpose. **The town changes with your brain cells**: right now it's a loud cash-grab town. Get smarter and it turns **cozy**, then **real**, then **fancy**. Watch the buildings.",
		art = { "🎰", "➡️", "🏡", "➡️", "🏙", "➡️", "🏛" },
		cam = "town",
		color = Color3.fromRGB(80, 170, 255),
	},
	losePasses = {
		bit = 2,
		title = "⚠️ IMPORTANT",
		text = "On this path, game passes make you **lose MORE brain cells**. The **dumber** the pass, the **more you lose**. But the whole path is **finishable for free**. You never have to buy anything.",
		art = { "🎟", "=", "🧠📉📉" },
		quiz = { q = "Do you need to buy a pass to finish the Lose path?", options = { "Yes", "No, it's finishable for free" }, answer = 2 },
		color = Color3.fromRGB(255, 190, 40),
	},
	loseFinal = {
		bit = 3,
		title = "YOU'RE READY",
		text = "That's everything. **Skip** every text. Click every **clickbait**. Post **dumb comments**. Keep the 😳 **embarrassment meter under half** or you'll hide behind a bush. At **0** brain cells you **win**… very loudly.",
		art = { "📱", "🔥", "🗿", "💥" },
		color = Color3.fromRGB(255, 70, 140),
	},
	gainIntro = {
		bit = 4,
		title = "⚠️ IMPORTANT",
		top = "Read every word. On this path, reading IS the game.",
		text = "Your goal: grow your brain from **86 billion** cells, raise your **IQ** and climb the job ladder. Books, facts, jobs and inventions make you smarter. Later: **Noble Prizes**, **space**, maybe even **World's Smartest**.",
		art = { "🧠", "📚", "💼", "🔬", "🚀", "👑" },
		color = Color3.fromRGB(70, 140, 255),
	},
	smartToo = {
		bit = 5,
		title = "⚠️ IMPORTANT",
		text = "**Learn for real.** Books, Jack B and BrainTalks teach **real fun facts**, and quick questions check you were paying attention. Your character gets smarter when **you** do.",
		art = { "🧑", "➕", "🧠", "=", "📚✅" },
		quiz = { q = "Who makes your character smarter?", options = { "A game pass", "YOU", "Dr. Wrinkles" }, answer = 2 },
		color = Color3.fromRGB(240, 190, 40),
	},
	flashy = {
		bit = 6,
		title = "⚠️ IMPORTANT",
		text = "**Flashy = dumb.** In this game the **cool-looking** glasses are the **weak** ones. The really smart ones have **boring names** like \"−2.25 SPH Progressive Lens\". If it sparkles, it's probably for beginners.",
		art = { "🕶✨", "<", "👓" },
		quiz = { q = "Which glasses are SMARTER?", options = { "✨ MEGA GALAXY SHADES ✨", "−1.50 SPH Lens" }, answer = 2 },
		color = Color3.fromRGB(180, 120, 255),
	},
	harder = {
		bit = 7,
		title = "⚠️ IMPORTANT",
		text = "**Getting smarter gets harder.** Every IQ point needs **more** brain cells than the last one. The boosts shrink too: **×999** at the start… **×1.01** at the end. That's how real brains work.",
		art = { "×999", "➡️", "×10", "➡️", "×1.01" },
		color = Color3.fromRGB(90, 200, 150),
	},
	rare = {
		bit = 8,
		title = "⚠️ IMPORTANT",
		text = "**Your IQ is real-life rare.** Next to your IQ you'll see things like \"**Only 1 in 31,000** people are this smart\". Those are **real numbers**. Every point you earn really means something.",
		art = { "🧍🧍🧍🧍", "🧍🧍🧍🧍", "⭐" },
		color = Color3.fromRGB(255, 200, 80),
	},
	job = {
		bit = 9,
		title = "⚠️ IMPORTANT",
		text = "**Get a job, go to work.** Jobs unlock with IQ: **Cashier**, **Teacher**, **Doctor**, **Scientist**… You don't click a button: you go to the **real building** (🚕 taxi) and do the **real task**.",
		art = { "💼", "🚕", "🏥", "✅" },
		color = Color3.fromRGB(70, 180, 100),
	},
	workIdeas = {
		bit = 10,
		title = "⚠️ IMPORTANT",
		text = "**Work = ideas.** Every job task fills your 💡 **idea meter**. When it's full: **EUREKA!** You pick a **secret invention**. Smart people don't only work. They **invent**.",
		art = { "🛠", "➡️", "💡💡💡", "➡️", "🦆🥾📡" },
		color = Color3.fromRGB(255, 210, 60),
	},
	stress = {
		bit = 11,
		title = "⚠️ IMPORTANT",
		text = "**Geniuses get stressed.** Jobs and projects raise your 😰 **stress**. Too much and you **freeze**. Fix it like real geniuses did: ☕ count **60 coffee beans** (Beethoven), 😴 a **power nap** (Edison), 🐦 feed **pigeons** (Tesla).",
		art = { "😰", "➡️", "☕😴🐦", "➡️", "😌" },
		quiz = { q = "You're frozen from stress. What fixes it?", options = { "Buy a pass", "Do a genius habit", "Wait forever" }, answer = 2 },
		color = Color3.fromRGB(255, 140, 60),
	},
	money = {
		bit = 12,
		title = "⚠️ IMPORTANT",
		text = "**Money can't buy brains.** On this path the Store has comfort and cosmetics only. **No pass** ever buys brain cells. Your brain is the only thing that grows them.",
		art = { "💰", "≠", "🧠" },
		quiz = { q = "Can a pass buy you brain cells?", options = { "Yes", "No" }, answer = 2 },
		color = Color3.fromRGB(255, 90, 200),
	},
}

-- The guided sequences
local SEQ = {
	-- 1.9.1 fun fixes (docs/Fun review.md: "the Gain start feels like homework"): both tutorials are short and
	-- about DOING things; the old text cards (town, flashy, harder, rare, workIdeas, stress, money, gate) are gone
	-- from the sequence and their notes still exist for later tips.
	Lose = {
		{ note = "loseIntro" },
		{ note = "losePasses" },
		{ practice = true, title = "SKIP A TEXT BOX!", desc = "A boring text box appears. DON'T read it. Find the tiny SKIP button." },
		{ event = "clickbait", target = "phone", title = "CLICK THE CLICKBAIT!", desc = "Open 📱 Phone → ClickNews. Tap the DUMBEST headline." },
		{ event = "steal", target = "phone", title = "PLAY A COPYCAT GAME!", desc = "Open 📱 Phone → Steal A. Pick the dumbest game." },
		{ event = "comments", target = "phone", title = "POST A DUMB COMMENT!", desc = "Open 📱 Phone → Comments. Dumber combo = more cells lost." },
		{ event = "scroller", target = "phone", title = "DOOMSCROLL!", desc = "Open 📱 Phone → BrainTok. Swipe through videos." },
		{ note = "loseFinal" },
	},
	Gain = {
		{ note = "gainIntro" },
		{ event = "library", target = "library", title = "READ A BOOK!", desc = "Tap 📚 Library. Read for real, then answer the question." },
		{ event = "job", target = "phone", title = "GET A JOB!", desc = "Open 📱 Phone → Jobs. Pick one your IQ allows." },
		{ event = "work", target = "work", title = "GO TO WORK!", desc = "Tap 🛠 Work (or take the 🚌 bus) and play your job's minigame.", last = true },
	},
}

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local state = {
	path = nil,
	step = 1,
	replay = false,
	running = false,
	notesSeen = 0,
}

local function hasBit(mask: number, b: number): boolean
	return math.floor(mask / 2 ^ b) % 2 == 1
end
local function setBit(mask: number, b: number): number
	if hasBit(mask, b) then
		return mask
	end
	return mask + 2 ^ b
end

-- 1.4 uses new save keys, so players who did the old small tutorial still get this one
local function key(path: string): string
	return "tut" .. path .. "2"
end

local function bor(a: number, b: number): number
	local out, bit = 0, 1
	while a > 0 or b > 0 do
		if a % 2 == 1 or b % 2 == 1 then
			out += bit
		end
		a, b, bit = math.floor(a / 2), math.floor(b / 2), bit * 2
	end
	return out
end

-- Skipping counts as having seen every note, so no "moment" note pops up right after a skip
local function markAllSeen()
	for _, note in pairs(NOTES) do
		if note.bit then
			state.notesSeen = setBit(state.notesSeen or 0, note.bit)
		end
	end
end

local function persist(extra)
	if state.replay or not Tutorial.save then
		return
	end
	local changes = { tutNotes = state.notesSeen }
	if state.path then
		changes[key(state.path)] = state.step
	end
	for k, v in pairs(extra or {}) do
		changes[k] = v
	end
	Tutorial.save(changes)
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function tween(obj, t: number, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- "**word**" -> highlighted rich text; also returns the list of key words
local function rich(text: string, color: Color3)
	local hex = string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
	local words = {}
	local out = string.gsub(text, "%*%*(.-)%*%*", function(w)
		table.insert(words, w)
		return '<font color="' .. hex .. '"><b>' .. w .. "</b></font>"
	end)
	return out, words
end

local function plainLength(text: string): number
	local s = string.gsub(text, "%*%*", "")
	return utf8.len(s) or #s
end

local musicVolumes = {}
local function duckMusic(on: boolean)
	for _, s in ipairs(SoundService:GetDescendants()) do
		if s:IsA("Sound") and s.Looped then
			if on then
				musicVolumes[s] = s.Volume
				tween(s, 0.8, { Volume = s.Volume * 0.25 })
			elseif musicVolumes[s] then
				tween(s, 0.8, { Volume = musicVolumes[s] })
			end
		end
	end
	if not on then
		musicVolumes = {}
	end
end

local blur = nil
local function setBlur(on: boolean)
	if on then
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "TutorialBlur"
			blur.Size = 0
			blur.Parent = Lighting
		end
		tween(blur, 0.6, { Size = 10 })
	elseif blur then
		local b = blur
		blur = nil
		tween(b, 0.5, { Size = 0 }).Completed:Connect(function()
			b:Destroy()
		end)
	end
end

-- slow fly-over of the plaza for the "town" note
local camConn = nil
local function startFlyover()
	local oldType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	camConn = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - t0) * 0.12
		local center = Vector3.new(0, 4, 0)
		local pos = center + Vector3.new(math.cos(t) * 95, 48 - math.min(14, (os.clock() - t0) * 1.2), math.sin(t) * 95)
		camera.CFrame = CFrame.lookAt(pos, center)
	end)
	return function()
		if camConn then
			camConn:Disconnect()
			camConn = nil
		end
		camera.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
	end
end

---------------------------------------------------------------------
-- NOTE CARD (the cinematic part)
---------------------------------------------------------------------
local root = nil -- current cinematic frame

local function buildStage(color: Color3)
	local stage = UI.new("Frame", { Name = "TutorialStage", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Active = true, ZIndex = 100, Parent = UI.gui })
	-- letterbox bars slide in
	local top = UI.new("Frame", { Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.fromScale(0, -0.1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 101, Parent = stage })
	local bot = UI.new("Frame", { Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 101, Parent = stage })
	tween(stage, 0.6, { BackgroundTransparency = 0.35 })
	tween(top, 0.6, { Position = UDim2.fromScale(0, 0) })
	tween(bot, 0.6, { Position = UDim2.fromScale(0, 0.9) })
	-- colored glow behind the card
	local glow = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.9, 0.7), BackgroundColor3 = color, BackgroundTransparency = 1, ZIndex = 101, Parent = stage })
	UI.corner(glow, 40)
	tween(glow, 1, { BackgroundTransparency = 0.82 })
	return stage, top, bot
end

local function showNote(key: string, onDone)
	local note = NOTES[key]
	if not note then
		onDone()
		return
	end
	local color = note.color or UI.Colors.gold
	local stage, top, bot = buildStage(color)
	root = stage
	duckMusic(true)
	setBlur(note.cam ~= "town")
	local stopCam = note.cam == "town" and startFlyover() or nil
	UI.sound("ImportantSlam", 0.8)

	-- "⚠️ IMPORTANT" slams in on a hazard stripe
	local stripe = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.17), Size = UDim2.fromScale(1.2, 0.09), Rotation = -2, BackgroundColor3 = Color3.fromRGB(255, 210, 40), BorderSizePixel = 0, ZIndex = 102, Parent = stage })
	UI.gradient(stripe, Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 160, 20), 0)
	local titleScale = UI.new("UIScale", { Scale = 3, Parent = stripe })
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = note.title, Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.fromRGB(20, 20, 20), ZIndex = 103, Parent = stripe })
	tween(titleScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(0.35, function()
		if not UI.settings.reduceFlashing then
			for i = 1, 6 do
				stripe.Rotation = -2 + ((i % 2 == 0) and 1.5 or -1.5)
				task.wait(0.04)
			end
			stripe.Rotation = -2
		end
	end)

	-- the card
	local card = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 1.2), Size = UDim2.fromScale(0.86, 0.62), BackgroundColor3 = Color3.fromRGB(255, 252, 245), ZIndex = 102, Parent = stage }, {
		UI.new("UISizeConstraint", { MaxSize = Vector2.new(900, 520) }),
	})
	UI.corner(card, 22)
	UI.stroke(card, color, 4, 0)
	tween(card, 0.6, { Position = UDim2.fromScale(0.5, 0.25) }, Enum.EasingStyle.Back)

	-- Dr. Wrinkles, big, on the left (bobs while "talking")
	local drw = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.015, 0.06), Size = UDim2.fromScale(0.22, 0.62), ZIndex = 103, Parent = card })
	local face = UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.8), Text = "🧠", TextScaled = true, ZIndex = 104, Parent = drw })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.18, 0.28), Size = UDim2.fromScale(0.64, 0.3), Text = "👓", TextScaled = true, ZIndex = 105, Parent = drw })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.8), Size = UDim2.fromScale(1, 0.18), Text = "Dr. Wrinkles", Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(90, 70, 90), ZIndex = 104, Parent = drw })
	local faceScale = UI.new("UIScale", { Parent = face })

	-- optional top line (e.g. "This is the ONLY text you're allowed to read")
	local y = 0.06
	if note.top then
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.26, y), Size = UDim2.fromScale(0.71, 0.13), Text = note.top, Font = Enum.Font.GothamBlack, TextScaled = true, TextWrapped = true, TextColor3 = Color3.fromRGB(220, 30, 60), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 104, Parent = card })
		y += 0.15
	end
	-- typewriter body
	local body = (state.path == "Gain" and note.textGain) or note.text
	local richText, words = rich(body, color:Lerp(Color3.new(0, 0, 0), 0.25))
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.26, y),
		Size = UDim2.fromScale(0.71, 0.5 - (y - 0.06)),
		RichText = true,
		Text = richText,
		MaxVisibleGraphemes = 0,
		Font = Enum.Font.GothamMedium,
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Color3.fromRGB(40, 35, 45),
		ZIndex = 104,
		Parent = card,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = UI.settings.largeText and 34 or 28 }) })

	-- key word chips + animated art row
	local chips = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.26, 0.58), Size = UDim2.fromScale(0.71, 0.1), ZIndex = 104, Parent = card }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	local art = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.03, 0.7), Size = UDim2.fromScale(0.94, 0.16), ZIndex = 104, Parent = card }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})

	-- NEXT / SKIP
	local nextBtn = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -12), Size = UDim2.fromScale(0.3, 0.11), Text = "NEXT ▶", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = color, Visible = false, ZIndex = 105, Parent = card })
	UI.corner(nextBtn, 14)
	UI.stroke(nextBtn, Color3.new(0, 0, 0), 2, 0.4)
	local nextScale = UI.new("UIScale", { Parent = nextBtn })
	local waitLabel = UI.new("TextLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -12), Size = UDim2.fromScale(0.4, 0.08), BackgroundTransparency = 1, Text = "⏳ read it…", Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(150, 140, 150), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 105, Parent = card })
	local closeNote -- set below; lets Skip close the card in one tap
	do
		local skip = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0.11, 6), Size = UDim2.fromOffset(160, 40), Text = state.replay and "Skip ⏭" or "Skip tutorial ⏭", Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(60, 60, 70), ZIndex = 110, Parent = stage })
		UI.corner(skip, 10)
		skip.Activated:Connect(function()
			markAllSeen()
			if state.running then
				state.skipAll = true -- skip the rest of the sequence too
			end
			persist()
			if closeNote then
				closeNote(onDone)
			end
		end)
	end

	local finished = false
	local function close(after)
		if finished then
			return
		end
		finished = true
		if stopCam then
			stopCam()
		end
		setBlur(false)
		duckMusic(false)
		tween(card, 0.35, { Position = UDim2.fromScale(0.5, 1.2) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(stripe, 0.3, { Position = UDim2.fromScale(0.5, -0.2) })
		tween(top, 0.4, { Position = UDim2.fromScale(0, -0.1) })
		tween(bot, 0.4, { Position = UDim2.fromScale(0, 1) })
		tween(stage, 0.45, { BackgroundTransparency = 1 })
		task.delay(0.5, function()
			stage:Destroy()
			if root == stage then
				root = nil
			end
			after()
		end)
	end

	closeNote = close

	-- play the note (and again if a quiz answer was wrong)
	local function play()
		label.MaxVisibleGraphemes = 0
		for _, c in ipairs(chips:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for _, c in ipairs(art:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		nextBtn.Visible = false
		waitLabel.Visible = false
		local total = plainLength(body)
		local speed = UI.settings.extraTime and 40 or 70 -- characters per second
		task.spawn(function()
			task.wait(0.25)
			local shown = 0
			while shown < total and stage.Parent do
				if state.skipAll then
					shown = total
				else
					shown += 1
				end
				label.MaxVisibleGraphemes = shown
				faceScale.Scale = 1 + ((shown % 6 < 3) and 0.05 or 0)
				if shown % 4 == 0 then
					UI.sound("TypeTick", 0.15)
				end
				task.wait(1 / speed)
			end
			label.MaxVisibleGraphemes = -1
			faceScale.Scale = 1
			-- key words bounce in
			for i, w in ipairs(words) do
				if i > 4 then
					break
				end
				local chip = UI.new("TextLabel", { BackgroundColor3 = color, Size = UDim2.new(0, 10, 0.9, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "  " .. w .. "  ", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 105, Parent = chips }, {
					UI.new("UITextSizeConstraint", { MaxTextSize = 20 }),
				})
				UI.corner(chip, 10)
				local sc = UI.new("UIScale", { Scale = 0, Parent = chip })
				tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
				UI.sound("NotificationPing", 0.15)
				task.wait(0.18)
			end
			-- the little animation
			for _, e in ipairs(note.art or {}) do
				local a = UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0, 10, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = e, Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.fromRGB(60, 50, 60), ZIndex = 105, Parent = art })
				local sc = UI.new("UIScale", { Scale = 0, Parent = a })
				tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
				task.wait(0.22)
			end
		end)
		-- NEXT appears when the typing ends
		local readTime = 0.4 + plainLength(body) / speed
		task.delay(state.replay and 0.8 or readTime, function()
			if not stage.Parent then
				return
			end
			waitLabel.Visible = false
			nextBtn.Visible = true
			UI.sound("LevelUp", 0.3)
			task.spawn(function()
				while nextBtn.Parent and nextBtn.Visible do
					tween(nextScale, 0.45, { Scale = 1.08 }, Enum.EasingStyle.Sine)
					task.wait(0.45)
					tween(nextScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Sine)
					task.wait(0.45)
				end
			end)
		end)
	end

	local function quiz()
		local q = note.quiz
		label.MaxVisibleGraphemes = -1
		label.RichText = true
		label.Text = "<b>Quick check:</b> " .. q.q
		for _, c in ipairs(chips:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for _, c in ipairs(art:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		nextBtn.Visible = false
		local row = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.26, 0.56), Size = UDim2.fromScale(0.71, 0.3), ZIndex = 105, Parent = card }, {
			UI.new("UIListLayout", { Padding = UDim.new(0, 6) }),
		})
		for i, opt in ipairs(q.options) do
			local b = UI.new("TextButton", { Size = UDim2.new(1, 0, 1 / #q.options, -6), Text = opt, Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(70, 70, 90), ZIndex = 106, Parent = row }, {
				UI.new("UITextSizeConstraint", { MaxTextSize = 22 }),
			})
			UI.corner(b, 10)
			b.Activated:Connect(function()
				if i == q.answer then
					b.BackgroundColor3 = UI.Colors.good
					UI.sound("LevelUp", 0.6)
					task.wait(0.6)
					row:Destroy()
					close(onDone)
				else
					b.BackgroundColor3 = UI.Colors.bad
					UI.sound("SadTrombone", 0.5)
					for k = 1, 6 do
						card.Position = UDim2.new(0.5, (k % 2 == 0) and 8 or -8, 0.25, 0)
						task.wait(0.04)
					end
					card.Position = UDim2.fromScale(0.5, 0.25)
					label.Text = "Not quite. <b>Watch it again.</b>"
					task.wait(1.2)
					row:Destroy()
					label.Text = richText
					play()
				end
			end)
		end
	end

	nextBtn.Activated:Connect(function()
		if not nextBtn.Visible then
			return
		end
		nextBtn.Visible = false
		if note.quiz and not state.skipAll then
			quiz()
		else
			close(onDone)
		end
	end)
	play()
end

---------------------------------------------------------------------
-- DO-IT STEP (non-blocking card + bouncing arrow on the real button)
---------------------------------------------------------------------
local doCard, arrow, ring, arrowConn = nil, nil, nil, nil

local function clearDo()
	if arrowConn then
		arrowConn:Disconnect()
		arrowConn = nil
	end
	for _, g in ipairs({ doCard, arrow, ring }) do
		if g then
			g:Destroy()
		end
	end
	doCard, arrow, ring = nil, nil, nil
end

local function showDo(step, index: number, count: number)
	clearDo()
	doCard = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -120), Size = UDim2.fromOffset(380, 96), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 40, Parent = UI.gui })
	UI.autoScale(doCard)
	UI.corner(doCard, 16)
	UI.stroke(doCard, Color3.fromRGB(10, 40, 120), 3, 0)
	UI.gradient(doCard, Color3.fromRGB(70, 140, 255), Color3.fromRGB(30, 80, 200), 90)
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(60, 60), Text = "🧠", TextScaled = true, ZIndex = 41, Parent = doCard })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 6), Size = UDim2.new(1, -90, 0, 18), Text = "STEP " .. index .. " OF " .. count, Font = Enum.Font.GothamBlack, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 220, 60), ZIndex = 41, Parent = doCard })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 24), Size = UDim2.new(1, -90, 0, 30), Text = step.title, Font = Enum.Font.FredokaOne, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.4, ZIndex = 41, Parent = doCard })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 56), Size = UDim2.new(1, -90, 0, 34), Text = step.desc, Font = Enum.Font.GothamBold, TextScaled = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(230, 240, 255), ZIndex = 41, Parent = doCard })
	do
		local skip = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(22, 22), Text = "X", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 42, Parent = doCard })
		skip.Activated:Connect(function()
			-- first time: counts as done, so it won't come back (replay it from Settings)
			if Tutorial.skipNow then
				Tutorial.skipNow()
			else
				Tutorial.stop()
			end
		end)
	end
	tween(doCard, 0.5, { Position = UDim2.new(0.5, 0, 0, 66) }, Enum.EasingStyle.Back)
	UI.sound("NotificationPing", 0.5)

	-- arrow + highlight ring on the real button
	if step.target and Tutorial.target then
		arrow = UI.new("TextLabel", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(54, 54), BackgroundTransparency = 1, Text = "👈", TextScaled = true, ZIndex = 45, Parent = UI.gui })
		ring = UI.new("Frame", { BackgroundTransparency = 1, ZIndex = 44, Parent = UI.gui })
		UI.corner(ring, 18)
		local stroke = UI.stroke(ring, Color3.fromRGB(255, 230, 60), 4, 0)
		local _ = stroke
		local t0 = os.clock()
		arrowConn = RunService.RenderStepped:Connect(function()
			local target = Tutorial.target(step.target)
			local show = target ~= nil and target.Parent ~= nil and target.Visible and not UI.isModalOpen()
			arrow.Visible = show
			ring.Visible = show
			if show then
				local p, s = target.AbsolutePosition, target.AbsoluteSize
				local bounce = math.sin((os.clock() - t0) * 7) * 8
				arrow.Position = UDim2.fromOffset(p.X + s.X + 6 + bounce, p.Y + s.Y / 2)
				ring.Position = UDim2.fromOffset(p.X - 5, p.Y - 5)
				ring.Size = UDim2.fromOffset(s.X + 10, s.Y + 10)
				ring.BackgroundTransparency = 0.75 + math.sin((os.clock() - t0) * 7) * 0.15
				ring.BackgroundColor3 = Color3.fromRGB(255, 230, 60)
			end
		end)
	end
end

-- A fake boring text box for the Lose "skip it" practice
local function practiceBox(onDone)
	local m = UI.modal("📖 A Very Important Text", { color = Color3.fromRGB(120, 120, 140) })
	UI.label(m.content, "The mitochondria is the powerhouse of the cell. Photosynthesis converts light energy into chemical energy. The French Revolution began in 1789. Water is made of hydrogen and oxygen. The speed of light is about 300,000 km per second. This text is very long on purpose. Reading it would make you smarter. That would be bad for you.", { LayoutOrder = 1, TextColor3 = Color3.fromRGB(90, 90, 100) })
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 2, Parent = m.content })
	local skip = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(54, 24), Text = "skip", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(120, 120, 130), BackgroundColor3 = Color3.fromRGB(230, 230, 235), Parent = row })
	UI.corner(skip, 6)
	-- the arrow helps you find it
	local hint = UI.new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0, 12), Size = UDim2.fromOffset(40, 30), BackgroundTransparency = 1, Text = "👉", TextScaled = true, Parent = row })
	task.spawn(function()
		local t0 = os.clock()
		while hint.Parent do
			hint.Position = UDim2.new(1, -62 + math.sin((os.clock() - t0) * 8) * 6, 0, 12)
			task.wait()
		end
	end)
	skip.Activated:Connect(function()
		m.close()
		UI.toast("✅ PERFECT. You skipped it. Skipping = dumber = your goal.", UI.Colors.good, 4)
		onDone()
	end)
	m.focus()
end

---------------------------------------------------------------------
-- Running the sequence
---------------------------------------------------------------------
local function finish()
	clearDo()
	state.running = false
	if not state.replay and state.path then
		persist({ [key(state.path) .. "Done"] = true })
		UI.toast("🎓 Tutorial complete! Dr. Wrinkles is proud of you (in his own way).", UI.Colors.good, 6)
	end
	state.replay = false
	state.skipAll = false
end

local runStep

function Tutorial.skipNow()
	markAllSeen()
	finish()
end

local function advance()
	state.step += 1
	persist()
	runStep()
end

function runStep()
	local seq = state.path and SEQ[state.path]
	if not seq or not state.running then
		return
	end
	local step = seq[state.step]
	if not step then
		finish()
		return
	end
	-- don't interrupt a death screen or cutscene: wait a moment and retry
	if UI.state and UI.state.dead then
		return
	end
	if step.note then
		clearDo()
		local note = NOTES[step.note]
		if state.skipAll then
			advance()
			return
		end
		UI.closeModal()
		showNote(step.note, function()
			if note then
				state.notesSeen = setBit(state.notesSeen, note.bit)
			end
			advance()
		end)
	elseif step.practice then
		if state.skipAll then
			advance()
			return
		end
		showDo(step, state.step, #seq)
		task.delay(1.2, function()
			practiceBox(function()
				advance()
			end)
		end)
	else
		if state.skipAll then
			finish()
			return
		end
		showDo(step, state.step, #seq)
	end
end

-- A game action happened (from Stations): does it complete the current DO step?
function Tutorial.event(name: string)
	if not state.running then
		return
	end
	local seq = state.path and SEQ[state.path]
	local step = seq and seq[state.step]
	if step and step.event == name then
		UI.sound("LevelUp", 0.7)
		UI.toast("✅ " .. step.title:gsub("!", "") .. " — done!", UI.Colors.good, 3)
		clearDo()
		task.delay(1.2, function()
			if state.running then
				advance()
			end
		end)
	end
end

function Tutorial.stop()
	clearDo()
	if root then
		root:Destroy()
		root = nil
	end
	setBlur(false)
	duckMusic(false)
	if camConn then
		camConn:Disconnect()
		camConn = nil
		camera.CameraType = Enum.CameraType.Custom
	end
	state.running = false
	state.replay = false
	state.skipAll = false
end

-- Called on every state update from the server
function Tutorial.onState(st)
	local s = st.settings or {}
	state.notesSeen = bor(s.tutNotes or 0, state.notesSeen or 0)
	if st.dead or not st.path then
		if state.running and not state.replay then
			Tutorial.stop()
		end
		state.path = st.path
		return
	end
	if st.path ~= state.path then
		if state.running then
			Tutorial.stop()
		end
		state.path = st.path
		if not s[key(st.path) .. "Done"] then
			-- first time on this path (or coming back mid-tutorial): it starts, no skipping
			state.step = math.clamp(s[key(st.path)] or 1, 1, #SEQ[st.path])
			state.running = true
			state.replay = false
			task.delay(1.5, runStep)
		end
	end
	-- "moment" notes: if something happens before you reached its note, show it right then
	if not state.running and st.path == "Gain" then
		if st.glasses and not hasBit(state.notesSeen, NOTES.flashy.bit) then
			Tutorial.moment("flashy")
		elseif (st.stress or 0) >= 40 and not hasBit(state.notesSeen, NOTES.stress.bit) then
			Tutorial.moment("stress")
		end
	end
end

-- Play one note on its own (moment notes)
local momentBusy = false
function Tutorial.moment(key: string)
	local note = NOTES[key]
	if not note or momentBusy or root then
		return
	end
	momentBusy = true
	state.notesSeen = setBit(state.notesSeen, note.bit)
	persist()
	task.delay(0.5, function()
		UI.closeModal()
		showNote(key, function()
			momentBusy = false
		end)
	end)
end

function Tutorial.replay()
	local st = UI.state
	if not st or not st.path then
		UI.toast("Pick a path first, then replay its tutorial.")
		return
	end
	Tutorial.stop()
	state.path = st.path
	state.step = 1
	state.replay = true
	state.running = true
	state.skipAll = false
	runStep()
end

function Tutorial.reset()
	Tutorial.stop()
	state.path = nil
	state.notesSeen = 0
end

-- Store opened for the first time on the Gain path -> "Money can't buy brains"
function Tutorial.onShop()
	local st = UI.state
	if st and st.path == "Gain" and not state.running and not hasBit(state.notesSeen, NOTES.money.bit) then
		Tutorial.moment("money")
	end
end

return Tutorial

-- Hud: the main screen, laid out like a real simulator game.
--   Top-left:     brain counter (movable in Settings)
--   Left:         2-column grid of activity buttons (icons + labels)
--   Top-center:   title banner + "STEP X OF Y" tutorial card
--   Right:        settings/staff buttons, big SHOP and MAP buttons
--   Bottom-center: brain bar (like a level bar) + meter + pass buttons (cash-grab look)
--   Right-bottom: Dr. Wrinkles speech bubble
-- Everything re-themes with your brain (lobby and Lose path = loud cash grab).

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local Shared = ReplicatedStorage.Shared
local Brain = require(Shared.Brain)
local Config = require(Shared.Config)
local Narration = require(Shared.Narration)
local Content = require(Shared.Content)

local UI = require(script.Parent.UI)

local Hud = {}
Hud.onMenu = nil
Hud.onAdmin = nil
Hud.onStation = nil
Hud.onChoosePath = nil
Hud.onBuyPass = nil
Hud.onSaveSettings = nil

local themed = {}
local function themedPart(fn)
	table.insert(themed, fn)
	fn(UI.T)
end
UI.onTheme(function(T)
	for _, fn in ipairs(themed) do
		pcall(fn, T)
	end
end)

local function outlined(label: TextLabel, thickness: number?)
	local s = label:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = Color3.new(0, 0, 0)
	s.Thickness = thickness or 2
	s.Parent = label
	return s
end

-- 1.7.2: HUD buttons stay thumb-sized on small phones (48 px AFTER the device shrink)
local MT = UI.minTouch()

local function text(parent, props)
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	})
	for k, v in pairs(props) do
		l[k] = v
	end
	return l
end

---------------------------------------------------------------------
-- TOP-LEFT: brain counter
---------------------------------------------------------------------
local top = UI.new("Frame", { Name = "Counter", Position = UDim2.new(0, 10, 0, 6), Size = UDim2.fromOffset(240, 62), Parent = UI.gui })
local topScale = UI.new("UIScale", { Parent = top })
local brainIcon = text(top, { Position = UDim2.fromOffset(4, 2), Size = UDim2.fromOffset(58, 58), Text = "🧠" })
local cellsLabel = text(top, { Position = UDim2.fromOffset(64, 4), Size = UDim2.new(1, -70, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Text = "86,000,000,000" })
outlined(cellsLabel, 2.5)
local chipRow = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 36), Size = UDim2.new(1, -70, 0, 20), Parent = top }, {
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }),
})
local iqChip = UI.chip(chipRow, "IQ 100", Color3.fromRGB(255, 170, 40), { TextSize = UI.textSize(12), Size = UDim2.fromOffset(10, UI.textSize(12) + 6) })
local coinChip = UI.chip(chipRow, "", Color3.fromRGB(230, 180, 30), { TextSize = UI.textSize(12), Size = UDim2.fromOffset(10, UI.textSize(12) + 6), Visible = false })
themedPart(function(T)
	-- 1.9 kit: the counter card is a calm panel with a thin light outline (was darkened theme + black stroke)
	top.BackgroundColor3 = T.bg
	top.BackgroundTransparency = 0.12
	UI.corner(top, 12)
	UI.stroke(top, Color3.new(1, 1, 1), 2, 0.88)
	cellsLabel.Font = T.title
	iqChip.Font = T.font
	coinChip.Font = T.font
end)

-- 1.9 (UI judge): ONE chip row under the counter card for status and career (no floating status lines)
local P19 = Content.Phone19
local infoRow = UI.new("Frame", { Name = "Chips", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, 4), Size = UDim2.new(1, 60, 0, 22), Parent = top }, {
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})
local function updateChips(st)
	for _, c in ipairs(infoRow:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	local chips = {}
	if st.stage and st.stage ~= "human" and st.stageEmoji then
		table.insert(chips, { st.stageEmoji .. " " .. tostring(st.stageName or ""), UI.T.accent })
	end
	if st.job and st.path == "Gain" then
		table.insert(chips, { string.format(P19.ChipJob, tostring((st.career and st.career.title) or st.job)), Color3.fromRGB(70, 160, 110) })
	end
	if st.frozen then
		table.insert(chips, { P19.ChipStress, UI.Colors.bad })
	end
	if st.comeback then
		table.insert(chips, { P19.ChipComeback, Color3.fromRGB(150, 90, 200) })
	end
	if st.canSave == false then
		table.insert(chips, { P19.ChipNoSave, UI.Colors.bad })
	end
	for i, c in ipairs(chips) do
		if i > 3 then
			break -- never more than one tidy row
		end
		UI.chip(infoRow, c[1], c[2], { LayoutOrder = i, TextSize = UI.textSize(12), Size = UDim2.fromOffset(10, UI.textSize(12) + 8) })
	end
	infoRow.Visible = #chips > 0 and not st.dead
end

-- 1.9 Gain path redesign: the progress path strip (Job → Shift → Promotion → Next job), under the chips
local PS = Content.PathStrip
local stackH = 96 -- how tall the counter + chips (+ strip) column is; the activity buttons sit under it
local strip = UI.new("Frame", { Name = "PathStrip", Position = UDim2.new(0, 0, 1, 30), Size = UDim2.new(1, 0, 0, 48), Visible = false, Parent = top })
UI.corner(strip, 12)
UI.stroke(strip, Color3.new(1, 1, 1), 2, 0.88)
local stepsRow = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 3), Size = UDim2.new(1, -64, 0, 16), Parent = strip }, {
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local stepLabels = {}
for i, name in ipairs(PS.Steps) do
	stepLabels[i] = UI.new("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), Font = Enum.Font.GothamBold, TextSize = 11, Text = (i > 1 and "› " or "") .. name, LayoutOrder = i, Parent = stepsRow })
end
local stripText = UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 19), Size = UDim2.new(1, -64, 0, 14), Font = Enum.Font.GothamMedium, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = strip }, { UI.new("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 8 }) }) -- 1.9.1: longer "next step" lines shrink to fit
local stripBar = UI.new("Frame", { Position = UDim2.fromOffset(8, 36), Size = UDim2.new(1, -64, 0, 6), BackgroundColor3 = Color3.fromRGB(60, 66, 90), Parent = strip })
UI.corner(stripBar, 3)
local stripFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), Parent = stripBar })
UI.corner(stripFill, 3)
local stripGo = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(48, 36), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), Text = PS.Go, Parent = strip })
UI.corner(stripGo, 10)
local stripTarget = nil
stripGo.Activated:Connect(function()
	if stripTarget and Hud.onStation then
		Hud.onStation(stripTarget)
	end
end)
local function updateStrip(st)
	local human = st.stage == "human" or st.stage == "barelyhuman" or st.stage == nil
	local show = st.path == "Gain" and not st.dead and human
	strip.Visible = show
	stackH = show and 150 or 96
	if not show then
		return
	end
	local T = UI.T
	strip.BackgroundColor3 = T.bg
	strip.BackgroundTransparency = 0.12
	stripFill.BackgroundColor3 = T.accent
	stripGo.BackgroundColor3 = T.accent
	local c = st.career
	local step, msg, share, go = 1, PS.PickJob, 0, "jobs"
	-- 1.9.1 (user: "make the progression easier to know what you're gonna do next"): every line says the
	-- next action AND what it gets you (the next title, what unlocks), and GO takes you there.
	local needLevel = Config.Inventions and Config.Inventions.NeedLevel or 3
	local sci = c and c.jobId == "scientist"
	if (st.stress or 0) >= Config.PathStrip.StressBreakAt then
		step, msg, share, go = c and 2 or 1, PS.Break, (st.stress or 0) / 100, "coffee"
	elseif not c and (st.iq or 0) < PS.FirstJobIQ then
		step, msg, share, go = 1, string.format(PS.ReadFirst, PS.FirstJobIQ), (st.iq or 0) / PS.FirstJobIQ, "library"
	elseif not c then
		step, msg, share, go = 1, PS.PickJob, 0, "jobs"
	elseif c.project then
		step, msg, share, go = 4, string.format(PS.Project, c.project.icon, c.project.name, c.project.phase or 1), ((c.project.phase or 1) - 1) / 6, "lab"
	elseif sci and c.level >= needLevel and not (c.nextXP and c.xp >= c.nextXP) then
		step, msg, share, go = 4, PS.Invent, 1, "lab"
	elseif c.level >= 4 then
		step, msg, share = 4, st.geniusOpen and PS.Genius or PS.Top, 1
		go = st.geniusOpen and "genius" or "jobs"
	elseif c.nextXP and c.xp >= c.nextXP then
		step, msg, share, go = 3, string.format(PS.PromoIQ, c.nextIQ or 0, c.nextTitle or "?"), 1, "library"
	else
		local unlock = (sci and c.level + 1 == needLevel) and PS.UnlocksInventions or PS.UnlocksPay
		step, msg, share, go = 2, string.format(PS.Promo, c.xp or 0, c.nextXP or 1, c.nextTitle or "?", unlock), (c.xp or 0) / math.max(1, c.nextXP or 1), "work"
	end
	for i, l in ipairs(stepLabels) do
		l.TextColor3 = i == step and T.accent or (i < step and Color3.fromRGB(200, 205, 215) or Color3.fromRGB(120, 126, 145))
	end
	stripText.Text = msg
	stripFill.Size = UDim2.fromScale(math.clamp(share, 0.02, 1), 1)
	stripTarget = go
end

---------------------------------------------------------------------
-- LEFT: activity grid
---------------------------------------------------------------------
local ACTIVITIES = {
	none = {},
	-- 1.9 phone = main menu: only the Phone and Quick Play stay on the screen (plus 🆘 Unstuck top right);
	-- every other activity is an app in the phone now
	Lose = {
		{ key = "phone", icon = "📱", name = "Phone", color = Color3.fromRGB(150, 80, 250) },
		{ key = "quickplay", icon = "⚡", name = "Quick Play", color = Color3.fromRGB(240, 170, 20) }, -- 1.8.5 tester feedback
	},
	Gain = {
		{ key = "phone", icon = "📱", name = "Phone", color = Color3.fromRGB(150, 80, 250) },
		{ key = "quickplay", icon = "⚡", name = "Quick Play", color = Color3.fromRGB(240, 170, 20) }, -- 1.8.5 tester feedback
	},
}

local grid = UI.new("ScrollingFrame", {
	Name = "Activities",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 8, 0, 74),
	Size = UDim2.new(0, 132, 1, -250),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3,
	BorderSizePixel = 0,
	Selectable = false,
	Parent = UI.gui,
}, {
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(math.max(60, MT), math.max(60, MT)), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	UI.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 2) }),
	UI.new("UISizeConstraint", { MinSize = Vector2.new(132, 140) }),
})

local function iconButton(parent, item, order: number, onClick)
	local T = UI.T
	local b = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		-- 1.9 UI overhaul: ONE neutral tile colour (the judge: "every button a different saturated colour");
		-- the activity's own colour is only a thin stripe at the top, so tiles stay recognisable
		BackgroundColor3 = T.bg,
		BackgroundTransparency = 0.15,
		LayoutOrder = order,
		Selectable = true,
		Size = UDim2.fromOffset(math.max(60, MT), math.max(60, MT)),
		Parent = parent,
	})
	UI.corner(b, 12)
	UI.stroke(b, Color3.new(1, 1, 1), 2, 0.88)
	local stripe = UI.new("Frame", { Position = UDim2.new(0.2, 0, 0, 0), Size = UDim2.new(0.6, 0, 0, 3), BackgroundColor3 = item.color, BorderSizePixel = 0, Parent = b })
	UI.corner(stripe, 2)
	text(b, { Position = UDim2.new(0.2, 0, 0, 6), Size = UDim2.new(0.6, 0, 0.5, 0), Text = item.icon })
	-- labels: a fixed 13 px white bold label (never auto-scaled, so "Quick Play" matches its neighbours)
	local name = text(b, { Position = UDim2.new(0, 2, 1, -20), Size = UDim2.new(1, -4, 0, 16), Text = item.name, Font = Enum.Font.GothamBold, TextScaled = true })
	UI.new("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 9, Parent = name }) -- shrinks long names like "Quick Play" to fit instead of cutting them
	local _ = name
	local scale = UI.new("UIScale", { Parent = b })
	local function s(v)
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = v }):Play()
	end
	b.MouseEnter:Connect(function()
		s(1.08)
	end)
	b.MouseLeave:Connect(function()
		s(1)
	end)
	b.SelectionGained:Connect(function()
		s(1.1)
	end)
	b.SelectionLost:Connect(function()
		s(1)
	end)
	b.MouseButton1Down:Connect(function()
		s(0.9)
	end)
	b.Activated:Connect(function()
		s(1)
		UI.sound("CartoonBoing", 0.25)
		onClick()
	end)
	if T.wobble and UI.effects() > 0 and not UI.reducedMotion() then
		b.Rotation = math.random(-6, 6)
	end
	return b
end

local gridPath = "?"
local function buildGrid(path: string?)
	local key = path or "none"
	if key == gridPath then
		return
	end
	gridPath = key
	for _, c in ipairs(grid:GetChildren()) do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	Hud.targets = {}
	-- 1.8.1 UI review: one tidy column with at most Config.UI.HudMaxButtons; the rest go in "☰ More"
	local all = ACTIVITIES[key] or {}
	local maxB = Config.UI.HudMaxButtons
	local shown = #all > maxB and maxB - 1 or #all
	for i = 1, shown do
		local item = all[i]
		Hud.targets[item.key] = iconButton(grid, item, i, function()
			if Hud.onStation then
				Hud.onStation(item.key)
			end
		end)
	end
	if #all > shown then
		local more = iconButton(grid, { key = "more", icon = "➕", name = Content.HudMore.Button, color = Color3.fromRGB(70, 70, 90) }, shown + 1, function()
			local m = UI.modal(Content.HudMore.Title, { color = Color3.fromRGB(70, 70, 90) })
			for i, item in ipairs(all) do
				UI.button(m.content, item.icon .. "  " .. item.name, function()
					m.close()
					if Hud.onStation then
						Hud.onStation(item.key)
					end
				end, { LayoutOrder = i, BackgroundColor3 = item.color })
			end
			m.focus()
		end)
		-- the tutorial points at a hidden activity's button: point it at "More" instead
		for i = shown + 1, #all do
			Hud.targets[all[i].key] = more
		end
	end
end
UI.onTheme(function()
	local p = gridPath
	gridPath = "?"
	buildGrid(p ~= "none" and p or nil)
end)

---------------------------------------------------------------------
-- TOP-CENTER: title banner + tutorial card
---------------------------------------------------------------------
local banner = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.fromOffset(330, 54), Parent = UI.gui })
local bannerTitle = text(banner, { Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 32), Text = "BRAINVILLE", TextColor3 = Color3.fromRGB(255, 205, 50) })
outlined(bannerTitle, 2.5)
local bannerSub = text(banner, { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 16), Text = "PICK • A • PATH" })
outlined(bannerSub, 1.5)
themedPart(function(T)
	banner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	banner.BackgroundTransparency = 0.35
	UI.corner(banner, 16)
	bannerTitle.Font = T.title
	bannerSub.Font = T.font
end)

local tutorial = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(330, 82), Visible = false, Parent = UI.gui })
UI.corner(tutorial, 14)
UI.stroke(tutorial, Color3.fromRGB(10, 40, 120), 3, 0)
UI.gradient(tutorial, Color3.fromRGB(70, 140, 255), Color3.fromRGB(30, 80, 200), 90)
tutorial.BackgroundColor3 = Color3.new(1, 1, 1)
local tutStep = text(tutorial, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -40, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 220, 60), Text = "STEP 1 OF 5" })
outlined(tutStep, 1.5)
local tutTitle = text(tutorial, { Position = UDim2.fromOffset(12, 22), Size = UDim2.new(1, -24, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Text = "" })
outlined(tutTitle, 2.5)
local tutDesc = text(tutorial, { Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Font = Enum.Font.GothamBold, Text = "" })
local tutClose = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromOffset(36, 36), Text = "X", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Parent = tutorial })

local TUTORIAL = {
	Lose = {
		{ event = "reading", title = "SKIP A TEXT BOX!", desc = "When a text pops up, smash SKIP fast. Reading = smarter (bad)." },
		{ event = "clickbait", title = "CLICK THE CLICKBAIT!", desc = "Open 📱 Phone → ClickNews and fall for the dumbest headline." },
		{ event = "steal", title = "PLAY A COPYCAT GAME!", desc = "Open 📱 Phone → Steal A and pick the dumbest game." },
		{ event = "comments", title = "POST A DUMB COMMENT!", desc = "Open 📱 Phone → Comments. Dumber = more cells lost." },
		{ event = "scroller", title = "DOOMSCROLL!", desc = "Open 📱 Phone → BrainTok and swipe through videos." },
	},
	Gain = {
		{ event = "library", title = "READ A BOOK!", desc = "Tap 📚 Library, read for 10 seconds, then answer." },
		{ event = "theater", title = "WATCH JACK B!", desc = "Open 📱 Phone → Jack B and learn a fun fact." },
		{ event = "job", title = "GET A JOB!", desc = "Open 📱 Phone → Jobs and pick one your IQ allows." },
		{ event = "work", title = "GO TO WORK!", desc = "Tap 🛠 Work (take the 🚌 bus or Hoppr) and finish a task." },
		{ event = "gate", title = "FACE THE SKILL GATE!", desc = "Reach the gate's IQ, then tap 🚧 Gate. YOU must be smart." },
	},
}
-- (1.4) The old small card is retired: the cinematic Tutorial module replaces it.
local tutState = { path = nil, step = 1, hidden = true }

local function showTutorial()
	local list = tutState.path and TUTORIAL[tutState.path]
	if not list or tutState.hidden or tutState.step > #list then
		tutorial.Visible = false
		return
	end
	local s = list[tutState.step]
	tutorial.Visible = true
	tutStep.Text = "STEP " .. tutState.step .. " OF " .. #list
	tutTitle.Text = s.title
	tutDesc.Text = s.desc
end
tutClose.Activated:Connect(function()
	tutState.hidden = true
	showTutorial()
end)

Hud.targets = {}
-- Where the tutorial arrow should point
function Hud.target(key: string)
	-- 1.9: everything but Quick Play lives in the phone, so the tutorial arrow points at the Phone button
	return Hud.targets[key] or Hud.targets.phone
end

function Hud.tutorialEvent(event: string)
	if Hud.onTutorialEvent then
		Hud.onTutorialEvent(event)
		return
	end
	local list = tutState.path and TUTORIAL[tutState.path]
	if not list or tutState.step > #list then
		return
	end
	if list[tutState.step].event == event then
		tutState.step += 1
		UI.sound("LevelUp", 0.6)
		if tutState.step > #list then
			UI.toast("🎉 Tutorial complete! You're on your own now.", UI.Colors.good)
		end
		if Hud.onSaveSettings then
			Hud.onSaveSettings({ ["tut" .. tutState.path] = tutState.step })
		end
		showTutorial()
	end
end

---------------------------------------------------------------------
-- TOP-RIGHT: settings / staff; RIGHT: big SHOP and MAP buttons
---------------------------------------------------------------------
local corner = UI.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), Size = UDim2.fromOffset(3 * MT + 16, MT + 2), BackgroundTransparency = 1, Parent = UI.gui }, {
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8) }),
})
local function roundButton(parent, icon: string, color: Color3, order: number, onClick)
	local b = UI.new("TextButton", { Text = icon, TextScaled = true, BackgroundColor3 = color, Size = UDim2.fromOffset(MT, MT), LayoutOrder = order, AutoButtonColor = true, Parent = parent }, {
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
	UI.corner(b, MT / 2)
	UI.stroke(b, Color3.new(0, 0, 0), 2, 0.3)
	b.Activated:Connect(onClick)
	return b
end
local settingsBtn = roundButton(corner, "⚙️", Color3.fromRGB(30, 30, 40), 2, function()
	if Hud.onMenu then
		Hud.onMenu()
	end
end)
local adminBtn = roundButton(corner, "🛠", Color3.fromRGB(170, 50, 90), 1, function()
	if Hud.onAdmin then
		Hud.onAdmin()
	end
end)
adminBtn.Visible = false
-- 1.5: a way out if you get stuck (furniture, odd corners, falling behind things)
local unstuckBtn = roundButton(corner, Content.Unstuck.Button, Color3.fromRGB(200, 120, 30), 0, function()
	if Hud.onUnstuck then
		Hud.onUnstuck()
	end
end)
unstuckBtn.Name = "Unstuck"

-- 1.8.5 (user: "SHOP and MAP are huge"): they are small round icons in the same top-right row now
corner.Size = UDim2.fromOffset(5 * MT + 40, MT + 2)
local function bigButton(label: string, _sub: string, c1: Color3, c2: Color3, order: number, onClick)
	local icon = string.match(label, "^(%S+)") or label
	local b = roundButton(corner, icon, Color3.new(1, 1, 1), -10 + order, onClick)
	local g = UI.gradient(b, c1, c2, 0)
	return b, g
end
local shopBtn, shopGrad = bigButton("🛒 SHOP", "", Color3.fromRGB(255, 80, 200), Color3.fromRGB(255, 200, 40), 1, function()
	if Hud.onStation then
		Hud.onStation("shop")
	end
end)
Hud.shopButton = shopBtn
local mapBtn = bigButton("🗺 MAP", Content.Bus.MapButtonSub, Color3.fromRGB(40, 200, 120), Color3.fromRGB(40, 140, 240), 2, function()
	if Hud.onStation then
		Hud.onStation("map")
	end
end)
Hud.mapButton = mapBtn
-- rainbow shimmer on the shop button (cash-grab energy)
task.spawn(function()
	local h = 0
	while true do
		task.wait(0.05)
		if shopBtn.Visible and not UI.settings.reduceFlashing and UI.tier == "cashgrab" and UI.effects() > 0 then
			h = (h + 0.01) % 1
			shopGrad.Color = ColorSequence.new(Color3.fromHSV(h, 0.8, 1), Color3.fromHSV((h + 0.25) % 1, 0.8, 1))
		else
			task.wait(1) -- idle: check rarely instead of 20 times a second
		end
	end
end)

---------------------------------------------------------------------
-- BOTTOM-CENTER: brain bar, meter and pass buttons
---------------------------------------------------------------------
local bottom = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.fromOffset(400, 72 + math.max(40, MT)), BackgroundTransparency = 1, Parent = UI.gui })
local meterLabel = text(bottom, { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 16), Text = "", Font = Enum.Font.GothamBold })
outlined(meterLabel, 1.5)
local meterBack = UI.new("Frame", { Position = UDim2.fromOffset(60, 18), Size = UDim2.new(1, -120, 0, 8), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Parent = bottom })
UI.corner(meterBack, 4)
local meterFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = meterBack })
UI.corner(meterFill, 4)
local meterGrad = UI.gradient(meterFill, Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 60, 90), 0)
local halfLine = UI.new("Frame", { Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = meterBack })

local bar = UI.new("Frame", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(20, 20, 30), BackgroundTransparency = 0.15, Parent = bottom })
bar.Visible = false -- 1.9 (UI judge): IQ already shows on the counter card; this bar duplicated it
UI.corner(bar, 10)
UI.stroke(bar, Color3.new(0, 0, 0), 2.5, 0)
local barFill = UI.new("Frame", { Position = UDim2.fromOffset(3, 3), Size = UDim2.new(0.5, -6, 1, -6), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar })
UI.corner(barFill, 8)
local barGrad = UI.gradient(barFill, Color3.fromRGB(80, 150, 255), Color3.fromRGB(40, 90, 230), 90)
local barLeft = text(bar, { Position = UDim2.fromOffset(12, 3), Size = UDim2.new(0.6, 0, 1, -6), TextXAlignment = Enum.TextXAlignment.Left, Text = "Human" })
outlined(barLeft, 2)
local barRight = text(bar, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 3), Size = UDim2.new(0.4, 0, 1, -6), TextXAlignment = Enum.TextXAlignment.Right, Text = "" })
outlined(barRight, 2)

local PH = math.max(40, MT) -- pass button height
local passRow = UI.new("Frame", { Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, PH), BackgroundTransparency = 1, Parent = bottom }, {
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }),
})
local PASS_BUTTONS = {
	Lose = {
		{ key = "BuyBrain", label = "🧠 BUY BRAIN", c1 = Color3.fromRGB(255, 150, 40), c2 = Color3.fromRGB(240, 90, 20) },
		{ key = "GoldenSkip", label = "⏭ GOLD SKIP", c1 = Color3.fromRGB(90, 140, 255), c2 = Color3.fromRGB(40, 80, 220) },
		{ key = "ExtraLoudDeath", label = "📢 LOUD DEATH", c1 = Color3.fromRGB(255, 70, 90), c2 = Color3.fromRGB(200, 30, 60) },
	},
	Gain = {
		{ key = "ExtraHints", label = "💡 HINTS", c1 = Color3.fromRGB(90, 140, 255), c2 = Color3.fromRGB(40, 80, 220) },
		{ key = "VIPLibrary", label = "📚 VIP", c1 = Color3.fromRGB(255, 150, 40), c2 = Color3.fromRGB(240, 90, 20) },
	},
}
local passPath = "?"
local function buildPasses(path: string?)
	local key = path or "none"
	if key == passPath then
		return
	end
	passPath = key
	for _, c in ipairs(passRow:GetChildren()) do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	-- selene: allow(shadowing)
	local PH = math.max(40, UI.minTouch()) -- 1.8: measured now, not when the HUD was first built
	for i, p in ipairs(PASS_BUTTONS[key] or {}) do
		local pass = Config.GamePasses[p.key]
		local b = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(122, PH), LayoutOrder = i, Parent = passRow })
		UI.corner(b, 10)
		UI.stroke(b, Color3.new(0, 0, 0), 2.5, 0)
		UI.gradient(b, p.c1, p.c2, 90)
		local t = text(b, { Position = UDim2.fromOffset(6, PH / 2 - 18), Size = UDim2.new(1, -12, 0, 22), Text = p.label })
		outlined(t, 2)
		local price = text(b, { Position = UDim2.fromOffset(6, PH / 2 + 3), Size = UDim2.new(1, -12, 0, 14), Text = "R$ " .. tostring(pass and pass.price or "?"), TextColor3 = Color3.fromRGB(150, 255, 150) })
		outlined(price, 1.5)
		b.Activated:Connect(function()
			if Hud.onBuyPass then
				Hud.onBuyPass(p.key)
			end
		end)
	end
end

-- Lobby: two DOORS on the screen (no physical doors in the world)
local doorDim = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 6, 25), BackgroundTransparency = 0.35, Visible = false, ZIndex = 15, Parent = UI.gui })
local pickRow = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(560, 340), BackgroundTransparency = 1, ZIndex = 16, Parent = UI.gui })
local doorsTitle = text(pickRow, { Position = UDim2.fromOffset(0, -6), Size = UDim2.new(1, 0, 0, 40), Text = "🚪 PICK A DOOR 🚪", TextColor3 = Color3.fromRGB(255, 215, 60), ZIndex = 17 })
outlined(doorsTitle, 3)
local doorsSub = text(pickRow, { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 20), Text = "Are you smart enough to get smarter, or dumb enough to get dumber?", Font = Enum.Font.GothamBold, ZIndex = 17 })
outlined(doorsSub, 1.5)
local doorsForced = false
local doorLabels = {}

local DOORS = {
	{ path = "Lose", title = "LOSE A BRAIN CELL", sub = "≈2 hour chaos run", face = "🤪", c1 = Color3.fromRGB(255, 80, 200), c2 = Color3.fromRGB(170, 20, 120), frame = Color3.fromRGB(255, 220, 60) },
	{ path = "Gain", title = "GAIN A BRAIN CELL", sub = "the long road to genius", face = "🤓", c1 = Color3.fromRGB(90, 160, 255), c2 = Color3.fromRGB(30, 70, 200), frame = Color3.fromRGB(230, 230, 240) },
}
for i, info in ipairs(DOORS) do
	local slot = UI.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(i == 1 and 0.27 or 0.73, 0, 0, 62), Size = UDim2.fromOffset(220, 276), Selectable = true, ZIndex = 17, Parent = pickRow })
	-- sign above the door
	local plaque = text(slot, { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 30), Text = info.title, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(30, 25, 45), ZIndex = 18 })
	UI.corner(plaque, 10)
	outlined(plaque, 2)
	doorLabels[i] = plaque
	-- the frame + light behind the door
	local frameP = UI.new("Frame", { Position = UDim2.fromOffset(20, 36), Size = UDim2.fromOffset(180, 214), BackgroundColor3 = info.frame, ZIndex = 18, Parent = slot })
	UI.corner(frameP, 90)
	UI.stroke(frameP, Color3.new(0, 0, 0), 3, 0)
	local light = UI.new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(160, 204), BackgroundColor3 = Color3.fromRGB(255, 250, 220), ZIndex = 19, Parent = frameP })
	UI.corner(light, 80)
	-- the door itself (swings open when you pick it)
	local door = UI.new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(160, 204), BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true, ZIndex = 20, Parent = frameP })
	UI.corner(door, 80)
	UI.gradient(door, info.c1, info.c2, 90)
	for _, pnl in ipairs({ { 22, 70 }, { 22, 132 } }) do
		local panel = UI.new("Frame", { Position = UDim2.fromOffset(pnl[1], pnl[2]), Size = UDim2.fromOffset(116, 50), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.8, ZIndex = 21, Parent = door })
		UI.corner(panel, 10)
	end
	local window = text(door, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(52, 52), Text = info.face, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 22 })
	UI.corner(window, 26)
	local knob = UI.new("Frame", { Position = UDim2.fromOffset(132, 110), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(255, 210, 60), ZIndex = 22, Parent = door })
	UI.corner(knob, 8)
	UI.stroke(knob, Color3.new(0, 0, 0), 1.5, 0)
	local sub = text(slot, { Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 20), Text = info.sub, TextColor3 = Color3.fromRGB(255, 250, 200), ZIndex = 18 })
	outlined(sub, 1.5)
	local glow = frameP:FindFirstChildOfClass("UIStroke")
	local scale = UI.new("UIScale", { Parent = slot })
	local function hover(on)
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = on and 1.06 or 1 }):Play()
		glow.Color = on and Color3.fromRGB(255, 255, 255) or Color3.new(0, 0, 0)
		glow.Thickness = on and 5 or 3
	end
	slot.MouseEnter:Connect(function()
		hover(true)
	end)
	slot.MouseLeave:Connect(function()
		hover(false)
	end)
	slot.SelectionGained:Connect(function()
		hover(true)
	end)
	slot.SelectionLost:Connect(function()
		hover(false)
	end)
	local busy = false
	slot.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		UI.sound("CartoonBoing")
		-- the door swings open into the light
		TweenService:Create(door, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(14, 204) }):Play()
		task.wait(0.55)
		doorsForced = false
		pickRow.Visible = false
		doorDim.Visible = false
		door.Size = UDim2.fromOffset(160, 204)
		busy = false
		local p = DOORS[i].path
		-- April-Fools-style swapped signs: the sign decides, not the door
		if doorLabels[i]:GetAttribute("Swapped") then
			p = (p == "Lose") and "Gain" or "Lose"
		end
		if Hud.onChoosePath then
			Hud.onChoosePath(p)
		end
	end)
end

-- Open the door screen again (e.g. to switch paths from Settings)
function Hud.openDoors()
	doorsForced = true
	pickRow.Visible = true
	doorDim.Visible = true
end

-- Admin fun: swap the door signs
function Hud.swapDoorSigns()
	local a, b = doorLabels[1], doorLabels[2]
	a.Text, b.Text = b.Text, a.Text
	a:SetAttribute("Swapped", not a:GetAttribute("Swapped"))
	b:SetAttribute("Swapped", not b:GetAttribute("Swapped"))
end

---------------------------------------------------------------------
-- Dr. Wrinkles (right side, above the jump button)
---------------------------------------------------------------------
local bubble = UI.new("Frame", { Name = "DrWrinkles", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -150), Size = UDim2.fromOffset(300, 74), Parent = UI.gui })
local bubbleScale = UI.new("UIScale", { Scale = 0, Parent = bubble })
local face = text(bubble, { Position = UDim2.fromOffset(-14, 6), Size = UDim2.fromOffset(62, 62), Text = "🧠", BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(255, 160, 200) })
UI.corner(face, 31)
UI.stroke(face, Color3.new(1, 1, 1), 3, 0)
local moodBadge = text(face, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 6, 1, 6), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Text = "🎤" })
UI.corner(moodBadge, 12)
local nameLabel = text(bubble, { Position = UDim2.fromOffset(54, 4), Size = UDim2.new(1, -62, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, Text = Narration.Name })
nameLabel.TextStrokeTransparency = 0.35 -- 1.8.5: the speaker name was faint on light cards
nameLabel.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
local speech = text(bubble, { Position = UDim2.fromOffset(54, 24), Size = UDim2.new(1, -62, 1, -28), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Font = Enum.Font.GothamMedium, Text = "" })
UI.new("UITextSizeConstraint", { MaxTextSize = 16, Parent = speech })
themedPart(function(T)
	bubble.BackgroundColor3 = T.bg
	bubble.BackgroundTransparency = math.min(0.2, T.bgT + 0.05)
	UI.corner(bubble, 16)
	UI.stroke(bubble, Color3.new(1, 1, 1), 2, 0.88) -- 1.9 kit: calm panel, thin light border
	speech.TextColor3 = T.text
end)

local MOOD = {
	host = { emoji = "🎤", font = Enum.Font.FredokaOne, color = Color3.fromRGB(255, 205, 60), title = "Dr. Wrinkles • Game Show Host" },
	librarian = { emoji = "📚", font = Enum.Font.GothamMedium, color = Color3.fromRGB(190, 210, 255), title = "Dr. Wrinkles • Librarian" },
	brainrot = { emoji = "📱", font = Enum.Font.Cartoon, color = Color3.fromRGB(255, 90, 200), title = "dr wrinkles 💀" },
	caveman = { emoji = "🦴", font = Enum.Font.Fantasy, color = Color3.fromRGB(200, 150, 100), title = "WRINKL" },
}
local sayToken = 0
---------------------------------------------------------------------
-- 1.6: current objective (a small banner under the title, e.g. "🏫 Go to school!")
---------------------------------------------------------------------
local objectiveLabel = UI.new("TextLabel", {
	Name = "Objective",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10), -- 1.8.3: a slim line at the very top, not a banner in the middle
	Size = UDim2.fromOffset(300, 22),
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0.5,
	TextColor3 = Color3.fromRGB(255, 225, 120),
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	Text = "",
	Visible = false,
	Parent = UI.gui,
}, {
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }),
})
UI.corner(objectiveLabel, 10)
UI.autoScale(objectiveLabel)
function Hud.objective(msg: string?)
	objectiveLabel.Text = msg or ""
	objectiveLabel.Visible = msg ~= nil and msg ~= ""
end

function Hud.say(msg: string, mood: string?)
	local look = MOOD[mood or "host"] or MOOD.host
	nameLabel.Text = look.title
	nameLabel.TextColor3 = UI.T.accent -- 1.9 kit: the name in the accent colour
	nameLabel.Font = UI.T.font
	moodBadge.Text = look.emoji
	speech.Font = UI.T.body -- 1.9 kit: one font (moods only change the badge and title)
	sayToken += 1
	local my = sayToken
	speech.Text = ""
	TweenService:Create(bubbleScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = UI.D }):Play()
	task.spawn(function()
		for i = 1, #msg do
			if my ~= sayToken then
				return
			end
			speech.Text = string.sub(msg, 1, i)
			if i % 2 == 0 then
				task.wait(0.012)
			end
		end
		speech.Text = msg
		task.wait(Config.UI.BubbleSeconds) -- 1.9: auto-hides
		if my == sayToken then
			TweenService:Create(bubbleScale, TweenInfo.new(0.2), { Scale = 0 }):Play()
		end
	end)
end

---------------------------------------------------------------------
-- Small status line + debug overlay
---------------------------------------------------------------------
local status = text(UI.gui, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 200), Size = UDim2.fromOffset(240, 14), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 220, 120), Text = "" })
outlined(status, 1)

local debugLabel = UI.new("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 220),
	Size = UDim2.fromOffset(250, 92),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.35,
	Font = Enum.Font.Code,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.fromRGB(120, 255, 120),
	Visible = false,
	Parent = UI.gui,
})
UI.corner(debugLabel, 8)
function Hud.toggleDebug()
	debugLabel.Visible = not debugLabel.Visible
end
task.spawn(function()
	local frames, last = 0, os.clock()
	RunService.RenderStepped:Connect(function()
		frames += 1
	end)
	while true do
		task.wait(1)
		if debugLabel.Visible then
			local st = UI.state
			local ping = 0
			pcall(function()
				ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			debugLabel.Text = string.format(
				" FPS: %d\n Ping: %d ms\n Tier: %s  Stage: %s\n Path: %s  Rank: %s\n Saving: %s",
				frames / (os.clock() - last),
				math.floor(ping),
				st and st.tier or "?",
				st and st.stage or "?",
				st and tostring(st.path) or "?",
				st and Config.RankNames[st.rank or 0] or "?",
				st and (st.canSave and "on" or "OFF") or "?"
			)
		end
		frames, last = 0, os.clock()
	end
end)

---------------------------------------------------------------------
-- Counter position (Settings) and drag
---------------------------------------------------------------------
local dragging = false
local counterTopLeft = true
function Hud.layoutCounter(s)
	if dragging then
		return
	end
	local where = s.counterPos or "topleft"
	topScale.Scale = (s.counterBig and 1.3 or 1) * UI.D
	if where == "topcenter" then
		top.AnchorPoint = Vector2.new(0.5, 0)
		top.Position = UDim2.new(0.5, 0, 0, 150)
	elseif where == "topright" then
		top.AnchorPoint = Vector2.new(1, 0)
		top.Position = UDim2.new(1, -190, 0, 64)
	elseif where == "bottomright" then
		top.AnchorPoint = Vector2.new(1, 1)
		top.Position = UDim2.new(1, -10, 1, -240)
	elseif where == "custom" and s.counterX and s.counterY then
		top.AnchorPoint = Vector2.new(0, 0)
		top.Position = UDim2.fromScale(s.counterX, s.counterY)
	else
		top.AnchorPoint = Vector2.new(0, 0)
		top.Position = UDim2.new(0, 10, 0, 6)
	end
	counterTopLeft = (where == "topleft" or where == nil)
	grid.Position = UDim2.new(0, 8, 0, counterTopLeft and (6 + stackH * UI.D) or 8) -- 1.9: room for the chip row
end

function Hud.dragCounter(onDone)
	if dragging then
		return
	end
	dragging = true
	UI.toast("✋ Drag the brain counter where you want it, then let go.")
	local conns = {}
	local startPos, startInput = nil, nil
	table.insert(conns, top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startPos = top.AbsolutePosition
			startInput = input.Position
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if startInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput
			top.AnchorPoint = Vector2.new(0, 0)
			top.Position = UDim2.fromOffset(startPos.X + delta.X, startPos.Y + delta.Y)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if startInput and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			startInput = nil
			for _, c in ipairs(conns) do
				c:Disconnect()
			end
			dragging = false
			local screen = UI.gui.AbsoluteSize
			local x = math.clamp(top.AbsolutePosition.X / math.max(1, screen.X), 0, 0.95)
			local y = math.clamp(top.AbsolutePosition.Y / math.max(1, screen.Y), 0, 0.95)
			top.Position = UDim2.fromScale(x, y)
			if onDone then
				onDone(x, y)
			end
		end
	end))
end

---------------------------------------------------------------------
-- Device scaling: every block follows the screen size
---------------------------------------------------------------------
for _, inst in ipairs({ grid, banner, tutorial, corner, bottom, pickRow, status }) do
	UI.autoScale(inst)
end
-- 1.8 (screenshot check): the thumb-size minimum depends on the real screen size, which isn't known
-- when the HUD is first built, so re-size the touch targets whenever the scale changes...
UI.onScale(function()
	local mt = UI.minTouch()
	corner.Size = UDim2.fromOffset(5 * mt + 40, mt + 2)
	for _, b in ipairs(corner:GetChildren()) do
		if b:IsA("TextButton") then
			b.Size = UDim2.fromOffset(mt, mt)
		end
	end
	local cell = math.max(60, mt)
	local gl = grid:FindFirstChildOfClass("UIGridLayout")
	if gl then
		gl.CellSize = UDim2.fromOffset(cell, cell)
	end
	grid.Size = UDim2.new(0, cell + 10, 1, -250) -- 1.8.1 UI review: ONE tidy column
	local ph = math.max(40, mt)
	bottom.Size = UDim2.fromOffset(400, passRow.Visible and (72 + ph) or 68)
	passRow.Size = UDim2.new(1, 0, 0, ph)
	for _, b in ipairs(passRow:GetChildren()) do
		if b:IsA("TextButton") then
			b.Size = UDim2.fromOffset(122, ph)
		end
	end
end)
-- ...and keep the bottom bar fully on screen (a UIScale grows it past the bottom edge on big screens)
local function fitBottom()
	bottom.Position = UDim2.new(0.5, 0, 1, -6)
	task.defer(function()
		local limit = UI.gui.AbsoluteSize.Y - 6
		local lowest = bottom.AbsolutePosition.Y + bottom.AbsoluteSize.Y
		for _, d in ipairs(bottom:GetDescendants()) do
			if d:IsA("GuiObject") and d.Visible then
				lowest = math.max(lowest, d.AbsolutePosition.Y + d.AbsoluteSize.Y)
			end
		end
		if lowest > limit then
			bottom.Position = UDim2.new(0.5, 0, 1, -6 - (lowest - limit))
		end
	end)
end
UI.onScale(fitBottom)
UI.gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitBottom)
UI.onScale(function(d)
	topScale.Scale = ((UI.settings and UI.settings.counterBig) and 1.3 or 1) * d
	grid.Position = UDim2.new(0, 8, 0, counterTopLeft and (6 + stackH * d) or 8)
	tutorial.Position = UDim2.new(0.5, 0, 0, 2 + 60 * d)
	bubble.Position = UDim2.new(1, -10, 1, -(150 * d))
	status.Position = UDim2.new(1, -10, 0, 6 + 200 * d)
	if bubbleScale.Scale > 0 then
		bubbleScale.Scale = d
	end
end)

---------------------------------------------------------------------
-- Update from server state
---------------------------------------------------------------------
local BANNERS = {
	none = { "BRAINVILLE", "PICK • YOUR • PATH" },
	Lose = { "LOSE A BRAIN CELL", "SKIP • CLICK • SCROLL" },
	Gain = { "GAIN A BRAIN CELL", "READ • LEARN • THINK" },
}

local function progress(st): (number, string)
	if st.path == "Gain" then
		local nextIq
		for _, g in ipairs(Config.Gates) do
			if g.name == st.gate then
				nextIq = g.iq
			end
		end
		if nextIq then
			local target = Brain.cellsForIQ(nextIq)
			local from = st.comeback and 1 or Config.GainStartCells
			local p = math.clamp((st.cells - from) / math.max(1, target - from), 0, 1)
			return p, st.atGate and "🚧 GATE!" or ("IQ " .. nextIq .. " gate")
		end
		return 1, "All gates passed"
	elseif st.path == "Lose" then
		local p = 1 - math.clamp(math.log10(math.max(1, st.cells)) / math.log10(Config.LoseStartCells), 0, 1)
		return p, math.floor(p * 100) .. "% gone"
	end
	return 0, ""
end

---------------------------------------------------------------------
-- 1.6: animal power button (bottom right, above the jump button)
---------------------------------------------------------------------
local currentPower = nil
local powerBtn = UI.new("TextButton", {
	Name = "AnimalPower",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -125, 1, -22), -- left of the phone jump button, under the narrator
	Size = UDim2.fromOffset(120, 52),
	BackgroundColor3 = Color3.fromRGB(255, 170, 40),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	Text = "",
	Visible = false,
	Parent = UI.gui,
}, {
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
})
UI.corner(powerBtn, 16)
UI.stroke(powerBtn, Color3.new(0, 0, 0), 2, 0.3)
UI.autoScale(powerBtn)
powerBtn.Activated:Connect(function()
	if Hud.onPower then
		Hud.onPower()
	end
end)
function Hud.hasPower(): boolean
	return currentPower ~= nil
end
local function updatePower(st)
	local power = st and not st.dead and Config.Animals.Powers[st.stage] or nil
	currentPower = power
	powerBtn.Visible = power ~= nil
	if power then
		powerBtn.Text = Content.Animals.Powers[power] or power
	end
end

function Hud.update(st)
	updatePower(st)
	UI.setTier(st.tier)
	if st.settings then
		Hud.layoutCounter(st.settings)
		if tutState.path ~= st.path then
			tutState.path = st.path
			tutState.step = st.path and (st.settings["tut" .. st.path] or 1) or 1
			showTutorial()
		end
	end
	local path = (not st.dead) and st.path or nil
	buildGrid(path)
	buildPasses(st.tier == "cashgrab" and path or nil)
	-- 1.8.1 UI review: passes live in the 🛒 Shop only (Config.UI.HudPassButtons), not on the HUD
	passRow.Visible = Config.UI.HudPassButtons == true and st.tier == "cashgrab" and path ~= nil
	bottom.Size = UDim2.fromOffset(400, passRow.Visible and 112 or 68)

	cellsLabel.Text = st.cellsText
	iqChip.Text = st.iqText
	coinChip.Visible = st.path == "Gain"
	coinChip.Text = "💰 " .. tostring(math.floor(st.coins or 0))
	local b = BANNERS[path or "none"]
	bannerTitle.Text = b[1]
	bannerSub.Text = b[2]
	banner.Visible = path == nil -- 1.8.1 UI review: the big title only in the lobby ("pick a path")

	-- brain bar
	local p, right = progress(st)
	TweenService:Create(barFill, TweenInfo.new(0.4), { Size = UDim2.new(math.max(0.03, p), -6, 1, -6) }):Play()
	barLeft.Text = (st.stage ~= "human" and (st.stageEmoji .. " " .. st.stageName .. "  •  ") or "") .. st.iqText
	barRight.Text = right
	barGrad.Color = st.path == "Lose" and ColorSequence.new(Color3.fromRGB(255, 90, 180), Color3.fromRGB(200, 40, 140)) or ColorSequence.new(Color3.fromRGB(80, 150, 255), Color3.fromRGB(40, 90, 230))
	bar.Visible = false -- 1.9: hidden for good (IQ is on the counter card)

	-- meter
	if st.path == "Lose" and not st.dead then
		meterBack.Visible = not st.meterBroken
		halfLine.Visible = true
		meterGrad.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 60, 90))
		meterLabel.Text = st.meterBroken and "🗿 too dumb to be embarrassed" or (st.hiding and "🌳 HIDING BEHIND A BUSH" or "😳 embarrassment (stay under ½)")
		meterFill.Size = UDim2.fromScale(math.clamp(st.embarrass / 100, 0, 1), 1)
	elseif st.path == "Gain" then
		meterBack.Visible = true
		halfLine.Visible = false
		meterGrad.Color = ColorSequence.new(Color3.fromRGB(120, 220, 140), Color3.fromRGB(255, 140, 40))
		-- 1.9 (UI judge): no more "Overflow ×999 (…)" joke text here, just the stress bar
		meterLabel.Text = st.frozen and "😵 TOO STRESSED: take a break!" or "😰 stress"
		meterFill.Size = UDim2.fromScale(math.clamp(st.stress / 100, 0, 1), 1)
	else
		meterBack.Visible = false
		meterLabel.Text = ""
	end

	-- 1.9: status and career moved to the chip row under the counter (updateChips)
	status.Text = ""

	adminBtn.Visible = (st.rank or 0) >= 1
	pickRow.Visible = (path == nil and not st.dead) or doorsForced
	doorDim.Visible = pickRow.Visible
	grid.Visible = path ~= nil
	corner.Visible = not st.dead
	-- 1.9: Shop, Map and Settings are phone apps now; ⚙️ only stays in the lobby (no phone apps yet)
	shopBtn.Visible = false
	mapBtn.Visible = false
	settingsBtn.Visible = path == nil
	updateChips(st)
	updateStrip(st)
	grid.Position = UDim2.new(0, 8, 0, counterTopLeft and (6 + stackH * UI.D) or 8)
end

function Hud.delta(amount: number, up: boolean)
	local t = text(top, {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 64, 1, 28), -- 1.9: under the chip row
		Size = UDim2.fromOffset(200, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = up and UI.Colors.good or UI.Colors.bad,
		Text = (up and "+" or "−") .. Brain.formatNumber(amount),
	})
	outlined(t, 2)
	TweenService:Create(t, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { Position = t.Position + UDim2.fromOffset(0, 30), TextTransparency = 1 }):Play()
	task.delay(1.3, function()
		t:Destroy()
	end)
	if not UI.settings.reduceFlashing then
		local base = (UI.settings.counterBig and 1.3 or 1) * UI.D
		topScale.Scale = base * (up and 1.06 or 0.95)
		TweenService:Create(topScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = base }):Play()
	end
	local _ = brainIcon
	-- 1.7.3: big changes get a big animated number in the middle of the screen
	local cells = UI.state and UI.state.cells
	if cells and cells > 0 and amount / (cells + (up and 0 or amount)) >= Config.UI.BigDeltaShare then
		Hud.bigCounter(amount, up)
	end
end

function Hud.bigCounter(amount: number, up: boolean, title: string?)
	local big = text(UI.gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(520, 120),
		TextColor3 = up and UI.Colors.good or UI.Colors.bad,
		Text = (title and (title .. "\n") or "") .. (up and "+" or "−") .. Brain.formatNumber(amount) .. " 🧠",
		ZIndex = 40,
	})
	outlined(big, 4)
	local sc = UI.new("UIScale", { Scale = UI.reducedMotion() and UI.D or 0.3 * UI.D, Parent = big })
	if not UI.reducedMotion() then
		TweenService:Create(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = UI.D }):Play()
	end
	task.delay(1.6, function()
		TweenService:Create(big, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.7)
		big:Destroy()
	end)
end

return Hud

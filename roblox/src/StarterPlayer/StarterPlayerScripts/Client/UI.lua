-- UI: the look of every screen. The whole interface re-themes with your brain:
--   genius   = elegant ivory + navy, serif
--   smart    = clean navy + gold
--   average  = modern glassy purple
--   cashgrab = LOUD neon gradients, chunky outlines, shine
--   nonsense = grey crayon, wobbly, falling apart
-- Works with touch, mouse/keyboard and controller.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local UI = {}

UI.state = nil
UI.settings = { music = 0.5, sfx = 0.8, reduceFlashing = false, largeText = false, extraTime = false }

---------------------------------------------------------------------
-- Themes
---------------------------------------------------------------------
UI.Themes = {
	average = {
		bg = Color3.fromRGB(20, 18, 34),
		panel = Color3.fromRGB(38, 32, 66),
		panel2 = Color3.fromRGB(58, 48, 98),
		accent = Color3.fromRGB(150, 90, 255),
		accent2 = Color3.fromRGB(70, 160, 255),
		text = Color3.fromRGB(248, 245, 255),
		muted = Color3.fromRGB(180, 170, 210),
		stroke = Color3.fromRGB(190, 160, 255),
		strokeT = 0.55,
		font = Enum.Font.GothamBold,
		title = Enum.Font.FredokaOne,
		body = Enum.Font.GothamMedium,
		radius = 16,
		strokeW = 2,
		bgT = 0.08,
	},
	smart = {
		bg = Color3.fromRGB(14, 22, 40),
		panel = Color3.fromRGB(24, 38, 66),
		panel2 = Color3.fromRGB(36, 56, 94),
		accent = Color3.fromRGB(230, 180, 70),
		accent2 = Color3.fromRGB(80, 140, 220),
		text = Color3.fromRGB(240, 244, 252),
		muted = Color3.fromRGB(160, 175, 205),
		stroke = Color3.fromRGB(230, 190, 100),
		strokeT = 0.5,
		font = Enum.Font.GothamBold,
		title = Enum.Font.GothamBlack, -- 1.8.3: one font family (no serif fallback look)
		body = Enum.Font.Gotham,
		radius = 12,
		strokeW = 1.5,
		bgT = 0.06,
	},
	genius = {
		bg = Color3.fromRGB(246, 242, 232),
		panel = Color3.fromRGB(236, 230, 216),
		panel2 = Color3.fromRGB(222, 214, 196),
		accent = Color3.fromRGB(255, 200, 61), -- 1.9: gold (the old navy vanished on the dark kit panels)
		accent2 = Color3.fromRGB(120, 95, 50),
		text = Color3.fromRGB(28, 30, 38),
		muted = Color3.fromRGB(110, 105, 95),
		stroke = Color3.fromRGB(150, 130, 90),
		strokeT = 0.3,
		font = Enum.Font.GothamBold,
		title = Enum.Font.GothamBlack,
		body = Enum.Font.GothamMedium,
		radius = 6,
		strokeW = 1,
		bgT = 0.02,
	},
	cashgrab = {
		bg = Color3.fromRGB(255, 40, 160),
		panel = Color3.fromRGB(255, 205, 0),
		panel2 = Color3.fromRGB(0, 220, 120),
		accent = Color3.fromRGB(0, 200, 255),
		accent2 = Color3.fromRGB(255, 120, 0),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(255, 255, 200),
		stroke = Color3.fromRGB(0, 0, 0),
		strokeT = 0,
		font = Enum.Font.FredokaOne,
		title = Enum.Font.FredokaOne,
		body = Enum.Font.FredokaOne,
		radius = 22,
		strokeW = 4,
		bgT = 0,
		textStroke = true,
		shine = true,
	},
	cozy = {
		bg = Color3.fromRGB(255, 244, 250),
		panel = Color3.fromRGB(255, 226, 238),
		panel2 = Color3.fromRGB(255, 200, 225),
		accent = Color3.fromRGB(255, 110, 165),
		accent2 = Color3.fromRGB(110, 190, 255),
		text = Color3.fromRGB(70, 40, 80),
		muted = Color3.fromRGB(150, 110, 150),
		stroke = Color3.fromRGB(255, 150, 195),
		strokeT = 0,
		font = Enum.Font.FredokaOne,
		title = Enum.Font.FredokaOne,
		body = Enum.Font.GothamBold,
		radius = 18,
		strokeW = 2.5,
		bgT = 0.02,
	},
	nonsense = {
		bg = Color3.fromRGB(150, 150, 150),
		panel = Color3.fromRGB(175, 175, 175),
		panel2 = Color3.fromRGB(195, 195, 195),
		accent = Color3.fromRGB(120, 120, 120),
		accent2 = Color3.fromRGB(100, 100, 100),
		text = Color3.fromRGB(30, 30, 30),
		muted = Color3.fromRGB(70, 70, 70),
		stroke = Color3.fromRGB(40, 40, 40),
		strokeT = 0,
		font = Enum.Font.Cartoon,
		title = Enum.Font.Cartoon,
		body = Enum.Font.Cartoon,
		radius = 2,
		strokeW = 3,
		bgT = 0,
		wobble = true,
	},
}
-- 1.9 UI overhaul (a fresh "harsh judge" review: docs/UI judge review.md): the root cause of the
-- "UI feels bad" complaint was that every look had its own panels, corners, outlines, gradients and
-- fonts. Now every look shares ONE calm design kit; only the accent colour (and the world style)
-- still changes with your brain level.
local KIT = {
	bg = Color3.fromRGB(27, 32, 48), -- #1B2030 panels
	panel = Color3.fromRGB(34, 40, 58),
	panel2 = Color3.fromRGB(42, 49, 71), -- #2A3147 buttons
	text = Color3.fromRGB(245, 246, 250),
	muted = Color3.fromRGB(160, 168, 190),
	stroke = Color3.new(1, 1, 1),
	strokeT = 0.88, -- 2 px white at 12%
	strokeW = 2,
	radius = 12,
	bgT = 0.08,
	font = Enum.Font.GothamBold,
	title = Enum.Font.GothamBlack,
	body = Enum.Font.GothamMedium,
	textStroke = false,
	shine = false,
	wobble = false,
}
for _, theme in pairs(UI.Themes) do
	for k, v in pairs(KIT) do
		theme[k] = v
	end
	theme.accent2 = theme.accent2 or theme.accent
end
UI.tier = "average"
UI.T = UI.Themes.average

-- Kept for older code: semantic colors that don't change with the theme
UI.Colors = {
	good = Color3.fromRGB(70, 210, 120),
	bad = Color3.fromRGB(255, 80, 100),
	gold = Color3.fromRGB(255, 200, 60),
}
setmetatable(UI.Colors, {
	__index = function(_, k)
		return UI.T[k]
	end,
})

local themeListeners = {}
function UI.onTheme(fn)
	table.insert(themeListeners, fn)
end

function UI.setTier(tier: string)
	if not UI.Themes[tier] or tier == UI.tier then
		return
	end
	UI.tier = tier
	UI.T = UI.Themes[tier]
	for _, fn in ipairs(themeListeners) do
		task.spawn(fn, UI.T)
	end
end

---------------------------------------------------------------------
-- Building blocks
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Device scale: the whole interface shrinks on phones and grows a bit on big screens.
-- Designed for a 1000x462 screen (a phone held sideways).
---------------------------------------------------------------------
UI.D = 1
local scaleListeners = {}
function UI.onScale(fn)
	table.insert(scaleListeners, fn)
	fn(UI.D)
end
local function computeScale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1000, 462)
	local d = math.min(v.X / 1000, v.Y / 462)
	-- 1.7: never shrink below 0.7, so buttons stay thumb-sized on small phones
	d = math.clamp(d, Config.UI.MinDeviceScale, Config.UI.MaxDeviceScale or 1)
	if math.abs(d - UI.D) > 0.01 then
		UI.D = d
		for _, fn in ipairs(scaleListeners) do
			task.spawn(fn, d)
		end
	end
end
task.defer(function()
	computeScale()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(computeScale)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		computeScale()
		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(computeScale)
		end
	end)
end)
computeScale()

-- 1.7 fix: the 48 px touch minimum, measured AFTER the device scale shrinks the UI on phones
function UI.minTouch(): number
	return math.ceil(Config.UI.MinTouch / math.min(UI.D, 1))
end

-- Adds a UIScale that follows the device scale (times an optional extra factor)
function UI.autoScale(inst, extra: number?)
	local sc = inst:FindFirstChild("DeviceScale") or Instance.new("UIScale")
	sc.Name = "DeviceScale"
	sc.Parent = inst
	UI.onScale(function(d)
		sc.Scale = d * (extra or 1)
	end)
	return sc
end

UI.gui = Instance.new("ScreenGui")
UI.gui.Name = "BrainUI"
UI.gui.ResetOnSpawn = false
UI.gui.IgnoreGuiInset = false
-- 1.7: keep everything clear of the notch, the Dynamic Island and Roblox's top bar
pcall(function()
	UI.gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)
UI.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.gui.Parent = player:WaitForChild("PlayerGui")

function UI.new(className: string, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function UI.corner(inst, radius: number?)
	local c = inst:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or UI.T.radius)
	c.Parent = inst
	return inst
end

function UI.stroke(inst, color: Color3?, thickness: number?, transparency: number?)
	local s = inst:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.Color = color or UI.T.stroke
	s.Thickness = thickness or UI.T.strokeW
	s.Transparency = transparency or UI.T.strokeT
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return inst
end

-- top-to-bottom shine gradient
function UI.gradient(inst, c1: Color3, c2: Color3?, rotation: number?)
	local g = inst:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2 or c1)
	g.Rotation = rotation or 90
	g.Parent = inst
	return g
end

local function lighten(c: Color3, a: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), a)
end
local function darken(c: Color3, a: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), a)
end
UI.lighten = lighten
UI.darken = darken

-- 1.7: a phone = the short side of the screen is small (TouchEnabled is also true on touch PCs)
function UI.isPhone(): boolean
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1000, 462)
	return math.min(v.X, v.Y) < Config.UI.PhoneShortSide
end

-- 1.7: one switch for "calm motion": Roblox's Reduced Motion setting, or the Effects slider at 0
function UI.reducedMotion(): boolean
	local ok, on = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	if ok and on then
		return true
	end
	return UI.effects() <= 0
end

-- 1.7: Effects intensity (0..1) from Settings. Shake, glitch, scramble and ads scale with it.
function UI.effects(): number
	local v = UI.settings and UI.settings.fxIntensity
	if typeof(v) ~= "number" then
		return 1
	end
	return math.clamp(v, 0, 1)
end

function UI.textSize(base: number): number
	local size = UI.settings.largeText and math.floor(base * 1.25) or base
	-- 1.7: readable on phones (after the device scale shrinks it)
	if UI.isPhone() then
		size = math.max(size, math.ceil(Config.UI.MinPhoneText / math.min(UI.D, 1)))
	end
	return size
end

function UI.styleText(t)
	t.Font = t:GetAttribute("Title") and UI.T.title or (t:GetAttribute("Body") and UI.T.body or UI.T.font)
	if UI.T.textStroke then
		t.TextStrokeTransparency = 0
		t.TextStrokeColor3 = Color3.new(0, 0, 0)
	else
		t.TextStrokeTransparency = 1
	end
end

function UI.label(parent, text: string, props)
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = UI.T.text,
		Font = UI.T.body,
		TextSize = UI.textSize(16),
		TextWrapped = true,
		RichText = true,
		Size = UDim2.new(1, 0, 0, 22),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	l:SetAttribute("Body", true)
	UI.styleText(l)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

-- Buttons: gradient, outline, bounce on press/hover/controller-select.
function UI.button(parent, text: string, onClick, props)
	local T = UI.T
	local b = UI.new("TextButton", {
		Text = text,
		TextColor3 = T.text,
		TextSize = UI.textSize(16),
		TextWrapped = true,
		RichText = true,
		BackgroundColor3 = T.panel2,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 46),
		Selectable = true,
		Parent = parent,
	})
	UI.styleText(b)
	UI.corner(b)
	UI.stroke(b)
	local scale = UI.new("UIScale", { Parent = b })
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	-- 1.7: every tappable button is at least thumb-sized
	if b.Size.Y.Scale == 0 and b.Size.Y.Offset < UI.minTouch() then
		b.Size = UDim2.new(b.Size.X.Scale, math.max(b.Size.X.Offset, b.Size.X.Scale == 0 and UI.minTouch() or 0), 0, UI.minTouch())
	end
	local base = b.BackgroundColor3
	UI.gradient(b, Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 210), 90)
	if T.shine then
		UI.gradient(b, Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170), 90)
	end
	if T.wobble and UI.effects() > 0 and not UI.reducedMotion() then
		b.Rotation = math.random(-3, 3)
	end
	local function tweenScale(s: number)
		if UI.reducedMotion() then
			scale.Scale = 1
			return
		end
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = s }):Play()
	end
	b.MouseEnter:Connect(function()
		tweenScale(1.04)
		b.BackgroundColor3 = lighten(base, 0.12)
	end)
	b.MouseLeave:Connect(function()
		tweenScale(1)
		b.BackgroundColor3 = base
	end)
	b.SelectionGained:Connect(function()
		tweenScale(1.06)
		b.BackgroundColor3 = lighten(base, 0.15)
	end)
	b.SelectionLost:Connect(function()
		tweenScale(1)
		b.BackgroundColor3 = base
	end)
	b.MouseButton1Down:Connect(function()
		tweenScale(0.93)
	end)
	b.MouseButton1Up:Connect(function()
		tweenScale(1)
	end)
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		-- remember colors set by callers (selected answers etc.)
		local c = b.BackgroundColor3
		if c ~= lighten(base, 0.12) and c ~= lighten(base, 0.15) then
			base = c
		end
	end)
	if onClick then
		local busy = false
		b.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			UI.sound("Click", 0.35) -- 1.9.3: a soft click (every button used the cartoon boing)
			task.spawn(function()
				local ok, err = pcall(onClick, b)
				if not ok then
					warn(err)
				end
				busy = false
			end)
		end)
	end
	return b
end

-- Small rounded "chip" label
function UI.chip(parent, text: string, color: Color3?, props)
	local c = UI.new("TextLabel", {
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = UI.textSize(14),
		RichText = true,
		BackgroundColor3 = color or UI.T.accent,
		Size = UDim2.fromOffset(10, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = parent,
	}, {
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
	})
	UI.styleText(c)
	UI.corner(c, 12)
	for k, v in pairs(props or {}) do
		c[k] = v
	end
	return c
end

-- Soft drop shadow behind a frame
function UI.shadow(frame)
	local s = UI.new("Frame", {
		Name = "Shadow",
		AnchorPoint = frame.AnchorPoint,
		Position = frame.Position + UDim2.fromOffset(0, 6),
		Size = frame.Size,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		ZIndex = math.max(0, frame.ZIndex - 1),
		Parent = frame.Parent,
	})
	UI.corner(s, UI.T.radius + 2)
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("UISizeConstraint") then
			c:Clone().Parent = s
		end
	end
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		s.Visible = frame.Visible
	end)
	frame.Destroying:Connect(function()
		s:Destroy()
	end)
	return s
end

---------------------------------------------------------------------
-- Sounds
---------------------------------------------------------------------
local lastVariant = {}
function UI.sound(name: string?, volumeScale: number?)
	if not name then
		return
	end
	local id = Config.Sounds[name]
	-- 1.9.3: pick one of several versions (never the same one twice in a row) and vary the pitch a little
	local variants = Config.SoundVariants and Config.SoundVariants[name]
	if variants and #variants > 1 then
		local pick = variants[math.random(1, #variants)]
		if pick == lastVariant[name] then
			pick = variants[(table.find(variants, pick) % #variants) + 1]
		end
		lastVariant[name] = pick
		id = pick
	end
	if not id or id == 0 then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = (UI.settings.sfx or 0.8) * (volumeScale or 1)
	if name ~= "TypeTick" then
		local j = Config.SoundPitchJitter or 0
		s.PlaybackSpeed = 1 + (math.random() * 2 - 1) * j
	end
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
	task.delay(15, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

---------------------------------------------------------------------
-- Toasts: slide in from the right
---------------------------------------------------------------------
local toastHolder = UI.new("Frame", {
	Name = "Toasts",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0), -- 1.9.3 (user: notifications took way too much space): top-RIGHT, out of your view
	Position = UDim2.new(1, -12, 0, 120),
	Size = UDim2.new(0.3, 0, 0, 10),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 50,
	Parent = UI.gui,
}, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }),
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(240, 200), MinSize = Vector2.new(160, 0) }),
})
-- 1.8.1: toasts sit just under the goal line, whatever the screen size
local toastTop = UDim2.new(0.5, 0, 0, 74)
UI.onScale(function(d)
	toastTop = UDim2.new(1, -12, 0, 16 + 66 * d) -- 1.9.3: top-right, just under the round buttons
	toastHolder.Position = toastTop
end)
UI.autoScale(toastHolder)

local toastOrder = 0
-- 1.8.1 (user feedback "too many, too big, too long"): small top toasts, at most MaxToasts at once,
-- about 3 s each, repeats merged ("×4"), and Settings → "Fewer notifications" drops routine ones.
local liveToasts = {} -- { {text, holder, label, count, base, timer} }, oldest first
local function isLowValue(text: string): boolean
	for _, word in ipairs(Config.UI.ToastLowValue) do
		if string.find(string.lower(text), word, 1, true) then
			return true
		end
	end
	return false
end
function UI.toast(text: string, color: Color3?, seconds: number?)
	text = tostring(text or "")
	if text == "" then
		return
	end
	if (not UI.settings or UI.settings.fewerToasts ~= false) and isLowValue(text) then
		return -- routine news (interest, bills…): the phone shows it instead
	end
	local life = seconds and math.min(seconds, Config.UI.ToastSeconds + 1) or Config.UI.ToastSeconds
	-- the same message again: bump its counter instead of adding another card
	for _, t in ipairs(liveToasts) do
		if t.base == text and t.holder.Parent then
			t.count += 1
			t.label.Text = text .. "  ×" .. t.count
			t.until_ = os.clock() + life
			return
		end
	end
	-- 1.9.1 test fix: while a pop-up is open, toasts sit at the bottom so they never cover its title
	-- 1.9.3: always the same small corner (top-right), pop-up or not
	toastHolder.AnchorPoint = Vector2.new(1, 0)
	toastHolder.Position = toastTop
	while #liveToasts >= Config.UI.MaxToasts do
		local old = table.remove(liveToasts, 1)
		if old.holder.Parent then
			old.holder:Destroy()
		end
	end
	toastOrder += 1
	local T = UI.T
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = toastOrder, ZIndex = 50, Parent = toastHolder })
	local card = UI.new("Frame", {
		BackgroundColor3 = T.bg,
		BackgroundTransparency = math.max(T.bgT or 0, 0.15),
		Position = UDim2.fromScale(0, -0.3),
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 50,
		Parent = holder,
	}, {
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})
	UI.corner(card, 10)
	local bar = UI.new("Frame", { BackgroundColor3 = color or T.accent, Position = UDim2.new(0, -12, 0, -6), Size = UDim2.new(0, 4, 1, 12), ZIndex = 51, Parent = card })
	UI.corner(bar, 2)
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = T.text,
		TextSize = UI.textSize(13),
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 51,
		Parent = card,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(math.huge, UI.textSize(13) * 2 + 6), Parent = l }) -- 1.9.3: at most 2 lines
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l:SetAttribute("Body", true)
	UI.styleText(l)
	-- 1.9.1 toasts follow the pop-up style; smart players (glass / clean) get phone-notification cards
	pcall(function()
		local key = UI.popupStyle()
		local P = UI.PopStyles[key]
		if P then -- 1.9.3 Brain Kit: every toast is the same dark card with the tier's accent bar
			card.BackgroundColor3 = P.bg
			card.BackgroundTransparency = 0.05
			UI.corner(card, math.min(P.radius, 16))
			l.TextColor3 = P.text
			UI.stroke(card, P.stroke, math.min(P.strokeW, 3), P.strokeT)
			if P.font then
				l.Font = P.font
			elseif P.face then
				l.FontFace = Font.new(P.face)
			end
			bar.BackgroundColor3 = color or P.line
		end
	end)
	-- 1.9.1 quality of life: tap a toast to dismiss it
	local tapOff = UI.new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 53, Parent = card })
	tapOff.Activated:Connect(function()
		holder:Destroy()
	end)
	local entry = { base = text, holder = holder, label = l, count = 1, until_ = os.clock() + life }
	table.insert(liveToasts, entry)
	if not UI.reducedMotion() then
		TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0, 0) }):Play()
	else
		card.Position = UDim2.fromScale(0, 0)
	end
	task.spawn(function()
		while holder.Parent and os.clock() < entry.until_ do
			task.wait(0.25)
		end
		local i = table.find(liveToasts, entry)
		if i then
			table.remove(liveToasts, i)
		end
		if holder.Parent then
			holder:Destroy()
		end
	end)
end

---------------------------------------------------------------------
-- Modals (one at a time). Controller: B closes, first button selected.
---------------------------------------------------------------------
local current = nil

function UI.closeModal()
	if current then
		local c = current
		current = nil
		UI.popupOpen = false
		ContextActionService:UnbindAction("BrainCloseModal")
		GuiService.SelectedObject = nil
		if c.onClose then
			pcall(c.onClose)
		end
		local scale = c.frame:FindFirstChildOfClass("UIScale")
		if scale then
			TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 0.9 * UI.D }):Play()
		end
		task.delay(0.1, function()
			c.backdrop:Destroy()
		end)
	end
end

function UI.isModalOpen(): boolean
	return current ~= nil
end

---------------------------------------------------------------------
-- 1.9.1 pop-up styles by brain level (user picked from docs/screens/popup-styles/: "integrate all of
-- them according to how smart/dumb you are"). Low brain = loud and silly, high brain = calm and real:
--   neon (Lose, really dumb) · bubbly (Lose, and animals) · storybook (new / average, matches the start town)
--   glass (smart, IQ 100+) · clean dark card (really smart, IQ 135+)
-- Toasts use the same style, and smart players (IQ 100+) get phone-notification toasts.
-- Only ordinary pop-ups are skinned: the phone, minigames and other big screens keep their own look.
---------------------------------------------------------------------
-- 1.9.3 BRAIN KIT (docs/UI review.md): every pop-up shares ONE base: dark card, light text, the same
-- buttons and the same red close button. Brain level only changes the accent line, roundness, outline
-- and title font, never the colours of the body (the cream / yellow / white / neon skins made the game
-- look "all over the place").
local BASE = {
	bg = Color3.fromRGB(27, 32, 48), -- #1B2030
	header = Color3.fromRGB(27, 32, 48),
	title = Color3.fromRGB(245, 246, 250),
	text = Color3.fromRGB(245, 246, 250), -- #F5F6FA
	muted = Color3.fromRGB(168, 176, 200), -- #A8B0C8
	card = Color3.fromRGB(42, 49, 71), -- #2A3147
	btn = Color3.fromRGB(62, 74, 107), -- #3E4A6B secondary
	btnText = Color3.new(1, 1, 1),
	stroke = Color3.new(1, 1, 1),
	strokeT = 0.88,
	strokeW = 1.5,
	radius = 16,
	closeBg = Color3.fromRGB(240, 72, 90), -- #F0485A, the same close button on every pop-up
	closeFg = Color3.new(1, 1, 1),
	light = false,
}
local function kit(over)
	local t = table.clone(BASE)
	for k, v in pairs(over) do
		t[k] = v
	end
	return t
end
UI.PopStyles = {
	clean = kit({ line = Color3.fromRGB(255, 200, 61), radius = 12 }), -- really smart: gold, calm
	glass = kit({ line = Color3.fromRGB(77, 168, 255), radius = 12 }), -- smart: blue
	storybook = kit({ line = Color3.fromRGB(154, 107, 255), radius = 16 }), -- average / new: purple
	bubbly = kit({ line = Color3.fromRGB(255, 138, 61), radius = 20, strokeW = 2.5, strokeT = 0.7, titleFont = Enum.Font.FredokaOne }), -- Lose / animals: orange, chunky
	neon = kit({ line = Color3.fromRGB(255, 79, 163), radius = 20, strokeW = 3, strokeT = 0.6, titleFont = Enum.Font.FredokaOne }), -- really dumb: pink, loudest
}

function UI.popupStyle(): string
	local st = UI.state or {}
	local animal = st.stage ~= nil and st.stage ~= "human" and st.stage ~= "barelyhuman"
	if st.path == "Lose" or animal then
		if not animal and (st.cells or math.huge) < Config.UI.NeonBelowCells then
			return "neon"
		end
		return "bubbly"
	end
	if st.path == "Gain" then
		local iq = st.iq or 0
		if iq >= Config.UI.CleanCardIQ then
			return "clean"
		elseif iq >= Config.UI.GlassIQ then
			return "glass"
		end
	end
	return "storybook"
end

local function lum(c: Color3): number
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end
local function same(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.04
end

-- restyle one thing a screen put into a skinned pop-up (runs after the caller set its own colours)
local function skinOne(d: Instance, P)
	if d:FindFirstAncestorWhichIsA("GuiObject") and d:FindFirstAncestorWhichIsA("GuiObject"):GetAttribute("NoSkin") then
		return
	end
	if d:IsA("TextButton") then
		local plain = same(d.BackgroundColor3, KIT.panel2) or same(d.BackgroundColor3, KIT.panel) or same(d.BackgroundColor3, KIT.bg)
		if plain then
			d.BackgroundColor3 = P.btn
			d.TextColor3 = P.btnText
		elseif lum(d.BackgroundColor3) > 0.7 and lum(d.TextColor3) > 0.7 then
			d.TextColor3 = Color3.fromRGB(30, 30, 40) -- light custom button: dark text
		end
		if P.font then
			d.Font = P.font
		elseif P.face then
			d.FontFace = Font.new(P.face, Enum.FontWeight.Bold)
		end
		if P.outlineButtons then
			local s = d:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color, s.Transparency, s.Thickness = P.stroke, 0, 3
			end
		end
	elseif d:IsA("TextLabel") then
		if d.BackgroundTransparency > 0.5 then
			local c = d.TextColor3
			if P.light and lum(c) > 0.72 then
				d.TextColor3 = (same(c, KIT.muted) and P.muted) or P.text
			elseif not P.light and same(c, KIT.text) then
				d.TextColor3 = P.text
			elseif same(c, KIT.muted) then
				d.TextColor3 = P.muted
			end
		end
		if P.font then
			d.Font = P.font
		elseif P.face then
			local bold = d.Font == Enum.Font.GothamBold or d.Font == Enum.Font.GothamBlack
			d.FontFace = Font.new(P.face, bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular)
		end
	elseif d:IsA("Frame") then
		if same(d.BackgroundColor3, KIT.panel) or same(d.BackgroundColor3, KIT.panel2) or same(d.BackgroundColor3, KIT.bg) then
			d.BackgroundColor3 = P.card
		end
	end
end

function UI.modal(title: string, opts)
	UI.closeModal()
	opts = opts or {}
	local T = UI.T
	-- 1.9.1: which pop-up style (nil = the phone / big screens keep their own look)
	local P = (not opts.phone and not opts.big and not opts.noSkin) and UI.PopStyles[UI.popupStyle()] or nil
	local accent = opts.color or T.accent

	-- 1.9: a FULL-screen dim (it also covers the top bar inset, so it is never a partial rectangle)
	local inset = GuiService:GetGuiInset()
	local backdrop = UI.new("Frame", {
		Name = "ModalBackdrop",
		Position = UDim2.fromOffset(0, -inset.Y),
		Size = UDim2.new(1, 0, 1, inset.Y),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = opts.phone and 1 or Config.UI.ModalDim, -- 1.9.3: no dim behind the phone, so you can walk with it open
		ZIndex = 19,
		Parent = UI.gui,
	})
	local D = UI.D
	local phone = opts.phone == true
	local frame = UI.new("Frame", {
		Name = phone and "Phone" or "Modal",
		-- 1.9: the phone (main menu) stands tall on the RIGHT of the screen; pop-ups stay centred
		AnchorPoint = phone and Vector2.new(1, 0.5) or Vector2.new(0.5, 0.5),
		Position = phone and UDim2.new(1, -12, 0.5, inset.Y / 2) or UDim2.fromScale(0.5, 0.52),
		-- sized so that AFTER the device scale it still fits the screen
		-- 1.8.5: ordinary pop-ups are capped (Config.UI.ModalPhone / ModalPC); only the phone is near full screen
		Size = phone and UDim2.fromScale(Config.UI.PhoneHeight / D, Config.UI.PhoneHeight / D) or (function()
			local share = (opts.big and Vector2.new(0.9, 0.84)) or (UI.isPhone() and Config.UI.ModalPhone or Config.UI.ModalPC)
			return UDim2.fromScale(share.X / D, share.Y / D)
		end)(),
		BackgroundColor3 = phone and Color3.fromRGB(14, 14, 18) or T.bg,
		BackgroundTransparency = phone and 0 or T.bgT,
		ZIndex = 20,
		Parent = backdrop,
	}, {
		UI.new("UISizeConstraint", { MaxSize = phone and Vector2.new(720, 820) or (opts.maxSize or Config.UI.ModalMax) }), -- 1.8.7: wide enough for the landscape phone shape
	})
	if phone then
		-- 1.9: always a tall phone (target: docs/reference/phone_target.jpg), also on sideways phones
		UI.new("UIAspectRatioConstraint", { AspectRatio = Config.UI.PhoneAspect, DominantAxis = Enum.DominantAxis.Height, Parent = frame })
		UI.corner(frame, 34)
		UI.stroke(frame, Color3.fromRGB(10, 10, 12), 8, 0)
		-- notch
		local notch = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(90, 18), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 30, Parent = frame })
		UI.corner(notch, 9)
		-- status bar
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 6), Size = UDim2.new(1, -36, 0, 18), Text = os.date("%H:%M") .. string.rep(" ", 40) .. "📶 🔋", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), ZIndex = 29, Parent = frame })
	elseif P then
		frame.BackgroundColor3 = P.bg
		frame.BackgroundTransparency = P.bgT or 0
		UI.corner(frame, P.radius)
		UI.stroke(frame, P.stroke, P.strokeW, P.strokeT)
		if P.bg2 then
			UI.new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)), Rotation = 90, Parent = frame })
			frame.BackgroundColor3 = P.bg
			local g = frame:FindFirstChildOfClass("UIGradient")
			g.Color = ColorSequence.new(P.bg, P.bg2)
		end
		if P == UI.PopStyles.neon then
			-- a second glowing border inside the first
			local inner = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), ZIndex = 20, Parent = frame })
			UI.corner(inner, P.radius - 4)
			UI.stroke(inner, P.line, 2, 0.3)
		end
	else
		UI.corner(frame, T.radius + 4)
		UI.stroke(frame, Color3.new(1, 1, 1), 2, 0.88) -- 1.9 kit: thin light border (was a thick accent border)
		if T.wobble and UI.effects() > 0 and not UI.reducedMotion() then
			frame.Rotation = math.random(-2, 2)
		end
	end
	local scale = UI.new("UIScale", { Scale = 0.85 * D, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = D }):Play()

	-- header bar
	local header = UI.new("Frame", {
		Name = "Header",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = phone and UDim2.fromOffset(0, 28) or UDim2.new(),
		-- tall enough for the 48 px close button (1.7 skeleton), so it can't poke into the status bar
		Size = UDim2.new(1, 0, 0, phone and (UI.minTouch() + 4) or math.max(56, UI.minTouch() + 8)),
		ZIndex = 21,
		Parent = frame,
	})
	UI.corner(header, phone and 0 or (T.radius + 4))
	-- 1.9 kit (UI judge: "remove all gradients"): a calm solid header with one thin accent line
	header.BackgroundColor3 = T.panel
	if phone then
		header.BackgroundTransparency = 1 -- 1.9: the phone has no title bar, only its close button
	else
		-- square off the header's bottom corners
		UI.new("Frame", { BackgroundColor3 = T.panel, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 14), ZIndex = 21, Parent = header })
		UI.new("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), ZIndex = 22, Parent = header })
	end
	local titleLabel = UI.new("TextLabel", {
		Text = title,
		TextSize = UI.textSize(24),
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -80, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 22,
		Parent = header,
	})
	titleLabel:SetAttribute("Title", true)
	UI.styleText(titleLabel)
	titleLabel.TextStrokeTransparency = T.textStroke and 0 or 0.6
	if P then
		-- 1.9.1 pop-up style: header colour, title colour and font
		header.BackgroundColor3 = P.header
		for _, c in ipairs(header:GetChildren()) do
			if c:IsA("Frame") then
				c.BackgroundColor3 = (c.Size.Y.Offset == 2) and P.line or P.header
			end
		end
		titleLabel.TextColor3 = P.title
		titleLabel.TextStrokeTransparency = P.outlineTitle and 0 or 1
		titleLabel.TextStrokeColor3 = P.stroke
		if P.titleFont then
			titleLabel.Font = P.titleFont
		elseif P.font then
			titleLabel.Font = P.font
		elseif P.face then
			titleLabel.FontFace = Font.new(P.face, Enum.FontWeight.Bold)
		end
		if P == UI.PopStyles.storybook then
			-- a red ribbon title in the middle instead of a full bar
			header.BackgroundTransparency = 1
			for _, c in ipairs(header:GetChildren()) do
				if c:IsA("Frame") then
					c.Visible = false
				end
			end
			local ribbon = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0.62, 0, 0, 46), BackgroundColor3 = P.header, ZIndex = 21, Parent = header })
			UI.corner(ribbon, 6)
			UI.stroke(ribbon, P.line, 3, 0)
			titleLabel.Parent = ribbon
			titleLabel.Position = UDim2.fromOffset(8, 0)
			titleLabel.Size = UDim2.new(1, -16, 1, 0)
			titleLabel.TextXAlignment = Enum.TextXAlignment.Center
		elseif P == UI.PopStyles.bubbly then
			UI.stroke(header, P.stroke, 4, 0)
			titleLabel.TextXAlignment = Enum.TextXAlignment.Center
			titleLabel.Text = string.upper(title)
		elseif P == UI.PopStyles.neon or P == UI.PopStyles.glass then
			header.BackgroundTransparency = P == UI.PopStyles.glass and 1 or 0
		end
	end

	local closeBtn = nil
	if not opts.noClose then
		closeBtn = UI.button(header, "X", function() -- (the ✕ symbol isn't in these fonts: it showed as a box)
			UI.closeModal()
		end, {
			Font = Enum.Font.GothamBlack,
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.fromOffset(UI.minTouch(), UI.minTouch()),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(255, 80, 100),
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 23,
		})
		UI.corner(closeBtn, UI.minTouch() / 2)
		if P then
			closeBtn.BackgroundColor3 = P.closeBg
			closeBtn.TextColor3 = P.closeFg
			if P.outlineButtons then
				UI.stroke(closeBtn, P.stroke, 3, 0)
			end
		end
	end

	local content = UI.new("ScrollingFrame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = phone and UDim2.fromOffset(8, 28 + UI.minTouch() + 4 + 6) or UDim2.fromOffset(14, math.max(56, UI.minTouch() + 8) + 10),
		Size = phone and UDim2.new(1, -16, 1, -(28 + UI.minTouch() + 4 + 6 + 50)) or UDim2.new(1, -28, 1, -(math.max(56, UI.minTouch() + 8) + 22)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 21,
		Selectable = false,
		Parent = frame,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }),
	})

	if phone then
		-- home bar
		local home = UI.new("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.fromOffset(150, 40),
			Text = opts.onHome and "⌂  Home" or "",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = Color3.fromRGB(60, 60, 70),
			ZIndex = 30,
			Parent = frame,
		})
		UI.corner(home, 17)
		home.Activated:Connect(function()
			if opts.onHome then
				opts.onHome()
			else
				UI.closeModal()
			end
		end)
	end

	-- 1.9.1 pop-up style: restyle what the screen puts in (after it has set its own colours)
	if P then
		content.ScrollBarImageColor3 = P.line
		content.DescendantAdded:Connect(function(d)
			task.defer(function()
				if d.Parent then
					pcall(skinOne, d, P)
				end
			end)
		end)
	end

	current = { frame = frame, backdrop = backdrop, content = content, onClose = opts.onClose }
	UI.popupOpen = not phone
	if not opts.noClose and phone then
		-- 1.9.3: the phone lets touches through (thumbstick, camera): close with X / home / ButtonB only
		backdrop.Active = false
		ContextActionService:BindAction("BrainCloseModal", function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				UI.closeModal()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.ButtonB)
	elseif not opts.noClose then
		-- 1.8.5: tap outside the pop-up to close it
		backdrop.Active = true
		backdrop.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local p, s = frame.AbsolutePosition, frame.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < p.X or x > p.X + s.X or y < p.Y or y > p.Y + s.Y then
				if current and current.frame == frame then
					UI.closeModal()
				end
			end
		end)
		ContextActionService:BindAction("BrainCloseModal", function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				UI.closeModal()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.ButtonB)
	end

	local handle = { frame = frame, content = content, closeButton = closeBtn }
	function handle.close()
		if current and current.frame == frame then
			UI.closeModal()
		end
	end
	function handle.alive(): boolean
		return frame.Parent ~= nil and backdrop.Parent ~= nil
	end
	function handle.clear()
		for _, c in ipairs(content:GetChildren()) do
			if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
				c:Destroy()
			end
		end
	end
	function handle.focus()
		if UserInputService.GamepadEnabled then
			task.defer(function()
				for _, d in ipairs(content:GetDescendants()) do
					if d:IsA("GuiButton") and d.Visible and d.Selectable then
						GuiService.SelectedObject = d
						return
					end
				end
				if closeBtn then
					GuiService.SelectedObject = closeBtn
				end
			end)
		end
	end
	return handle
end

-- 1.9: a kit slider (Settings volume). value 0..1; onChange(value) fires when you let go.
function UI.slider(parent, label: string, value: number, onChange, props)
	local T = UI.T
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64), Parent = parent })
	for k, v in pairs(props or {}) do
		row[k] = v
	end
	local title = UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = T.body, TextSize = UI.textSize(14), TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = row })
	local track = UI.new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 28), BackgroundTransparency = 1, Selectable = true, Parent = row })
	local bar = UI.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = T.panel2, Parent = track })
	UI.corner(bar, 4)
	local fill = UI.new("Frame", { Size = UDim2.fromScale(value, 1), BackgroundColor3 = T.accent, Parent = bar })
	UI.corner(fill, 4)
	local knob = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(value, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.text, Parent = track })
	UI.corner(knob, 13)
	local function show(v)
		value = math.clamp(v, 0, 1)
		fill.Size = UDim2.fromScale(value, 1)
		knob.Position = UDim2.fromScale(value, 0.5)
		title.Text = label .. ": " .. math.floor(value * 100 + 0.5) .. "%"
	end
	show(value)
	local dragging = false
	local function at(x: number)
		local p, s = track.AbsolutePosition.X, math.max(1, track.AbsoluteSize.X)
		show(math.floor(((x - p) / s) * 20 + 0.5) / 20) -- steps of 5%
	end
	local conns = {}
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			at(input.Position.X)
		end
	end)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			at(input.Position.X)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			onChange(value)
		end
	end))
	row.Destroying:Connect(function()
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
	end)
	-- controllers: pressing A on the selected track steps it up by 10% (wraps to 0)
	track.Activated:Connect(function()
		if GuiService.SelectedObject == track then
			show(value >= 1 and 0 or value + 0.1)
			onChange(value)
		end
	end)
	return row
end

-- 1.9: a row of tabs (Settings). tabs = { {key = , name = } }; onPick(key). Returns setActive(key).
function UI.tabs(parent, tabs, active: string, onPick, props)
	local T = UI.T
	local bar = UI.new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, BorderSizePixel = 0, Parent = parent }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	for k, v in pairs(props or {}) do
		bar[k] = v
	end
	local buttons = {}
	local function setActive(key)
		for k, b in pairs(buttons) do
			b.BackgroundColor3 = k == key and T.accent or T.panel2
		end
	end
	for i, t in ipairs(tabs) do
		local b = UI.new("TextButton", { Text = t.name, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 44), Font = T.font, TextSize = UI.textSize(14), TextColor3 = T.text, BackgroundColor3 = T.panel2, LayoutOrder = i, Parent = bar }, {
			UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		})
		UI.corner(b, 12)
		buttons[t.key] = b
		b.Activated:Connect(function()
			setActive(t.key)
			onPick(t.key)
		end)
	end
	setActive(active)
	return setActive
end

-- 1.9.1 real icon art: the image for a HUD button / phone app key (nil = keep the emoji)
-- 1.9.3: icon pictures that never drew (still in moderation / rejected). Those keys show their emoji
-- instead of an empty square. Filled by UI.watchIcon.
UI.badIcons = {}
function UI.watchIcon(img: ImageLabel, onFail: () -> ())
	-- 1.9.3 fix: ContentProvider:PreloadAsync reported EVERY icon as failed (even ones that draw fine), so
	-- every button fell back to emoji. Now: an icon only counts as broken if it is on screen for
	-- Config.UI.IconLoadSeconds and still hasn't drawn (ImageLabel.IsLoaded).
	local id = img.Image
	if UI.badIcons[id] then
		onFail()
		return
	end
	task.spawn(function()
		local shown = 0
		while img.Parent and not img.IsLoaded do
			task.wait(0.5)
			if img.AbsoluteSize.X > 0 and img:IsDescendantOf(game) then
				local onScreen = true
				local a = img:FindFirstAncestorWhichIsA("LayerCollector")
				if a and a:IsA("ScreenGui") and not a.Enabled then
					onScreen = false
				end
				if onScreen then
					shown += 0.5
				end
			end
			if shown >= (Config.UI.IconLoadSeconds or 10) then
				UI.badIcons[id] = true
				if img.Parent then
					onFail()
				end
				return
			end
		end
	end)
end

function UI.iconImage(key: string?): (string?, Color3?, number?)
	if not key then
		return nil
	end
	local function ok(img: string?): string?
		return (img and not UI.badIcons[img]) and img or nil
	end
	local style = UI.popupStyle and UI.popupStyle() or "storybook"
	if style == "glass" or style == "clean" or style == "neon" then
		local mono = Config.IconsMono and Config.IconsMono[key]
		if mono and ok("rbxassetid://" .. tostring(mono)) then
			if style == "neon" then
				local tints = Config.IconNeonTints
				local i = (#key % #tints) + 1
				return "rbxassetid://" .. tostring(mono), tints[i], (#key % 2 == 0) and -8 or 7
			end
			return "rbxassetid://" .. tostring(mono), Color3.new(1, 1, 1), 0
		end
	end
	local id = Config.Icons and Config.Icons[key]
	return id and ok("rbxassetid://" .. tostring(id)) or nil, nil, 0
end

-- 1.9.3 (user: "everything should have full 3D icons"): the 3D icon for `key` if we have one (emoji if the
-- picture is missing or fails to load). props = Position / Size / ZIndex etc.
function UI.icon(parent, key: string?, emoji: string, props)
	local art, tint, rot = UI.iconImage(key)
	local function emojiLabel()
		local l = UI.new("TextLabel", { BackgroundTransparency = 1, TextScaled = true, Text = emoji, Parent = parent })
		for k, v in pairs(props or {}) do
			l[k] = v
		 end
		return l
	end
	if not art then
		return emojiLabel()
	end
	local img = UI.new("ImageLabel", { BackgroundTransparency = 1, Image = art, ImageColor3 = tint or Color3.new(1, 1, 1), Rotation = rot or 0, ScaleType = Enum.ScaleType.Fit, Parent = parent })
	for k, v in pairs(props or {}) do
		img[k] = v
	end
	UI.watchIcon(img, function()
		img:Destroy()
		emojiLabel()
	end)
	return img
end

-- 1.9.1: a glossy little phone drawn with frames (the icon packs have no phone)
function UI.drawPhoneIcon(parent: Instance, props)
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Parent = parent })
	for k, v in pairs(props or {}) do
		holder[k] = v
	end
	local body = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.58, 0.96), BackgroundColor3 = Color3.fromRGB(120, 70, 230), Parent = holder })
	UI.corner(body, 8)
	UI.stroke(body, Color3.fromRGB(30, 20, 60), 2.5, 0)
	UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(190, 150, 255), Color3.fromRGB(110, 60, 220)), Rotation = 90, Parent = body })
	local screen = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.fromScale(0.78, 0.72), BackgroundColor3 = Color3.fromRGB(80, 200, 255), Parent = body })
	UI.corner(screen, 5)
	UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 235, 255), Color3.fromRGB(40, 140, 240)), Rotation = 120, Parent = screen })
	local shine = UI.new("Frame", { Position = UDim2.fromScale(0.08, 0.06), Size = UDim2.fromScale(0.3, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, Rotation = 18, Parent = screen })
	UI.corner(shine, 4)
	local button = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.91), Size = UDim2.fromScale(0.22, 0.07), BackgroundColor3 = Color3.fromRGB(240, 235, 255), Parent = body })
	UI.corner(button, 4)
	return holder
end

function UI.isGamepad(): boolean
	return UserInputService.GamepadEnabled and not UserInputService.TouchEnabled
end

return UI

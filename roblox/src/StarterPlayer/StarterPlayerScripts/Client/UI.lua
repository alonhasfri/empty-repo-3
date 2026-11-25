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
			UI.sound("CartoonBoing", 0.25)
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
function UI.sound(name: string?, volumeScale: number?)
	if not name then
		return
	end
	local id = Config.Sounds[name]
	if not id or id == 0 then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = (UI.settings.sfx or 0.8) * (volumeScale or 1)
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
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 170),
	Size = UDim2.new(0.4, 0, 0, 10),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 50,
	Parent = UI.gui,
}, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(300, 600), MinSize = Vector2.new(200, 0) }),
})
-- 1.8.1: toasts sit just under the goal line, whatever the screen size
UI.onScale(function(d)
	toastHolder.Position = UDim2.new(0.5, 0, 0, 14 + 60 * d) -- 1.8.7: high up, under the slim goal lines (never mid-screen)
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
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
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
	l:SetAttribute("Body", true)
	UI.styleText(l)
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

function UI.modal(title: string, opts)
	UI.closeModal()
	opts = opts or {}
	local T = UI.T
	local accent = opts.color or T.accent

	-- 1.9: a FULL-screen dim (it also covers the top bar inset, so it is never a partial rectangle)
	local inset = GuiService:GetGuiInset()
	local backdrop = UI.new("Frame", {
		Name = "ModalBackdrop",
		Position = UDim2.fromOffset(0, -inset.Y),
		Size = UDim2.new(1, 0, 1, inset.Y),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = opts.phone and Config.UI.PhoneDim or Config.UI.ModalDim,
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

	current = { frame = frame, backdrop = backdrop, content = content, onClose = opts.onClose }
	if not opts.noClose then
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

function UI.isGamepad(): boolean
	return UserInputService.GamepadEnabled and not UserInputService.TouchEnabled
end

return UI

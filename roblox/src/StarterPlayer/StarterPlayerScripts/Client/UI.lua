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
		title = Enum.Font.Merriweather,
		body = Enum.Font.Gotham,
		radius = 12,
		strokeW = 1.5,
		bgT = 0.06,
	},
	genius = {
		bg = Color3.fromRGB(246, 242, 232),
		panel = Color3.fromRGB(236, 230, 216),
		panel2 = Color3.fromRGB(222, 214, 196),
		accent = Color3.fromRGB(28, 40, 70),
		accent2 = Color3.fromRGB(120, 95, 50),
		text = Color3.fromRGB(28, 30, 38),
		muted = Color3.fromRGB(110, 105, 95),
		stroke = Color3.fromRGB(150, 130, 90),
		strokeT = 0.3,
		font = Enum.Font.Merriweather,
		title = Enum.Font.Garamond,
		body = Enum.Font.Merriweather,
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
	d = math.clamp(d, Config.UI.MinDeviceScale, 1.35)
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
		size = math.max(size, Config.UI.MinPhoneText)
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
	if b.Size.Y.Scale == 0 and b.Size.Y.Offset < Config.UI.MinTouch then
		b.Size = UDim2.new(b.Size.X.Scale, math.max(b.Size.X.Offset, b.Size.X.Scale == 0 and Config.UI.MinTouch or 0), 0, Config.UI.MinTouch)
	end
	local base = b.BackgroundColor3
	UI.gradient(b, Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 210), 90)
	if T.shine then
		UI.gradient(b, Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170), 90)
	end
	if T.wobble then
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
	Position = UDim2.new(0.5, 0, 0, 150),
	Size = UDim2.new(0.4, 0, 0, 10),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 50,
	Parent = UI.gui,
}, {
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(360, 600), MinSize = Vector2.new(220, 0) }),
})
UI.autoScale(toastHolder)

local toastOrder = 0
function UI.toast(text: string, color: Color3?, seconds: number?)
	toastOrder += 1
	local T = UI.T
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = -toastOrder, ZIndex = 50, Parent = toastHolder })
	local card = UI.new("Frame", {
		BackgroundColor3 = T.bg,
		BackgroundTransparency = T.bgT,
		Position = UDim2.fromScale(1.2, 0),
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 50,
		Parent = holder,
	}, {
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})
	UI.corner(card)
	UI.stroke(card)
	local bar = UI.new("Frame", { BackgroundColor3 = color or T.accent, Position = UDim2.new(0, -16, 0, -10), Size = UDim2.new(0, 6, 1, 20), ZIndex = 51, Parent = card })
	UI.corner(bar, 3)
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = T.text,
		TextSize = UI.textSize(15),
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 51,
		Parent = card,
	})
	l:SetAttribute("Body", true)
	UI.styleText(l)
	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0, 0) }):Play()
	task.delay(seconds or 4, function()
		local t = TweenService:Create(card, TweenInfo.new(0.25), { Position = UDim2.fromScale(1.2, 0) })
		t:Play()
		t.Completed:Wait()
		holder:Destroy()
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

	local backdrop = UI.new("Frame", {
		Name = "ModalBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		ZIndex = 19,
		Parent = UI.gui,
	})
	local D = UI.D
	local phone = opts.phone == true
	local frame = UI.new("Frame", {
		Name = phone and "Phone" or "Modal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, phone and 0.5 or 0.52),
		-- sized so that AFTER the device scale it still fits the screen
		Size = phone and UDim2.fromScale(0.94 / D, 0.94 / D) or UDim2.fromScale(0.92 / D, 0.84 / D),
		BackgroundColor3 = phone and Color3.fromRGB(14, 14, 18) or T.bg,
		BackgroundTransparency = phone and 0 or T.bgT,
		ZIndex = 20,
		Parent = backdrop,
	}, {
		UI.new("UISizeConstraint", { MaxSize = phone and Vector2.new(400, 820) or (opts.maxSize or Vector2.new(580, 500)) }),
	})
	if phone then
		-- on a sideways phone screen a tall phone would be tiny, so it gets a wider shape there
		local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 462)
		local aspect = (UI.isPhone() and v.X > v.Y) and Config.UI.LandscapePhoneAspect or 0.52
		UI.new("UIAspectRatioConstraint", { AspectRatio = aspect, DominantAxis = Enum.DominantAxis.Height, Parent = frame })
		UI.corner(frame, 34)
		UI.stroke(frame, Color3.fromRGB(10, 10, 12), 8, 0)
		-- notch
		local notch = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(90, 18), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 30, Parent = frame })
		UI.corner(notch, 9)
		-- status bar
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 6), Size = UDim2.new(1, -36, 0, 18), Text = os.date("%H:%M") .. string.rep(" ", 40) .. "📶 🔋", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), ZIndex = 29, Parent = frame })
	else
		UI.corner(frame, T.radius + 4)
		UI.stroke(frame, T.textStroke and Color3.new(0, 0, 0) or accent, T.strokeW + 1, 0)
		if T.wobble then
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
		Size = UDim2.new(1, 0, 0, phone and (Config.UI.MinTouch + 4) or math.max(56, Config.UI.MinTouch + 8)),
		ZIndex = 21,
		Parent = frame,
	})
	UI.corner(header, phone and 0 or (T.radius + 4))
	UI.gradient(header, accent, T.accent2, 0)
	-- square off the header's bottom corners
	local cover = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 14), ZIndex = 21, Parent = header })
	UI.gradient(cover, accent, T.accent2, 0)
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
			Size = UDim2.fromOffset(Config.UI.MinTouch, Config.UI.MinTouch),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(255, 80, 100),
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 23,
		})
		UI.corner(closeBtn, Config.UI.MinTouch / 2)
	end

	local content = UI.new("ScrollingFrame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = phone and UDim2.fromOffset(8, 28 + Config.UI.MinTouch + 4 + 6) or UDim2.fromOffset(14, math.max(56, Config.UI.MinTouch + 8) + 10),
		Size = phone and UDim2.new(1, -16, 1, -(28 + Config.UI.MinTouch + 4 + 6 + 50)) or UDim2.new(1, -28, 1, -(math.max(56, Config.UI.MinTouch + 8) + 22)),
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

function UI.isGamepad(): boolean
	return UserInputService.GamepadEnabled and not UserInputService.TouchEnabled
end

return UI

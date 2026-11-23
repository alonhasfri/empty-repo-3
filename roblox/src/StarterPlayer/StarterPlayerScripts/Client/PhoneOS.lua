-- PhoneOS (1.7): the phone changes with your brain, not just its colors.
--   toy  (Lose path, or Gain IQ under 95): big chunky icons, 2 per row, loud.
--   cozy (Gain IQ 95-120): a clean 3x3 phone. Brain Bank (basic) unlocks.
--   real (Gain IQ 120+): a real-feeling phone OS: status bar, swipe between home
--        pages, a dock, labelled 4-column grid, Hoppr rides, Brain Bank and Shifts.
-- Animals don't get a phone at all (see AnimalUI).
-- Settings -> "Simple phone" gives everyone the same plain phone.
-- Text: Content.Life. Numbers: Config.PhoneTiers / Config.Life.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local PhoneOS = {}
PhoneOS.stations = nil -- the Stations module (set by ClientMain)
PhoneOS.classicPhone = nil -- the old phone function (set by ClientMain)
PhoneOS.animalUI = nil -- function() for animals (set by ClientMain)
PhoneOS.beforeOpen = nil -- function(appKey, go) for the Lose-path "brain lag" (set by LoseFX)
PhoneOS.label = nil -- function(text) -> text, scrambles app labels on the Lose path (set by LoseFX)

local TL = Content.Life
local C = UI.Colors
local WHITE = Color3.new(1, 1, 1)
local SOFT = Color3.fromRGB(200, 205, 215)

local EXTRA = {
	hoppr = { key = "hoppr", c1 = Color3.fromRGB(40, 40, 50), c2 = Color3.fromRGB(255, 200, 40) },
	bank = { key = "bank", c1 = Color3.fromRGB(40, 160, 120), c2 = Color3.fromRGB(20, 90, 70) },
	shifts = { key = "shifts", c1 = Color3.fromRGB(255, 120, 60), c2 = Color3.fromRGB(200, 60, 40) },
}
for key, a in pairs(EXTRA) do
	a.icon = TL.Apps[key].icon
	a.name = TL.Apps[key].name
end

local function isAnimal(st): boolean
	return st.stage ~= nil and st.stage ~= "human" and st.stage ~= "barelyhuman"
end

-- Which phone this brain gets
function PhoneOS.tier(st): string
	st = st or UI.state or {}
	if UI.settings and UI.settings.classicHud then
		return "classic"
	end
	if st.path ~= "Gain" then
		return "toy"
	end
	local iq = st.iq or 0
	if iq >= Config.PhoneTiers.RealIQ then
		return "real"
	elseif iq >= Config.PhoneTiers.CozyIQ then
		return "cozy"
	end
	return "toy"
end

local function appsFor(st, tier: string)
	local base = (PhoneOS.stations and PhoneOS.stations.PHONE_APPS or {})[st.path or ""] or {}
	local list = {}
	for _, a in ipairs(base) do
		table.insert(list, a)
	end
	local function addBefore(app)
		-- extra apps go before Settings
		local n = #list
		if n > 0 and list[n].key == "settings" then
			table.insert(list, n, app)
		else
			table.insert(list, app)
		end
	end
	if tier == "real" then
		addBefore(EXTRA.hoppr)
		addBefore(EXTRA.bank)
		if st.path == "Gain" then
			addBefore(EXTRA.shifts)
		end
	elseif tier == "cozy" then
		addBefore(EXTRA.bank)
	end
	return list
end

local function phoneOpts(color: Color3)
	return { phone = true, color = color, onHome = function()
		PhoneOS.open()
	end }
end

local function openApp(app)
	local function go()
		UI.sound("CartoonBoing", 0.2)
		if app.key == "settings" then
			PhoneOS.stations.settings()
		elseif app.key == "hoppr" then
			PhoneOS.hoppr()
		elseif app.key == "bank" then
			PhoneOS.bank()
		elseif app.key == "shifts" then
			PhoneOS.shifts()
		elseif PhoneOS.stations.route then
			PhoneOS.stations.route(app.key)
		end
	end
	if PhoneOS.beforeOpen then
		PhoneOS.beforeOpen(app.key, go)
	else
		go()
	end
end

local function appLabel(text: string): string
	if PhoneOS.label then
		return PhoneOS.label(text)
	end
	return text
end

-- One app icon (icons never scramble, so the phone always still works)
local function appIcon(parent, app, order: number, size: number, labelH: number)
	local cell = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, LayoutOrder = order, Selectable = true, Parent = parent })
	-- the icon fills its grid cell (up to `size`), so narrow phones never get overlapping icons
	local icon = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.9, 0.9), BackgroundColor3 = WHITE, Parent = cell }, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }),
		UI.new("UISizeConstraint", { MaxSize = Vector2.new(size, size) }),
	})
	UI.corner(icon, math.floor(size * 0.27))
	UI.gradient(icon, app.c1, app.c2, 45)
	local pad = math.floor(size * 0.17)
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = app.icon, TextScaled = true, Parent = icon }, {
		UI.new("UIPadding", { PaddingTop = UDim.new(0, pad), PaddingBottom = UDim.new(0, pad), PaddingLeft = UDim.new(0, pad), PaddingRight = UDim.new(0, pad) }),
	})
	if labelH > 0 then
		UI.new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, labelH), Text = appLabel(app.name), Font = Enum.Font.GothamMedium, TextScaled = true, TextColor3 = WHITE, Parent = cell })
	end
	cell.Activated:Connect(function()
		openApp(app)
	end)
	return cell
end

---------------------------------------------------------------------
-- Home screens
---------------------------------------------------------------------
local function wallpaper(parent, st, tier: string, order: number)
	local h = tier == "toy" and 90 or 110
	local wall = UI.new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, 0, 0, h), LayoutOrder = order, Parent = parent })
	UI.corner(wall, 18)
	if tier == "toy" then
		UI.gradient(wall, Color3.fromRGB(255, 60, 200), Color3.fromRGB(255, 220, 40), 20)
	elseif tier == "cozy" then
		UI.gradient(wall, Color3.fromRGB(240, 170, 110), Color3.fromRGB(150, 110, 200), 60)
	else
		UI.gradient(wall, Color3.fromRGB(30, 50, 90), Color3.fromRGB(70, 110, 160), 90)
	end
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h * 0.55), Position = UDim2.fromOffset(0, 8), Text = os.date("%H:%M"), Font = tier == "real" and Enum.Font.GothamMedium or Enum.Font.FredokaOne, TextScaled = true, TextColor3 = WHITE, Parent = wall })
	local sub = tier == "toy" and ("🧠 " .. tostring(st.cellsText or "") .. " 🔥🔥") or ("🧠 " .. tostring(st.cellsText or "") .. " brain cells")
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -26), Text = sub, Font = Enum.Font.GothamMedium, TextScaled = true, TextColor3 = Color3.fromRGB(255, 245, 255), Parent = wall })
end

local function gridHome(m, st, tier: string)
	local apps = appsFor(st, tier)
	wallpaper(m.content, st, tier, 1)
	local cols, size, labelH, cellH = 3, 58, 18, 86
	if tier == "toy" then
		cols, size, labelH, cellH = 2, 84, 24, 118
	end
	local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / cols - 0.03, 0, 0, cellH), CellPadding = UDim2.new(0.03, 0, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, app in ipairs(apps) do
		appIcon(grid, app, i, size, labelH)
	end
	if #apps == 0 then
		UI.label(m.content, "Pick a path first (bottom of the screen) to unlock your apps.", { TextColor3 = WHITE, LayoutOrder = 3 })
	end
end

-- The real-feeling phone OS: status bar, swipe pages, page dots, dock
local function realHome(m, st)
	local apps = appsFor(st, "real")
	-- (the phone frame already draws the status bar; a second one here showed the time twice)
	-- widget
	local widget = UI.new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, 0, 0, 74), LayoutOrder = 2, Parent = m.content })
	UI.corner(widget, 18)
	UI.gradient(widget, Color3.fromRGB(30, 50, 90), Color3.fromRGB(70, 110, 160), 90)
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 36), Text = os.date("%A %H:%M"), Font = Enum.Font.GothamMedium, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, Parent = widget })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -28, 0, 20), Text = "IQ " .. (st.iq and tostring(math.floor(st.iq)) or "?") .. (st.job and ("  •  💼 " .. st.job) or "") .. "  •  💰 " .. tostring(st.coins or 0), Font = Enum.Font.Gotham, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = SOFT, Parent = widget })

	-- swipe pages: 4 columns x 3 rows per page; the last 4 apps sit in the dock
	local perPage = 12
	local dockCount = math.min(4, #apps)
	local pageApps = {}
	for i = 1, #apps - dockCount do
		table.insert(pageApps, apps[i])
	end
	local pagesHolder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 300), ClipsDescendants = true, LayoutOrder = 3, Parent = m.content })
	local layout = UI.new("UIPageLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		EasingStyle = Enum.EasingStyle.Quad,
		TweenTime = UI.reducedMotion() and 0 or 0.25,
		TouchInputEnabled = true,
		GamepadInputEnabled = true,
		ScrollWheelInputEnabled = true,
		Circular = false,
		Parent = pagesHolder,
	})
	local pageCount = math.max(1, math.ceil(#pageApps / perPage))
	for p = 1, pageCount do
		local page = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), LayoutOrder = p, Parent = pagesHolder }, {
			UI.new("UIGridLayout", { CellSize = UDim2.new(0.23, 0, 0, 92), CellPadding = UDim2.new(0.026, 0, 0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		for i = (p - 1) * perPage + 1, math.min(#pageApps, p * perPage) do
			appIcon(page, pageApps[i], i, 56, 18)
		end
	end
	-- page dots + arrows (arrows for mouse and controller players)
	local dotsRow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 4, Parent = m.content }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local dots = {}
	local prev = UI.new("TextButton", { Text = "‹", Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromOffset(48, 48), LayoutOrder = 0, Parent = dotsRow })
	for p = 1, pageCount do
		local dot = UI.new("Frame", { Size = UDim2.fromOffset(8, 8), BackgroundColor3 = WHITE, BackgroundTransparency = p == 1 and 0 or 0.6, LayoutOrder = p, Parent = dotsRow })
		UI.corner(dot, 4)
		dots[p] = dot
	end
	local nextB = UI.new("TextButton", { Text = "›", Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromOffset(48, 48), LayoutOrder = pageCount + 1, Parent = dotsRow })
	prev.Visible = pageCount > 1
	nextB.Visible = pageCount > 1
	prev.Activated:Connect(function()
		layout:Previous()
	end)
	nextB.Activated:Connect(function()
		layout:Next()
	end)
	layout:GetPropertyChangedSignal("CurrentPage"):Connect(function()
		local cur = layout.CurrentPage
		for p, dot in ipairs(dots) do
			dot.BackgroundTransparency = (cur and cur.LayoutOrder == p) and 0 or 0.6
		end
	end)
	-- dock
	local dock = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 64, 76), BackgroundTransparency = 0.2, Size = UDim2.new(1, 0, 0, 84), LayoutOrder = 5, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.23, 0, 0, 70), CellPadding = UDim2.new(0.026, 0, 0, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 8) }),
	})
	UI.corner(dock, 22)
	for i = #apps - dockCount + 1, #apps do
		appIcon(dock, apps[i], i, 56, 0)
	end
end

function PhoneOS.open()
	local st = UI.state or {}
	if isAnimal(st) and PhoneOS.animalUI then
		PhoneOS.animalUI()
		return
	end
	local tier = PhoneOS.tier(st)
	if tier == "classic" and PhoneOS.classicPhone then
		PhoneOS.classicPhone()
		return
	end
	if PhoneOS.stations and PhoneOS.stations.onEvent then
		pcall(PhoneOS.stations.onEvent, "phone")
	end
	local title = tier == "real" and "" or (tier == "cozy" and "📱 Phone" or "📱 BRAIN PHONE!!")
	local color = tier == "real" and Color3.fromRGB(40, 44, 56) or (tier == "cozy" and Color3.fromRGB(180, 120, 90) or Color3.fromRGB(255, 60, 180))
	local m = UI.modal(title, { phone = true, color = color })
	if tier == "real" then
		realHome(m, st)
	else
		gridHome(m, st, tier)
	end
	m.focus()
end

---------------------------------------------------------------------
-- Hoppr: ride-hail
---------------------------------------------------------------------
local function whiteLabel(parent, text: string, order: number, props)
	local l = UI.label(parent, text, { TextColor3 = WHITE, LayoutOrder = order })
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

local riding = nil -- the open ride screen, so "rideDone" can close it

function PhoneOS.hoppr()
	local r = Remote.call("ride_places")
	if not r.ok then
		return
	end
	local m = UI.modal(TL.Ride.Title, phoneOpts(Color3.fromRGB(40, 40, 50)))
	local function quoteScreen(place)
		local q = Remote.call("ride_quote", { key = place.key })
		if not q.ok then
			UI.toast("⛔ " .. tostring(q.msg or ""), C.bad)
			return
		end
		m.clear()
		whiteLabel(m.content, "📍 " .. tostring(q.name), 1, { Font = Enum.Font.GothamBold, TextSize = UI.textSize(20) })
		whiteLabel(m.content, string.format(TL.Ride.Fare, q.fare) .. "   •   " .. string.format(TL.Ride.Eta, q.eta), 2)
		whiteLabel(m.content, "💰 " .. tostring(q.coins) .. "  •  " .. tostring(q.distance) .. " studs", 3, { TextColor3 = SOFT })
		if q.busy then
			whiteLabel(m.content, TL.Ride.Busy, 4, { TextColor3 = Color3.fromRGB(255, 210, 90) })
		end
		UI.button(m.content, string.format(TL.Ride.Confirm, q.fare), function()
			local b = Remote.call("ride_book", { key = place.key })
			if not b.ok then
				UI.toast("⛔ " .. tostring(b.msg or ""), C.bad)
				return
			end
			local ride = b.ride
			m.clear()
			whiteLabel(m.content, TL.Ride.Coming, 1, { Font = Enum.Font.GothamBold, TextSize = UI.textSize(20) })
			local card = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(245, 245, 240), Size = UDim2.new(1, 0, 0, 96), LayoutOrder = 2, Parent = m.content })
			UI.corner(card, 14)
			UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 1, -16), Text = string.format(TL.Ride.PlateCard, ride.color, ride.model, ride.plate, ride.driver), Font = Enum.Font.GothamBold, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(20, 20, 24), Parent = card })
			local timer = whiteLabel(m.content, string.format(TL.Ride.Eta, ride.eta), 3)
			riding = m
			task.spawn(function()
				for t = ride.eta, 1, -1 do
					if not m.alive() then
						return
					end
					timer.Text = string.format(TL.Ride.Eta, t)
					task.wait(1)
				end
				if m.alive() then
					timer.Text = string.format(TL.Ride.Riding, tostring(ride.name))
					UI.sound("Whoosh", 0.4)
				end
			end)
		end, { LayoutOrder = 10, BackgroundColor3 = Color3.fromRGB(255, 200, 40), TextColor3 = Color3.new(0, 0, 0) })
		UI.button(m.content, TL.Ride.Cancel, function()
			PhoneOS.hoppr()
		end, { LayoutOrder = 11 })
		whiteLabel(m.content, TL.Ride.Free, 12, { TextColor3 = SOFT, TextSize = UI.textSize(13) })
	end
	whiteLabel(m.content, TL.Ride.WhereTo, 1, { Font = Enum.Font.GothamBold, TextSize = UI.textSize(22) })
	for i, place in ipairs(r.places) do
		UI.button(m.content, place.name, function()
			quoteScreen(place)
		end, { LayoutOrder = 10 + i, TextSize = UI.textSize(14) })
	end
	whiteLabel(m.content, TL.Ride.Free, 999, { TextColor3 = SOFT, TextSize = UI.textSize(13) })
	m.focus()
end

Remote.on("rideDone", function(d)
	if riding and riding.alive() then
		riding.close()
	end
	riding = nil
	UI.toast(string.format(TL.Ride.Receipt, tostring(d.name), tonumber(d.fare) or 0, tostring(d.plate)), C.good, 6)
end)

---------------------------------------------------------------------
-- Brain Bank
---------------------------------------------------------------------
function PhoneOS.bank()
	local r = Remote.call("bank_state")
	if not r.ok then
		return
	end
	local m = UI.modal(TL.Bank.Title, phoneOpts(Color3.fromRGB(40, 160, 120)))
	whiteLabel(m.content, string.format(TL.Bank.Checking, r.checking), 1, { Font = Enum.Font.GothamBold, TextSize = UI.textSize(18) })
	whiteLabel(m.content, string.format(TL.Bank.Savings, r.savings), 2, { Font = Enum.Font.GothamBold, TextSize = UI.textSize(18) })
	whiteLabel(m.content, string.format(TL.Bank.Rate, r.rate, math.floor(r.every / 60)), 3, { TextColor3 = SOFT })
	local nextLabel = whiteLabel(m.content, "", 4, { TextColor3 = SOFT })
	task.spawn(function()
		local left = r.nextIn
		while m.alive() and left >= 0 do
			nextLabel.Text = string.format(TL.Bank.NextIn, math.floor(left / 60), left % 60)
			task.wait(1)
			left -= 1
		end
	end)
	local function move(dir: string, amount: number)
		if amount <= 0 then
			UI.toast(TL.Bank.Amount)
			return
		end
		local res = Remote.call("bank_move", { dir = dir, amount = amount })
		if res.ok then
			UI.sound("LevelUp", 0.3)
			PhoneOS.bank()
		elseif res.msg then
			UI.toast("⛔ " .. res.msg, C.bad)
		end
	end
	local order = 10
	for _, amount in ipairs({ 10, 50 }) do
		order += 1
		UI.button(m.content, string.format(TL.Bank.Save, amount), function()
			move("save", amount)
		end, { LayoutOrder = order, BackgroundColor3 = Color3.fromRGB(40, 160, 120), TextColor3 = WHITE })
	end
	UI.button(m.content, string.format(TL.Bank.Save, r.checking), function()
		move("save", r.checking)
	end, { LayoutOrder = 13, BackgroundColor3 = Color3.fromRGB(40, 160, 120), TextColor3 = WHITE })
	for i, amount in ipairs({ 10, 50 }) do
		UI.button(m.content, string.format(TL.Bank.Take, amount), function()
			move("take", amount)
		end, { LayoutOrder = 20 + i })
	end
	UI.button(m.content, string.format(TL.Bank.Take, r.savings), function()
		move("take", r.savings)
	end, { LayoutOrder = 23 })
	local hl
	hl = UI.button(m.content, string.format(TL.Bank.HardLife, r.hardLife and "ON" or "OFF"), function()
		UI.settings.hardLife = not UI.settings.hardLife
		Remote.call("settings", UI.settings)
		hl.Text = string.format(TL.Bank.HardLife, UI.settings.hardLife and "ON" or "OFF")
	end, { LayoutOrder = 30 })
	whiteLabel(m.content, string.format(TL.Bank.HardLifeInfo, r.bill), 31, { TextColor3 = SOFT, TextSize = UI.textSize(13) })
	whiteLabel(m.content, TL.Bank.Note, 32, { TextColor3 = SOFT, TextSize = UI.textSize(13) })
	m.focus()
end

---------------------------------------------------------------------
-- Shifts and payslips
---------------------------------------------------------------------
function PhoneOS.shifts(payslip)
	local r = Remote.call("shift_status")
	if not r.ok then
		return
	end
	local m = UI.modal(TL.Shift.Title, phoneOpts(Color3.fromRGB(255, 120, 60)))
	if payslip then
		local p = payslip
		local card = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(250, 248, 240), Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = m.content }, {
			UI.new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		})
		UI.corner(card, 12)
		UI.label(card, string.format(TL.Shift.Payslip, tostring(p.job), tostring(p.minutes), p.tasks, p.wages, p.bonus, p.total), { TextColor3 = Color3.fromRGB(20, 20, 24), Font = Enum.Font.Code })
	end
	if not r.job then
		whiteLabel(m.content, TL.Shift.NoJob, 2)
		m.focus()
		return
	end
	whiteLabel(m.content, "💼 " .. r.job .. " • " .. tostring(r.place), 3, { Font = Enum.Font.GothamBold })
	local status = whiteLabel(m.content, "", 4)
	local onShiftFor = r.shiftSeconds
	local untilNext = r.untilNext
	local since = r.since
	task.spawn(function()
		while m.alive() do
			if r.onShift then
				status.Text = string.format(TL.Shift.OnShiftFor, math.floor(onShiftFor / 60), onShiftFor % 60)
				onShiftFor += 1
			elseif since <= r.grace then
				status.Text = string.format(TL.Shift.StartedAgo, since, r.grace)
			else
				status.Text = string.format(TL.Shift.NextIn, math.floor(untilNext / 60), untilNext % 60)
			end
			task.wait(1)
			since += 1
			untilNext -= 1
			if untilNext < 0 then
				untilNext += Config.Life.Shift.EverySeconds
				since = 0
			end
		end
	end)
	if r.onShift then
		UI.button(m.content, TL.Shift.ClockOut, function()
			local res = Remote.call("shift_out")
			if res.ok then
				UI.sound("LevelUp", 0.4)
				PhoneOS.shifts(res.payslip)
			elseif res.msg then
				UI.toast("⛔ " .. res.msg, C.bad)
			end
		end, { LayoutOrder = 10, BackgroundColor3 = Color3.fromRGB(230, 80, 70), TextColor3 = WHITE })
	else
		UI.button(m.content, TL.Shift.ClockIn, function()
			local res = Remote.call("shift_in")
			if res.ok then
				UI.toast(res.msg, res.onTime and C.good or C.gold, 5)
				PhoneOS.shifts()
			else
				UI.toast("⛔ " .. tostring(res.msg or ""), C.bad)
				if res.notAtWork then
					PhoneOS.hoppr()
				end
			end
		end, { LayoutOrder = 10, BackgroundColor3 = Color3.fromRGB(70, 200, 110), TextColor3 = WHITE })
	end
	whiteLabel(m.content, string.format(TL.Shift.BonusInfo, r.bonus, r.grace), 20, { TextColor3 = SOFT, TextSize = UI.textSize(13) })
	whiteLabel(m.content, TL.Shift.Tip, 21, { TextColor3 = SOFT, TextSize = UI.textSize(13) })
	m.focus()
end

return PhoneOS

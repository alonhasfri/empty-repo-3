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
-- 1.8.7 phone pass: true on a sideways phone screen (wide and short), where the in-game phone is wide too
-- 1.9: the phone is always tall now (main menu on the right), so it is never "wide"
function PhoneOS.wide(): boolean
	return false
end
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
-- 1.9 phone = main menu: everything that used to be a HUD button is an app now
local P19 = Content.Phone19
local MORE = {
	items = { c1 = Color3.fromRGB(70, 200, 190), c2 = Color3.fromRGB(20, 120, 130) },
	badges = { c1 = Color3.fromRGB(240, 190, 60), c2 = Color3.fromRGB(190, 120, 20) },
	help = { c1 = Color3.fromRGB(60, 64, 80), c2 = Color3.fromRGB(30, 32, 40) },
	gate = { c1 = Color3.fromRGB(250, 200, 60), c2 = Color3.fromRGB(220, 130, 30) },
	coffee = { c1 = Color3.fromRGB(150, 100, 60), c2 = Color3.fromRGB(90, 55, 30) },
	nap = { c1 = Color3.fromRGB(110, 110, 210), c2 = Color3.fromRGB(60, 60, 150) },
	pigeons = { c1 = Color3.fromRGB(160, 160, 170), c2 = Color3.fromRGB(100, 100, 115) },
	events = { c1 = Color3.fromRGB(255, 120, 160), c2 = Color3.fromRGB(200, 60, 110) },
	genius = { c1 = Color3.fromRGB(255, 215, 80), c2 = Color3.fromRGB(200, 140, 30) },
}
for key, a in pairs(MORE) do
	a.key = key
	a.icon = P19.Apps[key].icon
	a.name = P19.Apps[key].name
	EXTRA[key] = a
end
PhoneOS.EXTRA = EXTRA

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
	if #list == 0 then
		return list -- no path yet: no apps
	end
	-- 1.9: the old HUD activity buttons live in the phone now
	if st.path == "Gain" then
		addBefore(EXTRA.gate)
		addBefore(EXTRA.coffee)
		addBefore(EXTRA.nap)
		addBefore(EXTRA.pigeons)
		if st.geniusOpen then
			addBefore(EXTRA.genius) -- 1.9 Genius Crossroads (server sets geniusOpen)
		end
	end
	if st.eventInvite or st.eventsDone then
		addBefore(EXTRA.events) -- 1.9 big life events
	end
	addBefore(EXTRA.badges)
	addBefore(EXTRA.help)
	table.insert(list, 1, EXTRA.items)
	-- the old Gadgets app is the Items app now
	for i = #list, 1, -1 do
		if list[i].key == "gadgets" then
			table.remove(list, i)
		end
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
		elseif app.key == "items" then
			PhoneOS.items()
		elseif app.key == "help" then
			PhoneOS.help()
		elseif app.key == "badges" then
			PhoneOS.stations.badges()
		elseif (app.key == "events" or app.key == "genius") and PhoneOS.stations[app.key] then
			PhoneOS.stations[app.key]()
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
	local cell = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, LayoutOrder = order, Selectable = true, Parent = parent }, {
		-- 1.8.1 fix: icon and name stacked in ONE column, so the name always sits right under its own icon
		-- (before, the name was pinned to the cell bottom and lined up with the next row's icon)
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	-- the icon follows the cell width (up to `size`), so narrow phones never get overlapping icons
	local icon = UI.new("Frame", { Size = UDim2.fromScale(0.78, 1), LayoutOrder = 1, BackgroundColor3 = WHITE, Parent = cell }, { -- square: the aspect constraint makes height = width
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
		UI.new("TextLabel", { BackgroundTransparency = 1, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, labelH), Text = appLabel(app.name), Font = Enum.Font.GothamMedium, TextScaled = true, TextColor3 = WHITE, Parent = cell })
	end
	cell.Activated:Connect(function()
		openApp(app)
	end)
	return cell
end

---------------------------------------------------------------------
-- Home screens
---------------------------------------------------------------------
-- 1.9: a slim clock + brain strip (the phone frame draws the status bar above it)
local function wallpaper(parent, st, tier: string, order: number)
	local h = 64
	local wall = UI.new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, 0, 0, h), LayoutOrder = order, Parent = parent })
	UI.corner(wall, 18)
	if tier == "toy" then
		UI.gradient(wall, Color3.fromRGB(255, 60, 200), Color3.fromRGB(255, 220, 40), 20)
	elseif tier == "cozy" then
		UI.gradient(wall, Color3.fromRGB(240, 170, 110), Color3.fromRGB(150, 110, 200), 60)
	else
		UI.gradient(wall, Color3.fromRGB(30, 50, 90), Color3.fromRGB(70, 110, 160), 90)
	end
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 4), Text = os.date("%H:%M"), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = WHITE, Parent = wall })
	local sub = "🧠 " .. tostring(st.cellsText or "") .. ((st.iq and st.path == "Gain") and ("  •  IQ " .. math.floor(st.iq)) or "")
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 1, -22), Text = sub, Font = Enum.Font.GothamMedium, TextScaled = true, TextColor3 = Color3.fromRGB(255, 245, 255), Parent = wall })
end

-- 1.9 phone = main menu (docs/reference/phone_target.jpg): ONE home for every brain tier:
-- 3 labelled icons per row, and a dock at the bottom with Items, Maps and Settings.
local function home(m, st, tier: string)
	local apps = appsFor(st, tier)
	wallpaper(m.content, st, tier, 1)
	local dockKeys = Config.UI.PhoneDock
	local dockApps, gridApps = {}, {}
	for _, app in ipairs(apps) do
		local slot = table.find(dockKeys, app.key)
		if slot then
			dockApps[slot] = app
		else
			table.insert(gridApps, app)
		end
	end
	local cols = Config.UI.PhoneColumns
	local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / cols - 0.03, 0, 0, 84), CellPadding = UDim2.new(0.03, 0, 0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, app in ipairs(gridApps) do
		appIcon(grid, app, i, 58, 18)
	end
	if #apps == 0 then
		UI.label(m.content, "Pick a path first to unlock your apps.", { TextColor3 = WHITE, LayoutOrder = 3 })
		return
	end
	-- dock: the last row of the phone
	local dock = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 64, 76), BackgroundTransparency = 0.25, Size = UDim2.new(1, 0, 0, 78), LayoutOrder = 9, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(1 / cols - 0.03, 0, 0, 62), CellPadding = UDim2.new(0.03, 0, 0, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 8) }),
	})
	UI.corner(dock, 22)
	for slot = 1, #dockKeys do
		if dockApps[slot] then
			appIcon(dock, dockApps[slot], slot, 56, 0)
		end
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
	local color = tier == "real" and Color3.fromRGB(40, 44, 56) or (tier == "cozy" and Color3.fromRGB(180, 120, 90) or Color3.fromRGB(255, 60, 180))
	local m = UI.modal("", { phone = true, color = color })
	home(m, st, tier)
	m.focus()
end

---------------------------------------------------------------------
-- 1.9 Items: every gadget and secret invention in one place
---------------------------------------------------------------------
local function itemRow(parent, order: number, icon: string, name: string, desc: string, dim: boolean)
	local card = UI.new("Frame", { BackgroundColor3 = UI.T.panel, BackgroundTransparency = dim and 0.5 or 0, Size = UDim2.new(1, 0, 0, 64), LayoutOrder = order, Parent = parent })
	UI.corner(card, 12)
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(48, 48), TextScaled = true, Text = icon, Parent = card })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(62, 6), Size = UDim2.new(1, -150, 0, 22), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, Font = UI.T.font, TextColor3 = UI.T.text, Text = name, Parent = card })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(62, 30), Size = UDim2.new(1, -150, 0, 28), TextScaled = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Font = UI.T.body, TextColor3 = UI.T.muted, Text = desc, Parent = card })
	return card
end

local function plainLabel(parent, text: string, order: number)
	return UI.label(parent, text, { TextColor3 = WHITE, LayoutOrder = order })
end

function PhoneOS.items()
	local st = UI.state or {}
	local m = UI.modal(P19.ItemsTitle, phoneOpts(Color3.fromRGB(40, 44, 56)))
	local order = 1
	local function header(text: string)
		order += 1
		UI.label(m.content, text, { TextColor3 = WHITE, Font = Enum.Font.GothamBold, LayoutOrder = order })
	end
	header(P19.ItemsStuff)
	order += 1
	itemRow(m.content, order, "💰", string.format(P19.ItemsCoins, math.floor(st.coins or 0)), "", false)
	if st.phoneModel then
		order += 1
		itemRow(m.content, order, "📱", string.format(P19.ItemsPhone, tostring(st.phoneModel)), "", false)
	end
	for perk, on in pairs(st.perks or {}) do
		if on then
			order += 1
			itemRow(m.content, order, "⭐", string.format(P19.ItemsPerk, tostring(perk)), "", false)
		end
	end
	if st.path ~= "Gain" then
		order += 1
		plainLabel(m.content, P19.ItemsLose, order)
		m.focus()
		return
	end
	local r = Remote.call("inventions_list")
	header(P19.ItemsGadgets)
	if not (r and r.ok) then
		order += 1
		plainLabel(m.content, P19.ItemsEmpty, order)
		m.focus()
		return
	end
	local owned, locked = {}, {}
	for _, inv in ipairs(r.inventions or {}) do
		table.insert(inv.owned and owned or locked, inv)
	end
	if #owned == 0 then
		order += 1
		plainLabel(m.content, P19.ItemsEmpty, order)
	end
	for _, inv in ipairs(owned) do
		order += 1
		local card = itemRow(m.content, order, inv.icon, inv.name, inv.desc, false)
		UI.button(card, (inv.cooldown or 0) > 0 and ("⏳ " .. inv.cooldown .. "s") or "USE", function()
			if inv.key == "remote" then
				-- the TV remote needs a place: the old Gadgets screen asks for it
				PhoneOS.stations.gadgets()
				return
			end
			local res = Remote.call("invention_use", { key = inv.key })
			if res and res.msg then
				UI.toast(res.msg, res.ok and UI.Colors.good or UI.Colors.bad)
			end
			m.close()
		end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(76, 44), BackgroundColor3 = UI.Colors.good })
	end
	if #locked > 0 then
		header(P19.ItemsLocked)
		for _, inv in ipairs(locked) do
			order += 1
			itemRow(m.content, order, "❔", inv.name, inv.desc, true)
		end
	end
	m.focus()
end

---------------------------------------------------------------------
-- 1.9 Help
---------------------------------------------------------------------
function PhoneOS.help()
	local m = UI.modal(P19.HelpTitle, phoneOpts(Color3.fromRGB(40, 44, 56)))
	for i, line in ipairs(P19.HelpLines) do
		plainLabel(m.content, line, i)
	end
	UI.button(m.content, P19.HelpTutorial, function()
		m.close()
		if PhoneOS.stations.onReplayTutorial then
			PhoneOS.stations.onReplayTutorial()
		end
	end, { LayoutOrder = 20 })
	UI.button(m.content, P19.HelpWhatsNew, function()
		PhoneOS.stations.whatsNew()
	end, { LayoutOrder = 21 })
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

-- 1.7.3: a friend nearby booked Hoppr; join their ride (the fare is shown before you pay)
Remote.on("rideInvite", function(d)
	local m = UI.modal(TL.Ride.Title, { color = Color3.fromRGB(40, 40, 50) })
	UI.label(m.content, string.format(TL.Ride.Invite, tostring(d.from), tostring(d.name), tonumber(d.fare) or 0), { LayoutOrder = 1 })
	UI.button(m.content, string.format(TL.Ride.Join, tonumber(d.fare) or 0), function()
		m.close()
		local r = Remote.call("ride_join", { leaderId = d.leaderId })
		UI.toast((r.ok and "" or "⛔ ") .. tostring(r.msg or ""), r.ok and C.good or C.bad)
		if r.ok then
			riding = nil
		end
	end, { LayoutOrder = 2, BackgroundColor3 = C.good })
	UI.button(m.content, TL.Ride.NoThanks, function()
		m.close()
	end, { LayoutOrder = 3 })
	m.focus()
	-- the invite expires when the car leaves
	task.delay(tonumber(d.seconds) or 5, function()
		if m.alive and m.alive() then
			m.close()
		end
	end)
end)

Remote.on("rideDone", function(d)
	if riding and riding.alive() then
		riding.close()
	end
	riding = nil
	if d.refunded then
		UI.toast(string.format(TL.Ride.Refunded, tonumber(d.fare) or 0), C.good, 6)
		return
	end
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

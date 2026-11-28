-- AdminPanel (1.8.6 redesign, target look: docs/admin_panel_mockup.png).
-- A dark panel: left sidebar with tabs, a search box, player cards with rank badges, a quick-action
-- grid, and a red confirm step for dangerous commands. Only commands your rank allows are shown,
-- and the server still checks the rank on every command (AdminService). Works with touch, mouse
-- and controller, and fits a phone in landscape.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local player = Players.LocalPlayer
local A = Content.AdminUI

local AdminPanel = {}
AdminPanel.onDebug = nil

-- one small dark design kit (8 px spacing, 3 text sizes)
local K = {
	bg = Color3.fromRGB(15, 18, 26),
	side = Color3.fromRGB(19, 23, 33),
	card = Color3.fromRGB(26, 31, 44),
	cardHi = Color3.fromRGB(32, 42, 66),
	line = Color3.fromRGB(48, 56, 78),
	text = Color3.fromRGB(235, 238, 245),
	muted = Color3.fromRGB(140, 150, 170),
	accent = Color3.fromRGB(255, 92, 150),
	blue = Color3.fromRGB(70, 130, 240),
	action = Color3.fromRGB(28, 42, 80),
	danger = Color3.fromRGB(70, 26, 34),
	dangerHi = Color3.fromRGB(240, 70, 100),
	small = 13,
	body = 15,
	title = 22,
}

local TABS = { "Players", "Server", "Game", "Fun", "Testing", "Logs", "Settings" }
-- commands that change or remove things for real players get a red confirm step first
local DANGER = {
	kick = true, ban = true, jail = true, wipedata = true, shutdown = true, shutdownall = true,
	killswitch = true, lock = true, muteall = true, bringall = true, resetme = true, setrank = true,
}
local RANK_BADGE = { [1] = Color3.fromRGB(90, 170, 255), [2] = Color3.fromRGB(80, 220, 120), [3] = Color3.fromRGB(255, 170, 60), [4] = Color3.fromRGB(240, 70, 90) }

local selectedTarget, selectedName = nil, nil
local currentTab = "Players"
local root = nil

local function myRank(): number
	return player:GetAttribute("Rank") or 0
end

-- which commands appear on a tab (always filtered by the viewer's rank)
local function commandsFor(tab: string)
	local list = {}
	for name, def in pairs(Config.Commands) do
		local on
		if tab == "Testing" then
			on = def.min == 1 or name == "lifepack"
		elseif tab == "Settings" then
			on = name == "refreshrank" or name == "debug"
		elseif tab == "Server" then
			on = def.cat == "Server" and def.min >= 2
		elseif tab == "*" then
			on = true -- 1.8.7: searching looks through every command you may use, on every tab
		else
			-- 1.8.7 (user: "Set Brain Cells is missing"): player commands always show on the player card too
			on = def.cat == tab
		end
		if on and myRank() >= def.min then
			table.insert(list, { name = name, def = def })
		end
	end
	table.sort(list, function(a, b)
		if (DANGER[a.name] or false) ~= (DANGER[b.name] or false) then
			return not DANGER[a.name]
		end
		if a.def.min ~= b.def.min then
			return a.def.min < b.def.min
		end
		return a.def.label < b.def.label
	end)
	return list
end

local function new(class: string, props, children)
	return UI.new(class, props, children)
end
local function corner(o, r)
	UI.corner(o, r or 10)
end
local function label(parent, text: string, size: number, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = size,
		TextColor3 = K.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, size + 6),
		Parent = parent,
	})
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end
local function button(parent, text: string, color: Color3, onClick, props)
	local b = new("TextButton", {
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = K.body,
		TextColor3 = K.text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = color,
		AutoButtonColor = true,
		Size = UDim2.new(1, 0, 0, math.max(40, UI.minTouch())),
		Parent = parent,
	}, {
		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }),
	})
	corner(b, 8)
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	b.Activated:Connect(onClick)
	return b
end
local function list(parent, padding: number?)
	return new("UIListLayout", { Padding = UDim.new(0, padding or 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = parent })
end
local function scroller(parent, props)
	local s = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = K.line,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = parent,
	})
	for k, v in pairs(props or {}) do
		s[k] = v
	end
	return s
end

function AdminPanel.close()
	if root then
		root:Destroy()
		root = nil
	end
	ContextActionService:UnbindAction("BrainCloseAdmin")
end

function AdminPanel.open()
	if myRank() < 1 then
		UI.toast(A.StaffOnly)
		return
	end
	AdminPanel.close()
	UI.closeModal()
	local phone = UI.isPhone()

	-- 1.9.4 (user: "the admin menu doesn't fit mobile"): its own full-screen layer that only keeps clear of the
	-- notch (the HUD layer keeps a big top margin and a phone UIScale, which squeezed the panel)
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local layer = pg:FindFirstChild("BrainAdminGui")
	if not layer then
		layer = new("ScreenGui", { Name = "BrainAdminGui", IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets, DisplayOrder = 40, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = pg })
	end
	-- 1.9.4 (user: "can't scroll on mobile"): no buttons ABOVE the scrolling lists any more (a button parent can
	-- swallow the touch drag): the dim and the panel are plain frames, and tap-outside-to-close is its own layer
	root = new("Frame", { Name = "AdminPanel", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 40, Parent = layer })
	new("TextButton", { Name = "Outside", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 40, Parent = root })
	-- 1.9.4 (user): no tap-outside-to-close (it closed by accident); the dim only blocks taps to the world
	local panel = new("Frame", {
		Active = true, -- taps on the panel never reach the world or the close layer
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = phone and UDim2.fromScale(0.98, 0.96) or UDim2.fromScale(0.8, 0.8),
		BackgroundColor3 = K.bg,
		ZIndex = 41,
		Parent = root,
	}, {
		new("UISizeConstraint", { MaxSize = Vector2.new(1000, 640) }),
	})
	corner(panel, 14)
	UI.stroke(panel, K.line, 1, 0)

	-- sidebar
	local sideW = phone and 0.12 or 0.2 -- 1.8.9: an icon rail on phones, so the content gets the room
	local side = new("Frame", { Size = UDim2.new(sideW, 0, 1, 0), BackgroundColor3 = K.side, ZIndex = 42, Parent = panel })
	corner(side, 14)
	new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = side })
	local brand = 	label(side, A.Brand .. A.BrandAccent, phone and 16 or 20, { Font = Enum.Font.GothamBlack, RichText = true, Text = A.Brand .. '<font color="#FF5C96">' .. A.BrandAccent .. "</font>", ZIndex = 43 })
	if phone then
		brand.Text = "🧠" -- 1.8.9: the icon rail is too narrow for the name
	end
	local tabList = scroller(side, { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -110), ZIndex = 43 })
	list(tabList, 4)
	local youCard = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = K.card, ZIndex = 43, Parent = side })
	corner(youCard, 10)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), Parent = youCard })
	label(youCard, A.You, K.small, { ZIndex = 44 })
	local badge = label(youCard, " " .. string.upper(Config.RankNames[myRank()] or "?") .. " ", 12, {
		Position = UDim2.fromOffset(0, 20), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0,
		BackgroundColor3 = RANK_BADGE[myRank()] or K.blue, Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), ZIndex = 44,
	})
	corner(badge, 9)
	label(youCard, string.format(A.PlayersHere, #Players:GetPlayers()), 12, { Position = UDim2.fromOffset(0, 42), TextColor3 = K.muted, ZIndex = 44 })
	if phone then
		youCard.Visible = false -- 1.8.9: no room on the phone icon rail (the rank shows on the title bar instead)
	end

	-- main area: title, search, close
	local main = new("Frame", { Position = UDim2.new(sideW, 12, 0, 0), Size = UDim2.new(1 - sideW, -24, 1, 0), BackgroundTransparency = 1, ZIndex = 42, Parent = panel })
	local titleL = label(main, "", K.title, { Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(0.4, 0, 0, 30), ZIndex = 43 })
	local search = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -52, 0, 10), Size = UDim2.new(0.5, -10, 0, 36),
		PlaceholderText = A.Search, Text = "", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = K.small,
		TextColor3 = K.text, PlaceholderColor3 = K.muted, BackgroundColor3 = K.card, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = main,
	}, { new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
	corner(search, 8)
	local closeB = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(phone and 48 or 40, phone and 48 or 40), Text = "X", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = K.dangerHi, BackgroundColor3 = K.danger, ZIndex = 43, Parent = main })
	corner(closeB, 8)
	closeB.Activated:Connect(AdminPanel.close)
	local body = new("Frame", { Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 1, -70), BackgroundTransparency = 1, ZIndex = 42, Parent = main })

	-- a value box for commands that need a number or text (staff only, never shown to players)
	local valueBox
	local function run(name: string, def)
		local res = Remote.call("admin", { cmd = name, target = def.target and selectedTarget or nil, arg = valueBox and valueBox.Text or "" })
		UI.toast((res.ok and "✅ " or "⛔ ") .. tostring(res.msg), res.ok and K.card or UI.Colors.bad, 5)
		if name == "debug" and res.ok and AdminPanel.onDebug then
			AdminPanel.onDebug()
		end
	end

	local function confirm(name: string, def)
		local box = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(320, 150), BackgroundColor3 = K.side, ZIndex = 60, Parent = panel })
		corner(box, 12)
		UI.stroke(box, K.dangerHi, 1.5, 0)
		new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 14), Parent = box })
		label(box, string.format(A.ConfirmTitle, "⛔", def.label .. (def.target and selectedName and (" · " .. selectedName) or "")), 17, { Font = Enum.Font.GothamBold, ZIndex = 61 })
		label(box, A.ConfirmBody, K.small, { Position = UDim2.fromOffset(0, 30), TextColor3 = K.muted, ZIndex = 61 })
		local no = button(box, A.Cancel, K.card, function() end, { Position = UDim2.new(0, 0, 1, -56), Size = UDim2.new(0.5, -6, 0, 42), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 61 })
		local yes = button(box, A.Confirm, K.dangerHi, function() end, { Position = UDim2.new(0.5, 6, 1, -56), Size = UDim2.new(0.5, -6, 0, 42), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 61 })
		no.Activated:Connect(function()
			box:Destroy()
		end)
		yes.Activated:Connect(function()
			box:Destroy()
			run(name, def)
		end)
	end

	local tabButtons = {}
	local showTab
	local function clearBody()
		for _, c in ipairs(body:GetChildren()) do
			c:Destroy()
		end
		valueBox = nil
	end
	local function matches(text: string): boolean
		local q = string.lower(search.Text)
		return q == "" or string.find(string.lower(text), q, 1, true) ~= nil
	end

	local function actionGrid(parent, tab: string, header: string?)
		local col = scroller(parent, { Size = UDim2.fromScale(1, 1), ZIndex = 43 })
		list(col, 8)
		new("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = col })
		if header then
			label(col, header, 12, { Font = Enum.Font.GothamBold, TextColor3 = K.muted, LayoutOrder = 0, ZIndex = 44 })
		end
		local cmds = commandsFor(search.Text ~= "" and "*" or tab)
		local needsValue = false
		for _, c in ipairs(cmds) do
			needsValue = needsValue or c.def.arg ~= nil
		end
		if needsValue then
			valueBox = new("TextBox", {
				PlaceholderText = A.Value, Text = "", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = K.small,
				TextColor3 = K.text, PlaceholderColor3 = K.muted, BackgroundColor3 = K.card, TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 1, ZIndex = 44, Parent = col,
			}, { new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
			corner(valueBox, 8)
		end
		local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 43, Parent = col })
		local cols = phone and 2 or 3
		new("UIGridLayout", { CellSize = UDim2.new(1 / cols, -8 * (cols - 1) / cols, 0, math.max(40, UI.minTouch())), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
		local shown = 0
		for i, c in ipairs(cmds) do
			if matches(c.def.label) then
				shown += 1
				local danger = DANGER[c.name] == true
				button(grid, c.def.label .. (c.def.arg and " …" or ""), danger and K.danger or K.action, function()
					if danger then
						confirm(c.name, c.def)
					else
						run(c.name, c.def)
					end
				end, { LayoutOrder = i, TextSize = K.small, TextColor3 = danger and Color3.fromRGB(255, 190, 200) or K.text, ZIndex = 44 })
			end
		end
		if shown == 0 then
			label(col, A.Empty, K.small, { TextColor3 = K.muted, LayoutOrder = 3, ZIndex = 44 })
		end
		return col
	end

	showTab = function(tab: string)
		currentTab = tab
		titleL.Text = (string.gsub(A.Tabs[tab] or tab, "^%S+%s", "")) .. (phone and ("  ·  " .. (Config.RankNames[myRank()] or "")) or "")
		for t, b in pairs(tabButtons) do
			b.BackgroundColor3 = t == tab and K.cardHi or K.side
			b.TextColor3 = t == tab and K.text or K.muted
		end
		clearBody()
		if tab == "Players" then
			local left = scroller(body, { Size = UDim2.new(0.42, -6, 1, 0), ZIndex = 43 })
			list(left, 8)
			new("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = left })
			local res = Remote.call("admin_players")
			if res.ok then
				for i, p in ipairs(res.players) do
					if matches(p.display .. " " .. p.name) then
						local sel = selectedTarget == p.userId
						local card = button(left, "", sel and K.cardHi or K.card, function()
							selectedTarget = p.userId
							selectedName = p.display
							showTab("Players")
						end, { Size = UDim2.new(1, 0, 0, 56), LayoutOrder = i, ZIndex = 44 })
						if sel then
							UI.stroke(card, K.blue, 1.5, 0)
						end
						local av = new("Frame", { Position = UDim2.new(0, 0, 0.5, -18), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Color3.fromHSV((p.userId % 97) / 97, 0.45, 0.95), ZIndex = 45, Parent = card })
						corner(av, 8)
						local nameRow = label(card, p.display, K.body, { Position = UDim2.fromOffset(46, 8), Size = UDim2.new(1, -50, 0, 20), Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 45 })
						if p.rank > 0 then
							local rb = label(card, " " .. string.upper(Config.RankNames[p.rank] or "") .. " ", 11, {
								AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 8), Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X,
								BackgroundTransparency = 0, BackgroundColor3 = RANK_BADGE[p.rank] or K.blue, Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), ZIndex = 46,
							})
							corner(rb, 8)
							nameRow.Size = UDim2.new(1, -130, 0, 20)
						end
						local sub = tostring(p.path) .. (p.iq and p.path == "Gain" and (" · IQ " .. p.iq) or (" · " .. tostring(p.cells) .. " cells"))
						label(card, sub, 12, { Position = UDim2.fromOffset(46, 30), Size = UDim2.new(1, -50, 0, 16), TextColor3 = K.muted, ZIndex = 45 })
					end
				end
			end
			local right = new("Frame", { Position = UDim2.new(0.42, 6, 0, 0), Size = UDim2.new(0.58, -6, 1, 0), BackgroundColor3 = K.card, BackgroundTransparency = 0.3, ZIndex = 43, Parent = body })
			corner(right, 12)
			new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = right })
			actionGrid(right, "Players", string.format(A.QuickActions, string.upper(selectedName or A.Nobody)) .. (selectedName and "" or ("  ·  " .. A.PickPlayer)))
		elseif tab == "Logs" then
			local col = actionGrid(body, "Logs")
			local res = Remote.call("admin_logs")
			if res.ok then
				for i, line in ipairs(res.logs) do
					if matches(line) then
						label(col, line, K.small, { TextColor3 = K.muted, LayoutOrder = 10 + i, ZIndex = 44 })
					end
				end
				if #res.logs == 0 then
					label(col, A.NoLogs, K.small, { LayoutOrder = 10, ZIndex = 44 })
				end
			else
				label(col, A.LogsLocked, K.small, { LayoutOrder = 10, ZIndex = 44 })
			end
		else
			local col = actionGrid(body, tab)
			if tab == "Settings" then
				label(col, string.format(A.Version, Config.Version), K.small, { TextColor3 = K.muted, LayoutOrder = 20, ZIndex = 44 })
			end
		end
	end

	for i, tab in ipairs(TABS) do
		local tabText = A.Tabs[tab] or tab
		if phone then
			tabText = string.match(tabText, "^(%S+)") or tabText -- icon only on phones
		end
		tabButtons[tab] = button(tabList, tabText, K.side, function()
			showTab(tab)
		end, { LayoutOrder = i, TextSize = phone and K.small or K.body, Size = UDim2.new(1, 0, 0, phone and math.max(36, UI.minTouch()) or 36), ZIndex = 44 })
		if phone then -- 1.9.4: the icon fills its button, centred (it was padded into a sliver and got cut off)
			local b = tabButtons[tab]
			b.TextXAlignment = Enum.TextXAlignment.Center
			b.TextScaled = true
			local pad = b:FindFirstChildOfClass("UIPadding")
			if pad then
				pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 6), UDim.new(0, 6)
			end
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		showTab(currentTab)
	end)
	ContextActionService:BindAction("BrainCloseAdmin", function(_, state)
		if state == Enum.UserInputState.Begin then
			AdminPanel.close()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
	showTab(currentTab)
end

return AdminPanel

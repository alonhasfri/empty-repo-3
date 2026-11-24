-- Stations: the screens for every activity, popup and menu.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brain = require(ReplicatedStorage.Shared.Brain)
local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local player = Players.LocalPlayer
local C = UI.Colors

local Stations = {}
Stations.onEvent = nil -- tutorial progress (set by ClientMain)
local function event(name: string)
	if Stations.onEvent then
		pcall(Stations.onEvent, name)
	end
end

local function resultToast(r)
	if not r then
		return
	end
	if r.ok == false and r.msg then
		UI.toast("⛔ " .. r.msg, C.bad)
	elseif r.result then
		UI.toast(r.result)
	elseif r.msg then
		UI.toast(r.msg)
	end
end

local function optionButtons(parent, options, onPick)
	local buttons = {}
	for i, text in ipairs(options) do
		buttons[i] = UI.button(parent, text, function()
			onPick(i, buttons)
		end, { LayoutOrder = 10 + i })
	end
	return buttons
end

---------------------------------------------------------------------
-- THE PHONE: a home screen with apps. Apps open inside the phone.
---------------------------------------------------------------------
Stations.route = nil -- set by ClientMain: opens a station with the server check

local function phoneOpts(color: Color3)
	return { phone = true, color = color, onHome = function()
		Stations.phone()
	end }
end
Stations.phoneOpts = phoneOpts

local PHONE_APPS = {
	Lose = {
		{ key = "scroller", icon = "📱", name = "BrainTok", c1 = Color3.fromRGB(30, 30, 40), c2 = Color3.fromRGB(255, 40, 120) },
		{ key = "clickbait", icon = "📰", name = "ClickNews", c1 = Color3.fromRGB(255, 80, 60), c2 = Color3.fromRGB(200, 30, 40) },
		{ key = "steal", icon = "🎮", name = "Steal A", c1 = Color3.fromRGB(255, 200, 40), c2 = Color3.fromRGB(240, 120, 20) },
		{ key = "comments", icon = "💬", name = "Comments", c1 = Color3.fromRGB(80, 180, 255), c2 = Color3.fromRGB(40, 100, 230) },
		{ key = "together", icon = "🎭", name = "Vs Mode", c1 = Color3.fromRGB(255, 140, 70), c2 = Color3.fromRGB(230, 70, 40) },
		{ key = "map", icon = "🗺", name = "Maps", c1 = Color3.fromRGB(70, 210, 120), c2 = Color3.fromRGB(30, 150, 90) },
		{ key = "shop", icon = "🛒", name = "Store", c1 = Color3.fromRGB(255, 90, 200), c2 = Color3.fromRGB(180, 40, 160) },
		{ key = "settings", icon = "⚙️", name = "Settings", c1 = Color3.fromRGB(120, 120, 130), c2 = Color3.fromRGB(70, 70, 80) },
	},
	Gain = {
		{ key = "theater", icon = "🎬", name = "Jack B", c1 = Color3.fromRGB(230, 60, 60), c2 = Color3.fromRGB(150, 20, 30) },
		{ key = "library", icon = "📚", name = "eBooks", c1 = Color3.fromRGB(170, 120, 70), c2 = Color3.fromRGB(110, 70, 40) },
		{ key = "jobs", icon = "💼", name = "Jobs", c1 = Color3.fromRGB(70, 180, 100), c2 = Color3.fromRGB(30, 120, 60) },
		{ key = "work", icon = "🛠", name = "Work", c1 = Color3.fromRGB(110, 130, 160), c2 = Color3.fromRGB(60, 80, 110) },
		{ key = "lab", icon = "🔬", name = "Projects", c1 = Color3.fromRGB(60, 200, 220), c2 = Color3.fromRGB(20, 120, 160) },
		{ key = "space", icon = "🚀", name = "Space", c1 = Color3.fromRGB(40, 40, 110), c2 = Color3.fromRGB(10, 10, 40) },
		{ key = "gadgets", icon = "🎒", name = "Gadgets", c1 = Color3.fromRGB(60, 190, 190), c2 = Color3.fromRGB(20, 120, 130) },
		{ key = "together", icon = "🎭", name = "Vs Mode", c1 = Color3.fromRGB(255, 140, 70), c2 = Color3.fromRGB(230, 70, 40) },
		{ key = "map", icon = "🗺", name = "Maps", c1 = Color3.fromRGB(70, 210, 120), c2 = Color3.fromRGB(30, 150, 90) },
		{ key = "shop", icon = "🏛", name = "Store", c1 = Color3.fromRGB(255, 90, 200), c2 = Color3.fromRGB(180, 40, 160) },
		{ key = "settings", icon = "⚙️", name = "Settings", c1 = Color3.fromRGB(120, 120, 130), c2 = Color3.fromRGB(70, 70, 80) },
	},
}

Stations.PHONE_APPS = PHONE_APPS -- 1.7: PhoneOS builds the brain-tiered phones from this list

function Stations.phone()
	event("phone")
	local st = UI.state or {}
	local apps = PHONE_APPS[st.path or ""] or {}
	local m = UI.modal("BrainPhone", { phone = true, color = Color3.fromRGB(110, 60, 255) })
	-- wallpaper + clock
	local wall = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, 0, 0, 110), LayoutOrder = 1, Parent = m.content })
	UI.corner(wall, 18)
	UI.gradient(wall, Color3.fromRGB(120, 70, 255), Color3.fromRGB(255, 90, 170), 35)
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromOffset(0, 10), Text = os.date("%H:%M"), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Parent = wall })
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 74), Text = "🧠 " .. tostring(st.cellsText or "") .. " brain cells", Font = Enum.Font.GothamMedium, TextScaled = true, TextColor3 = Color3.fromRGB(255, 240, 255), Parent = wall })
	local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.31, 0, 0, 86), CellPadding = UDim2.new(0.035, 0, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, app in ipairs(apps) do
		local cell = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, LayoutOrder = i, Selectable = true, Parent = grid })
		local icon = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(58, 58), BackgroundColor3 = Color3.new(1, 1, 1), Parent = cell })
		UI.corner(icon, 16)
		UI.gradient(icon, app.c1, app.c2, 45)
		UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = app.icon, TextScaled = true, Parent = icon }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, 0, 0, 18), Text = app.name, Font = Enum.Font.GothamMedium, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Parent = cell })
		cell.Activated:Connect(function()
			UI.sound("CartoonBoing", 0.2)
			if app.key == "settings" then
				Stations.settings()
			elseif Stations.route then
				Stations.route(app.key)
			end
		end)
	end
	if #apps == 0 then
		UI.label(m.content, "Pick a path first (bottom of the screen) to unlock your apps.", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 3 })
	end
	m.focus()
end

---------------------------------------------------------------------
-- LOSE APP: ClickNews (clickbait feed)
---------------------------------------------------------------------
local THUMBS = { "😱", "🤯", "🚨", "👀", "🔥", "💀", "🍌", "🧠" }

function Stations.clickbait()
	local r = Remote.call("clickbait_get")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("📰 ClickNews", phoneOpts(Color3.fromRGB(230, 50, 50)))
	UI.label(m.content, "<b>Trending now</b>  •  tap to read", { TextColor3 = Color3.fromRGB(220, 220, 230), TextSize = UI.textSize(13), LayoutOrder = 1 })
	for i, card in ipairs(r.cards) do
		local b = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(32, 32, 40), Size = UDim2.new(1, 0, 0, 86), LayoutOrder = 10 + i, Selectable = true, Parent = m.content })
		UI.corner(b, 12)
		local thumb = UI.new("TextLabel", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(70, 70), BackgroundColor3 = Color3.fromHSV(math.random(), 0.6, 0.8), Text = THUMBS[math.random(1, #THUMBS)], TextScaled = true, Parent = b }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
		UI.corner(thumb, 10)
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(86, 6), Size = UDim2.new(1, -94, 0, 54), Text = card.text, TextWrapped = true, TextScaled = true, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Parent = b }, { UI.new("UITextSizeConstraint", { MaxTextSize = 17 }) })
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 86, 1, -24), Size = UDim2.new(1, -94, 0, 16), Text = "BrainNews • " .. math.random(2, 59) .. "m ago • 👁 " .. math.random(10, 999) .. "K", TextScaled = true, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(160, 160, 175), Parent = b })
		b.Activated:Connect(function()
			local a = Remote.call("clickbait_open", { id = card.id })
			if not a.ok then
				return
			end
			event("clickbait")
			m.clear()
			local hero = UI.new("TextLabel", { BackgroundColor3 = Color3.fromHSV(math.random(), 0.6, 0.7), Size = UDim2.new(1, 0, 0, 120), Text = THUMBS[math.random(1, #THUMBS)], TextScaled = true, LayoutOrder = 1, Parent = m.content }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20) }) })
			UI.corner(hero, 12)
			UI.label(m.content, a.text, { Font = Enum.Font.GothamBlack, TextSize = UI.textSize(20), TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 2 })
			UI.label(m.content, a.article, { TextColor3 = Color3.fromRGB(220, 220, 230), LayoutOrder = 3 })
			local timer = UI.label(m.content, "⏱ 0s", { TextColor3 = UI.Colors.gold, LayoutOrder = 4 })
			local opened = os.clock()
			task.spawn(function()
				while m.alive() do
					timer.Text = "⏱ reading for " .. math.floor(os.clock() - opened) .. "s  (10s = smarter!)"
					task.wait(0.25)
				end
			end)
			UI.button(m.content, "⬅ Back", function()
				local res = Remote.call("clickbait_close")
				resultToast(res)
				Stations.phone()
			end, { LayoutOrder = 5, BackgroundColor3 = Color3.fromRGB(230, 50, 50) })
			m.focus()
		end)
	end
	UI.button(m.content, "🙈 Ignore all headlines", function()
		resultToast(Remote.call("clickbait_ignore"))
		Stations.phone()
	end, { LayoutOrder = 99, BackgroundColor3 = Color3.fromRGB(50, 50, 60) })
	m.focus()
end

---------------------------------------------------------------------
-- LOSE APP: Steal A (copycat game store)
---------------------------------------------------------------------
local function copycatGame(word: string)
	local m = UI.modal("🎮 Steal A " .. tostring(word), { phone = true, color = Color3.fromRGB(255, 180, 30), noClose = true })
	UI.label(m.content, "A totally original game. Tap to steal! 10 seconds!", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 1 })
	local count = 0
	local counter = UI.label(m.content, "Stolen: 0", { Font = Enum.Font.FredokaOne, TextSize = UI.textSize(28), TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2 })
	UI.button(m.content, "💰 STEAL!", function()
		count += 1
		counter.Text = "Stolen: " .. count .. " " .. string.rep("💰", math.min(count, 8))
	end, { Size = UDim2.new(1, 0, 0, 110), TextSize = 32, BackgroundColor3 = Color3.fromRGB(255, 170, 0), LayoutOrder = 3 })
	m.focus()
	task.delay(10, function()
		UI.toast("You stole " .. count .. " " .. tostring(word) .. "s. The game was terrible. 10/10.")
		Stations.phone()
	end)
end

function Stations.steal()
	local r = Remote.call("steal_get")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("🎮 Steal A Games", phoneOpts(Color3.fromRGB(240, 160, 20)))
	UI.label(m.content, "<b>Top charts</b>  •  the dumbest pick loses the most brain cells", { TextColor3 = Color3.fromRGB(220, 220, 230), TextSize = UI.textSize(13), LayoutOrder = 1 })
	for i, opt in ipairs(r.options) do
		local b = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(32, 32, 40), Size = UDim2.new(1, 0, 0, 92), LayoutOrder = 10 + i, Selectable = true, Parent = m.content })
		UI.corner(b, 12)
		local cover = UI.new("TextLabel", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(76, 76), BackgroundColor3 = Color3.fromHSV((i * 0.27) % 1, 0.7, 0.9), Text = ({ "🦹", "🔧", "🛠" })[((i - 1) % 3) + 1], TextScaled = true, Parent = b }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
		UI.corner(cover, 14)
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(92, 8), Size = UDim2.new(1, -100, 0, 44), Text = opt.text, TextWrapped = true, TextScaled = true, Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Parent = b }, { UI.new("UITextSizeConstraint", { MaxTextSize = 20 }) })
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 92, 1, -34), Size = UDim2.new(0.5, 0, 0, 16), Text = "⭐ " .. string.format("%.1f", 3 + math.random() * 2) .. "  •  " .. math.random(1, 99) .. "M plays", TextScaled = true, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(170, 170, 185), Parent = b })
		local play = UI.new("TextLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -10), Size = UDim2.fromOffset(70, 28), BackgroundColor3 = Color3.fromRGB(60, 200, 110), Text = "PLAY", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Parent = b }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }) })
		UI.corner(play, 14)
		b.Activated:Connect(function()
			local res = Remote.call("steal_choose", { id = opt.id })
			event("steal")
			resultToast(res)
			if res and res.kind == "steal" then
				copycatGame(res.word)
			else
				Stations.phone()
			end
		end)
	end
	m.focus()
end

---------------------------------------------------------------------
-- LOSE APP: Comments (a social media post)
---------------------------------------------------------------------
function Stations.comments()
	local r = Remote.call("comments_get")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("💬 Comments", phoneOpts(Color3.fromRGB(60, 140, 240)))
	-- the post
	local post = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(32, 32, 40), Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = m.content }, {
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UI.corner(post, 12)
	local head = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 1, Parent = post })
	local av = UI.new("TextLabel", { Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Color3.fromHSV(math.random(), 0.5, 0.85), Text = string.sub(r.post.author, 1, 1), Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Parent = head })
	UI.corner(av, 18)
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -44, 0, 20), Text = "@" .. r.post.author .. " ✔", Font = Enum.Font.GothamBold, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), Parent = head })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(44, 20), Size = UDim2.new(1, -44, 0, 14), Text = math.random(1, 23) .. "h ago", Font = Enum.Font.Gotham, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(150, 150, 165), Parent = head })
	UI.label(post, r.post.text, { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 2 })
	UI.label(post, "❤️ " .. math.random(1, 99) .. "K    💬 " .. math.random(100, 999) .. "    ↪️ Share", { TextColor3 = Color3.fromRGB(170, 170, 185), TextSize = UI.textSize(13), LayoutOrder = 3 })
	-- your comment (chat bubble)
	local chosen = {}
	local bubble = UI.new("TextLabel", { BackgroundColor3 = Color3.fromRGB(40, 110, 230), Size = UDim2.new(1, 0, 0, 44), AutomaticSize = Enum.AutomaticSize.Y, Text = "Write a comment…", TextWrapped = true, Font = Enum.Font.GothamMedium, TextSize = UI.textSize(16), TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = m.content }, {
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})
	UI.corner(bubble, 16)
	local function refresh()
		local words = {}
		for _, w in ipairs(chosen) do
			table.insert(words, w.text)
		end
		bubble.Text = #words > 0 and table.concat(words, " ") or "Write a comment…"
	end
	UI.label(m.content, "Tap words to build your comment (max 5):", { TextColor3 = Color3.fromRGB(170, 170, 185), TextSize = UI.textSize(13), LayoutOrder = 3 })
	local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.48, 0, 0, 38), CellPadding = UDim2.fromOffset(6, 6) }),
	})
	for _, w in ipairs(r.words) do
		local chip = UI.new("TextButton", { Text = w.text, Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(55, 55, 70), Parent = grid }, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) })
		UI.corner(chip, 19)
		chip.Activated:Connect(function()
			if #chosen < 5 then
				table.insert(chosen, w)
				refresh()
			end
		end)
	end
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 5, Parent = m.content }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
	})
	UI.button(row, "🗑", function()
		chosen = {}
		refresh()
	end, { Size = UDim2.new(0.25, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(60, 60, 70) })
	UI.button(row, "📨 POST", function()
		local ids = {}
		for _, w in ipairs(chosen) do
			table.insert(ids, w.id)
		end
		local res = Remote.call("comments_post", { ids = ids })
		if res.ok then
			event("comments")
			UI.toast("You posted: \"" .. res.comment .. "\"" .. (res.viral and "  📈 IT'S GOING VIRAL" or ""))
			Stations.phone()
		else
			resultToast(res)
		end
	end, { Size = UDim2.new(0.72, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(40, 110, 230) })
	m.focus()
end

---------------------------------------------------------------------
-- LOSE: Short video scroller (animated "videos" in a phone)
---------------------------------------------------------------------
local VIDEOS = require(ReplicatedStorage.Shared.Content).Videos

local function emoji(parent, text: string, x: number, y: number, size: number)
	return UI.new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(size, size),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		TextScaled = true,
		Text = text,
		ZIndex = 30,
		Parent = parent,
	})
end

local function tween(obj, seconds: number, props, style)
	local t = TweenService:Create(obj, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad), props)
	t:Play()
	return t
end

-- Each scene animates inside `canvas` until alive() is false.
local SCENES = {}
SCENES.cat = function(canvas, alive)
	emoji(canvas, "🟫", 0.4, 0.62, 0.7)
	local cat = emoji(canvas, "🐱", 0.3, 0.45, 0.3)
	while alive() do
		cat.Position, cat.Rotation = UDim2.fromScale(0.3, 0.45), 0
		task.wait(0.8)
		tween(cat, 1, { Position = UDim2.fromScale(0.85, 0.45) })
		task.wait(1)
		tween(cat, 0.6, { Position = UDim2.fromScale(0.95, 0.9), Rotation = 200 }, Enum.EasingStyle.Quad)
		task.wait(0.7)
		local cry = emoji(canvas, "😭", 0.75, 0.75, 0.2)
		task.wait(1)
		cry:Destroy()
	end
end
SCENES.noodles = function(canvas, alive)
	local face = emoji(canvas, "😮", 0.5, 0.35, 0.4)
	local bowl = emoji(canvas, "🍜", 0.5, 0.75, 0.35)
	while alive() do
		bowl.Size = UDim2.fromScale(0.35, 0.35)
		bowl.Position = UDim2.fromScale(0.5, 0.75)
		face.Text = "😮"
		task.wait(0.6)
		tween(bowl, 0.8, { Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.05, 0.05) })
		task.wait(0.8)
		face.Text = "😋"
		task.wait(1.2)
	end
end
SCENES.dance = function(canvas, alive)
	local guy = emoji(canvas, "🕺", 0.5, 0.55, 0.5)
	local i = 0
	while alive() do
		i += 1
		tween(guy, 0.25, { Rotation = (i % 2 == 0) and 15 or -15, Position = UDim2.fromScale((i % 2 == 0) and 0.42 or 0.58, 0.55) }, Enum.EasingStyle.Back)
		local note = emoji(canvas, (i % 2 == 0) and "🎵" or "🎶", math.random(15, 85) / 100, 0.9, 0.12)
		tween(note, 1.5, { Position = UDim2.fromScale(note.Position.X.Scale, 0.05), TextTransparency = 1 })
		task.delay(1.5, function()
			note:Destroy()
		end)
		task.wait(0.3)
	end
end
SCENES.wall = function(canvas, alive)
	emoji(canvas, "🧱", 0.85, 0.55, 0.35)
	local man = emoji(canvas, "🏃", 0.15, 0.58, 0.3)
	while alive() do
		man.Position, man.Rotation = UDim2.fromScale(0.15, 0.58), 0
		tween(man, 0.8, { Position = UDim2.fromScale(0.65, 0.58) })
		task.wait(0.8)
		local bonk = emoji(canvas, "💥 bonk", 0.7, 0.35, 0.35)
		tween(man, 0.5, { Position = UDim2.fromScale(0.35, 0.7), Rotation = -90 }, Enum.EasingStyle.Bounce)
		task.wait(1.4)
		bonk:Destroy()
	end
end
SCENES.duck = function(canvas, alive)
	local duck = emoji(canvas, "🦆", 0.5, 0.6, 0.45)
	local hat = emoji(canvas, "🎩", 0.5, 0.36, 0.25)
	local clock = emoji(canvas, "🕐", 0.85, 0.12, 0.15)
	local clocks = { "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙" }
	local i = 0
	while alive() do
		i += 1
		local y = (i % 2 == 0) and 0.58 or 0.62
		tween(duck, 0.5, { Position = UDim2.fromScale(0.5, y) }, Enum.EasingStyle.Sine)
		tween(hat, 0.5, { Position = UDim2.fromScale(0.5, y - 0.24) }, Enum.EasingStyle.Sine)
		clock.Text = clocks[(i % #clocks) + 1]
		task.wait(0.5)
	end
end
SCENES.waitforit = function(canvas, alive)
	local big = emoji(canvas, "3", 0.5, 0.5, 0.5)
	while alive() do
		for _, n in ipairs({ "3", "2", "1" }) do
			big.Text = n
			big.Size = UDim2.fromScale(0.7, 0.7)
			tween(big, 0.8, { Size = UDim2.fromScale(0.4, 0.4) })
			task.wait(0.9)
		end
		big.Text = "…"
		task.wait(1.2)
		big.Text = "🗿"
		task.wait(1.2)
	end
end
SCENES.rocket = function(canvas, alive)
	local rocket = emoji(canvas, "🚀", 0.5, 0.7, 0.35)
	while alive() do
		rocket.Rotation = -45
		rocket.Position = UDim2.fromScale(0.5, 0.7)
		for _ = 1, 8 do
			rocket.Position = UDim2.fromScale(0.5 + math.random(-10, 10) / 400, 0.7)
			task.wait(0.06)
		end
		tween(rocket, 0.4, { Position = UDim2.fromScale(0.5, 0.55) })
		task.wait(0.4)
		tween(rocket, 0.7, { Position = UDim2.fromScale(0.75, 0.85), Rotation = 120 }, Enum.EasingStyle.Bounce)
		task.wait(0.7)
		local boom = emoji(canvas, "💥", 0.75, 0.8, 0.4)
		task.wait(1)
		boom:Destroy()
	end
end

function Stations.scroller()
	local m = UI.modal("📱 BrainTok", phoneOpts(Color3.fromRGB(255, 40, 120)))
	local phone = UI.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 10, 14),
		Size = UDim2.new(1, 0, 0, 380),
		ClipsDescendants = true,
		LayoutOrder = 1,
		Parent = m.content,
	})
	UI.corner(phone, 16)
	-- fill the phone screen, whatever the device
	task.defer(function()
		local h = m.content.AbsoluteSize.Y / math.max(0.1, UI.D)
		phone.Size = UDim2.new(1, 0, 0, math.max(220, h - 92))
	end)
	local swipes = 0
	local current = nil
	local token = 0
	local stats = UI.label(m.content, "", { TextColor3 = Color3.fromRGB(180, 180, 195), TextXAlignment = Enum.TextXAlignment.Center, TextSize = UI.textSize(12), LayoutOrder = 3 })

	local function showVideo()
		token += 1
		local my = token
		local v = VIDEOS[math.random(1, #VIDEOS)]
		local old = current
		local canvas = UI.new("Frame", {
			BackgroundColor3 = Color3.fromHSV(math.random(), 0.55, 0.55),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 1),
			ClipsDescendants = true,
			Parent = phone,
		})
		UI.gradient(canvas, Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 140), 90)
		current = canvas
		-- overlay: title, creator, likes, progress bar
		UI.new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 1, -86),
			Size = UDim2.new(0.75, 0, 0, 22),
			Text = v.creator,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0.5,
			ZIndex = 32,
			Parent = canvas,
		})
		UI.new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 1, -62),
			Size = UDim2.new(0.75, 0, 0, 40),
			Text = v.title,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0.5,
			ZIndex = 32,
			Parent = canvas,
		})
		for i, ic in ipairs({ { "❤️", v.likes }, { "💬", tostring(math.random(2, 90)) .. "K" }, { "↪️", "Share" } }) do
			UI.new("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0.35, (i - 1) * 56),
				Size = UDim2.fromOffset(56, 50),
				Text = ic[1] .. "\n" .. ic[2],
				TextScaled = true,
				Font = Enum.Font.GothamBold,
				TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0.5,
				ZIndex = 32,
				Parent = canvas,
			})
		end
		local prog = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(0, 0, 0, 4), ZIndex = 33, Parent = canvas })
		tween(prog, 6, { Size = UDim2.new(1, 0, 0, 4) }, Enum.EasingStyle.Linear)
		-- slide in, push the old one up
		tween(canvas, 0.3, { Position = UDim2.fromScale(0, 0) })
		if old then
			tween(old, 0.3, { Position = UDim2.fromScale(0, -1) })
			task.delay(0.35, function()
				old:Destroy()
			end)
		end
		local scene = SCENES[v.key]
		if scene then
			task.spawn(scene, canvas, function()
				return my == token and canvas.Parent ~= nil and m.alive()
			end)
		end
	end

	local function swipe()
		local r = Remote.call("scroll_swipe")
		if r.ok then
			event("scroller")
			swipes += 1
			stats.Text = "Swipes: " .. swipes .. "  •  attention span: " .. math.max(0, 100 - swipes * 3) .. "%"
			showVideo()
		elseif r.msg then
			resultToast(r)
		end
	end

	UI.button(m.content, "⬆ SWIPE", swipe, { Size = UDim2.new(1, 0, 0, 52), TextSize = 22, BackgroundColor3 = Color3.fromRGB(255, 40, 120), LayoutOrder = 2 })
	-- swipe gesture on phones
	local conn = UserInputService.TouchSwipe:Connect(function(dir)
		if dir == Enum.SwipeDirection.Up and m.alive() then
			swipe()
		end
	end)
	phone.Destroying:Connect(function()
		conn:Disconnect()
	end)
	showVideo()
	m.focus()
end

---------------------------------------------------------------------
-- SHOP (both paths)
---------------------------------------------------------------------
local function confirm(title: string, text: string, yesText: string, onYes)
	local m = UI.modal(title, { color = C.gold })
	UI.label(m.content, text, { LayoutOrder = 1 })
	UI.button(m.content, yesText, function()
		m.close()
		onYes()
	end, { LayoutOrder = 2, BackgroundColor3 = C.good })
	UI.button(m.content, "Cancel", function()
		m.close()
	end, { LayoutOrder = 3 })
	m.focus()
end

function Stations.shop()
	event("shop")
	local r = Remote.call("shop_list")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("🛒 Passes", { color = C.good })
	UI.label(m.content, r.reminder, { TextColor3 = C.gold, LayoutOrder = 1 })
	if not r.enabled then
		UI.label(m.content, "Purchases are paused right now.", { TextColor3 = C.bad, LayoutOrder = 2 })
	end
	for i, pass in ipairs(r.passes) do
		local text = pass.name .. "  •  R$ " .. pass.price .. "\n" .. pass.desc
		if pass.cellsLost > 0 then
			text ..= "\n🧠📉 Costs " .. Brain.formatNumber(pass.cellsLost) .. " brain cells"
		end
		UI.label(m.content, text, { LayoutOrder = 10 + i * 2 })
		UI.button(m.content, pass.owned and "✅ Owned" or ("Buy for R$ " .. pass.price), function()
			if pass.owned or not r.enabled then
				return
			end
			if pass.id == 0 then
				UI.toast("This pass isn't set up yet (the owner needs to add its ID).", C.bad)
				return
			end
			local warning = "You'll pay R$ " .. pass.price .. " for: " .. pass.desc
			if pass.cellsLost > 0 then
				warning ..= "\n\nThis pass makes you lose " .. Brain.formatNumber(pass.cellsLost) .. " brain cells. You can finish the game without it."
			end
			confirm("Are you sure?", warning, "Continue to purchase", function()
				MarketplaceService:PromptGamePassPurchase(player, pass.id)
			end)
		end, { LayoutOrder = 11 + i * 2, BackgroundColor3 = pass.owned and C.panel2 or C.good })
	end
	m.focus()
end

---------------------------------------------------------------------
-- GAIN: Library and Jack B Movies
---------------------------------------------------------------------
local function readAndAnswer(title: string, getAction: string, answerAction: string, color: Color3, inPhone: boolean?)
	local r = Remote.call(getAction)
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal(title, inPhone and phoneOpts(color) or { color = color })
	UI.label(m.content, r.text, { TextSize = UI.textSize(18), LayoutOrder = 1, TextColor3 = inPhone and Color3.new(1, 1, 1) or UI.T.text })
	local timer = UI.label(m.content, "", { TextColor3 = C.gold, LayoutOrder = 2 })
	UI.label(m.content, r.q, { Font = Enum.Font.GothamBold, LayoutOrder = 3, TextColor3 = inPhone and Color3.new(1, 1, 1) or UI.T.text })
	local opened = os.clock()
	local buttons
	buttons = optionButtons(m.content, r.options, function(i)
		if os.clock() - opened < r.wait then
			UI.toast("Read it first! ⏱")
			return
		end
		local res = Remote.call(answerAction, { choice = i })
		if not res.ok then
			return resultToast(res)
		end
		event((string.gsub(getAction, "_get", "")))
		for bi, b in ipairs(buttons) do
			b.BackgroundColor3 = bi == res.answer and C.good or (bi == i and C.bad or C.panel2)
		end
		UI.toast(res.correct and "✅ Correct! Brain cells up." or "❌ Not quite.", res.correct and C.good or C.bad)
		task.wait(1.2)
		m.close()
	end)
	for _, b in ipairs(buttons) do
		b.AutoButtonColor = false
		b.BackgroundTransparency = 0.5
	end
	task.spawn(function()
		while m.alive() do
			local left = r.wait - (os.clock() - opened)
			if left <= 0 then
				timer.Text = "✅ You can answer now."
				for _, b in ipairs(buttons) do
					b.BackgroundTransparency = 0
					b.AutoButtonColor = true
				end
				break
			end
			timer.Text = "⏱ Read for " .. math.ceil(left) .. " more seconds…"
			task.wait(0.2)
		end
	end)
	m.focus()
end

function Stations.library()
	readAndAnswer("📚 The Library", "library_get", "library_answer", Color3.fromRGB(160, 120, 80))
end

function Stations.theater()
	readAndAnswer("🎬 Jack B", "theater_get", "theater_answer", Color3.fromRGB(220, 60, 60), true)
end

---------------------------------------------------------------------
-- GAIN: Skill Gate
---------------------------------------------------------------------
function Stations.gate()
	local st = Remote.call("gate_status")
	local m = UI.modal("🚧 The Skill Gate", { color = C.gold })
	if not st.gate then
		UI.label(m.content, "You've passed every gate in this update. More come in future updates!", { LayoutOrder = 1 })
		return m.focus()
	end
	UI.label(m.content, st.gate .. ": you need " .. st.iq .. " IQ to try it. Then YOU must answer real questions. All correct to pass.", { LayoutOrder = 1 })
	if not st.atGate then
		UI.label(m.content, "Keep learning (library, Jack B Movies, jobs) until your brain cells hit the gate.", { TextColor3 = C.muted, LayoutOrder = 2 })
		return m.focus()
	end
	if st.cooldown > 0 then
		UI.label(m.content, "⏳ Cool down for " .. st.cooldown .. " seconds first.", { TextColor3 = C.bad, LayoutOrder = 2 })
		return m.focus()
	end
	UI.button(m.content, "▶ Start the Gate", function()
		local r = Remote.call("gate_start")
		if not r.ok then
			return resultToast(r)
		end
		event("gate")
		m.clear()
		local answers = {}
		local deadline = os.clock() + r.seconds
		local timer = UI.label(m.content, "", { TextColor3 = C.gold, Font = Enum.Font.GothamBlack, LayoutOrder = 0 })
		local hintsLabel = UI.label(m.content, "💡 Hints left: " .. r.hints .. " (each costs 1% of your brain cells)", { TextColor3 = C.muted, LayoutOrder = 1 })
		local order = 2
		local submitted = false
		for qi, q in ipairs(r.questions) do
			order += 1
			UI.label(m.content, qi .. ". " .. q.q, { Font = Enum.Font.GothamBold, LayoutOrder = order })
			local buttons = {}
			for oi, opt in ipairs(q.options) do
				order += 1
				buttons[oi] = UI.button(m.content, opt, function()
					answers[qi] = oi
					for bi, b in ipairs(buttons) do
						if b:GetAttribute("Removed") ~= true then
							b.BackgroundColor3 = bi == oi and C.accent or C.panel2
						end
					end
				end, { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 40) })
			end
			order += 1
			UI.button(m.content, "💡 Hint for question " .. qi, function()
				local h = Remote.call("gate_hint", { index = qi })
				if not h.ok then
					return resultToast(h)
				end
				local b = buttons[h.remove]
				if b then
					b:SetAttribute("Removed", true)
					b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					b.Text = "✖ " .. b.Text
				end
				hintsLabel.Text = "💡 Hints left: " .. h.hints
			end, { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(70, 60, 30) })
		end
		local function submit()
			if submitted then
				return
			end
			submitted = true
			local res = Remote.call("gate_submit", { answers = answers })
			m.close()
			if res.passed then
				UI.toast("🎉 GATE PASSED! Your brain can grow again.", C.good, 6)
				UI.sound("LevelUp")
			elseif res.ok then
				UI.toast("❌ " .. res.correct .. "/" .. res.total .. " correct" .. (res.late and " (too slow!)" or "") .. ". Try again after the cooldown.", C.bad, 6)
				UI.sound("SadTrombone")
			end
		end
		order += 1
		UI.button(m.content, "✅ Submit answers", submit, { LayoutOrder = order, BackgroundColor3 = C.good })
		task.spawn(function()
			while m.alive() and not submitted do
				local left = deadline - os.clock()
				if left <= 0 then
					submit()
					break
				end
				timer.Text = "⏱ " .. math.ceil(left) .. "s left"
				task.wait(0.25)
			end
		end)
		m.focus()
	end, { LayoutOrder = 3, BackgroundColor3 = C.good })
	m.focus()
end

---------------------------------------------------------------------
-- GAIN: Jobs, work, town map, gadgets
---------------------------------------------------------------------
local function ideaBar(parent, idea: number, max: number, order: number)
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = order, Parent = parent })
	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = "💡 Idea meter: " .. idea .. "/" .. max .. "  (full = secret invention!)",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = UI.T.body,
		TextScaled = true,
		TextColor3 = UI.T.text,
		Parent = holder,
	})
	local back = UI.new("Frame", { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, Parent = holder })
	UI.corner(back, 6)
	local fill = UI.new("Frame", { Size = UDim2.fromScale(math.clamp(idea / max, 0.02, 1), 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = back })
	UI.corner(fill, 6)
	UI.gradient(fill, Color3.fromRGB(255, 230, 80), Color3.fromRGB(255, 140, 40), 0)
end

function Stations.jobs()
	local r = Remote.call("jobs_list")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("💼 Job Board", { color = C.good })
	if r.workplace then
		UI.label(m.content, "Your workplace: <b>" .. r.workplace .. "</b>", { LayoutOrder = 1 })
		UI.button(m.content, Content.Bus.ToWork, function()
			local t = Remote.call("taxi", { key = "work" })
			resultToast(t)
			if t.ok then
				m.close()
			end
		end, { LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(240, 190, 30), TextColor3 = Color3.new(0, 0, 0) })
		ideaBar(m.content, r.idea, r.ideaMax, 3)
	end
	local CT = Content.Careers
	if r.career then
		local c = r.career
		local line = string.format(CT.Ladder, c.ladder) .. "\n" .. string.format(CT.Now, c.title, c.xp)
		line ..= c.nextXP and string.format(CT.Next, c.nextXP, c.nextIQ) or CT.Top
		UI.label(m.content, line, { LayoutOrder = 3 })
	end
	UI.label(m.content, CT.Pick, { LayoutOrder = 4 })
	for i, j in ipairs(r.jobs) do
		local status = j.current and CT.Yours or (j.available and "" or string.format(CT.Locked, math.max(0, j.minIQ)))
		UI.button(m.content, string.format(CT.JobButton, j.first or j.name, j.top or j.name, j.coins, j.placeName, status), function()
			if not j.available or j.current then
				return
			end
			local res = Remote.call("job_take", { id = j.id })
			resultToast(res)
			if res.ok then
				event("job")
			end
			m.close()
		end, { LayoutOrder = 10 + i, TextSize = UI.textSize(14), BackgroundColor3 = j.current and C.good or (j.available and C.panel2 or C.panel) })
	end
	m.focus()
end

-- 1.6: report card every few shifts
function Stations.reportCard(d)
	local CT = Content.Careers
	local m = UI.modal(CT.ReportTitle, { color = C.good })
	local rows = { d.title, d.accuracy, d.speed, d.vibes }
	for i, name in ipairs(CT.ReportRows) do
		UI.label(m.content, name .. ":  <b>" .. tostring(rows[i]) .. "</b>", { LayoutOrder = i })
	end
	local prog = d.need and (d.xp .. "/" .. d.need) or CT.Max
	UI.label(m.content, string.format(CT.ReportProgress, prog), { LayoutOrder = 10 })
	local back = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = C.panel, LayoutOrder = 11, Parent = m.content })
	UI.corner(back, 6)
	local fill = UI.new("Frame", { Size = UDim2.fromScale(d.need and math.clamp(d.xp / d.need, 0.02, 1) or 1, 1), BackgroundColor3 = Color3.fromRGB(47, 191, 113), Parent = back })
	UI.corner(fill, 6)
	UI.button(m.content, "OK", function()
		m.close()
	end, { LayoutOrder = 20, BackgroundColor3 = C.good })
	m.focus()
end

function Stations.work()
	local t = Remote.call("job_task")
	if not t.ok then
		resultToast(t)
		if t.notAtWork then
			local m = UI.modal("💼 Not at work", { color = C.gold })
			UI.label(m.content, tostring(t.msg), { LayoutOrder = 1 })
			UI.button(m.content, Content.Bus.ToWork, function()
				resultToast(Remote.call("taxi", { key = "work" }))
				m.close()
			end, { LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(240, 190, 30), TextColor3 = Color3.new(0, 0, 0) })
			m.focus()
		end
		return
	end
	local m = UI.modal(t.title, { color = C.good })
	UI.label(m.content, t.prompt, { Font = UI.T.font, TextSize = UI.textSize(19), LayoutOrder = 1 })
	local buttons
	buttons = optionButtons(m.content, t.options, function(i)
		local res = Remote.call("job_answer", { choice = i })
		if not res.ok then
			return
		end
		event("work")
		for bi, b in ipairs(buttons) do
			b.BackgroundColor3 = bi == res.answer and C.good or (bi == i and C.bad or C.panel2)
		end
		UI.toast(res.correct and "✅ Good work! +💰" or "❌ Oops.", res.correct and C.good or C.bad)
		task.wait(0.8)
		if m.alive() then
			m.clear()
			ideaBar(m.content, res.idea or 0, res.ideaMax or 6, 1)
			UI.button(m.content, "🔁 Next task", function()
				m.close()
				Stations.work()
			end, { LayoutOrder = 2, BackgroundColor3 = C.good })
			UI.button(m.content, "Take a break", function()
				m.close()
			end, { LayoutOrder = 3 })
			m.focus()
		end
	end)
	m.focus()
end

function Stations.map(free: boolean?)
	local r = Remote.call("places")
	if not r.ok then
		return
	end
	local m = UI.modal("🗺 Brainville Map", phoneOpts(Color3.fromRGB(40, 170, 100)))
	-- the drawn town
	local map = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(110, 185, 95), Size = UDim2.new(1, 0, 0, 10), LayoutOrder = 1, ClipsDescendants = true, Parent = m.content }, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
	})
	map.Size = UDim2.new(1, 0, 0, 300)
	UI.corner(map, 14)
	local ext = r.extent or 160
	local function at(x: number, z: number): UDim2
		return UDim2.fromScale(0.5 + x / (2 * ext), 0.5 + z / (2 * ext))
	end
	local function road(x1, z1, x2, z2)
		local horizontal = z1 == z2
		local f = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(70, 70, 78), BorderSizePixel = 0, Parent = map })
		f.Position = at((x1 + x2) / 2, (z1 + z2) / 2)
		if horizontal then
			f.Size = UDim2.new(math.abs(x2 - x1) / (2 * ext), 0, 0, 6)
		else
			f.Size = UDim2.new(0, 6, math.abs(z2 - z1) / (2 * ext), 0)
		end
	end
	local S = 0.55
	road(-410 * S, 0, 410 * S, 0)
	road(0, -410 * S, 0, 410 * S)
	for _, v in ipairs({ -200 * S, 200 * S }) do
		road(v, -400 * S, v, 400 * S)
	end
	local plaza = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = at(0, 0), Size = UDim2.fromScale(146 * S / (2 * ext), 146 * S / (2 * ext)), BackgroundColor3 = Color3.fromRGB(215, 205, 190), Parent = map })
	UI.corner(plaza, 6)
	local myPath = UI.state and UI.state.path
	for _, p in ipairs(r.places) do
		local pin = UI.new("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = at(p.x, p.z),
			Size = UDim2.fromOffset(34, 34),
			Text = string.match(p.name, "^(%S+)") or "📍",
			TextScaled = true,
			BackgroundColor3 = (p.path == "Lose" and Color3.fromRGB(255, 80, 180)) or (p.path == "Gain" and Color3.fromRGB(70, 140, 255)) or Color3.fromRGB(255, 200, 60),
			ZIndex = 25,
			Parent = map,
		}, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }) })
		UI.corner(pin, 17)
		UI.stroke(pin, Color3.new(1, 1, 1), 2, 0)
		pin.Activated:Connect(function()
			local t = Remote.call("taxi", { key = p.key, free = free })
			resultToast(t)
			if t.ok then
				m.close()
			end
		end)
	end
	if r.me then
		local me = UI.new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = at(r.me.x, r.me.z), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Text = "", ZIndex = 26, Parent = map })
		UI.corner(me, 9)
		UI.stroke(me, Color3.fromRGB(255, 60, 60), 4, 0)
	end
	UI.label(m.content, string.format(Content.Bus.MapHint, Config.Bus.WaitSeconds), { TextColor3 = Color3.fromRGB(210, 210, 220), TextSize = UI.textSize(12), LayoutOrder = 2 })
	for i, p in ipairs(r.places) do
		local tag = (p.path and myPath and p.path ~= myPath) and " (other path)" or ""
		UI.button(m.content, p.name .. tag, function()
			local t = Remote.call("taxi", { key = p.key, free = free })
			resultToast(t)
			if t.ok then
				m.close()
			end
		end, { LayoutOrder = 10 + i, TextSize = UI.textSize(14), Size = UDim2.new(1, 0, 0, 38) })
	end
	m.focus()
end

function Stations.gadgets()
	local r = Remote.call("inventions_list")
	if not r.ok then
		return
	end
	local m = UI.modal("🎒 Secret Inventions", { color = Color3.fromRGB(90, 220, 200) })
	ideaBar(m.content, r.idea, r.ideaMax, 1)
	for i, inv in ipairs(r.inventions) do
		local card = UI.new("Frame", { BackgroundColor3 = inv.owned and UI.T.panel or UI.T.bg, BackgroundTransparency = inv.owned and 0 or 0.4, Size = UDim2.new(1, 0, 0, 74), LayoutOrder = 10 + i, Parent = m.content })
		UI.corner(card)
		UI.stroke(card)
		UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(58, 58), TextScaled = true, Text = inv.icon, Parent = card })
		UI.new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(74, 6),
			Size = UDim2.new(1, -190, 0, 24),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.T.font,
			TextColor3 = UI.T.text,
			Text = inv.name,
			Parent = card,
		})
		UI.new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(74, 32),
			Size = UDim2.new(1, -190, 0, 36),
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.T.body,
			TextColor3 = UI.T.muted,
			Text = inv.desc,
			Parent = card,
		})
		if inv.owned then
			UI.button(card, inv.cooldown > 0 and ("⏳ " .. inv.cooldown .. "s") or "USE", function()
				if inv.key == "remote" then
					m.clear()
					UI.label(m.content, "📡 Where to?", { LayoutOrder = 1 })
					for pi, p in ipairs(r.places) do
						UI.button(m.content, p.name, function()
							resultToast(Remote.call("invention_use", { key = "remote", place = p.key }))
							m.close()
						end, { LayoutOrder = 1 + pi })
					end
					m.focus()
					return
				end
				resultToast(Remote.call("invention_use", { key = inv.key }))
				m.close()
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(100, 46), BackgroundColor3 = C.good })
		end
	end
	m.focus()
end

---------------------------------------------------------------------
-- GAIN: Genius habits
---------------------------------------------------------------------
function Stations.coffee()
	local m = UI.modal("☕ Beethoven's Coffee", { color = Color3.fromRGB(150, 100, 60) })
	Remote.call("habit_coffee_start") -- the server times the counting
	UI.label(m.content, "Beethoven counted EXACTLY 60 coffee beans for every cup. Count yours.", { LayoutOrder = 1 })
	local count = 0
	local label = UI.label(m.content, "Beans: 0", { Font = Enum.Font.FredokaOne, TextSize = UI.textSize(30), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2 })
	UI.button(m.content, "🟤 +1 bean", function()
		count += 1
		label.Text = "Beans: " .. count
	end, { Size = UDim2.new(1, 0, 0, 70), TextSize = 26, LayoutOrder = 3 })
	UI.button(m.content, "➖ remove a bean", function()
		count = math.max(0, count - 1)
		label.Text = "Beans: " .. count
	end, { LayoutOrder = 4 })
	UI.button(m.content, "☕ Brew it", function()
		local r = Remote.call("habit_coffee", { count = count })
		event("habit")
		m.close()
		resultToast(r)
	end, { LayoutOrder = 5, BackgroundColor3 = C.good })
	m.focus()
end

function Stations.nap()
	local m = UI.modal("😴 Edison's Nap Chair", { color = Color3.fromRGB(110, 110, 200) })
	UI.label(m.content, "Edison napped holding something that fell when he dozed off, waking him up. Tap WAKE UP the moment the key drops!", { LayoutOrder = 1 })
	local scene = UI.label(m.content, "🪑", { TextSize = 60, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 90), LayoutOrder = 2 })
	local started = false
	UI.button(m.content, "😴 Close your eyes", function(btn)
		if started then
			return
		end
		local r = Remote.call("habit_nap_start")
		if not r.ok then
			return resultToast(r)
		end
		started = true
		btn.Text = "💤 zzz…"
		scene.Text = "😴🔑"
		task.delay(r.delay, function()
			if m.alive() then
				scene.Text = "😴 …🔑💥 CLANG!"
				UI.sound("CavemanBonk")
			end
		end)
	end, { LayoutOrder = 3 })
	UI.button(m.content, "⏰ WAKE UP!", function()
		if not started then
			return
		end
		local r = Remote.call("habit_nap_tap")
		event("habit")
		m.close()
		resultToast(r)
	end, { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = C.gold, TextColor3 = Color3.new(0, 0, 0) })
	m.focus()
end

function Stations.pigeons()
	local r = Remote.call("habit_pigeons")
	event("habit")
	resultToast(r)
end

---------------------------------------------------------------------
-- Reading popups (Lose path)
---------------------------------------------------------------------
local readingFrame = nil

function Stations.reading(d)
	if readingFrame then
		readingFrame:Destroy()
	end
	local st = UI.state or {}
	local golden = st.perks and st.perks.GoldenSkip
	local f = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, d.tos and 0.7 or 0.42),
		BackgroundColor3 = Color3.fromRGB(250, 250, 245),
		ZIndex = 40,
		Parent = UI.gui,
	}, {
		UI.new("UISizeConstraint", { MaxSize = Vector2.new(520, d.tos and 480 or 300) }),
	})
	readingFrame = f
	UI.corner(f, 12)
	UI.stroke(f, Color3.fromRGB(80, 80, 80), 2)
	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 1, -80),
		Text = d.text,
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(30, 30, 30),
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 41,
		Parent = f,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = 22 }) })
	local opened = os.clock()
	local timer = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -10),
		Size = UDim2.fromOffset(120, 30),
		Text = "0s",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(120, 120, 120),
		ZIndex = 41,
		Parent = f,
	})
	local done = false
	local function finish()
		if done then
			return
		end
		done = true
		f:Destroy()
		if readingFrame == f then
			readingFrame = nil
		end
		GuiService.SelectedObject = nil
		resultToast(Remote.call("reading_done", { id = d.id }))
		event("reading")
	end
	-- Skip button gets bigger as you get dumber; at high brain cells it's tiny and runs away.
	local sizes = { [1] = UDim2.fromOffset(60, 26), [2] = UDim2.fromOffset(110, 40), [3] = UDim2.fromOffset(170, 54), [4] = UDim2.fromOffset(240, 70) }
	local skip = UI.button(f, "SKIP", finish, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -10),
		Size = sizes[d.tier] or sizes[2],
		BackgroundColor3 = golden and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(230, 60, 60),
		ZIndex = 42,
	})
	UI.button(f, "I read it", finish, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(100, 30),
		BackgroundColor3 = Color3.fromRGB(180, 180, 180),
		TextColor3 = Color3.fromRGB(40, 40, 40),
		TextSize = 13,
		ZIndex = 42,
	})
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = skip
	end
	task.spawn(function()
		while not done and f.Parent do
			timer.Text = math.floor(os.clock() - opened) .. "s"
			if d.tier == 1 and math.random() < 0.15 then
				-- the skip button runs away
				skip.Position = UDim2.new(math.random(30, 100) / 100, -12, math.random(60, 100) / 100, -10)
			end
			task.wait(0.4)
		end
	end)
end

---------------------------------------------------------------------
-- Path switching, warnings, hiding, death screen
---------------------------------------------------------------------
function Stations.confirmSwitch(d)
	confirm(
		"Switch paths?",
		"You're already on the other path. Switching to " .. d.path .. " restarts your run from the beginning.",
		"Yes, switch to " .. d.path,
		function()
			resultToast(Remote.call("switch_path", { path = d.path }))
		end
	)
end

function Stations.warning(d)
	local m = UI.modal("⚠️ Warning from staff", { color = C.bad })
	UI.label(m.content, d.reason, { LayoutOrder = 1 })
	UI.button(m.content, "OK", function()
		m.close()
	end, { LayoutOrder = 2 })
	m.focus()
end

function Stations.hide(d)
	local f = UI.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(30, 90, 30),
		BackgroundTransparency = 0.25,
		Text = "🌳🌳🌳\nYou ran and hid behind a bush.\nToo embarrassed to do anything for " .. d.seconds .. " seconds.",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		ZIndex = 30,
		Parent = UI.gui,
	}, { UI.new("UITextSizeConstraint", { MaxTextSize = 36 }) })
	task.delay(d.seconds, function()
		f:Destroy()
	end)
end

local function formatTime(seconds: number?): string
	seconds = seconds or 0
	return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

function Stations.deathScreen(d)
	local m = UI.modal("🎉 GUD JOB 🎉", { color = C.gold, noClose = not d.test })
	UI.label(m.content, "U DROPED DED BCUZ U HAV NO BRAIN SELLS", { Font = Enum.Font.FredokaOne, TextSize = UI.textSize(24), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1 })
	if d.seconds then
		UI.label(m.content, "⏱ Time: " .. formatTime(d.seconds) .. "   🏆 Best: " .. formatTime(d.best), { LayoutOrder = 2 })
		UI.label(m.content, "📰 Clickbait clicked: " .. tostring(d.clickbait) .. "   ⏭ Texts skipped: " .. tostring(d.skipped), { LayoutOrder = 3 })
		if d.moments and #d.moments > 0 then
			UI.label(m.content, "😳 Your most embarrassing moments:", { Font = Enum.Font.GothamBold, LayoutOrder = 4 })
			for i, moment in ipairs(d.moments) do
				UI.label(m.content, i .. ". " .. moment, { TextColor3 = C.muted, LayoutOrder = 4 + i })
			end
		end
	end
	UI.label(m.content, "🏅 Certified Smooth Brain", { TextColor3 = C.gold, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 10 })
	if d.test then
		UI.button(m.content, "Close (test)", function()
			m.close()
		end, { LayoutOrder = 11 })
	else
		UI.button(m.content, "🔁 Do It Again (speedrun)", function()
			local r = Remote.call("death_again")
			if r.ok then
				m.close()
			end
		end, { LayoutOrder = 11, BackgroundColor3 = Color3.fromRGB(255, 80, 180) })
		UI.button(m.content, "🧠 Try Gaining a Brain Cell?", function()
			local r = Remote.call("death_comeback")
			if r.ok then
				m.close()
			end
		end, { LayoutOrder = 12, BackgroundColor3 = Color3.fromRGB(60, 120, 255) })
	end
	m.focus()
end

---------------------------------------------------------------------
-- What's new (from Settings): the update list in Content.Updates
---------------------------------------------------------------------
-- 1.7.3: badge checklist (every badge; locked ones greyed out, secret ones show a hint instead)
local BadgeList = require(ReplicatedStorage.Shared.Badges)
local function badgeOrder()
	local keys = {}
	for k in pairs(BadgeList) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		local va, vb = BadgeList[a].version, BadgeList[b].version
		if va ~= vb then
			return tostring(va) < tostring(vb)
		end
		return BadgeList[a].name < BadgeList[b].name
	end)
	return keys
end

function Stations.badgeCount(): (number, number)
	local owned = (UI.state and UI.state.badges) or {}
	local got, total = 0, 0
	for k in pairs(BadgeList) do
		total += 1
		if owned[k] then
			got += 1
		end
	end
	return got, total
end

function Stations.badges()
	local BU = Content.BadgeUI
	local owned = (UI.state and UI.state.badges) or {}
	local m = UI.modal(BU.Title, { color = Color3.fromRGB(200, 160, 40) })
	for i, k in ipairs(badgeOrder()) do
		local b = BadgeList[k]
		local has = owned[k] == true
		local text
		if has then
			text = BU.Got .. " <b>" .. b.name .. "</b>\n" .. b.desc
		elseif b.secret then
			text = BU.Locked .. " <b>" .. BU.Secret .. "</b>\n" .. (BU.Hints[k] or "???")
		else
			text = BU.Locked .. " <b>" .. b.name .. "</b>\n" .. b.desc
		end
		local l = UI.label(m.content, text, { LayoutOrder = i })
		if not has then
			l.TextTransparency = 0.45
		end
	end
	m.focus()
end

function Stations.whatsNew()
	local m = UI.modal("📋 What's new", { color = C.accent })
	for i, u in ipairs(Content.Updates or {}) do
		local head = "Update " .. u.v .. ": " .. u.name
		if u.v == Config.Version then
			head ..= "  ⬅ YOU ARE HERE"
		end
		UI.label(m.content, head, { LayoutOrder = i * 10, Font = Enum.Font.GothamBlack })
		UI.label(m.content, table.concat(u.lines, "\n"), { LayoutOrder = i * 10 + 1, TextColor3 = C.muted })
	end
	UI.button(m.content, "⬅ Back to Settings", function()
		Stations.settings()
	end, { LayoutOrder = 9999 })
	m.focus()
end

---------------------------------------------------------------------
-- Settings menu
---------------------------------------------------------------------
function Stations.settings()
	local s = UI.settings
	local m = UI.modal("⚙️ Settings", { color = C.accent })
	local function save()
		Remote.call("settings", s)
	end
	local function stepper(label: string, key: string, order: number)
		local l = UI.label(m.content, "", { LayoutOrder = order })
		local function refresh()
			l.Text = label .. ": " .. math.floor(s[key] * 100 + 0.5) .. "%"
		end
		refresh()
		local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = order + 1, Parent = m.content }, {
			UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
		})
		UI.button(row, "➖", function()
			s[key] = math.max(0, s[key] - 0.1)
			refresh()
			save()
		end, { Size = UDim2.new(0.48, 0, 1, 0) })
		UI.button(row, "➕", function()
			s[key] = math.min(1, s[key] + 0.1)
			refresh()
			save()
		end, { Size = UDim2.new(0.48, 0, 1, 0) })
	end
	local function toggle(label: string, key: string, order: number)
		local b
		b = UI.button(m.content, "", function()
			s[key] = not s[key]
			b.Text = label .. ": " .. (s[key] and "ON" or "OFF")
			save()
		end, { LayoutOrder = order })
		b.Text = label .. ": " .. (s[key] and "ON" or "OFF")
	end
	-- which update you're on, and what's new
	UI.label(m.content, "🆕 You're on update " .. tostring(Config.Version), { LayoutOrder = -2 })
	UI.button(m.content, "📋 What's new in " .. tostring(Config.Version), function()
		Stations.whatsNew()
	end, { LayoutOrder = -1, BackgroundColor3 = Color3.fromRGB(40, 170, 110) })
	stepper("🎵 Music volume", "music", 1)
	-- 1.7: Effects intensity (shake, glitches, scrambled words, joke ads) and the simple phone
	if typeof(s.fxIntensity) ~= "number" then
		s.fxIntensity = 1
	end
	stepper(Content.Settings17.Effects, "fxIntensity", 8)
	UI.label(m.content, Content.Settings17.EffectsInfo, { TextColor3 = C.muted, LayoutOrder = 10 })
	toggle(Content.Settings17.ClassicHud, "classicHud", 11)
	-- 1.7.2: the "What do I do now?" guide and Low graphics for cheap phones
	toggle(Content.Settings17.Guide, "guide", 12)
	toggle(Content.Settings17.LowGraphics, "lowGraphics", 13)
	toggle(Content.Settings17.SpeedrunTimer, "speedrunTimer", 15)
	toggle(Content.Settings17.AlwaysDay, "alwaysDay", 19) -- 1.8.1
	toggle(Content.Settings17.FewerToasts, "fewerToasts", 20) -- 1.8.1
	-- 1.8: Life Pack (only shown to owners)
	if UI.state and UI.state.perks and UI.state.perks.LifePack then
		UI.button(m.content, Content.LifeStages.StartLife, function()
			m.close()
			Stations.startLife()
		end, { LayoutOrder = 17, BackgroundColor3 = Color3.fromRGB(255, 170, 200) })
		toggle(Content.LifeStages.Pause, "lifePause", 18)
	end
	-- 1.7.3: horror setting (Off / Spooky / Full), saved on the server
	do
		local TH = Content.Horror
		local order = { "off", "spooky", "full" }
		local cur = (s.horror == "off" or s.horror == "full") and s.horror or "spooky"
		local hb
		hb = UI.button(m.content, string.format(TH.Setting, TH.SettingNames[cur]), function()
			local i = table.find(order, cur) or 2
			local nextV = order[i % 3 + 1]
			local r = Remote.call("horror_setting", { value = nextV })
			if r.ok then
				cur = nextV
				s.horror = nextV
				hb.Text = string.format(TH.Setting, TH.SettingNames[cur])
			end
		end, { LayoutOrder = 16 })
	end
	UI.button(m.content, string.format(Content.BadgeUI.Button, Stations.badgeCount()), function()
		Stations.badges()
	end, { LayoutOrder = 0, BackgroundColor3 = Color3.fromRGB(200, 150, 40) })
	UI.label(m.content, Content.Settings17.LowGraphicsInfo, { TextColor3 = C.muted, LayoutOrder = 14 })
	stepper("🔊 Sound effects", "sfx", 3)
	toggle("⚡ Reduce flashing", "reduceFlashing", 5)
	toggle("🔠 Large text", "largeText", 6)
	toggle("⏱ Extra time on Skill Gates", "extraTime", 7)
	-- brain counter position
	local where = s.counterPos or "topleft"
	local posBtn
	local ORDER = { "topleft", "topcenter", "topright", "bottomright" }
	local NAMES = { topleft = "Top-left", topcenter = "Top-center", topright = "Top-right", bottomright = "Bottom-right", custom = "Custom (dragged)" }
	posBtn = UI.button(m.content, "🧠 Counter position: " .. NAMES[where], function()
		local i = table.find(ORDER, s.counterPos or "topleft") or 0
		s.counterPos = ORDER[(i % #ORDER) + 1]
		posBtn.Text = "🧠 Counter position: " .. NAMES[s.counterPos]
		save()
	end, { LayoutOrder = 71 })
	UI.button(m.content, "✋ Drag the counter anywhere", function()
		m.close()
		if Stations.dragCounter then
			Stations.dragCounter(function(x, y)
				s.counterPos = "custom"
				s.counterX, s.counterY = x, y
				save()
			end)
		end
	end, { LayoutOrder = 72 })
	toggle("🔍 Bigger counter", "counterBig", 73)
	UI.button(m.content, "🚪 Switch path (pick a door again)", function()
		m.close()
		if Stations.openDoors then
			Stations.openDoors()
		end
	end, { LayoutOrder = 75, BackgroundColor3 = Color3.fromRGB(150, 70, 200) })
	UI.button(m.content, "📖 Replay the tutorial", function()
		m.close()
		if Stations.onReplayTutorial then
			Stations.onReplayTutorial()
		end
	end, { LayoutOrder = 76, BackgroundColor3 = Color3.fromRGB(60, 120, 230) })
	UI.button(m.content, "🔄 Refresh my staff rank", function()
		local r = Remote.call("admin", { cmd = "refreshrank" })
		resultToast(r)
	end, { LayoutOrder = 80 })
	UI.label(m.content, "Controller: Ⓨ menu, Select button = admin panel, Ⓑ close, Ⓧ use prompts. Keyboard: M menu, P admin panel, E use prompts.", { TextColor3 = C.muted, LayoutOrder = 90 })
	m.focus()
end

---------------------------------------------------------------------
-- SMART VS DUMB (update 1.2): activities, journalist, lawsuits, elections
---------------------------------------------------------------------
function Stations.together()
	local r = Remote.call("social_list")
	if not r.ok then
		return
	end
	local m = UI.modal("🎭 Smart vs Dumb", { color = Color3.fromRGB(255, 120, 60), maxSize = Vector2.new(620, 540) })
	UI.label(m.content, "Team up with other players (or an NPC if nobody's around). Everyone wins their own goal: smart players gain, dumb players lose.", { TextColor3 = UI.T.muted, LayoutOrder = 1 })
	if r.queued then
		UI.label(m.content, "⏳ Waiting in: <b>" .. r.queued .. "</b>", { LayoutOrder = 2 })
		UI.button(m.content, "Leave the queue", function()
			resultToast(Remote.call("social_leave"))
			m.close()
		end, { LayoutOrder = 3 })
	end
	for i, act in ipairs(r.activities) do
		local card = UI.new("Frame", { BackgroundColor3 = UI.T.panel, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 10 + i, Parent = m.content }, {
			UI.new("UIListLayout", { Padding = UDim.new(0, 6) }),
			UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
		})
		UI.corner(card)
		UI.stroke(card)
		UI.label(card, "<b>" .. act.name .. "</b>", { Font = UI.T.title, TextSize = UI.textSize(19) })
		UI.label(card, act.desc, { TextColor3 = UI.T.muted, TextSize = UI.textSize(14) })
		local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Parent = card }, {
			UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
		})
		for _, role in ipairs(act.roles) do
			local text = role.ok and ("Join as " .. role.label .. (role.waiting > 0 and ("  (" .. role.waiting .. " waiting)") or "")) or ("🔒 " .. role.label .. ": " .. tostring(role.why))
			UI.button(row, text, function()
				if not role.ok then
					return
				end
				resultToast(Remote.call("social_join", { act = act.key, role = role.key }))
				m.close()
			end, { Size = UDim2.new(0.49, 0, 1, 0), TextSize = UI.textSize(13), BackgroundColor3 = role.ok and C.good or UI.T.panel2 })
		end
	end
	if r.canJournal then
		UI.button(m.content, "📰 Be a Journalist: write clickbait for dumb players", Stations.journal, { LayoutOrder = 100, BackgroundColor3 = C.accent })
	end
	m.focus()
end

local socialModal = nil
local function socialFrame(d)
	local m = UI.modal(d.title .. "  •  Round " .. tostring(d.round or 1) .. "/" .. tostring(d.rounds or 1), { color = Color3.fromRGB(255, 120, 60), noClose = true })
	socialModal = m
	local chips = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = m.content }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
	})
	UI.chip(chips, "You: " .. tostring(d.role), Color3.fromRGB(80, 160, 255))
	UI.chip(chips, "vs " .. tostring(d.partner), Color3.fromRGB(255, 100, 120))
	for i, line in ipairs(d.transcript or {}) do
		UI.label(m.content, line, { TextColor3 = UI.T.muted, TextSize = UI.textSize(14), LayoutOrder = 2 + i })
	end
	return m
end

function Stations.socialStart(d)
	UI.toast("🎭 " .. tostring(d.title) .. ": you're the " .. tostring(d.role) .. " vs " .. tostring(d.partner) .. ". " .. tostring(d.text), nil, 6)
	UI.sound("GameShowJingle")
end

function Stations.socialStep(d)
	local m = socialFrame(d)
	UI.label(m.content, d.prompt, { Font = UI.T.font, TextSize = UI.textSize(19), LayoutOrder = 20 })
	local timer = UI.label(m.content, "", { TextColor3 = C.gold, LayoutOrder = 21 })
	local answered = false
	for i, opt in ipairs(d.options) do
		UI.button(m.content, opt, function()
			if answered then
				return
			end
			answered = true
			Remote.call("social_answer", { sessionId = d.sessionId, choice = i })
			if m.alive() then
				m.clear()
				UI.label(m.content, "✅ Locked in. Waiting…", { LayoutOrder = 1 })
			end
		end, { LayoutOrder = 30 + i, TextSize = UI.textSize(15) })
	end
	local deadline = os.clock() + (d.seconds or 15)
	task.spawn(function()
		while m.alive() and not answered do
			local left = deadline - os.clock()
			if left <= 0 then
				break
			end
			timer.Text = "⏱ " .. math.ceil(left) .. "s"
			task.wait(0.25)
		end
	end)
	m.focus()
end

function Stations.socialWait(d)
	local m = socialFrame(d)
	UI.label(m.content, "⏳ " .. tostring(d.text), { LayoutOrder = 20 })
end

function Stations.socialEnd(d)
	local m = UI.modal("🎭 Results", { color = Color3.fromRGB(255, 120, 60) })
	socialModal = nil
	for i, line in ipairs(d.lines or {}) do
		UI.label(m.content, line, { LayoutOrder = i })
	end
	UI.button(m.content, "🔁 Play again", function()
		m.close()
		Stations.together()
	end, { LayoutOrder = 100, BackgroundColor3 = C.good })
	UI.button(m.content, "Done", function()
		m.close()
	end, { LayoutOrder = 101 })
	m.focus()
end

function Stations.journal()
	local r = Remote.call("journal_parts")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("📰 Write Clickbait", { color = C.accent })
	local sel = { s = 1, m = 1, e = 1 }
	local preview = UI.label(m.content, "", { Font = UI.T.title, TextSize = UI.textSize(20), LayoutOrder = 1 })
	local function refresh()
		preview.Text = "\"" .. r.parts.starts[sel.s] .. " " .. r.parts.subjects[sel.m] .. " " .. r.parts.endings[sel.e] .. "\""
	end
	refresh()
	local order = 2
	for _, group in ipairs({ { "s", "starts", "Start" }, { "m", "subjects", "Subject" }, { "e", "endings", "Ending" } }) do
		UI.label(m.content, "<b>" .. group[3] .. "</b>", { LayoutOrder = order })
		order += 1
		local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = m.content }, {
			UI.new("UIGridLayout", { CellSize = UDim2.new(0.48, 0, 0, 40), CellPadding = UDim2.fromOffset(6, 6) }),
		})
		order += 1
		for i, text in ipairs(r.parts[group[2]]) do
			UI.button(grid, text, function()
				sel[group[1]] = i
				refresh()
			end, { TextSize = UI.textSize(13) })
		end
	end
	UI.button(m.content, "📤 Publish", function()
		resultToast(Remote.call("journal_publish", sel))
		m.close()
	end, { LayoutOrder = 100, BackgroundColor3 = C.good })
	m.focus()
end

function Stations.sued(d)
	local m = UI.modal("⚖️ YOU'RE BEING SUED!", { color = Color3.fromRGB(200, 50, 50) })
	UI.label(m.content, "Someone is suing you because you " .. tostring(d.case) .. ".", { TextSize = UI.textSize(18), LayoutOrder = 1 })
	UI.label(m.content, "Go to court? A lawyer will defend you while you say the dumbest things possible.", { TextColor3 = UI.T.muted, LayoutOrder = 2 })
	UI.button(m.content, "⚖️ Go to court", function()
		m.close()
		resultToast(Remote.call("sued_accept"))
	end, { LayoutOrder = 3, BackgroundColor3 = C.good })
	UI.button(m.content, "🏃 Run away", function()
		m.close()
		UI.toast("You ran away from the law. Bold.")
	end, { LayoutOrder = 4 })
	m.focus()
end

function Stations.electionSpeech(d)
	local m = UI.modal("🗳 You're running for Mayor!", { color = C.gold })
	UI.label(m.content, "Pick your campaign promise (15 seconds):", { LayoutOrder = 1 })
	for i, opt in ipairs(d.options) do
		UI.button(m.content, opt, function()
			Remote.call("election_speech", { choice = i })
			m.close()
			UI.toast("📣 Speech locked in!")
		end, { LayoutOrder = 1 + i })
	end
	m.focus()
end

function Stations.electionVote(d)
	local m = UI.modal("🗳 Vote for Mayor!", { color = C.gold })
	UI.label(m.content, "You have " .. tostring(d.seconds) .. " seconds.", { TextColor3 = UI.T.muted, LayoutOrder = 1 })
	for i, c in ipairs(d.cands) do
		UI.button(m.content, (c.path == "Gain" and "🤓 " or "🤪 ") .. c.name .. "\n\"" .. c.speech .. "\"", function()
			resultToast(Remote.call("election_cast", { choice = i }))
			m.close()
		end, { LayoutOrder = 1 + i, Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = c.path == "Gain" and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(255, 50, 170) })
	end
	m.focus()
	task.delay(d.seconds or 20, function()
		if m.alive() then
			m.close()
		end
	end)
end

---------------------------------------------------------------------
-- UPDATE 1.3: Major Projects (the Science Lab)
---------------------------------------------------------------------
function Stations.lab()
	local r = Remote.call("project_list")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("🔬 Major Projects", phoneOpts(Color3.fromRGB(30, 160, 200)))
	if not r.allowed then
		UI.label(m.content, tostring(r.why), { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 1 })
	end
	if r.active then
		local card = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(20, 70, 100), Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = m.content }, {
			UI.new("UIListLayout", { Padding = UDim.new(0, 6) }),
			UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
		})
		UI.corner(card, 12)
		UI.label(card, "<b>" .. r.active.icon .. " " .. r.active.name .. "</b>", { TextColor3 = Color3.new(1, 1, 1), TextSize = UI.textSize(18) })
		UI.label(card, "Phase " .. r.active.phase .. "/" .. r.active.phases .. ": " .. r.active.phaseName, { TextColor3 = Color3.fromRGB(180, 230, 255) })
		local back = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.new(1, 0, 0, 10), Parent = card })
		UI.corner(back, 5)
		local fill = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(90, 255, 170), Size = UDim2.fromScale((r.active.phase - 1) / r.active.phases, 1), Parent = back })
		UI.corner(fill, 5)
		UI.button(card, "▶ Continue the project", function()
			Stations.projectStep()
		end, { BackgroundColor3 = Color3.fromRGB(40, 200, 120) })
		UI.button(card, "Abandon project", function()
			resultToast(Remote.call("project_abandon"))
			Stations.lab()
		end, { BackgroundColor3 = Color3.fromRGB(90, 60, 60), Size = UDim2.new(1, 0, 0, 34), TextSize = UI.textSize(13) })
	end
	UI.label(m.content, "<b>Pick a project</b> (inventions change the world for everyone):", { TextColor3 = Color3.fromRGB(210, 210, 220), TextSize = UI.textSize(13), LayoutOrder = 3 })
	for i, p in ipairs(r.projects) do
		local status = p.done and "✅ invented" or (p.globalActive and "🌍 active now" or "")
		local b = UI.button(m.content, p.icon .. "  " .. p.name .. (status ~= "" and ("   " .. status) or "") .. "\n<font size=\"12\">" .. p.unlock .. "</font>", function()
			if not r.allowed or r.active then
				resultToast({ ok = false, msg = r.active and "Finish your current project first." or r.why })
				return
			end
			local res = Remote.call("project_start", { key = p.key })
			resultToast(res)
			if res.ok then
				Stations.projectStep()
			end
		end, { LayoutOrder = 10 + i, Size = UDim2.new(1, 0, 0, 62), TextSize = UI.textSize(15), TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = p.done and Color3.fromRGB(30, 90, 60) or Color3.fromRGB(40, 40, 52) })
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = b })
	end
	UI.button(m.content, "⏳ Time Machine (secret project)" .. (r.timeMachineFails > 0 and ("   fails: " .. r.timeMachineFails) or ""), function()
		local res = Remote.call("project_start", { key = "timemachine" })
		resultToast(res)
	end, { LayoutOrder = 100, BackgroundColor3 = Color3.fromRGB(70, 40, 110) })
	m.focus()
end

function Stations.projectStep()
	local r = Remote.call("project_step")
	if not r.ok then
		return resultToast(r)
	end
	local m = UI.modal(r.icon .. " " .. r.name, phoneOpts(Color3.fromRGB(30, 160, 200)))
	UI.label(m.content, "Phase " .. r.phase .. "/" .. r.phases .. ": <b>" .. r.phaseName .. "</b>", { TextColor3 = Color3.fromRGB(180, 230, 255), LayoutOrder = 1 })
	UI.label(m.content, r.prompt, { Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), TextSize = UI.textSize(18), LayoutOrder = 2 })
	optionButtons(m.content, r.options, function(i)
		local res = Remote.call("project_answer", { choice = i })
		if not res.ok then
			return
		end
		if res.testDay then
			UI.toast("🚀 TEST DAY! The whole server is watching…", UI.Colors.gold, 6)
			m.close()
		elseif res.correct then
			UI.toast("✅ Phase complete!", UI.Colors.good)
			UI.sound("LevelUp", 0.6)
			Stations.projectStep()
		else
			UI.toast(res.msg, UI.Colors.bad, 5)
			UI.sound("DeathBoom", 0.5)
			Stations.projectStep()
		end
	end)
	m.focus()
end

function Stations.quiz(d)
	local m = UI.modal("❓ Server Quiz!", { color = UI.Colors.gold })
	UI.label(m.content, d.q, { Font = Enum.Font.GothamBold, TextSize = UI.textSize(19), LayoutOrder = 1 })
	optionButtons(m.content, d.options, function(i)
		resultToast(Remote.call("quiz_answer", { id = d.id, choice = i }))
		m.close()
	end)
	m.focus()
end

---------------------------------------------------------------------
-- One-tap pass buttons on the HUD (honest: price + effect shown first)
---------------------------------------------------------------------
function Stations.buyPass(key: string)
	local r = Remote.call("shop_list")
	if not r.ok then
		return
	end
	if not r.enabled then
		UI.toast("Purchases are paused right now.", C.bad)
		return
	end
	for _, pass in ipairs(r.passes) do
		if pass.key == key then
			if pass.owned then
				UI.toast("✅ You already own " .. pass.name)
				return
			end
			if pass.id == 0 then
				UI.toast("This pass isn't set up yet (the owner needs to add its ID).", C.bad)
				return
			end
			local warning = "R$ " .. pass.price .. " for: " .. pass.desc
			if pass.cellsLost > 0 then
				warning ..= "\n\nThis pass makes you lose " .. Brain.formatNumber(pass.cellsLost) .. " brain cells. You can finish the game without it."
			end
			confirm(pass.name, warning, "Continue to purchase", function()
				MarketplaceService:PromptGamePassPurchase(player, pass.id)
			end)
			return
		end
	end
	UI.toast("That pass is for the other path.")
end

---------------------------------------------------------------------
-- UPDATE 1.4: SPACE
---------------------------------------------------------------------
local SPACE = Color3.fromRGB(30, 30, 90)

local function card(parent, order: number, color: Color3)
	local f = UI.new("Frame", { BackgroundColor3 = color, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = parent }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})
	UI.corner(f, 14)
	return f
end

function Stations.space()
	local r = Remote.call("space_info")
	if not r or not r.ok then
		return
	end
	local m = UI.modal("🚀 Space", phoneOpts(SPACE))
	local white = Color3.new(1, 1, 1)
	if r.path ~= "Gain" then
		UI.label(m.content, "Space is on the Gain path. (Rockets need brains.)", { TextColor3 = white, LayoutOrder = 1 })
		m.focus()
		return
	end
	local status = card(m.content, 1, Color3.fromRGB(20, 20, 60))
	UI.label(status, "<b>🧑‍🚀 Astronaut</b>", { TextColor3 = white, TextSize = UI.textSize(20) })
	UI.label(status, (r.iq >= r.needIQ and "✅" or "⬜") .. "  IQ " .. r.needIQ .. "+   (you: " .. r.iq .. ")", { TextColor3 = white })
	UI.label(status, (r.invented and "✅  Space Travel has been invented (by someone, ever)" or "⬜  Nobody has invented 🚀 Space Travel yet"), { TextColor3 = white })
	if r.passOwned then
		UI.label(status, "🎟 Astronaut Early Access: owned", { TextColor3 = Color3.fromRGB(255, 220, 120) })
	end
	if r.astronaut then
		UI.label(status, "<b>You're an Astronaut!</b>", { TextColor3 = Color3.fromRGB(120, 255, 170) })
		if r.inSpace then
			UI.button(m.content, "🧑‍🚀 Astronaut training", function()
				Stations.astroTraining()
			end, { LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(60, 90, 200) })
			UI.button(m.content, "🚧 Space Gate (orbital mechanics)", function()
				Stations.spaceGate()
			end, { LayoutOrder = 3, BackgroundColor3 = Color3.fromRGB(90, 60, 170) })
			UI.button(m.content, "🔬 Space projects", function()
				if Stations.route then
					Stations.route("lab")
				end
			end, { LayoutOrder = 4, BackgroundColor3 = Color3.fromRGB(30, 140, 180) })
		else
			UI.button(m.content, "🚀 Go to the Launch Pad", function()
				m.close()
				resultToast(Remote.call("space_launch"))
			end, { LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(220, 70, 50) })
		end
	elseif r.iq >= r.needIQ and not r.invented then
		-- the honest choice screen
		UI.label(m.content, "<b>You're smart enough to be an Astronaut.</b> But nobody has invented Space Travel yet. Two ways:", { TextColor3 = white, LayoutOrder = 2 })
		local free = card(m.content, 3, Color3.fromRGB(25, 90, 60))
		UI.label(free, "<b>🆓 FREE: invent it yourself</b>", { TextColor3 = white, TextSize = UI.textSize(17) })
		UI.label(free, "Do the 🚀 Space Travel Major Project. You might even be the FIRST player ever (badge + statue).", { TextColor3 = white })
		UI.button(free, "🔬 Open Projects", function()
			if Stations.route then
				Stations.route("lab")
			end
		end, { BackgroundColor3 = Color3.fromRGB(40, 170, 100) })
		if r.passOffered then
			local paid = card(m.content, 4, Color3.fromRGB(70, 50, 20))
			UI.label(paid, "<b>🎟 Astronaut Early Access: R$ " .. r.passPrice .. "</b>", { TextColor3 = white, TextSize = UI.textSize(17) })
			UI.label(paid, "Unlocks Astronaut right now, for every run.\n⚠️ Heads up: as soon as ANY player invents Space Travel, Astronaut becomes FREE for everyone. You'd be paying to get it early.", { TextColor3 = Color3.fromRGB(255, 235, 200) })
			UI.button(paid, "See the pass", function()
				Stations.buyPass("AstronautEarly")
			end, { BackgroundColor3 = Color3.fromRGB(200, 140, 40) })
		end
	else
		UI.label(m.content, "Keep getting smarter. At IQ " .. r.needIQ .. " (and once Space Travel exists) the Launch Pad east of town is yours.", { TextColor3 = white, LayoutOrder = 2 })
	end
	m.focus()
end

local function miniFrame(parent, h: number)
	local f = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(5, 5, 20), Size = UDim2.new(1, 0, 0, h), LayoutOrder = 5, ClipsDescendants = true, Parent = parent })
	UI.corner(f, 12)
	-- stars
	for _ = 1, 30 do
		UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = math.random() * 0.6, BorderSizePixel = 0, Size = UDim2.fromOffset(2, 2), Position = UDim2.fromScale(math.random(), math.random()), Parent = f })
	end
	return f
end

local function reportTraining(key: string, success: boolean, after)
	local r = Remote.call("astro_train_done", { key = key, success = success })
	resultToast(r)
	UI.sound(success and "LevelUp" or "CartoonBoing", 0.6)
	if after then
		task.delay(1.2, after)
	end
end

function Stations.astroTraining()
	local m = UI.modal("🧑‍🚀 Astronaut Training", phoneOpts(SPACE))
	local st = UI.state or {}
	local _ = st
	for i, t in ipairs(require(ReplicatedStorage.Shared.Content).AstroTraining) do
		UI.button(m.content, t.icon .. "  " .. t.name .. "\n<font size=\"12\">" .. t.desc .. "</font>", function()
			Remote.call("astro_train_start", { key = t.key }) -- the server times each round
			Stations["astro_" .. t.key]()
		end, { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 70), TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Color3.fromRGB(40, 50, 110) })
	end
	m.focus()
end

-- Docking: the capsule drifts side to side. Tap DOCK when it lines up with the port.
Stations.astro_dock = function()
	local m = UI.modal("🛰 Docking", phoneOpts(SPACE))
	UI.label(m.content, "Tap <b>DOCK</b> when the capsule lines up with the port. 3 good docks in a row!", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 1 })
	local f = miniFrame(m.content, 220)
	local port = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(54, 40), BackgroundColor3 = Color3.fromRGB(180, 190, 200), Parent = f })
	UI.corner(port, 6)
	UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "🛰", TextScaled = true, Parent = port })
	local guide = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.new(0, 2, 1, -60), BackgroundColor3 = Color3.fromRGB(90, 255, 160), BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = f })
	local _ = guide
	local cap = UI.new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(46, 46), BackgroundTransparency = 1, Text = "🚀", TextScaled = true, Parent = f })
	local good = 0
	local t0 = os.clock()
	local speed = 1.6
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not f.Parent then
			conn:Disconnect()
			return
		end
		local x = 0.5 + 0.42 * math.sin((os.clock() - t0) * speed)
		cap.Position = UDim2.new(x, 0, 1, -10)
	end)
	local score = UI.label(m.content, "Docks: 0 / 3", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 6 })
	UI.button(m.content, "🔒 DOCK", function()
		local off = math.abs(cap.Position.X.Scale - 0.5)
		if off < 0.06 then
			good += 1
			speed += 0.5
			UI.sound("NotificationPing", 0.5)
			score.Text = "Docks: " .. good .. " / 3"
			if good >= 3 then
				conn:Disconnect()
				reportTraining("dock", true, Stations.astroTraining)
			end
		else
			conn:Disconnect()
			reportTraining("dock", false, Stations.astroTraining)
		end
	end, { LayoutOrder = 7, BackgroundColor3 = Color3.fromRGB(40, 170, 100) })
	m.focus()
end

-- Oxygen: the needle drops all the time. Tap BREATHE to keep it in the green zone for 15 s.
Stations.astro_oxygen = function()
	local m = UI.modal("💦 Oxygen", phoneOpts(SPACE))
	UI.label(m.content, "Keep the needle in the <b>green zone</b> for 15 seconds. Too much oxygen is bad too!", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 1 })
	local f = miniFrame(m.content, 70)
	local zone = UI.new("Frame", { Position = UDim2.new(0.4, 0, 0.2, 0), Size = UDim2.new(0.3, 0, 0.6, 0), BackgroundColor3 = Color3.fromRGB(60, 200, 110), BackgroundTransparency = 0.3, Parent = f })
	UI.corner(zone, 6)
	local needle = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.55, 0, 0.05, 0), Size = UDim2.new(0, 6, 0.9, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = f })
	UI.corner(needle, 3)
	local timeLabel = UI.label(m.content, "15.0 s left", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 6 })
	local value, outside, left = 0.55, 0, 15
	local done = false
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not f.Parent then
			conn:Disconnect()
			return
		end
		value = math.clamp(value - dt * 0.16, 0, 1)
		needle.Position = UDim2.new(value, 0, 0.05, 0)
		local inZone = value >= 0.4 and value <= 0.7
		needle.BackgroundColor3 = inZone and Color3.new(1, 1, 1) or Color3.fromRGB(255, 80, 80)
		if not inZone then
			outside += dt
		end
		left -= dt
		timeLabel.Text = string.format("%.1f s left   (out of zone: %.1f / 3 s)", math.max(0, left), outside)
		if not done and (outside > 3 or left <= 0) then
			done = true
			conn:Disconnect()
			reportTraining("oxygen", outside <= 3, Stations.astroTraining)
		end
	end)
	UI.button(m.content, "💨 BREATHE", function()
		value = math.clamp(value + 0.12, 0, 1)
	end, { LayoutOrder = 7, BackgroundColor3 = Color3.fromRGB(60, 140, 220) })
	m.focus()
end

-- Zero-G: push off in a direction. You keep drifting (no brakes in space). Grab 4 handles in 30 s.
Stations.astro_zerog = function()
	local m = UI.modal("🧑‍🚀 Zero-G", phoneOpts(SPACE))
	UI.label(m.content, "Push off to reach each 🟡 handle. You keep drifting: push the other way to slow down. 4 handles in 30 s!", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 1 })
	local f = miniFrame(m.content, 230)
	local me = UI.new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, Text = "🧑‍🚀", TextScaled = true, Parent = f })
	local handle = UI.new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Text = "🟡", TextScaled = true, Parent = f })
	local pos, vel = Vector2.new(0.5, 0.5), Vector2.new(0, 0)
	local target = Vector2.new(0.2, 0.2)
	local got, left, done = 0, 30, false
	local info = UI.label(m.content, "Handles: 0 / 4", { TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 6 })
	local function newTarget()
		target = Vector2.new(0.12 + math.random() * 0.76, 0.12 + math.random() * 0.76)
		handle.Position = UDim2.fromScale(target.X, target.Y)
	end
	newTarget()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not f.Parent then
			conn:Disconnect()
			return
		end
		pos += vel * dt
		if pos.X < 0.05 or pos.X > 0.95 then
			vel = Vector2.new(-vel.X * 0.8, vel.Y)
			pos = Vector2.new(math.clamp(pos.X, 0.05, 0.95), pos.Y)
		end
		if pos.Y < 0.05 or pos.Y > 0.95 then
			vel = Vector2.new(vel.X, -vel.Y * 0.8)
			pos = Vector2.new(pos.X, math.clamp(pos.Y, 0.05, 0.95))
		end
		me.Position = UDim2.fromScale(pos.X, pos.Y)
		me.Rotation += dt * 40
		left -= dt
		if (pos - target).Magnitude < 0.08 then
			got += 1
			UI.sound("NotificationPing", 0.5)
			info.Text = "Handles: " .. got .. " / 4"
			newTarget()
		end
		if not done and (got >= 4 or left <= 0) then
			done = true
			conn:Disconnect()
			reportTraining("zerog", got >= 4, Stations.astroTraining)
		end
	end)
	local pad = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), LayoutOrder = 7, Parent = m.content }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.23, 0, 0, 46), CellPadding = UDim2.new(0.02, 0, 0, 0) }),
	})
	for _, d in ipairs({ { "⬅", Vector2.new(-1, 0) }, { "⬆", Vector2.new(0, -1) }, { "⬇", Vector2.new(0, 1) }, { "➡", Vector2.new(1, 0) } }) do
		UI.button(pad, d[1], function()
			vel += d[2] * 0.18
		end, { BackgroundColor3 = Color3.fromRGB(60, 70, 140), Size = UDim2.new(1, 0, 1, 0) })
	end
	m.focus()
end

function Stations.spaceGate()
	local r = Remote.call("space_gate")
	if not r or not r.ok then
		return resultToast(r)
	end
	local m = UI.modal("🚧 Space Gate", phoneOpts(SPACE))
	UI.label(m.content, r.q, { Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), TextSize = UI.textSize(18), LayoutOrder = 1 })
	optionButtons(m.content, r.options, function(i)
		local res = Remote.call("space_gate_answer", { choice = i })
		resultToast(res)
		if res and res.correct then
			UI.sound("LevelUp", 0.6)
		end
		Stations.space()
	end)
	m.focus()
end

-- Retired Genius: someone walks up and asks you something
function Stations.retiredQuestion(d)
	if UI.isModalOpen() then
		return -- don't interrupt; they'll ask again later
	end
	local m = UI.modal("👑 Someone has a question", { color = C.gold })
	UI.label(m.content, "<b>" .. tostring(d.who) .. "</b> walks up to you:\n\"" .. tostring(d.q) .. "\"", { TextSize = UI.textSize(18), LayoutOrder = 1 })
	optionButtons(m.content, d.options, function(i)
		resultToast(Remote.call("retired_answer", { choice = i }))
		m.close()
	end)
	m.focus()
end

---------------------------------------------------------------------
-- Dispatcher
---------------------------------------------------------------------
---------------------------------------------------------------------
-- 1.8: Phone Shop (phones, case maker with Brainrot meter) and the scam stall
---------------------------------------------------------------------
function Stations.phoneshop()
	local TP = Content.PhoneShop
	local r = Remote.call("phone_shop")
	if not r.ok then
		return
	end
	local m = UI.modal(TP.Title, { color = Color3.fromRGB(120, 90, 255) })
	local meter
	local function refreshMeter(x)
		if meter then
			meter.Text = string.format(TP.Meter, x.rot or 0, x.maxRot or 15)
		end
	end
	for i, ph in ipairs(r.phones) do
		local label = ph.name .. "\n<font size=\"13\">" .. ph.desc .. "</font>"
		local btnText = ph.using and TP.Using or (ph.owned and TP.Use or (ph.price == 0 and TP.Free or string.format(TP.BuyFor, ph.price)))
		local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, UI.minTouch() + 10), LayoutOrder = i, Parent = m.content })
		UI.label(row, label, { Size = UDim2.new(0.6, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.None })
		UI.button(row, btnText, function()
			if ph.using then
				return
			end
			local b = Remote.call("phone_buy", { key = ph.key })
			UI.toast((b.ok and "" or "⛔ ") .. tostring(b.msg or ""), b.ok and C.good or C.bad)
			if b.ok then
				m.close()
				Stations.phoneshop()
			end
		end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.38, 0, 0, UI.minTouch()), BackgroundColor3 = ph.using and C.good or nil })
	end
	-- case maker
	UI.label(m.content, "<b>" .. TP.CaseHeader .. "</b>", { LayoutOrder = 50 })
	local state = { color = r.color, stickers = {} }
	for _, k in ipairs(r.stickers or {}) do
		state.stickers[k] = true
	end
	local function send()
		local list = {}
		for _, s in ipairs(TP.Stickers) do
			if state.stickers[s.key] then
				table.insert(list, s.key)
			end
		end
		local x = Remote.call("case_set", { color = state.color, stickers = list })
		if x.ok then
			refreshMeter(x)
		end
		return x
	end
	UI.label(m.content, TP.ColorHeader, { LayoutOrder = 51 })
	for i, c in ipairs(TP.Colors) do
		local b
		b = UI.button(m.content, (state.color == c.key and "✅ " or "") .. c.name, function()
			state.color = c.key
			send()
			m.close()
			Stations.phoneshop()
		end, { LayoutOrder = 51 + i })
		local _ = b
	end
	UI.label(m.content, string.format(TP.StickerHeader, 4), { LayoutOrder = 60 })
	for i, s in ipairs(TP.Stickers) do
		local b
		b = UI.button(m.content, (state.stickers[s.key] and "✅ " or "➕ ") .. s.name, function()
			state.stickers[s.key] = not state.stickers[s.key] or nil
			local x = send()
			-- the server keeps at most 4: show what it really kept
			state.stickers = {}
			for _, k in ipairs(x.stickers or {}) do
				state.stickers[k] = true
			end
			b.Text = (state.stickers[s.key] and "✅ " or "➕ ") .. s.name
		end, { LayoutOrder = 60 + i })
	end
	meter = UI.label(m.content, "", { LayoutOrder = 70, Font = Enum.Font.FredokaOne, TextSize = UI.textSize(18) })
	refreshMeter(r)
	UI.label(m.content, TP.MeterInfo, { LayoutOrder = 71, TextColor3 = C.muted })
	UI.button(m.content, TP.Show, function()
		local x = Remote.call("case_show")
		UI.toast(tostring(x.msg or ""), x.ok and C.good or C.bad)
	end, { LayoutOrder = 72, BackgroundColor3 = Color3.fromRGB(255, 120, 220) })
	m.focus()
end

function Stations.scam()
	local TP = Content.PhoneShop
	local r = Remote.call("phone_shop")
	if not r.ok then
		return
	end
	local m = UI.modal(TP.ScamTitle, { color = Color3.fromRGB(255, 200, 40) })
	UI.label(m.content, TP.ScamPitch, { LayoutOrder = 1 })
	if r.path == "Gain" then
		-- smart players see what's really going on
		UI.label(m.content, "<b>" .. TP.RedFlagsTitle .. "</b>", { LayoutOrder = 2 })
		for i, f in ipairs(TP.RedFlags) do
			UI.label(m.content, f, { LayoutOrder = 2 + i })
		end
		UI.button(m.content, TP.Report, function()
			local x = Remote.call("scam_report")
			UI.toast(tostring(x.msg or ""), x.ok and C.good or C.bad)
			if x.ok then
				m.close()
			end
		end, { LayoutOrder = 20, BackgroundColor3 = Color3.fromRGB(60, 110, 230) })
	else
		-- honest money: the price and the (unknown) effect are shown before you pay
		UI.label(m.content, string.format(TP.ScamPrice, Config.PhoneShop.ScamPrice), { LayoutOrder = 2 })
		UI.label(m.content, TP.ScamEffect, { LayoutOrder = 3, TextColor3 = C.muted })
		if r.scam then
			UI.button(m.content, TP.ScamUse, function()
				local x = Remote.call("scam_use")
				UI.toast(tostring(x.msg or ""), x.ok and C.good or C.bad)
			end, { LayoutOrder = 10 })
		else
			UI.button(m.content, string.format(TP.ScamBuy, Config.PhoneShop.ScamPrice), function()
				local x = Remote.call("scam_buy")
				UI.toast(tostring(x.msg or ""), x.ok and C.good or C.bad)
				m.close()
			end, { LayoutOrder = 10, BackgroundColor3 = Color3.fromRGB(255, 170, 40) })
		end
	end
	m.focus()
end

---------------------------------------------------------------------
-- 1.8: free west-side places (Slime Shop, Trampoline Park, Fortune Teller)
---------------------------------------------------------------------
local function funScreen(key: string)
	local TF = Content.Fun
	local T = TF[key]
	local m = UI.modal(T.Title, { color = Color3.fromRGB(170, 80, 255) })
	local path = UI.state and UI.state.path
	if key == "fortune" then
		-- exact odds, shown before you ask
		UI.label(m.content, "<b>" .. TF.OddsTitle .. "</b>", { LayoutOrder = 1 })
		for i, o in ipairs(Config.Fun.fortune.Odds) do
			UI.label(m.content, string.format(TF.Odds[o.kind], o.weight), { LayoutOrder = 1 + i })
		end
		UI.label(m.content, TF.OddsEffect, { LayoutOrder = 10, TextColor3 = C.muted })
	end
	if key == "toystore" and UI.state and UI.state.perks and UI.state.perks.LifePack then
		-- 1.8: adopt a pet here (Life Pack)
		local TP = Content.PetsFriends
		UI.label(m.content, "<b>" .. TP.PetHeader .. "</b>", { LayoutOrder = 30 })
		for i, kind in ipairs({ "dog", "cat", "fish", "none" }) do
			UI.button(m.content, TP.PetButtons[kind], function()
				local x = Remote.call("pet_adopt", { kind = kind })
				UI.toast(tostring(x.msg or ""), x.ok and C.good or C.bad)
			end, { LayoutOrder = 30 + i })
		end
	end
	local label = key == "fortune" and T.Button or (path == "Gain" and T.Gain or T.Lose)
	UI.button(m.content, label, function()
		local r = Remote.call("fun_do", { key = key })
		if r.card then
			m.close()
			Stations.lifePackCard(r)
			return
		end
		UI.toast(tostring(r.msg or ""), r.ok and C.good or C.bad, 5)
	end, { LayoutOrder = 20, BackgroundColor3 = Color3.fromRGB(170, 80, 255) })
	m.focus()
end
function Stations.slime()
	funScreen("slime")
end
function Stations.trampoline()
	funScreen("trampoline")
end
function Stations.fortune()
	funScreen("fortune")
end
-- 1.8: the honest Life Pack card (price + contents first) and the five hidden places
function Stations.lifePackCard(r)
	local TP = Content.LifePackPlaces
	local m = UI.modal(TP.CardTitle, { color = Color3.fromRGB(255, 200, 220) })
	UI.label(m.content, string.format(TP.CardText, tonumber(r.price) or 100), { LayoutOrder = 1 })
	if not r.previewUsed then
		UI.button(m.content, TP.Preview, function()
			local x = Remote.call("life_preview")
			UI.toast(tostring(x.msg or ""), x.ok and C.good or C.bad, 5)
			m.close()
		end, { LayoutOrder = 2, BackgroundColor3 = C.good })
	end
	UI.button(m.content, TP.SeePass, function()
		m.close()
		Stations.buyPass("LifePack")
	end, { LayoutOrder = 3 })
	m.focus()
end
for _, k in ipairs({ "party", "kindergarten", "daycare", "retirement", "toystore" }) do
	Stations[k] = function()
		funScreen(k)
	end
end


---------------------------------------------------------------------
-- 1.8: Life Pack: the Crossroads Ceremony and starting a new life
---------------------------------------------------------------------
function Stations.crossroads(d)
	local TL = Content.LifeStages
	local m = UI.modal(TL.CeremonyTitle, { color = Color3.fromRGB(255, 210, 80) })
	if d.chosen then
		UI.label(m.content, TL.AlreadyChose, { LayoutOrder = 1 })
	elseif (d.age or 0) < (d.from or 8) then
		UI.label(m.content, string.format(TL.CeremonyWait, d.age or 0, d.from or 8), { LayoutOrder = 1 })
	else
		UI.label(m.content, string.format(TL.CeremonyText, d.age or 0), { LayoutOrder = 1 })
		for i, p in ipairs({ "Gain", "Lose" }) do
			UI.button(m.content, p == "Gain" and TL.PickGain or TL.PickLose, function()
				local r = Remote.call("crossroads", { path = p })
				UI.toast(tostring(r.msg or ""), r.ok and C.good or C.bad, 5)
				if r.ok then
					m.close()
				end
			end, { LayoutOrder = 1 + i, BackgroundColor3 = p == "Gain" and Color3.fromRGB(70, 140, 255) or Color3.fromRGB(255, 90, 180) })
		end
		UI.button(m.content, TL.NotNow, function()
			m.close()
		end, { LayoutOrder = 10 })
	end
	m.focus()
end

function Stations.startLife()
	local TL = Content.LifeStages
	local m = UI.modal(TL.StartLife, { color = Color3.fromRGB(255, 200, 220) })
	UI.label(m.content, TL.StartLifeConfirm, { LayoutOrder = 1 })
	UI.button(m.content, TL.StartLifeYes, function()
		local r = Remote.call("life_start", { confirm = true })
		UI.toast(tostring(r.msg or ""), r.ok and C.good or C.bad, 6)
		m.close()
	end, { LayoutOrder = 2, BackgroundColor3 = C.good })
	UI.button(m.content, TL.NotNow, function()
		m.close()
	end, { LayoutOrder = 3 })
	m.focus()
end

function Stations.open(key: string)
	local fn = Stations[key]
	if fn and key ~= "open" then
		fn()
	end
end

return Stations

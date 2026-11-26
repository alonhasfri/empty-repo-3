-- Conversation (update 1.5): the cinematic look of a conversation scene.
--   Letterbox bars, the camera moves in and cuts to whoever is talking,
--   lines are typed out with little blips, and you pick what to say from the
--   bottom-left (like bargaining in a football game). Each choice plays your line.
-- The server (ConversationService) decides everything; this only shows it.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local Conversation = {}

local player = Players.LocalPlayer
local CC = Config.Conversations
local T = Content.ConvUI

local gui = Instance.new("ScreenGui")
gui.Name = "ConversationUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false -- stay below Roblox's own top bar buttons
gui.DisplayOrder = 20
gui.Enabled = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- The black bars live in their own layer that ignores phone safe areas, so they reach the edges
local bars = Instance.new("ScreenGui")
bars.Name = "ConversationBars"
bars.ResetOnSpawn = false
bars.IgnoreGuiInset = true
bars.ScreenInsets = Enum.ScreenInsets.None
bars.DisplayOrder = 19
bars.Enabled = false
bars.Parent = gui.Parent

local cur = nil -- the open conversation

-- Your friends (the people who follow you around) step out of the shot
local function hideFriends()
	local hidden = {}
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("FriendName") then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("Decal") then
					table.insert(hidden, d)
					d.LocalTransparencyModifier = 1
				elseif d:IsA("BillboardGui") and d.Enabled then
					table.insert(hidden, d)
					d.Enabled = false
				end
			end
		end
	end
	return hidden
end

local function showFriends(hidden)
	for _, d in ipairs(hidden or {}) do
		if d.Parent then
			if d:IsA("BillboardGui") then
				d.Enabled = true
			else
				d.LocalTransparencyModifier = 0
			end
		end
	end
end

---------------------------------------------------------------------
-- Building the screen
---------------------------------------------------------------------
local function new(className: string, props, parent)
	local i = Instance.new(className)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function corner(i, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, i)
end

local function maxText(i, size)
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 9 }, i)
end

local function build()
	gui:ClearAllChildren()
	bars:ClearAllChildren()
	local r = {}
	r.top = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0.09, 0), Position = UDim2.new(0, 0, -0.09, 0) }, bars)
	r.bottom = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(1, 0, 0.09, 0), Position = UDim2.new(0, 0, 1.09, 0) }, bars)

	-- meter (top center, just under the bar)
	local meter = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.03, 0), Size = UDim2.new(0.36, 0, 0.075, 0), BackgroundColor3 = Color3.fromRGB(20, 20, 28), BackgroundTransparency = 0.25 }, gui)
	corner(meter, 8)
	r.meterName = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.42, 0, 1, 0), Position = UDim2.new(0.02, 0, 0, 0), Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, meter)
	maxText(r.meterName, 18)
	local bar = new("Frame", { Position = UDim2.new(0.46, 0, 0.3, 0), Size = UDim2.new(0.51, 0, 0.4, 0), BackgroundColor3 = Color3.fromRGB(60, 60, 70) }, meter)
	corner(bar, 6)
	r.fill = new("Frame", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 210, 60) }, bar)
	corner(r.fill, 6)

	-- leave (top right, always there: the way out)
	r.leave = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.98, 0, 0.03, 0), Size = UDim2.new(0.11, 0, 0.075, 0), BackgroundColor3 = Color3.fromRGB(40, 40, 50), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.FredokaOne, TextScaled = true, Text = T.Leave, AutoButtonColor = true, Name = "Leave" }, gui)
	corner(r.leave, 8)
	maxText(r.leave, 18)
	new("UISizeConstraint", { MinSize = Vector2.new(70, 32) }, r.leave)

	-- subtitles (bottom right): who is talking + the line. Tap to finish the line.
	r.sub = new("TextButton", { AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.98, 0, 0.87, 0), Size = UDim2.new(0.5, 0, 0.27, 0), BackgroundColor3 = Color3.fromRGB(16, 16, 24), BackgroundTransparency = 0.15 }, gui)
	corner(r.sub, 12)
	new("UIStroke", { Color = Color3.fromRGB(255, 210, 60), Thickness = 2, Transparency = 0.3 }, r.sub)
	r.name = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.04, 0, 0.05, 0), Size = UDim2.new(0.92, 0, 0.24, 0), Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.fromRGB(255, 210, 60), TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, r.sub)
	maxText(r.name, 20)
	r.text = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.04, 0, 0.3, 0), Size = UDim2.new(0.92, 0, 0.66, 0), Font = Enum.Font.GothamMedium, TextScaled = true, TextWrapped = true, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, r.sub)
	maxText(r.text, 22)

	-- choices (bottom left)
	r.opts = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0.02, 0, 0.87, 0), Size = UDim2.new(0.44, 0, 0.52, 0), BackgroundTransparency = 1, Visible = false }, gui)
	new("UIListLayout", { Padding = UDim.new(0.03, 0), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }, r.opts)
	return r
end

---------------------------------------------------------------------
-- Camera
---------------------------------------------------------------------
-- Only the town's buildings (walls, roofs) can block the camera
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Include

-- Moves the camera from `from` toward `want`, stopping in front of any wall in between
local function clearSpot(from: Vector3, want: Vector3): Vector3
	local town = workspace:FindFirstChild("Town")
	if not town then
		return want
	end
	wallParams.FilterDescendantsInstances = { town }
	local dir = want - from
	local hit = workspace:Raycast(from, dir, wallParams)
	if hit then
		return hit.Position - dir.Unit * 0.8
	end
	return want
end

local function tweenCam(from: Vector3, want: Vector3, lookAt: Vector3)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local cf = CFrame.lookAt(clearSpot(from, want), lookAt)
	TweenService:Create(cam, TweenInfo.new(CC.CameraTween, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = cf }):Play()
end

local function shot(kind: string)
	if not cur then
		return
	end
	local me, npc = cur.stand.Position, cur.npc.Position
	local meHead, npcHead = me + Vector3.new(0, 4.4, 0), npc + Vector3.new(0, 4.4, 0)
	if kind == "wide" then
		local mid = (meHead + npcHead) / 2
		tweenCam(mid, cur.wide, mid)
	elseif kind == "npc" then
		-- over your shoulder, looking at them
		local back = (me - npc).Unit
		local right = back:Cross(Vector3.yAxis).Unit
		tweenCam(meHead, meHead + back * 3.4 + right * 4.6 + Vector3.new(0, 1, 0), npcHead + right * 0.4)
	else
		-- over their shoulder, looking at you
		local back = (npc - me).Unit
		local right = back:Cross(Vector3.yAxis).Unit
		tweenCam(npcHead, npcHead + back * 3.4 + right * 4.6 + Vector3.new(0, 1, 0), meHead + right * 0.4)
	end
end

---------------------------------------------------------------------
-- Lines and choices
---------------------------------------------------------------------
local function setMeter(v: number)
	if not cur then
		return
	end
	local color = v >= CC.GoodAt and Color3.fromRGB(47, 191, 113) or (v <= CC.BadAt and Color3.fromRGB(229, 72, 77) or Color3.fromRGB(255, 210, 60))
	TweenService:Create(cur.r.fill, TweenInfo.new(0.4), { Size = UDim2.new(math.clamp(v / 100, 0, 1), 0, 1, 0), BackgroundColor3 = color }):Play()
end

local function typeSpeed(): number
	local st = UI.state
	if st and st.iq and st.iq >= CC.SmartIQ then
		return CC.SmartTypeSpeed
	end
	return CC.TypeSpeed
end

-- Types a line; returns when it's done (or tapped to finish)
local function typeLine(name: string, text: string)
	local c = cur
	if not c then
		return
	end
	c.r.name.Text = name
	c.r.text.Text = text
	c.r.text.MaxVisibleGraphemes = 0
	c.skip = false
	local total = utf8.len(text) or #text
	local shown = 0
	local step = 1 / typeSpeed()
	while c == cur and shown < total do
		if c.skip then
			shown = total
		else
			shown += 1
		end
		c.r.text.MaxVisibleGraphemes = shown
		if shown % 3 == 0 then
			UI.sound("TypeTick", 0.25)
		end
		task.wait(step)
	end
	if c == cur then
		c.r.text.MaxVisibleGraphemes = -1
		task.wait(CC.PauseAfterLine)
	end
end

local function floatText(text: string, color: Color3)
	if not cur then
		return
	end
	local l = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.12, 0), Size = UDim2.new(0.4, 0, 0.06, 0), Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = color, TextStrokeTransparency = 0.3, Text = text }, gui)
	TweenService:Create(l, TweenInfo.new(1.2), { Position = UDim2.new(0.5, 0, 0.08, 0), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.3, function()
		l:Destroy()
	end)
end

local function objection()
	local l = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.42, 0), Size = UDim2.new(0.7, 0, 0.2, 0), Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.fromRGB(255, 60, 60), TextStrokeColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, Rotation = -6, Text = T.Objection }, gui)
	local sc = new("UIScale", { Scale = 2.2 }, l)
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	UI.sound("ImportantSlam", 0.8)
	task.delay(1.1, function()
		l:Destroy()
	end)
end

local pick -- forward

local function unbindKeys()
	ContextActionService:UnbindAction("ConvChoice")
end

local function showChoices(list, onChoose)
	local c = cur
	if not c then
		return
	end
	for _, ch in ipairs(c.r.opts:GetChildren()) do
		if ch:IsA("GuiButton") then
			ch:Destroy()
		end
	end
	local buttons = {}
	for i, text in ipairs(list) do
		local b = new("TextButton", { LayoutOrder = i, Size = UDim2.new(1, 0, 0.3, 0), BackgroundColor3 = Color3.fromRGB(18, 22, 36), BackgroundTransparency = 0.1, AutoButtonColor = true, Text = "", Selectable = true }, c.r.opts)
		corner(b, 8)
		new("UIStroke", { Color = UI.T.accent or Color3.fromRGB(150, 90, 255), Thickness = 2, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		local num = new("TextLabel", { Size = UDim2.new(0.13, 0, 1, 0), BackgroundColor3 = UI.T.accent or Color3.fromRGB(150, 90, 255), Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = tostring(i) }, b)
		corner(num, 8)
		new("UIPadding", { PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0) }, num)
		local l = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.16, 0, 0.06, 0), Size = UDim2.new(0.81, 0, 0.88, 0), Font = Enum.Font.GothamBold, TextScaled = true, TextWrapped = true, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Text = text }, b)
		maxText(l, 18)
		-- slide in from the left, one after another
		local sc = new("UIScale", { Scale = 0.6 }, b)
		TweenService:Create(sc, TweenInfo.new(0.18 + i * 0.05, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		b.Activated:Connect(function()
			onChoose(i)
		end)
		buttons[i] = b
	end
	c.r.opts.Visible = true
	-- keys 1/2/3 and controllers
	ContextActionService:BindActionAtPriority("ConvChoice", function(_, state, input)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local map = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.KeypadOne] = 1, [Enum.KeyCode.KeypadTwo] = 2, [Enum.KeyCode.KeypadThree] = 3 }
		local i = map[input.KeyCode]
		if i and buttons[i] then
			onChoose(i)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.KeypadOne, Enum.KeyCode.KeypadTwo, Enum.KeyCode.KeypadThree)
	if UI.isGamepad and UI.isGamepad() then
		GuiService.SelectedObject = buttons[1]
	end
end

local function hideChoices()
	if cur then
		cur.r.opts.Visible = false
	end
	unbindKeys()
	GuiService.SelectedObject = nil
end

local function sayNode(node)
	local c = cur
	if not c then
		return
	end
	c.node = node
	shot("npc")
	typeLine(c.who, node.say)
	if c ~= cur then
		return
	end
	showChoices(node.opts, function(i)
		pick(i)
	end)
end

local function close()
	local c = cur
	if not c then
		return
	end
	cur = nil
	ContextActionService:UnbindAction("ConvLeave")
	hideChoices()
	task.spawn(function()
		Remote.call("conv_close")
	end)
	TweenService:Create(c.r.top, TweenInfo.new(0.3), { Position = UDim2.new(0, 0, -0.09, 0) }):Play()
	TweenService:Create(c.r.bottom, TweenInfo.new(0.3), { Position = UDim2.new(0, 0, 1.09, 0) }):Play()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if hum then
		cam.CameraSubject = hum
	end
	if root then
		root.Anchored = false
	end
	if UI.gui then
		UI.gui.Enabled = true
	end
	pcall(function()
		GuiService.TouchControlsEnabled = true
	end)
	showFriends(c.hidden)
	task.delay(0.3, function()
		if not cur then
			gui.Enabled = false
			bars.Enabled = false
			gui:ClearAllChildren()
			bars:ClearAllChildren()
		end
	end)
end
Conversation.close = close

local function finish(ended)
	local c = cur
	if not c then
		return
	end
	shot("wide")
	typeLine(c.who, ended.line)
	if c ~= cur then
		return
	end
	UI.sound(ended.tier == "good" and "LevelUp" or (ended.tier == "bad" and "SadTrombone" or "NotificationPing"), 0.6)
	showChoices({ "✓ " .. ended.result .. "  ·  " .. T.Done }, function()
		close()
	end)
end

pick = function(i: number)
	local c = cur
	if not c or c.busy then
		return
	end
	c.busy = true
	hideChoices()
	local said = c.node.opts[i]
	local result
	task.spawn(function()
		result = Remote.call("conv_pick", { i = i })
	end)
	shot("me")
	typeLine(T.You, said)
	while c == cur and result == nil do
		task.wait()
	end
	if c ~= cur then
		return
	end
	c.busy = false
	if not result or not result.ok then
		close()
		return
	end
	if result.slam then
		objection()
	end
	setMeter(result.meter)
	if result.delta > 0 then
		floatText("▲ " .. c.meterName, Color3.fromRGB(125, 255, 176))
	elseif result.delta < 0 then
		floatText("▼ " .. c.meterName, Color3.fromRGB(255, 125, 154))
	end
	if result.next then
		task.wait(0.3)
		sayNode(result.next)
	elseif result.ended then
		task.wait(0.4)
		finish(result.ended)
	end
end

---------------------------------------------------------------------
-- Open
---------------------------------------------------------------------
function Conversation.open(d)
	if cur then
		close()
	end
	UI.closeModal()
	local r = build()
	cur = { r = r, who = d.who, meterName = d.meterName, stand = d.stand, npc = d.npc, wide = d.wide }
	local c = cur
	r.meterName.Text = d.meterName
	r.fill.Size = UDim2.new(math.clamp(d.meter / 100, 0, 1), 0, 1, 0)
	setMeter(d.meter)
	r.sub.Activated:Connect(function()
		if cur then
			cur.skip = true
		end
	end)
	r.leave.Activated:Connect(close)
	-- controller B / Backspace also leave
	ContextActionService:BindActionAtPriority("ConvLeave", function(_, state)
		if state == Enum.UserInputState.Begin then
			close()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.ButtonB, Enum.KeyCode.Backspace)
	if d.seen then
		r.name.Text = T.Fast
	end
	-- hold still and hide the normal HUD
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		task.delay(0.15, function()
			if c == cur then
				root.Anchored = true
			end
		end)
	end
	if UI.gui then
		UI.gui.Enabled = false
	end
	cur.hidden = hideFriends()
	gui.Enabled = true
	bars.Enabled = true
	pcall(function()
		GuiService.TouchControlsEnabled = false
	end)
	TweenService:Create(r.top, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Position = UDim2.new(0, 0, 0, 0) }):Play()
	TweenService:Create(r.bottom, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Position = UDim2.new(0, 0, 1, 0) }):Play()
	UI.sound("ImportantSlam", 0.5)
	shot("wide")
	task.spawn(function()
		task.wait(CC.OpenDelay)
		if c == cur then
			sayNode(d.node)
		end
	end)
end

---------------------------------------------------------------------
-- 1.9.1 Vs Mode as a cutscene (big ideas #8, user: "make the dumb versus smart have actual cutscenes
-- with dialogue options like the school ones, like the lawsuit with a big objection").
-- SocialService still runs the session; this only shows it: cinema bars, camera cuts between you and
-- the other side, choices bottom-left (1/2/3), typed lines, and a big OBJECTION! slam in court.
-- Leave closes the cutscene; the rest of the session then shows in the old pop-up.
---------------------------------------------------------------------
local vsOff = {} -- [sessionId] = true once the player left the cutscene

local function vsRun(fn)
	local c = cur
	if not c or not c.vs then
		return
	end
	table.insert(c.queue, fn)
	if c.running then
		return
	end
	c.running = true
	task.spawn(function()
		while c == cur and #c.queue > 0 do
			local f = table.remove(c.queue, 1)
			pcall(f)
		end
		c.running = false
	end)
end

local function isSlam(text: string?): boolean
	return text ~= nil and string.find(string.upper(text), "OBJECTION", 1, true) ~= nil
end

-- type the newest line of the story (what the other side just did)
local function vsLatest(d)
	local c = cur
	local list = d.transcript or {}
	local last = list[#list]
	if c and last and last ~= c.lastLine then
		c.lastLine = last
		shot("wide")
		if isSlam(last) then
			objection()
		end
		typeLine("🎬", last)
	end
end

function Conversation.vsActive(sessionId): boolean
	return cur ~= nil and cur.vs == true and cur.sessionId == sessionId
end

function Conversation.vsWanted(sessionId): boolean
	return not vsOff[sessionId] and (cur == nil or (cur.vs and cur.sessionId == sessionId))
end

function Conversation.vsStart(d)
	if cur then
		close()
	end
	UI.closeModal()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local r = build()
	local me = root.CFrame
	-- the other side: the partner's character if they're close, else a spot in front of you
	local other = d.partnerId and Players:GetPlayerByUserId(d.partnerId)
	local oroot = other and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
	local npc = me * CFrame.new(0, 0, -7) * CFrame.Angles(0, math.pi, 0)
	local alone = true
	if oroot and (oroot.Position - me.Position).Magnitude < 40 then
		npc = oroot.CFrame
		alone = false
	end
	local mid = (me.Position + npc.Position) / 2
	local wide = mid + me.RightVector * 12 + Vector3.new(0, 6, 0)
	cur = { alone = alone, r = r, vs = true, sessionId = d.sessionId, who = tostring(d.partner), meterName = tostring(d.title), stand = me, npc = npc, wide = wide, queue = {} }
	local c = cur
	r.meterName.Text = tostring(d.title)
	r.fill.Size = UDim2.new(0, 0, 1, 0)
	r.sub.Activated:Connect(function()
		if cur then
			cur.skip = true
		end
	end)
	r.leave.Activated:Connect(function()
		vsOff[c.sessionId] = true
		close()
	end)
	ContextActionService:BindActionAtPriority("ConvLeave", function(_, state)
		if state == Enum.UserInputState.Begin then
			vsOff[c.sessionId] = true
			close()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.ButtonB, Enum.KeyCode.Backspace)
	task.delay(0.15, function()
		if c == cur then
			root.Anchored = true
		end
	end)
	if UI.gui then
		UI.gui.Enabled = false
	end
	cur.hidden = hideFriends()
	gui.Enabled = true
	bars.Enabled = true
	pcall(function()
		GuiService.TouchControlsEnabled = false
	end)
	TweenService:Create(r.top, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Position = UDim2.new(0, 0, 0, 0) }):Play()
	TweenService:Create(r.bottom, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Position = UDim2.new(0, 0, 1, 0) }):Play()
	UI.sound("ImportantSlam", 0.5)
	shot("wide")
	vsRun(function()
		task.wait(CC.OpenDelay)
		typeLine("🎭 " .. tostring(d.role) .. " vs " .. tostring(d.partner), tostring(d.text))
	end)
	return true
end

function Conversation.vsStep(d)
	vsRun(function()
		local c = cur
		vsLatest(d)
		if c ~= cur then
			return
		end
		c.r.meterName.Text = string.format("%s  %d/%d", tostring(d.title), d.round or 1, d.rounds or 1)
		c.r.fill.Size = UDim2.new(math.clamp((d.round or 1) / (d.rounds or 1), 0, 1), 0, 1, 0)
		shot(c.alone and "wide" or "npc") -- test fix: an NPC partner has no body to film
		typeLine("🎬 " .. tostring(d.role), tostring(d.prompt))
		if c ~= cur then
			return
		end
		local answered = false
		local deadline = os.clock() + (d.seconds or 15)
		showChoices(d.options or {}, function(i)
			if answered then
				return
			end
			answered = true
			hideChoices()
			task.spawn(function()
				Remote.call("social_answer", { sessionId = d.sessionId, choice = i })
			end)
			shot("me")
			if isSlam(d.options[i]) then
				objection()
			end
			typeLine(T.You, d.options[i])
		end)
		while c == cur and not answered and os.clock() < deadline do
			task.wait(0.1)
		end
		if c == cur and not answered then
			hideChoices() -- time's up: the server picks for you
		end
		while c == cur and answered and c.r.opts.Visible do
			task.wait(0.1)
		end
	end)
end

function Conversation.vsWait(d)
	vsRun(function()
		vsLatest(d)
		if cur then
			shot(cur.alone and "wide" or "npc")
			typeLine(tostring(d.partner), "⏳ " .. tostring(d.text))
		end
	end)
end

function Conversation.vsEnd(d)
	vsRun(function()
		local c = cur
		local lines = d.lines or {}
		shot("wide")
		for i = math.max(1, #lines - 1), #lines do
			if c ~= cur then
				return
			end
			if lines[i] ~= c.lastLine then
				c.lastLine = lines[i]
				if isSlam(lines[i]) then
					objection()
				end
				typeLine("🎬", lines[i])
			end
		end
		if c == cur then
			UI.sound("LevelUp", 0.5)
			showChoices({ "✓ " .. T.Done }, function()
				close()
			end)
		end
	end)
end

function Conversation.isOpen(): boolean
	return cur ~= nil
end

---------------------------------------------------------------------
-- Prompt text per path ("Get checked" on Lose, "See a patient" on Gain...)
---------------------------------------------------------------------
local lastPath = nil
local function labelOne(pp: ProximityPrompt, path: string?)
	if pp:GetAttribute("LoseAction") or pp:GetAttribute("GainAction") then
		-- not for your path (or no path yet): just "Talk"
		pp.ActionText = (path and pp:GetAttribute(path .. "Action")) or Content.Rooms.Talk
	end
end
local function relabel(path: string?)
	local rooms = workspace:FindFirstChild("Rooms")
	if not rooms then
		return
	end
	for _, pp in ipairs(rooms:GetDescendants()) do
		if pp:IsA("ProximityPrompt") then
			labelOne(pp, path)
		end
	end
end

function Conversation.onState(st)
	if st.path ~= lastPath then
		lastPath = st.path
		relabel(st.path)
	end
end

Remote.on("conv_open", Conversation.open)
Remote.on("conv_close", close)
task.spawn(function()
	local rooms = workspace:WaitForChild("Rooms", 30)
	if rooms then
		-- the rooms may arrive after the first state: label what's already there,
		-- and again shortly after (attributes can replicate a moment later)
		relabel(lastPath)
		task.delay(3, function()
			relabel(lastPath)
		end)
		rooms.DescendantAdded:Connect(function(d)
			if d:IsA("ProximityPrompt") then
				task.defer(labelOne, d, lastPath)
			end
		end)
	end
end)

return Conversation

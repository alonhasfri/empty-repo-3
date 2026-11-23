-- ClientMain: starts the player's screen (HUD, menus, styles, effects)
-- and listens to the server. Supports touch, keyboard/mouse and controllers.

local ContextActionService = game:GetService("ContextActionService")

local Client = script.Parent:WaitForChild("Client")
local UI = require(Client.UI)
local Remote = require(Client.Remote)
local Hud = require(Client.Hud)
local Stations = require(Client.Stations)
local Style = require(Client.Style)
local Effects = require(Client.Effects)
local AdminPanel = require(Client.AdminPanel)
local Tutorial = require(Client.Tutorial)
local Conversation = require(Client.Conversation)

Hud.onMenu = Stations.settings
Hud.onAdmin = AdminPanel.open
Hud.onStation = function(key)
	if key == "map" or key == "gadgets" or key == "together" or key == "phone" or key == "space" then
		Stations.open(key)
		return
	end
	local r = Remote.call("station", { key = key })
	if r.ok then
		Stations.open(key)
	elseif r.msg then
		UI.toast("⛔ " .. r.msg, UI.Colors.bad)
	end
end
Hud.onChoosePath = function(path)
	local r = Remote.call("choose_path", { path = path })
	if r and r.msg then
		UI.toast(r.msg)
	end
end
AdminPanel.onDebug = Hud.toggleDebug
Stations.dragCounter = Hud.dragCounter
-- Guided tutorial (1.4): Stations report what the player did, the tutorial reacts
Stations.onEvent = function(name)
	Tutorial.event(name)
	if name == "shop" then
		Tutorial.onShop()
	end
end
Hud.onTutorialEvent = Tutorial.event
-- 1.5: Unstuck button
Hud.onUnstuck = function()
	if Conversation.isOpen() then
		Conversation.close()
	end
	local r = Remote.call("unstuck")
	if r and r.msg then
		UI.toast(r.msg, r.ok and UI.Colors.good or nil)
	end
end
Tutorial.target = Hud.target
Stations.onReplayTutorial = Tutorial.replay
Stations.route = function(key)
	Hud.onStation(key)
end
Hud.onBuyPass = function(key)
	Stations.buyPass(key)
end
Hud.onSaveSettings = function(changes)
	for k, v in pairs(changes) do
		UI.settings[k] = v
	end
	Remote.call("settings", UI.settings)
end
Tutorial.save = Hud.onSaveSettings

---------------------------------------------------------------------
-- Server -> client events
---------------------------------------------------------------------
local function applyState(st)
	if not st then
		return
	end
	-- Town style timeline (what the world looks like) and the matching UI theme
	st.realTier = st.tier
	local look
	if st.path == "Gain" then
		if st.cells < 45e9 then
			look = "nonsense" -- Comeback mode's very start
		elseif st.iq < 95 then
			look = "cashgrab"
		elseif st.iq < 120 then
			look = "cozy"
		elseif st.iq < 135 then
			look = "realistic"
		elseif st.iq < 200 then
			look = "fancy"
		else
			look = "future" -- 1.4: Bloxburg plus futuristic touches
		end
	else
		if st.cells >= 70e9 then
			look = "cozycash" -- lobby + start of the Lose path
		elseif st.cells >= 45e9 then
			look = "cashgrab"
		else
			look = "nonsense"
		end
	end
	st.look = look
	local UI_THEME = { cozycash = "cashgrab", cashgrab = "cashgrab", nonsense = "nonsense", cozy = "cozy", realistic = "smart", fancy = "genius", future = "genius" }
	st.tier = UI_THEME[look]
	UI.state = st
	if st.settings then
		UI.settings = st.settings
	end
	Hud.update(st)
	Style.apply(st)
	Tutorial.onState(st)
	Conversation.onState(st)
end

Remote.on("state", applyState)

Remote.on("delta", function(d)
	Hud.delta(d.amount, d.up)
	UI.sound(d.up and "BrainCellGained" or "BrainCellLost", 0.5)
end)

Remote.on("narrator", function(d)
	Hud.say(d.text, d.mood)
end)

Remote.on("toast", function(d)
	UI.toast(d.text)
	UI.sound(d.sound)
end)

Remote.on("badge", Effects.badge)

Remote.on("openStation", function(d)
	Stations.open(d.station)
end)

Remote.on("reading", Stations.reading)
Remote.on("confirmSwitch", Stations.confirmSwitch)
Remote.on("warning", Stations.warning)
Remote.on("hide", Stations.hide)

Remote.on("death", function(d)
	UI.closeModal()
	Effects.death(d, function()
		Stations.deathScreen(d)
	end)
end)

Remote.on("deathScreen", function()
	Stations.deathScreen({})
end)

Remote.on("banCutscene", Effects.banCutscene)
Remote.on("viral", Effects.viral)
Remote.on("confetti", Effects.confetti)
Remote.on("friendsLaugh", Style.friendsLaugh)
Remote.on("kazoo", function(d)
	Style.kazoo(d.seconds or 60)
end)
Remote.on("weather", function(d)
	Style.weather(d.kind, d.seconds or 60)
end)
Remote.on("debug", Hud.toggleDebug)
Remote.on("swapDoors", Hud.swapDoorSigns)
Stations.openDoors = Hud.openDoors

-- Jobs and secret inventions
Remote.on("workMarker", function(d)
	Style.workMarker(d.pos, d.name)
end)
Remote.on("lowGravity", function(d)
	Style.lowGravity(d.seconds or 30)
end)
local function showEureka(choices)
	Effects.eureka(choices, function(key)
		local r = Remote.call("invention_choose", { key = key })
		if r.ok then
			Effects.inventionUnlocked(r)
		end
	end)
end
Remote.on("eureka", function(d)
	showEureka(d.choices)
end)

-- Update 1.3: Inventors
Remote.on("prize", function(d)
	Effects.prize(d, function()
		local r = Remote.call("prize_refuse")
		if r and r.msg then
			UI.toast(r.msg, UI.Colors.gold, 6)
		end
	end)
end)
Remote.on("testDay", Effects.testDay)
-- 1.6 careers
Remote.on("promoted", Effects.promoted)
Remote.on("reportCard", Stations.reportCard)
-- 1.6 animal forms
Remote.on("transform", Effects.transform)
Hud.onPower = function()
	local r = Remote.call("animal_power")
	if r and r.msg then
		UI.toast(r.msg)
	end
	if r and r.ok and r.power == "buzz" then
		local root = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, r.up or 55, v.Z)
		end
	end
end
-- 1.6 school objective banner
Remote.on("objective", function(d)
	Hud.objective(d.text)
end)
Remote.on("freeTaxi", function()
	Stations.map(true)
end)
Remote.on("inventionGift", Effects.inventionUnlocked)

-- Admin extras
Remote.on("quiz", Stations.quiz)
Remote.on("spectate", function(d)
	local cam = workspace.CurrentCamera
	local target = d.userId and game:GetService("Players"):GetPlayerByUserId(d.userId)
	local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	local myHum = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	cam.CameraSubject = hum or myHum
end)

-- Update 1.1: Comeback
Remote.on("comebackCutscene", Effects.comeback)
Remote.on("makeover", Effects.makeover)
Remote.on("friendVisit", function(d)
	Style.friendVisit(d.lines, d.seconds or 12)
end)

-- Update 1.2: Smart vs Dumb
Remote.on("social_start", Stations.socialStart)
Remote.on("social_step", Stations.socialStep)
Remote.on("social_wait", Stations.socialWait)
Remote.on("social_end", Stations.socialEnd)
Remote.on("sued", Stations.sued)
Remote.on("election_speech", Stations.electionSpeech)
Remote.on("election_vote", Stations.electionVote)
Remote.on("election_result", function(d)
	UI.toast(d.text, UI.Colors.gold, 10)
	Effects.confetti()
	UI.sound("GameShowJingle")
end)

-- Update 1.4: Space and secrets
Remote.on("launch", function(d)
	UI.closeModal()
	task.spawn(Effects.launch, d)
end)
Remote.on("worldsSmartest", function(d)
	task.spawn(Effects.worldsSmartest, d)
end)
Remote.on("retiredQuestion", Stations.retiredQuestion)
Remote.on("voidFall", function()
	UI.closeModal()
	task.spawn(Effects.voidFall)
end)
Remote.on("castleEnter", function()
	task.spawn(Effects.castleEnter)
end)
Remote.on("castleStep", Style.castleStep)
Remote.on("tutorialReset", function()
	Tutorial.reset()
	UI.toast("📖 Your tutorial was reset by staff.")
end)
Remote.on("castleWallOpen", Style.castleWallOpen)

Remote.on("announce", function(d)
	UI.toast((d.global and "📢 GLOBAL: " or "📢 ") .. tostring(d.text) .. "  (" .. tostring(d.by) .. ")", Color3.fromRGB(40, 60, 120), 8)
	UI.sound("GameShowJingle")
end)

---------------------------------------------------------------------
-- Controller and keyboard shortcuts
---------------------------------------------------------------------
ContextActionService:BindAction("BrainMenu", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		if UI.isModalOpen() then
			UI.closeModal()
		else
			Stations.settings()
		end
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonY, Enum.KeyCode.M)

-- 1.6: animal power (F on keyboard, X on a controller)
ContextActionService:BindAction("AnimalPower", function(_, inputState)
	if inputState == Enum.UserInputState.Begin and Hud.onPower and Hud.hasPower() then
		Hud.onPower()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonX)

ContextActionService:BindAction("BrainAdmin", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		if UI.isModalOpen() then
			UI.closeModal()
		else
			AdminPanel.open()
		end
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonSelect, Enum.KeyCode.P)

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
task.spawn(function()
	for _ = 1, 20 do
		local r = Remote.call("hello")
		if r and r.ok and r.state then
			applyState(r.state)
			-- left during a Eureka cutscene? offer it again
			local e = Remote.call("eureka_pending")
			if e and e.ok and e.choices then
				showEureka(e.choices)
			end
			break
		end
		task.wait(1)
	end
end)

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
local PhoneOS = require(Client.PhoneOS) -- 1.7: the phone changes with your brain
local _Bits = require(Client.Bits) -- 1.9.3: brain bits on the streets
local Machines = require(Client.Machines) -- 1.9.3: inventable hotbar machines (Trace Teleporter, Jetpack, Bounce Pad)
local Cutscene = require(Client.Cutscene) -- 1.9: cutscene player (intro flyover)

-- 1.7: the brain-tiered phone replaces the old one (kept as the "Simple phone" setting)
PhoneOS.stations = Stations
PhoneOS.classicPhone = Stations.phone
Stations.phone = PhoneOS.open
-- 1.7: Lose-path effects (scrambled labels, brain lag, joke ads)
local LoseFX = require(Client.LoseFX)
PhoneOS.label = LoseFX.label
PhoneOS.beforeOpen = LoseFX.beforeOpen
LoseFX.isBusy = function()
	return Conversation.isOpen()
end
LoseFX.start()
-- 1.7: animals get a wordless icon menu with a smell trail instead of the phone
local AnimalUI = require(Client.AnimalUI)
local Guide = require(Client.Guide)
local _RoomGuide = require(Client.RoomGuide) -- 1.9.1: "what to do here" inside buildings (runs on its own)
local _DumbSigns = require(Client.DumbSigns) -- 1.9.1: wrong-way signs at a really low brain (runs on its own)
local _Weather = require(Client.Weather) -- 1.9.1: rain, snow, fog, puddles (runs on its own)
local _NpcReact = require(Client.NpcReact) -- 1.9.1: townspeople react to your brain level (runs on its own)
local _QoL = require(Client.QoL) -- 1.9.1: sprint, AFK-safe (runs on its own)
local LowGraphics = require(Client.LowGraphics)
local Watchdog = require(Client.Watchdog) -- 1.8.8: frees you if something left you stuck
-- locks that are on purpose: the watchdog leaves these alone
Watchdog.isLocked = function(): boolean
	local lp = game:GetService("Players").LocalPlayer
	return Conversation.isOpen() or Cutscene.isPlaying() or Machines.isBusy() or lp:GetAttribute("AdminFrozen") == true or (UI.state ~= nil and UI.state.dead == true)
end
local SpeedrunTimer = require(Client.SpeedrunTimer)
local DayNight = require(Client.DayNight)
local _Horror = require(Client.Horror) -- 1.7.3: The Average Files (listens on its own)
local _HighFive = require(Client.HighFive) -- 1.8: friends meter (listens on its own)
PhoneOS.animalUI = AnimalUI.open
Remote.on("animalTarget", AnimalUI.onTarget) -- 1.9.1 animal jobs and friends
local Adopt = require(Client.Adopt) -- 1.9.1 adopt an animal player
Remote.on("adoptAsk", Adopt.onAsk)
Remote.on("expAsk", Adopt.onExpAsk) -- 1.9.1 a Scientist invites an animal into an experiment
Remote.on("geniusFinale", Effects.geniusFinale) -- 1.9.1 genius endings
local InventionHall = require(Client.InventionHall) -- 1.9.1 hover the inventions + the tour
Remote.on("inventionTour", InventionHall.tour)
AnimalUI.hasPower = function()
	return Hud.hasPower()
end
AnimalUI.onPower = function()
	if Hud.onPower then
		Hud.onPower()
	end
end

Hud.onMenu = Stations.settings
Hud.onAdmin = AdminPanel.open
Hud.onStation = function(key)
	if key == "items" then -- 1.9.3: the rail's Items button
		PhoneOS.items()
		return
	end
	if key == "map" or key == "gadgets" or key == "together" or key == "phone" or key == "space" or key == "quickplay" or key == "events" or key == "genius" then
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
	Watchdog.freeNow(false) -- 1.8.8: Unstuck also clears every local lock (anchor, sit, camera, hidden thumbstick)
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
local introChecked = false
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
	AnimalUI.onState(st)
	Guide.onState(st)
	LowGraphics.onState(st)
	SpeedrunTimer.onState(st)
	DayNight.onState(st)
	-- 1.9: the first time you join (no path yet), a short skippable flyover to the two doors
	if not introChecked and st.settings then
		introChecked = true
		if st.path == nil and not st.dead and not st.settings.introSeen then
			Cutscene.intro(function()
				Hud.onSaveSettings({ introSeen = true })
			end)
		end
	end
end

Remote.on("state", applyState)

-- 1.8.2: the slow-device check switched Low detail on: simplify the style too and say so once
LowGraphics.onAuto = function()
	if UI.state then
		Style.apply(UI.state)
	end
	UI.toast(require(game:GetService("ReplicatedStorage").Shared.Content).Settings17.LowGraphicsAuto)
end

-- 1.7.3: the first big moment of a run: title + shake (the big number comes with the delta)
Remote.on("firstWow", function(d)
	local FW = require(game:GetService("ReplicatedStorage").Shared.Content).FirstWow
	UI.toast(d.up and FW.Gain or FW.Lose, d.up and UI.Colors.good or UI.Colors.bad, 4)
	UI.sound(d.up and "LevelUp" or "CartoonBoing", 0.7)
end)

Remote.on("delta", function(d)
	Hud.delta(d.amount, d.up, d.iq, d.pct)
	UI.sound(d.up and "BrainCellGained" or "BrainCellLost", 0.5)
end)

Remote.on("narrator", function(d)
	Hud.say(d.text, d.mood)
end)

-- 1.9.3 harsh review #3: server news (birthdays, Golden Brain, events…) covered pop-ups and scenes.
-- It now waits in a queue while a pop-up, the phone or a full-screen scene is open (at most
-- Config.UI.ToastHoldMax seconds), then shows. Your own button feedback still shows at once.
local CONFIG_UI = require(game:GetService("ReplicatedStorage").Shared.Config).UI
local toastQueue = {}
local function screenBusy(): boolean
	if not UI.gui then
		return false
	end
	if UI.gui:FindFirstChild("ModalBackdrop") then
		return true
	end
	for _, c in ipairs(UI.gui:GetChildren()) do
		if c:IsA("Frame") and c.Visible and c.ZIndex >= 60 then -- Effects overlays (cutscenes, big moments)
			return true
		end
	end
	return false
end
Remote.on("toast", function(d)
	if screenBusy() then
		table.insert(toastQueue, { text = d.text, sound = d.sound, t = os.clock() })
		return
	end
	UI.toast(d.text)
	UI.sound(d.sound)
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		if #toastQueue > 0 and (not screenBusy() or os.clock() - toastQueue[1].t > CONFIG_UI.ToastHoldMax) then
			local q = table.remove(toastQueue, 1)
			UI.toast(q.text)
			UI.sound(q.sound)
			task.wait(1.2) -- one at a time, not a pile
		end
	end
end)

Remote.on("badge", Effects.badge)

Remote.on("crossroads", function(d)
	Stations.crossroads(d)
end)
Remote.on("openStation", function(d)
	Stations.open(d.station)
end)

Remote.on("reading", Stations.reading)
Remote.on("confirmSwitch", Stations.confirmSwitch)
Remote.on("warning", Stations.warning)
Remote.on("hide", Stations.hide)

Remote.on("death", function(d)
	UI.closeModal()
	AdminPanel.close() -- morning test fix: the 🧪 replay is started from the staff panel, which hid the POOF and shredder
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
-- 1.9 test command: set the time of day on this screen (nil = back to the normal cycle)
Remote.on("timeOfDay", function(d)
	game:GetService("Lighting"):SetAttribute("TestClock", d and d.hour or nil)
end)
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
-- 1.9.1 big ideas #8: Vs Mode plays as a cutscene (Conversation.vs*); the old pop-ups are the fallback
local VS_CUTSCENE = require(game:GetService("ReplicatedStorage").Shared.Config).VsCutscene == true
Remote.on("social_start", function(d)
	if not (VS_CUTSCENE and Conversation.vsWanted(d.sessionId) and Conversation.vsStart(d)) then
		Stations.socialStart(d)
	end
end)
Remote.on("social_step", function(d)
	if Conversation.vsActive(d.sessionId) then
		Conversation.vsStep(d)
	else
		Stations.socialStep(d)
	end
end)
Remote.on("social_wait", function(d)
	if Conversation.vsActive(d.sessionId) then
		Conversation.vsWait(d)
	else
		Stations.socialWait(d)
	end
end)
Remote.on("social_end", function(d)
	if Conversation.vsActive(d.sessionId) then
		Conversation.vsEnd(d)
	else
		Stations.socialEnd(d)
	end
end)
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

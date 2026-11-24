-- HorrorService.lua (1.7.3): "The Average Files", part 1 (ported from web/src/horror.js).
-- A slow, kid-safe mystery about the Perfectly Average Guy. Same for dumb, smart and animal players.
--   stage 0: normal
--   stage 1: (after a few minutes on a path, sooner if you talked to him) notes start appearing; he's sometimes seen far away
--   stage 2: (3 notes) more notes, more sightings
--   stage 3: (5 notes) the last notes. (Part 2, not built yet: the phone call, The Mean, the final talk and 3 endings.)
-- Settings → 😐 Horror: Off / Spooky (default, never a jump scare) / Full (jump scares allowed; part 1 has none anyway).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local HorrorService = {}
local CH = Config.Horror
local TH = Content.Horror

local function hz(data)
	if typeof(data.horror) ~= "table" then
		data.horror = { stage = 0, notes = {}, talks = 0, time = 0 }
	end
	local h = data.horror
	h.stage = tonumber(h.stage) or 0
	h.notes = typeof(h.notes) == "table" and h.notes or {}
	h.talks = tonumber(h.talks) or 0
	h.time = tonumber(h.time) or 0
	return h
end

local function setting(data): string
	local s = data.settings and data.settings.horror
	if s == "off" or s == "full" then
		return s
	end
	return "spooky"
end

local function on(data): boolean
	return data.path ~= nil and not data.dead and setting(data) ~= "off"
end

local function count(t): number
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

local function sendState(player, data)
	local h = hz(data)
	Net.send(player, "horrorState", { stage = on(data) and h.stage or 0, notes = h.notes, setting = setting(data) })
end

local function advance(player, data)
	local h = hz(data)
	local n = count(h.notes)
	local st = h.stage
	if st == 0 and (h.time > CH.Stage1After or (h.talks >= 1 and h.time > CH.Stage1AfterTalk)) then
		st = 1
	end
	if st == 1 and n >= CH.NotesForStage2 then
		st = 2
	end
	if st == 2 and n >= CH.NotesForStage3 then
		st = 3
	end
	if st ~= h.stage then
		h.stage = st
		if TH.StageToast[st] then
			BrainService.toast(player, TH.StageToast[st], "NotificationPing")
		end
		sendState(player, data)
	end
end

-- Called by GainService when you talk to the Perfectly Average guy
function HorrorService.talked(player)
	local data = DataService.get(player)
	if data then
		local h = hz(data)
		h.talks += 1
		advance(player, data)
	end
end

-- Note spots: next to things that already exist (found by name once the town is built)
local function buildNotes()
	local folder = Instance.new("Folder")
	folder.Name = "AverageNotes"
	folder.Parent = workspace
	for i, spot in ipairs(CH.NoteSpots) do
		local anchor = workspace:FindFirstChild(spot.near, true)
		if anchor and anchor:IsA("BasePart") then
			local p = Instance.new("Part")
			p.Name = "AverageNote_" .. i
			p.Size = Vector3.new(1.2, 0.1, 1.6)
			p.Anchored = true
			p.CanCollide = false
			p.Color = Color3.fromRGB(235, 228, 205) -- beige paper
			p.Material = Enum.Material.SmoothPlastic
			p.CFrame = CFrame.new(anchor.Position + spot.offset) * CFrame.Angles(0, math.rad(17 * i), 0)
			p.Transparency = 1 -- every player sees only the notes they can find (client shows them)
			p:SetAttribute("NoteIndex", i)
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = TH.ReadNote
			pp.ObjectText = TH.NoteObject
			pp.MaxActivationDistance = 8
			pp.RequiresLineOfSight = false
			-- on for everyone on the server; each client hides the notes it can't find yet (the server re-checks anyway)
			pp.Parent = p
			p.Parent = folder
			pp.Triggered:Connect(function(player)
				local data = DataService.get(player)
				if not data or not on(data) then
					return
				end
				local h = hz(data)
				if h.stage < (CH.NoteGate[i] or 1) or h.notes[tostring(i)] then
					return
				end
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not root or (root.Position - p.Position).Magnitude > 12 then
					return
				end
				h.notes[tostring(i)] = true
				local animal = Brain.stage(data.cells, BrainService.secretAnimals).key ~= "human"
					and Brain.stage(data.cells, BrainService.secretAnimals).key ~= "barelyhuman"
				Net.send(player, "horrorNote", { index = i, total = #CH.NoteSpots, animal = animal })
				advance(player, data)
				sendState(player, data)
			end)
		end
	end
end

function HorrorService.start()
	task.defer(buildNotes)
	-- play time on a path moves the story along (only while the setting isn't Off)
	task.spawn(function()
		while true do
			task.wait(5)
			for _, p in ipairs(Players:GetPlayers()) do
				local data = DataService.get(p)
				if data and on(data) then
					local h = hz(data)
					h.time += 5
					advance(p, data)
				end
			end
		end
	end)
	Net.on("horror_state", function(player)
		local data = DataService.get(player)
		if data then
			sendState(player, data)
		end
		return { ok = true }
	end)
	Net.on("horror_setting", function(player, d)
		local data = DataService.get(player)
		if not data or (d.value ~= "off" and d.value ~= "spooky" and d.value ~= "full") then
			return { ok = false }
		end
		data.settings.horror = d.value
		sendState(player, data)
		return { ok = true, value = d.value }
	end)
end

return HorrorService

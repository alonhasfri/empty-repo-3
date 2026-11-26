-- SchoolService (update 1.6): SCHOOL for the Lose path (from web/src/v16.js).
-- Every so often the school bell rings for human Lose players. Get to the School in
-- time and you sit in class (act dumb: sleep, throw paper, fail the pop quiz).
-- Too late, and a cartoon truant officer walks after you: get caught and he walks you
-- to class (embarrassing), or out-run him and you escaped. Animals can't go to school.
-- Text: Content.School. Numbers: Config.School.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local FriendService = require(script.Parent.FriendService)
local Rooms = require(script.Parent.Rooms)

local SchoolService = {}

local CS = Config.School
local T = Content.School
local SCHOOL_KEY = "gain" -- the School building's key in Rooms.Buildings

local state = {} -- [player] = { nextBell, phase = nil/"go"/"chase"/"in", deadline, officer }

local function objective(player, text: string?)
	Net.send(player, "objective", { text = text })
end

local function rootOf(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function inSchool(player): boolean
	local root = rootOf(player)
	return root ~= nil and Rooms.buildingAt(root.Position) == SCHOOL_KEY
end

-- Can this player go to school right now? (Lose path, alive, human)
local function eligible(player): boolean
	local data = DataService.get(player)
	return data ~= nil and data.path == "Lose" and not data.dead and not Rooms.isAnimal(player)
end

local function removeOfficer(s)
	if s.officer then
		s.officer:Destroy()
		s.officer = nil
	end
end

local function makeOfficer(near: Vector3)
	local m = FriendService.npc("TruantOfficer", Color3.fromRGB(232, 185, 143), Color3.fromRGB(30, 58, 138), Color3.fromRGB(17, 17, 17))
	if m then
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end
		local hum = m:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	else
		m = Instance.new("Model")
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Size = Vector3.new(2, 5, 1.2)
		p.Color = Color3.fromRGB(30, 58, 138)
		p.Parent = m
		m.PrimaryPart = p
	end
	m.Name = "TruantOfficer"
	local head = m:FindFirstChild("Head") or m.PrimaryPart
	if head then
		local g = Instance.new("BillboardGui")
		g.Size = UDim2.new(6, 0, 1.2, 0)
		g.StudsOffset = Vector3.new(0, 2.5, 0)
		g.MaxDistance = 120
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = Color3.fromRGB(150, 200, 255)
		l.TextStrokeTransparency = 0.2
		l.Text = T.Officer
		l.Parent = g
		g.Parent = head
	end
	m:PivotTo(CFrame.new(near))
	m.Parent = workspace
	return m
end

-- Ring the bell for one player (also used by the admin "schoolbell" command)
function SchoolService.ring(player): boolean
	local s = state[player]
	if not s or not eligible(player) or player:GetAttribute("AFK") then -- 1.9.1: never ring for someone who is away
		return false
	end
	removeOfficer(s)
	s.phase = "go"
	s.deadline = os.clock() + CS.LateAfter
	s.nextBell = os.clock() + CS.BellEvery
	BrainService.toast(player, string.format(T.Bell, CS.LateAfter), "ImportantSlam")
	return true
end

local function startClass(player, s)
	removeOfficer(s)
	s.phase = "in"
	s.deadline = os.clock() + CS.ClassSeconds
	objective(player, T.ClassObjective)
end

local function finish(player, s, text: string?)
	removeOfficer(s)
	s.phase = nil
	objective(player, nil)
	if text then
		BrainService.toast(player, text)
	end
end

local function step(player, s, dt: number)
	local now = os.clock()
	if not eligible(player) then
		if s.phase then
			finish(player, s, nil)
		end
		return
	end
	if not s.phase then
		if now >= s.nextBell then
			SchoolService.ring(player)
		end
		return
	end
	if s.phase == "go" then
		if inSchool(player) then
			BrainService.toast(player, T.InClass)
			startClass(player, s)
		elseif now >= s.deadline then
			local root = rootOf(player)
			if not root then
				return
			end
			s.phase = "chase"
			s.deadline = now + CS.ChaseSeconds
			local away = root.CFrame.LookVector * -CS.OfficerStartDistance
			s.officer = makeOfficer(Vector3.new(root.Position.X + away.X, root.Position.Y, root.Position.Z + away.Z))
			BrainService.toast(player, T.Chase, "ImportantSlam")
			objective(player, T.ChaseObjective)
		else
			objective(player, string.format(T.GoObjective, math.ceil(s.deadline - now)))
		end
	elseif s.phase == "chase" then
		local root = rootOf(player)
		if inSchool(player) then
			BrainService.toast(player, T.InClass)
			startClass(player, s)
			return
		end
		if now >= s.deadline then
			finish(player, s, T.Escaped)
			return
		end
		if not root or not s.officer then
			return
		end
		-- walk straight toward the player (cartoon: walls don't stop him)
		local pos = s.officer:GetPivot().Position
		local target = root.Position
		local flat = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
		local dist = flat.Magnitude
		if dist <= CS.CatchDistance then
			BrainService.embarrass(player, CS.CaughtEmbarrass, T.CaughtMoment)
			BrainService.toast(player, string.format(T.Caught, CS.CaughtEmbarrass), "SadTrombone")
			local spot = Rooms.ConvSpots.classroom
			local char = player.Character
			if spot and char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					Rooms.standUp(hum)
				end
				char:PivotTo(spot.stand * CFrame.new(0, 3, -4))
			end
			startClass(player, s)
			return
		end
		local move = math.min(dist, CS.OfficerSpeed * dt)
		local newPos = pos + flat.Unit * move
		newPos = Vector3.new(newPos.X, target.Y, newPos.Z)
		s.officer:PivotTo(CFrame.lookAt(newPos, Vector3.new(target.X, target.Y, target.Z)))
	elseif s.phase == "in" then
		if now >= s.deadline then
			finish(player, s, T.ClassOver)
		end
	end
end

function SchoolService.start()
	local function add(p)
		state[p] = { nextBell = os.clock() + CS.FirstBellAfter }
	end
	Players.PlayerAdded:Connect(add)
	for _, p in ipairs(Players:GetPlayers()) do
		add(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		local s = state[p]
		if s then
			removeOfficer(s)
		end
		state[p] = nil
	end)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.1)
			local now = os.clock()
			local dt = now - last
			last = now
			for p, s in pairs(state) do
				local ok, err = pcall(step, p, s, dt)
				if not ok then
					warn("[School] " .. tostring(err))
				end
			end
		end
	end)
end

return SchoolService

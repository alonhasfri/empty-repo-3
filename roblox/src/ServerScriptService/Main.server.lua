-- Main: starts every server system and handles players joining and leaving.
-- Lose a Brain Cell / Gain a Brain Cell, update 1.0

local Players = game:GetService("Players")

local Services = script.Parent:WaitForChild("Services")
local Net = require(Services.Net)
local DataService = require(Services.DataService)
local BrainService = require(Services.BrainService)
local WorldService = require(Services.WorldService)
local LoseService = require(Services.LoseService)
local GainService = require(Services.GainService)
local ShopService = require(Services.ShopService)
local AdminService = require(Services.AdminService)
local FriendService = require(Services.FriendService)
local SocialService = require(Services.SocialService)
local ProjectService = require(Services.ProjectService)
local SpaceService = require(Services.SpaceService)
local CastleService = require(Services.CastleService)
local ConversationService = require(Services.ConversationService)
local SchoolService = require(Services.SchoolService)
local _AnimalService = require(Services.AnimalService) -- 1.6 animal powers (listens on its own)
local LifeService = require(Services.LifeService) -- 1.7: Hoppr rides, shifts and payslips, Brain Bank
AdminService.adminInvent = ProjectService.adminInvent
AdminService.runElection = SocialService.runElection
AdminService.ringBell = SchoolService.ring
BrainService.hooks.onStageChange = GainService.applyUniform -- 1.6: no work vest on animals

WorldService.build()

local STATION_PATH = {
	clickbait = "Lose",
	steal = "Lose",
	comments = "Lose",
	scroller = "Lose",
	library = "Gain",
	theater = "Gain",
	gate = "Gain",
	jobs = "Gain",
	coffee = "Gain",
	nap = "Gain",
	pigeons = "Gain",
	work = "Gain",
	lab = "Gain",
	shop = "Any",
}

-- Workplace desks around town
WorldService.onWork = function(player, placeKey)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" then
		BrainService.toast(player, "Jobs are on the Gain path.")
		return
	end
	local myPlace = nil
	for _, j in ipairs(require(game:GetService("ReplicatedStorage").Shared.Content).Jobs) do
		if j.id == data.job then
			myPlace = j.place
		end
	end
	if not myPlace then
		BrainService.toast(player, "💼 Get a job at the Job Center first.")
		return
	end
	if myPlace ~= placeKey then
		BrainService.toast(player, "This isn't your workplace.")
		return
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		BrainService.toast(player, blocked)
		return
	end
	Net.send(player, "openStation", { station = "work" })
end

-- Returns nil if the player may open this station, or a reason why not.
local function stationProblem(player, key: string): string?
	local data = DataService.get(player)
	local path = STATION_PATH[key]
	if not data or not path then
		return "Not available."
	end
	if not data.path then
		return "Pick a path first: Lose or Gain."
	end
	if path ~= "Any" and data.path ~= path then
		return "That's for the " .. path .. " path."
	end
	if key ~= "shop" and key ~= "coffee" and key ~= "nap" and key ~= "pigeons" then
		return BrainService.blocked(player)
	end
	return nil
end

WorldService.onStation = function(player, key)
	local problem = stationProblem(player, key)
	if problem then
		BrainService.toast(player, problem)
		return
	end
	Net.send(player, "openStation", { station = key })
end

-- Activity dock on the screen (open activities from anywhere)
Net.on("station", function(player, d)
	local key = tostring(d.key)
	local problem = stationProblem(player, key)
	if problem then
		return { ok = false, msg = problem }
	end
	return { ok = true }
end)

-- Path picker on the screen (same as walking through a door)
Net.on("choose_path", function(player, d)
	if d.path ~= "Lose" and d.path ~= "Gain" then
		return { ok = false }
	end
	WorldService.enterDoor(player, d.path)
	return { ok = true }
end)
-- 1.5: the Unstuck button. Inside a building -> out the front door; anywhere else -> nearest street spot.
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Rooms = require(Services.Rooms)
local unstuckAt = {}
Net.on("unstuck", function(player)
	local now = os.clock()
	local last = unstuckAt[player]
	if last and now - last < Config.Unstuck.Cooldown then
		return { ok = false, msg = string.format(Content.Unstuck.Wait, math.ceil(Config.Unstuck.Cooldown - (now - last))) }
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return { ok = false }
	end
	unstuckAt[player] = now
	ConversationService.stop(player)
	Rooms.standUp(hum)
	local key = Rooms.buildingAt(root.Position)
	if not (key and WorldService.Spots[key]) then
		local best = math.huge
		key = "lobby"
		for k, spot in pairs(WorldService.Spots) do
			local d = (WorldService.sp(spot) - root.Position).Magnitude
			if d < best then
				best, key = d, k
			end
		end
	end
	WorldService.teleport(player, key)
	return { ok = true, msg = Content.Unstuck.Done }
end)
game:GetService("Players").PlayerRemoving:Connect(function(p)
	unstuckAt[p] = nil
end)

WorldService.onCashGrab = GainService.cashGrab
WorldService.onAverageGuy = GainService.averageGuy

BrainService.hooks.onPathReset = function(player)
	LoseService.reset(player)
	GainService.reset(player)
end

-- a real, finite number (NaN and infinity from a cheating client are refused)
local function isNum(v): boolean
	return typeof(v) == "number" and v == v and math.abs(v) < math.huge
end

Net.on("settings", function(player, d)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local s = data.settings
	if isNum(d.music) then
		s.music = math.clamp(d.music, 0, 1)
	end
	if isNum(d.sfx) then
		s.sfx = math.clamp(d.sfx, 0, 1)
	end
	if d.counterPos == "topleft" or d.counterPos == "topcenter" or d.counterPos == "topright" or d.counterPos == "bottomright" or d.counterPos == "custom" then
		s.counterPos = d.counterPos
	end
	if isNum(d.counterX) and isNum(d.counterY) then
		s.counterX = math.clamp(d.counterX, 0, 0.95)
		s.counterY = math.clamp(d.counterY, 0, 0.95)
	end
	for _, k in ipairs({ "tutLose", "tutGain", "tutLose2", "tutGain2" }) do
		if isNum(d[k]) then
			s[k] = math.clamp(math.floor(d[k]), 1, 30)
		end
	end
	-- guided tutorial (1.4): which notes you've seen (bit mask) + finished flags
	if isNum(d.tutNotes) then
		s.tutNotes = math.clamp(math.floor(d.tutNotes), 0, 2 ^ 30)
	end
	for _, k in ipairs({ "tutLose2Done", "tutGain2Done" }) do
		if typeof(d[k]) == "boolean" then
			s[k] = d[k]
		end
	end
	-- 1.7: Effects intensity (0..1) and the optional "harder life" bills
	if isNum(d.fxIntensity) then
		s.fxIntensity = math.clamp(math.floor(d.fxIntensity * 10 + 0.5) / 10, 0, 1)
	end
	for _, k in ipairs({ "reduceFlashing", "largeText", "extraTime", "counterBig", "hardLife", "classicHud" }) do
		if typeof(d[k]) == "boolean" then
			s[k] = d[k]
		end
	end
	BrainService.push(player)
	return { ok = true }
end)

Net.on("hello", function(player)
	return { ok = true, state = BrainService.state(player) }
end)

local function onPlayerAdded(player: Player)
	local data = DataService.load(player)
	if not player.Parent then
		DataService.release(player)
		return
	end
	if not AdminService.onJoin(player) then
		return
	end
	FriendService.build(player)
	BrainService.setup(player, data)
	if data.inventions and data.inventions.duck then
		player:SetAttribute("DuckPet", true)
	end
	ShopService.checkOwned(player)

	local firstSpawn = true
	local function onCharacter(char)
		local humanoid = char:WaitForChild("Humanoid", 10)
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.2)
		BrainService.applyCharacter(player)
		if firstSpawn then
			firstSpawn = false
			-- come back exactly where you left off
			if data.position and data.path and not data.dead then
				local p = data.position
				char:PivotTo(CFrame.new(p.x, p.y + 3, p.z))
			end
			if data.dead then
				Net.send(player, "deathScreen", {})
			else
				BrainService.narrate(player, "welcome")
			end
		end
		if humanoid then
			humanoid.Died:Connect(function()
				local d = DataService.get(player)
				if d and d.path == "Lose" and not d.dead then
					-- fell or reset: no penalty, just a dumb moment
					BrainService.embarrass(player, 5, "Fell over for no reason")
				end
			end)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	DataService.release(player)
	BrainService.cleanup(player)
	FriendService.cleanup(player)
end)

DataService.start()
BrainService.start()
LoseService.start()
GainService.start()
ShopService.start()
AdminService.start()
SocialService.start()
ProjectService.start()
SpaceService.start()
CastleService.start()
ConversationService.start()
SchoolService.start()
LifeService.start()

print("[Lose a Brain Cell] Server started (updates 1.0 – 1.7)")

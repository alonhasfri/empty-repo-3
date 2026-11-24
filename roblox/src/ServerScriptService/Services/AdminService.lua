-- AdminService: ranks (from the community + manual), admin commands, logs,
-- the Brain Shredder ban, live config and global messages.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TextChatService = game:GetService("TextChatService")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Brain = require(Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local ShopService = require(script.Parent.ShopService)

local AdminService = {}

AdminService.locked = false
local logs = {}
local muted = {}
local duck = nil

local liveStore = nil
local bugStore = nil
pcall(function()
	liveStore = DataStoreService:GetDataStore("BrainLiveConfig_v1")
	bugStore = DataStoreService:GetDataStore("BrainBugReports_v1")
end)

---------------------------------------------------------------------
-- Ranks
---------------------------------------------------------------------
local function groupId(): number
	if Config.GroupId ~= 0 then
		return Config.GroupId
	end
	if game.CreatorType == Enum.CreatorType.Group then
		return game.CreatorId
	end
	return 0
end

function AdminService.resolveRank(player: Player): number
	local level = 0
	if RunService:IsStudio() and Config.StudioIsOwner then
		level = 4
	end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 and player.UserId == game.CreatorId then
		level = 4
	end
	if table.find(Config.OwnerUserIds, player.UserId) then
		level = 4
	end
	local gid = groupId()
	if gid ~= 0 then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(gid)
		end)
		if ok and rank then
			if rank == 255 then
				level = math.max(level, 4)
			else
				for _, m in ipairs(Config.GroupRankMap) do
					if rank >= m.minRank then
						level = math.max(level, m.level)
						break
					end
				end
			end
		end
	end
	local data = DataService.get(player)
	if data and data.manualRank then
		level = math.max(level, math.clamp(data.manualRank, 0, 3))
	end
	player:SetAttribute("Rank", level)
	BrainService.applyCharacter(player)
	BrainService.push(player)
	return level
end

local function rankOf(player: Player): number
	return player:GetAttribute("Rank") or 0
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function addLog(actor: Player, cmd: string, target: Player?, arg: string?)
	local entry = string.format(
		"[%s] %s (%s) → %s%s%s",
		os.date("!%m-%d %H:%M", os.time()),
		actor.Name,
		Config.RankNames[rankOf(actor)],
		cmd,
		target and (" on " .. target.Name) or "",
		(arg and arg ~= "") and (" | " .. arg) or ""
	)
	table.insert(logs, 1, entry)
	while #logs > 200 do
		table.remove(logs)
	end
	print("[Admin] " .. entry)
end

local function filterBroadcast(text: string, fromUserId: number): string?
	text = string.sub(text, 1, 200)
	local ok, result = pcall(function()
		return TextService:FilterStringAsync(text, fromUserId)
	end)
	if not ok or not result then
		return nil
	end
	local ok2, filtered = pcall(function()
		return result:GetNonChatStringForBroadcastAsync()
	end)
	return ok2 and filtered or nil
end

local function setMuted(target: Player, isMuted: boolean)
	muted[target.UserId] = isMuted or nil
	local channels = TextChatService:FindFirstChild("TextChannels")
	if channels then
		for _, channel in ipairs(channels:GetChildren()) do
			for _, src in ipairs(channel:GetChildren()) do
				if src:IsA("TextSource") and src.UserId == target.UserId then
					src.CanSend = not isMuted
				end
			end
		end
	end
end

local function parseDuration(token: string?): number?
	if not token then
		return nil
	end
	token = string.lower(token)
	if token == "perm" or token == "permanent" then
		return -1
	end
	local n, unit = string.match(token, "^(%d+)([hdm]?)$")
	n = tonumber(n)
	if not n then
		return nil
	end
	if unit == "h" then
		return n * 3600
	elseif unit == "m" then
		return n * 60
	end
	return n * 86400
end

local function publish(topic: string, message)
	pcall(function()
		MessagingService:PublishAsync(topic, message)
	end)
end

local function saveLiveConfig()
	local payload = { features = Config.Features, rates = Config.Rates }
	if liveStore then
		pcall(function()
			liveStore:SetAsync("config", payload)
		end)
	end
	publish("BrainLiveConfig", payload)
end

local function applyLiveConfig(payload)
	if typeof(payload) ~= "table" then
		return
	end
	if typeof(payload.features) == "table" then
		for k, v in pairs(payload.features) do
			if Config.Features[k] ~= nil and typeof(v) == "boolean" then
				Config.Features[k] = v
			end
		end
	end
	if typeof(payload.rates) == "table" then
		for k, v in pairs(payload.rates) do
			if Config.Rates[k] ~= nil and typeof(v) == "number" then
				Config.Rates[k] = v
			end
		end
	end
end

local function revertAfter(seconds: number, fn)
	task.delay(seconds, function()
		pcall(fn)
	end)
end

---------------------------------------------------------------------
-- Command handlers: function(actor, target, arg) -> message
---------------------------------------------------------------------
local H = {}

H.setcells = function(actor, target, arg)
	local n = tonumber((string.gsub(arg or "", ",", "")))
	if not n then
		return "Type a number, like 86000000000"
	end
	local data = DataService.get(target)
	data.adminTouched = true -- excluded from leaderboards / world firsts
	BrainService.setCells(target, n)
	return target.Name .. " now has " .. Brain.formatNumber(n) .. " brain cells."
end

H.setpath = function(actor, target, arg)
	local path = string.lower(arg or "") == "gain" and "Gain" or (string.lower(arg or "") == "lose" and "Lose" or nil)
	if not path then
		return "Type Lose or Gain"
	end
	BrainService.startPath(target, path)
	DataService.get(target).adminTouched = true
	WorldService.teleport(target, string.lower(path))
	return target.Name .. " is now on the " .. path .. " path."
end

H.resetme = function(actor)
	local data = DataService.get(actor)
	data.path = nil
	data.cells = Config.LoseStartCells
	data.dead = false
	data.gatesPassed = {}
	data.job = nil
	BrainService.setCells(actor, Config.LoseStartCells)
	data.path = nil
	BrainService.push(actor)
	WorldService.teleport(actor, "lobby")
	return "Your progress was reset."
end

H.replaydeath = function(actor)
	Net.send(actor, "death", { seconds = 1234, best = 1234, clickbait = 42, skipped = 99, moments = { "Walked into a wall for 2 minutes (test)" }, loud = true, test = true })
	return "Replaying the death ending (test only, nothing changes)."
end

H.teleportme = function(actor, _, arg)
	local where = string.lower(arg or "lobby")
	if not WorldService.Spots[where] then
		return "Type lobby, lose or gain"
	end
	WorldService.teleport(actor, where)
	return "Teleported to " .. where .. "."
end

H.debug = function(actor)
	Net.send(actor, "debug", {})
	return "Debug overlay toggled."
end

H.bug = function(actor, _, arg)
	if not arg or arg == "" then
		return "Describe the bug in the text box."
	end
	local char = actor.Character
	local pos = char and char:GetPivot().Position or Vector3.zero
	local data = DataService.get(actor)
	local report = string.format("%s | %s | cells %s | pos %d,%d,%d | %s", os.date("!%Y-%m-%d %H:%M"), actor.Name, Brain.formatNumber(data.cells), pos.X, pos.Y, pos.Z, string.sub(arg, 1, 300))
	if bugStore then
		pcall(function()
			bugStore:UpdateAsync("reports", function(old)
				old = old or {}
				table.insert(old, 1, report)
				while #old > 100 do
					table.remove(old)
				end
				return old
			end)
		end)
	end
	return "Bug report saved. Thank you, tester!"
end

H.refreshrank = function(actor)
	local level = AdminService.resolveRank(actor)
	return "Your rank: " .. Config.RankNames[level]
end

H.kick = function(actor, target, arg)
	target:Kick("You were kicked by staff. " .. (arg or ""))
	return target.Name .. " was kicked."
end

H.warn = function(actor, target, arg)
	local data = DataService.get(target)
	table.insert(data.warnings, { by = actor.Name, reason = arg or "", time = os.time() })
	Net.send(target, "warning", { reason = arg ~= "" and arg or "Please follow the rules." })
	return target.Name .. " was warned (" .. #data.warnings .. " total)."
end

H.mute = function(actor, target)
	setMuted(target, true)
	Net.send(target, "toast", { text = "🔇 You were muted by staff." })
	return target.Name .. " was muted."
end

H.unmute = function(actor, target)
	setMuted(target, false)
	return target.Name .. " was unmuted."
end

H.ban = function(actor, target, arg)
	local token, reason = string.match(arg or "", "^(%S+)%s*(.*)$")
	local seconds = parseDuration(token)
	if not seconds then
		return "Type a duration first: 1d, 7d, 30d or perm (then a reason)."
	end
	local limit = Config.BanLimits[rankOf(actor)] or 0
	if limit ~= -1 and (seconds == -1 or seconds > limit) then
		return "Your rank can only ban for up to " .. math.floor(limit / 3600) .. " hours."
	end
	reason = (reason and reason ~= "") and reason or "Breaking the rules"
	Net.send(target, "banCutscene", { by = actor.DisplayName })
	local userId = target.UserId
	task.delay(4.5, function()
		local ok, err = pcall(function()
			Players:BanAsync({
				UserIds = { userId },
				ApplyToUniverse = true,
				Duration = seconds,
				DisplayReason = "You were thrown into the Brain Shredder. Reason: " .. reason,
				PrivateReason = "Banned by " .. actor.Name .. ": " .. reason,
				ExcludeAltAccounts = false, -- also bans their alt accounts
			})
		end)
		if not ok then
			warn("[Admin] BanAsync failed: " .. tostring(err))
			local p = Players:GetPlayerByUserId(userId)
			if p then
				p:Kick("You were banned: " .. reason)
			end
		end
	end)
	return target.Name .. " goes into the Brain Shredder (" .. (seconds == -1 and "permanent" or token) .. ")."
end

H.unban = function(actor, _, arg)
	local id = tonumber(arg)
	if not id then
		return "Type the player's user ID."
	end
	local ok, err = pcall(function()
		Players:UnbanAsync({ UserIds = { id }, ApplyToUniverse = true })
	end)
	return ok and ("Unbanned user " .. id .. ".") or ("Unban failed: " .. tostring(err))
end

H.tp = function(actor, target)
	if actor.Character and target.Character then
		actor.Character:PivotTo(target.Character:GetPivot() * CFrame.new(0, 0, 4))
	end
	return "Teleported to " .. target.Name .. "."
end

H.bring = function(actor, target)
	if actor.Character and target.Character then
		target.Character:PivotTo(actor.Character:GetPivot() * CFrame.new(0, 0, -4))
	end
	return "Brought " .. target.Name .. "."
end

H.freeze = function(actor, target)
	local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = true
	end
	return target.Name .. " is frozen."
end

H.unfreeze = function(actor, target)
	local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = false
	end
	return target.Name .. " is unfrozen."
end

H.viewstats = function(actor, target)
	local data = DataService.get(target)
	return string.format(
		"%s | Path: %s | Cells: %s | %s | Coins: %d | Warnings: %d | Rank: %s",
		target.Name,
		tostring(data.path),
		Brain.formatNumber(data.cells),
		Brain.iqText(data.cells, data.path),
		data.coins,
		#data.warnings,
		Config.RankNames[rankOf(target)]
	)
end

H.smsg = function(actor, _, arg)
	local text = filterBroadcast(arg or "", actor.UserId)
	if not text or text == "" then
		return "Message blocked or empty."
	end
	Net.broadcast("announce", { text = text, by = actor.DisplayName })
	return "Sent."
end

H.secretanimals = function()
	BrainService.secretAnimals = not BrainService.secretAnimals
	for _, p in ipairs(Players:GetPlayers()) do
		BrainService.applyCharacter(p)
		BrainService.push(p)
	end
	return "Secret animals are now " .. (BrainService.secretAnimals and "ON (tardigrade, microbe)" or "OFF") .. " in this server."
end

-- 1.6: ring the school bell for a Lose-path player (set by Main from SchoolService)
H.schoolbell = function(_, target)
	if not AdminService.ringBell then
		return "School isn't running."
	end
	return AdminService.ringBell(target) and ("🔔 Rang the school bell for " .. target.Name .. ".") or "Only human players on the Lose path go to school."
end

H.rubberduck = function()
	if duck and duck.Parent then
		duck:Destroy()
		duck = nil
		return "Rubber Duck removed."
	end
	duck = WorldService.spawnRubberDuck()
	return "🦆 The Rubber Duck appeared in the lobby (this server only)."
end

H.setrank = function(actor, target, arg)
	local newRank = tonumber(arg)
	local limit = Config.RankGiveLimit[rankOf(actor)] or 0
	if not newRank or newRank < 0 or newRank > 3 then
		return "Type 0 (Player), 1 (Tester), 2 (Moderator) or 3 (Head Moderator)."
	end
	if newRank > limit then
		return "Your rank can give up to " .. Config.RankNames[limit] .. "."
	end
	DataService.get(target).manualRank = newRank
	local level = AdminService.resolveRank(target)
	return target.Name .. " is now " .. Config.RankNames[level] .. " (community ranks still apply)."
end

H.givepass = function(actor, target, arg)
	local wanted = string.lower(arg or "")
	for key in pairs(Config.GamePasses) do
		if string.lower(key) == wanted then
			ShopService.grant(target, key, false)
			return "Gave " .. key .. " to " .. target.Name .. "."
		end
	end
	local names = {}
	for key in pairs(Config.GamePasses) do
		table.insert(names, key)
	end
	return "Pass names: " .. table.concat(names, ", ")
end

H.lock = function()
	AdminService.locked = true
	return "Server locked. Only staff can join."
end

H.unlock = function()
	AdminService.locked = false
	return "Server unlocked."
end

H.shutdown = function(actor)
	for _, p in ipairs(Players:GetPlayers()) do
		DataService.save(p, true)
		p:Kick("This server was shut down by staff. Your progress is saved. Rejoin to keep playing!")
	end
	return "Shutting down."
end

H.announce = function(actor, _, arg)
	local text = filterBroadcast(arg or "", actor.UserId)
	if not text or text == "" then
		return "Message blocked or empty."
	end
	Net.broadcast("announce", { text = text, by = actor.DisplayName, global = true })
	publish("BrainAnnounce", { text = text, by = actor.DisplayName, from = game.JobId })
	return "Global announcement sent."
end

H.feature = function(actor, _, arg)
	local wanted = string.lower(arg or "")
	for k, v in pairs(Config.Features) do
		if string.lower(k) == wanted then
			Config.Features[k] = not v
			saveLiveConfig()
			return k .. " is now " .. (Config.Features[k] and "ON" or "OFF") .. " in all servers."
		end
	end
	local names = {}
	for k in pairs(Config.Features) do
		table.insert(names, k)
	end
	return "Features: " .. table.concat(names, ", ")
end

H.liveconfig = function(actor, _, arg)
	local k, v = string.match(arg or "", "^(%S+)%s+(%S+)$")
	v = tonumber(v)
	if not k or not v or Config.Rates[k] == nil then
		return "Type: GainRate 0.002  or  LoseRate 0.03  or  MinLoss 1"
	end
	if v < 0 or v > 1000 then
		return "That number is out of range."
	end
	Config.Rates[k] = v
	saveLiveConfig()
	return k .. " set to " .. v .. " in all servers."
end

H.election = function()
	if not AdminService.runElection then
		return "Elections aren't ready."
	end
	task.spawn(AdminService.runElection)
	return "🗳 Election started!"
end

-- More tools
local jails = {}
local quiz = nil
local QUIZ = {
	{ q = "How many brain cells does an average human have?", options = { "86 million", "86 billion", "86 trillion", "302" }, answer = 2 },
	{ q = "Which animal has exactly 302 neurons?", options = { "Bee", "C. elegans worm", "Mouse", "Octopus" }, answer = 2 },
	{ q = "Who counted exactly 60 coffee beans per cup?", options = { "Einstein", "Tesla", "Beethoven", "Darwin" }, answer = 3 },
	{ q = "What is 7 × 8?", options = { "54", "56", "58", "64" }, answer = 2 },
	{ q = "Which planet is the hottest?", options = { "Mercury", "Venus", "Mars", "Jupiter" }, answer = 2 },
}

H.pm = function(actor, target, arg)
	local text = filterBroadcast(arg or "", actor.UserId)
	if not text or text == "" then
		return "Message blocked or empty."
	end
	Net.send(target, "announce", { text = "✉️ " .. text, by = actor.DisplayName .. " (staff)" })
	return "Sent to " .. target.Name .. "."
end
H.spectate = function(actor, target)
	Net.send(actor, "spectate", { userId = target.UserId })
	return "Spectating " .. target.Name .. ". Use Stop Spectating to come back."
end
H.unspectate = function(actor)
	Net.send(actor, "spectate", {})
	return "Back to your own camera."
end
H.jail = function(actor, target)
	local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return "No character."
	end
	if jails[target.UserId] then
		jails[target.UserId]:Destroy()
	end
	local cage = Instance.new("Model")
	cage.Name = "Jail_" .. target.Name
	local c = CFrame.new(root.Position - Vector3.new(0, 3, 0))
	for _, info in ipairs({
		{ Vector3.new(0, 0, 0), Vector3.new(10, 0.6, 10) },
		{ Vector3.new(0, 11, 0), Vector3.new(10, 0.6, 10) },
		{ Vector3.new(5, 5.5, 0), Vector3.new(0.6, 11, 10) },
		{ Vector3.new(-5, 5.5, 0), Vector3.new(0.6, 11, 10) },
		{ Vector3.new(0, 5.5, 5), Vector3.new(10, 11, 0.6) },
		{ Vector3.new(0, 5.5, -5), Vector3.new(10, 11, 0.6) },
	}) do
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = info[2]
		p.CFrame = c * CFrame.new(info[1])
		p.Material = Enum.Material.ForceField
		p.Color = Color3.fromRGB(255, 80, 80)
		p.Parent = cage
	end
	cage.Parent = workspace
	jails[target.UserId] = cage
	return target.Name .. " is in jail. 🚔"
end
H.unjail = function(actor, target)
	if jails[target.UserId] then
		jails[target.UserId]:Destroy()
		jails[target.UserId] = nil
	end
	return target.Name .. " is free."
end
H.respawn = function(actor, target)
	target:LoadCharacter()
	return target.Name .. " respawned."
end
H.clearjunk = function()
	local n = 0
	for _, d in ipairs(workspace:GetChildren()) do
		if d.Name == "RainItem" or d.Name == "RainBrain" or d.Name == "Pigeon" or d.Name == "RubberChicken" then
			d:Destroy()
			n += 1
		end
	end
	return "Cleared " .. n .. " things."
end
local function numberArg(arg, lo, hi)
	local n = tonumber(arg)
	if not n then
		return nil
	end
	return math.clamp(n, lo, hi)
end
H.speed = function(actor, target, arg)
	local n = numberArg(arg, 0, 200)
	local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not n or not hum then
		return "Type a number."
	end
	hum.WalkSpeed = n
	return target.Name .. " walk speed = " .. n .. " (resets on respawn)."
end
H.jump = function(actor, target, arg)
	local n = numberArg(arg, 0, 300)
	local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not n or not hum then
		return "Type a number."
	end
	hum.UseJumpPower = true
	hum.JumpPower = n
	return target.Name .. " jump power = " .. n .. "."
end
H.size = function(actor, target, arg)
	local n = numberArg(arg, 0.3, 3)
	if not n or not target.Character then
		return "Type a size between 0.3 and 3."
	end
	pcall(function()
		target.Character:ScaleTo(n)
	end)
	target.Character:SetAttribute("AppliedScale", n)
	return target.Name .. " size = " .. n .. "."
end
-- 1.8: Life Pack for testing before the real pass ID exists (owner rank only)
H.lifepack = function(_actor, target)
	local data = DataService.get(target)
	data.perks.LifePack = true
	data.adminTouched = true
	BrainService.push(target)
	return target.Name .. " now has the Life Pack (test)."
end

H.coins = function(actor, target, arg)
	local n = numberArg(arg, -1e6, 1e6)
	if not n then
		return "Type a number."
	end
	local data = DataService.get(target)
	data.coins = math.max(0, data.coins + n)
	BrainService.push(target)
	return target.Name .. " now has " .. math.floor(data.coins) .. " coins."
end
H.stress = function(actor, target, arg)
	local n = numberArg(arg, 0, 100)
	if not n then
		return "Type 0 – 100."
	end
	local data = DataService.get(target)
	BrainService.stress(target, n - data.stress)
	return target.Name .. " stress = " .. n .. "."
end
H.embarrass = function(actor, target, arg)
	local n = numberArg(arg, 0, 100)
	if not n then
		return "Type 0 – 100."
	end
	DataService.get(target).embarrass = n
	BrainService.push(target)
	return target.Name .. " embarrassment = " .. n .. "."
end
H.givegadget = function(actor, target, arg)
	local key = string.lower(arg or "")
	local Content = require(ReplicatedStorage.Shared.Content)
	for _, inv in ipairs(Content.Inventions) do
		if inv.key == key then
			DataService.get(target).inventions[key] = true
			if key == "duck" then
				target:SetAttribute("DuckPet", true)
			end
			Net.send(target, "inventionGift", { icon = inv.icon, name = inv.name, desc = inv.desc })
			return "Gave " .. inv.name .. " to " .. target.Name .. "."
		end
	end
	return "Unknown gadget."
end
H.skipgate = function(actor, target)
	local gate = BrainService.nextGate(target)
	if not gate then
		return "No gate ahead."
	end
	DataService.get(target).gatesPassed[gate.id] = true
	DataService.get(target).adminTouched = true
	BrainService.resetGateNotice(target)
	BrainService.push(target)
	return target.Name .. " passed " .. gate.name .. "."
end
H.resettutorial = function(actor, target)
	local s = DataService.get(target).settings
	s.tutLose, s.tutGain = 1, 1
	s.tutNotes, s.tutLose2, s.tutGain2, s.tutLose2Done, s.tutGain2Done = 0, 1, 1, false, false
	BrainService.push(target)
	Net.send(target, "tutorialReset", {})
	return "Tutorial reset for " .. target.Name .. "."
end
H.bringall = function(actor)
	local root = actor.Character and actor.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return "No character."
	end
	for i, p in ipairs(Players:GetPlayers()) do
		if p ~= actor and p.Character then
			p.Character:PivotTo(root.CFrame * CFrame.new(math.cos(i) * 6, 0, math.sin(i) * 6))
		end
	end
	return "Everyone's here."
end
H.muteall = function()
	for _, p in ipairs(Players:GetPlayers()) do
		if rankOf(p) < 1 then
			setMuted(p, true)
		end
	end
	return "Everyone (except staff) is muted."
end
H.unmuteall = function()
	for _, p in ipairs(Players:GetPlayers()) do
		setMuted(p, false)
	end
	return "Everyone is unmuted."
end
H.invent = function(actor, _, arg)
	if not AdminService.adminInvent then
		return "Not ready."
	end
	return AdminService.adminInvent(string.lower(arg or ""), actor.DisplayName) and "🔬 Invention hour started in every server!" or "Unknown invention. Try: teleport, space, fusion, hunger, water, cure, translator, superconductor, battery, climate, robots, labfood"
end
H.quiz = function()
	local q = QUIZ[math.random(1, #QUIZ)]
	quiz = { id = os.clock(), answer = q.answer, winner = nil }
	Net.broadcast("quiz", { id = quiz.id, q = q.q, options = q.options })
	return "❓ Quiz sent to everyone. First correct answer wins 50 coins."
end
Net.on("quiz_answer", function(player, d)
	if not quiz or d.id ~= quiz.id then
		return { ok = false, msg = "Too late!" }
	end
	if quiz.winner then
		return { ok = false, msg = quiz.winner .. " already won!" }
	end
	if tonumber(d.choice) ~= quiz.answer then
		return { ok = true, msg = "❌ Wrong!" }
	end
	quiz.winner = player.DisplayName
	local data = DataService.get(player)
	if data then
		data.coins += 50
		BrainService.push(player)
	end
	Net.broadcast("announce", { text = "❓ " .. player.DisplayName .. " won the quiz! +50 coins", by = "Dr. Wrinkles" })
	return { ok = true, msg = "✅ You won! +50 coins" }
end)

H.logs = function()
	return "Logs refreshed."
end

-- Fun
H.brainrain = function()
	WorldService.brainRain(30)
	return "🧠 It's raining brains!"
end
H.chicken = function()
	WorldService.spawnChicken()
	return "🐔 A rubber chicken appeared somewhere in the lobby."
end
H.laugh = function()
	Net.broadcast("friendsLaugh", { all = true })
	return "😂 Everyone's friends laugh."
end
H.narrator = function(actor, _, arg)
	local text = filterBroadcast(arg or "", actor.UserId)
	if not text or text == "" then
		return "Message blocked or empty."
	end
	Net.broadcast("narrator", { text = text, mood = "host" })
	return "Dr. Wrinkles said it."
end
H.weather = function(actor, _, arg)
	local kind = string.lower(arg or "duckstorm")
	Net.broadcast("weather", { kind = kind, seconds = 60 })
	return "Weather: " .. kind .. " for 60 seconds."
end
H.bighead = function(actor, target)
	local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	local hs = hum and hum:FindFirstChild("HeadScale")
	if hs and hs:IsA("NumberValue") then
		local old = hs.Value
		hs.Value = 3
		revertAfter(60, function()
			hs.Value = old
		end)
		return "🎈 Big head for 60 seconds."
	end
	return "This avatar can't change head size (R15 only)."
end
H.crayon = function(actor, target)
	local char = target.Character
	if not char then
		return "No character."
	end
	local saved = {}
	local colors = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 220, 60), Color3.fromRGB(90, 220, 90) }
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			saved[d] = { d.Color, d.Material }
			d.Color = colors[math.random(1, #colors)]
			d.Material = Enum.Material.SmoothPlastic
		end
	end
	revertAfter(60, function()
		for p, v in pairs(saved) do
			if p.Parent then
				p.Color = v[1]
				p.Material = v[2]
			end
		end
	end)
	return "🖍 " .. target.Name .. " is a crayon drawing for 60 seconds."
end
H.kazoo = function()
	Net.broadcast("kazoo", { seconds = 60 })
	return "🎺 Kazoo mode for 60 seconds."
end
H.confetti = function()
	Net.broadcast("confetti", {})
	return "🎉 Confetti!"
end
H.gravity = function(actor, _, arg)
	local kind = string.lower(arg or "low")
	local values = { low = 40, normal = 196.2, high = 400 }
	local g = values[kind]
	if not g then
		return "Type low, normal or high"
	end
	workspace.Gravity = g
	if kind ~= "normal" then
		revertAfter(60, function()
			workspace.Gravity = 196.2
		end)
	end
	return "Gravity: " .. kind .. (kind ~= "normal" and " for 60 seconds." or ".")
end
H.swapdoors = function()
	WorldService.swapDoors()
	Net.broadcast("swapDoors", {})
	return "🚪 Door signs swapped. Chaos."
end

-- Owner only
H.shutdownall = function()
	publish("BrainShutdown", { reason = "Update" })
	for _, p in ipairs(Players:GetPlayers()) do
		DataService.save(p, true)
		p:Kick("The game is updating! Your progress is saved. Rejoin in a minute.")
	end
	return "All servers are shutting down."
end

H.wipedata = function(actor, _, arg)
	local id = tonumber(arg)
	if not id then
		return "Type the user ID."
	end
	local online = Players:GetPlayerByUserId(id)
	if online then
		online:Kick("Your data was deleted at your request.")
	end
	task.wait(1)
	return DataService.wipe(id) and ("Deleted data for user " .. id .. ".") or "Delete failed."
end

H.killswitch = function()
	Config.Features.Purchases = not Config.Features.Purchases
	saveLiveConfig()
	return "Purchases are now " .. (Config.Features.Purchases and "ON" or "PAUSED") .. " in all servers."
end

---------------------------------------------------------------------
-- Running a command (panel and chat)
---------------------------------------------------------------------
function AdminService.execute(actor: Player, cmd: string, targetUserId: number?, arg: string?)
	cmd = string.lower(cmd or "")
	local def = Config.Commands[cmd]
	local handler = H[cmd]
	if not def or not handler then
		return { ok = false, msg = "Unknown command." }
	end
	local level = rankOf(actor)
	if level < def.min then
		return { ok = false, msg = "Your rank can't use that." }
	end
	local target = nil
	if def.target then
		target = targetUserId and Players:GetPlayerByUserId(targetUserId) or nil
		if not target and def.selfBelow and level < def.selfBelow then
			target = actor
		end
		if not target then
			return { ok = false, msg = "Pick a player first." }
		end
		if target ~= actor then
			if def.selfBelow and level < def.selfBelow then
				return { ok = false, msg = "Your rank can only use this on yourself." }
			end
			if rankOf(target) >= level then
				return { ok = false, msg = "You can't use that on someone with an equal or higher rank." }
			end
		end
		if not DataService.get(target) then
			return { ok = false, msg = "That player is still loading." }
		end
	end
	local ok, result = pcall(handler, actor, target, arg or "")
	if not ok then
		warn("[Admin] " .. cmd .. " error: " .. tostring(result))
		return { ok = false, msg = "Command failed." }
	end
	if cmd ~= "logs" and cmd ~= "viewstats" and cmd ~= "debug" then
		addLog(actor, cmd, target, arg)
	end
	return { ok = true, msg = result }
end

Net.on("admin", function(player, d)
	return AdminService.execute(player, d.cmd, tonumber(d.target), typeof(d.arg) == "string" and d.arg or "")
end)

Net.on("admin_players", function(player)
	if rankOf(player) < 1 then
		return { ok = false }
	end
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local data = DataService.get(p)
		table.insert(list, {
			userId = p.UserId,
			name = p.Name,
			display = p.DisplayName,
			rank = rankOf(p),
			cells = data and Brain.shortNumber(data.cells) or "?",
			iq = data and math.floor(Brain.iq(data.cells)) or nil,
			path = data and data.path or "Lobby",
		})
	end
	return { ok = true, players = list }
end)

Net.on("admin_logs", function(player)
	if rankOf(player) < 3 then
		return { ok = false }
	end
	return { ok = true, logs = logs }
end)

local function onChatted(player: Player, message: string)
	if string.sub(message, 1, 1) ~= ";" or rankOf(player) < 1 then
		return
	end
	local words = {}
	for w in string.gmatch(string.sub(message, 2), "%S+") do
		table.insert(words, w)
	end
	local cmd = string.lower(words[1] or "")
	local def = Config.Commands[cmd]
	if not def then
		Net.send(player, "toast", { text = "Unknown command: " .. cmd })
		return
	end
	local targetId = nil
	local argStart = 2
	if def.target and words[2] then
		local wanted = string.lower(words[2])
		if wanted == "me" then
			targetId = player.UserId
			argStart = 3
		else
			for _, p in ipairs(Players:GetPlayers()) do
				if string.sub(string.lower(p.Name), 1, #wanted) == wanted or string.sub(string.lower(p.DisplayName), 1, #wanted) == wanted then
					targetId = p.UserId
					argStart = 3
					break
				end
			end
		end
	end
	local arg = table.concat(words, " ", argStart)
	local result = AdminService.execute(player, cmd, targetId, arg)
	Net.send(player, "toast", { text = (result.ok and "✅ " or "⛔ ") .. tostring(result.msg) })
end

---------------------------------------------------------------------
-- Joining, live config, cross-server messages
---------------------------------------------------------------------
function AdminService.onJoin(player: Player)
	local level = AdminService.resolveRank(player)
	if AdminService.locked and level < 2 then
		player:Kick("This server is locked right now. Try another server!")
		return false
	end
	player.Chatted:Connect(function(msg)
		onChatted(player, msg)
	end)
	if muted[player.UserId] then
		setMuted(player, true)
	end
	return true
end

function AdminService.start()
	if liveStore then
		local ok, payload = pcall(function()
			return liveStore:GetAsync("config")
		end)
		if ok then
			applyLiveConfig(payload)
		end
	end
	pcall(function()
		MessagingService:SubscribeAsync("BrainLiveConfig", function(msg)
			applyLiveConfig(msg.Data)
		end)
	end)
	pcall(function()
		MessagingService:SubscribeAsync("BrainAnnounce", function(msg)
			local d = msg.Data
			if typeof(d) == "table" and d.from ~= game.JobId then
				Net.broadcast("announce", { text = d.text, by = d.by, global = true })
			end
		end)
	end)
	pcall(function()
		MessagingService:SubscribeAsync("BrainShutdown", function()
			for _, p in ipairs(Players:GetPlayers()) do
				DataService.save(p, true)
				p:Kick("The game is updating! Your progress is saved. Rejoin in a minute.")
			end
		end)
	end)
	-- Re-apply mutes when chat sources appear
	local channels = TextChatService:FindFirstChild("TextChannels")
	if channels then
		channels.DescendantAdded:Connect(function(d)
			if d:IsA("TextSource") and muted[d.UserId] then
				d.CanSend = false
			end
		end)
	end
end

return AdminService

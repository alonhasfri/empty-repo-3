-- DataService: loads and saves every player's progress (with a session lock,
-- so the same account in two servers can't duplicate or lose progress).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local store = nil
local okStore = pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

local profiles = {} -- [player] = data
local noSave = {} -- [player] = true if saving isn't available (Studio without API access)

local function defaultData()
	return {
		version = 1,
		path = nil, -- "Lose" or "Gain"
		cells = Config.LoseStartCells,
		coins = 0,
		badges = {},
		gatesPassed = {},
		job = nil,
		embarrass = 0,
		stress = 0,
		position = nil,
		settings = { music = 0.5, sfx = 0.8, reduceFlashing = false, largeText = false, extraTime = false, fxIntensity = 1, hardLife = false, classicHud = false, guide = true, lowGraphics = false },
		manualRank = 0,
		perks = {},
		comeback = false,
		runStart = os.time(),
		bestRunSeconds = nil,
		viralCount = 0,
		clickbaitClicks = 0,
		warnings = {},
		stats = { textsSkipped = 0, textsRead = 0, clickbaitClicked = 0, commentsPosted = 0, gatesFailed = 0 },
		embarrassingMoments = {},
		inventions = {}, -- secret inventions owned
		ideaMeter = 0, -- fills by doing job tasks; full = Eureka cutscene
		eurekaChoices = nil,
		focusCharges = 0,
		bonusHints = 0,
		jobTasksDone = 0,
		bank = { savings = 0, lastTick = 0 }, -- 1.7: Brain Bank savings (checking = coins)
		convSeen = {}, -- 1.5: conversation scenes you've finished (older saves get this automatically)
	}
end

local function reconcile(data, template)
	for k, v in pairs(template) do
		if data[k] == nil then
			if typeof(v) == "table" then
				local copy = {}
				for k2, v2 in pairs(v) do
					copy[k2] = v2
				end
				data[k] = copy
			else
				data[k] = v
			end
		elseif typeof(v) == "table" and typeof(data[k]) == "table" then
			reconcile(data[k], v)
		end
	end
	return data
end

local function key(userId: number): string
	return "p_" .. tostring(userId)
end

function DataService.load(player: Player)
	if not okStore or not store then
		noSave[player] = true
		profiles[player] = defaultData()
		return profiles[player], false
	end

	local loaded = nil
	local attempts = 0
	while attempts < 6 and player.Parent do
		attempts += 1
		local locked = false
		local ok, err = pcall(function()
			store:UpdateAsync(key(player.UserId), function(old)
				old = old or defaultData()
				local lock = old.lock
				local force = attempts >= 6
				if lock and lock.job ~= game.JobId and os.time() - (lock.time or 0) < 120 and not force then
					locked = true
					return nil -- cancel, another server still has it
				end
				old.lock = { job = game.JobId, time = os.time() }
				loaded = old
				return old
			end)
		end)
		if ok and loaded then
			break
		end
		if not ok then
			warn("[DataService] Load failed: " .. tostring(err))
			if RunService:IsStudio() then
				break
			end
		end
		if locked then
			task.wait(3)
		else
			task.wait(1)
		end
	end

	if not loaded then
		noSave[player] = true
		loaded = defaultData()
		profiles[player] = loaded
		return loaded, false
	end

	reconcile(loaded, defaultData())
	-- 1.7.2: repair money broken by an old exploit (NaN or infinity can't be spent or saved sanely)
	local function finite(v)
		return typeof(v) == "number" and v == v and math.abs(v) < 1e15
	end
	if not finite(loaded.coins) then
		loaded.coins = 0
	end
	if typeof(loaded.bank) == "table" then
		if not finite(loaded.bank.savings) then
			loaded.bank.savings = 0
		end
		if not finite(loaded.bank.minSince) then
			loaded.bank.minSince = loaded.bank.savings
		end
	end
	profiles[player] = loaded
	return loaded, true
end

function DataService.get(player: Player)
	return profiles[player]
end

function DataService.canSave(player: Player): boolean
	return not noSave[player]
end

local function snapshotPosition(player: Player, data)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
		local p = root.Position
		data.position = { x = p.X, y = p.Y, z = p.Z }
	end
end

function DataService.save(player: Player, release: boolean?)
	local data = profiles[player]
	if not data or noSave[player] or not store then
		return
	end
	snapshotPosition(player, data)
	local ok, err = pcall(function()
		store:UpdateAsync(key(player.UserId), function(old)
			if old and old.lock and old.lock.job ~= game.JobId then
				-- another server took over; don't overwrite their newer data
				return nil
			end
			data.lock = (not release) and { job = game.JobId, time = os.time() } or nil
			return data
		end)
	end)
	if not ok then
		warn("[DataService] Save failed: " .. tostring(err))
	end
end

function DataService.release(player: Player)
	DataService.save(player, true)
	profiles[player] = nil
	noSave[player] = nil
end

-- Admin: delete a player's data (Roblox data-deletion requests)
function DataService.wipe(userId: number): boolean
	if not store then
		return false
	end
	local ok = pcall(function()
		store:RemoveAsync(key(userId))
	end)
	return ok
end

-- Admin: read another player's manual rank while they're offline is not needed in 1.0.

function DataService.start()
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for _, p in ipairs(Players:GetPlayers()) do
				task.spawn(DataService.save, p)
			end
		end
	end)
	game:BindToClose(function()
		local threads = 0
		for _, p in ipairs(Players:GetPlayers()) do
			threads += 1
			task.spawn(function()
				DataService.save(p, true)
				threads -= 1
			end)
		end
		local t = os.clock()
		while threads > 0 and os.clock() - t < 25 do
			task.wait(0.2)
		end
	end)
end

return DataService

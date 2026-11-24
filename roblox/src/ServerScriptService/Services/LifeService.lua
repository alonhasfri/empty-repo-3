-- LifeService (1.7): the "real life" systems that smart players get on their phone.
--   * Hoppr: ride-hail. Pick a preset place, see the fare and ETA BEFORE you confirm,
--     the car comes, you see its plate, a short ride, a receipt. Paid with coins you
--     earn in-game (never Robux). The free map taxi still exists for everyone.
--   * Shifts: a shift starts every few minutes. Clock in at your workplace on time for
--     a bonus, clock out for a payslip. Walking is free but can make you late.
--   * Brain Bank: checking (your coins) + savings at a fixed, shown rate. Optional
--     "harder life" bills that never take you below 0. No debt, no gambling.
-- All text lives in Content.Life, all numbers in Config.Life.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Content = require(Shared.Content)
local Brain = require(Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local ConversationService = require(script.Parent.ConversationService)

local LifeService = {}

local CL = Config.Life
local TL = Content.Life

local sessions = {} -- [player] = { quote, rideAt, riding, shift }
local function sess(player)
	local x = sessions[player]
	if not x then
		x = {}
		sessions[player] = x
	end
	return x
end

local function jobOf(data)
	for _, j in ipairs(Content.Jobs) do
		if j.id == data.job then
			return j
		end
	end
	return nil
end

local function isAnimal(data): boolean
	local stage = Brain.stage(data.cells, BrainService.secretAnimals)
	return stage.key ~= "human" and stage.key ~= "barelyhuman"
end

local function bank(data)
	if typeof(data.bank) ~= "table" then
		data.bank = { savings = 0, lastTick = 0 }
	end
	data.bank.savings = math.max(0, math.floor(tonumber(data.bank.savings) or 0))
	data.bank.lastTick = tonumber(data.bank.lastTick) or 0
	-- lowest savings since the last interest tick (old saves start from what they have)
	data.bank.minSince = math.max(0, math.floor(tonumber(data.bank.minSince) or data.bank.savings))
	return data.bank
end

---------------------------------------------------------------------
-- Hoppr (ride-hail)
---------------------------------------------------------------------
local function destination(player, data, key: string): (Vector3?, string?)
	if key == "work" then
		local job = jobOf(data)
		if not job then
			return nil, nil
		end
		return WorldService.Workplaces[job.place], job.placeName
	end
	local spot = WorldService.Spots[key]
	if not spot then
		return nil, nil
	end
	local name = key
	for _, p in ipairs(WorldService.Places) do
		if p.key == key then
			name = p.name
		end
	end
	return WorldService.sp(spot), name
end

local function busyNow(): boolean
	return (os.time() % CL.Ride.BusyEverySeconds) < CL.Ride.BusyLengthSeconds
end

local PLATE_LETTERS = { "B", "R", "N", "Z", "K", "Q", "T", "M" }
local CAR_COLORS = TL.Ride.CarColors
local CAR_MODELS = TL.Ride.CarModels

Net.on("ride_places", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local list = {}
	local job = jobOf(data)
	if job and WorldService.Workplaces[job.place] then
		table.insert(list, { key = "work", name = "💼 " .. TL.Ride.Work .. " (" .. job.placeName .. ")" })
	end
	for _, p in ipairs(WorldService.placeList()) do
		table.insert(list, { key = p.key, name = p.name })
	end
	return { ok = true, places = list }
end)

Net.on("ride_quote", function(player, d)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	if isAnimal(data) then
		return { ok = false, msg = TL.Ride.Animal }
	end
	local key = tostring(d.key)
	local pos, name = destination(player, data, key)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not pos or not root then
		return { ok = false, msg = TL.Ride.Unknown }
	end
	local dist = (root.Position - pos).Magnitude
	local busy = busyNow()
	local fare = CL.Ride.BaseFare + (dist / 100) * CL.Ride.PerHundredStuds
	if busy then
		fare *= CL.Ride.BusyMultiplier
	end
	fare = math.max(1, math.ceil(fare))
	local eta = math.random(CL.Ride.EtaMin, CL.Ride.EtaMax)
	sess(player).quote = { key = key, fare = fare, eta = eta, at = os.clock(), name = name }
	return { ok = true, fare = fare, eta = eta, busy = busy, name = name, coins = data.coins, distance = math.floor(dist) }
end)

Net.on("ride_book", function(player, d)
	local data = DataService.get(player)
	local s = sess(player)
	local q = s.quote
	if not data or not q or q.key ~= tostring(d.key) or os.clock() - q.at > 60 then
		return { ok = false, msg = TL.Ride.Expired }
	end
	if s.riding then
		return { ok = false, msg = TL.Ride.Already }
	end
	if s.rideAt and os.clock() < s.rideAt then
		return { ok = false, msg = TL.Ride.Wait }
	end
	if data.coins < q.fare then
		return { ok = false, msg = string.format(TL.Ride.TooPoor, q.fare) }
	end
	data.coins -= q.fare
	s.quote = nil
	s.riding = true
	BrainService.push(player)
	local plate = PLATE_LETTERS[math.random(#PLATE_LETTERS)] .. PLATE_LETTERS[math.random(#PLATE_LETTERS)] .. "-" .. math.random(100, 999)
	local ride = {
		plate = plate,
		color = CAR_COLORS[math.random(#CAR_COLORS)],
		model = CAR_MODELS[math.random(#CAR_MODELS)],
		driver = TL.Ride.Drivers[math.random(#TL.Ride.Drivers)],
		eta = q.eta,
		rideSeconds = CL.Ride.RideSeconds,
		fare = q.fare,
		name = q.name,
	}
	task.delay(q.eta + CL.Ride.RideSeconds, function()
		s.riding = false
		s.rideAt = os.clock() + CL.Ride.Cooldown
		if not player.Parent then
			return
		end
		-- never yank someone out of a conversation; stand them up from a seat first
		if not ConversationService.readyToTravel(player) then
			data.coins += q.fare
			BrainService.push(player)
			Net.send(player, "rideDone", { refunded = true, fare = q.fare })
			return
		end
		local pos = destination(player, data, q.key)
		if q.key ~= "work" and WorldService.Spots[q.key] then
			WorldService.teleport(player, q.key)
		elseif pos and player.Character then
			player.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 3, -8)))
		end
		Net.send(player, "rideDone", { fare = q.fare, name = q.name, plate = plate })
	end)
	return { ok = true, ride = ride }
end)

---------------------------------------------------------------------
-- Shifts and payslips (Gain path, needs a job)
---------------------------------------------------------------------
local function shiftClock()
	local every = CL.Shift.EverySeconds
	local phase = os.time() % every
	return phase, every - phase -- seconds since the last start, seconds to the next
end

Net.on("shift_status", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local job = jobOf(data)
	local since, untilNext = shiftClock()
	local s = sess(player).shift
	return {
		ok = true,
		job = job and job.name or nil,
		place = job and job.placeName or nil,
		since = since,
		untilNext = untilNext,
		grace = CL.Shift.GraceSeconds,
		bonus = CL.Shift.OnTimeBonus,
		onShift = s ~= nil,
		shiftSeconds = s and (os.time() - s.start) or 0,
		onTime = s and s.onTime or false,
	}
end)

Net.on("shift_in", function(player)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" then
		return { ok = false, msg = TL.Shift.GainOnly }
	end
	local job = jobOf(data)
	if not job then
		return { ok = false, msg = TL.Shift.NoJob }
	end
	local s = sess(player)
	if s.shift then
		return { ok = false, msg = TL.Shift.Already }
	end
	local pos = WorldService.Workplaces[job.place]
	if not pos or not WorldService.near(player, pos, Config.WorkRadius) then
		return { ok = false, msg = string.format(TL.Shift.NotThere, job.placeName), notAtWork = true }
	end
	local since = shiftClock()
	local onTime = since <= CL.Shift.GraceSeconds
	local window = math.floor(os.time() / CL.Shift.EverySeconds)
	s.shift = { start = os.time(), onTime = onTime, coinsAt = data.coins, tasksAt = data.jobTasksDone or 0, job = job.name, place = job.place, window = window }
	player:SetAttribute("OnShift", true)
	return { ok = true, onTime = onTime, msg = onTime and string.format(TL.Shift.OnTime, CL.Shift.OnTimeBonus) or TL.Shift.Late }
end)

local function clockOut(player, quiet: boolean?)
	local data = DataService.get(player)
	local s = sess(player)
	local sh = s.shift
	if not data or not sh then
		return { ok = false, msg = TL.Shift.NotOn }
	end
	local seconds = os.time() - sh.start
	if seconds < CL.Shift.MinShiftSeconds and not quiet then
		return { ok = false, msg = string.format(TL.Shift.TooShort, CL.Shift.MinShiftSeconds - seconds) }
	end
	s.shift = nil
	player:SetAttribute("OnShift", nil)
	local wages = math.max(0, data.coins - sh.coinsAt)
	local tasks = math.max(0, (data.jobTasksDone or 0) - sh.tasksAt)
	-- the on-time bonus needs real work: tasks done, still at work, and only once per shift window
	local pos = WorldService.Workplaces[sh.place]
	local atWork = pos ~= nil and WorldService.near(player, pos, Config.WorkRadius)
	local earned = sh.onTime
		and seconds >= CL.Shift.MinShiftSeconds
		and tasks >= CL.Shift.BonusMinTasks
		and atWork
		and s.bonusWindow ~= sh.window
	local bonus = earned and CL.Shift.OnTimeBonus or 0
	if earned then
		s.bonusWindow = sh.window
	end
	data.coins += bonus
	BrainService.push(player)
	return {
		ok = true,
		payslip = {
			job = sh.job,
			minutes = math.floor(seconds / 60 * 10 + 0.5) / 10,
			tasks = math.max(0, (data.jobTasksDone or 0) - sh.tasksAt),
			wages = wages,
			bonus = bonus,
			total = wages + bonus,
			onTime = sh.onTime,
		},
	}
end

Net.on("shift_out", function(player)
	return clockOut(player)
end)

---------------------------------------------------------------------
-- Brain Bank
---------------------------------------------------------------------
Net.on("bank_state", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local b = bank(data)
	local nextIn = math.max(0, CL.Bank.InterestEverySeconds - (os.time() - b.lastTick))
	return {
		ok = true,
		checking = data.coins,
		savings = b.savings,
		rate = CL.Bank.SavingsRatePercent,
		every = CL.Bank.InterestEverySeconds,
		nextIn = b.lastTick == 0 and CL.Bank.InterestEverySeconds or nextIn,
		hardLife = data.settings and data.settings.hardLife == true,
		bill = CL.Bank.Bill,
	}
end)

Net.on("bank_move", function(player, d)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local b = bank(data)
	local amount = math.floor(tonumber(d.amount) or 0)
	if amount <= 0 then
		return { ok = false, msg = TL.Bank.Amount }
	end
	if d.dir == "save" then
		if amount > data.coins then
			return { ok = false, msg = TL.Bank.NotEnough }
		end
		data.coins -= amount
		b.savings += amount
		if b.lastTick == 0 then
			b.lastTick = os.time()
		end
	elseif d.dir == "take" then
		if amount > b.savings then
			return { ok = false, msg = TL.Bank.NotEnough }
		end
		b.savings -= amount
		data.coins += amount
		-- interest is paid on the lowest balance since the last tick (no "park it just before the tick")
		b.minSince = math.min(b.minSince, b.savings)
	else
		return { ok = false }
	end
	BrainService.push(player)
	return { ok = true, checking = data.coins, savings = b.savings }
end)

local function bankTick(player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local b = bank(data)
	if b.lastTick == 0 then
		b.lastTick = os.time()
		return
	end
	if os.time() - b.lastTick < CL.Bank.InterestEverySeconds then
		return
	end
	b.lastTick = os.time()
	local base = math.min(b.savings, b.minSince)
	b.minSince = b.savings -- the next period starts from what is saved now
	local interest = math.min(CL.Bank.MaxInterestPerTick, math.floor(base * CL.Bank.SavingsRatePercent / 100))
	if interest > 0 then
		b.savings += interest
		BrainService.toast(player, string.format(TL.Bank.Interest, interest))
	end
	if data.settings and data.settings.hardLife then
		-- optional bills: paid from checking, then savings, and never below 0 (no debt)
		local due = CL.Bank.Bill
		local fromCoins = math.min(due, math.max(0, data.coins))
		data.coins -= fromCoins
		due -= fromCoins
		local fromSavings = math.min(due, b.savings)
		b.savings -= fromSavings
		local paid = fromCoins + fromSavings
		if paid > 0 then
			b.brokeToldAt = nil
			BrainService.toast(player, string.format(TL.Bank.BillPaid, paid))
		elseif not b.brokeToldAt then
			b.brokeToldAt = os.time() -- say "skipped" once, not every tick
			BrainService.toast(player, TL.Bank.BillSkipped)
		end
	end
	BrainService.push(player)
end

function LifeService.start()
	task.spawn(function()
		while true do
			task.wait(30)
			for _, p in ipairs(Players:GetPlayers()) do
				pcall(bankTick, p)
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(p)
	sessions[p] = nil
end)

return LifeService

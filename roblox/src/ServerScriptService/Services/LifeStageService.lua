-- LifeStageService.lua (1.8, Life Pack plan step 3): grow up from baby to grandparent.
-- Life Pack owners can start a new life as a 👶 baby. You age about 1 year every Config.LifeStages.SecondsPerYear.
-- Little kids can't use the two doors: the 🌟 Crossroads Ceremony at the fountain lets you pick
-- Lose or Gain at any age from 8 to 20. At the end of a long life you retire, and your next baby
-- inherits a small bonus (a replay loop). Non-owners play exactly as before. Pausing aging is in Settings.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)

local LifeStageService = {}
local CL = Config.LifeStages
local TL = Content.LifeStages

local function owns(data): boolean
	return data.perks and data.perks.LifePack == true
end

local function life(data)
	if typeof(data.life) ~= "table" then
		data.life = { on = false, seconds = 0, gen = 0 }
	end
	local l = data.life
	l.seconds = tonumber(l.seconds) or 0
	l.gen = tonumber(l.gen) or 0
	return l
end

function LifeStageService.age(data): number
	return math.floor(life(data).seconds / CL.SecondsPerYear)
end

function LifeStageService.stage(data)
	local a = LifeStageService.age(data)
	for _, s in ipairs(CL.Stages) do
		if a >= s.from and a <= s.to then
			return s
		end
	end
	return CL.Stages[#CL.Stages]
end

-- for the state the client gets (nil when not in a Life Pack life)
function LifeStageService.info(data)
	local l = life(data)
	if not l.on or not owns(data) then
		return nil
	end
	local s = LifeStageService.stage(data)
	return { age = LifeStageService.age(data), stage = s.key, emoji = s.emoji, name = TL.StageNames[s.key], gen = l.gen, paused = data.settings and data.settings.lifePause == true }
end

local function applyBody(player, data)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hum then
		return
	end
	local info = LifeStageService.info(data)
	local s = info and LifeStageService.stage(data)
	local scale = s and s.scale or 1
	pcall(function()
		if math.abs(char:GetScale() - scale) > 0.01 then
			char:ScaleTo(scale)
		end
	end)
	if s and s.walk and hum.WalkSpeed > s.walk then
		hum.WalkSpeed = s.walk -- babies crawl, grandparents stroll
	end
end
LifeStageService.applyBody = applyBody

-- Doors: little kids in a Life Pack life use the Crossroads Ceremony instead
function LifeStageService.doorBlocked(player): string?
	local data = DataService.get(player)
	if not data or not LifeStageService.info(data) then
		return nil
	end
	local a = LifeStageService.age(data)
	if a < CL.CrossroadsFrom then
		return string.format(TL.TooYoung, CL.CrossroadsFrom, a)
	end
	return nil
end

Net.on("life_start", function(player, d)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	if not owns(data) then
		return { ok = false, msg = TL.NeedPass }
	end
	if d.confirm ~= true then
		return { ok = false }
	end
	local l = life(data)
	local inherited = l.on and LifeStageService.age(data) >= CL.LegacyAge
	l.on = true
	l.seconds = 0
	l.lastYear = 0
	l.gen = inherited and (l.gen + 1) or math.max(l.gen, 1)
	-- a brand-new baby: no path yet
	data.path = nil
	data.dead = false
	data.cells = Config.LoseStartCells
	data.job = nil
	if inherited then
		data.coins += CL.LegacyCoins
	end
	BrainService.applyCharacter(player)
	BrainService.push(player)
	WorldService.teleport(player, "lobby")
	task.delay(1, applyBody, player, data)
	return { ok = true, msg = inherited and string.format(TL.BornAgain, l.gen, CL.LegacyCoins) or TL.Born }
end)

Net.on("crossroads", function(player, d)
	local data = DataService.get(player)
	local info = data and LifeStageService.info(data)
	if not info then
		return { ok = false, msg = TL.NeedPass }
	end
	if data.path then
		return { ok = false, msg = TL.AlreadyChose }
	end
	if info.age < CL.CrossroadsFrom then
		return { ok = false, msg = string.format(TL.TooYoung, CL.CrossroadsFrom, info.age) }
	end
	if d.path ~= "Lose" and d.path ~= "Gain" then
		return { ok = false }
	end
	-- keep the life going: startPath resets the run, not the age
	local l = data.life
	local keep = { seconds = l.seconds, gen = l.gen, lastYear = l.lastYear }
	BrainService.startPath(player, d.path)
	data.life = { on = true, seconds = keep.seconds, gen = keep.gen, lastYear = keep.lastYear }
	WorldService.teleport(player, string.lower(d.path))
	Net.send(player, "confetti", {})
	task.delay(1, applyBody, player, data)
	return { ok = true, msg = d.path == "Gain" and TL.ChoseGain or TL.ChoseLose }
end)

function LifeStageService.start()
	-- the fountain hosts the Crossroads Ceremony
	task.defer(function()
		local fountain = workspace:FindFirstChild("FountainBase", true)
		if not fountain then
			return
		end
		local spot = Instance.new("Part")
		spot.Name = "CrossroadsSpot"
		spot.Anchored = true
		spot.CanCollide = false
		spot.Transparency = 1
		spot.Size = Vector3.new(2, 2, 2)
		spot.Position = fountain.Position + Vector3.new(0, 3, -15)
		spot.Parent = workspace
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = TL.CeremonyAction
		pp.ObjectText = TL.CeremonyObject
		pp.MaxActivationDistance = 14
		pp.RequiresLineOfSight = false
		pp.Parent = spot
		pp.Triggered:Connect(function(player)
			local data = DataService.get(player)
			local info = data and LifeStageService.info(data)
			if not info then
				BrainService.toast(player, TL.CeremonyNotYou)
				return
			end
			Net.send(player, "crossroads", { age = info.age, from = CL.CrossroadsFrom, to = CL.CrossroadsTo, chosen = data.path ~= nil })
		end)
	end)
	-- aging
	task.spawn(function()
		while true do
			task.wait(5)
			for _, p in ipairs(Players:GetPlayers()) do
				local data = DataService.get(p)
				local info = data and LifeStageService.info(data)
				if info and not info.paused and not data.dead then
					local l = data.life
					local before = LifeStageService.stage(data).key
					l.seconds += 5
					local age = LifeStageService.age(data)
					if age > (l.lastYear or 0) then
						l.lastYear = age
						BrainService.toast(p, string.format(TL.Birthday, age), "BadgeSparkle")
						local after = LifeStageService.stage(data)
						if after.key ~= before then
							BrainService.toast(p, string.format(TL.NewStage, after.emoji, TL.StageNames[after.key]), "LevelUp")
							applyBody(p, data)
						end
						if age == CL.CrossroadsFrom and not data.path then
							BrainService.toast(p, TL.CrossroadsOpen, "NotificationPing")
						elseif age >= CL.CrossroadsTo and not data.path then
							BrainService.toast(p, TL.CrossroadsLast, "NotificationPing")
						end
						if age == CL.LegacyAge then
							BrainService.toast(p, string.format(TL.Legacy, CL.LegacyCoins), "LibrarianChime")
						end
						BrainService.push(p)
					end
				end
			end
		end
	end)
	local function watch(p)
		p.CharacterAdded:Connect(function()
			task.delay(1.6, function()
				local data = DataService.get(p)
				if data then
					applyBody(p, data)
				end
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
	end
end

return LifeStageService

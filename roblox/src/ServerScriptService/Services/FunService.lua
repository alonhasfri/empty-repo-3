-- FunService.lua (1.8, Life Pack plan step 2): free new places on the empty west (Lose) side.
-- Each one also has a reason for Gain players to visit (both paths matter equally).
--   💦 Slime Shop      Lose: make the slimiest slime, lose cells   | Gain: the science of slime, small gain
--   🤸 Trampoline Park Lose: bounce, brain cells fly out            | Gain: exercise, stress down
--   🔮 Fortune Teller  free; exact odds shown; Lose: silly fortunes cost cells | Gain: wise ones give a little
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)

local FunService = {}
local CF = Config.Fun
local TF = Content.Fun

local nextAt = {} -- [player] = { [key] = os.clock() }

local function pickFortune()
	local total = 0
	for _, o in ipairs(CF.fortune.Odds) do
		total += o.weight
	end
	local roll = math.random() * total
	for _, o in ipairs(CF.fortune.Odds) do
		roll -= o.weight
		if roll <= 0 then
			return o.kind
		end
	end
	return CF.fortune.Odds[1].kind
end

Net.on("fun_do", function(player, d)
	local key = tostring(d.key)
	local cfg = CF[key]
	local data = DataService.get(player)
	if not cfg or not data then
		return { ok = false }
	end
	-- 1.8 Life Pack places: owners, or anyone during their one free preview; everyone else gets the honest card
	if cfg.NeedsPass and not (data.perks and data.perks.LifePack) and (tonumber(data.lifePreviewUntil) or 0) < os.time() then
		return { ok = false, card = true, price = Config.GamePasses.LifePack.price, previewUsed = data.lifePreviewUsed == true }
	end
	if not data.path or data.dead then
		return { ok = false, msg = TF.PickPath }
	end
	-- you have to be there (the screen opens from the counter inside)
	local spot = workspace:FindFirstChild("Station_" .. key, true)
	if not spot or not WorldService.near(player, spot.Position, CF.Radius) then
		return { ok = false, msg = TF.GoThere }
	end
	nextAt[player] = nextAt[player] or {}
	local t = nextAt[player][key]
	if t and os.clock() < t then
		return { ok = false, msg = string.format(TF.Wait, math.ceil(t - os.clock())) }
	end
	nextAt[player][key] = os.clock() + cfg.Cooldown
	local T = TF[key]
	if key == "fortune" then
		local kind = pickFortune()
		local lines = T[kind]
		local line = lines[math.random(1, #lines)]
		if data.path == "Lose" and kind == "silly" then
			BrainService.lose(player, cfg.SillyLose, "fortune")
		elseif data.path == "Gain" and kind == "wise" then
			BrainService.gain(player, cfg.WiseGain, "fortune")
		end
		return { ok = true, msg = line, kind = kind }
	end
	if data.path == "Lose" then
		BrainService.lose(player, cfg.Lose, key)
		return { ok = true, msg = T.LoseDone[math.random(1, #T.LoseDone)] }
	end
	if cfg.Gain then
		BrainService.gain(player, cfg.Gain, key)
	end
	if cfg.Stress then
		BrainService.stress(player, -cfg.Stress)
	end
	return { ok = true, msg = T.GainDone[math.random(1, #T.GainDone)] }
end)

-- 1.8: the free 2-minute Life Pack preview (once per player, saved)
Net.on("life_preview", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	if data.lifePreviewUsed then
		return { ok = false, msg = Content.LifePackPlaces.PreviewUsed }
	end
	data.lifePreviewUsed = true
	data.lifePreviewUntil = os.time() + CF.PreviewSeconds
	return { ok = true, msg = Content.LifePackPlaces.PreviewOn }
end)

function FunService.start()
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		nextAt[p] = nil
	end)
end

return FunService

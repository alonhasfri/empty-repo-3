-- PhoneShopService.lua (1.8, Life Pack plan step 1): the free Phone Shop on the Lose side.
--   * Phones: original parody names, paid with in-game coins only, price shown before buying.
--   * Case maker: colours + preset stickers. The Brainrot meter = how loud the case is.
--     "Show it off": Lose players lose cells (louder case = more); Gain players with a calm case get a stress drop.
--   * Scam stall "Totally Real Phones 👍": the "iBrainz 99 MEGA" is a calculator with a sticker.
--     Lose players can buy it (price shown, effect honestly "unknown"); using it loses cells.
--     Gain players see the red flags and can report the scammer for brain cells (teaches spotting scams).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local PhoneShopService = {}
local CP = Config.PhoneShop
local TP = Content.PhoneShop

local cooldowns = {} -- [player] = { [action] = os.clock() }

local function ready(player, action: string, seconds: number): boolean
	cooldowns[player] = cooldowns[player] or {}
	local t = cooldowns[player][action]
	if t and os.clock() < t then
		return false
	end
	cooldowns[player][action] = os.clock() + seconds
	return true
end

local function phoneData(data)
	if typeof(data.phone) ~= "table" then
		data.phone = {}
	end
	local p = data.phone
	p.owned = typeof(p.owned) == "table" and p.owned or { brick = true }
	p.owned.brick = true -- the free starter phone
	p.model = typeof(p.model) == "string" and p.owned[p.model] and p.model or "brick"
	p.color = typeof(p.color) == "string" and p.color or "grey"
	p.stickers = typeof(p.stickers) == "table" and p.stickers or {}
	p.scam = p.scam == true
	return p
end

local function find(list, key)
	for _, x in ipairs(list) do
		if x.key == key then
			return x
		end
	end
	return nil
end

local function rotOf(p): number
	local rot = 0
	local color = find(TP.Colors, p.color)
	rot += color and color.rot or 0
	for _, k in ipairs(p.stickers) do
		local s = find(TP.Stickers, k)
		rot += s and s.rot or 0
	end
	return rot
end

local function payload(data)
	local p = phoneData(data)
	local phones = {}
	for _, ph in ipairs(TP.Phones) do
		table.insert(phones, { key = ph.key, name = ph.name, price = ph.price, desc = ph.desc, owned = p.owned[ph.key] == true, using = p.model == ph.key })
	end
	return {
		ok = true,
		coins = data.coins,
		phones = phones,
		color = p.color,
		stickers = p.stickers,
		rot = rotOf(p),
		maxRot = CP.MaxRot,
		path = data.path,
		scam = p.scam,
	}
end

Net.on("phone_shop", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	return payload(data)
end)

Net.on("phone_buy", function(player, d)
	local data = DataService.get(player)
	local ph = data and find(TP.Phones, tostring(d.key))
	if not data or not ph then
		return { ok = false, msg = TP.Unknown }
	end
	local p = phoneData(data)
	if not p.owned[ph.key] then
		if data.coins < ph.price then
			return { ok = false, msg = string.format(TP.TooPoor, ph.price) }
		end
		data.coins -= ph.price
		p.owned[ph.key] = true
	end
	p.model = ph.key
	BrainService.push(player)
	local out = payload(data)
	out.msg = string.format(TP.Bought, ph.name)
	return out
end)

Net.on("case_set", function(player, d)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local p = phoneData(data)
	if typeof(d.color) == "string" and find(TP.Colors, d.color) then
		p.color = d.color
	end
	if typeof(d.stickers) == "table" then
		local clean, seen = {}, {}
		for _, k in ipairs(d.stickers) do
			if typeof(k) == "string" and find(TP.Stickers, k) and not seen[k] and #clean < CP.MaxStickers then
				seen[k] = true
				table.insert(clean, k)
			end
		end
		p.stickers = clean
	end
	return payload(data)
end)

Net.on("case_show", function(player)
	local data = DataService.get(player)
	if not data or not data.path or data.dead then
		return { ok = false, msg = TP.PickPath }
	end
	if not ready(player, "show", CP.ShowCooldown) then
		return { ok = false, msg = TP.Cooldown }
	end
	local rot = rotOf(phoneData(data))
	if data.path == "Lose" then
		if rot <= 0 then
			return { ok = true, msg = TP.ShowBoring }
		end
		BrainService.lose(player, rot * CP.ShowLosePerRot, "phonecase")
		return { ok = true, msg = string.format(TP.ShowLose, rot) }
	end
	if rot <= CP.CalmMaxRot then
		BrainService.stress(player, -CP.CalmStress)
		return { ok = true, msg = TP.ShowCalm }
	end
	return { ok = true, msg = TP.ShowTooLoud }
end)

Net.on("scam_buy", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	if data.path == "Gain" then
		return { ok = false, msg = TP.ScamGainNo }
	end
	local p = phoneData(data)
	if p.scam then
		return { ok = false, msg = TP.ScamAlready }
	end
	if data.coins < CP.ScamPrice then
		return { ok = false, msg = string.format(TP.TooPoor, CP.ScamPrice) }
	end
	data.coins -= CP.ScamPrice
	p.scam = true
	BrainService.push(player)
	return { ok = true, msg = TP.ScamBought }
end)

Net.on("scam_use", function(player)
	local data = DataService.get(player)
	if not data or not phoneData(data).scam then
		return { ok = false, msg = TP.ScamNone }
	end
	if not ready(player, "scamuse", CP.ScamUseCooldown) then
		return { ok = false, msg = TP.Cooldown }
	end
	if data.path == "Lose" and not data.dead then
		BrainService.lose(player, CP.ScamUseLose, "scamphone")
	end
	return { ok = true, msg = TP.ScamUsed[math.random(1, #TP.ScamUsed)] }
end)

Net.on("scam_report", function(player)
	local data = DataService.get(player)
	if not data or data.path ~= "Gain" or data.dead then
		return { ok = false, msg = TP.ReportGainOnly }
	end
	if not ready(player, "report", CP.ReportCooldown) then
		return { ok = false, msg = TP.ReportAlready }
	end
	BrainService.gain(player, CP.ReportGain, "scamreport")
	return { ok = true, msg = TP.Reported }
end)

function PhoneShopService.start()
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		cooldowns[p] = nil
	end)
end

return PhoneShopService

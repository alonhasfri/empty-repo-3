-- ShopService: game passes (honest joke passes on the Lose path, fair ones on the Gain path)
-- and pass perks that staff can gift.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local ShopService = {}

local function passKeyById(id: number): string?
	for key, pass in pairs(Config.GamePasses) do
		if pass.id ~= 0 and pass.id == id then
			return key
		end
	end
	return nil
end

-- Applies a pass's effect. chargeCells = true on a real purchase.
function ShopService.grant(player, key: string, chargeCells: boolean)
	local data = DataService.get(player)
	local pass = Config.GamePasses[key]
	if not data or not pass then
		return false
	end
	data.perks[key] = true
	if key == "BuyBrain" then
		data.perks.DunceCap = true
	end
	if chargeCells and pass.cellsLost > 0 and data.path == "Lose" and not data.dead then
		BrainService.setCells(player, data.cells - pass.cellsLost)
		BrainService.toast(player, "🧠📉 " .. pass.name .. " cost you " .. require(ReplicatedStorage.Shared.Brain).formatNumber(pass.cellsLost) .. " brain cells.", "RecordScratch")
	end
	BrainService.applyCharacter(player)
	BrainService.push(player)
	BrainService.toast(player, "✅ You got: " .. pass.name, "BadgeSparkle")
	return true
end

Net.on("shop_list", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local list = {}
	-- Astronaut Early Access (1.4) is only offered at IQ 160+ while nobody has invented Space Travel
	local Brain = require(ReplicatedStorage.Shared.Brain)
	local astroOffered = data.perks.AstronautEarly == true
		or (not BrainService.spaceInvented() and Brain.iq(data.cells) >= Config.Space.AstronautIQ)
	for key, pass in pairs(Config.GamePasses) do
		if (pass.path == data.path or pass.path == "Any") and (key ~= "AstronautEarly" or astroOffered) then
			table.insert(list, {
				key = key,
				id = pass.id,
				name = pass.name,
				desc = pass.desc,
				price = pass.price,
				cellsLost = pass.cellsLost,
				owned = data.perks[key] == true,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.price < b.price
	end)
	return {
		ok = true,
		passes = list,
		enabled = BrainService.feature("Purchases"),
		reminder = data.path == "Lose" and "Reminder: passes are optional. You can finish the whole game for free." or "Passes never help with Skill Gates.",
	}
end)

function ShopService.checkOwned(player)
	for key, pass in pairs(Config.GamePasses) do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			local data = DataService.get(player)
			if ok and owns and data and not data.perks[key] then
				ShopService.grant(player, key, false)
			end
		end
	end
end

function ShopService.start()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = passKeyById(passId)
		if key then
			ShopService.grant(player, key, true)
		end
	end)
end

return ShopService

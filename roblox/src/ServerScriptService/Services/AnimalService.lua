-- AnimalService (update 1.6): animal powers (from web/src/v16.js).
--   🐶 Dog: BARK (pigeons fly off, nearby players hear it)
--   🪰 Fly / 🐝 Bee: BUZZ UP (the client pushes you up into the air)
--   🪱 Worm: DIG a tunnel to another building
-- The bodies are built by AnimalForms; text in Content.Animals, numbers in Config.Animals.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)
local Rooms = require(script.Parent.Rooms)

local AnimalService = {}

local CA = Config.Animals
local T = Content.Animals
local lastUse = {} -- [player] = os.clock()

Net.on("animal_power", function(player)
	local data = DataService.get(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not data or not root or not hum or hum.Health <= 0 or data.dead then
		return { ok = false }
	end
	local key = Brain.stage(data.cells, BrainService.secretAnimals).key
	local power = CA.Powers[key]
	if not power then
		return { ok = false }
	end
	local blocked = BrainService.blocked(player)
	if blocked then
		return { ok = false, msg = "⛔ " .. blocked }
	end
	local now = os.clock()
	if lastUse[player] and now - lastUse[player] < CA.PowerCooldown then
		return { ok = false, msg = T.Wait }
	end
	lastUse[player] = now
	if power == "bark" then
		BrainService.toast(player, T.Woof, "CartoonBoing")
		WorldService.pigeonBurst(root.Position)
		for _, other in ipairs(Players:GetPlayers()) do
			local oroot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if oroot and (oroot.Position - root.Position).Magnitude <= CA.BarkRadius then
				BrainService.toast(other, string.format(T.BarkedAt, player.DisplayName))
			end
		end
		return { ok = true, power = power }
	elseif power == "buzz" then
		return { ok = true, power = power, up = CA.BuzzUp }
	elseif power == "dig" then
		local here = Rooms.buildingAt(root.Position)
		local choices = {}
		for _, p in ipairs(WorldService.Places) do
			if p.key ~= here and WorldService.Spots[p.key] then
				table.insert(choices, p)
			end
		end
		local to = choices[math.random(1, #choices)]
		Rooms.standUp(hum)
		WorldService.teleport(player, to.key)
		BrainService.toast(player, string.format(T.Dug, to.name), "CartoonBoing")
		return { ok = true, power = power }
	end
	return { ok = false }
end)

Players.PlayerRemoving:Connect(function(p)
	lastUse[p] = nil
end)

return AnimalService

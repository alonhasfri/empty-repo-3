-- AdoptService (1.9.1, big ideas #10): a human player can ask to adopt a player who is an animal.
--   * The animal gets "🐶 <name> wants to adopt you! Accept?" with Yes / No / Block. Nothing happens without Yes.
--   * Adopted: a "🐾 <owner>'s pet" tag, treats every few minutes while near the owner, and the owner can
--     call the pet (a smell trail leads the pet to them). Nobody is ever moved or held by force.
--   * Either side can end it any time (✕ in the animal menu / the Home app). It also ends when one of them
--     leaves the game or the pet becomes human again. No Robux, no trading, nothing saved.
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

local AdoptService = {}
local CA = Config.Adopt
local TA = Content.Adopt

local owner = {} -- [pet] = owner Player
local pending = {} -- [pet] = { from = Player, at = os.clock() }
local blocked = {} -- [pet] = { [userId] = true } (this server only)
local lastAsk = {} -- [asker] = os.clock()

local function stageKey(p: Player): string?
	local d = DataService.get(p)
	return d and Brain.stage(d.cells, BrainService.secretAnimals).key or nil
end

local function tagPet(pet: Player, ownerName: string?)
	local head = pet.Character and pet.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("PetTag")
	if old then
		old:Destroy()
	end
	if not ownerName then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "PetTag"
	bb.Size = UDim2.fromOffset(180, 30)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.MaxDistance = 80
	bb.Parent = head
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(255, 220, 120)
	l.TextStrokeTransparency = 0.4
	l.Text = string.format(TA.Tag, ownerName)
	l.Parent = bb
end

local function endAdoption(pet: Player, why: string?)
	local o = owner[pet]
	if not o then
		return
	end
	owner[pet] = nil
	pet:SetAttribute("AdoptedBy", nil)
	tagPet(pet, nil)
	if why then
		if pet.Parent then
			BrainService.toast(pet, why)
		end
		if o.Parent then
			BrainService.toast(o, why)
		end
	end
end

function AdoptService.petOf(o: Player): Player?
	for pet, who in pairs(owner) do
		if who == o then
			return pet
		end
	end
	return nil
end

Net.on("adopt_ask", function(player, d)
	local pet = typeof(d) == "table" and Players:GetPlayerByUserId(tonumber(d.userId) or 0) or nil
	if not pet or pet == player then
		return { ok = false }
	end
	if Rooms.isAnimal(player) then
		return { ok = false, msg = TA.AnimalsCant }
	end
	if not Rooms.isAnimal(pet) then
		return { ok = false, msg = TA.NotAnimal }
	end
	if owner[pet] then
		return { ok = false, msg = string.format(TA.Taken, pet.DisplayName) }
	end
	if AdoptService.petOf(player) then
		return { ok = false, msg = TA.OnePet }
	end
	if blocked[pet] and blocked[pet][player.UserId] then
		return { ok = false, msg = TA.NoThanks }
	end
	local root = pet.Character and pet.Character:FindFirstChild("HumanoidRootPart")
	if not root or not WorldService.near(player, root.Position, CA.AskRadius) then
		return { ok = false, msg = TA.TooFar }
	end
	if (lastAsk[player] or 0) > os.clock() then
		return { ok = false, msg = TA.Wait }
	end
	lastAsk[player] = os.clock() + CA.AskCooldown
	pending[pet] = { from = player, at = os.clock() }
	Net.send(pet, "adoptAsk", { from = player.DisplayName, fromId = player.UserId, icon = Brain.stage(DataService.get(pet).cells, BrainService.secretAnimals).emoji })
	return { ok = true, msg = string.format(TA.Asked, pet.DisplayName) }
end)

Net.on("adopt_answer", function(pet, d)
	local p = pending[pet]
	pending[pet] = nil
	if not p or typeof(d) ~= "table" or tonumber(d.fromId) ~= p.from.UserId or os.clock() - p.at > CA.AnswerSeconds then
		return { ok = false }
	end
	local asker = p.from
	if d.block then
		blocked[pet] = blocked[pet] or {}
		blocked[pet][asker.UserId] = true
		BrainService.toast(asker, string.format(TA.Declined, pet.DisplayName))
		return { ok = true }
	end
	if not d.yes then
		BrainService.toast(asker, string.format(TA.Declined, pet.DisplayName))
		return { ok = true }
	end
	if not asker.Parent or not Rooms.isAnimal(pet) or owner[pet] then
		return { ok = false }
	end
	owner[pet] = asker
	pet:SetAttribute("AdoptedBy", asker.DisplayName)
	tagPet(pet, asker.DisplayName)
	BrainService.toast(asker, string.format(TA.NowOwner, pet.DisplayName), "LevelUp")
	return { ok = true, msg = string.format(TA.NowPet, asker.DisplayName) }
end)

-- either side ends it, any time
Net.on("adopt_end", function(player)
	if owner[player] then
		endAdoption(player, TA.Ended)
		return { ok = true }
	end
	local pet = AdoptService.petOf(player)
	if pet then
		endAdoption(pet, TA.Ended)
		return { ok = true }
	end
	return { ok = false }
end)

-- the owner calls the pet: a smell trail leads the pet to the owner
Net.on("adopt_call", function(player)
	local pet = AdoptService.petOf(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not pet or not root then
		return { ok = false }
	end
	Net.send(pet, "animalTarget", { x = root.Position.X, z = root.Position.Z, icon = "📣" })
	BrainService.toast(pet, string.format(TA.Called, player.DisplayName), "NotificationPing")
	return { ok = true, msg = string.format(TA.Calling, pet.DisplayName) }
end)

Net.on("adopt_info", function(player)
	local pet = AdoptService.petOf(player)
	return { ok = true, pet = pet and pet.DisplayName or nil, owner = owner[player] and owner[player].DisplayName or nil }
end)

-- every few seconds: tell clients who is an animal (for the Adopt prompt), end adoptions that no
-- longer make sense, and give treats to pets near their owner
task.spawn(function()
	local treatClock = 0
	while true do
		task.wait(CA.Tick)
		treatClock += CA.Tick
		for _, p in ipairs(Players:GetPlayers()) do
			local key = stageKey(p)
			p:SetAttribute("AnimalStage", Rooms.isAnimal(p) and key or nil)
		end
		for pet, o in pairs(owner) do
			if not pet.Parent or not o.Parent then
				endAdoption(pet, nil)
			elseif not Rooms.isAnimal(pet) then
				endAdoption(pet, TA.Grown)
			else
				local head = pet.Character and pet.Character:FindFirstChild("Head")
				if head and not head:FindFirstChild("PetTag") then
					tagPet(pet, o.DisplayName) -- respawned: put the tag back
				end
			end
			if owner[pet] and treatClock >= CA.TreatEvery then
				local root = o.Character and o.Character:FindFirstChild("HumanoidRootPart")
				local d = DataService.get(pet)
				if root and d and WorldService.near(pet, root.Position, CA.TreatRadius) then
					d.coins = (d.coins or 0) + CA.TreatCoins
					BrainService.toast(pet, string.format(TA.Treat, CA.TreatCoins), "CartoonBoing")
					BrainService.push(pet)
				end
			end
		end
		if treatClock >= CA.TreatEvery then
			treatClock = 0
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	if owner[p] then
		endAdoption(p, nil)
	end
	local pet = AdoptService.petOf(p)
	if pet then
		endAdoption(pet, TA.OwnerLeft)
	end
	pending[p] = nil
	blocked[p] = nil
	lastAsk[p] = nil
end)

return AdoptService

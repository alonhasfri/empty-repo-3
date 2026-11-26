-- PetFriendService.lua (1.8, Life Pack plan step 5, first part): pets and the friends meter.
--   * Pets (Life Pack): adopt a 🐶 dog, 🐱 cat or 🐟 goldfish at the Toy Store screen. It floats along beside you.
--   * Friends meter (everyone, kid-safe): preset high-fives with players near you.
--     Friend → Good friend → Best friend 🤝. Friends and family only: never dating (Roblox rules).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)
local WorldService = require(script.Parent.WorldService)

local PetFriendService = {}
local CP = Config.PetsFriends
local TP = Content.PetsFriends

local function petModel(kind: string)
	local look = CP.Pets[kind]
	local m = Instance.new("Model")
	m.Name = "Pet"
	local body = Instance.new("Part")
	body.Name = "PetBody"
	body.Size = look.size
	body.Color = look.color
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.Massless = true
	body.Parent = m
	local head = body:Clone()
	head.Name = "PetHead"
	head.Size = look.head
	head.Parent = m
	local hw = Instance.new("WeldConstraint")
	head.CFrame = body.CFrame * CFrame.new(0, look.size.Y / 2, -look.size.Z / 2)
	hw.Part0, hw.Part1 = body, head
	hw.Parent = body
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(60, 30)
	tag.StudsOffset = Vector3.new(0, 2, 0)
	tag.MaxDistance = 60
	tag.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Name = "PetTagText"
	t.Text = TP.PetNames[kind]
	t.Parent = tag
	m.PrimaryPart = body
	return m
end

-- the pet rides beside you (welded, massless: it never trips you up)
local function attachPet(player: Player)
	local data = DataService.get(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local old = char:FindFirstChild("Pet")
	if old then
		old:Destroy()
	end
	local kind = data.pet
	if not kind or not CP.Pets[kind] or not PetFriendService.owns(data, kind) then
		return
	end
	local m = petModel(kind)
	m:PivotTo(root.CFrame * CFrame.new(3, CP.Pets[kind].float, 1))
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = root, m.PrimaryPart
	w.Parent = m.PrimaryPart
	m.Parent = char
end

-- 1.9.1 big ideas #17: pets for everyone. The Life Pack still gives them all; anyone can also buy one
-- with coins (price shown first) or win one at a life event. Owned pets: data.petsOwned (nil-safe).
function PetFriendService.owns(data, kind: string): boolean
	if data.perks and data.perks.LifePack then
		return true
	end
	return typeof(data.petsOwned) == "table" and data.petsOwned[kind] == true
end

function PetFriendService.give(player: Player, kind: string): boolean
	local data = DataService.get(player)
	if not data or not CP.Pets[kind] then
		return false
	end
	data.petsOwned = typeof(data.petsOwned) == "table" and data.petsOwned or {}
	local new = not data.petsOwned[kind]
	data.petsOwned[kind] = true
	if not data.pet then
		data.pet = kind
		attachPet(player)
	end
	return new
end

Net.on("pet_list", function(player)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local list = {}
	for _, kind in ipairs(CP.ShopOrder) do
		table.insert(list, { kind = kind, icon = TP.PetNames[kind], name = TP.ShopNames[kind], price = CP.Prices[kind], owned = PetFriendService.owns(data, kind), out = data.pet == kind })
	end
	return { ok = true, list = list, coins = data.coins or 0 }
end)

Net.on("pet_buy", function(player, d)
	local data = DataService.get(player)
	local kind = typeof(d) == "table" and tostring(d.kind) or ""
	local price = CP.Prices[kind]
	if not data or not price then
		return { ok = false }
	end
	if PetFriendService.owns(data, kind) then
		return { ok = false, msg = TP.AlreadyOwn }
	end
	if (data.coins or 0) < price then
		return { ok = false, msg = string.format(TP.Poor, price) }
	end
	data.coins -= price
	PetFriendService.give(player, kind)
	data.pet = kind
	attachPet(player)
	BrainService.push(player)
	return { ok = true, msg = string.format(TP.Bought, TP.PetNames[kind], price) }
end)

Net.on("pet_adopt", function(player, d)
	local data = DataService.get(player)
	if not data then
		return { ok = false }
	end
	local kind = tostring(d.kind)
	if kind ~= "none" and not CP.Pets[kind] then
		return { ok = false }
	end
	if kind ~= "none" and not PetFriendService.owns(data, kind) then
		return { ok = false, msg = TP.NeedPass }
	end
	data.pet = kind ~= "none" and kind or nil
	attachPet(player)
	return { ok = true, msg = kind == "none" and TP.PetHome or string.format(TP.Adopted, TP.PetNames[kind]) }
end)

local lastFive = {} -- [player] = os.clock()
Net.on("high_five", function(player, d)
	local data = DataService.get(player)
	local other = Players:GetPlayerByUserId(tonumber(d.userId) or 0)
	if not data or not other or other == player then
		return { ok = false, msg = TP.NoOne }
	end
	local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
	if not root or not WorldService.near(player, root.Position, CP.HighFiveRadius) then
		return { ok = false, msg = TP.TooFar }
	end
	if (lastFive[player] or 0) > os.clock() then
		return { ok = false, msg = TP.Wait }
	end
	lastFive[player] = os.clock() + CP.HighFiveCooldown
	local od = DataService.get(other)
	if not od then
		return { ok = false }
	end
	data.friends = typeof(data.friends) == "table" and data.friends or {}
	od.friends = typeof(od.friends) == "table" and od.friends or {}
	local a, b = tostring(other.UserId), tostring(player.UserId)
	-- capped so a long friendship never bloats the save
	data.friends[a] = math.min(CP.MaxPoints, (tonumber(data.friends[a]) or 0) + 1)
	od.friends[b] = math.min(CP.MaxPoints, (tonumber(od.friends[b]) or 0) + 1)
	local function level(n)
		local name = TP.Levels[1]
		for i, need in ipairs(CP.Levels) do
			if n >= need then
				name = TP.Levels[i]
			end
		end
		return name
	end
	BrainService.toast(other, string.format(TP.GotFive, player.DisplayName, level(od.friends[b])), "CartoonBoing")
	return { ok = true, msg = string.format(TP.GaveFive, other.DisplayName, level(data.friends[a])) }
end)

-- 1.9.1 big ideas #17: your pet gets smarter or sillier with you (a little badge on its tag)
local function petMood(data): string
	local cells = data.cells or 0
	if data.path == "Gain" then
		local iq = require(ReplicatedStorage.Shared.Brain).iq(cells)
		return (iq >= CP.SmartPetIQ and TP.Moods.genius) or (iq >= CP.NicePetIQ and TP.Moods.smart) or ""
	elseif data.path == "Lose" then
		return cells < CP.SillyPetCells and TP.Moods.verysilly or TP.Moods.silly
	end
	return ""
end

task.spawn(function()
	while true do
		task.wait(10)
		for _, p in ipairs(Players:GetPlayers()) do
			local data = DataService.get(p)
			local pet = p.Character and p.Character:FindFirstChild("Pet")
			local label = pet and pet:FindFirstChild("PetTagText", true)
			if data and data.pet and label then
				label.Text = (TP.PetNames[data.pet] or "🐾") .. petMood(data)
			end
		end
	end
end)

function PetFriendService.start()
	local function watch(p)
		p.CharacterAdded:Connect(function()
			task.delay(2, attachPet, p)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastFive[p] = nil
	end)
end

return PetFriendService

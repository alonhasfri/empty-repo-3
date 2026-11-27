-- MachineService (1.9.3, user request): MACHINES are useful items you can invent (Config.Machines,
-- Content.Machines). They live in the Roblox hotbar as Tools.
--   * The inventor keeps the machine for good (saved in data.machines).
--   * Everyone in the inventor's server gets one too (until they leave).
--   * Every OTHER server borrows it for Config.Machines.GlobalMinutes (MessagingService "BrainMachine").
-- Machines are invented through the Eureka cards (GainService) or the admin "givemachine" command.
-- The client side (Client/Machines.lua) runs the Trace Teleporter, the Jetpack and the Bounce Pad;
-- the server checks ownership, cooldowns and the teleport path.
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local CM = Config.Machines
local TM = Content.Machines
local MachineService = {}

local serverGrant = {} -- [key] = true: someone in THIS server invented it
local globalUntil = {} -- [key] = os.time() it stops being borrowed from another server
local cooldowns = {} -- [player] = { [key] = os.clock() }

local function def(key: string)
	for _, m in ipairs(TM.List) do
		if m.key == key then
			return m
		end
	end
	return nil
end
MachineService.def = def

function MachineService.has(player: Player, key: string): boolean
	local data = DataService.get(player)
	if data and typeof(data.machines) == "table" and data.machines[key] then
		return true
	end
	return serverGrant[key] == true or (globalUntil[key] or 0) > os.time()
end

function MachineService.uninvented(data)
	local list = {}
	for _, m in ipairs(TM.List) do
		if not (typeof(data.machines) == "table" and data.machines[m.key]) then
			table.insert(list, m)
		end
	end
	return list
end

-- make the hotbar match what this player may use right now
function MachineService.refresh(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local have = {}
	for _, holder in ipairs({ backpack, player.Character }) do
		if holder then
			for _, t in ipairs(holder:GetChildren()) do
				local key = t:IsA("Tool") and t:GetAttribute("Machine")
				if key then
					if MachineService.has(player, key) then
						have[key] = true
					else
						t:Destroy() -- a borrowed machine went back
					end
				end
			end
		end
	end
	for _, m in ipairs(TM.List) do
		if not have[m.key] and MachineService.has(player, m.key) then
			local tool = Instance.new("Tool")
			tool.Name = m.icon .. " " .. m.name
			tool.ToolTip = m.desc
			tool.RequiresHandle = false
			tool.CanBeDropped = false
			tool:SetAttribute("Machine", m.key)
			local iconId = Config.Icons and Config.Icons[m.key]
			if iconId then
				tool.TextureId = "rbxassetid://" .. tostring(iconId)
			end
			tool.Parent = backpack
		end
	end
end

local function refreshAll()
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(MachineService.refresh, p)
	end
end

-- someone in this server invented a machine
function MachineService.invent(player: Player, key: string): boolean
	local m = def(key)
	local data = DataService.get(player)
	if not m or not data then
		return false
	end
	if typeof(data.machines) ~= "table" then
		data.machines = {}
	end
	data.machines[key] = true
	serverGrant[key] = true
	refreshAll()
	for _, p in ipairs(Players:GetPlayers()) do
		BrainService.toast(p, string.format(TM.Invented, player.DisplayName, m.name), "LevelUp")
	end
	local expiry = os.time() + CM.GlobalMinutes * 60
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync("BrainMachine", { key = key, by = player.DisplayName, from = game.JobId, expiry = expiry })
		end)
	end)
	return true
end

local function borrow(key: string, by: string, expiry: number)
	local m = def(key)
	if not m or serverGrant[key] then
		return
	end
	expiry = math.min(expiry, os.time() + CM.GlobalMinutes * 60) -- never longer than the rule
	globalUntil[key] = math.max(globalUntil[key] or 0, expiry)
	refreshAll()
	for _, p in ipairs(Players:GetPlayers()) do
		BrainService.toast(p, string.format(TM.Global, by, m.name, CM.GlobalMinutes), "NotificationPing")
	end
	task.delay(math.max(1, expiry - os.time()) + 1, function()
		if (globalUntil[key] or 0) <= os.time() then
			refreshAll()
			for _, p in ipairs(Players:GetPlayers()) do
				local data = DataService.get(p)
				if not (data and typeof(data.machines) == "table" and data.machines[key]) then
					BrainService.toast(p, string.format(TM.Expired, m.name))
				end
			end
		end
	end)
end

local function ready(player: Player, key: string)
	if not MachineService.has(player, key) then
		return false, "You don't have that machine."
	end
	cooldowns[player] = cooldowns[player] or {}
	local left = (cooldowns[player][key] or 0) - os.clock()
	if left > 0 then
		return false, string.format(TM.Recharging, math.ceil(left))
	end
	return true
end

local function startCooldown(player: Player, key: string)
	cooldowns[player] = cooldowns[player] or {}
	cooldowns[player][key] = os.clock() + CM[key].cooldown
end

-- the client asks before opening trace mode (so a recharging teleporter says so right away)
Net.on("machine_check", function(player, d)
	local key = typeof(d) == "table" and tostring(d.key) or ""
	local ok, msg = ready(player, key)
	return { ok = ok, msg = msg }
end)

-- a teleport path: the client sends the ghost's points; the server checks every step
local function pathOk(player: Player, points): (boolean, string?)
	local C = CM.teleporter
	if typeof(points) ~= "table" or #points < 2 or #points > C.maxPoints then
		return false, TM.NoPath
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, nil
	end
	local params = RaycastParams.new()
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local total = 0
	local prev = nil
	for i, p in ipairs(points) do
		if typeof(p) ~= "table" or typeof(p[1]) ~= "number" or typeof(p[2]) ~= "number" or typeof(p[3]) ~= "number" then
			return false, nil
		end
		local v = Vector3.new(p[1], p[2], p[3])
		if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then
			return false, nil
		end
		if i == 1 then
			if (v - root.Position).Magnitude > 10 then
				return false, nil
			end
		else
			local seg = v - prev
			total += seg.Magnitude
			if seg.Magnitude > C.step * 4 then
				return false, nil
			end
			if total > C.maxStuds + 1 then
				return false, TM.TooFar
			end
			if seg.Magnitude > 0.05 and workspace:Raycast(prev + Vector3.new(0, 1, 0), seg, params) then
				return false, TM.Blocked
			end
		end
		prev = v
	end
	return true, nil
end

Net.on("machine_use", function(player, d)
	if typeof(d) ~= "table" then
		return { ok = false }
	end
	local key = tostring(d.key)
	if not CM[key] or not def(key) then
		return { ok = false }
	end
	local ok, msg = ready(player, key)
	if not ok then
		return { ok = false, msg = msg }
	end
	if key == "teleporter" then
		local good, why = pathOk(player, d.points)
		if not good then
			return { ok = false, msg = why or TM.Blocked }
		end
	elseif key == "bouncepad" then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			return { ok = false }
		end
		local C = CM.bouncepad
		local spot = root.CFrame * CFrame.new(0, 0, -6)
		local hit = workspace:Raycast(spot.Position + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0))
		local y = hit and hit.Position.Y or (root.Position.Y - 3)
		local pad = Instance.new("Part")
		pad.Name = "BouncePad"
		pad.Anchored = true
		pad.Size = Vector3.new(6, 0.6, 6)
		pad.Shape = Enum.PartType.Cylinder
		pad.Size = Vector3.new(0.6, 6, 6)
		pad.CFrame = CFrame.new(spot.Position.X, y + 0.3, spot.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		pad.Color = Color3.fromRGB(60, 220, 120)
		pad.Material = Enum.Material.Neon
		pad.Parent = workspace
		local last = {}
		pad.Touched:Connect(function(part)
			local p = Players:GetPlayerFromCharacter(part.Parent)
			if p and (last[p] or 0) < os.clock() then
				last[p] = os.clock() + 1
				Net.send(p, "machineBounce", { power = C.power })
			end
		end)
		task.delay(C.seconds, function()
			pad:Destroy()
		end)
		msg = TM.PadPlaced
	elseif key == "jetpack" then
		msg = TM.Jetpack
	end
	startCooldown(player, key)
	return { ok = true, msg = msg, cooldown = CM[key].cooldown }
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1.2)
		MachineService.refresh(player)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function()
		task.wait(1.2)
		MachineService.refresh(p)
	end)
	task.spawn(MachineService.refresh, p)
end
Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)

task.spawn(function()
	pcall(function()
		MessagingService:SubscribeAsync("BrainMachine", function(msg)
			local d = msg.Data
			if typeof(d) == "table" and d.from ~= game.JobId and typeof(d.key) == "string" and typeof(d.expiry) == "number" then
				borrow(d.key, tostring(d.by or "Someone"), d.expiry)
			end
		end)
	end)
end)

return MachineService

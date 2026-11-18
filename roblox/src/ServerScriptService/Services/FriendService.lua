-- FriendService: builds REAL avatar models for each player's NPC friends,
-- using the player's actual Roblox friends (their avatars and display names).
-- Falls back to default people if the friends list can't be loaded.
-- Models are stored in ReplicatedStorage > FriendModels > <UserId>; only that
-- player's screen clones and shows them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendService = {}

local folder = Instance.new("Folder")
folder.Name = "FriendModels"
folder.Parent = ReplicatedStorage

local FALLBACK = {
	{ name = "Kyle", skin = Color3.fromRGB(234, 184, 146), shirt = Color3.fromRGB(220, 60, 60), pants = Color3.fromRGB(40, 50, 90) },
	{ name = "Mia", skin = Color3.fromRGB(160, 110, 80), shirt = Color3.fromRGB(80, 160, 240), pants = Color3.fromRGB(30, 30, 40) },
	{ name = "Zeke", skin = Color3.fromRGB(250, 214, 180), shirt = Color3.fromRGB(250, 200, 50), pants = Color3.fromRGB(70, 110, 60) },
}

local function defaultDescription(i: number): HumanoidDescription
	local f = FALLBACK[i]
	local d = Instance.new("HumanoidDescription")
	d.HeadColor = f.skin
	d.LeftArmColor = f.skin
	d.RightArmColor = f.skin
	d.TorsoColor = f.shirt
	d.LeftLegColor = f.pants
	d.RightLegColor = f.pants
	return d
end

function FriendService.makeModel(desc: HumanoidDescription, name: string): Model?
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[FriendService] couldn't build avatar: " .. tostring(model))
		return nil
	end
	model.Name = name
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	return model
end

function FriendService.build(player: Player)
	task.spawn(function()
		local list = {}
		pcall(function()
			local pages = Players:GetFriendsAsync(player.UserId)
			for _, fr in ipairs(pages:GetCurrentPage()) do
				table.insert(list, fr)
			end
		end)
		for i = #list, 2, -1 do
			local j = math.random(1, i)
			list[i], list[j] = list[j], list[i]
		end
		local f = Instance.new("Folder")
		f.Name = tostring(player.UserId)
		for i = 1, 3 do
			local fr = list[i]
			local desc, name = nil, FALLBACK[i].name
			if fr then
				local ok, d = pcall(function()
					return Players:GetHumanoidDescriptionFromUserId(fr.Id)
				end)
				if ok and d then
					desc = d
					name = fr.DisplayName or fr.Username or name
				end
			end
			desc = desc or defaultDescription(i)
			local model = FriendService.makeModel(desc, "Friend" .. i)
			if not model and desc ~= nil then
				model = FriendService.makeModel(defaultDescription(i), "Friend" .. i)
				name = FALLBACK[i].name
			end
			if model then
				model:SetAttribute("FriendName", name)
				model.Parent = f
			end
		end
		if player.Parent then
			f.Parent = folder
		end
	end)
end

function FriendService.cleanup(player: Player)
	local f = folder:FindFirstChild(tostring(player.UserId))
	if f then
		f:Destroy()
	end
end

-- A plain grey person for the Perfectly Average guy and other NPCs
function FriendService.npc(name: string, skin: Color3?, shirt: Color3?, pants: Color3?): Model?
	local d = Instance.new("HumanoidDescription")
	local s = skin or Color3.fromRGB(200, 170, 140)
	d.HeadColor = s
	d.LeftArmColor = s
	d.RightArmColor = s
	d.TorsoColor = shirt or Color3.fromRGB(150, 150, 150)
	d.LeftLegColor = pants or Color3.fromRGB(110, 110, 110)
	d.RightLegColor = pants or Color3.fromRGB(110, 110, 110)
	return FriendService.makeModel(d, name)
end

return FriendService

-- HighFive.lua (1.8): a "High-five" prompt over every other player (client-only prompt, preset action).
-- The server checks distance and keeps the friends meter (Friend → Good friend → Best friend).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local me = Players.LocalPlayer
local TP = Content.PetsFriends

local function addPrompt(p: Player, char: Model)
	if p == me then
		return
	end
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root or root:FindFirstChild("HighFivePrompt") then
		return
	end
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "HighFivePrompt"
	pp.ActionText = TP.HighFive
	pp.ObjectText = p.DisplayName
	pp.MaxActivationDistance = 10
	pp.RequiresLineOfSight = false
	pp.Parent = root
	pp.Triggered:Connect(function()
		local r = Remote.call("high_five", { userId = p.UserId })
		UI.toast(tostring(r.msg or ""), r.ok and UI.Colors.good or UI.Colors.bad)
	end)
end

local function watch(p: Player)
	p.CharacterAdded:Connect(function(c)
		addPrompt(p, c)
	end)
	if p.Character then
		task.spawn(addPrompt, p, p.Character)
	end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do
	watch(p)
end

return {}

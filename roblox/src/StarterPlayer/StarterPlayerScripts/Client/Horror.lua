-- Horror.lua (1.7.3): client side of "The Average Files", part 1.
-- Shows the beige notes you're allowed to find, the note reader, and far-away "sightings" of the
-- Perfectly Average guy (he stands still in the distance and is gone when you walk closer or look again).
-- Spooky mode never jump-scares: sightings are far away, silent and slow. Effects at 0 or Reduced Motion: no sightings.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local CH = Config.Horror
local TH = Content.Horror
local player = Players.LocalPlayer
local Horror = {}

local state = { stage = 0, notes = {}, setting = "spooky" }

local function refreshNotes()
	local folder = workspace:FindFirstChild("AverageNotes")
	if not folder then
		return
	end
	for _, p in ipairs(folder:GetChildren()) do
		local i = p:GetAttribute("NoteIndex")
		local can = state.setting ~= "off" and state.stage >= (CH.NoteGate[i] or 1) and not state.notes[tostring(i)]
		p.LocalTransparencyModifier = 0
		p.Transparency = can and 0 or 1
		local pp = p:FindFirstChildOfClass("ProximityPrompt")
		if pp then
			pp.Enabled = can
		end
	end
end

Remote.on("horrorState", function(d)
	state.stage = tonumber(d.stage) or 0
	state.notes = d.notes or {}
	state.setting = d.setting or "spooky"
	refreshNotes()
end)

Remote.on("horrorNote", function(d)
	local i = tonumber(d.index) or 1
	local m = UI.modal(string.format(TH.NoteTitle, i, tonumber(d.total) or #CH.NoteSpots), { color = Color3.fromRGB(150, 140, 115) })
	local body = d.animal and TH.AnimalNote or (TH.Notes[i] or "")
	UI.label(m.content, body, { LayoutOrder = 1, Font = Enum.Font.SpecialElite })
	m.focus()
	UI.sound("NotificationPing", 0.3)
end)

-- the folder is built a moment after the server starts
task.spawn(function()
	workspace:WaitForChild("AverageNotes", 30)
	task.wait(1)
	Remote.call("horror_state")
end)

-- Sightings: from stage 1, now and then he stands far away for a few seconds
local function sighting()
	local town = workspace:FindFirstChild("Town")
	local src = town and town:FindFirstChild("PerfectlyAverageGuy")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	if not src or not root or not cam then
		return
	end
	local ghost = src:Clone()
	for _, d in ipairs(ghost:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	-- far away, roughly where you'd glance at: off to the side of the camera, on the ground
	local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
	if look.Magnitude < 0.1 then
		return
	end
	look = look.Unit
	local side = Vector3.new(-look.Z, 0, look.X) * (math.random() < 0.5 and -1 or 1)
	local spot = root.Position + (look * 0.6 + side * 0.8).Unit * CH.SightingDistance
	local hit = workspace:Raycast(spot + Vector3.new(0, 60, 0), Vector3.new(0, -200, 0))
	if not hit then
		ghost:Destroy()
		return
	end
	local _, size = ghost:GetBoundingBox()
	ghost:PivotTo(CFrame.lookAt(hit.Position + Vector3.new(0, size.Y / 2, 0), Vector3.new(root.Position.X, hit.Position.Y + size.Y / 2, root.Position.Z)))
	ghost.Name = "AverageSighting"
	ghost.Parent = cam
	local t0 = os.clock()
	while ghost.Parent and os.clock() - t0 < CH.SightingSeconds do
		task.wait(0.2)
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - ghost:GetPivot().Position).Magnitude < CH.SightingVanishAt then
			break -- walk toward him and he's simply not there any more
		end
	end
	ghost:Destroy()
end

task.spawn(function()
	while true do
		task.wait(CH.SightingEvery + math.random() * CH.SightingJitter)
		if state.stage >= 1 and state.setting ~= "off" and UI.effects() > 0 and not UI.reducedMotion() then
			pcall(sighting)
		end
	end
end)

function Horror.setting(): string
	return state.setting
end

return Horror

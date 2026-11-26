-- Watchdog.lua (1.8.8 fix, user: "sometimes you get stuck and can't move", mostly on phones).
-- Several features hold you still on purpose (conversations anchor you, hide the thumbstick and
-- take the camera). If one of them ends without cleaning up, you were stuck for good.
-- Every second this checks: if NO known lock is active but you are still held (anchored, sitting,
-- platform-standing, speed 0, thumbstick hidden, scripted camera) for Config.Watchdog.Seconds,
-- it frees you and says so once. Unstuck calls Watchdog.freeNow() too.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local Watchdog = {}
Watchdog.isLocked = nil -- function(): boolean, set by ClientMain (conversation, cutscene, ...)

local heldFor = 0
local lastPos = nil
local triedToMove = false -- only say "we freed you" if the player was actually trying to walk

local function held(): (boolean, Humanoid?, BasePart?)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return false, nil, nil
	end
	local touchOff = false
	pcall(function()
		touchOff = GuiService.TouchControlsEnabled == false
	end)
	local cam = workspace.CurrentCamera
	local stuck = root.Anchored or hum.PlatformStand or hum.WalkSpeed <= 0 or touchOff or (cam and cam.CameraType == Enum.CameraType.Scriptable)
	-- sitting is fine on a seat; it's only stuck if you're "sitting" on nothing
	if hum.Sit and not hum.SeatPart then
		stuck = true
	end
	return stuck, hum, root
end

function Watchdog.freeNow(say: boolean?)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = false
	end
	if hum then
		hum.PlatformStand = false
		if hum.Sit then
			hum.Sit = false
		end
		if hum.WalkSpeed <= 0 then
			hum.WalkSpeed = Config.Watchdog.RestoreWalk
		end
		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = hum
		end
	end
	pcall(function()
		GuiService.TouchControlsEnabled = true
	end)
	if UI.gui then
		UI.gui.Enabled = true
	end
	heldFor = 0
	triedToMove = false
	if say then
		UI.toast(Content.Watchdog.Freed)
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		local locked = Watchdog.isLocked and Watchdog.isLocked() or false
		local stuck, hum, root = held()
		if root and lastPos and (root.Position - lastPos).Magnitude > 1 then
			heldFor = 0
		end
		lastPos = root and root.Position or nil
		if stuck and not locked then
			heldFor += 1
			if hum and hum.MoveDirection.Magnitude > 0.1 then
				triedToMove = true
			end
			if heldFor >= Config.Watchdog.Seconds then
				Watchdog.freeNow(triedToMove)
			end
		else
			heldFor = 0
			triedToMove = false
		end
	end
end)

return Watchdog

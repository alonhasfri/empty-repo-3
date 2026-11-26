-- QoL.lua (1.9.1, quality of life, client side):
--   * Sprint: hold Shift (PC) or tap the 🏃 button (phones, above the jump button) to walk faster.
--   * AFK-safe: no input for a while → the server marks you AFK (no school bell, no life-event invites).
--   * Tap a toast to dismiss it early (UI.lua).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local QoL = {}
local me = Players.LocalPlayer
local CQ = Config.QoL

---------------------------------------------------------------------
-- Sprint (never stacks: it only adds the bonus while held, and only takes back what it added)
---------------------------------------------------------------------
local sprinting = false
local added = 0
local function setSprint(on: boolean)
	local hum = me.Character and me.Character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if on and not sprinting then
		if hum.WalkSpeed > 0 and not me:GetAttribute("AdminFrozen") then
			added = CQ.SprintBonus
			hum.WalkSpeed += added
			sprinting = true
		end
	elseif not on and sprinting then
		hum.WalkSpeed = math.max(0, hum.WalkSpeed - added)
		added = 0
		sprinting = false
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
		setSprint(true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
		setSprint(false)
	end
end)
me.CharacterAdded:Connect(function()
	sprinting = false
	added = 0
end)

-- phones: a small toggle button above the jump button
task.defer(function()
	if not UserInputService.TouchEnabled or not UI.gui then
		return
	end
	local b = UI.new("TextButton", {
		Name = "SprintButton",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -CQ.SprintButtonRight, 1, -CQ.SprintButtonUp),
		Size = UDim2.fromOffset(math.max(56, UI.minTouch()), math.max(56, UI.minTouch())),
		BackgroundColor3 = UI.T.bg,
		BackgroundTransparency = 0.2,
		Text = Content.QoL.Sprint,
		TextScaled = true,
		Parent = UI.gui,
	})
	UI.corner(b, 28)
	UI.autoScale(b) -- 1.9.3: follows the HUD scale, stays thumb-sized
	b.Activated:Connect(function()
		setSprint(not sprinting)
		b.BackgroundColor3 = sprinting and Color3.fromRGB(70, 200, 120) or UI.T.bg
	end)
end)

---------------------------------------------------------------------
-- AFK-safe
---------------------------------------------------------------------
local lastInput = os.clock()
local afk = false
UserInputService.InputBegan:Connect(function()
	lastInput = os.clock()
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.Gamepad1 then
		lastInput = os.clock()
	end
end)
task.spawn(function()
	while true do
		task.wait(5)
		local now = os.clock() - lastInput > CQ.AfkSeconds
		if now ~= afk then
			afk = now
			pcall(Remote.call, "afk", { afk = afk })
			if not afk then
				UI.toast(Content.QoL.WelcomeBack)
			end
		end
	end
end)

return QoL

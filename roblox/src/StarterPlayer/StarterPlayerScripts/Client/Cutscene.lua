-- Cutscene (1.9): a small reusable cutscene player. Camera keyframes, letterbox bars, a fade,
-- one caption line, and a Skip button (also: Backspace / gamepad B). Always skippable.
-- Cutscene.play(shots, opts): shots = { { pos = Vector3 offset, look = Vector3 offset, t = seconds, text = index } },
--   offsets are relative to your character (or opts.origin). opts.captions = list of strings, opts.onDone().
-- Reduced Motion or Effects at 0: no camera flight, just the captions with a fade.
-- The HUD (BrainUI) hides while it plays and comes back after. Numbers: Config.Cutscenes. Text: Content.Cutscenes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local UI = require(script.Parent.UI)

local Cutscene = {}
local player = Players.LocalPlayer
local playing = false

function Cutscene.isPlaying(): boolean
	return playing
end

function Cutscene.play(shots, opts)
	if playing then
		return
	end
	opts = opts or {}
	playing = true
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local origin = opts.origin or (root and root.Position) or Vector3.new(0, 5, 0)
	local still = UI.reducedMotion() or UI.effects() <= 0

	local gui = Instance.new("ScreenGui")
	gui.Name = "Cutscene"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local bar = Config.Cutscenes.Letterbox
	local top = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, bar), Parent = gui })
	local bottom = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, bar), Parent = gui })
	local caption = UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(20, 0), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = bottom }, {
		UI.new("UITextSizeConstraint", { MaxTextSize = 28 }),
	})
	local fade = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, ZIndex = 5, Parent = gui })
	local skip = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 10), Size = UDim2.fromOffset(120, 44), Text = Content.Cutscenes.Skip, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(42, 49, 71), ZIndex = 6, Parent = gui })
	UI.corner(skip, 12)
	local _ = top

	local hudWas = UI.gui.Enabled
	UI.gui.Enabled = false
	local camWas = cam.CameraType
	local skipped = false
	local function finish()
		if not playing then
			return
		end
		playing = false
		ContextActionService:UnbindAction("BrainSkipCutscene")
		cam.CameraType = camWas == Enum.CameraType.Scriptable and Enum.CameraType.Custom or camWas
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
		UI.gui.Enabled = hudWas
		TweenService:Create(fade, TweenInfo.new(Config.Cutscenes.Fade), { BackgroundTransparency = 1 }):Play()
		task.delay(Config.Cutscenes.Fade + 0.05, function()
			gui:Destroy()
		end)
		if opts.onDone then
			task.spawn(opts.onDone)
		end
	end
	local function doSkip()
		skipped = true
		finish()
	end
	skip.Activated:Connect(doSkip)
	ContextActionService:BindAction("BrainSkipCutscene", function(_, state)
		if state == Enum.UserInputState.Begin then
			doSkip()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)

	task.spawn(function()
		if not still then
			cam.CameraType = Enum.CameraType.Scriptable
			local s1 = shots[1]
			cam.CFrame = CFrame.lookAt(origin + s1.pos, origin + s1.look)
		end
		TweenService:Create(fade, TweenInfo.new(Config.Cutscenes.Fade), { BackgroundTransparency = 1 }):Play()
		for i, shot in ipairs(shots) do
			if skipped then
				return
			end
			caption.Text = (shot.text and opts.captions and opts.captions[shot.text]) or caption.Text
			if i > 1 then
				if not still then
					TweenService:Create(cam, TweenInfo.new(shot.t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = CFrame.lookAt(origin + shot.pos, origin + shot.look) }):Play()
				end
				task.wait(shot.t)
			else
				task.wait(0.8)
			end
		end
		if not skipped then
			fade.BackgroundTransparency = 1
			TweenService:Create(fade, TweenInfo.new(Config.Cutscenes.Fade), { BackgroundTransparency = 0 }):Play()
			task.wait(Config.Cutscenes.Fade)
			finish()
		end
	end)
end

-- the first-join flyover to the two doors
function Cutscene.intro(onDone)
	Cutscene.play(Config.Cutscenes.Intro, { captions = Content.Cutscenes.Intro, onDone = onDone })
end

return Cutscene

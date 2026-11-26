-- PhotoMode.lua (1.9.1, big ideas #18): photo mode with stickers (📸 Camera app on the phone).
--   * hides the HUD; you frame the shot with the normal camera controls
--   * a tray of preset stickers (emoji only, kid-safe): tap one to add it, drag it where you want,
--     tap it again to make it bigger (3 sizes, then it goes away)
--   * frames: none / Brainville Times front page / polaroid
--   * 📸 Snap: the controls hide for a moment, Roblox's CaptureService takes the picture and asks
--     whether to save it (if that isn't available on the device, a tip says to use the device's own screenshot)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)

local PhotoMode = {}
local me = Players.LocalPlayer
local TP = Content.PhotoMode

local gui: ScreenGui? = nil
local controls: Frame? = nil
local stickerLayer: Frame? = nil
local frameLayer: Frame? = nil
local frameIndex = 1
local hudWas = true

local function close()
	if gui then
		gui:Destroy()
		gui = nil
	end
	if UI.gui then
		UI.gui.Enabled = hudWas
	end
end
PhotoMode.close = close

local SIZES = { 70, 110, 160 }

local function addSticker(icon: string)
	if not stickerLayer then
		return
	end
	local s = Instance.new("TextButton")
	s.Name = "Sticker"
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.2, 0.45 + (math.random() - 0.5) * 0.2)
	s.Size = UDim2.fromOffset(SIZES[1], SIZES[1])
	s.BackgroundTransparency = 1
	s.TextScaled = true
	s.Text = icon
	s.Rotation = math.random(-12, 12)
	s.AutoButtonColor = false
	s:SetAttribute("SizeStep", 1)
	s.Parent = stickerLayer
	-- drag it around; a short tap makes it bigger (and after the biggest size, removes it)
	local dragging, startPos, startInput, moved = false, nil, nil, false
	s.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			startPos, startInput = s.Position, input.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput
			if delta.Magnitude > 6 then
				moved = true
			end
			s.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	s.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			if not moved then
				local step = (s:GetAttribute("SizeStep") or 1) + 1
				if step > #SIZES then
					s:Destroy()
				else
					s:SetAttribute("SizeStep", step)
					s.Size = UDim2.fromOffset(SIZES[step], SIZES[step])
				end
			end
		end
	end)
	UI.sound("CartoonBoing", 0.2)
end

local function drawFrame()
	if not frameLayer then
		return
	end
	frameLayer:ClearAllChildren()
	local kind = TP.Frames[frameIndex].key
	if kind == "news" then
		local top = UI.new("TextLabel", { Size = UDim2.fromScale(1, 0.14), BackgroundColor3 = Color3.fromRGB(245, 240, 225), TextColor3 = Color3.fromRGB(20, 20, 20), Font = Enum.Font.Garamond, TextScaled = true, Text = TP.NewsTitle, Parent = frameLayer })
		local _ = top
		UI.new("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.08), BackgroundColor3 = Color3.fromRGB(245, 240, 225), TextColor3 = Color3.fromRGB(20, 20, 20), Font = Enum.Font.Garamond, TextScaled = true, Text = string.format(TP.NewsLine, me.DisplayName), Parent = frameLayer })
	elseif kind == "polaroid" then
		for _, f in ipairs({
			{ UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.05) },
			{ UDim2.fromScale(0, 0), UDim2.fromScale(0.04, 1) },
			{ UDim2.fromScale(0.96, 0), UDim2.fromScale(0.04, 1) },
		}) do
			UI.new("Frame", { Position = f[1], Size = f[2], BackgroundColor3 = Color3.fromRGB(250, 250, 248), BorderSizePixel = 0, Parent = frameLayer })
		end
		UI.new("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.16), BackgroundColor3 = Color3.fromRGB(250, 250, 248), TextColor3 = Color3.fromRGB(50, 50, 60), Font = Enum.Font.PatrickHand, TextScaled = true, Text = TP.PolaroidLine, Parent = frameLayer })
	end
end

local function snap()
	if not controls then
		return
	end
	controls.Visible = false
	task.wait(0.15)
	local ok = pcall(function()
		local CaptureService = game:GetService("CaptureService")
		CaptureService:CaptureScreenshot(function(contentId)
			if controls then
				controls.Visible = true
			end
			pcall(function()
				CaptureService:PromptSaveCapturesToGallery({ contentId }, function() end)
			end)
		end)
	end)
	-- a white flash either way
	if gui then
		local flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.1, ZIndex = 50, Parent = gui })
		TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		task.delay(0.45, function()
			flash:Destroy()
		end)
	end
	UI.sound("NotificationPing", 0.5)
	if not ok then
		task.wait(0.5)
		if controls then
			controls.Visible = true
		end
		UI.toast(TP.NoCapture)
	end
end

function PhotoMode.open()
	if gui then
		return
	end
	UI.closeModal()
	hudWas = (UI.gui == nil) or UI.gui.Enabled
	if UI.gui then
		UI.gui.Enabled = false
	end
	local g = Instance.new("ScreenGui")
	g.Name = "PhotoMode"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 40
	g.Parent = me:WaitForChild("PlayerGui")
	gui = g
	frameLayer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = g })
	stickerLayer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = g })
	controls = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = g })
	-- sticker tray (left)
	local tray = UI.new("ScrollingFrame", { Position = UDim2.new(0, 10, 0.12, 0), Size = UDim2.new(0, 64, 0.7, 0), BackgroundColor3 = UI.T.panel, BackgroundTransparency = 0.2, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = controls }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 4) }),
	})
	UI.corner(tray, 12)
	for i, icon in ipairs(TP.Stickers) do
		local b = UI.new("TextButton", { Size = UDim2.fromOffset(52, 52), BackgroundTransparency = 1, TextScaled = true, Text = icon, LayoutOrder = i, Parent = tray })
		b.Activated:Connect(function()
			addSticker(icon)
		end)
	end
	-- bottom bar: frame, clear, snap, close
	local bar = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(440, 56), BackgroundTransparency = 1, Parent = controls }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local frameBtn
	frameBtn = UI.button(bar, TP.Frames[frameIndex].name, function()
		frameIndex = frameIndex % #TP.Frames + 1
		frameBtn.Text = TP.Frames[frameIndex].name
		drawFrame()
	end, { Size = UDim2.fromOffset(120, 50), LayoutOrder = 1 })
	UI.button(bar, TP.Clear, function()
		if stickerLayer then
			stickerLayer:ClearAllChildren()
		end
	end, { Size = UDim2.fromOffset(90, 50), LayoutOrder = 2 })
	UI.button(bar, TP.Snap, function()
		task.spawn(snap)
	end, { Size = UDim2.fromOffset(110, 50), LayoutOrder = 3, BackgroundColor3 = UI.Colors.good })
	UI.button(bar, TP.Close, function()
		close()
	end, { Size = UDim2.fromOffset(80, 50), LayoutOrder = 4 })
	UI.label(controls, TP.Hint, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(420, 30), TextColor3 = Color3.new(1, 1, 1) })
	drawFrame()
end

-- dying or respawning closes photo mode
me.CharacterAdded:Connect(close)

return PhotoMode

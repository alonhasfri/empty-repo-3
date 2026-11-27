-- Bits (1.9.3): the client side of BitService. Draws YOUR brain bits (small glowing brains that bob and
-- spin), notices when you walk into one, asks the server, and shows the 🔥 streak with a rising sound.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local CB = Config.Bits
local player = Players.LocalPlayer
local Bits = {}

local folder = Instance.new("Folder")
folder.Name = "BrainBits"
folder.Parent = workspace.CurrentCamera
local shown = {} -- [id] = { part, base, pending }

local streakLabel = UI.new("TextLabel", {
	Name = "BitStreak",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 120),
	Size = UDim2.fromOffset(220, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.FredokaOne,
	TextSize = UI.textSize(28),
	TextColor3 = Color3.fromRGB(255, 170, 60),
	TextStrokeTransparency = 0.2,
	Text = "",
	Visible = false,
	Parent = UI.gui,
})
local streakToken = 0

local function makeBit(pos: Vector3): BasePart
	local lose = UI.state and UI.state.path == "Lose"
	local p = Instance.new("Part")
	p.Name = "BrainBit"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1.3, 1.1, 1.5)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = lose and Color3.fromRGB(255, 120, 200) or Color3.fromRGB(255, 150, 190)
	p.CFrame = CFrame.new(pos)
	local glow = Instance.new("PointLight")
	glow.Color = p.Color
	glow.Range = 8
	glow.Brightness = 1.2
	glow.Parent = p
	p.Parent = folder
	return p
end

local function showStreak(n: number)
	streakToken += 1
	local my = streakToken
	if n < 2 then
		return
	end
	streakLabel.Text = string.format(Content.Bits.Streak, n)
	streakLabel.Visible = true
	streakLabel.TextTransparency = 0
	task.delay(CB.StreakSeconds, function()
		if my == streakToken then
			streakLabel.Visible = false
		end
	end)
end

Remote.on("bits", function(d)
	local keep = {}
	for _, b in ipairs(d.list or {}) do
		keep[b.id] = true
		if not shown[b.id] then
			local pos = Vector3.new(b.x, b.y, b.z)
			shown[b.id] = { part = makeBit(pos), base = pos, pending = false }
		end
	end
	for id, s in pairs(shown) do
		if not keep[id] then
			s.part:Destroy()
			shown[id] = nil
		end
	end
end)

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for id, s in pairs(shown) do
		if not UI.reducedMotion() then
			s.part.CFrame = CFrame.new(s.base + Vector3.new(0, math.sin(t * 3 + s.base.X) * 0.35, 0)) * CFrame.Angles(0, t * 2, 0)
		end
		if root and not s.pending and (root.Position - s.base).Magnitude < CB.TouchRange then
			s.pending = true
			s.part.Transparency = 1
			task.spawn(function()
				local r = Remote.call("bit_take", { id = id })
				if r.ok then
					-- a pop that rises in pitch with the streak (so it never sounds the same twice in a row)
					local snd = Instance.new("Sound")
					snd.SoundId = "rbxassetid://" .. tostring(Config.Sounds.BrainCellGained or 0)
					snd.PlaybackSpeed = math.min(2, 0.9 + (r.streak or 1) * 0.08)
					snd.Volume = 0.5
					snd.Parent = workspace.CurrentCamera
					snd:Play()
					game:GetService("Debris"):AddItem(snd, 2)
					showStreak(r.streak or 1)
					local burst = s.part:Clone()
					burst.Transparency = 0
					burst.Parent = folder
					TweenService:Create(burst, TweenInfo.new(0.3), { Size = burst.Size * 2.2, Transparency = 1 }):Play()
					task.delay(0.35, function()
						burst:Destroy()
					end)
				end
				s.tries = (s.tries or 0) + 1
				if not r.ok and not r.gone and s.part.Parent and s.tries < 4 then
					-- the server hadn't seen you arrive yet (lag): show it again and try once more in a moment
					task.wait(0.6)
					s.part.Transparency = 0
					s.pending = false
					return
				end
				if s.part.Parent then
					s.part:Destroy()
				end
				shown[id] = nil
			end)
		end
	end
end)

return Bits

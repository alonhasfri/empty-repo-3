-- BrainrotTVService (1.9.1, big ideas #12): a giant TV in the town square whose shows get dumber
-- the dumber the server is. The "server brain" is the average of everyone's brain level
-- (Lose players far below average pull it down, smart players pull it up) → channel 0 (smart) … 4 (pure brainrot).
--   * Lose players: 📺 Watch (lose a little, with a cooldown)
--   * Gain players: 🔁 Change the channel → the Science channel for a while (a small stress drop)
-- All shows are original, kid-safe parody lines (Content.BrainrotTV). No real brands or creators.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local DataService = require(script.Parent.DataService)
local BrainService = require(script.Parent.BrainService)

local BrainrotTVService = {}
local CT = Config.BrainrotTV
local TT = Content.BrainrotTV

local screenLabel: TextLabel? = nil
local channelLabel: TextLabel? = nil
local scienceUntil = 0
local lastUse = {} -- [player] = os.clock()

-- 0 = smart server … 4 = full brainrot
function BrainrotTVService.level(): number
	if os.clock() < scienceUntil then
		return 0
	end
	local sum, n = 0, 0
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataService.get(p)
		if d and d.path then
			local iq = Brain.iq(d.cells or 0)
			sum += iq
			n += 1
		end
	end
	if n == 0 then
		return 2
	end
	local avg = sum / n
	for i, cut in ipairs(CT.IQCuts) do -- highest first
		if avg >= cut then
			return i - 1
		end
	end
	return #CT.IQCuts
end

local function build()
	local folder = workspace:FindFirstChild("Boards") or Instance.new("Folder")
	folder.Name = "Boards"
	folder.Parent = workspace
	local frame = Instance.new("Part")
	frame.Name = "BrainrotTV"
	frame.Anchored = true
	frame.Size = Vector3.new(CT.Size.X + 1, CT.Size.Y + 1, 1)
	frame.CFrame = CFrame.lookAt(CT.Pos, CT.Pos + CT.Facing)
	frame.Color = Color3.fromRGB(25, 25, 30)
	frame.Material = Enum.Material.SmoothPlastic
	frame.Parent = folder
	local screen = Instance.new("Part")
	screen.Name = "BrainrotTVScreen"
	screen.Anchored = true
	screen.CanCollide = false
	screen.Size = Vector3.new(CT.Size.X, CT.Size.Y, 0.2)
	screen.CFrame = frame.CFrame * CFrame.new(0, 0, -0.55)
	screen.Material = Enum.Material.Neon
	screen.Color = Color3.fromRGB(20, 30, 60)
	screen.Parent = folder
	local pole = Instance.new("Part")
	pole.Name = "BrainrotTVPole"
	pole.Anchored = true
	pole.Size = Vector3.new(1, CT.Pos.Y, 1)
	pole.CFrame = CFrame.new(CT.Pos.X, CT.Pos.Y / 2 - CT.Size.Y / 2, CT.Pos.Z)
	pole.Color = Color3.fromRGB(60, 60, 70)
	pole.Parent = folder
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(800, 450)
	sg.LightInfluence = 0
	sg.Parent = screen
	local ch = Instance.new("TextLabel")
	ch.Size = UDim2.fromScale(1, 0.16)
	ch.BackgroundTransparency = 1
	ch.Font = Enum.Font.FredokaOne
	ch.TextScaled = true
	ch.TextColor3 = Color3.fromRGB(255, 220, 90)
	ch.Text = ""
	ch.Parent = sg
	local show = Instance.new("TextLabel")
	show.Position = UDim2.fromScale(0.05, 0.2)
	show.Size = UDim2.fromScale(0.9, 0.75)
	show.BackgroundTransparency = 1
	show.Font = Enum.Font.FredokaOne
	show.TextScaled = true
	show.TextWrapped = true
	show.TextColor3 = Color3.new(1, 1, 1)
	show.Text = ""
	show.Parent = sg
	screenLabel, channelLabel = show, ch
	-- the prompt (what it does depends on your path)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = TT.Action
	pp.ObjectText = TT.Object
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 22
	pp.Parent = pole
	pp.Triggered:Connect(function(player)
		local d = DataService.get(player)
		if not d or not d.path then
			return
		end
		if (lastUse[player] or 0) > os.clock() then
			BrainService.toast(player, TT.Wait)
			return
		end
		lastUse[player] = os.clock() + CT.Cooldown
		if d.path == "Gain" then
			scienceUntil = os.clock() + CT.ScienceSeconds
			BrainService.stress(player, -CT.ScienceCalm)
			BrainService.toast(player, TT.Switched, "NotificationPing")
		else
			BrainService.lose(player, CT.WatchLose, "brainrottv")
			BrainService.toast(player, TT.Watched[math.random(1, #TT.Watched)], "CartoonBoing")
		end
	end)
end

local function render()
	if not screenLabel or not channelLabel then
		return
	end
	local lvl = BrainrotTVService.level()
	local shows = TT.Shows[lvl] or TT.Shows[2]
	channelLabel.Text = TT.Channels[lvl] or ""
	screenLabel.Text = shows[math.random(1, #shows)]
	local colors = CT.Colors
	local screen = screenLabel.Parent and screenLabel.Parent.Parent
	if screen and screen:IsA("BasePart") then
		screen.Color = colors[lvl + 1] or colors[1]
	end
end

task.spawn(function()
	task.wait(5)
	pcall(build)
	while true do
		pcall(render)
		task.wait(CT.ShowSeconds)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	lastUse[p] = nil
end)

return BrainrotTVService

-- SpeedrunTimer.lua (1.7.3): optional on-screen run timer (Settings → ⏱). Display only:
-- the real time for the plaza board is measured on the server (runStart → IQ 200).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)

local SpeedrunTimer = {}

local label = UI.new("TextLabel", {
	Name = "SpeedrunTimer",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(150, UI.textSize(18) + 10),
	BackgroundColor3 = Color3.fromRGB(10, 10, 20),
	BackgroundTransparency = 0.3,
	TextColor3 = Color3.fromRGB(120, 255, 160),
	Font = Enum.Font.Code,
	TextSize = UI.textSize(18),
	Visible = false,
	Parent = UI.gui,
})
UI.corner(label, 8)
UI.autoScale(label)

local runStart, offset, on, finished = nil, 0, false, false

local function fmt(v: number): string
	v = math.max(0, math.floor(v))
	local h = math.floor(v / 3600)
	if h > 0 then
		return string.format("%d:%02d:%02d", h, math.floor(v / 60) % 60, v % 60)
	end
	return string.format("%d:%02d", math.floor(v / 60), v % 60)
end

function SpeedrunTimer.onState(st)
	on = st and st.settings and st.settings.speedrunTimer == true or false
	runStart = st and st.runStart
	finished = st and (st.retired or st.dead) or false
	if st and st.serverNow then
		offset = st.serverNow - os.time() -- line our clock up with the server's
	end
	label.Visible = on and runStart ~= nil
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if on and runStart then
			label.Text = string.format(Content.Speedrun.Timer, fmt(os.time() + offset - runStart)) .. (finished and " 🏁" or "")
		end
	end
end)

return SpeedrunTimer

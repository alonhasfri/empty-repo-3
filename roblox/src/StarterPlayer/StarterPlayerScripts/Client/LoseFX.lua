-- LoseFX (1.7): being dumb changes how the game WORKS, not just how it looks.
-- Lose path only, and only while you're still human (animals have their own UI):
--   * scrambled app LABELS below 45B (the icons never scramble, so the phone still works)
--   * "brain lag": a short "uh oh…" before a phone app opens
--   * silly joke ads that pop up now and then, always with a big ✕ (nothing to buy)
-- Never touches prices, odds or confirm buttons.
-- Everything scales with Settings -> Effects intensity (0% = off) and respects Reduced Motion.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local UI = require(script.Parent.UI)

local LoseFX = {}
LoseFX.isBusy = nil -- function() -> true while a conversation or cutscene is open (set by ClientMain)

local CF = Config.LoseFX
local TF = Content.Life.LoseFX

local function active(): boolean
	local st = UI.state
	if not st or st.path ~= "Lose" or st.dead then
		return false
	end
	if st.stage ~= nil and st.stage ~= "human" and st.stage ~= "barelyhuman" then
		return false -- animals: see AnimalUI
	end
	return UI.effects() > 0
end

-- Shuffle the middle letters of some words ("Settings" -> "Sttenigs"). Same word = same scramble.
local function scrambleWord(w: string, seed: number): string
	local chars = {}
	for _, c in utf8.codes(w) do
		table.insert(chars, utf8.char(c))
	end
	if #chars < 4 then
		return w
	end
	local rng = Random.new(seed)
	for i = #chars - 1, 3, -1 do
		local j = rng:NextInteger(2, i)
		chars[i], chars[j] = chars[j], chars[i]
	end
	return table.concat(chars)
end

function LoseFX.label(text: string): string
	if not active() then
		return text
	end
	local st = UI.state
	if (st.cells or math.huge) >= CF.ScrambleBelowCells then
		return text
	end
	local out = {}
	local i = 0
	for w in string.gmatch(text, "%S+") do
		i += 1
		local seed = #w * 31 + i
		-- at lower intensity, fewer words scramble
		if (seed % 10) / 10 < UI.effects() then
			table.insert(out, scrambleWord(w, seed))
		else
			table.insert(out, w)
		end
	end
	return table.concat(out, " ")
end

-- A short warning, then the app opens (brain lag). Clear and quick: never blocks.
function LoseFX.beforeOpen(_key: string, go)
	local st = UI.state
	if not active() or not st or (st.cells or math.huge) >= 70e9 then
		go()
		return
	end
	local lag = CF.LagSeconds * UI.effects()
	if lag < 0.05 then
		go()
		return
	end
	UI.toast("🥴 " .. TF.Warn[math.random(#TF.Warn)], nil, 1)
	task.delay(lag, go)
end

---------------------------------------------------------------------
-- Joke ads
---------------------------------------------------------------------
local adOpen = nil

local function showAd()
	if adOpen and adOpen.Parent then
		return
	end
	local ad = TF.Ads[math.random(#TF.Ads)]
	local frame = UI.new("Frame", {
		Name = "JokeAd",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(300, 170),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 60,
		Parent = UI.gui,
	})
	adOpen = frame
	UI.autoScale(frame)
	UI.corner(frame, 18)
	UI.stroke(frame, Color3.new(0, 0, 0), 4, 0)
	UI.gradient(frame, Color3.fromRGB(255, 60, 200), Color3.fromRGB(255, 220, 40), 30)
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -80, 0, 44), Text = ad.title, Font = Enum.Font.FredokaOne, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, ZIndex = 61, Parent = frame })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 60), Size = UDim2.new(1, -28, 0, 60), Text = ad.text, Font = Enum.Font.GothamBold, TextScaled = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(40, 20, 40), ZIndex = 61, Parent = frame })
	UI.new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 1, -30), Size = UDim2.new(1, -28, 0, 20), Text = TF.AdNote, Font = Enum.Font.Gotham, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(60, 40, 60), ZIndex = 61, Parent = frame })
	-- the big, obvious close button (always there, always works)
	local x = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(56, 56),
		Text = "X",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(30, 30, 36),
		ZIndex = 62,
		Parent = frame,
	}, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
	UI.corner(x, 28)
	local function close()
		if frame.Parent then
			frame:Destroy()
		end
	end
	x.Activated:Connect(close)
	if not UI.reducedMotion() then
		local sc = UI.new("UIScale", { Scale = 0.6, Parent = frame })
		TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	UI.sound("AirHorn", 0.15 * UI.effects())
	task.delay(8, close)
end

function LoseFX.start()
	task.spawn(function()
		while true do
			local eff = UI.effects()
			-- lower intensity = fewer ads; 0% = none
			task.wait(CF.AdEverySeconds / math.max(eff, 0.25))
			if active() and eff > 0 and not UI.isModalOpen() and not (LoseFX.isBusy and LoseFX.isBusy()) then
				UI.toast("🥴 " .. TF.Warn[math.random(#TF.Warn)], nil, CF.WarnSeconds)
				task.wait(CF.WarnSeconds)
				if active() and not UI.isModalOpen() and not (LoseFX.isBusy and LoseFX.isBusy()) then
					showAd()
				end
			end
		end
	end)
end

return LoseFX

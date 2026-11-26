-- DumbSigns.lua (1.9.1, big ideas #13): at a really low brain (Lose path, below Config.DumbWorld.WrongBelowCells)
-- every arrow on the town's signs points the wrong way (only on YOUR screen), and they turn back when you're
-- smarter again. The map's "you are here" dot drifts too (Stations.map). Never touches prices, odds or buttons:
-- only signs in the world (SurfaceGui / BillboardGui text in workspace).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.UI)

local DumbSigns = {}
local DW = Config.DumbWorld
local SWAP = { ["➡️"] = "⬅️", ["⬅️"] = "➡️", ["⬆️"] = "⬇️", ["⬇️"] = "⬆️", ["→"] = "←", ["←"] = "→", ["↑"] = "↓", ["↓"] = "↑" }

local flipped = {} -- [TextLabel] = original text
local isDumb = false

local function flip(text: string): string
	-- one pass over every arrow, so ➡️ → ⬅️ doesn't flip back again
	local out = text
	local marks = {}
	for from, to in pairs(SWAP) do
		local key = "{{" .. #marks .. "}}" -- plain-text marker (no pattern characters)
		table.insert(marks, { key = key, to = to })
		out = string.gsub(out, from, key)
	end
	for _, m in ipairs(marks) do
		out = string.gsub(out, m.key, m.to)
	end
	return out
end

local function hasArrow(text: string): boolean
	for from in pairs(SWAP) do
		if string.find(text, from, 1, true) then
			return true
		end
	end
	return false
end

local function signLabels()
	local list = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("TextLabel") and (d:FindFirstAncestorWhichIsA("SurfaceGui") or d:FindFirstAncestorWhichIsA("BillboardGui")) and hasArrow(d.Text) then
			table.insert(list, d)
		end
	end
	return list
end

local function apply(dumb: boolean)
	if dumb then
		for _, l in ipairs(signLabels()) do
			if not flipped[l] then
				flipped[l] = l.Text
				l.Text = flip(l.Text)
			end
		end
	else
		for l, original in pairs(flipped) do
			if l.Parent then
				l.Text = original
			end
		end
		flipped = {}
	end
end

task.spawn(function()
	local rescan = 0
	while true do
		task.wait(3)
		local st = UI.state or {}
		local dumb = st.path == "Lose" and (st.cells or math.huge) < DW.WrongBelowCells
		rescan += 3
		if dumb ~= isDumb or (dumb and rescan >= 30) then
			isDumb = dumb
			rescan = 0
			pcall(apply, dumb)
		end
	end
end)

return DumbSigns

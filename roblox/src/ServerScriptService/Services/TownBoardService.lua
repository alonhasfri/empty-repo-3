-- TownBoardService (1.9.1, big ideas #6): a live "Today in town" board in the plaza for THIS server:
-- smartest, dumbest, top inventor, genius branches and the best teamworker. The 🏙 Town phone app shows
-- the same rows with a Visit button (HomeService). Display names only, never free text.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local Brain = require(ReplicatedStorage.Shared.Brain)

local Net = require(script.Parent.Net)
local DataService = require(script.Parent.DataService)

local TownBoardService = {}
local CT = Config.TownBoard
local TT = Content.TownBoard

local function count(t): number
	local n = 0
	for _ in pairs(typeof(t) == "table" and t or {}) do
		n += 1
	end
	return n
end

-- the rows: { key, label, name, id, value }
function TownBoardService.rows()
	local best = {}
	local geniuses = {}
	local function consider(key: string, p: Player, score: number, value: string)
		local b = best[key]
		if not b or score > b.score then
			best[key] = { score = score, name = p.DisplayName, id = p.UserId, value = value }
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataService.get(p)
		if d and d.path then
			local cells = d.cells or 0
			if d.path == "Gain" then
				local iq = Brain.iq(cells)
				consider("smartest", p, iq, string.format(TT.IQ, iq))
			else
				consider("dumbest", p, -cells, Brain.shortNumber(cells))
			end
			local inv = count(d.inventions)
			if inv > 0 then
				consider("inventor", p, inv, tostring(inv))
			end
			if (d.groupShifts or 0) > 0 then
				consider("team", p, d.groupShifts, tostring(d.groupShifts))
			end
			if d.genius then
				geniuses[d.genius] = (geniuses[d.genius] or 0) + 1
			end
		end
	end
	local rows = {}
	for _, key in ipairs({ "smartest", "dumbest", "inventor", "team" }) do
		local b = best[key]
		table.insert(rows, { key = key, label = TT.Rows[key], name = b and b.name or TT.Nobody, id = b and b.id or nil, value = b and b.value or "" })
	end
	local g = {}
	for _, branch in ipairs(Config.Genius.Branches) do
		if geniuses[branch] then
			table.insert(g, (Content.Genius.Branches[branch] and Content.Genius.Branches[branch].icon or "🌟") .. " " .. geniuses[branch])
		end
	end
	table.insert(rows, { key = "genius", label = TT.Rows.genius, name = #g > 0 and table.concat(g, "  ") or TT.Nobody, value = "" })
	-- 1.9.1: inventions changing the world right now
	local inv = {}
	for _, p in ipairs(Content.Projects) do
		if workspace:GetAttribute("Inv_" .. p.key) then
			table.insert(inv, p.icon)
		end
	end
	table.insert(rows, { key = "inventions", label = TT.Rows.inventions, name = #inv > 0 and table.concat(inv, " ") or TT.Nobody, value = "" })
	return rows
end

-- the physical board in the plaza
local label: TextLabel? = nil
local function buildBoard()
	local folder = workspace:FindFirstChild("Boards") or Instance.new("Folder")
	folder.Name = "Boards"
	folder.Parent = workspace
	local p = Instance.new("Part")
	p.Name = "Board_Town"
	p.Anchored = true
	p.Size = Vector3.new(14, 10, 0.6)
	p.CFrame = CFrame.lookAt(CT.Pos, CT.Pos + CT.Facing)
	p.Color = Color3.fromRGB(34, 40, 58)
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = folder
	for _, x in ipairs({ -6.5, 6.5 }) do
		local leg = Instance.new("Part")
		leg.Name = "BoardLeg"
		leg.Anchored = true
		leg.Size = Vector3.new(0.6, CT.Pos.Y, 0.6)
		leg.CFrame = p.CFrame * CFrame.new(x, -5 - CT.Pos.Y / 2 + 0.3, 0.3)
		leg.Color = Color3.fromRGB(60, 60, 70)
		leg.Parent = folder
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(700, 500)
	sg.LightInfluence = 0
	sg.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextSize = 30
	l.TextWrapped = true
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.Text = TT.Title
	l.Parent = sg
	label = l
end

local function render()
	if not label then
		return
	end
	local lines = { TT.Title }
	for _, r in ipairs(TownBoardService.rows()) do
		table.insert(lines, r.label .. "  " .. r.name .. (r.value ~= "" and ("  (" .. r.value .. ")") or ""))
	end
	table.insert(lines, TT.Footer)
	label.Text = table.concat(lines, "\n")
end

Net.on("town_get", function(_player)
	return { ok = true, rows = TownBoardService.rows() }
end)

task.spawn(function()
	task.wait(5) -- after the town is built
	pcall(buildBoard)
	while true do
		pcall(render)
		task.wait(CT.Refresh)
	end
end)

return TownBoardService

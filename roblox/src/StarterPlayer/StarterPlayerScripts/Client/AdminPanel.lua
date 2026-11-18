-- AdminPanel: staff panel with tabs (Players, Server, Fun, Game, Logs).
-- Dark rounded panel with a top tab row, player list and big buttons.
-- Only shows buttons your rank can use. Works with touch, mouse and controller.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local player = Players.LocalPlayer
local C = UI.Colors

local AdminPanel = {}
AdminPanel.onDebug = nil

local TABS = { "Players", "Server", "Fun", "Game", "Logs" }
local selectedTarget = nil -- userId
local selectedName = nil
local currentTab = "Players"

local function myRank(): number
	return player:GetAttribute("Rank") or 0
end

local function commandsFor(cat: string)
	local list = {}
	for name, def in pairs(Config.Commands) do
		if def.cat == cat and myRank() >= def.min then
			table.insert(list, { name = name, def = def })
		end
	end
	table.sort(list, function(a, b)
		if a.def.min ~= b.def.min then
			return a.def.min < b.def.min
		end
		return a.def.label < b.def.label
	end)
	return list
end

function AdminPanel.open()
	if myRank() < 1 then
		UI.toast("Staff only.")
		return
	end
	local m = UI.modal("🛠 Staff Panel  •  " .. Config.RankNames[myRank()], { color = Config.RankColors[myRank()], maxSize = Vector2.new(640, 520) })

	-- Tab row
	local tabRow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1, Parent = m.content }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
	})
	local body = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = m.content }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	-- shared argument box
	local argBox = UI.new("TextBox", {
		PlaceholderText = "Text box (reason, number, duration…)",
		Text = "",
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		TextSize = UI.textSize(15),
		TextColor3 = C.text,
		PlaceholderColor3 = C.muted,
		BackgroundColor3 = C.panel,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 2,
		Parent = m.content,
	})
	UI.corner(argBox, 8)

	local function run(name: string, def)
		local res = Remote.call("admin", { cmd = name, target = def.target and selectedTarget or nil, arg = argBox.Text })
		UI.toast((res.ok and "✅ " or "⛔ ") .. tostring(res.msg), res.ok and C.panel or C.bad, 6)
		if name == "debug" and res.ok and AdminPanel.onDebug then
			AdminPanel.onDebug()
		end
	end

	local function clearBody()
		for _, c in ipairs(body:GetChildren()) do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
	end

	local function commandGrid(cat: string, order: number)
		local grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = body }, {
			UI.new("UIGridLayout", { CellSize = UDim2.new(0.48, 0, 0, 46), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		for i, c in ipairs(commandsFor(cat)) do
			local text = c.def.label .. (c.def.arg and "  ✎" or "")
			UI.button(grid, text, function()
				run(c.name, c.def)
			end, { LayoutOrder = i, TextSize = UI.textSize(14), BackgroundColor3 = c.def.min >= 4 and Color3.fromRGB(110, 30, 30) or C.panel2 })
		end
		UI.label(body, "✎ = uses the text box above. Args: " .. (function()
			local hints = {}
			for _, c in ipairs(commandsFor(cat)) do
				if c.def.arg then
					table.insert(hints, c.def.label .. ": " .. c.def.arg)
				end
			end
			return #hints > 0 and table.concat(hints, " • ") or "none"
		end)(), { TextColor3 = C.muted, TextSize = UI.textSize(12), LayoutOrder = order + 1 })
	end

	local function showTab(tab: string)
		currentTab = tab
		clearBody()
		if tab == "Players" then
			local res = Remote.call("admin_players")
			UI.label(body, "Selected: " .. (selectedName or "nobody (tap a player)"), { Font = Enum.Font.GothamBold, TextColor3 = C.gold, LayoutOrder = 1 })
			if res.ok then
				for i, p in ipairs(res.players) do
					local tag = p.rank > 0 and ("[" .. Config.RankNames[p.rank] .. "] ") or ""
					UI.button(body, tag .. p.display .. " (@" .. p.name .. ")  •  " .. tostring(p.path) .. "  •  🧠 " .. p.cells, function()
						selectedTarget = p.userId
						selectedName = p.display
						showTab("Players")
					end, {
						LayoutOrder = 1 + i,
						Size = UDim2.new(1, 0, 0, 40),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = UI.textSize(14),
						BackgroundColor3 = selectedTarget == p.userId and C.accent or C.panel,
					})
				end
			end
			commandGrid("Players", 100)
		elseif tab == "Logs" then
			commandGrid("Logs", 1)
			local res = Remote.call("admin_logs")
			if res.ok then
				for i, line in ipairs(res.logs) do
					UI.label(body, line, { TextSize = UI.textSize(13), TextColor3 = C.muted, LayoutOrder = 10 + i })
				end
				if #res.logs == 0 then
					UI.label(body, "No staff actions yet.", { LayoutOrder = 10 })
				end
			else
				UI.label(body, "Head Moderator or Owner only.", { LayoutOrder = 10 })
			end
		else
			commandGrid(tab, 1)
		end
		m.focus()
	end

	for _, tab in ipairs(TABS) do
		UI.button(tabRow, tab, function()
			showTab(tab)
		end, { Size = UDim2.new(0.19, 0, 1, 0), TextSize = UI.textSize(14), BackgroundColor3 = C.panel })
	end
	showTab(currentTab)
end

return AdminPanel

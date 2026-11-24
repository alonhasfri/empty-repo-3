-- BoardService.lua (1.7.2/1.7.3): plaza leaderboards backed by OrderedDataStores.
--   * Weekly pay: coins earned from real work this week (wages, task pay, shift bonus). New key every week.
--   * Speedrun: best times (lower is better), see SpeedrunService.
-- Display names only (never free text). Every DataStore call is pcall'd: if the store is down,
-- the board shows a calm "resting" line and the game carries on.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)

local BoardService = {}
local CB = Config.Boards
local TB = Content.Boards

local boards = {} -- [key] = { def, store, storeName, label, pending = { [userId] = n } }
local names = {} -- [userId] = display name (cached)

local function weekNumber(): number
	-- weeks since 1970 (Thursday start is fine: it only has to change once a week, the same for everyone)
	return math.floor(os.time() / (7 * 24 * 3600))
end

local function storeFor(b)
	local name = b.def.Store .. (b.def.Weekly and ("_W" .. weekNumber()) or "")
	if b.storeName ~= name then
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(name)
		end)
		b.store = ok and store or nil
		b.storeName = name
	end
	return b.store
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local p = Players:GetPlayerByUserId(userId)
	if p then
		names[userId] = p.DisplayName
		return p.DisplayName
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = ok and n or "?"
	return names[userId]
end

-- the physical board in the plaza
local function buildBoard(key: string, def)
	local folder = workspace:FindFirstChild("Boards") or Instance.new("Folder")
	folder.Name = "Boards"
	folder.Parent = workspace
	local p = Instance.new("Part")
	p.Name = "Board_" .. key
	p.Anchored = true
	p.Size = Vector3.new(12, 9, 0.6)
	p.CFrame = CFrame.lookAt(def.Pos, def.Pos + def.Facing)
	p.Color = Color3.fromRGB(30, 30, 45)
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = folder
	for _, x in ipairs({ -5.5, 5.5 }) do
		local leg = Instance.new("Part")
		leg.Name = "BoardLeg"
		leg.Anchored = true
		leg.Size = Vector3.new(0.6, def.Pos.Y, 0.6)
		leg.CFrame = p.CFrame * CFrame.new(x, -4.5 - def.Pos.Y / 2 + 0.3, 0.3)
		leg.Color = Color3.fromRGB(60, 60, 70)
		leg.Parent = folder
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(600, 450)
	sg.LightInfluence = 0
	sg.Parent = p
	local list = Instance.new("TextLabel")
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.TextColor3 = Color3.new(1, 1, 1)
	list.Font = Enum.Font.FredokaOne
	list.TextSize = 30
	list.TextYAlignment = Enum.TextYAlignment.Top
	list.Text = def.Title
	list.Parent = sg
	return list
end

local function render(b)
	local store = storeFor(b)
	local lines = { b.def.Title }
	if not store then
		table.insert(lines, TB.Resting)
		b.label.Text = table.concat(lines, "\n")
		return
	end
	local ok, page = pcall(function()
		return store:GetSortedAsync(b.def.Ascending == true, b.def.Top):GetCurrentPage()
	end)
	if not ok then
		table.insert(lines, TB.Resting)
	elseif #page == 0 then
		table.insert(lines, TB.Empty)
	else
		for i, entry in ipairs(page) do
			local userId = tonumber(entry.key) or 0
			table.insert(lines, string.format("%d. %s  %s", i, nameOf(userId), b.def.Format(entry.value)))
		end
	end
	b.label.Text = table.concat(lines, "\n")
end

local function flush(b)
	local store = storeFor(b)
	local pending = b.pending
	b.pending = {}
	if not store then
		return
	end
	for userId, n in pairs(pending) do
		pcall(function()
			if b.def.Best then
				-- keep the best (lowest) value only
				store:UpdateAsync(tostring(userId), function(old)
					if old == nil or n < old then
						return n
					end
					return nil
				end)
			else
				store:IncrementAsync(tostring(userId), n)
			end
		end)
	end
end

function BoardService.define(key: string, def)
	local b = { def = def, pending = {} }
	b.label = buildBoard(key, def)
	boards[key] = b
	return b
end

-- Weekly pay: add coins earned from real work (sent in batches every Refresh seconds)
function BoardService.addPay(player: Player, coins: number)
	local b = boards.WeeklyPay
	if not b or typeof(coins) ~= "number" or coins ~= coins or coins <= 0 or coins > 1e6 then
		return
	end
	b.pending[player.UserId] = (b.pending[player.UserId] or 0) + math.floor(coins)
end

-- Best time (seconds, lower is better)
function BoardService.submitBest(key: string, player: Player, value: number)
	local b = boards[key]
	if not b or typeof(value) ~= "number" or value ~= value or value <= 0 or value > 1e9 then
		return
	end
	local old = b.pending[player.UserId]
	if not old or value < old then
		b.pending[player.UserId] = math.floor(value)
	end
end

function BoardService.start()
	BoardService.define("WeeklyPay", {
		Store = CB.WeeklyPay.Store,
		Weekly = true,
		Top = CB.WeeklyPay.Top,
		Pos = CB.WeeklyPay.Pos,
		Facing = CB.WeeklyPay.Facing,
		Title = TB.WeeklyPayTitle,
		Format = function(v)
			return string.format(TB.Coins, v)
		end,
	})
	task.spawn(function()
		while true do
			for _, b in pairs(boards) do
				flush(b)
				render(b)
			end
			task.wait(CB.Refresh)
		end
	end)
end

game:BindToClose(function()
	for _, b in pairs(boards) do
		pcall(flush, b)
	end
end)

return BoardService

-- NpcReact.lua (1.9.1, big ideas #16): townspeople react to YOUR brain level.
-- When you walk past a townsperson (any NPC with a Humanoid that isn't a player), they sometimes say a
-- short line in a speech bubble that only you see: "Wow, Professor!" at genius level, "…are you okay?"
-- at a very low brain, and something for animals too. Lines come from shuffle bags, so they don't repeat
-- much. Text: Content.NpcReact. Numbers: Config.NpcReact.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)

local NpcReact = {}
local me = Players.LocalPlayer
local CN = Config.NpcReact
local TN = Content.NpcReact

local npcs = {} -- list of { model, head }
local said = {} -- [model] = os.clock() of the last line
local bags = {} -- [mood] = shuffled list
local lastAny = 0

local function mood(): string
	local st = UI.state or {}
	if st.stage and Content.Animals.Forms[st.stage] then
		return "animal"
	end
	local iq = st.iq or 100
	if st.path == "Lose" then
		return (st.cells or 86e9) < CN.VeryDumbCells and "verydumb" or "dumb"
	end
	if iq >= CN.GeniusIQ then
		return "genius"
	elseif iq >= CN.SmartIQ then
		return "smart"
	end
	return "average"
end

local function nextLine(m: string): string
	local bag = bags[m]
	if not bag or #bag == 0 then
		bag = table.clone(TN.Lines[m] or TN.Lines.average)
		for i = #bag, 2, -1 do
			local j = math.random(1, i)
			bag[i], bag[j] = bag[j], bag[i]
		end
		bags[m] = bag
	end
	return table.remove(bag)
end

local function rescan()
	local list = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Humanoid") then
			local m = d.Parent
			if m and m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
				local head = m:FindFirstChild("Head") or m.PrimaryPart
				if head and head:IsA("BasePart") then
					table.insert(list, { model = m, head = head })
				end
			end
		end
	end
	npcs = list
end

local function bubble(head: BasePart, text: string)
	local bb = Instance.new("BillboardGui")
	bb.Name = "NpcReact"
	bb.Adornee = head
	bb.Size = UDim2.fromOffset(220, 46)
	bb.StudsOffset = Vector3.new(0, 3.6, 0)
	bb.MaxDistance = 40
	bb.AlwaysOnTop = true
	bb.Parent = me:WaitForChild("PlayerGui")
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = Color3.new(1, 1, 1)
	l.TextColor3 = Color3.fromRGB(30, 30, 40)
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextWrapped = true
	l.Text = text
	l.Parent = bb
	UI.new("UITextSizeConstraint", { MaxTextSize = 16, Parent = l })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = l })
	UI.corner(l, 12)
	task.delay(CN.BubbleSeconds, function()
		bb:Destroy()
	end)
end

task.spawn(function()
	task.wait(8)
	local sinceScan = math.huge
	while true do
		task.wait(1)
		sinceScan += 1
		if sinceScan >= CN.RescanSeconds then
			sinceScan = 0
			pcall(rescan)
		end
		local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
		local st = UI.state
		if root and st and st.path and os.clock() - lastAny > CN.GlobalGap then
			for _, n in ipairs(npcs) do
				if n.head.Parent and (n.head.Position - root.Position).Magnitude <= CN.Radius and os.clock() - (said[n.model] or 0) > CN.PerNpcGap then
					if math.random() < CN.Chance then
						said[n.model] = os.clock()
						lastAny = os.clock()
						bubble(n.head, nextLine(mood()))
						break
					end
				end
			end
		end
	end
end)

return NpcReact

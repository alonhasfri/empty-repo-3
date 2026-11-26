-- InventionHall.lua (1.9.1, user: "a cutscene where you see all the inventions, and you can hover above them"):
--   * hover an exhibit in the Science Lab with the mouse: a card shows what the invention does and if it's on now
--   * on a phone: walk up and tap 🔍 Look (same card)
--   * the tour: when you reach the Scientist rank (or tap the Invention Hall sign) the camera floats above every
--     exhibit in turn with its name and effect as the caption. Skippable (Cutscene.lua).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)

local InventionHall = {}
local me = Players.LocalPlayer
local TI = Content.Inventions

local function statusText(p: Instance): string
	local s = p:GetAttribute("Status")
	return (s == "active" and TI.StateActive) or (s == "invented" and TI.StateInvented) or TI.StateLocked
end

-- the hover card (follows the mouse)
local tip: Frame? = nil
local tipFor: Instance? = nil
local function hideTip()
	if tip then
		tip:Destroy()
		tip = nil
	end
	tipFor = nil
end

local function showTip(p: Instance)
	hideTip()
	if not UI.gui then
		return
	end
	tipFor = p
	local f = UI.new("Frame", { Size = UDim2.fromOffset(260, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = UI.T.panel, ZIndex = 40, Parent = UI.gui }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
	})
	UI.corner(f, 12)
	UI.stroke(f, Color3.fromRGB(90, 200, 255), 2, 0.2)
	local function line(text: string, color: Color3, bold: boolean, order: number)
		UI.new("TextLabel", { Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Font = bold and UI.T.title or UI.T.body, TextSize = bold and 18 or 14, TextColor3 = color, Text = text, LayoutOrder = order, ZIndex = 41, Parent = f })
	end
	line(tostring(p:GetAttribute("Icon")) .. "  " .. tostring(p:GetAttribute("Title")), Color3.new(1, 1, 1), true, 1)
	line(tostring(p:GetAttribute("Unlock")), UI.T.text, false, 2)
	line(statusText(p), Color3.fromRGB(255, 210, 80), false, 3)
	tip = f
end

RunService.RenderStepped:Connect(function()
	if tip then
		local m = UserInputService:GetMouseLocation()
		tip.Position = UDim2.fromOffset(m.X + 18, m.Y - 10)
	end
end)

local function hook(p: Instance)
	local cd = p:FindFirstChildOfClass("ClickDetector") or p:WaitForChild("ClickDetector", 10)
	if not cd then
		return
	end
	cd.MouseHoverEnter:Connect(function()
		showTip(p)
	end)
	cd.MouseHoverLeave:Connect(function()
		if tipFor == p then
			hideTip()
		end
	end)
end
for _, p in ipairs(CollectionService:GetTagged("InventionExhibit")) do
	task.spawn(hook, p)
end
CollectionService:GetInstanceAddedSignal("InventionExhibit"):Connect(function(p)
	task.spawn(hook, p)
end)

-- phones: 🔍 Look opens the same information as a small pop-up
ProximityPromptService.PromptTriggered:Connect(function(pp)
	if pp.Name ~= "ExhibitPrompt" then
		return
	end
	local p = pp.Parent
	if not p then
		return
	end
	local m = UI.modal(tostring(p:GetAttribute("Icon")) .. " " .. tostring(p:GetAttribute("Title")), { color = Color3.fromRGB(90, 200, 255) })
	UI.label(m.content, tostring(p:GetAttribute("Unlock")), { LayoutOrder = 1, TextColor3 = Color3.new(1, 1, 1) })
	UI.label(m.content, statusText(p), { LayoutOrder = 2, TextColor3 = Color3.fromRGB(255, 210, 80) })
	m.focus()
end)

-- the tour: float above every exhibit with its name and effect
function InventionHall.tour(d)
	local list = CollectionService:GetTagged("InventionExhibit")
	table.sort(list, function(a, b)
		return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
	end)
	if #list == 0 then
		return
	end
	local ok, Cutscene = pcall(require, script.Parent.Cutscene)
	if not ok or not Cutscene or Cutscene.isPlaying() then
		return
	end
	local shots, captions = {}, {}
	local firstPos = list[1].Position
	local lastPos = list[#list].Position
	local mid = (firstPos + lastPos) / 2
	local back = (list[1].CFrame.LookVector) -- exhibits face the room
	-- 1) a wide shot of the whole hall
	table.insert(captions, d and d.reason == "unlock" and TI.TourUnlock or TI.TourIntro)
	table.insert(shots, { pos = mid + back * 26 + Vector3.new(0, 16, 0), look = mid, t = 0, text = #captions })
	-- 2) float above each exhibit
	for _, p in ipairs(list) do
		table.insert(captions, tostring(p:GetAttribute("Icon")) .. " " .. tostring(p:GetAttribute("Title")) .. ": " .. tostring(p:GetAttribute("Unlock")))
		table.insert(shots, { pos = p.Position + back * 7 + Vector3.new(0, 8, 0), look = p.Position + Vector3.new(0, 3, 0), t = 2.3, text = #captions })
	end
	-- 3) back out
	table.insert(captions, TI.TourEnd)
	table.insert(shots, { pos = mid + back * 30 + Vector3.new(0, 12, 0), look = mid, t = 2.5, text = #captions })
	Cutscene.play(shots, { origin = Vector3.zero, captions = captions })
	local _ = me
end

return InventionHall

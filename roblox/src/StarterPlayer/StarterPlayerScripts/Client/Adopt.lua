-- Adopt.lua (1.9.1, big ideas #10): the client half of adopting an animal player.
--   * an "🏠 Adopt" prompt over players who are animals (only while YOU are human)
--   * the "<name> wants to adopt you! Accept?" pop-up with Yes / No / Block (the pet decides)
-- Leaving: ✕ in the animal menu (AnimalUI) or the Home app. Server: AdoptService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Content = require(ReplicatedStorage.Shared.Content)
local UI = require(script.Parent.UI)
local Remote = require(script.Parent.Remote)

local Adopt = {}
local me = Players.LocalPlayer
local TA = Content.Adopt

local function iAmAnimal(): boolean
	return me:GetAttribute("AnimalStage") ~= nil
end

local function promptFor(p: Player)
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local pp = root:FindFirstChild("AdoptPrompt")
	if not pp then
		pp = Instance.new("ProximityPrompt")
		pp.Name = "AdoptPrompt"
		pp.ActionText = TA.Prompt
		pp.ObjectText = p.DisplayName
		pp.HoldDuration = 0.4
		pp.RequiresLineOfSight = false
		pp.MaxActivationDistance = 10
		pp.UIOffset = Vector2.new(0, 60) -- under the High-five prompt
		pp.Enabled = false
		pp.Parent = root
		pp.Triggered:Connect(function()
			local r = Remote.call("adopt_ask", { userId = p.UserId })
			if r and r.msg then
				UI.toast(r.msg)
			end
		end)
	end
	return pp
end

-- keep every Adopt prompt on or off (the other player must be an animal, you must be human, nobody's pet yet)
task.spawn(function()
	while true do
		task.wait(1.5)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= me then
				local pp = promptFor(p)
				if pp then
					pp.Enabled = p:GetAttribute("AnimalStage") ~= nil and p:GetAttribute("AdoptedBy") == nil and not iAmAnimal()
				end
			end
		end
	end
end)

-- someone asks to adopt you
function Adopt.onAsk(d)
	local m = UI.modal(string.format(TA.AskTitle, tostring(d.icon or "🐾")), { color = Color3.fromRGB(255, 190, 90) })
	UI.label(m.content, string.format(TA.AskText, tostring(d.from)), { LayoutOrder = 1, TextColor3 = Color3.new(1, 1, 1) })
	UI.label(m.content, TA.AskFine, { LayoutOrder = 2, TextColor3 = UI.T.muted })
	local function answer(yes: boolean, block: boolean?)
		m.close()
		local r = Remote.call("adopt_answer", { fromId = d.fromId, yes = yes, block = block })
		if r and r.msg then
			UI.toast(r.msg)
		end
	end
	UI.button(m.content, TA.Yes, function()
		answer(true)
	end, { LayoutOrder = 3, BackgroundColor3 = UI.Colors.good })
	UI.button(m.content, TA.No, function()
		answer(false)
	end, { LayoutOrder = 4 })
	UI.button(m.content, TA.Block, function()
		answer(false, true)
	end, { LayoutOrder = 5, BackgroundColor3 = Color3.fromRGB(120, 50, 50) })
	m.focus()
end

return Adopt

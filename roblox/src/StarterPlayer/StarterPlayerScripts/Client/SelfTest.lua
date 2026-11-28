-- SelfTest (1.9.4, user: "there are so many problems, I would never find all of them"): a staff-only
-- automatic BUG SWEEP. Opens every screen through the game's own code (phone apps, rail buttons, settings,
-- admin menu), and on each one checks the on-screen UI for:
--   OFFSCREEN  something visible sticks out of the screen
--   CLIPPED    text that doesn't fit its box (and isn't auto-scaled)
--   SMALL      a button smaller than a finger (under 40 px)
--   OVERFLOW   a list taller than its box that can't scroll
--   NOIMAGE    a picture that still hasn't loaded after a few seconds
--   ERROR      a red error in the Output while the screen was open
-- Run it with the admin command `sweep` (it prints [SWEEP] lines in the Output and shows a summary).
local Players = game:GetService("Players")
local LogService = game:GetService("LogService")

local UI = require(script.Parent.UI)

local SelfTest = {}
local player = Players.LocalPlayer
local running = false

local function visibleChain(o: Instance): boolean
	while o and o:IsA("GuiObject") do
		if not o.Visible then
			return false
		end
		o = o.Parent
	end
	local sg = o and (o:IsA("LayerCollector") and o or o:FindFirstAncestorWhichIsA("LayerCollector"))
	return sg == nil or not sg:IsA("ScreenGui") or sg.Enabled
end

local function insideScroller(o: Instance): boolean
	return o:FindFirstAncestorWhichIsA("ScrollingFrame") ~= nil
end

local function short(o: Instance): string
	return (o:GetFullName():gsub("^Players%.[^%.]+%.PlayerGui%.", ""))
end

-- check what is on screen right now; adds issues to `found` (deduped by kind + path)
local function check(screen: string, found, seen)
	local vp = workspace.CurrentCamera.ViewportSize
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local function add(kind: string, o: Instance, detail: string)
		local key = kind .. short(o)
		if seen[key] then
			return
		end
		seen[key] = true
		table.insert(found, { screen = screen, kind = kind, path = short(o), detail = detail })
	end
	for _, sgName in ipairs({ "BrainUI", "BrainAdminGui" }) do
		local sg = pg:FindFirstChild(sgName)
		if sg and sg.Enabled then
			for _, o in ipairs(sg:GetDescendants()) do
				if o:IsA("GuiObject") and visibleChain(o) and o.AbsoluteSize.X > 1 and o.AbsoluteSize.Y > 1 then
					local p, s = o.AbsolutePosition, o.AbsoluteSize
					-- (the top-bar inset shifts GUI coordinates by up to ~60 px, so allow that much above)
					if not insideScroller(o) and (p.X < -4 or p.Y < -70 or p.X + s.X > vp.X + 4 or p.Y + s.Y > vp.Y + 4) then
						add("OFFSCREEN", o, string.format("%dx%d at %d,%d (screen %dx%d)", s.X, s.Y, p.X, p.Y, vp.X, vp.Y))
					end
					if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and not o.TextScaled and not o.TextFits and o.TextTruncate == Enum.TextTruncate.None then
						add("CLIPPED", o, string.format("%q", string.sub(o.Text, 1, 40)))
					end
					if o:IsA("GuiButton") and o.Active and (s.X < 40 or s.Y < 40) and o.Name ~= "Outside" then
						add("SMALL", o, string.format("%dx%d", s.X, s.Y))
					end
					if o:IsA("ImageLabel") and o.Image ~= "" and not o.IsLoaded and o.ImageTransparency < 1 then
						add("NOIMAGE", o, o.Image)
					end
				elseif (o:IsA("UIListLayout") or o:IsA("UIGridLayout")) and o.Parent:IsA("GuiObject") and visibleChain(o.Parent) then
					local f = o.Parent :: GuiObject
					local horiz = o:IsA("UIListLayout") and o.FillDirection == Enum.FillDirection.Horizontal
					local need = horiz and o.AbsoluteContentSize.X or o.AbsoluteContentSize.Y
					local have = horiz and f.AbsoluteSize.X or f.AbsoluteSize.Y
					if not f:IsA("ScrollingFrame") and f.AutomaticSize == Enum.AutomaticSize.None and need > have + 6 then
						add("OVERFLOW", f, string.format("needs %d px, has %d", need, have))
					end
				end
			end
		end
	end
end

-- screens = { { name, open = function() end }, ... }; close = function() end (closes whatever is open)
function SelfTest.run(screens, close)
	if running then
		return
	end
	running = true
	local found, seen = {}, {}
	local current = "start"
	local conn = LogService.MessageOut:Connect(function(msg, kind)
		if kind == Enum.MessageType.MessageError and not string.find(msg, "%[SWEEP%]") then
			table.insert(found, { screen = current, kind = "ERROR", path = "", detail = string.sub(msg, 1, 160) })
		end
	end)
	print("[SWEEP] start: " .. #screens .. " screens, screen " .. tostring(workspace.CurrentCamera.ViewportSize))
	for _, sc in ipairs(screens) do
		current = sc.name
		close()
		task.wait(0.4)
		local ok, err = pcall(function()
			task.spawn(sc.open)
		end)
		if not ok then
			table.insert(found, { screen = sc.name, kind = "ERROR", path = "", detail = tostring(err) })
		end
		task.wait(sc.wait or 3) -- let it load (remote calls, pictures)
		check(sc.name, found, seen)
	end
	close()
	conn:Disconnect()
	for _, f in ipairs(found) do
		print(string.format("[SWEEP] %s | %s | %s | %s", f.screen, f.kind, f.path, f.detail))
	end
	print("[SWEEP] done: " .. #found .. " issues")
	UI.toast("🧪 Bug sweep done: " .. #found .. " issues (see Output / F9)")
	running = false
	return found
end

return SelfTest

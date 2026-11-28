-- AutoTexture (1.9.4, user: "some things haven't been upgraded, they're plain with no texture, and there are so
-- many items I'd have to update everything by hand, so it looks very mixed"): ONE automatic pass that gives
-- every plain part (SmoothPlastic / Plastic, no texture of its own) a fitting real material, picked from
-- what it looks like: its colour, size and shape, plus a few name / parent hints. On your screen only.
--   * cozy, textured, realistic and future looks: textured (Config.AutoTexture.Looks)
--   * toon and low-poly looks (flat on purpose) and Low detail mode: the flat originals come back
--   * parts added later (new props, rooms) are picked up too
-- Brightly painted things, signs with text, road lines, neon and see-through parts are left alone.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local AutoTexture = {}
local CA = Config.AutoTexture
local M = Enum.Material

local originals = setmetatable({}, { __mode = "k" }) -- [part] = its own material (before we touched it)
local verdict = setmetatable({}, { __mode = "k" }) -- [part] = the material we picked (false = leave alone)
local active = false
local watching = false

local PLAIN = { [M.SmoothPlastic] = true, [M.Plastic] = true }

local function hasOwnLook(p: BasePart): boolean
	if p:IsA("MeshPart") and p.TextureID ~= "" then
		return true
	end
	for _, c in ipairs(p:GetChildren()) do
		if c:IsA("SurfaceAppearance") or c:IsA("Texture") or c:IsA("Decal") or c:IsA("SurfaceGui") then
			return true -- (a SurfaceGui = a sign with text: keep it plain so it stays readable)
		end
	end
	return false
end

local function skip(p: BasePart): boolean
	if p.Transparency > 0.4 or p.Size.Magnitude < CA.MinSize then
		return true
	end
	if p:IsDescendantOf(workspace.CurrentCamera) then
		return true -- cutscene sets, brain bits, local effects
	end
	local m = p:FindFirstAncestorWhichIsA("Model")
	if m and (Players:GetPlayerFromCharacter(m) or m:FindFirstChildOfClass("Humanoid")) then
		return true -- people, NPCs and animals keep their look
	end
	local role = p:GetAttribute("Role")
	if role and role ~= "prop" and p:HasTag("Styled") then
		return true -- Style.lua already textures walls, roofs, roads and nature per look
	end
	return false
end

local function has(s: string, words): boolean
	s = string.lower(s)
	for _, w in ipairs(words) do
		if string.find(s, w, 1, true) then
			return true
		end
	end
	return false
end

-- the material this part should get in the textured looks, or nil = leave it as it is
local function classify(p: BasePart): Enum.Material?
	local name = p.Name
	local parent = p.Parent and p.Parent.Name or ""
	if has(name, { "line", "stripe", "mark", "screen", "neon", "glow", "light" }) then
		return nil
	end
	if has(name, { "glass", "window" }) then
		return M.Glass
	end
	if has(name, { "door", "hull", "plank", "crate", "bench", "shelf", "table", "desk" }) then
		return M.WoodPlanks
	end
	if has(name, { "rail", "leg", "pole", "post", "pipe", "fin", "nose", "bumper" }) then
		return M.Metal
	end
	local h, s, v = p.Color:ToHSV()
	local sz = p.Size
	local big = math.max(sz.X, sz.Y, sz.Z)
	local flat = sz.Y < math.min(sz.X, sz.Z) * 0.35
	-- roofs on houses
	if p:IsA("WedgePart") and big > 6 then
		return M.RoofShingles -- big wedges are roofs (any colour)
	end
	-- greys and whites
	if s < 0.14 then
		if v < 0.22 then
			return M.Metal
		elseif v < 0.72 then
			return big > 6 and M.Concrete or M.Metal
		elseif big > 8 then
			return M.Plaster
		end
		return nil -- small white things (fridges, signs): stay smooth
	end
	-- browns: wood
	if h >= 0.03 and h <= 0.13 and s > 0.25 and v < 0.78 then
		return (big > 6 and not (p.Shape == Enum.PartType.Cylinder)) and M.WoodPlanks or M.Wood
	end
	-- brick red on big parts
	if (h < 0.035 or h > 0.96) and s > 0.35 and s < 0.85 and v > 0.25 and v < 0.75 and big > 6 then
		return M.Brick
	end
	-- greens: leaves and grass
	if h > 0.2 and h < 0.45 and s > 0.3 and v < 0.8 then
		if p:IsA("Part") and p.Shape == Enum.PartType.Ball then
			return M.LeafyGrass
		elseif flat and big > 6 then
			return M.Grass
		end
		return nil
	end
	-- blue-grey skyline towers: glass
	if has(parent, { "skyline" }) and h > 0.5 and h < 0.7 and s < 0.45 then
		return M.Glass
	end
	-- sandy / beige big parts: sandstone-like
	if h >= 0.08 and h <= 0.16 and s <= 0.35 and v >= 0.7 and big > 8 then
		return M.Sandstone
	end
	-- big painted surfaces (walls, roof slabs, shop fronts): painted render instead of plastic
	if big > 8 then
		return M.Plaster
	end
	return nil -- small brightly painted things stay painted
end

local function one(p: Instance)
	if not p:IsA("BasePart") or p:IsA("Terrain") then
		return
	end
	local mine = verdict[p]
	if mine == nil then
		if not PLAIN[p.Material] or hasOwnLook(p) or skip(p) then
			verdict[p] = false
			return
		end
		originals[p] = p.Material
		mine = classify(p) or false
		verdict[p] = mine
	end
	if mine == false then
		return
	end
	p.Material = active and mine or originals[p]
end

local function sweep()
	local n = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		one(d)
		n += 1
		if n % CA.PerFrame == 0 then
			task.wait()
		end
	end
end

-- called by Style.apply whenever the look (or Low detail) changes
function AutoTexture.apply(styleName: string, lowDetail: boolean)
	-- (always re-run: Style puts props back to their own material when the look changes)
	active = CA.Looks[styleName] == true and not lowDetail
	task.spawn(sweep)
	if not watching then
		watching = true
		workspace.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				task.defer(one, d) -- (after its builder has set colour and size)
			end
		end)
	end
end

return AutoTexture

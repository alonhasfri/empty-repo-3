-- AnimalForms (update 1.6): blocky, kid-safe animal bodies (from web/src/v16.js).
-- When a player is an animal, their avatar is hidden and one of these bodies is
-- welded to their HumanoidRootPart instead. Front of the body = -Z (the way you walk).
-- Used by BrainService.applyCharacter. No other dependencies (so no require loops).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local AnimalForms = {}

local BODY = "AnimalBody"

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Each body: list of { kind, size, pos (x, y above the ground, z), color, extra }
-- kind = "box" or "ball". z < 0 is the front.
local SHAPES = {
	dog = {
		{ "box", Vector3.new(1.4, 1.1, 2.6), Vector3.new(0, 1.5, 0), rgb(168, 116, 63) },
		{ "box", Vector3.new(1.1, 1, 1.1), Vector3.new(0, 2.3, -1.5), rgb(168, 116, 63) },
		{ "box", Vector3.new(0.6, 0.45, 0.6), Vector3.new(0, 2.1, -2.15), rgb(201, 147, 90) },
		{ "box", Vector3.new(0.22, 0.18, 0.1), Vector3.new(0, 2.25, -2.47), rgb(17, 17, 17) },
		{ "box", Vector3.new(0.3, 0.6, 0.2), Vector3.new(-0.4, 3, -1.4), rgb(107, 69, 32) },
		{ "box", Vector3.new(0.3, 0.6, 0.2), Vector3.new(0.4, 3, -1.4), rgb(107, 69, 32) },
		{ "box", Vector3.new(0.14, 0.14, 0.05), Vector3.new(-0.25, 2.5, -2.07), rgb(17, 17, 17) },
		{ "box", Vector3.new(0.14, 0.14, 0.05), Vector3.new(0.25, 2.5, -2.07), rgb(17, 17, 17) },
		{ "box", Vector3.new(0.35, 1, 0.35), Vector3.new(-0.5, 0.5, -0.9), rgb(138, 90, 42) },
		{ "box", Vector3.new(0.35, 1, 0.35), Vector3.new(0.5, 0.5, -0.9), rgb(138, 90, 42) },
		{ "box", Vector3.new(0.35, 1, 0.35), Vector3.new(-0.5, 0.5, 0.9), rgb(138, 90, 42) },
		{ "box", Vector3.new(0.35, 1, 0.35), Vector3.new(0.5, 0.5, 0.9), rgb(138, 90, 42) },
		{ "box", Vector3.new(0.2, 0.2, 1), Vector3.new(0, 2, 1.6), rgb(168, 116, 63), "tail" },
	},
	fly = {
		{ "ball", Vector3.new(1.6, 1.44, 2.24), Vector3.new(0, 1.6, 0), rgb(43, 43, 48) },
		{ "ball", Vector3.new(1, 1, 1), Vector3.new(0, 1.8, -1.1), rgb(43, 43, 48) },
		{ "ball", Vector3.new(0.64, 0.64, 0.64), Vector3.new(-0.3, 1.95, -1.35), rgb(192, 38, 29) },
		{ "ball", Vector3.new(0.64, 0.64, 0.64), Vector3.new(0.3, 1.95, -1.35), rgb(192, 38, 29) },
		{ "box", Vector3.new(1.4, 0.05, 0.9), Vector3.new(-1.1, 2.2, 0), rgb(230, 244, 255), "wing" },
		{ "box", Vector3.new(1.4, 0.05, 0.9), Vector3.new(1.1, 2.2, 0), rgb(230, 244, 255), "wing" },
	},
	bee = {
		{ "ball", Vector3.new(1.6, 1.44, 2.24), Vector3.new(0, 1.6, 0), rgb(255, 201, 40) },
		{ "box", Vector3.new(1.62, 1.3, 0.25), Vector3.new(0, 1.6, 0.35), rgb(26, 26, 26) },
		{ "box", Vector3.new(1.62, 1.3, 0.25), Vector3.new(0, 1.6, -0.25), rgb(26, 26, 26) },
		{ "ball", Vector3.new(1, 1, 1), Vector3.new(0, 1.8, -1.1), rgb(26, 26, 26) },
		{ "ball", Vector3.new(0.28, 0.28, 0.28), Vector3.new(-0.3, 1.95, -1.5), rgb(255, 255, 255) },
		{ "ball", Vector3.new(0.28, 0.28, 0.28), Vector3.new(0.3, 1.95, -1.5), rgb(255, 255, 255) },
		{ "box", Vector3.new(1.4, 0.05, 0.9), Vector3.new(-1.1, 2.2, 0), rgb(230, 244, 255), "wing" },
		{ "box", Vector3.new(1.4, 0.05, 0.9), Vector3.new(1.1, 2.2, 0), rgb(230, 244, 255), "wing" },
	},
	mouse = {
		{ "ball", Vector3.new(1.6, 1.28, 2.24), Vector3.new(0, 0.8, 0), rgb(185, 185, 194) },
		{ "ball", Vector3.new(1, 1, 1), Vector3.new(0, 1.1, -1.1), rgb(185, 185, 194) },
		{ "box", Vector3.new(0.6, 0.6, 0.08), Vector3.new(-0.35, 1.6, -1), rgb(242, 160, 181) },
		{ "box", Vector3.new(0.6, 0.6, 0.08), Vector3.new(0.35, 1.6, -1), rgb(242, 160, 181) },
		{ "ball", Vector3.new(0.18, 0.18, 0.18), Vector3.new(0, 1.05, -1.62), rgb(242, 160, 181) },
		{ "box", Vector3.new(0.1, 0.1, 1.8), Vector3.new(0, 0.6, 1.8), rgb(242, 160, 181), "tail" },
	},
	worm = {
		{ "ball", Vector3.new(0.84, 0.84, 0.84), Vector3.new(0, 0.42, -1.2), rgb(242, 154, 176) },
		{ "ball", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 0.4, -0.65), rgb(232, 130, 154) },
		{ "ball", Vector3.new(0.76, 0.76, 0.76), Vector3.new(0, 0.38, -0.1), rgb(242, 154, 176) },
		{ "ball", Vector3.new(0.72, 0.72, 0.72), Vector3.new(0, 0.36, 0.45), rgb(232, 130, 154) },
		{ "ball", Vector3.new(0.68, 0.68, 0.68), Vector3.new(0, 0.34, 1), rgb(242, 154, 176) },
		{ "ball", Vector3.new(0.64, 0.64, 0.64), Vector3.new(0, 0.32, 1.55), rgb(232, 130, 154) },
		{ "ball", Vector3.new(0.14, 0.14, 0.14), Vector3.new(-0.15, 0.62, -1.5), rgb(17, 17, 17) },
		{ "ball", Vector3.new(0.14, 0.14, 0.14), Vector3.new(0.15, 0.62, -1.5), rgb(17, 17, 17) },
	},
	dead = {
		{ "box", Vector3.new(2.6, 2, 2.4), Vector3.new(0, 1, 0), rgb(141, 141, 146), nil, CFrame.Angles(0, 0.4, 0.15) },
		{ "box", Vector3.new(2, 1.6, 2), Vector3.new(0.3, 1.6, 0.2), rgb(125, 125, 132), nil, CFrame.Angles(0.3, 1.1, 0) },
		{ "box", Vector3.new(1.4, 1.2, 1.6), Vector3.new(-0.5, 2.1, -0.2), rgb(150, 150, 156), nil, CFrame.Angles(0.2, 0.7, 0.3) },
	},
}

function AnimalForms.has(key: string): boolean
	return SHAPES[key] ~= nil
end

-- Shows or hides the player's own avatar (keeps the original transparency to restore it)
local function setAvatarHidden(char: Model, hidden: boolean)
	for _, d in ipairs(char:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d.Name ~= "HumanoidRootPart" and not d:FindFirstAncestor(BODY) then
			if hidden then
				if d:GetAttribute("AnimalOrigT") == nil then
					d:SetAttribute("AnimalOrigT", d.Transparency)
				end
				d.Transparency = 1
			else
				local orig = d:GetAttribute("AnimalOrigT")
				if orig ~= nil then
					d.Transparency = orig
					d:SetAttribute("AnimalOrigT", nil)
				end
			end
		end
	end
end

function AnimalForms.clear(char: Model)
	local old = char:FindFirstChild(BODY)
	if old then
		old:Destroy()
	end
	char:SetAttribute("AnimalForm", nil)
	setAvatarHidden(char, false)
end

-- Gives the character the body for `key` (or clears it when there is no body for it)
function AnimalForms.apply(char: Model, key: string)
	local shapes = SHAPES[key]
	if not shapes then
		if char:GetAttribute("AnimalForm") then
			AnimalForms.clear(char)
		end
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		return
	end
	if char:GetAttribute("AnimalForm") ~= key or not char:FindFirstChild(BODY) then
		local old = char:FindFirstChild(BODY)
		if old then
			old:Destroy()
		end
		local s = Config.Animals.BodyScale[key] or 1
		-- the ground right under the player, facing the way they face
		local flat = CFrame.lookAt(root.Position, root.Position + Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z))
		local ground = flat * CFrame.new(0, -(hum.HipHeight + root.Size.Y / 2), 0)
		local model = Instance.new("Model")
		model.Name = BODY
		for i, sh in ipairs(shapes) do
			local p = Instance.new("Part")
			p.Name = sh[5] or ("Part" .. i)
			p.Size = sh[2] * s
			if sh[1] == "ball" then
				-- a sphere mesh stretches to the part's size, so bodies can be oval
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = p
			end
			p.Color = sh[4]
			p.Material = Enum.Material.SmoothPlastic
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			if sh[5] == "wing" then
				p.Transparency = 0.35
			end
			p.CFrame = ground * CFrame.new(sh[3] * s) * (sh[6] or CFrame.identity)
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
			p.Parent = model
		end
		model.Parent = char
		char:SetAttribute("AnimalForm", key)
	end
	setAvatarHidden(char, true)
end

return AnimalForms

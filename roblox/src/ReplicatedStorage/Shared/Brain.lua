-- Brain: shared math for brain cells, IQ, rarity, stages and text decay.
-- Used by both the server and the client.

local Config = require(script.Parent.Config)

local Brain = {}

---------------------------------------------------------------------
-- Numbers
---------------------------------------------------------------------
function Brain.formatNumber(n: number): string
	if n ~= n then
		return "0"
	end
	local negative = n < 0
	n = math.floor(math.abs(n) + 0.5)
	local s = string.format("%.0f", n)
	local out = ""
	local count = 0
	for i = #s, 1, -1 do
		out = string.sub(s, i, i) .. out
		count += 1
		if count % 3 == 0 and i > 1 then
			out = "," .. out
		end
	end
	return (negative and "-" or "") .. out
end

-- 1.8.3: short form for huge numbers (the counter showed 25 squeezed digits). Up to
-- Config.ShortNumberFrom it keeps the full "86,000,000,000"; above, 1.2T, 9.9Qa ... then "∞".
function Brain.shortNumber(n: number): string
	if n ~= n then
		return "0"
	end
	if math.abs(n) < Config.ShortNumberFrom then
		return Brain.formatNumber(n)
	end
	local suffixes = Config.NumberSuffixes
	local v, i = math.abs(n), 0
	while v >= 1000 and i < #suffixes do
		v /= 1000
		i += 1
	end
	if v >= 1000 or v == math.huge then
		return "∞"
	end
	return (n < 0 and "-" or "") .. string.format("%.1f", v) .. suffixes[i]
end

---------------------------------------------------------------------
-- IQ (every 8 billion cells = 15 IQ points; overflow above ~200)
---------------------------------------------------------------------
function Brain.iq(cells: number): number
	if cells <= Config.OverflowCells then
		return 100 + 15 * (cells - Config.AverageCells) / Config.CellsPerSD
	end
	local overflowIq = 100 + 15 * (Config.OverflowCells - Config.AverageCells) / Config.CellsPerSD
	-- 1 trillion cells = only about +1 IQ
	local extra = math.log(cells / Config.OverflowCells) / math.log(1e12 / Config.OverflowCells)
	return overflowIq + extra
end

function Brain.cellsForIQ(iq: number): number
	return Config.AverageCells + (iq - 100) / 15 * Config.CellsPerSD
end

-- Chance of being at least this smart, as "1 in X".
local function upperTail(z: number): number
	if z <= 0 then
		return 0.5
	end
	if z > 3 then
		local phi = math.exp(-z * z / 2) / math.sqrt(2 * math.pi)
		return phi / z * (1 - 1 / (z * z) + 3 / (z ^ 4))
	end
	-- Abramowitz and Stegun 7.1.26
	local x = z / math.sqrt(2)
	local t = 1 / (1 + 0.3275911 * x)
	local y = 1
		- (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592)
			* t
			* math.exp(-x * x)
	return 0.5 * (1 - y)
end

function Brain.rarityOneIn(iq: number): number?
	if iq <= 100 then
		return nil
	end
	local p = upperTail((iq - 100) / 15)
	if p <= 0 then
		return nil
	end
	return 1 / p
end

-- IQ text. On the Lose path the display breaks below the human range.
function Brain.iqText(cells: number, path: string?): string
	if path == "Lose" or cells < Config.HumanFloorCells then
		if cells < 1e6 then
			return "IQ: ???"
		elseif cells < 1e9 then
			return "IQ: 🗿"
		elseif cells < 20e9 then
			return "IQ: banana"
		elseif cells < Config.HumanFloorCells then
			return "IQ: -12"
		end
	end
	local iq = Brain.iq(cells)
	if iq >= 200 then
		return string.format("IQ: %.2f", iq)
	end
	return "IQ: " .. tostring(math.floor(iq + 0.5))
end

function Brain.rarityText(cells: number, path: string?): string
	if path == "Lose" and cells < Config.AverageCells then
		return ""
	end
	local iq = Brain.iq(cells)
	if iq >= 200 then
		return "Smarter than any human. Your head is getting big."
	end
	local oneIn = Brain.rarityOneIn(iq)
	if not oneIn or oneIn < 2.5 then
		return ""
	end
	return "Only 1 in " .. Brain.formatNumber(oneIn) .. " people are this smart"
end

---------------------------------------------------------------------
-- Art style (how the world looks) and narrator mood
---------------------------------------------------------------------
function Brain.artTier(cells: number): string
	if cells >= Brain.cellsForIQ(145) then
		return "genius"
	elseif cells >= Brain.cellsForIQ(105) then
		return "smart"
	elseif cells >= Brain.cellsForIQ(95) then
		return "average"
	elseif cells >= Config.HumanFloorCells then
		return "cashgrab"
	end
	return "nonsense"
end

function Brain.narratorMood(cells: number): string
	local tier = Brain.artTier(cells)
	if tier == "genius" or tier == "smart" then
		return "librarian"
	elseif tier == "average" then
		return "host"
	elseif tier == "cashgrab" then
		return "brainrot"
	end
	return "caveman"
end

---------------------------------------------------------------------
-- Animal stages (real neuron counts, roughly)
---------------------------------------------------------------------
Brain.Stages = {
	{ key = "dead", max = 0, name = "Rock", emoji = "🗿", walk = 0, scale = 1 },
	{ key = "microbe", max = 10, name = "Microbe", emoji = "🦠", walk = 10, scale = 0.25, secret = true },
	{ key = "tardigrade", max = 200, name = "Tardigrade", emoji = "🐛", walk = 6, scale = 0.4, secret = true },
	{ key = "worm", max = 302, name = "Worm", emoji = "🐛", walk = 5, scale = 0.45 },
	{ key = "fly", max = 140000, name = "Fruit Fly", emoji = "🦟", walk = 22, scale = 0.5 },
	{ key = "bee", max = 1e6, name = "Honeybee", emoji = "🐝", walk = 20, scale = 0.55 },
	{ key = "mouse", max = 70e6, name = "Mouse", emoji = "🐭", walk = 18, scale = 0.6 },
	{ key = "octopus", max = 500e6, name = "Octopus", emoji = "🐙", walk = 12, scale = 0.85 },
	{ key = "dog", max = 2e9, name = "Dog", emoji = "🐶", walk = 20, scale = 0.8 },
	{ key = "barelyhuman", max = Config.HumanFloorCells, name = "Barely Human", emoji = "🥴", walk = 14, scale = 1 },
	{ key = "human", max = math.huge, name = "Human", emoji = "🧠", walk = 16, scale = 1 },
}

function Brain.stage(cells: number, secretAnimals: boolean?)
	for _, s in ipairs(Brain.Stages) do
		if cells <= s.max and (not s.secret or secretAnimals) then
			return s
		end
	end
	return Brain.Stages[#Brain.Stages]
end

---------------------------------------------------------------------
-- Gain multiplier
---------------------------------------------------------------------
function Brain.gainMultiplier(cells: number): (number, string)
	for _, m in ipairs(Config.GainMultipliers) do
		if cells < m.below then
			return m.mult, m.label
		end
	end
	return 1, ""
end

---------------------------------------------------------------------
-- Text decay for the dumb side
---------------------------------------------------------------------
local EMOJIS = { "🧱", "🥔", "🗿", "🤯", "👀", "🍌", "💀" }

local function hash(s: string): number
	local h = 0
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % 1000003
	end
	return h
end

function Brain.decayLevel(cells: number): number
	if cells >= 70e9 then
		return 0
	elseif cells >= Config.HumanFloorCells then
		return 1
	elseif cells >= 1e9 then
		return 2
	end
	return 3
end

-- fx (0..1) is the player's Effects slider: 0 = never scramble, 1 = full scramble
function Brain.degradeText(text: string, cells: number, fx: number?): string
	local level = Brain.decayLevel(cells)
	if fx ~= nil then
		level = math.floor(level * math.clamp(fx, 0, 1) + 0.5)
	end
	if level == 0 then
		return text
	end
	if level == 3 then
		return EMOJIS[(hash(text) % #EMOJIS) + 1]
	end
	local t = string.lower(text)
	t = string.gsub(t, "[%.,;:]", "")
	t = string.gsub(t, "%f[%a]you%f[%A]", "u")
	t = string.gsub(t, "%f[%a]to%f[%A]", "2")
	t = string.gsub(t, "%f[%a]for%f[%A]", "4")
	t = string.gsub(t, "%f[%a]the%f[%A]", "da")
	t = string.gsub(t, "ing%f[%A]", "in")
	t = string.gsub(t, "welcome", "welcom")
	if level == 2 then
		local words = {}
		for w in string.gmatch(t, "%S+") do
			table.insert(words, w)
			if #words >= 2 then
				break
			end
		end
		return table.concat(words, " ") .. "?"
	end
	return t
end

return Brain

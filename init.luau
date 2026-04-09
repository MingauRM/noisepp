--!strict
--!native
--!optimize 2

local function _gradient(h: number): Vector2
	return Vector2.new(math.cos(h), math.sin(h))
end
local function _smoothstep(t: number): number
	return t * t * t * (t * (t * 6 - 15) + 10)
end
local function _rand(x: number, y: number, seed: number): number
	local n = math.sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453
	return n - math.floor(n)
end
local function _perlin2D(x: number, y: number, seed: number): number
	local GRID_SIZE = 16

	local x0, y0 = (x // GRID_SIZE), (y // GRID_SIZE)
	local x1, y1 = x0 + 1, y0 + 1

	local dx, dy = x / GRID_SIZE - x0, y / GRID_SIZE - y0

	local g00 = _gradient(_rand(x0, y0, seed) * 2 * math.pi)
	local g10 = _gradient(_rand(x1, y0, seed) * 2 * math.pi)
	local g01 = _gradient(_rand(x0, y1, seed) * 2 * math.pi)
	local g11 = _gradient(_rand(x1, y1, seed) * 2 * math.pi)

	local dot00 = g00.X * dx + g00.Y * dy
	local dot10 = g10.X * (dx - 1) + g10.Y * dy
	local dot01 = g01.X * dx + g01.Y * (dy - 1)
	local dot11 = g11.X * (dx - 1) + g11.Y * (dy - 1)

	local u, v = _smoothstep(dx), _smoothstep(dy)

	return math.lerp(math.lerp(dot00, dot10, u), math.lerp(dot01, dot11, u), v)
end
local function _cell_hash(x, y, seed)
	return _rand(x, y, seed)
end

local NoisePP = {}

local SEED = 0
local FREQUENCY = 1
local GAIN = 0.5
local OCTAVES = 4

--// Setting parameters

NoisePP.set_seed = function(seed: number)
	SEED = seed or 0
end

NoisePP.set_gain = function(gain: number)
	GAIN = gain or 0.5
end

NoisePP.set_frequency = function(frequency: number)
	FREQUENCY = frequency or 1
end

NoisePP.set_octaves = function(octaves: number)
	OCTAVES = octaves or 4
end

-- Noises

NoisePP.perlin = function(x: number, y: number, seed: number?): number
	return _perlin2D(x, y, seed or SEED)
end

NoisePP.fbm = function(x: number, y: number, seed: number?, octaves: number?, frequency: number?): number
	local sum = 0
	local amp = 1
	local freq = frequency or FREQUENCY
	local max = 0

	local o = octaves or OCTAVES

	for _i = 1, o do
		sum += NoisePP.perlin(x * freq, y * freq, seed) * amp
		max += amp

		amp *= GAIN
		freq *= 2.01
	end

	return sum / max
end

NoisePP.ridged = function(x: number, y: number, seed: number?, octaves: number, frequency: number): number
	local sum = 0
	local amp = 1
	local freq = frequency or FREQUENCY
	local max = 0
	local weight = 1

	local o = octaves or OCTAVES

	for _i = 1, o do
		local n = NoisePP.perlin(x * freq, y * freq, seed)

		n = 1 - math.abs(n)
		n *= n
		n *= weight

		weight = math.clamp(n * 2, 0, 1)

		sum += n * amp
		max += amp

		amp *= GAIN
		freq *= 2.01
	end

	return sum / max
end

NoisePP.billow = function(x: number, y: number, seed: number?, octaves: number, frequency: number): number
	local sum = 0
	local amp = 1
	local freq = frequency or FREQUENCY
	local max = 0

	local o = octaves or OCTAVES

	for _i = 1, o do
		local n = NoisePP.perlin(x * freq, y * freq, seed)

		n = math.abs(n)
		n = n * 2 - 1

		sum += n * amp
		max += amp

		amp *= GAIN
		freq *= 2.01
	end

	return sum / max
end

NoisePP.cellular = function(x: number, y: number, seed: number?): number
	seed = seed or SEED

	local xi = math.floor(x)
	local yi = math.floor(y)

	local f1 = math.huge
	local f2 = math.huge

	for oy = -1, 1 do
		for ox = -1, 1 do
			local cx = xi + ox
			local cy = yi + oy

			local px = cx + _rand(cx, cy, seed or SEED)
			local py = cy + _rand(cx + 100, cy + 100, seed or SEED)

			local dx = px - x
			local dy = py - y

			local dist = dx * dx + dy * dy

			if dist < f1 then
				f2 = f1
				f1 = dist
			elseif dist < f2 then
				f2 = dist
			end
		end
	end
	return math.sqrt(f2) - math.sqrt(f1)
end

NoisePP.turbulence = function(x: number, y: number, seed: number?, octaves: number, frequency: number): number
	local sum = 0
	local amp = 1
	local freq = frequency or FREQUENCY
	local max = 0

	local o = octaves or OCTAVES

	for _i = 1, o do
		local n = NoisePP.perlin(x * freq, y * freq, seed)

		sum += math.abs(n) * amp
		max += amp

		amp *= GAIN
		freq *= 2.01
	end

	return sum / max
end

NoisePP.marble = function(x: number, y: number, seed: number?, octaves: number, frequency: number): number
	local n = NoisePP.fbm(x, y, seed, octaves, frequency)
	return math.sin((x * 0.1 + n * 5))
end

NoisePP.terrace = function(
	x: number,
	y: number,
	steps: number,
	seed: number?,
	octaves: number,
	frequency: number
): number
	local n = NoisePP.fbm(x, y, seed, octaves, frequency)
	return math.floor(n * steps) / steps
end

NoisePP.white = function(x: number, y: number, seed: number?): number
	return _rand(x, y, seed or SEED)
end

local warp = {}
warp.__index = warp

NoisePP.warp = function(seed: number?)
	local self = setmetatable({}, warp)

	self.Seed = seed or 0
	self.Frequency = 0.025
	self.Amplitude = 20

	return self
end

function warp.Apply(self: DomainWarp, x: number, y: number): (number, number)
	local wx = NoisePP.fbm(x * self.Frequency, y * self.Frequency, self.Seed)
	local wy = NoisePP.fbm(x * self.Frequency + 100, y * self.Frequency + 100, self.Seed)

	wx = x + wx * self.Amplitude
	wy = y + wy * self.Amplitude

	return wx, wy
end

function warp.Octaved(self: DomainWarp, x: number, y: number, octaves: number, gain: number?): (number, number)
	local wx, wy = x, y

	local freq = self.Frequency
	local amp = self.Amplitude
	local g = gain or 0.5

	for _i = 1, octaves do
		local tx = NoisePP.fbm(wx * freq, wy * freq, self.Seed)
		local ty = NoisePP.fbm(wx * freq + 100, wy * freq + 100, self.Seed)

		wx += (tx or wx) * amp
		wy += (ty or wy) * amp

		freq *= 2.01
		amp *= g
	end

	return wx, wy
end

export type DomainWarp = {
	Seed: number,
	Frequency: number,
	Amplitude: number,
	Apply: (self: DomainWarp, x: number, y: number) -> (number, number),
	Octaved: (self: DomainWarp, x: number, y: number, Octaves: number, Gain: number?) -> (number, number),
}
export type NoisePP = typeof(NoisePP)

return NoisePP :: NoisePP

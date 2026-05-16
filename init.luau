--!strict
--!optimize 2
--!native

-- Utils

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

-- Noise class
local NoisePP = {}
local NoiseMethods = {}
NoisePP.__index = NoiseMethods

-- Domain warp class
local Warp = {}
local WarpMethods = {}
Warp.__index = WarpMethods

-- Constructs a new Noise object.
function NoisePP.new(params: Parameters?): Noise
	local self = setmetatable({}, NoisePP)
	params = params or {
		Seed = 0,
		Frequency = 1,
		Gain = 0.6,
		Octaves = 1,
	}

	self.Seed = params.Seed
	self.Frequency = params.Frequency
	self.Gain = params.Gain
	self.Octaves = params.Octaves

	return self :: Noise
end

-- Constructs a new domain warp object.
function NoisePP.warp(params: Parameters?): DomainWarp
	local self = setmetatable({}, Warp)
	params = params or {
		Seed = 0,
		Frequency = 1,
		Gain = 0.6,
		Octaves = 1,
	}

	self.Seed = params.Seed or 0
	self.Frequency = params.Frequency or 1.0
	self.Gain = params.Gain or 0.6
	self.Octaves = params.Octaves or 1

	return self :: DomainWarp
end

----- Noise methods -----

function NoiseMethods.SetSeed(self: Noise, seed: number): ()
	self.Seed = seed
end

function NoiseMethods.SetFrequency(self: Noise, freq: number): ()
	self.Frequency = freq
end

function NoiseMethods.SetGain(self: Noise, gain: number): ()
	self.Gain = gain
end

function NoiseMethods.SetOctaves(self: Noise, octaves: number): ()
	self.Octaves = octaves
end

function NoiseMethods.SetParameters(self: Noise, params: Parameters)
	self.Seed = params.Seed or self.Seed
	self.Frequency = params.Frequency or self.Frequency
	self.Gain = params.Gain or self.Gain
	self.Octaves = params.Octaves or self.Octaves
end

function NoiseMethods.Perlin(self: Noise, x: number, y: number): number
	local freq = self.Frequency or 1.0
	local seed = self.Seed or 0

	return _perlin2D(x * freq, y * freq, seed)
end

function NoiseMethods.Fbm(self: Noise, x: number, y: number): number
	local Seed = self.Seed or 0
	local Frequency = self.Frequency or 1.0
	local Gain = self.Gain or 0.6
	local Octaves = self.Octaves or 1

	local result = 0

	local ampl = 1.0
	local maxAmpl = ampl

	for _ = 1, Octaves do
		result += _perlin2D(x, y, Seed) * ampl

		Frequency *= 2.01
		ampl *= Gain

		maxAmpl += ampl
	end

	return result / maxAmpl
end

function NoiseMethods.Ridged(self: Noise, x: number, y: number): number
	local Seed = self.Seed or 0
	local Frequency = self.Frequency or 1.0
	local Gain = self.Gain or 0.6
	local Octaves = self.Octaves or 1

	local result = 0

	local ampl = 1.0
	local maxAmpl = ampl

	local weight = 1

	for _ = 1, Octaves do
		local noise = _perlin2D(x, y, Seed)

		noise = 1 - math.abs(noise)
		noise *= noise
		noise *= weight

		weight = math.clamp(noise * 2, 0, 1)

		result += noise

		Frequency *= 2.01
		ampl *= Gain

		maxAmpl += ampl
	end

	return result / maxAmpl
end

function NoiseMethods.Billow(self: Noise, x: number, y: number): number
	local Seed = self.Seed or 0
	local Frequency = self.Frequency or 1.0
	local Gain = self.Gain or 0.6
	local Octaves = self.Octaves or 1

	local result = 0

	local ampl = 1.0
	local maxAmpl = ampl

	for _ = 1, Octaves do
		local noise = _perlin2D(x * Frequency, y * Frequency, Seed)

		noise = math.abs(noise)
		noise = noise * 2 - 1

		result += noise * ampl
		maxAmpl += ampl

		ampl *= Gain
		Frequency *= 2.01
	end

	return result / maxAmpl
end

function NoiseMethods.Cellular(self: Noise, x, y): number
	local Seed = self.Seed or 0
	local Frequency = self.Frequency or 1.0
	local Gain = self.Gain or 0.6
	local Octaves = self.Octaves or 1

	local ampl = 1
	local maxAmpl = ampl

	local xi = math.floor(x)
	local yi = math.floor(y)

	local f1 = math.huge
	local f2 = math.huge

	for _ = 1, Octaves do
		for oy = -1, 1 do
			for ox = -1, 1 do
				local cx = xi + ox
				local cy = yi + oy

				local px = cx + _rand(cx * Frequency, cy * Frequency, Seed) * ampl
				local py = cy + _rand((cx + 100) * Frequency, (cy + 100) * Frequency, Seed) * ampl

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

		ampl *= Gain
		Frequency *= 2.01

		maxAmpl += ampl
	end

	return (math.sqrt(f2) - math.sqrt(f1)) / maxAmpl
end

function NoiseMethods.Turbulence(self: Noise, x: number, y: number): number
	local Seed = self.Seed or 0
	local Frequency = self.Frequency or 1.0
	local Gain = self.Gain or 0.6
	local Octaves = self.Octaves or 1

	local result = 0

	local ampl = 1
	local maxAmpl = ampl

	for _i = 1, Octaves do
		local n = self:Perlin(x * Frequency, y * Frequency, Seed)

		result += math.abs(n) * ampl

		ampl *= Gain
		Frequency *= 2.01

		maxAmpl += ampl
	end

	return result / maxAmpl
end

function NoiseMethods.Marble(self: Noise, x: number, y: number): number
	local n = self:Fbm(x, y)
	return math.sin((x * 0.1 + n * 5))
end

function NoiseMethods.Terrace(self: Noise, x: number, y: number, steps: number): number
	local n = self:Fbm(x, y)
	return math.floor(n * steps) / steps
end

NoisePP.white = function(self: Noise, x: number, y: number): number
	return _rand(x, y, self.Seed or 0)
end

----- Domain Warp methods -----

function Warp.Apply(self: DomainWarp, x: number, y: number): (number, number)
	local wx, wy = x, y

	local Seed = self.Seed or 0
	local Frequency = self.Frequency or 1.0
	local Gain = self.Gain or 0.6
	local Octaves = self.Octaves or 1

	local ampl = 1.0

	local noise = NoisePP.new({
		Seed = Seed,
		Frequency = Frequency,
		Gain = Gain,
		Octaves = Octaves,
	})

	local tx = noise:Fbm(wx, wy)
	local ty = noise:Fbm(wx + 100, wy + 100)

	wx += (tx or wx) * ampl
	wy += (ty or wy) * ampl

	return wx, wy
end

function WarpMethods.SetSeed(self: DomainWarp, seed: number): ()
	self.Seed = seed
end

function WarpMethods.SetFrequency(self: DomainWarp, freq: number): ()
	self.Frequency = freq
end

function WarpMethods.SetGain(self: DomainWarp, gain: number): ()
	self.Gain = gain
end

function WarpMethods.SetOctaves(self: DomainWarp, octaves: number): ()
	self.Octaves = octaves
end

function WarpMethods.SetParameters(self: DomainWarp, params: Parameters)
	self.Seed = params.Seed or self.Seed
	self.Frequency = params.Frequency or self.Frequency
	self.Gain = params.Gain or self.Gain
	self.Octaves = params.Octaves or self.Octaves
end

-- Noise class type
type NoisePP = {
	new: (params: Parameters) -> Noise,
	warp: (params: Parameters) -> DomainWarp,
}

type Noise = Parameters & typeof(NoiseMethods)
type DomainWarp = Parameters & typeof(WarpMethods)

type Parameters = {
	Seed: number?,
	Frequency: number?,
	Gain: number?,
	Octaves: number?,
}

return NoisePP :: NoisePP

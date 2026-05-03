# Noise++ module

## A noise module that adds noise types and features that the math.noise function doesn't have.

## Usage

Firstly, install NoisePP via [Wally package manager](https://wally.run) or from this repository.

Then, require it from any script.

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local noisepp = require(ReplicatedStorage.Packages.noisepp)

    local x, y = 1, 5

    local Noise = noisepp.new({
        Seed = tick(),
        Frequency = 0.5,
        Gain = 0.6,
        Octaves = 4
    }) -- The arguments that aren't passed are replaced by the defaults.

    print(Noise:Fbm(x, y))

## License

I dont have any license for this, if you would make a showcase on it, you can just credit me for the module.

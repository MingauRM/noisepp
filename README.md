# Noise++ module

## A noise module that adds noise types and features that the math.noise function doesn't have.

## Usage

Firstly, install NoisePP via [Wally package manager](https://wally.run) or from this repository.

Then, require it from any script.

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local noisepp = require(ReplicatedStorage.Packages.noisepp)

    local SEED = tick()
    local x, y = 1, 5

    noisepp.set_octaves(4)
    noisepp.set_frequency(0.25)
    noisepp.set_gain(0.6)

    print(noisepp.fbm(x, y, SEED))

## License

I dont have any license for this, if you would make a showcase on it, you can just credit me for the module.

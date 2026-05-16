# Noise++ module

## A noise module that adds noise types and features that the math.noise function doesn't have.

## Usage

Firstly, install NoisePP via [Wally package manager](https://wally.run/package/mingaurm/noisepp) or from this repository.

Then, require it from any script.

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local noisepp = require(ReplicatedStorage.Packages.noisepp)

    local noise = noisepp.new()
    local x, y = 1, 5

    noise:SetSeed(tick())
    print(noise:Fbm(x, y))

## License

I dont have any license for this, if you would make a showcase on it, you can just credit me for the module.

local biomes = require("data.biomes")

local BiomeResolver = {}

local NOISE_SCALE = 0.05

local function remap(value, inMin, inMax)
    if inMax == inMin then
        return 0
    end
    return (value - inMin) / (inMax - inMin)
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function BiomeResolver.resolveChunk(worldSeed, chunkX, chunkY)
    local seedOffset = worldSeed * 0.0001
    local nx = chunkX * NOISE_SCALE + seedOffset
    local ny = chunkY * NOISE_SCALE - seedOffset
    local noiseValue = love.math.noise(nx, ny)

    local biome = biomes.findByNoiseValue(noiseValue)
    local normalized = remap(noiseValue, biome.noise.min, biome.noise.max)
    normalized = clamp(normalized, 0, 1)
    local distanceToEdge = math.min(normalized, 1 - normalized)
    local transitionStrength = clamp(1 - distanceToEdge * 4, 0, 1)

    local neighborSamples = {}
    local directions = {
        { dx = 1, dy = 0 },
        { dx = -1, dy = 0 },
        { dx = 0, dy = 1 },
        { dx = 0, dy = -1 },
    }

    for _, dir in ipairs(directions) do
        local neighborValue = love.math.noise((chunkX + dir.dx) * NOISE_SCALE + seedOffset, (chunkY + dir.dy) * NOISE_SCALE - seedOffset)
        neighborSamples[#neighborSamples + 1] = {
            dx = dir.dx,
            dy = dir.dy,
            biome = biomes.findByNoiseValue(neighborValue).id,
            noiseValue = neighborValue,
        }
    end

    return biome.id, {
        noiseValue = noiseValue,
        normalized = normalized,
        transitionStrength = transitionStrength,
        neighbors = neighborSamples,
    }
end

return BiomeResolver

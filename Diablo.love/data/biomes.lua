local biomes = {}

local biomeList = {
    {
        id = "forest",
        label = "Verdant Forest",
        noise = { min = 0.0, max = 0.45 },
        tileColors = {
            primary = { 0.09, 0.26, 0.12, 1 },
            secondary = { 0.13, 0.32, 0.16, 1 },
            accent = { 0.2, 0.4, 0.22, 1 },
        },
        propWeights = {
            { id = "shrub", weight = 3 },
            { id = "stone", weight = 1 },
        },
        structureWeights = {
            { id = "tree_cluster", weight = 4 },
            { id = "forest_hut", weight = 0.6 },
        },
        foeWeights = {
            { id = "slow", weight = 3 },
            { id = "medium", weight = 2 },
        },
    },
    {
        id = "desert",
        label = "Scorched Expanse",
        noise = { min = 0.45, max = 0.75 },
        tileColors = {
            primary = { 0.58, 0.45, 0.24, 1 },
            secondary = { 0.64, 0.5, 0.28, 1 },
            accent = { 0.74, 0.58, 0.32, 1 },
        },
        propWeights = {
            { id = "dune", weight = 3 },
            { id = "dry_brush", weight = 1 },
        },
        structureWeights = {
            { id = "desert_rock", weight = 5 },
            { id = "ruined_obelisk", weight = 0.8 },
        },
        foeWeights = {
            { id = "medium", weight = 2 },
            { id = "aggressive", weight = 3 },
        },
    },
    {
        id = "tundra",
        label = "Frozen Tundra",
        noise = { min = 0.75, max = 1.0 },
        tileColors = {
            primary = { 0.78, 0.84, 0.89, 1 },
            secondary = { 0.86, 0.91, 0.95, 1 },
            accent = { 0.7, 0.77, 0.84, 1 },
        },
        propWeights = {
            { id = "snow_drift", weight = 2 },
            { id = "ice_rock", weight = 1 },
        },
        structureWeights = {
            { id = "ice_spike", weight = 4 },
            { id = "frozen_ruin", weight = 0.4 },
        },
        foeWeights = {
            { id = "slow", weight = 1 },
            { id = "aggressive", weight = 2 },
        },
    },
}

local biomeIndex = {}
for _, biome in ipairs(biomeList) do
    biomeIndex[biome.id] = biome
end

function biomes.getAll()
    return biomeList
end

function biomes.getById(id)
    return biomeIndex[id]
end

function biomes.findByNoiseValue(value)
    for _, biome in ipairs(biomeList) do
        if value >= biome.noise.min and value < biome.noise.max then
            return biome
        end
    end
    return biomeList[#biomeList]
end

return biomes

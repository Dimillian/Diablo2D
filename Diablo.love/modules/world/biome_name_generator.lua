local BiomeNameGenerator = {}

local templateLibrary = {
    default = {
        patterns = {
            "The {adjective} {landform}",
            "{adjective} {landform}",
            "{landform} of {mystic}",
            "{landform} of the {guardian}",
        },
        adjective = {
            "Ancient",
            "Silent",
            "Forgotten",
            "Shimmering",
            "Radiant",
            "Dusky",
            "Wild",
            "Hidden",
        },
        landform = {
            "Expanse",
            "Wilds",
            "Frontier",
            "Sanctum",
            "Reach",
            "Hollow",
            "March",
            "Terrace",
        },
        mystic = {
            "Echoes",
            "Embers",
            "Twilight",
            "Dawn",
            "Storms",
            "Shadows",
            "Dreams",
            "Legends",
        },
        guardian = {
            "Watchers",
            "Serpent",
            "Titan",
            "Wardens",
            "Keeper",
            "Sentinel",
            "Stag",
            "Oracle",
        },
    },
    forest = {
        adjective = {
            "Emerald",
            "Whispering",
            "Sun-dappled",
            "Moonlit",
            "Verdant",
            "Bramble",
        },
        landform = {
            "Glade",
            "Thicket",
            "Grove",
            "Copse",
            "Canopy",
            "Wood",
        },
        mystic = {
            "Leaves",
            "Roots",
            "Song",
            "Boughs",
            "Petals",
            "Sap",
        },
        guardian = {
            "Stag",
            "Dryad",
            "Treant",
            "Sylph",
            "Wolf",
            "Greenwarden",
        },
    },
    desert = {
        adjective = {
            "Scorched",
            "Shifting",
            "Sunworn",
            "Burnished",
            "Gritstone",
            "Arid",
        },
        landform = {
            "Dunes",
            "Waste",
            "Sea",
            "Basin",
            "Reach",
            "Badlands",
        },
        mystic = {
            "Mirage",
            "Ember",
            "Heat",
            "Dust",
            "Sirocco",
            "Sun",
        },
        guardian = {
            "Jackal",
            "Sand Warden",
            "Sirocco",
            "Scarab",
            "Phoenix",
            "Desert King",
        },
    },
    tundra = {
        adjective = {
            "Frozen",
            "Glacial",
            "Blizzard",
            "Icy",
            "Wind-scoured",
            "Rimebound",
        },
        landform = {
            "Expanse",
            "Frostlands",
            "Drifts",
            "Glacier",
            "Tundra",
            "Barrens",
        },
        mystic = {
            "Aurora",
            "Frost",
            "Silence",
            "Midnight",
            "Icicles",
            "Starlight",
        },
        guardian = {
            "Bear",
            "White Wolf",
            "Icebound Sentinel",
            "Rimekeeper",
            "Snowcaller",
            "Frost Giant",
        },
    },
}

local function buildSeeds(seed, biomeId)
    local base = math.floor(seed or 0)
    local secondary = 0

    if biomeId then
        for index = 1, #biomeId do
            local byte = string.byte(biomeId, index)
            base = (base + byte * index) % 2147483563
            secondary = (secondary + byte * (index + 11)) % 2147483399
        end
    end

    if base == 0 then
        base = 127
    end
    if secondary == 0 then
        secondary = 379
    end

    return base, secondary
end

local function pickFrom(rng, list)
    if not list or #list == 0 then
        return ""
    end
    local index = rng:random(#list)
    return list[index]
end

function BiomeNameGenerator.generate(opts)
    opts = opts or {}
    local biomeId = opts.biomeId
    local seed = opts.seed or os.time()

    local biomeTemplates = templateLibrary[biomeId] or {}
    local defaults = templateLibrary.default

    local firstSeed, secondSeed = buildSeeds(seed, biomeId)
    local rng = love.math.newRandomGenerator(firstSeed, secondSeed)

    local patterns = biomeTemplates.patterns or defaults.patterns
    local pattern = pickFrom(rng, patterns)
    if pattern == "" then
        return "Unknown Wilds"
    end

    local name = pattern:gsub("{(%w+)}", function(token)
        local pool = biomeTemplates[token] or defaults[token] or { token }
        return pickFrom(rng, pool)
    end)

    name = name:gsub("%s+", " ")
    name = name:gsub("^%s+", "")
    name = name:gsub("%s+$", "")

    if name == "" then
        return "Unknown Wilds"
    end

    return name
end

return BiomeNameGenerator

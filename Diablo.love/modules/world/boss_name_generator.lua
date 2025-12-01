local Items = require("data.items")

local BossNameGenerator = {}

local adjectivePool = {}
local nounPool = {}

for _, affix in pairs(Items.prefixes) do
    if affix.name then
        adjectivePool[#adjectivePool + 1] = affix.name
    end
end

for _, affix in pairs(Items.suffixes) do
    if affix.name then
        nounPool[#nounPool + 1] = affix.name
    end
end

local fallbackAdjectives = { "Ancient", "Savage", "Malevolent", "Tormented", "Ravenous", "Eternal" }
local fallbackNouns = { "Gloom", "Ruin", "Ash", "Thorns", "Hunger", "Night" }

local function pick(rng, list, fallback)
    if list and #list > 0 then
        return list[rng:random(1, #list)]
    end
    return fallback[rng:random(1, #fallback)]
end

function BossNameGenerator.generate(seed)
    local rng = love.math.newRandomGenerator(seed or love.math.random(1, 999999))
    local adjective = pick(rng, adjectivePool, fallbackAdjectives)
    local noun = pick(rng, nounPool, fallbackNouns)
    return string.format("%s of %s", adjective, noun)
end

return BossNameGenerator

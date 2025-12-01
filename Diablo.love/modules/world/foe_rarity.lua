local foeRarities = require("data.foe_rarities")

local foeRarity = {}

local DEFAULT_RARITY_ID = "common"

local function clamp01(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function scale(value, multiplier)
    if value == nil then
        return nil
    end
    if not multiplier then
        return value
    end
    return value * multiplier
end

local function scaleAndRound(value, multiplier)
    local scaled = scale(value, multiplier)
    if scaled == nil then
        return nil
    end
    return math.max(1, math.floor(scaled + 0.5))
end

local function tintColor(baseColor, tint)
    local source = baseColor or { 1, 1, 1, 1 }
    local tintColorValue = tint or { 1, 1, 1, 1 }

    local r = clamp01((source[1] or 1) * (tintColorValue[1] or 1))
    local g = clamp01((source[2] or 1) * (tintColorValue[2] or 1))
    local b = clamp01((source[3] or 1) * (tintColorValue[3] or 1))
    local a = clamp01((source[4] or 1) * (tintColorValue[4] or 1))

    return { r, g, b, a }
end

function foeRarity.get(rarityId)
    if type(rarityId) ~= "string" or rarityId == "" then
        return foeRarities.getById(DEFAULT_RARITY_ID)
    end
    return foeRarities.getById(rarityId)
end

function foeRarity.apply(config, rarityId)
    config = config or {}
    local rarity = foeRarity.get(rarityId)

    local damageMin = scaleAndRound(config.damageMin, rarity.damageMultiplier)
    local damageMax = scaleAndRound(config.damageMax, rarity.damageMultiplier)
    if damageMin and damageMax and damageMax < damageMin then
        damageMax = damageMin
    end

    return {
        rarityId = rarity.id,
        rarityLabel = rarity.label,
        health = scaleAndRound(config.health, rarity.healthMultiplier),
        damageMin = damageMin,
        damageMax = damageMax,
        detectionRange = scale(config.detectionRange, rarity.detectionMultiplier),
        leashExtension = scale(config.leashExtension, rarity.leashMultiplier),
        scaleMultiplier = rarity.scaleMultiplier or 1.0,
        packAggro = rarity.forcePackAggro or config.packAggro,
        experience = scaleAndRound(config.experience, rarity.experienceMultiplier),
        color = tintColor(config.color, rarity.tint),
        itemDropChanceMultiplier = rarity.itemDropChanceMultiplier or 1.0,
        itemDropCount = rarity.itemDropCount,
        goldChanceMultiplier = rarity.goldChanceMultiplier or 1.0,
        goldAmountMultiplier = rarity.goldAmountMultiplier or 1.0,
    }
end

function foeRarity.withDefaults(descriptor)
    descriptor = descriptor or {}
    if not descriptor.rarity or descriptor.rarity == "" then
        descriptor.rarity = DEFAULT_RARITY_ID
    end

    local rarity = foeRarity.get(descriptor.rarity)
    descriptor.rarityLabel = descriptor.rarityLabel or rarity.label

    return descriptor
end

return foeRarity

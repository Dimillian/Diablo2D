local foeTypes = {}

-- Define 3 foe types with different characteristics
foeTypes.types = {
    slow = {
        name = "Slow Foe",
        speed = 60,
        detectionRange = 100,
        color = { 0.8, 0.2, 0.2, 1 }, -- Red
        wanderInterval = 0.01,
        health = 40,
        damageMin = 2,
        damageMax = 4,
        attackSpeed = 0.5,
        range = 50,
        leashExtension = 350,
        packAggro = false,
    },
    medium = {
        name = "Medium Foe",
        speed = 100,
        detectionRange = 180,
        color = { 1, 0.5, 0, 1 }, -- Orange
        wanderInterval = 0.01,
        health = 55,
        damageMin = 2,
        damageMax = 5,
        attackSpeed = 0.8,
        range = 50,
        leashExtension = 350,
        packAggro = false,
    },
    aggressive = {
        name = "Aggressive Foe",
        speed = 150,
        detectionRange = 250,
        color = { 0.8, 0.1, 0.8, 1 }, -- Purple/magenta
        wanderInterval = 0.01,
        health = 65,
        damageMin = 5,
        damageMax = 7,
        attackSpeed = 1.0,
        range = 50,
        leashExtension = 350,
        packAggro = true,
    },
}

-- Get a random foe type
function foeTypes.getRandomType()
    local keys = { "slow", "medium", "aggressive" }
    return keys[math.random(#keys)]
end

-- Get foe type configuration
function foeTypes.getConfig(typeName)
    return foeTypes.types[typeName] or foeTypes.types.slow
end

return foeTypes

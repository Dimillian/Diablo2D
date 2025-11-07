local foeTypes = {}

-- Define 3 foe types with different characteristics
foeTypes.types = {
    slow = {
        id = "slow",
        name = "Green Orc",
        speed = 30,
        detectionRange = 100,
        color = { 0.8, 0.2, 0.2, 1 },
        wanderInterval = 3.0,
        health = 40,
        damageMin = 2,
        damageMax = 4,
        attackSpeed = 0.5,
        range = 50,
        leashExtension = 350,
        packAggro = false,
        goldRange = { min = 3, max = 8 },
        goldChance = 0.6,
        spritePrefix = "orc1",
    },
    medium = {
        id = "medium",
        name = "Blue Orc",
        speed = 50,
        detectionRange = 180,
        color = { 1, 0.5, 0, 1 },
        wanderInterval = 2.5,
        health = 55,
        damageMin = 2,
        damageMax = 5,
        attackSpeed = 0.8,
        range = 50,
        leashExtension = 350,
        packAggro = false,
        goldRange = { min = 5, max = 12 },
        goldChance = 0.7,
        spritePrefix = "orc2",
    },
    aggressive = {
        id = "aggressive",
        name = "Red Orc",
        speed = 75,
        detectionRange = 250,
        color = { 0.8, 0.1, 0.8, 1 },
        wanderInterval = 2.0,
        health = 65,
        damageMin = 5,
        damageMax = 7,
        attackSpeed = 1.0,
        range = 50,
        leashExtension = 350,
        packAggro = true,
        goldRange = { min = 8, max = 18 },
        goldChance = 0.75,
        spritePrefix = "orc3",
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

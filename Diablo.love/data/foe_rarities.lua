local rarities = {
    common = {
        id = "common",
        label = "Common",
        healthMultiplier = 1.0,
        damageMultiplier = 1.0,
        detectionMultiplier = 1.0,
        leashMultiplier = 1.0,
        scaleMultiplier = 1.0,
        forcePackAggro = false,
        tint = { 1, 1, 1, 1 },
        experienceMultiplier = 1.0,
        itemDropChanceMultiplier = 1.0,
        itemDropCount = { min = 1, max = 1 },
        goldChanceMultiplier = 1.0,
        goldAmountMultiplier = 1.0,
    },
    elite = {
        id = "elite",
        label = "Elite",
        healthMultiplier = 2.1,
        damageMultiplier = 1.6,
        detectionMultiplier = 1.25,
        leashMultiplier = 1.35,
        scaleMultiplier = 1.12,
        forcePackAggro = true,
        tint = { 0.35, 0.65, 1.0, 1 },
        experienceMultiplier = 1.35,
        itemDropChanceMultiplier = 1.35,
        itemDropCount = { min = 1, max = 1 },
        goldChanceMultiplier = 1.25,
        goldAmountMultiplier = 1.35,
    },
    boss = {
        id = "boss",
        label = "Boss",
        healthMultiplier = 4.0,
        damageMultiplier = 2.4,
        detectionMultiplier = 1.5,
        leashMultiplier = 1.6,
        scaleMultiplier = 1.25,
        forcePackAggro = true,
        tint = { 0.75, 0.35, 1.0, 1 },
        experienceMultiplier = 1.9,
        itemDropChanceMultiplier = 1.0, -- Bosses always drop via item count below
        itemDropCount = { min = 2, max = 3 },
        goldChanceMultiplier = 1.5,
        goldAmountMultiplier = 2.0,
    },
}

local foeRarities = {}

function foeRarities.getById(id)
    return rarities[id] or rarities.common
end

function foeRarities.getAll()
    return rarities
end

return foeRarities

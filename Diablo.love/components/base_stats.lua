local defaultStats = {
    damageMin = 5,
    damageMax = 8,
    defense = 2,
    health = 50,
    mana = 25,
    critChance = 0.05,
    moveSpeed = 0,
    dodgeChance = 0,
    goldFind = 0,
    lifeSteal = 0,
    attackSpeed = 0,
    resistAll = 0,
    manaRegen = 0.5,
}

local function createBaseStatsComponent(opts)
    opts = opts or {}

    local stats = {}
    for key, value in pairs(defaultStats) do
        stats[key] = opts[key] or value
    end

    return stats
end

return createBaseStatsComponent

local defaultStats = {
    -- Primary attributes
    strength = 5,
    dexterity = 5,
    vitality = 50,
    intelligence = 25,
    -- Direct stats (not derived from attributes)
    defense = 2,
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

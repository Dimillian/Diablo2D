local LifetimeStats = {}

local function clampNonNegative(value)
    value = value or 0
    if value < 0 then
        return 0
    end
    return value
end

---Normalize a lifetime stats table into a safe structure.
---@param stats table|nil
---@return table
function LifetimeStats.normalize(stats)
    return {
        foesKilled = clampNonNegative(stats and stats.foesKilled),
        damageDealt = clampNonNegative(stats and stats.damageDealt),
        experienceEarned = clampNonNegative(stats and stats.experienceEarned),
        levelsGained = clampNonNegative(stats and stats.levelsGained),
    }
end

---Ensure lifetime stats exist on the world (or return a normalized copy for a snapshot).
---@param world table|nil
---@param initial table|nil
---@return table
function LifetimeStats.ensure(world, initial)
    if not world then
        return LifetimeStats.normalize(initial)
    end

    if world.lifetimeStats then
        world.lifetimeStats = LifetimeStats.normalize(world.lifetimeStats)
        return world.lifetimeStats
    end

    world.lifetimeStats = LifetimeStats.normalize(initial)
    return world.lifetimeStats
end

function LifetimeStats.addDamage(world, amount)
    local stats = LifetimeStats.ensure(world)
    stats.damageDealt = clampNonNegative(stats.damageDealt) + clampNonNegative(amount)
end

function LifetimeStats.addKill(world)
    local stats = LifetimeStats.ensure(world)
    stats.foesKilled = clampNonNegative(stats.foesKilled) + 1
end

function LifetimeStats.addExperience(world, amount)
    local stats = LifetimeStats.ensure(world)
    stats.experienceEarned = clampNonNegative(stats.experienceEarned) + clampNonNegative(amount)
end

function LifetimeStats.addLevels(world, amount)
    local stats = LifetimeStats.ensure(world)
    stats.levelsGained = clampNonNegative(stats.levelsGained) + clampNonNegative(amount)
end

return LifetimeStats

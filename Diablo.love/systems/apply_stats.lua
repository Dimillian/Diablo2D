local EquipmentHelper = require("system_helpers.equipment")

local applyStatsSystem = {}

---Apply computed stats (base + equipment) to player entity components
---Updates movement speed, health max, etc. based on total stats
function applyStatsSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player then
        return
    end

    local totalStats = EquipmentHelper.computeTotalStats(player)

    -- Apply movement speed: base speed * (1 + moveSpeed percentage bonuses)
    if player.movement then
        local baseSpeed = 140 -- Default base movement speed in pixels/second

        -- Apply moveSpeed bonuses from stats (both base and equipment)
        local speedMultiplier = 1 + (totalStats.moveSpeed or 0)
        player.movement.speed = baseSpeed * speedMultiplier
    end

    -- Apply health max: update max health based on stats
    if player.health then
        local baseMaxHealth = 50 -- Default base health
        if player.baseStats and player.baseStats.health then
            baseMaxHealth = player.baseStats.health
        end

        -- Total stats already includes base + equipment
        local newMaxHealth = totalStats.health or baseMaxHealth

        -- Update max health
        local oldMaxHealth = player.health.max
        player.health.max = newMaxHealth

        -- Adjust current health when max changes
        if newMaxHealth > oldMaxHealth then
            -- If max increased, add the difference to current health
            local healthIncrease = newMaxHealth - oldMaxHealth
            player.health.current = math.min(player.health.current + healthIncrease, newMaxHealth)
        elseif newMaxHealth < oldMaxHealth then
            -- If max decreased, cap current health proportionally
            local ratio = player.health.current / oldMaxHealth
            player.health.current = math.min(player.health.current, newMaxHealth * ratio)
        end
    end
end

return applyStatsSystem

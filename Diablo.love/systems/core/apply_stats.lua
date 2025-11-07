local EquipmentHelper = require("systems.helpers.equipment")

local applyStatsSystem = {}

---Apply computed stats (base + equipment) to player entity components
---Updates movement speed, health max, etc. based on total stats
function applyStatsSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player then
        return
    end

    local totalStats = EquipmentHelper.computeTotalStats(player)

    player.stats = player.stats or {}
    player.stats.total = totalStats
    player.stats.base = player.baseStats

    -- Apply movement speed: base speed * (1 + moveSpeed percentage bonuses)
    if player.movement then
        local baseSpeed = 140 -- Default base movement speed in pixels/second

        -- Apply moveSpeed bonuses from stats (both base and equipment)
        local speedMultiplier = 1 + (totalStats.moveSpeed or 0)
        player.movement.speed = baseSpeed * speedMultiplier
    end

    -- Apply health max: update max health based on stats
    if player.health then
        -- Total stats already includes derived health from vitality + equipment bonuses
        local newMaxHealth = totalStats.health or 50

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

    -- Apply mana max: update max mana based on stats
    if player.mana then
        -- Total stats already includes derived mana from intelligence + equipment bonuses
        local newMaxMana = totalStats.mana or 25

        -- Update max mana
        local oldMaxMana = player.mana.max
        player.mana.max = newMaxMana

        -- Adjust current mana when max changes
        if newMaxMana > oldMaxMana then
            -- If max increased, add the difference to current mana
            local manaIncrease = newMaxMana - oldMaxMana
            player.mana.current = math.min(player.mana.current + manaIncrease, newMaxMana)
        elseif newMaxMana < oldMaxMana then
            -- If max decreased, cap current mana proportionally
            local ratio = player.mana.current / oldMaxMana
            player.mana.current = math.min(player.mana.current, newMaxMana * ratio)
        end
    end
end

return applyStatsSystem

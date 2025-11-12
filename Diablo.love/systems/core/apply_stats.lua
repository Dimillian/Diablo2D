local EquipmentHelper = require("systems.helpers.equipment")
local ComponentDefaults = require("data.component_defaults")

local applyStatsSystem = {}

local function recalculateResource(component, newMaxValue, fallback)
    if not component then
        return
    end

    local oldMax = component.max or fallback
    local newMax = newMaxValue or fallback

    component.max = newMax

    local current = component.current or newMax

    if newMax > oldMax then
        local increase = newMax - oldMax
        current = math.min(current + increase, newMax)
    elseif newMax < oldMax then
        if oldMax > 0 then
            local ratio = current / oldMax
            current = math.min(current, newMax * ratio)
        else
            current = math.min(current, newMax)
        end
    else
        current = math.min(current, newMax)
    end

    component.current = current
end

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
        local baseSpeed = ComponentDefaults.BASE_MOVEMENT_SPEED

        -- Apply moveSpeed bonuses from stats (both base and equipment)
        local speedMultiplier = 1 + (totalStats.moveSpeed or 0)
        player.movement.speed = baseSpeed * speedMultiplier
    end

    -- Apply health max: update max health based on stats
    -- Apply health and mana caps using shared helper
    recalculateResource(player.health, totalStats.health, ComponentDefaults.PLAYER_STARTING_HEALTH)
    recalculateResource(player.mana, totalStats.mana, ComponentDefaults.PLAYER_STARTING_MANA)
end

return applyStatsSystem

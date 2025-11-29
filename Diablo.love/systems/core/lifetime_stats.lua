local LifetimeStats = require("modules.lifetime_stats")

local lifetimeStatsSystem = {}

---Track lifetime stats for player combat events.
---@param world table
---@param dt number|nil
function lifetimeStatsSystem.update(world, dt) -- luacheck: ignore 212/dt
    if not world or not world.pendingCombatEvents then
        return
    end

    LifetimeStats.ensure(world)

    local playerId = world.playerId
    if not playerId then
        return
    end

    for _, event in ipairs(world.pendingCombatEvents) do
        if event._lifetimeTracked then
            goto continue
        end

        if event.type == "damage" and event.sourceId == playerId then
            LifetimeStats.addDamage(world, event.amount or 0)
        elseif event.type == "death" and event.sourceId == playerId then
            LifetimeStats.addKill(world)
        end

        event._lifetimeTracked = true

        ::continue::
    end
end

return lifetimeStatsSystem

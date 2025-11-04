local manaRegenSystem = {}

---Apply mana regeneration over time based on player's manaRegen stat
---@param world WorldScene
---@param dt number
function manaRegenSystem.update(world, dt)
    local player = world:getPlayer()
    if not player or not player.mana then
        return
    end

    if not player.stats or not player.stats.total then
        return
    end

    local manaRegen = player.stats.total.manaRegen or 0
    if manaRegen <= 0 then
        return
    end

    local mana = player.mana
    if mana.current >= mana.max then
        return
    end

    mana.current = math.min(mana.current + (manaRegen * dt), mana.max)
end

return manaRegenSystem

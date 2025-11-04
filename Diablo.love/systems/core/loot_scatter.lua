local lootScatterSystem = {}

function lootScatterSystem.update(world, dt)
    if not world or not dt then
        return
    end

    local lootEntities = world:queryEntities({ "lootScatter", "position" })
    if not lootEntities or #lootEntities == 0 then
        return
    end

    for _, loot in ipairs(lootEntities) do
        if loot.inactive then
            world:removeComponent(loot.id, "lootScatter")
            goto continue
        end

        local scatter = loot.lootScatter
        if not scatter then
            goto continue
        end

        scatter.elapsed = (scatter.elapsed or 0) + dt

        local vx = scatter.vx or 0
        local vy = scatter.vy or 0

        loot.position.x = loot.position.x + vx * dt
        loot.position.y = loot.position.y + vy * dt

        local friction = scatter.friction or 8
        local decay = math.max(0, 1 - friction * dt)
        scatter.vx = vx * decay
        scatter.vy = vy * decay

        local threshold = scatter.stopThreshold or 8
        local speedSq = scatter.vx * scatter.vx + scatter.vy * scatter.vy
        local shouldStop = scatter.elapsed >= (scatter.maxDuration or 0.5)
            or speedSq <= (threshold * threshold)

        if shouldStop then
            world:removeComponent(loot.id, "lootScatter")
        end

        ::continue::
    end
end

return lootScatterSystem

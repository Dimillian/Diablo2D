local vector = require("modules.vector")

local chaseSystem = {}

function chaseSystem.update(world, _dt)
    local entities = world:queryEntities({ "chase", "movement", "position" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities (too far from player)
        if entity.inactive then
            goto continue
        end

        local chase = entity.chase
        local target = world:getEntity(chase.targetId)

        if not target or not target.position then
            goto continue
        end

        local myPos = entity.position
        local targetPos = target.position

        -- Calculate direction to target
        local dx = targetPos.x - myPos.x
        local dy = targetPos.y - myPos.y
        local ndx, ndy, magnitude = vector.normalize(dx, dy)

        if magnitude > 0 then
            -- Normalize direction and set velocity
            entity.movement.vx = ndx
            entity.movement.vy = ndy
        end

        ::continue::
    end
end

return chaseSystem

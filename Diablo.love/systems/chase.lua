local chaseSystem = {}

local function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

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
        local dist = distance(myPos.x, myPos.y, targetPos.x, targetPos.y)

        if dist > 0 then
            -- Normalize direction and set velocity
            entity.movement.vx = dx / dist
            entity.movement.vy = dy / dist
        end

        ::continue::
    end
end

return chaseSystem

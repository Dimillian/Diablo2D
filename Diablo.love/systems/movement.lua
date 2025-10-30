local movementSystem = {}

function movementSystem.update(world, dt)
    local entities = world:queryEntities({ "movement", "position" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities (too far from player)
        if entity.inactive then
            goto continue
        end

        local movement = entity.movement
        local dx = movement.vx or 0
        local dy = movement.vy or 0

        if dx ~= 0 or dy ~= 0 then
            local length = math.sqrt(dx * dx + dy * dy)
            if length > 0 then
                dx = dx / length
                dy = dy / length
            end
        end

        local distance = movement.speed * dt
        entity.position.x = entity.position.x + dx * distance
        entity.position.y = entity.position.y + dy * distance

        -- Reset per-frame velocity after applying.
        movement.vx = 0
        movement.vy = 0

        ::continue::
    end
end

return movementSystem

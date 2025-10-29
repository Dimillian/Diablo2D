local movementSystem = {}

function movementSystem.update(world, dt)
    local movementComponents = world.components.movement

    for entityId, movement in pairs(movementComponents) do
        local entity = world.entities[entityId]
        if entity and entity.position then
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
        end
    end
end

return movementSystem

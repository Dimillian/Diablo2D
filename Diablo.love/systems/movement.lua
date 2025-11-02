local vector = require("modules.vector")

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

        local ndx, ndy = vector.normalize(dx, dy)

        local distance = movement.speed * dt
        local maxDistance = movement.maxDistance
        if maxDistance ~= nil then
            -- Clamp how far we can travel this frame (used by chase separation logic)
            distance = math.min(distance, math.max(maxDistance, 0))
        end
        entity.position.x = entity.position.x + ndx * distance
        entity.position.y = entity.position.y + ndy * distance

        -- Apply knockback if present (direct position offset)
        if entity.knockback then
            local knockback = entity.knockback
            knockback.timer = (knockback.timer or 0) - dt

            if knockback.timer > 0 then
                -- Apply knockback as direct position offset
                -- strength controls pixels per second of knockback
                local strength = knockback.strength or 20
                local knockbackDistance = strength * dt
                entity.position.x = entity.position.x + knockback.x * knockbackDistance
                entity.position.y = entity.position.y + knockback.y * knockbackDistance
            else
                -- Remove knockback component when timer expires
                world:removeComponent(entity.id, "knockback")
            end
        end

        -- Reset per-frame velocity after applying.
        movement.vx = 0
        movement.vy = 0
        movement.maxDistance = nil

        ::continue::
    end
end

return movementSystem

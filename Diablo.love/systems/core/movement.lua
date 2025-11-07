local vector = require("modules.vector")

local movementSystem = {}

function movementSystem.update(world, dt)
    local entities = world:queryEntities({ "movement", "position" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities (too far from player)
        if entity.inactive then
            if entity.physicsBody and entity.physicsBody.body then
                entity.physicsBody.body:setLinearVelocity(0, 0)
            end
            goto continue
        end

        local movement = entity.movement
        local dx = movement.vx or 0
        local dy = movement.vy or 0

        local ndx, ndy = vector.normalize(dx, dy)

        local physics = entity.physicsBody
        if physics and physics.body then
            if physics.contactNormals and (ndx ~= 0 or ndy ~= 0) then
                local projectedX = ndx
                local projectedY = ndy

                for _, normal in pairs(physics.contactNormals) do
                    local dot = projectedX * normal.x + projectedY * normal.y
                    if dot < 0 then
                        projectedX = projectedX - dot * normal.x
                        projectedY = projectedY - dot * normal.y
                    end
                end

                ndx, ndy = vector.normalize(projectedX, projectedY)
            end

            local speed = movement.speed or 0
            if movement.maxDistance ~= nil then
                local allowedDistance = math.max(movement.maxDistance, 0)
                if allowedDistance <= 0 then
                    speed = 0
                elseif dt > 0 then
                    speed = math.min(speed, allowedDistance / dt)
                end
            end

            if ndx == 0 and ndy == 0 then
                speed = 0
            end

            physics.body:setLinearVelocity(ndx * speed, ndy * speed)

            if entity.knockback then
                local knockback = entity.knockback
                knockback.timer = (knockback.timer or 0) - dt

                if knockback.timer > 0 then
                    local strength = knockback.strength or 20
                    local impulse = strength * dt
                    physics.body:applyLinearImpulse(knockback.x * impulse, knockback.y * impulse)
                else
                    world:removeComponent(entity.id, "knockback")
                end
            end

            movement.vx = 0
            movement.vy = 0
            movement.maxDistance = nil

            goto continue
        end

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

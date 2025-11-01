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
        local heading = movement.heading
        local intentStrafe = movement.intentStrafe

        local moveX, moveY = 0, 0

        if movement.intentForward and heading then
            moveX = moveX + heading.x
            moveY = moveY + heading.y
        end

        if intentStrafe then
            moveX = moveX + (intentStrafe.x or 0)
            moveY = moveY + (intentStrafe.y or 0)
        end

        local ndx, ndy = vector.normalize(moveX, moveY)

        if ndx ~= 0 or ndy ~= 0 then
            local distance = movement.speed * dt
            entity.position.x = entity.position.x + ndx * distance
            entity.position.y = entity.position.y + ndy * distance
        end

        movement.intentForward = false
        if intentStrafe then
            intentStrafe.x = 0
            intentStrafe.y = 0
        end

        ::continue::
    end
end

return movementSystem

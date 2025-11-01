local vector = require("modules.vector")

local mouseMovementSystem = {}

function mouseMovementSystem.update(scene, _dt)
    -- Only process if right mouse button is held
    if not love.mouse.isDown(2) then
        return
    end

    local entities = scene:queryEntities({ "movement", "playerControlled" })

    for _, entity in ipairs(entities) do
        if not entity.position or not entity.movement then
            goto continue
        end

        -- Get mouse position in screen coordinates
        local screenX, screenY = love.mouse.getPosition()

        -- Convert to world coordinates
        local camera = scene.camera or { x = 0, y = 0 }
        local coordinates = scene.systemHelpers and scene.systemHelpers.coordinates
        if not coordinates then
            goto continue
        end

        local worldX, worldY = coordinates.toWorldFromScreen(camera, screenX, screenY)

        -- Compute player center position
        local playerCenterX = entity.position.x + (entity.size and entity.size.w / 2 or 0)
        local playerCenterY = entity.position.y + (entity.size and entity.size.h / 2 or 0)

        -- Compute direction vector from player to mouse cursor
        local dx = worldX - playerCenterX
        local dy = worldY - playerCenterY

        -- Calculate distance to target
        local distance = vector.distance(playerCenterX, playerCenterY, worldX, worldY)

        -- Threshold for stopping movement (prevents jitter when reaching destination)
        local threshold = 8

        if distance <= threshold then
            -- Close enough: stop movement
            entity.movement.vx = 0
            entity.movement.vy = 0
        else
            -- Normalize direction vector and set velocities
            local ndx, ndy = vector.normalize(dx, dy)
            entity.movement.vx = ndx
            entity.movement.vy = ndy
        end

        ::continue::
    end
end

return mouseMovementSystem

local vector = require("modules.vector")

local mouseLookSystem = {}

function mouseLookSystem.update(scene, _dt)
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

        -- Compute direction vector from player position to mouse cursor
        local playerCenterX = entity.position.x + (entity.size and entity.size.w / 2 or 0)
        local playerCenterY = entity.position.y + (entity.size and entity.size.h / 2 or 0)

        local dx = worldX - playerCenterX
        local dy = worldY - playerCenterY

        -- Normalize the direction vector
        local ndx, ndy = vector.normalize(dx, dy)

        -- Ensure lookDirection exists (should always exist due to component default, but safety check)
        if not entity.movement.lookDirection then
            entity.movement.lookDirection = { x = 0, y = -1 }
        end

        -- Mutate existing lookDirection table to preserve ECS component reference
        entity.movement.lookDirection.x = ndx
        entity.movement.lookDirection.y = ndy

        ::continue::
    end
end

return mouseLookSystem

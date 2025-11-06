local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")

local mouseMovementSystem = {}

function mouseMovementSystem.update(scene, _dt)
    -- Only process if right mouse button is held
    if not InputManager.isActionDown(InputActions.MOUSE_SECONDARY) then
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

        -- Compute direction vector from player to mouse cursor
        local ndx, ndy, distance = coordinates.directionFromEntityToWorld(entity, worldX, worldY)
        if not ndx or not ndy or not distance then
            goto continue
        end

        -- Threshold for stopping movement (prevents jitter when reaching destination)
        local threshold = 8

        if distance <= threshold then
            -- Close enough: stop movement
            entity.movement.vx = 0
            entity.movement.vy = 0
        else
            entity.movement.vx = ndx
            entity.movement.vy = ndy
        end

        ::continue::
    end
end

return mouseMovementSystem

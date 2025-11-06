local vector = require("modules.vector")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")

local playerInputSystem = {}

function playerInputSystem.update(world, _dt)
    local entities = world:queryEntities({ "movement", "playerControlled" })

    for _, entity in ipairs(entities) do
        local movement = entity.movement
        local dx, dy = 0, 0

        if InputManager.isActionDown(InputActions.MOVE_LEFT) then
            dx = dx - 1
        end
        if InputManager.isActionDown(InputActions.MOVE_RIGHT) then
            dx = dx + 1
        end
        if InputManager.isActionDown(InputActions.MOVE_UP) then
            dy = dy - 1
        end
        if InputManager.isActionDown(InputActions.MOVE_DOWN) then
            dy = dy + 1
        end

        movement.vx = dx
        movement.vy = dy

        -- Update look direction based on keyboard movement
        -- (mouse look will override this if mouse is moving)
        if dx ~= 0 or dy ~= 0 then
            local ndx, ndy = vector.normalize(dx, dy)
            if ndx ~= 0 or ndy ~= 0 then
                -- Ensure lookDirection exists
                if not movement.lookDirection then
                    movement.lookDirection = { x = 0, y = -1 }
                end
                -- Update look direction based on movement
                movement.lookDirection.x = ndx
                movement.lookDirection.y = ndy
            end
        end
    end
end

return playerInputSystem

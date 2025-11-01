local renderMouseLookSystem = {}

---Draw a simple arrow shape
---@param x number Center X position
---@param y number Center Y position
---@param angle number Rotation angle in radians
---@param size number Arrow size
local function drawArrow(x, y, angle, size)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)

    -- Draw arrow as a triangle pointing right (will be rotated)
    local arrowSize = size or 20
    local halfSize = arrowSize / 2

    -- Triangle points: tip pointing right, base on left
    love.graphics.polygon("fill",
        0, 0,                    -- Tip (right)
        -halfSize, -halfSize * 0.6, -- Top base (left)
        -halfSize * 0.5, 0,        -- Middle base (left)
        -halfSize, halfSize * 0.6   -- Bottom base (left)
    )

    love.graphics.pop()
end

function renderMouseLookSystem.draw(scene)
    local player = scene:getPlayer()
    if not player or not player.position or not player.movement or not player.movement.lookDirection then
        return
    end

    local camera = scene.camera or { x = 0, y = 0 }

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    local pos = player.position
    local size = player.size or { w = 32, h = 32 }
    local centerX = pos.x + (size.w / 2)
    local centerY = pos.y + (size.h / 2)

    -- Position arrow on a fixed-radius circle around the player center
    -- The arrow moves along this invisible circle based on look direction
    local lookDir = player.movement.lookDirection
    local playerRadius = math.max(size.w, size.h) / 2 -- Half the player size
    local circleRadius = playerRadius + 20 -- Fixed circle radius (ensures arrow doesn't overlap player)
    local arrowX = centerX + lookDir.x * circleRadius
    local arrowY = centerY + lookDir.y * circleRadius

    -- Calculate rotation angle from look direction
    local angle = math.atan2(lookDir.y, lookDir.x)

    -- Draw arrow with distinct color and opacity
    love.graphics.setColor(1, 1, 0.7, 0.7) -- Light yellow with moderate opacity
    local arrowSize = math.max(size.w, size.h) * 1.2 -- Slightly larger than player sprite
    drawArrow(arrowX, arrowY, angle, arrowSize)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderMouseLookSystem

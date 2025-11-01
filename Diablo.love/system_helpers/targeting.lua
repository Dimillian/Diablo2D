local vector = require("modules.vector")

local targeting = {}

---Acquire target based on mouse cursor position
---@param scene table World scene
---@param _player table Player entity (unused, kept for API consistency)
---@param maxRange number Maximum attack range in pixels
---@return table|nil Target entity or nil
function targeting.acquireTarget(scene, _player, maxRange)
    local foes = scene:queryEntities({ "foe", "position", "health" })
    if #foes == 0 then
        scene.currentTargetId = nil
        return nil
    end

    -- Get mouse position in screen coordinates
    local screenX, screenY = love.mouse.getPosition()

    -- Convert to world coordinates
    local camera = scene.camera or { x = 0, y = 0 }
    local coordinates = scene.systemHelpers and scene.systemHelpers.coordinates
    if not coordinates then
        scene.currentTargetId = nil
        return nil
    end

    local worldX, worldY = coordinates.toWorldFromScreen(camera, screenX, screenY)

    -- Find closest foe within range
    local closestFoe = nil
    local closestDist = maxRange

    for _, foe in ipairs(foes) do
        if foe.inactive or foe.dead then
            goto continue
        end

        -- Compute distance from mouse cursor to foe center
        local foeCenterX = foe.position.x + (foe.size and foe.size.w / 2 or 0)
        local foeCenterY = foe.position.y + (foe.size and foe.size.h / 2 or 0)

        local dist = vector.distance(worldX, worldY, foeCenterX, foeCenterY)

        if dist <= maxRange and dist < closestDist then
            closestDist = dist
            closestFoe = foe
        end

        ::continue::
    end

    if closestFoe then
        scene.currentTargetId = closestFoe.id
    else
        scene.currentTargetId = nil
    end

    return closestFoe
end

---Get current target entity
---@param scene table World scene
---@return table|nil Target entity or nil
function targeting.getTarget(scene)
    if not scene.currentTargetId then
        return nil
    end
    return scene:getEntity(scene.currentTargetId)
end

return targeting

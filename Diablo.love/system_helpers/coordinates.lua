local vector = require("modules.vector")

local coordinates = {}

---Convert screen coordinates to world coordinates
---@param camera table Camera object with x and y properties
---@param screenX number Screen X coordinate
---@param screenY number Screen Y coordinate
---@return number worldX, number worldY
function coordinates.toWorldFromScreen(camera, screenX, screenY)
    local worldX = screenX + camera.x
    local worldY = screenY + camera.y
    return worldX, worldY
end

---Calculate the center point for an entity using its position and size.
---@param entity table
---@return number|nil centerX, number|nil centerY
function coordinates.getEntityCenter(entity)
    if not entity or not entity.position then
        return nil, nil
    end

    local size = entity.size
    local halfWidth = size and size.w and (size.w / 2) or 0
    local halfHeight = size and size.h and (size.h / 2) or 0

    return entity.position.x + halfWidth, entity.position.y + halfHeight
end

---Compute the normalized direction vector and distance from an entity to a world point.
---@param entity table
---@param worldX number
---@param worldY number
---@return number|nil ndx, number|nil ndy, number|nil distance, number|nil centerX, number|nil centerY
function coordinates.directionFromEntityToWorld(entity, worldX, worldY)
    local centerX, centerY = coordinates.getEntityCenter(entity)
    if not centerX or not centerY then
        return nil, nil, nil, nil, nil
    end

    local dx = worldX - centerX
    local dy = worldY - centerY
    local ndx, ndy, distance = vector.normalize(dx, dy)

    return ndx, ndy, distance, centerX, centerY
end

return coordinates

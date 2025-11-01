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

return coordinates

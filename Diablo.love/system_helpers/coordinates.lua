local Coordinates = {}

function Coordinates.toWorldFromScreen(camera, screenX, screenY)
    local cameraX = 0
    local cameraY = 0

    if camera then
        cameraX = camera.x or 0
        cameraY = camera.y or 0
    end

    return screenX + cameraX, screenY + cameraY
end

return Coordinates

local coordinates = require("system_helpers.coordinates")

local cameraSystem = {}

function cameraSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player or not player.position or not player.size then
        return
    end

    local camera = world.camera
    if not camera then
        camera = { x = 0, y = 0 }
        world.camera = camera
    end

    local screenWidth, screenHeight = love.graphics.getDimensions()
    local halfWidth = screenWidth / 2
    local halfHeight = screenHeight / 2

    local playerCenterX, playerCenterY = coordinates.getEntityCenter(player)
    if not playerCenterX or not playerCenterY then
        return
    end

    camera.x = playerCenterX - halfWidth
    camera.y = playerCenterY - halfHeight
end

return cameraSystem

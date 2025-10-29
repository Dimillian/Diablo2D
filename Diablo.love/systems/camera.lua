local cameraSystem = {}

function cameraSystem.update(world, dt)
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

    local playerCenterX = player.position.x + (player.size.w / 2)
    local playerCenterY = player.position.y + (player.size.h / 2)

    camera.x = playerCenterX - halfWidth
    camera.y = playerCenterY - halfHeight
end

return cameraSystem

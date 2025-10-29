local playerInputSystem = {}

function playerInputSystem.update(world, dt)
    local movementComponents = world.components.movement
    local playerControlled = world.components.playerControlled or {}

    for entityId, movement in pairs(movementComponents) do
        if playerControlled[entityId] then
            local dx, dy = 0, 0

            if love.keyboard.isDown("left", "a") then
                dx = dx - 1
            end
            if love.keyboard.isDown("right", "d") then
                dx = dx + 1
            end
            if love.keyboard.isDown("up", "w") then
                dy = dy - 1
            end
            if love.keyboard.isDown("down", "s") then
                dy = dy + 1
            end

            movement.vx = dx
            movement.vy = dy
        end
    end
end

return playerInputSystem

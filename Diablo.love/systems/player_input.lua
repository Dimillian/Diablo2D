local playerInputSystem = {}

function playerInputSystem.update(world, dt)
    local entities = world:queryEntities({ "movement", "playerControlled" })

    for _, entity in ipairs(entities) do
        local movement = entity.movement
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

return playerInputSystem

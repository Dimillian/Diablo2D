local playerInputSystem = {}

function playerInputSystem.update(world, dt)
    for _, entity in pairs(world.entities) do
        local movement = entity.movement
        local playerControlled = entity.playerControlled

        if movement and playerControlled then
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

local wanderSystem = {}

local function randomDirection()
    local angle = math.random() * math.pi * 2
    return math.cos(angle), math.sin(angle)
end

function wanderSystem.update(world, dt)
    for _, entity in pairs(world.entities) do
        local wander = entity.wander
        local movement = entity.movement

        if wander and movement then
            if wander.elapsed <= 0 then
                movement.vx, movement.vy = randomDirection()
            end

            wander.elapsed = wander.elapsed + dt
            if wander.elapsed >= wander.interval then
                wander.elapsed = wander.elapsed - wander.interval
                movement.vx, movement.vy = randomDirection()
            end
        end
    end
end

return wanderSystem

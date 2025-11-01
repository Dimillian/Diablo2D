local wanderSystem = {}

local function randomDirection()
    local angle = math.random() * math.pi * 2
    return math.cos(angle), math.sin(angle)
end

function wanderSystem.update(world, dt)
    -- Query entities with wander and movement components
    -- Note: This will include player-controlled entities, but player_input
    -- runs first and sets velocity, so this only affects non-player entities
    -- If an entity has both playerControlled and wander, player input takes precedence
    local entities = world:queryEntities({ "wander", "movement" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities (too far from player)
        if entity.inactive then
            goto continue
        end

        -- Skip dead entities
        if entity.dead then
            goto continue
        end

        -- Skip player-controlled entities (player input should control them)
        if entity.playerControlled then
            goto continue
        end

        -- Skip entities that are chasing (chase behavior takes precedence)
        if entity.chase then
            goto continue
        end

        local wander = entity.wander
        local movement = entity.movement

        if wander.elapsed <= 0 then
            movement.vx, movement.vy = randomDirection()
        end

        wander.elapsed = wander.elapsed + dt
        if wander.elapsed >= wander.interval then
            wander.elapsed = wander.elapsed - wander.interval
            movement.vx, movement.vy = randomDirection()
        end

        ::continue::
    end
end

return wanderSystem

local walkingAnimationSystem = {}

---Update walking animation time for player-controlled entities
---@param world WorldScene
---@param dt number
function walkingAnimationSystem.update(world, dt)
    local entities = world:queryEntities({ "movement", "playerControlled" })

    for _, entity in ipairs(entities) do
        local movement = entity.movement
        if not movement then
            goto continue
        end

        -- Check if player is moving (has non-zero velocity)
        local isMoving = (movement.vx ~= 0) or (movement.vy ~= 0)

        if isMoving then
            -- Update animation time when moving
            movement.walkAnimationTime = (movement.walkAnimationTime or 0) + dt
        else
            -- Reset animation time when stopped for clean restart
            movement.walkAnimationTime = 0
        end

        ::continue::
    end
end

return walkingAnimationSystem

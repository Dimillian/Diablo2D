local foeAnimationSystem = {}

function foeAnimationSystem.update(world, dt)
    local entities = world:queryEntities({ "movement", "foe", "combat" })

    for _, entity in ipairs(entities) do
        local movement = entity.movement
        if not movement then
            goto continue
        end

        local renderable = entity.renderable
        if not renderable or not renderable.spritePrefix then
            goto continue
        end

        local combat = entity.combat
        local isAttacking = combat and combat.swingTimer and combat.swingTimer > 0

        if isAttacking then
            if not combat.attackAnimationTime then
                combat.attackAnimationTime = 0
            end
            combat.attackAnimationTime = combat.attackAnimationTime + dt
            renderable.animationState = "attacking"
        else
            local isMoving = (movement.vx ~= 0) or (movement.vy ~= 0)

            if isMoving then
                movement.walkAnimationTime = (movement.walkAnimationTime or 0) + dt
                renderable.animationState = "walking"
            else
                movement.walkAnimationTime = (movement.walkAnimationTime or 0) + dt
                renderable.animationState = "idle"
            end
        end

        ::continue::
    end
end

return foeAnimationSystem

local deathAnimationSystem = {}

---Update death animation timers and remove entities after animation completes
---@param world table World scene
---@param dt number Delta time
function deathAnimationSystem.update(world, dt)
    local dyingEntities = world:queryEntities({ "deathAnimation", "dead" })

    for _, entity in ipairs(dyingEntities) do
        if entity.inactive and entity.inactive.isInactive then
            goto continue
        end

        local deathAnim = entity.deathAnimation
        if not deathAnim then
            goto continue
        end

        -- Update timer
        deathAnim.timer = (deathAnim.timer or 0) + dt

        -- Check if animation is complete
        local totalDuration = deathAnim.animationDuration + deathAnim.holdDuration
        if deathAnim.timer >= totalDuration then
            -- Remove the entity after animation completes
            world:removeEntity(entity.id)
        end

        ::continue::
    end
end

return deathAnimationSystem

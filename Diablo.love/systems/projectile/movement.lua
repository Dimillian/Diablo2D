local vector = require("modules.vector")
local coordinates = require("systems.helpers.coordinates")
local projectileEffects = require("systems.helpers.projectile_effects")

local projectileMovementSystem = {}

local function removeProjectile(world, projectile)
    -- Stop travel sound if it's playing
    if projectile.travelSoundSource then
        projectile.travelSoundSource:stop()
        projectile.travelSoundSource = nil
    end
    world:removeEntity(projectile.id)
end

function projectileMovementSystem.update(world, dt)
    local projectiles = world:queryEntities({ "projectile", "position", "movement", "size" })
    for _, projectile in ipairs(projectiles) do
        local projectileComponent = projectile.projectile
        if not projectileComponent then
            goto continue
        end

        if projectileComponent.state == "impact" then
            projectileComponent.impactTimer = (projectileComponent.impactTimer or 0) - dt
            if projectileComponent.impactTimer <= 0 then
                removeProjectile(world, projectile)
            end
            goto continue
        end

        if projectile.inactive and projectile.inactive.isInactive then
            goto continue
        end

        projectileComponent.lifetime = (projectileComponent.lifetime or 0) - dt
        if projectileComponent.lifetime and projectileComponent.lifetime <= 0 then
            projectileEffects.triggerImpact(world, projectile)
            goto continue
        end

        local targetX, targetY
        local targetId = projectileComponent.targetId
        if targetId then
            local target = world:getEntity(targetId)
            if target and target.position and not target.dead and target.health and target.health.current > 0 then
                targetX, targetY = coordinates.getEntityCenter(target)
            else
                projectileComponent.targetId = nil
            end
        end

        if not targetX and projectileComponent.targetX and projectileComponent.targetY then
            targetX = projectileComponent.targetX
            targetY = projectileComponent.targetY
        end

        if not targetX or not targetY then
            projectileEffects.triggerImpact(world, projectile)
            goto continue
        end

        local centerX, centerY = coordinates.getEntityCenter(projectile)
        if not centerX or not centerY then
            goto continue
        end

        local dx = targetX - centerX
        local dy = targetY - centerY
        local ndx, ndy = vector.normalize(dx, dy)

        -- Clamp thunder bolts to land at their target when no enemy is hit.
        -- Otherwise the bolt continues past the cursor because it only expires on lifetime.
        if projectileComponent.spellId == "thunder" then
            local travelThisFrame = (projectileComponent.speed or projectile.movement.speed or 0) * dt
            if travelThisFrame > 0 then
                local distanceToTarget = vector.length(dx, dy)
                if distanceToTarget <= travelThisFrame then
                    projectileEffects.triggerImpact(world, projectile, {
                        position = { x = targetX, y = targetY },
                        directionX = ndx,
                        directionY = ndy,
                    })
                    goto continue
                end
            end
        end

        projectile.movement.vx = ndx
        projectile.movement.vy = ndy
        projectile.movement.speed = projectileComponent.speed or projectile.movement.speed

        projectileComponent.lastDirectionX = ndx
        projectileComponent.lastDirectionY = ndy

        ::continue::
    end
end

return projectileMovementSystem

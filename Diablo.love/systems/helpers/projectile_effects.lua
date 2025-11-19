local coordinates = require("systems.helpers.coordinates")
local soundHelper = require("systems.helpers.sound")

local projectileEffects = {}

---Trigger the impact state for a projectile so it can play its impact effect.
---@param world table
---@param projectile table
---@param opts table|nil
---@return boolean
function projectileEffects.triggerImpact(world, projectile, opts)
    opts = opts or {}

    if not world or not projectile or not projectile.projectile then
        if world and projectile and projectile.id then
            world:removeEntity(projectile.id)
        end
        return false
    end

    local projectileComponent = projectile.projectile
    if projectileComponent.state == "impact" then
        return false
    end

    local centerX, centerY = coordinates.getEntityCenter(projectile)
    local impactPosition = opts.position or { x = centerX, y = centerY }

    projectileComponent.state = "impact"
    projectileComponent.impactDuration = opts.duration or projectileComponent.impactDuration or 0.3
    projectileComponent.impactTimer = projectileComponent.impactDuration
    projectileComponent.impactStartedAt = world.time or 0
    projectileComponent.impactPosition = {
        x = impactPosition.x or centerX or 0,
        y = impactPosition.y or centerY or 0,
    }

    local directionX = opts.directionX or projectileComponent.lastDirectionX
    local directionY = opts.directionY or projectileComponent.lastDirectionY
    if projectile.movement then
        directionX = directionX or projectile.movement.vx
        directionY = directionY or projectile.movement.vy
        projectile.movement.vx = 0
        projectile.movement.vy = 0
        projectile.movement.speed = 0
    end

    projectileComponent.lastDirectionX = directionX or 0
    projectileComponent.lastDirectionY = directionY or 0

    if projectile.inactive then
        projectile.inactive.isInactive = true
    end

    if projectile.position and projectile.size then
        local radius = (projectile.size.w or projectile.size.h or 0) / 2
        projectile.position.x = (projectileComponent.impactPosition.x or 0) - radius
        projectile.position.y = (projectileComponent.impactPosition.y or 0) - radius
    end

    -- Handle sounds for fireball
    if projectileComponent.spellId == "fireball" then
        -- Stop travel sound if it's playing
        if projectile.travelSoundSource then
            projectile.travelSoundSource:stop()
            projectile.travelSoundSource = nil
        end
        -- Play impact sound
        soundHelper.playFireballImpactSound()
    end

    -- Handle sounds for thunder
    if projectileComponent.spellId == "thunder" then
        -- Stop travel sound if it's playing
        if projectile.travelSoundSource then
            projectile.travelSoundSource:stop()
            projectile.travelSoundSource = nil
        end
        -- Play impact sound
        soundHelper.playThunderImpactSound()
    end

    return true
end

return projectileEffects

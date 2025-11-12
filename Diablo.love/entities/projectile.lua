local Projectile = {}
Projectile.__index = Projectile

---Create a projectile entity representing a spell projectile.
---@param opts table|nil
---@return table
function Projectile.new(opts)
    opts = opts or {}

    local createPosition = require("components.position")
    local createSize = require("components.size")
    local createMovement = require("components.movement")
    local createRenderable = require("components.renderable")
    local createProjectile = require("components.projectile")
    local createInactive = require("components.inactive")

    local size = opts.size or 12

    local primaryColor = opts.color or { 1.0, 0.4, 0.1, 1 }
    local secondaryColor = opts.secondaryColor or { 1.0, 0.6, 0.2, 0.9 }
    local coreColor = opts.coreColor or { 1.0, 0.9, 0.7, 1 }

    local entity = {
        id = opts.id or ("projectile_" .. math.random(10000, 99999)),
        position = createPosition({
            x = opts.x or 0,
            y = opts.y or 0,
        }),
        size = createSize({
            w = size,
            h = size,
        }),
        movement = createMovement({
            speed = opts.speed or 300,
            vx = opts.vx or 0,
            vy = opts.vy or 0,
        }),
        renderable = createRenderable({
            kind = opts.renderKind or "circle",
            color = primaryColor,
            secondaryColor = secondaryColor,
            coreColor = coreColor,
            sparkleSeed = opts.sparkleSeed or math.random(),
        }),
        projectile = createProjectile({
            spellId = opts.spellId,
            targetId = opts.targetId,
            targetX = opts.targetX,
            targetY = opts.targetY,
            damage = opts.damage,
            ownerId = opts.ownerId,
            lifetime = opts.lifetime,
            maxLifetime = opts.lifetime,
            speed = opts.speed or 300,
            impactDuration = opts.impactDuration,
            directionX = opts.vx or 0,
            directionY = opts.vy or 0,
        }),
        inactive = createInactive(),
    }

    return setmetatable(entity, Projectile)
end

return Projectile

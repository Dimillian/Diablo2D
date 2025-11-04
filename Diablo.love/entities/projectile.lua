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

    local size = opts.size or 12

    local entity = {
        id = opts.id or "projectile_" .. math.random(10000, 99999),
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
        }),
        renderable = createRenderable({
            kind = "circle",
            color = opts.color or { 1.0, 0.4, 0.1, 1 },
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
        }),
    }

    return setmetatable(entity, Projectile)
end

return Projectile

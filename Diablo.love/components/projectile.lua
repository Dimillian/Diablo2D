local function createProjectileComponent(opts)
    opts = opts or {}

    return {
        spellId = opts.spellId,
        targetId = opts.targetId,
        targetX = opts.targetX,
        targetY = opts.targetY,
        damage = opts.damage,
        ownerId = opts.ownerId,
        lifetime = opts.lifetime or 3.0,
        maxLifetime = opts.maxLifetime or opts.lifetime or 3.0,
        speed = opts.speed,
    }
end

return createProjectileComponent

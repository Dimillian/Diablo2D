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
        state = opts.state or "flying",
        impactDuration = opts.impactDuration or 0.3,
        impactTimer = opts.impactTimer or 0,
        impactStartedAt = opts.impactStartedAt or 0,
        impactPosition = opts.impactPosition,
        lastDirectionX = opts.directionX or 0,
        lastDirectionY = opts.directionY or 0,
        hitEnemies = opts.hitEnemies or {},
    }
end

return createProjectileComponent

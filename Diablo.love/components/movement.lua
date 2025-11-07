local function createMovementComponent(opts)
    opts = opts or {}

    return {
        speed = opts.speed or 140,
        vx = opts.vx or 0,
        vy = opts.vy or 0,
        lookDirection = opts.lookDirection or { x = 0, y = -1 },
        walkAnimationTime = opts.walkAnimationTime or 0,
    }
end

return createMovementComponent

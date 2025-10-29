local function createMovementComponent(opts)
    opts = opts or {}

    return {
        speed = opts.speed or 140,
        vx = opts.vx or 0,
        vy = opts.vy or 0,
    }
end

return createMovementComponent

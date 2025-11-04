local function createLootScatterComponent(opts)
    opts = opts or {}

    return {
        vx = opts.vx or 0,
        vy = opts.vy or 0,
        friction = opts.friction or 8,
        maxDuration = opts.maxDuration or 0.5,
        stopThreshold = opts.stopThreshold or 8,
        elapsed = opts.elapsed or 0,
    }
end

return createLootScatterComponent

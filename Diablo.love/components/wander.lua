local function createWanderComponent(opts)
    opts = opts or {}

    return {
        interval = opts.interval or 1.5,
        elapsed = 0,
        removeOnDeath = true,
    }
end

return createWanderComponent

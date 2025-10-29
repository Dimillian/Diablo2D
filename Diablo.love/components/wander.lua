local function createWanderComponent(opts)
    opts = opts or {}

    return {
        interval = opts.interval or 1.5,
        elapsed = 0,
    }
end

return createWanderComponent

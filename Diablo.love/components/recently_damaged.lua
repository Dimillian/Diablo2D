local function createRecentlyDamagedComponent(opts)
    opts = opts or {}

    return {
        timer = opts.timer or 2.0,
    }
end

return createRecentlyDamagedComponent

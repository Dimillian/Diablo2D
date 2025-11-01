local function createRecentlyDamagedComponent(opts)
    opts = opts or {}

    local maxTimer = opts.maxTimer or 1.5

    return {
        timer = opts.timer or maxTimer,
        maxTimer = maxTimer,
    }
end

return createRecentlyDamagedComponent

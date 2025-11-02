local function createKnockbackComponent(opts)
    opts = opts or {}

    local maxTimer = opts.maxTimer or 0.15

    return {
        x = opts.x or 0,
        y = opts.y or 0,
        timer = opts.timer or maxTimer,
        maxTimer = maxTimer,
        strength = opts.strength or 20,
    }
end

return createKnockbackComponent

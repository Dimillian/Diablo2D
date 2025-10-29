local function createHealthComponent(opts)
    opts = opts or {}

    local max = opts.max or 50

    return {
        current = opts.current or max,
        max = max,
    }
end

return createHealthComponent

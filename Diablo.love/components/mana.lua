local function createManaComponent(opts)
    opts = opts or {}

    local max = opts.max or 25

    return {
        current = opts.current or max,
        max = max,
    }
end

return createManaComponent

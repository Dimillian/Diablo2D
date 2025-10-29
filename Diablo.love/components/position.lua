local function createPositionComponent(opts)
    opts = opts or {}

    return {
        x = opts.x or 0,
        y = opts.y or 0,
    }
end

return createPositionComponent

local function createSizeComponent(opts)
    opts = opts or {}

    return {
        w = opts.w or opts.width or 16,
        h = opts.h or opts.height or 24,
    }
end

return createSizeComponent

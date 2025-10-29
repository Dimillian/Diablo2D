local function createRenderableComponent(opts)
    opts = opts or {}

    return {
        kind = opts.kind or "rect",
        width = opts.width or 16,
        height = opts.height or 24,
        color = opts.color or { 1, 1, 1, 1 },
    }
end

return createRenderableComponent

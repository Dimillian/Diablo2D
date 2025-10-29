local function createRenderableComponent(opts)
    opts = opts or {}

    return {
        kind = opts.kind or "rect",
        color = opts.color or { 1, 1, 1, 1 },
    }
end

return createRenderableComponent

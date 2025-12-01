local function createRenderableComponent(opts)
    opts = opts or {}

    return {
        kind = opts.kind or "rect",
        color = opts.color or { 1, 1, 1, 1 },
        secondaryColor = opts.secondaryColor,
        coreColor = opts.coreColor,
        sparkleSeed = opts.sparkleSeed,
        spriteSheetPath = opts.spriteSheetPath,
        spritePrefix = opts.spritePrefix,
        animationState = opts.animationState or "idle",
        scaleMultiplier = opts.scaleMultiplier or 1,
    }
end

return createRenderableComponent

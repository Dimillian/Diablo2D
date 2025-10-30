local function createChaseComponent(opts)
    opts = opts or {}

    return {
        targetId = opts.targetId or nil, -- ID of the entity being chased
    }
end

return createChaseComponent

local function createFoeTag(opts)
    opts = opts or {}

    return {
        type = opts.type,
        packId = opts.packId,
        packAggro = opts.packAggro or false,
    }
end

return createFoeTag

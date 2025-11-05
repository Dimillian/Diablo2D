local function createFoeTag(opts)
    opts = opts or {}
    local typeId = opts.typeId or opts.type

    return {
        type = opts.type or typeId,
        typeId = typeId,
        packId = opts.packId,
        packAggro = opts.packAggro or false,
    }
end

return createFoeTag

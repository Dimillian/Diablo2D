local function createFoeTag(opts)
    opts = opts or {}

    return {
        typeId = opts.typeId,
    }
end

return createFoeTag

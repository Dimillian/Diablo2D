local function createStructureComponent(opts)
    opts = opts or {}

    return {
        id = opts.id,
        structureId = opts.structureId,
        lootable = opts.lootable or false,
        persistent = true,
    }
end

return createStructureComponent

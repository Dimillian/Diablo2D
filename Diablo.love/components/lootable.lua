local function createLootableComponent(opts)
    opts = opts or {}

    return {
        item = opts.item,
        pickupRadius = opts.pickupRadius or 40,
        source = opts.source or nil,
        despawnTimer = opts.despawnTimer or nil,
    }
end

return createLootableComponent

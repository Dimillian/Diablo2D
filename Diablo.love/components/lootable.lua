local function createLootableComponent(opts)
    opts = opts or {}

    return {
        item = opts.item,
        pickupRadius = opts.pickupRadius,
        source = opts.source,
        despawnTimer = opts.despawnTimer,
        maxDespawnTimer = opts.maxDespawnTimer or opts.despawnTimer,
    }
end

return createLootableComponent

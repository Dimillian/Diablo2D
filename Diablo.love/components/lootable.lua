local function createLootableComponent(opts)
    opts = opts or {}

    return {
        item = opts.item,
        gold = opts.gold,
        pickupRadius = opts.pickupRadius,
        source = opts.source,
        despawnTimer = opts.despawnTimer,
        maxDespawnTimer = opts.maxDespawnTimer or opts.despawnTimer,
        iconPath = opts.iconPath,
        goldIcon = opts.goldIcon,
    }
end

return createLootableComponent

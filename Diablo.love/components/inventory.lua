local function createInventoryComponent()
    opts = opts or {}

    return {
        items = opts.items or {},
        capacity = 80,
        gold = 0,
    }
end

return createInventoryComponent

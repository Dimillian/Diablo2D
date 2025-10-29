local function createInventoryComponent(opts)
    opts = opts or {}

    return {
        items = opts.items or {},
        capacity = opts.capacity or 30,
    }
end

return createInventoryComponent

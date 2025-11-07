local ComponentDefaults = require("data.component_defaults")

local function createInventoryComponent()
    return {
        items = {},
        capacity = ComponentDefaults.INVENTORY_CAPACITY,
        gold = 0,
    }
end

return createInventoryComponent

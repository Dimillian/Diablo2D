local equipmentSlots = { "weapon", "head", "chest", "feet", "gloves", "ringLeft", "ringRight", "amulet" }

local function createEquipmentComponent(opts)
    opts = opts or {}

    local equipment = {}
    for _, slot in ipairs(equipmentSlots) do
        equipment[slot] = opts[slot] or nil
    end

    return equipment
end

return createEquipmentComponent

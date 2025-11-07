local equipmentSlots = { "weapon", "head", "chest", "feet", "gloves", "ringLeft", "ringRight", "amulet" }

local function createEquipmentComponent()
    local equipment = {}
    for _, slot in ipairs(equipmentSlots) do
        equipment[slot] = nil
    end

    return equipment
end

return createEquipmentComponent

local Stats = require("modules.stats")

local equipmentSlots = {
    { id = "weapon", label = "Weapon" },
    { id = "head", label = "Head" },
    { id = "chest", label = "Chest" },
    { id = "gloves", label = "Gloves" },
    { id = "feet", label = "Boots" },
    { id = "ringLeft", label = "Ring (L)" },
    { id = "ringRight", label = "Ring (R)" },
    { id = "amulet", label = "Amulet" },
}

local EquipmentHelper = {}

function EquipmentHelper.slots()
    return equipmentSlots
end

function EquipmentHelper.ensure(player)
    if not player then
        return nil, nil
    end

    player.inventory = player.inventory or { items = {} }
    player.inventory.items = player.inventory.items or {}
    player.inventory.gold = player.inventory.gold or 0

    player.equipment = player.equipment or {}
    for _, slot in ipairs(equipmentSlots) do
        if player.equipment[slot.id] == nil then
            player.equipment[slot.id] = nil
        end
    end

    player.baseStats = player.baseStats or Stats.newRecord()

    return player.inventory, player.equipment
end

function EquipmentHelper.equip(player, item)
    if not player or not item or not item.slot then
        return
    end

    local inventory, equipment = EquipmentHelper.ensure(player)
    local inventoryItems = inventory and inventory.items or nil

    local slotId = item.slot

    -- Handle ring auto-assignment: rings can go in either ringLeft or ringRight
    if slotId == "ring" then
        -- Prefer ringLeft if empty, otherwise ringRight
        if not equipment.ringLeft then
            slotId = "ringLeft"
        elseif not equipment.ringRight then
            slotId = "ringRight"
        else
            -- Both slots full, replace ringLeft (player can unequip/re-equip to swap)
            slotId = "ringLeft"
        end
    end

    local previous = equipment[slotId]
    equipment[slotId] = item

    -- Remove item from inventory if it exists there (prevents duplication)
    if inventoryItems then
        for i = #inventoryItems, 1, -1 do
            if inventoryItems[i] == item then
                table.remove(inventoryItems, i)
                break
            end
        end
    end

    -- Add previously equipped item back to inventory
    if previous and inventoryItems then
        EquipmentHelper.addToInventory(player, previous)
    end
end

function EquipmentHelper.unequip(player, slotId)
    if not player or not slotId then
        return
    end

    local _, equipment = EquipmentHelper.ensure(player)
    local item = equipment[slotId]
    if item then
        EquipmentHelper.addToInventory(player, item)
        equipment[slotId] = nil
    end
end

function EquipmentHelper.removeFromInventory(player, index)
    if not player or not index then
        return
    end

    local inventory = EquipmentHelper.ensure(player)
    if not inventory or not inventory.items then
        return
    end

    table.remove(inventory.items, index)
end

---Add item to inventory at the beginning, trimming excess items if over limit
---@param player table Player entity
---@param item table Item to add
---@param maxSlots number|nil Maximum inventory slots (default: 48)
function EquipmentHelper.addToInventory(player, item, maxSlots)
    if not player or not item then
        return
    end

    local inventory = EquipmentHelper.ensure(player)
    if not inventory or not inventory.items then
        return
    end

    maxSlots = maxSlots or 48 -- Default: 8 cols * 6 rows

    -- Insert at beginning (position 1)
    table.insert(inventory.items, 1, item)

    -- Trim excess items from the end if over limit
    while #inventory.items > maxSlots do
        table.remove(inventory.items)
    end
end

function EquipmentHelper.computeTotalStats(player)
    EquipmentHelper.ensure(player)

    local total = Stats.clone(player.baseStats)

    for _, slot in ipairs(equipmentSlots) do
        local item = player.equipment[slot.id]
        if item and item.stats then
            Stats.add(total, item.stats)
        end
    end

    return total
end

---Get equipped items for tooltip comparison based on an item's slot
---@param player table Player entity
---@param itemSlot string The slot ID of the item to compare (e.g., "weapon", "ring", "head")
---@return table Array of equipped items to compare against
function EquipmentHelper.getEquippedItemsForComparison(player, itemSlot)
    if not player or not itemSlot then
        return {}
    end

    local _, equipment = EquipmentHelper.ensure(player)
    if not equipment then
        return {}
    end

    local equippedItems = {}

    -- Handle ring slots: compare against both ringLeft and ringRight
    if itemSlot == "ring" then
        if equipment.ringLeft then
            equippedItems[#equippedItems + 1] = equipment.ringLeft
        end
        if equipment.ringRight then
            equippedItems[#equippedItems + 1] = equipment.ringRight
        end
    else
        -- For other slots, get the equipped item if it exists
        local equippedItem = equipment[itemSlot]
        if equippedItem then
            equippedItems[#equippedItems + 1] = equippedItem
        end
    end

    return equippedItems
end

return EquipmentHelper

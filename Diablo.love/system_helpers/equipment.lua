local Stats = require("modules.stats")

local equipmentSlots = {
    { id = "weapon", label = "Weapon" },
    { id = "head", label = "Head" },
    { id = "chest", label = "Chest" },
    { id = "feet", label = "Boots" },
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
    local previous = equipment[slotId]
    equipment[slotId] = item

    if previous and inventoryItems then
        table.insert(inventoryItems, previous)
    end
end

function EquipmentHelper.unequip(player, slotId)
    if not player or not slotId then
        return
    end

    local inventory, equipment = EquipmentHelper.ensure(player)
    local item = equipment[slotId]
    if item and inventory and inventory.items then
        table.insert(inventory.items, item)
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

return EquipmentHelper

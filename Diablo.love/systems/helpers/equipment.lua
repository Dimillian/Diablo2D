local Stats = require("modules.stats")
local StatsDerivation = require("modules.stats_derivation")

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

function EquipmentHelper.equip(player, item)
    if not player or not item or not item.slot then
        return
    end

    local inventory = player.inventory
    local equipment = player.equipment
    local inventoryItems = inventory.items

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

    local equipment = player.equipment
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

    local inventory = player.inventory
    if not inventory.items then
        return
    end

    table.remove(inventory.items, index)
end

---Add item to inventory at the beginning, trimming excess items if over limit
---@param player table Player entity
---@param item table Item to add
---@param maxSlots number|nil Maximum inventory slots (uses inventory.capacity if not provided)
function EquipmentHelper.addToInventory(player, item, maxSlots)
    if not player or not item then
        return
    end

    local inventory = player.inventory
    if not inventory.items then
        return
    end

    maxSlots = maxSlots or inventory.capacity

    -- Insert at beginning (position 1)
    table.insert(inventory.items, 1, item)

    -- Trim excess items from the end if over limit
    while #inventory.items > maxSlots do
        table.remove(inventory.items)
    end
end

function EquipmentHelper.computeTotalStats(player)
    -- Step 1: Derive base stats from primary attributes
    local derivedStats = StatsDerivation.deriveStatsFromAttributes(player.baseStats)

    -- Step 2: Start with derived stats as base
    local total = Stats.clone(derivedStats)

    -- Step 3: Add direct stats from baseStats (defense, moveSpeed, etc.)
    if player.baseStats then
        Stats.add(total, {
            defense = player.baseStats.defense,
            moveSpeed = player.baseStats.moveSpeed,
            dodgeChance = player.baseStats.dodgeChance,
            goldFind = player.baseStats.goldFind,
            lifeSteal = player.baseStats.lifeSteal,
            attackSpeed = player.baseStats.attackSpeed,
            resistAll = player.baseStats.resistAll,
            manaRegen = player.baseStats.manaRegen,
        })
    end

    -- Step 4: Add equipment bonuses on top of derived stats
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

    local equipment = player.equipment
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

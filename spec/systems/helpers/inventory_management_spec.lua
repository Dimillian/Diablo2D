local helper = require("spec.spec_helper")

-- luacheck: globals describe it before_each assert

local EquipmentHelper = require("systems.helpers.equipment")
local ComponentDefaults = require("data.component_defaults")

describe("EquipmentHelper.addToInventory", function()
    local player

    before_each(function()
        player = helper.buildEntity({
            id = "player_1",
            inventory = {
                items = {},
                capacity = ComponentDefaults.INVENTORY_CAPACITY,
                gold = 0,
            },
        })
    end)

    it("returns false when player is nil", function()
        local item = { id = "item_1", name = "Test Item" }
        local result = EquipmentHelper.addToInventory(nil, item)
        assert.is_false(result)
    end)

    it("returns false when item is nil", function()
        local result = EquipmentHelper.addToInventory(player, nil)
        assert.is_false(result)
    end)

    it("adds item to empty inventory and returns true", function()
        local item = { id = "item_1", name = "Test Item" }
        local result = EquipmentHelper.addToInventory(player, item)

        assert.is_true(result)
        assert.equal(1, #player.inventory.items)
        assert.equal(item, player.inventory.items[1])
    end)

    it("appends items in insertion order (newest at end)", function()
        local item1 = { id = "item_1", name = "First Item" }
        local item2 = { id = "item_2", name = "Second Item" }
        local item3 = { id = "item_3", name = "Third Item" }

        EquipmentHelper.addToInventory(player, item1)
        EquipmentHelper.addToInventory(player, item2)
        EquipmentHelper.addToInventory(player, item3)

        assert.equal(3, #player.inventory.items)
        assert.equal(item1, player.inventory.items[1])
        assert.equal(item2, player.inventory.items[2])
        assert.equal(item3, player.inventory.items[3])
    end)

    it("returns false when inventory is full", function()
        player.inventory.capacity = 2
        local item1 = { id = "item_1", name = "First Item" }
        local item2 = { id = "item_2", name = "Second Item" }
        local item3 = { id = "item_3", name = "Third Item" }

        assert.is_true(EquipmentHelper.addToInventory(player, item1))
        assert.is_true(EquipmentHelper.addToInventory(player, item2))
        assert.is_false(EquipmentHelper.addToInventory(player, item3))

        assert.equal(2, #player.inventory.items)
        assert.equal(item1, player.inventory.items[1])
        assert.equal(item2, player.inventory.items[2])
    end)

    it("respects custom maxSlots parameter", function()
        local item1 = { id = "item_1", name = "First Item" }
        local item2 = { id = "item_2", name = "Second Item" }
        local item3 = { id = "item_3", name = "Third Item" }

        assert.is_true(EquipmentHelper.addToInventory(player, item1, 2))
        assert.is_true(EquipmentHelper.addToInventory(player, item2, 2))
        assert.is_false(EquipmentHelper.addToInventory(player, item3, 2))

        assert.equal(2, #player.inventory.items)
    end)
end)

describe("EquipmentHelper.equip", function()
    local player

    before_each(function()
        player = helper.buildEntity({
            id = "player_1",
            inventory = {
                items = {},
                capacity = ComponentDefaults.INVENTORY_CAPACITY,
                gold = 0,
            },
            equipment = {},
        })
    end)

    it("returns false when player is nil", function()
        local item = { id = "item_1", slot = "weapon", name = "Test Weapon" }
        local result = EquipmentHelper.equip(nil, item)
        assert.is_false(result)
    end)

    it("returns false when item is nil", function()
        local result = EquipmentHelper.equip(player, nil)
        assert.is_false(result)
    end)

    it("returns false when item has no slot", function()
        local item = { id = "item_1", name = "Test Item" }
        local result = EquipmentHelper.equip(player, item)
        assert.is_false(result)
    end)

    it("equips item to empty slot and returns true", function()
        local item = { id = "item_1", slot = "weapon", name = "Test Weapon" }
        local result = EquipmentHelper.equip(player, item)

        assert.is_true(result)
        assert.equal(item, player.equipment.weapon)
    end)

    it("stores previous item in inventory when equipping new item", function()
        local previousItem = { id = "item_1", slot = "weapon", name = "Old Weapon" }
        local newItem = { id = "item_2", slot = "weapon", name = "New Weapon" }

        player.equipment.weapon = previousItem
        local result = EquipmentHelper.equip(player, newItem)

        assert.is_true(result)
        assert.equal(newItem, player.equipment.weapon)
        assert.equal(1, #player.inventory.items)
        assert.equal(previousItem, player.inventory.items[1])
    end)

    it("returns false when inventory is full and cannot store previous item", function()
        local previousItem = { id = "item_1", slot = "weapon", name = "Old Weapon" }
        local newItem = { id = "item_2", slot = "weapon", name = "New Weapon" }

        player.equipment.weapon = previousItem
        player.inventory.capacity = 2
        -- Fill inventory
        EquipmentHelper.addToInventory(player, { id = "fill_1" })
        EquipmentHelper.addToInventory(player, { id = "fill_2" })

        local result = EquipmentHelper.equip(player, newItem)

        assert.is_false(result)
        -- Previous item should still be equipped
        assert.equal(previousItem, player.equipment.weapon)
        -- New item should not be equipped
        assert.not_equal(newItem, player.equipment.weapon)
        -- Inventory should still be full
        assert.equal(2, #player.inventory.items)
    end)

    it("removes item from inventory when equipping", function()
        local item = { id = "item_1", slot = "weapon", name = "Test Weapon" }
        EquipmentHelper.addToInventory(player, item)

        local result = EquipmentHelper.equip(player, item)

        assert.is_true(result)
        assert.equal(item, player.equipment.weapon)
        assert.equal(0, #player.inventory.items)
    end)

    it("handles ring auto-assignment to ringLeft when empty", function()
        local ring = { id = "ring_1", slot = "ring", name = "Test Ring" }
        local result = EquipmentHelper.equip(player, ring)

        assert.is_true(result)
        assert.equal(ring, player.equipment.ringLeft)
        assert.is_nil(player.equipment.ringRight)
    end)

    it("handles ring auto-assignment to ringRight when ringLeft is full", function()
        local ring1 = { id = "ring_1", slot = "ring", name = "First Ring" }
        local ring2 = { id = "ring_2", slot = "ring", name = "Second Ring" }

        EquipmentHelper.equip(player, ring1)
        local result = EquipmentHelper.equip(player, ring2)

        assert.is_true(result)
        assert.equal(ring1, player.equipment.ringLeft)
        assert.equal(ring2, player.equipment.ringRight)
    end)
end)

describe("EquipmentHelper.unequip", function()
    local player

    before_each(function()
        player = helper.buildEntity({
            id = "player_1",
            inventory = {
                items = {},
                capacity = ComponentDefaults.INVENTORY_CAPACITY,
                gold = 0,
            },
            equipment = {},
        })
    end)

    it("returns false when player is nil", function()
        local result = EquipmentHelper.unequip(nil, "weapon")
        assert.is_false(result)
    end)

    it("returns false when slotId is nil", function()
        local result = EquipmentHelper.unequip(player, nil)
        assert.is_false(result)
    end)

    it("returns false when slot is empty", function()
        local result = EquipmentHelper.unequip(player, "weapon")
        assert.is_false(result)
    end)

    it("unequips item and adds to inventory, returns true", function()
        local item = { id = "item_1", slot = "weapon", name = "Test Weapon" }
        player.equipment.weapon = item

        local result = EquipmentHelper.unequip(player, "weapon")

        assert.is_true(result)
        assert.is_nil(player.equipment.weapon)
        assert.equal(1, #player.inventory.items)
        assert.equal(item, player.inventory.items[1])
    end)

    it("returns false when inventory is full and cannot unequip", function()
        local item = { id = "item_1", slot = "weapon", name = "Test Weapon" }
        player.equipment.weapon = item
        player.inventory.capacity = 2
        -- Fill inventory
        EquipmentHelper.addToInventory(player, { id = "fill_1" })
        EquipmentHelper.addToInventory(player, { id = "fill_2" })

        local result = EquipmentHelper.unequip(player, "weapon")

        assert.is_false(result)
        -- Item should still be equipped
        assert.equal(item, player.equipment.weapon)
        -- Inventory should still be full
        assert.equal(2, #player.inventory.items)
    end)
end)

describe("EquipmentHelper.removeFromInventory", function()
    local player

    before_each(function()
        player = helper.buildEntity({
            id = "player_1",
            inventory = {
                items = {},
                capacity = ComponentDefaults.INVENTORY_CAPACITY,
                gold = 0,
            },
        })
    end)

    it("removes item at specified index", function()
        local item1 = { id = "item_1", name = "First Item" }
        local item2 = { id = "item_2", name = "Second Item" }
        local item3 = { id = "item_3", name = "Third Item" }

        EquipmentHelper.addToInventory(player, item1)
        EquipmentHelper.addToInventory(player, item2)
        EquipmentHelper.addToInventory(player, item3)

        EquipmentHelper.removeFromInventory(player, 2)

        assert.equal(2, #player.inventory.items)
        assert.equal(item1, player.inventory.items[1])
        assert.equal(item3, player.inventory.items[2])
    end)

    it("handles removing first item", function()
        local item1 = { id = "item_1", name = "First Item" }
        local item2 = { id = "item_2", name = "Second Item" }

        EquipmentHelper.addToInventory(player, item1)
        EquipmentHelper.addToInventory(player, item2)

        EquipmentHelper.removeFromInventory(player, 1)

        assert.equal(1, #player.inventory.items)
        assert.equal(item2, player.inventory.items[1])
    end)

    it("handles removing last item", function()
        local item1 = { id = "item_1", name = "First Item" }
        local item2 = { id = "item_2", name = "Second Item" }

        EquipmentHelper.addToInventory(player, item1)
        EquipmentHelper.addToInventory(player, item2)

        EquipmentHelper.removeFromInventory(player, 2)

        assert.equal(1, #player.inventory.items)
        assert.equal(item1, player.inventory.items[1])
    end)
end)

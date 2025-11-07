local helper = require("spec.spec_helper")

-- luacheck: globals describe it before_each assert

local EquipmentHelper = require("systems.helpers.equipment")

describe("EquipmentHelper.getEquippedItemsForComparison", function()
    local player

    before_each(function()
        player = helper.buildEntity({
            id = "player_1",
            equipment = {},
            inventory = { items = {}, gold = 0 },
            baseStats = {},
        })
    end)

    it("returns empty array when player is nil", function()
        local result = EquipmentHelper.getEquippedItemsForComparison(nil, "weapon")
        assert.same({}, result)
    end)

    it("returns empty array when itemSlot is nil", function()
        local result = EquipmentHelper.getEquippedItemsForComparison(player, nil)
        assert.same({}, result)
    end)

    it("returns empty array when slot has no equipped item", function()
        local result = EquipmentHelper.getEquippedItemsForComparison(player, "weapon")
        assert.same({}, result)
    end)

    it("returns the equipped item for a weapon slot", function()
        local weapon = { id = "weapon_1", slot = "weapon", name = "Iron Sword" }
        player.equipment.weapon = weapon

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "weapon")

        assert.equal(1, #result)
        assert.equal(weapon, result[1])
    end)

    it("returns the equipped item for a head slot", function()
        local helmet = { id = "helmet_1", slot = "head", name = "Iron Helmet" }
        player.equipment.head = helmet

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "head")

        assert.equal(1, #result)
        assert.equal(helmet, result[1])
    end)

    it("returns the equipped item for a chest slot", function()
        local chest = { id = "chest_1", slot = "chest", name = "Iron Chestplate" }
        player.equipment.chest = chest

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "chest")

        assert.equal(1, #result)
        assert.equal(chest, result[1])
    end)

    it("returns the equipped item for a gloves slot", function()
        local gloves = { id = "gloves_1", slot = "gloves", name = "Iron Gauntlets" }
        player.equipment.gloves = gloves

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "gloves")

        assert.equal(1, #result)
        assert.equal(gloves, result[1])
    end)

    it("returns the equipped item for a feet slot", function()
        local boots = { id = "boots_1", slot = "feet", name = "Iron Boots" }
        player.equipment.feet = boots

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "feet")

        assert.equal(1, #result)
        assert.equal(boots, result[1])
    end)

    it("returns the equipped item for an amulet slot", function()
        local amulet = { id = "amulet_1", slot = "amulet", name = "Iron Amulet" }
        player.equipment.amulet = amulet

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "amulet")

        assert.equal(1, #result)
        assert.equal(amulet, result[1])
    end)

    it("returns both rings when itemSlot is 'ring' and both are equipped", function()
        local ringLeft = { id = "ring_1", slot = "ring", name = "Ring of Power" }
        local ringRight = { id = "ring_2", slot = "ring", name = "Ring of Wisdom" }
        player.equipment.ringLeft = ringLeft
        player.equipment.ringRight = ringRight

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "ring")

        assert.equal(2, #result)
        assert.equal(ringLeft, result[1])
        assert.equal(ringRight, result[2])
    end)

    it("returns only ringLeft when only ringLeft is equipped for ring slot", function()
        local ringLeft = { id = "ring_1", slot = "ring", name = "Ring of Power" }
        player.equipment.ringLeft = ringLeft
        player.equipment.ringRight = nil

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "ring")

        assert.equal(1, #result)
        assert.equal(ringLeft, result[1])
    end)

    it("returns only ringRight when only ringRight is equipped for ring slot", function()
        local ringRight = { id = "ring_2", slot = "ring", name = "Ring of Wisdom" }
        player.equipment.ringLeft = nil
        player.equipment.ringRight = ringRight

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "ring")

        assert.equal(1, #result)
        assert.equal(ringRight, result[1])
    end)

    it("returns empty array when no rings are equipped for ring slot", function()
        player.equipment.ringLeft = nil
        player.equipment.ringRight = nil

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "ring")

        assert.same({}, result)
    end)

    it("handles player without equipment table initialized", function()
        player.equipment = nil
        EquipmentHelper.ensure(player) -- This initializes equipment

        local result = EquipmentHelper.getEquippedItemsForComparison(player, "weapon")

        assert.same({}, result)
        assert.is_not_nil(player.equipment) -- ensure() should have initialized it
    end)
end)

describe("EquipmentHelper.computeTotalStats", function()
    local player

    before_each(function()
        player = helper.buildEntity({
            id = "player_1",
            equipment = {},
            inventory = { items = {}, gold = 0 },
            baseStats = {
                strength = 10,
                dexterity = 20,
                vitality = 50,
                intelligence = 25,
                defense = 2,
                moveSpeed = 0,
            },
        })
    end)

    it("derives stats from primary attributes", function()
        local total = EquipmentHelper.computeTotalStats(player)

        -- 10 strength = 2 damage (10 * 0.2)
        assert.equal(2, total.damageMin)
        assert.equal(2, total.damageMax)
        -- 20 dexterity = 0.004 crit chance (20 * 0.0002)
        assert.equal(0.004, total.critChance)
        -- 50 vitality = 50 health
        assert.equal(50, total.health)
        -- 25 intelligence = 25 mana
        assert.equal(25, total.mana)
        -- Direct stats preserved
        assert.equal(2, total.defense)
    end)

    it("adds equipment bonuses to derived stats", function()
        player.equipment.weapon = {
            slot = "weapon",
            stats = {
                damageMin = 5,
                damageMax = 8,
            },
        }

        local total = EquipmentHelper.computeTotalStats(player)

        -- Base damage (2) + equipment (5-8) = 7-10
        assert.equal(7, total.damageMin)
        assert.equal(10, total.damageMax)
    end)

    it("combines multiple equipment pieces", function()
        player.equipment.weapon = {
            slot = "weapon",
            stats = {
                damageMin = 3,
                damageMax = 5,
            },
        }
        player.equipment.head = {
            slot = "head",
            stats = {
                health = 20,
                defense = 5,
            },
        }

        local total = EquipmentHelper.computeTotalStats(player)

        -- Base damage (2) + weapon (3-5) = 5-7
        assert.equal(5, total.damageMin)
        assert.equal(7, total.damageMax)
        -- Base health (50) + helmet (20) = 70
        assert.equal(70, total.health)
        -- Base defense (2) + helmet (5) = 7
        assert.equal(7, total.defense)
    end)
end)

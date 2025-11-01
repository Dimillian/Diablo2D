local ItemGenerator = require("items.generator")
local EquipmentHelper = require("system_helpers.equipment")

local starterGearSystem = {}

---Generate and equip starter gear for a new game.
---Runs once per world scene initialization.
function starterGearSystem.update(world, _dt)
    -- Check if starter gear has already been generated
    if world.starterGearGenerated then
        return
    end

    local player = world:getPlayer()
    if not player then
        return
    end

    -- Ensure player has inventory and equipment components
    EquipmentHelper.ensure(player)

    -- Generate starter gear: weapon + 4 armor pieces (helmet, chest, gloves, boots)
    local starterWeapon = ItemGenerator.roll({
        rarity = "common",
        allowedTypes = { "sword", "axe" },
        source = "starter",
    })

    local starterHelmet = ItemGenerator.roll({
        rarity = "common",
        itemType = "helmet",
        source = "starter",
    })

    local starterChest = ItemGenerator.roll({
        rarity = "common",
        itemType = "chest",
        source = "starter",
    })

    local starterGloves = ItemGenerator.roll({
        rarity = "common",
        itemType = "gloves",
        source = "starter",
    })

    local starterBoots = ItemGenerator.roll({
        rarity = "common",
        itemType = "boots",
        source = "starter",
    })

    -- Auto-equip all starter gear directly (items will be added to inventory when unequipped)
    EquipmentHelper.equip(player, starterWeapon)
    EquipmentHelper.equip(player, starterHelmet)
    EquipmentHelper.equip(player, starterChest)
    EquipmentHelper.equip(player, starterGloves)
    EquipmentHelper.equip(player, starterBoots)

    -- Mark as generated to prevent re-running
    world.starterGearGenerated = true

    -- Stats will be recomputed automatically on the next update cycle by applyStatsSystem
end

return starterGearSystem

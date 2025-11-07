local ItemGenerator = require("items.generator")
local EquipmentHelper = require("systems.helpers.equipment")

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

    if not player.skills then
        local createSkills = require("components.skills")
        player.skills = createSkills()
    end

    if not player.skills.equipped[1] then
        player.skills.equipped[1] = "fireball"
    end

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

    EquipmentHelper.equip(player, starterWeapon)
    EquipmentHelper.equip(player, starterHelmet)
    EquipmentHelper.equip(player, starterChest)
    EquipmentHelper.equip(player, starterGloves)
    EquipmentHelper.equip(player, starterBoots)

    world.starterGearGenerated = true
end

return starterGearSystem

local ItemGenerator = require("items.generator")
local ItemData = require("data.items")
local LootEntity = require("entities.loot")
local Tooltips = require("systems.helpers.tooltips")

local lootDropSystem = {}

local function buildLootRenderable(item)
    local color = Tooltips.getRarityColor(item and item.rarity) or Tooltips.rarityColors.common
    local alpha = color[4] or 1
    return {
        kind = "loot",
        color = { color[1], color[2], color[3], alpha },
    }
end

local function hasPotionCapacity(potions, potionTypeId)
    if not potions then
        return true
    end

    local countKey = potionTypeId == "health_potion" and "healthPotionCount" or "manaPotionCount"
    local maxKey = potionTypeId == "health_potion" and "maxHealthPotionCount" or "maxManaPotionCount"

    local current = potions[countKey] or 0
    local max = potions[maxKey]

    if not max then
        return true
    end

    return current < max
end

local function createPotionItem(potionTypeId)
    local potionType = ItemData.types[potionTypeId]
    if not potionType then
        return nil
    end

    return {
        id = "potion_" .. math.random(100000, 999999),
        name = potionType.label,
        type = potionType.id,
        slot = potionType.slot,
        rarity = "common",
        rarityLabel = "Common",
        stats = {},
        consumable = potionType.consumable,
        restoreHealth = potionType.restoreHealth,
        restoreMana = potionType.restoreMana,
        spritePath = string.format("resources/icons/%s.png", potionTypeId),
        source = "monster",
    }
end

local function spawnPotionLoot(world, event, basePosition)
    local potionDropChance = 0.15
    if math.random() >= potionDropChance then
        return
    end

    local player = world.getPlayer and world:getPlayer()
    local potions = player and player.potions

    local availablePotionTypes = {}
    if hasPotionCapacity(potions, "health_potion") then
        table.insert(availablePotionTypes, "health_potion")
    end
    if hasPotionCapacity(potions, "mana_potion") then
        table.insert(availablePotionTypes, "mana_potion")
    end

    if #availablePotionTypes == 0 then
        return
    end

    local potionTypeId = availablePotionTypes[math.random(#availablePotionTypes)]
    local potionItem = createPotionItem(potionTypeId)

    if not potionItem then
        return
    end

    local potionColor = potionTypeId == "health_potion" and { 0.8, 0.2, 0.2, 1 } or { 0.2, 0.4, 0.9, 1 }
    local width = 26
    local height = 26
    local offsetX = (math.random() < 0.5) and -32 or 32

    local potionLoot = LootEntity.new({
        x = basePosition.x - width / 2 + offsetX,
        y = basePosition.y - height / 2,
        width = width,
        height = height,
        renderable = {
            kind = "loot",
            color = potionColor,
        },
        lootable = {
            item = potionItem,
            pickupRadius = 128,
            source = event.lootSource or event.targetId,
            despawnTimer = 45,
            maxDespawnTimer = 45,
        },
    })

    world:addEntity(potionLoot)
end

local function spawnLoot(world, event)
    if not event.position then
        return
    end

    local item = ItemGenerator.roll({
        source = "loot",
    })

    if not item then
        return
    end

    item.source = item.source or "monster"

    local width = 26
    local height = 26

    local loot = LootEntity.new({
        x = event.position.x - width / 2,
        y = event.position.y - height / 2,
        width = width,
        height = height,
        renderable = buildLootRenderable(item),
        lootable = {
            item = item,
            pickupRadius = 128,
            source = event.lootSource or event.targetId,
            despawnTimer = 45,
            maxDespawnTimer = 45,
        },
    })

    world:addEntity(loot)

    spawnPotionLoot(world, event, event.position)
end

function lootDropSystem.update(world, _dt)
    local events = world.pendingCombatEvents
    if not events or #events == 0 then
        return
    end

    for _, event in ipairs(events) do
        if event.type == "death" and not event._spawnedLoot then
            spawnLoot(world, event)
            event._spawnedLoot = true
        end
    end
end

return lootDropSystem

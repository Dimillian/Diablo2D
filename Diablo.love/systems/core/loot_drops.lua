local ItemGenerator = require("items.generator")
local ItemData = require("data.items")
local LootEntity = require("entities.loot")
local Tooltips = require("systems.helpers.tooltips")
local FoeTypes = require("data.foe_types")

local lootDropSystem = {}
local TWO_PI = math.pi * 2
local ITEM_DROP_CHANCE = 0.7

local function buildLootRenderable(item)
    local color = Tooltips.getRarityColor(item and item.rarity) or Tooltips.rarityColors.common
    local alpha = color[4] or 1
    return {
        kind = "loot",
        color = { color[1], color[2], color[3], alpha },
    }
end

local function rollScatterData(opts)
    opts = opts or {}

    local angle = math.random() * TWO_PI
    local minSpeed = opts.minSpeed or 90
    local maxSpeed = opts.maxSpeed or 160
    if maxSpeed < minSpeed then
        maxSpeed = minSpeed
    end

    local speed = minSpeed + (maxSpeed - minSpeed) * math.random()

    local offsetMin = opts.offsetDistanceMin or 6
    local offsetMax = opts.offsetDistanceMax or 18
    if offsetMax < offsetMin then
        offsetMax = offsetMin
    end
    local offsetDistance = offsetMin + (offsetMax - offsetMin) * math.random()

    local directionX = math.cos(angle)
    local directionY = math.sin(angle)

    return {
        vx = directionX * speed,
        vy = directionY * speed,
        offsetX = directionX * offsetDistance,
        offsetY = directionY * offsetDistance,
        friction = opts.friction or 7,
        maxDuration = opts.maxDuration or 0.55,
        stopThreshold = opts.stopThreshold or 18,
    }
end

local function selectGoldIcon(amount)
    if amount <= 2 then
        return "gold/gold_1"
    elseif amount <= 6 then
        return "gold/gold_2"
    end

    return "gold/gold_3"
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

local function spawnPotionLoot(world, event)
    if not event.position then
        return
    end

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
    local baseX = event.position.x - width / 2
    local baseY = event.position.y - height / 2
    local scatter = rollScatterData({
        minSpeed = 70,
        maxSpeed = 150,
        offsetDistanceMin = 10,
        offsetDistanceMax = 26,
    })

    local potionLoot = LootEntity.new({
        x = baseX + scatter.offsetX,
        y = baseY + scatter.offsetY,
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
        lootScatter = {
            vx = scatter.vx,
            vy = scatter.vy,
            friction = scatter.friction,
            maxDuration = scatter.maxDuration,
            stopThreshold = scatter.stopThreshold,
        },
    })

    world:addEntity(potionLoot)
end

local function spawnItemLoot(world, event)
    if math.random() >= ITEM_DROP_CHANCE then
        return
    end

    if not event.position then
        return
    end

    local foeTier = 1
    if event.foeTypeId then
        local foeConfig = FoeTypes.getConfig(event.foeTypeId)
        if foeConfig and foeConfig.tier then
            foeTier = math.max(1, math.floor(foeConfig.tier))
        end
    end

    local item = ItemGenerator.roll({
        source = "loot",
        foeTier = foeTier,
    })

    if not item then
        return
    end

    item.source = item.source or "monster"

    local width = 26
    local height = 26
    local baseX = event.position.x - width / 2
    local baseY = event.position.y - height / 2
    local scatter = rollScatterData()

    local loot = LootEntity.new({
        x = baseX + scatter.offsetX,
        y = baseY + scatter.offsetY,
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
        lootScatter = {
            vx = scatter.vx,
            vy = scatter.vy,
            friction = scatter.friction,
            maxDuration = scatter.maxDuration,
            stopThreshold = scatter.stopThreshold,
        },
    })

    world:addEntity(loot)
end

local function spawnGoldLoot(world, event)
    if not event.position or not event.foeTypeId then
        return
    end

    local foeConfig = FoeTypes.getConfig(event.foeTypeId)
    if not foeConfig then
        return
    end

    local goldRange = foeConfig.goldRange
    if not goldRange then
        return
    end

    local chance = foeConfig.goldChance or 0.6
    if math.random() >= chance then
        return
    end

    local minGold = math.max(0, math.floor(goldRange.min or 0))
    local maxGold = math.max(minGold, math.floor(goldRange.max or minGold))

    if maxGold <= 0 then
        return
    end

    local amount = math.random(minGold, maxGold)
    if amount <= 0 then
        return
    end

    local width = 26
    local height = 26
    local baseX = event.position.x - width / 2
    local baseY = event.position.y - height / 2
    local scatter = rollScatterData({
        minSpeed = 80,
        maxSpeed = 180,
        offsetDistanceMin = 12,
        offsetDistanceMax = 32,
    })

    local iconName = selectGoldIcon(amount)
    local iconPath = string.format("resources/icons/%s.png", iconName)

    local loot = LootEntity.new({
        x = baseX + scatter.offsetX,
        y = baseY + scatter.offsetY,
        width = width,
        height = height,
        renderable = {
            kind = "loot",
            color = { 0.95, 0.78, 0.2, 1 },
        },
        lootable = {
            gold = amount,
            pickupRadius = 128,
            source = event.lootSource or event.targetId,
            despawnTimer = 45,
            maxDespawnTimer = 45,
            iconPath = iconPath,
            goldIcon = iconName,
        },
        lootScatter = {
            vx = scatter.vx,
            vy = scatter.vy,
            friction = scatter.friction,
            maxDuration = scatter.maxDuration,
            stopThreshold = scatter.stopThreshold,
        },
    })

    world:addEntity(loot)
end

function lootDropSystem.update(world, _dt)
    local events = world.pendingCombatEvents
    if not events or #events == 0 then
        return
    end

    for _, event in ipairs(events) do
        if event.type == "death" and event.foeTypeId and not event._spawnedLoot then
            spawnItemLoot(world, event)
            spawnPotionLoot(world, event)
            spawnGoldLoot(world, event)
            event._spawnedLoot = true
        end
    end
end

return lootDropSystem

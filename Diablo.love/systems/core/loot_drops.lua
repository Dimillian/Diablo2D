local ItemGenerator = require("items.generator")
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

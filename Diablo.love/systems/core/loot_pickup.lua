local vector = require("modules.vector")
local EquipmentHelper = require("systems.helpers.equipment")

local lootPickupSystem = {}

local function getEntityCenter(entity)
    if not entity or not entity.position then
        return nil, nil
    end

    local x = entity.position.x
    local y = entity.position.y

    if entity.size then
        x = x + (entity.size.w or 0) / 2
        y = y + (entity.size.h or 0) / 2
    end

    return x, y
end

local function transferItemToPlayer(world, player, lootEntity)
    local lootable = lootEntity.lootable
    if not lootable then
        return false
    end

    local inventory = player.inventory
    local equipment = player.equipment

    if lootable.gold and lootable.gold > 0 then
        if inventory then
            inventory.gold = (inventory.gold or 0) + lootable.gold
        end

        world:removeEntity(lootEntity.id)
        return true
    end

    if not lootable.item then
        return false
    end

    local item = lootable.item

    if item.type == "health_potion" or item.type == "mana_potion" then
        local potions = player.potions
        if not potions then
            return false
        end

        local countKey = item.type == "health_potion" and "healthPotionCount" or "manaPotionCount"
        local maxKey = item.type == "health_potion" and "maxHealthPotionCount" or "maxManaPotionCount"

        local currentCount = potions[countKey] or 0
        local maxCount = potions[maxKey]

        if maxCount and currentCount >= maxCount then
            return false
        end

        local newCount = currentCount + 1
        if maxCount then
            newCount = math.min(maxCount, newCount)
        end

        potions[countKey] = newCount

        lootable.item = nil
        world:removeEntity(lootEntity.id)
        return true
    end

    if item.slot and equipment[item.slot] == nil then
        EquipmentHelper.equip(player, item)
    else
        EquipmentHelper.addToInventory(player, item)
    end

    lootable.item = nil
    world:removeEntity(lootEntity.id)
    return true
end

function lootPickupSystem.update(world, dt)
    local player = world:getPlayer()
    if not player then
        return
    end

    local coordsHelper = world.systemHelpers and world.systemHelpers.coordinates
    if not coordsHelper or not coordsHelper.toWorldFromScreen then
        return
    end

    local loots = world:queryEntities({ "lootable", "position" })

    if dt and dt > 0 then
        for _, loot in ipairs(loots) do
            local lootable = loot.lootable
            if lootable and lootable.despawnTimer then
                lootable.despawnTimer = lootable.despawnTimer - dt
                if lootable.despawnTimer <= 0 then
                    world:removeEntity(loot.id)
                end
            end
        end
    end

    local input =
        world.input and world.input.mouse and world.input.mouse.primary
    if not input then
        return
    end

    if not input.pressed then
        return
    end

    if input.consumedClickId == input.clickId then
        return
    end

    local camera = world.camera or { x = 0, y = 0 }
    local screenX, screenY = love.mouse.getPosition()
    local worldX, worldY = coordsHelper.toWorldFromScreen(camera, screenX, screenY)

    local playerX, playerY = getEntityCenter(player)

    for _, loot in ipairs(loots) do
        if loot.inactive then
            goto continue
        end

        local pos = loot.position
        local size = loot.size or { w = 16, h = 16 }
        local lootX = pos.x
        local lootY = pos.y
        local lootCenterX = lootX + size.w / 2
        local lootCenterY = lootY + size.h / 2

        local withinCursor =
            worldX >= lootX and worldX <= lootX + size.w and worldY >= lootY and worldY <= lootY + size.h

        if withinCursor then
            local pickupRadius = (loot.lootable and loot.lootable.pickupRadius)
            local distanceToPlayer = vector.distance(playerX, playerY, lootCenterX, lootCenterY)
            if distanceToPlayer <= pickupRadius then
                local pickedUp = transferItemToPlayer(world, player, loot)
                if pickedUp then
                    input.consumedClickId = input.clickId
                    return
                end
            end
        end

        ::continue::
    end
end

return lootPickupSystem

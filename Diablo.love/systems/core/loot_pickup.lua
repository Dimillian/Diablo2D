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
    if not lootable or not lootable.item then
        return
    end

    local item = lootable.item

    -- Check if item is a potion
    if item.type == "health_potion" then
        if player.potions then
            player.potions.healthPotionCount = math.min(
                player.potions.maxHealthPotionCount,
                player.potions.healthPotionCount + 1
            )
        end
        lootable.item = nil
        world:removeEntity(lootEntity.id)
        return  -- Skip inventory/equipment transfer
    elseif item.type == "mana_potion" then
        if player.potions then
            player.potions.manaPotionCount = math.min(
                player.potions.maxManaPotionCount,
                player.potions.manaPotionCount + 1
            )
        end
        lootable.item = nil
        world:removeEntity(lootEntity.id)
        return  -- Skip inventory/equipment transfer
    end

    local _, equipment = EquipmentHelper.ensure(player)

    if item.slot and equipment and equipment[item.slot] == nil then
        EquipmentHelper.equip(player, item)
    else
        EquipmentHelper.addToInventory(player, item)
    end

    lootable.item = nil
    world:removeEntity(lootEntity.id)
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
                transferItemToPlayer(world, player, loot)
                input.consumedClickId = input.clickId
                return
            end
        end

        ::continue::
    end
end

return lootPickupSystem

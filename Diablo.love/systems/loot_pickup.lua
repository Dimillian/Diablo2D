local vector = require("modules.vector")
local EquipmentHelper = require("system_helpers.equipment")

local lootPickupSystem = {}

function lootPickupSystem.update(scene, dt)
    dt = dt or 0

    local lootEntities = scene:queryEntities({ "lootable", "position" })
    local player = scene:getPlayer()

    if not player or not player.position then
        return
    end

    local playerCenterX = player.position.x + (player.size and player.size.w / 2 or 0)
    local playerCenterY = player.position.y + (player.size and player.size.h / 2 or 0)

    for _, lootEntity in ipairs(lootEntities) do
        local lootable = lootEntity.lootable

        -- Handle despawn timer
        if lootable.despawnTimer then
            lootable.despawnTimer = lootable.despawnTimer - dt
            if lootable.despawnTimer <= 0 then
                scene:removeEntity(lootEntity.id)
                goto continue
            end
        end

        -- Check pickup distance
        local lootCenterX = lootEntity.position.x + (lootEntity.size and lootEntity.size.w / 2 or 0)
        local lootCenterY = lootEntity.position.y + (lootEntity.size and lootEntity.size.h / 2 or 0)
        local dist = vector.distance(playerCenterX, playerCenterY, lootCenterX, lootCenterY)

        -- Check if player clicks and is within pickup radius
        if dist <= lootable.pickupRadius and love.mouse.isDown(1) then
            if lootable.item then
                -- Ensure player has inventory
                EquipmentHelper.ensure(player)

                -- Add item to inventory
                table.insert(player.inventory.items, lootable.item)

                -- Auto-equip if slot is empty
                local slotId = lootable.item.slot
                if slotId and not player.equipment[slotId] then
                    EquipmentHelper.equip(player, lootable.item)
                end

                -- Remove loot entity
                scene:removeEntity(lootEntity.id)
            end
        end

        ::continue::
    end
end

return lootPickupSystem

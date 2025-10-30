local Resources = require("modules.resources")

local renderEquipmentSystem = {}

---Render equipped items on entities that have equipment
function renderEquipmentSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "equipment", "position", "size" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities
        if entity.inactive then
            goto continue
        end

        local pos = entity.position
        local size = entity.size
        local centerX = pos.x + (size.w / 2)
        local centerY = pos.y + (size.h / 2)

        -- Slot-specific offsets (relative to entity size)
        local offsets = {
            weapon = { x = size.w * 1, y = 0 }, -- Forward (right)
            head = { x = 0, y = -size.h * 1 }, -- Up
            chest = { x = 0, y = 0 }, -- Center
            feet = { x = 0, y = size.h * 1 }, -- Down
        }

        -- Draw equipped items in order: feet (bottom), chest, head, weapon (top)
        local drawOrder = { "feet", "chest", "head", "weapon" }

        for _, slotId in ipairs(drawOrder) do
            local item = entity.equipment[slotId]
            if item and item.spritePath then
                local sprite = Resources.loadImageSafe(item.spritePath)
                if sprite then
                    local spriteSize = math.max(size.w, size.h) * 1.2 -- Slightly larger than entity
                    local offset = offsets[slotId] or { x = 0, y = 0 }
                    local spriteX = centerX - spriteSize / 2 + offset.x
                    local spriteY = centerY - spriteSize / 2 + offset.y
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(sprite, spriteX, spriteY, 0, spriteSize / sprite:getWidth(), spriteSize / sprite:getHeight())
                end
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderEquipmentSystem

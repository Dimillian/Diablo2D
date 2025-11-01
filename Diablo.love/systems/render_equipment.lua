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
            weapon = { x = size.w * 3, y = 0.5 }, -- Forward (right)
            head = { x = 0, y = -size.h * 1 }, -- Up
            chest = { x = 0, y = 0 }, -- Center
            feet = { x = 0, y = size.h * 1 }, -- Down
            glovesLeft = { x = -size.w * 1.5, y = 0.5 }, -- Left side
            glovesRight = { x = size.w * 1.5, y = 0.5 }, -- Right side
        }

        -- Draw equipped items in order: feet (bottom), chest, gloves, head, weapon (top)
        local drawOrder = { "feet", "chest", "gloves", "head", "weapon" }

        for _, slotId in ipairs(drawOrder) do
            local item = entity.equipment[slotId]
            if item and item.spritePath then
                local sprite = Resources.loadImageSafe(item.spritePath)
                if sprite then
                    local spriteSize = math.max(size.w, size.h) * 1.2 -- Slightly larger than entity

                    -- Special handling for gloves: render both left and right
                    if slotId == "gloves" then
                        -- Left glove (normal)
                        local leftOffset = offsets.glovesLeft or { x = 0, y = 0 }
                        local leftSpriteX = centerX - spriteSize / 2 + leftOffset.x
                        local leftSpriteY = centerY - spriteSize / 2 + leftOffset.y
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(
                            sprite,
                            leftSpriteX,
                            leftSpriteY,
                            0,
                            spriteSize / sprite:getWidth(),
                            spriteSize / sprite:getHeight()
                        )

                        -- Right glove (flipped horizontally)
                        local rightOffset = offsets.glovesRight or { x = 0, y = 0 }
                        local rightSpriteX = centerX - spriteSize / 2 + rightOffset.x
                        local rightSpriteY = centerY - spriteSize / 2 + rightOffset.y
                        love.graphics.draw(
                            sprite,
                            rightSpriteX + spriteSize, -- Adjust origin for horizontal flip
                            rightSpriteY,
                            0,
                            -spriteSize / sprite:getWidth(), -- Negative scaleX to flip horizontally
                            spriteSize / sprite:getHeight()
                        )
                    else
                        -- Normal rendering for other slots
                        local offset = offsets[slotId] or { x = 0, y = 0 }
                        local spriteX = centerX - spriteSize / 2 + offset.x
                        local spriteY = centerY - spriteSize / 2 + offset.y

                        -- Apply weapon swing animation if combat component exists
                        if slotId == "weapon" and entity.combat and entity.combat.swingTimer > 0 then
                            local swingOffset = math.sin(entity.combat.swingTimer * 10) * 8
                            spriteX = spriteX + swingOffset
                        end

                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(
                            sprite,
                            spriteX,
                            spriteY,
                            0,
                            spriteSize / sprite:getWidth(),
                            spriteSize / sprite:getHeight()
                        )
                    end
                end
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderEquipmentSystem

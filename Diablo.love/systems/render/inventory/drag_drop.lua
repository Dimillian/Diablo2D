---Render system for drag-and-drop and trash dropzone
local Resources = require("modules.resources")
local Tooltips = require("systems.helpers.tooltips")

local renderInventoryDragDrop = {}

local TRASH_SIZE = 40
local TRASH_SPACING = 12

function renderInventoryDragDrop.draw(scene)
    local layout = scene.windowLayout
    if not layout or not layout.footer then
        return
    end

    local footer = layout.footer
    local rightColumn = layout.columns and layout.columns.right
    if not rightColumn then
        return
    end

    -- Draw trash dropzone in bottom right of inventory grid area
    local trashX = rightColumn.x + rightColumn.width - TRASH_SIZE - TRASH_SPACING
    local trashY = footer.y - TRASH_SIZE - TRASH_SPACING

    local isHoveringTrash = false
    if scene.dragState then
        local mx = scene.dragState.mouseX or 0
        local my = scene.dragState.mouseY or 0
        isHoveringTrash = mx >= trashX
            and mx <= trashX + TRASH_SIZE
            and my >= trashY
            and my <= trashY + TRASH_SIZE
    end

    -- Draw trash background
    if isHoveringTrash then
        love.graphics.setColor(0.8, 0.2, 0.2, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    end
    love.graphics.rectangle("fill", trashX, trashY, TRASH_SIZE, TRASH_SIZE, 4, 4)

    -- Draw trash border
    if isHoveringTrash then
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", trashX, trashY, TRASH_SIZE, TRASH_SIZE, 4, 4)

    -- Draw trash icon
    local trashIcon = Resources.loadUIIcon("trash")
    if trashIcon then
        local iconSize = 24
        local iconX = trashX + (TRASH_SIZE - iconSize) / 2
        local iconY = trashY + (TRASH_SIZE - iconSize) / 2
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        local scale = iconSize / math.max(trashIcon:getWidth(), trashIcon:getHeight())
        love.graphics.draw(trashIcon, iconX, iconY, 0, scale, scale)
    end

    -- Store trash rect for drop detection
    scene.trashRect = {
        x = trashX,
        y = trashY,
        w = TRASH_SIZE,
        h = TRASH_SIZE,
    }

    -- Highlight valid drop targets
    if scene.dragState and scene.dragState.item then
        local draggedItem = scene.dragState.item
        local mx = scene.dragState.mouseX or 0
        local my = scene.dragState.mouseY or 0

        -- Highlight inventory slots
        for _, rect in ipairs(scene.itemRects or {}) do
            local isHovering = mx >= rect.x
                and mx <= rect.x + rect.w
                and my >= rect.y
                and my <= rect.y + rect.h

            if isHovering then
                love.graphics.setColor(0.3, 0.8, 0.3, 0.5)
                love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 4, 4)
                love.graphics.setColor(0.3, 1, 0.3, 1)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 4, 4)
            end
        end

        -- Highlight compatible equipment slots
        for _, rect in ipairs(scene.equipmentRects or {}) do
            local slotId = rect.slot
            local compatibleSlot = draggedItem.slot
            if compatibleSlot == "ring" and (slotId == "ringLeft" or slotId == "ringRight") then
                compatibleSlot = slotId
            end

            if compatibleSlot == slotId then
                local isHovering = mx >= rect.x
                    and mx <= rect.x + rect.w
                    and my >= rect.y
                    and my <= rect.y + rect.h

                if isHovering then
                    love.graphics.setColor(0.3, 0.8, 0.3, 0.5)
                    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
                    love.graphics.setColor(0.3, 1, 0.3, 1)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 6, 6)
                end
            end
        end
    end

    -- Draw dragged item following cursor
    if scene.dragState and scene.dragState.item then
        local item = scene.dragState.item
        local mx = scene.dragState.mouseX or 0
        local my = scene.dragState.mouseY or 0

        local dragSize = 40
        local dragX = mx - dragSize / 2
        local dragY = my - dragSize / 2

        -- Draw semi-transparent background
        local rarityColor = Tooltips.getRarityColor(item.rarity)
        love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3], 0.8)
        love.graphics.rectangle("fill", dragX, dragY, dragSize, dragSize, 4, 4)

        love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3], rarityColor[4] or 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", dragX, dragY, dragSize, dragSize, 4, 4)

        -- Draw item sprite
        local sprite = Resources.loadImageSafe(item.spritePath)
        if sprite then
            local spriteSize = 32
            local spriteX = dragX + (dragSize - spriteSize) / 2
            local spriteY = dragY + (dragSize - spriteSize) / 2

            love.graphics.setColor(1, 1, 1, 0.9)
            local spriteScaleX = spriteSize / sprite:getWidth()
            local spriteScaleY = spriteSize / sprite:getHeight()
            love.graphics.draw(sprite, spriteX, spriteY, 0, spriteScaleX, spriteScaleY)
        end
    end

    -- Reset render state to prevent bleed to later systems
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return renderInventoryDragDrop

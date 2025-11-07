---Render system for inventory equipment slots
local Resources = require("modules.resources")
local EquipmentHelper = require("systems.helpers.equipment")
local WindowLayout = require("systems.helpers.window_layout")
local Tooltips = require("systems.helpers.tooltips")

local renderInventoryEquipment = {}

local function snap(value)
    return math.floor(value + 0.5)
end

local function drawEquipmentSlot(scene, slot, slotX, slotY, slotWidth, slotHeight, equippedItem)
    love.graphics.setColor(0.16, 0.16, 0.18, 0.95)
    love.graphics.rectangle("fill", slotX, slotY, slotWidth, slotHeight, 6, 6)

    if equippedItem then
        local rarityColor = Tooltips.getRarityColor(equippedItem.rarity)
        love.graphics.setColor(rarityColor)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.45, 0.4, 0.3, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", slotX, slotY, slotWidth, slotHeight, 6, 6)

    local labelY = snap(slotY + 6)
    local font = love.graphics.getFont()
    local labelHeight = font:getHeight()
    love.graphics.setColor(0.85, 0.82, 0.7, 1)
    love.graphics.print(slot.label, snap(slotX + 8), labelY)

    if equippedItem then
        local sprite = Resources.loadImageSafe(equippedItem.spritePath)
        if sprite then
            local spriteSize = 40
            local spriteX = snap(slotX + (slotWidth - spriteSize) / 2)
            local labelBottom = labelY + labelHeight + 6
            local spriteAreaBottom = slotY + slotHeight - 8
            local spriteAreaHeight = spriteAreaBottom - labelBottom
            local spriteY = snap(labelBottom + (spriteAreaHeight - spriteSize) / 2)
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

        scene.equipmentRects[#scene.equipmentRects + 1] = {
            slot = slot.id,
            item = equippedItem,
            x = slotX,
            y = slotY,
            w = slotWidth,
            h = slotHeight,
        }
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        local emptyText = "Empty"
        local textWidth = love.graphics.getFont():getWidth(emptyText)
        love.graphics.print(emptyText, snap(slotX + (slotWidth - textWidth) / 2), snap(slotY + slotHeight / 2))

        scene.equipmentRects[#scene.equipmentRects + 1] = {
            slot = slot.id,
            item = nil,
            x = slotX,
            y = slotY,
            w = slotWidth,
            h = slotHeight,
        }
    end
end

function renderInventoryEquipment.draw(scene)
    local player = scene.world:getPlayer()
    if not player then
        return
    end

    local equipment = player.equipment

    local layout = scene.windowLayout
    if not layout then
        return
    end

    local columns = layout.columns or WindowLayout.calculateColumns(layout, { leftRatio = 0.43 })
    layout.columns = columns

    local leftColumn = columns.left
    local padding = layout.padding
    local font = love.graphics.getFont()

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Equipment", leftColumn.x, leftColumn.y)

    local titleHeight = font:getHeight()
    local contentTop = leftColumn.y + titleHeight + padding * 0.5
    local availableHeight = leftColumn.height - (contentTop - leftColumn.y)
    if availableHeight <= 0 then
        return
    end

    local spacing = padding
    local slotsHeight = math.max(160, availableHeight * 0.6)
    if slotsHeight > availableHeight then
        slotsHeight = availableHeight
        spacing = 0
    end
    local statsHeight = availableHeight - slotsHeight - spacing
    if statsHeight < 0 then
        statsHeight = 0
        spacing = 0
    end

    local slotsArea = {
        x = leftColumn.x,
        y = contentTop,
        width = leftColumn.width,
        height = slotsHeight,
    }

    local statsArea = {
        x = leftColumn.x,
        y = slotsArea.y + slotsArea.height + spacing,
        width = leftColumn.width,
        height = statsHeight,
    }

    layout.inventoryAreas = layout.inventoryAreas or {}
    layout.inventoryAreas.slots = slotsArea
    layout.inventoryAreas.stats = statsArea

    local slotSpacingX = 14
    local slotSpacingY = 12
    local columnsCount = 2
    local slotWidth = snap((slotsArea.width - slotSpacingX * (columnsCount - 1)) / columnsCount)
    local slotHeight = 64

    local slots = EquipmentHelper.slots()
    for index, slot in ipairs(slots) do
        local col = (index - 1) % columnsCount
        local row = math.floor((index - 1) / columnsCount)

        local slotX = snap(slotsArea.x + col * (slotWidth + slotSpacingX))
        local slotY = snap(slotsArea.y + row * (slotHeight + slotSpacingY))

        if slotY + slotHeight > slotsArea.y + slotsArea.height then
            break
        end

        local equippedItem = equipment[slot.id]
        drawEquipmentSlot(scene, slot, slotX, slotY, slotWidth, slotHeight, equippedItem)
    end
end

return renderInventoryEquipment

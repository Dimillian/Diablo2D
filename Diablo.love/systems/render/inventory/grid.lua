---Render system for inventory grid
local Resources = require("modules.resources")
local EquipmentHelper = require("systems.helpers.equipment")
local Tooltips = require("systems.helpers.tooltips")
local WindowLayout = require("systems.helpers.window_layout")

local renderInventoryGrid = {}

local function snap(value)
    return math.floor(value + 0.5)
end

local MAX_SLOTS = 48
local GRID_COLUMNS = 8
local SLOT_SIZE = 40
local SLOT_SPACING = 6

local function drawInventorySlotFilled(scene, item, slotX, slotY, slotSize, slotIndex)
    local rarityColor = Tooltips.getRarityColor(item.rarity)

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4, 4)

    love.graphics.setColor(rarityColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4, 4)

    local sprite = Resources.loadImageSafe(item.spritePath)
    if sprite then
        local spriteSize = 32
        local spriteX = snap(slotX + (slotSize - spriteSize) / 2)
        local spriteY = snap(slotY + (slotSize - spriteSize) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        local spriteScaleX = spriteSize / sprite:getWidth()
        local spriteScaleY = spriteSize / sprite:getHeight()
        love.graphics.draw(sprite, spriteX, spriteY, 0, spriteScaleX, spriteScaleY)
    end

    scene.itemRects[#scene.itemRects + 1] = {
        item = item,
        index = slotIndex,
        x = slotX,
        y = slotY,
        w = slotSize,
        h = slotSize,
    }
end

local function drawInventorySlotEmpty(scene, slotX, slotY, slotSize, slotIndex)
    love.graphics.setColor(0.16, 0.16, 0.18, 0.95)
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4, 4)

    love.graphics.setColor(0.35, 0.35, 0.35, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4, 4)

    scene.itemRects[#scene.itemRects + 1] = {
        item = nil,
        index = slotIndex,
        x = slotX,
        y = slotY,
        w = slotSize,
        h = slotSize,
    }
end

function renderInventoryGrid.draw(scene)
    local player = scene.world:getPlayer()
    if not player then
        return
    end

    local inventory = EquipmentHelper.ensure(player)
    local items = inventory and inventory.items or {}

    local layout = scene.windowLayout
    if not layout then
        return
    end

    local columns = layout.columns or WindowLayout.calculateColumns(layout, { leftRatio = 0.43 })
    layout.columns = columns
    local rightColumn = columns.right

    local padding = layout.padding
    local font = love.graphics.getFont()

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Inventory", rightColumn.x, rightColumn.y)

    local headerHeight = font:getHeight()
    local contentTop = rightColumn.y + headerHeight + padding * 0.5
    local contentHeight = rightColumn.height - (contentTop - rightColumn.y)
    if contentHeight <= 0 then
        return
    end

    local cols = GRID_COLUMNS
    local slotSpacing = SLOT_SPACING
    local slotXStart = snap(rightColumn.x)
    local slotYStart = snap(contentTop)

    local lastSlotBottom = slotYStart
    local footerTop = layout.footer and layout.footer.y - padding or (rightColumn.y + rightColumn.height)
    local bottomLimit = footerTop - padding

    for slotIndex = 1, MAX_SLOTS do
        local col = (slotIndex - 1) % cols
        local row = math.floor((slotIndex - 1) / cols)

        local slotX = snap(slotXStart + col * (SLOT_SIZE + slotSpacing))
        local slotY = snap(slotYStart + row * (SLOT_SIZE + slotSpacing))

        if slotY + SLOT_SIZE > bottomLimit then
            break
        end

        local item = items[slotIndex]
        if item then
            drawInventorySlotFilled(scene, item, slotX, slotY, SLOT_SIZE, slotIndex)
        else
            drawInventorySlotEmpty(scene, slotX, slotY, SLOT_SIZE, slotIndex)
        end

        lastSlotBottom = math.max(lastSlotBottom, slotY + SLOT_SIZE)
    end

    scene.inventoryGridBottomY = lastSlotBottom
end

return renderInventoryGrid

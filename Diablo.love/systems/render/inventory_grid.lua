---Render system for inventory grid
local Resources = require("modules.resources")
local EquipmentHelper = require("systems.helpers.equipment")
local InventoryLayout = require("systems.helpers.inventory_layout")
local Tooltips = require("systems.helpers.tooltips")

local rarityColors = Tooltips.rarityColors

local renderInventoryGrid = {}

-- Utility function to snap values to nearest pixel
local function snap(value)
    return math.floor(value + 0.5)
end

---Draw a filled inventory slot with item sprite and rarity-colored border
---@param scene table Inventory scene
---@param item table Item object
---@param slotX number Slot X position
---@param slotY number Slot Y position
---@param slotSize number Slot size (width and height)
---@param slotIndex number Slot index in inventory
local function drawInventorySlotFilled(scene, item, slotX, slotY, slotSize, slotIndex)
    local rarityColor = rarityColors[item.rarity] or rarityColors.common

    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Draw rarity-colored border
    love.graphics.setColor(rarityColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Draw sprite centered (32x32)
    local sprite = Resources.loadImageSafe(item.spritePath)
    if sprite then
        local spriteSize = 32
        local spriteX = snap(slotX + (slotSize - spriteSize) / 2)
        local spriteY = snap(slotY + (slotSize - spriteSize) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        local spriteScaleX = spriteSize / sprite:getWidth()
        local spriteScaleY = spriteSize / sprite:getHeight()
        love.graphics.draw(
            sprite,
            spriteX,
            spriteY,
            0,
            spriteScaleX,
            spriteScaleY
        )
    end

    -- Store rect for click detection
    scene.itemRects[#scene.itemRects + 1] = {
        item = item,
        index = slotIndex,
        x = slotX,
        y = slotY,
        w = slotSize,
        h = slotSize,
    }
end

---Draw an empty inventory slot
---@param scene table Inventory scene
---@param slotX number Slot X position
---@param slotY number Slot Y position
---@param slotSize number Slot size (width and height)
---@param slotIndex number Slot index in inventory
local function drawInventorySlotEmpty(scene, slotX, slotY, slotSize, slotIndex)
    -- Draw empty slot background
    love.graphics.setColor(0.16, 0.16, 0.18, 0.95)
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Draw empty slot border
    love.graphics.setColor(0.35, 0.35, 0.35, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Store rect for click detection
    scene.itemRects[#scene.itemRects + 1] = {
        item = nil,
        index = slotIndex,
        x = slotX,
        y = slotY,
        w = slotSize,
        h = slotSize,
    }
end

---Draw inventory grid with filled and empty slots
---@param scene table Inventory scene
function renderInventoryGrid.draw(scene)
    local player = scene.world:getPlayer()
    if not player then
        return
    end

    local inventory = EquipmentHelper.ensure(player)
    local items = inventory and inventory.items or {}

    -- Calculate layout
    local panelLayout = InventoryLayout.calculatePanelLayout()
    local headersLayout = InventoryLayout.calculateHeadersLayout(
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth
    )
    local gridLayout = InventoryLayout.calculateInventoryLayout(
        headersLayout.inventoryHeaderX,
        headersLayout.headerY,
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth,
        panelLayout.panelHeight
    )

    -- Draw inventory grid (empty slots + filled slots)
    for slotIndex = 1, gridLayout.gridMaxSlots do
        local col = ((slotIndex - 1) % gridLayout.gridCols)
        local row = math.floor((slotIndex - 1) / gridLayout.gridCols)

        local slotX = snap(
            gridLayout.gridStartX + col * (gridLayout.gridSlotSize + gridLayout.gridSpacing)
        )
        local slotY = snap(
            gridLayout.gridStartY + row * (gridLayout.gridSlotSize + gridLayout.gridSpacing)
        )

        -- Stop if we go beyond panel bounds
        if slotY + gridLayout.gridSlotSize > gridLayout.panelY + gridLayout.panelHeight - 60 then
            break
        end

        local item = items[slotIndex]

        if item then
            drawInventorySlotFilled(scene, item, slotX, slotY, gridLayout.gridSlotSize, slotIndex)
        else
            drawInventorySlotEmpty(scene, slotX, slotY, gridLayout.gridSlotSize, slotIndex)
        end
    end
end

return renderInventoryGrid

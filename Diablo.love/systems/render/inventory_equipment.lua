---Render system for inventory equipment slots
local Resources = require("modules.resources")
local EquipmentHelper = require("systems.helpers.equipment")
local InventoryLayout = require("systems.helpers.inventory_layout")

local renderInventoryEquipment = {}

-- Utility function to snap values to nearest pixel
local function snap(value)
    return math.floor(value + 0.5)
end

---Draw a single equipment slot with item sprite if equipped
---@param scene table Inventory scene
---@param slot table Slot definition {id, label}
---@param slotX number Slot X position
---@param slotY number Slot Y position
---@param slotWidth number Slot width
---@param slotHeight number Slot height
---@param equippedItem table|nil Equipped item or nil
local function drawEquipmentSlot(scene, slot, slotX, slotY, slotWidth, slotHeight, equippedItem)
    -- Draw slot background and border
    love.graphics.setColor(0.16, 0.16, 0.18, 0.95)
    love.graphics.rectangle("fill", slotX, slotY, slotWidth, slotHeight, 6, 6)
    love.graphics.setColor(0.45, 0.4, 0.3, 1)
    love.graphics.rectangle("line", slotX, slotY, slotWidth, slotHeight, 6, 6)

    -- Draw slot label
    local labelY = snap(slotY + 6)
    love.graphics.setColor(0.85, 0.82, 0.7, 1)
    love.graphics.print(slot.label, snap(slotX + 8), labelY)

    if equippedItem then
        -- Draw equipped item sprite
        local sprite = Resources.loadImageSafe(equippedItem.spritePath)
        if sprite then
            local spriteSize = 40
            local spriteX = snap(slotX + (slotWidth - spriteSize) / 2)
            local spriteY = snap(labelY + 20)
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
        -- Draw "Empty" text
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        local emptyTextY = snap(slotY + (slotHeight / 2))
        local emptyTextX = snap(slotX + (slotWidth - love.graphics.getFont():getWidth("Empty")) / 2)
        love.graphics.print("Empty", emptyTextX, emptyTextY)

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

---Draw all equipment slots in a grid layout
---@param scene table Inventory scene
function renderInventoryEquipment.draw(scene)
    local player = scene.world:getPlayer()
    if not player then
        return
    end

    local _, equipment = EquipmentHelper.ensure(player)
    if not equipment then
        return
    end

    -- Calculate layout
    local panelLayout = InventoryLayout.calculatePanelLayout()
    local headersLayout = InventoryLayout.calculateHeadersLayout(
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth
    )
    local equipmentLayout = InventoryLayout.calculateEquipmentLayout(
        panelLayout.panelX,
        panelLayout.panelHeight,
        headersLayout.headerY,
        headersLayout.dividerX,
        headersLayout.equipmentHeaderX
    )

    -- Draw divider line
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    local dividerEndY = panelLayout.panelY + panelLayout.panelHeight
    love.graphics.line(
        headersLayout.dividerX,
        panelLayout.panelY,
        headersLayout.dividerX,
        dividerEndY
    )

    -- Draw headers
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Equipment", headersLayout.equipmentHeaderX, headersLayout.headerY)
    love.graphics.print("Inventory", headersLayout.inventoryHeaderX, headersLayout.headerY)

    -- Draw equipment slots
    local columns = 2
    local slotSpacingX = 14
    local slotSpacingY = 12
    local slotWidth = snap((equipmentLayout.equipmentAreaWidth - slotSpacingX * (columns - 1)) / columns)
    local slotHeight = 64

    local slots = EquipmentHelper.slots()
    for index, slot in ipairs(slots) do
        local col = ((index - 1) % columns)
        local row = math.floor((index - 1) / columns)

        local slotX = snap(equipmentLayout.equipmentAreaX + col * (slotWidth + slotSpacingX))
        local slotY = snap(equipmentLayout.equipmentAreaTop + row * (slotHeight + slotSpacingY))
        local equippedItem = equipment[slot.id]

        drawEquipmentSlot(scene, slot, slotX, slotY, slotWidth, slotHeight, equippedItem)
    end
end

return renderInventoryEquipment

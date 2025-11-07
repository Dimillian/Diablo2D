---Render system for inventory tooltips
local Tooltips = require("systems.helpers.tooltips")
local EquipmentHelper = require("systems.helpers.equipment")

local renderInventoryTooltip = {}

---Draw tooltip for hovered item
---@param scene table Inventory scene
function renderInventoryTooltip.draw(scene)
    local mx, my = love.mouse.getPosition()
    local hovered
    local isInventoryItem = false

    -- Check inventory items (only show tooltip if item exists)
    for _, rect in ipairs(scene.itemRects or {}) do
        if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
            if rect.item then
                hovered = rect.item
                isInventoryItem = true
                break
            end
        end
    end

    -- Check equipment slots
    if not hovered then
        for _, rect in ipairs(scene.equipmentRects or {}) do
            if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
                hovered = rect.item
                break
            end
        end
    end

    -- Check attribute hovers (only if no item is hovered)
    local hoveredAttribute = nil
    if not hovered then
        for _, rect in ipairs(scene.attributeRects or {}) do
            if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
                hoveredAttribute = rect
                break
            end
        end
    end

    -- Show attribute tooltip
    if hoveredAttribute then
        local attributeName = hoveredAttribute.attributeKey:gsub("^%l", string.upper)
        local lines = Tooltips.buildAttributeTooltipLines(
            hoveredAttribute.attributeKey,
            hoveredAttribute.attributeValue
        )
        Tooltips.drawSimpleTooltip(
            attributeName,
            lines,
            mx,
            my,
            {
                offsetX = 16,
                offsetY = 16,
                clamp = true,
            }
        )
        return
    end

    if not hovered then
        return
    end

    -- Only show comparison for inventory items (not already-equipped items)
    local isEquippedItem = not isInventoryItem
    local equippedItems = {}
    if isInventoryItem and hovered.slot then
        local player = scene.world:getPlayer()
        if player then
            equippedItems = EquipmentHelper.getEquippedItemsForComparison(player, hovered.slot)
        end
    end

    Tooltips.drawItemTooltip(hovered, mx, my, {
        offsetX = 16,
        offsetY = 16,
        clamp = true,
        equippedItems = equippedItems,
        isEquippedItem = isEquippedItem,
    })
end

return renderInventoryTooltip

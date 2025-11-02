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

    if not hovered then
        return
    end

    -- Only show comparison for inventory items (not already-equipped items)
    local equippedItems = {}
    local isEquippedItem = not isInventoryItem
    if isInventoryItem and hovered.slot then
        local player = scene.world:getPlayer()
        if player then
            local _, equipment = EquipmentHelper.ensure(player)
            if equipment then
                -- Handle ring slots: compare against both ringLeft and ringRight
                if hovered.slot == "ring" then
                    if equipment.ringLeft then
                        equippedItems[#equippedItems + 1] = equipment.ringLeft
                    end
                    if equipment.ringRight then
                        equippedItems[#equippedItems + 1] = equipment.ringRight
                    end
                else
                    -- For other slots, get the equipped item if it exists
                    local equippedItem = equipment[hovered.slot]
                    if equippedItem then
                        equippedItems[#equippedItems + 1] = equippedItem
                    end
                end
            end
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

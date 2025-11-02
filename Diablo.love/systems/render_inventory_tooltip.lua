---Render system for inventory tooltips
local Tooltips = require("system_helpers.tooltips")

local renderInventoryTooltip = {}

---Draw tooltip for hovered item
---@param scene table Inventory scene
function renderInventoryTooltip.draw(scene)
    local mx, my = love.mouse.getPosition()
    local hovered

    -- Check inventory items (only show tooltip if item exists)
    for _, rect in ipairs(scene.itemRects or {}) do
        if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
            if rect.item then
                hovered = rect.item
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

    Tooltips.drawItemTooltip(hovered, mx, my, {
        offsetX = 16,
        offsetY = 16,
        clamp = true,
    })
end

return renderInventoryTooltip

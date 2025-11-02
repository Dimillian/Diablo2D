---Render system for inventory background (dim overlay and panel)
local InventoryLayout = require("system_helpers.inventory_layout")

local renderInventoryBackground = {}

---Draw dimmed background overlay and panel
---@param _scene table Inventory scene (unused, kept for consistency)
function renderInventoryBackground.draw(_scene)
    local layout = InventoryLayout.calculatePanelLayout()

    -- Draw dimmed background overlay
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, layout.screenWidth, layout.screenHeight)

    -- Draw panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", layout.panelX, layout.panelY, layout.panelWidth, layout.panelHeight, 8, 8)

    -- Draw panel border
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", layout.panelX, layout.panelY, layout.panelWidth, layout.panelHeight, 8, 8)
end

return renderInventoryBackground

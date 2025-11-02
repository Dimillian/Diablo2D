---Render system for inventory help text
local InventoryLayout = require("system_helpers.inventory_layout")

local renderInventoryHelp = {}

---Draw help text at bottom of inventory section
---@param _scene table Inventory scene (unused, kept for consistency)
function renderInventoryHelp.draw(_scene)
    local panelLayout = InventoryLayout.calculatePanelLayout()
    local headersLayout = InventoryLayout.calculateHeadersLayout(
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth
    )
    local helpLayout = InventoryLayout.calculateHelpLayout(
        headersLayout.inventoryHeaderX,
        panelLayout.panelY,
        panelLayout.panelHeight
    )

    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Press G to add random loot", helpLayout.helpX, helpLayout.helpY)
end

return renderInventoryHelp

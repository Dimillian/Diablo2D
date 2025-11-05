---Inventory layout helper module
---Calculates all layout positions and dimensions for inventory UI
local InventoryLayout = {}
local BOTTOM_BAR_HEIGHT = 44
local BOTTOM_BAR_PADDING = 16

InventoryLayout.BOTTOM_BAR_HEIGHT = BOTTOM_BAR_HEIGHT
InventoryLayout.BOTTOM_BAR_PADDING = BOTTOM_BAR_PADDING

-- Utility function to snap values to nearest pixel for crisp rendering
local function snap(value)
    return math.floor(value + 0.5)
end

---Calculate panel dimensions and position centered on screen
---@return table Layout table with panelX, panelY, panelWidth, panelHeight, screenWidth, screenHeight
function InventoryLayout.calculatePanelLayout()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local panelWidth = snap(screenWidth * 0.8)
    local panelHeight = snap(screenHeight * 0.8)
    local panelX = snap((screenWidth - panelWidth) / 2)
    local panelY = snap((screenHeight - panelHeight) / 2)

    return {
        panelX = panelX,
        panelY = panelY,
        panelWidth = panelWidth,
        panelHeight = panelHeight,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
    }
end

---Calculate equipment area layout positions
---@param panelX number Panel X position
---@param panelHeight number Panel height
---@param headerY number Header Y position
---@param dividerX number Divider X position
---@param equipmentHeaderX number Equipment header X position
---@return table Layout table with equipment area positions
function InventoryLayout.calculateEquipmentLayout(
    panelX,
    panelHeight,
    headerY,
    dividerX,
    equipmentHeaderX
)
    local equipmentAreaTop = snap(headerY + 30)
    local equipmentAreaHeight = snap(panelHeight * 0.45)
    local equipmentAreaBottom = equipmentAreaTop + equipmentAreaHeight
    local equipmentAreaWidth = snap(dividerX - panelX - 40)
    local equipmentAreaX = equipmentHeaderX

    local statsDividerY = snap(equipmentAreaBottom + 12)
    local statsHeaderY = snap(statsDividerY + 12)
    local statsStartY = snap(statsHeaderY + 24)

    return {
        equipmentAreaX = equipmentAreaX,
        equipmentAreaTop = equipmentAreaTop,
        equipmentAreaHeight = equipmentAreaHeight,
        equipmentAreaWidth = equipmentAreaWidth,
        equipmentAreaBottom = equipmentAreaBottom,
        statsDividerY = statsDividerY,
        statsHeaderY = statsHeaderY,
        statsStartY = statsStartY,
    }
end

---Calculate inventory grid layout
---@param inventoryHeaderX number Inventory header X position
---@param headerY number Header Y position
---@param panelX number Panel X position
---@param panelY number Panel Y position
---@param panelWidth number Panel width
---@param panelHeight number Panel height
---@return table Layout table with grid dimensions and positions
function InventoryLayout.calculateInventoryLayout(inventoryHeaderX, headerY, panelX, panelY, panelWidth, panelHeight)
    local gridSlotSize = 40 -- 32px sprite + 8px padding
    local gridSpacing = 4
    local gridCols = 8
    local gridStartX = inventoryHeaderX
    local gridStartY = snap(headerY + 32)
    local gridAreaWidth = snap((panelX + panelWidth) - 40 - gridStartX)

    -- Calculate how many columns fit in available width
    local availableCols = math.floor((gridAreaWidth + gridSpacing) / (gridSlotSize + gridSpacing))
    if availableCols < gridCols then
        gridCols = math.max(1, availableCols)
    end

    local panelBottom = panelY + panelHeight
    local barReserve = BOTTOM_BAR_HEIGHT + BOTTOM_BAR_PADDING
    local gridBottomLimit = snap(panelBottom - barReserve)
    if gridBottomLimit <= gridStartY + gridSlotSize then
        gridBottomLimit = gridStartY + gridSlotSize + gridSpacing
    end

    local availableHeight = gridBottomLimit - gridStartY
    local rowsThatFit = math.max(1, math.floor((availableHeight + gridSpacing) / (gridSlotSize + gridSpacing)))
    local gridRows = rowsThatFit
    local gridMaxSlots = gridCols * gridRows
    local gridHeight = gridRows * gridSlotSize + (gridRows - 1) * gridSpacing
    local computedGridBottom = gridStartY + gridHeight

    return {
        gridSlotSize = gridSlotSize,
        gridCols = gridCols,
        gridRows = gridRows,
        gridMaxSlots = gridMaxSlots,
        gridSpacing = gridSpacing,
        gridStartX = gridStartX,
        gridStartY = gridStartY,
        gridAreaWidth = gridAreaWidth,
        panelY = panelY,
        panelHeight = panelHeight,
        gridBottomLimit = gridBottomLimit,
        gridComputedBottom = computedGridBottom,
    }
end

---Calculate divider and header positions
---@param panelX number Panel X position
---@param panelY number Panel Y position
---@param panelWidth number Panel width
---@return table Layout table with divider and header positions
function InventoryLayout.calculateHeadersLayout(panelX, panelY, panelWidth)
    local dividerX = snap(panelX + (panelWidth * 0.45))
    local headerY = snap(panelY + 20)
    local equipmentHeaderX = snap(panelX + 20)
    local inventoryHeaderX = snap(dividerX + 20)

    return {
        dividerX = dividerX,
        headerY = headerY,
        equipmentHeaderX = equipmentHeaderX,
        inventoryHeaderX = inventoryHeaderX,
    }
end

---Calculate help text position
---@param inventoryHeaderX number Inventory header X position
---@param panelY number Panel Y position
---@param panelHeight number Panel height
---@return table Layout table with help text position
function InventoryLayout.calculateHelpLayout(inventoryHeaderX, panelY, panelHeight)
    return {
        helpX = inventoryHeaderX,
        helpY = snap(panelY + panelHeight - 32),
    }
end

return InventoryLayout

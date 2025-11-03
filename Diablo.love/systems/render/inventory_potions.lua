---Render system for potion display in inventory
local Resources = require("modules.resources")
local InventoryLayout = require("systems.helpers.inventory_layout")

local renderInventoryPotions = {}

-- Utility function to snap values to nearest pixel
local function snap(value)
    return math.floor(value + 0.5)
end

---Draw potion section below inventory grid
---@param scene table Inventory scene
function renderInventoryPotions.draw(scene)
    local player = scene.world:getPlayer()
    if not player or not player.potions then
        return
    end

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

    -- Calculate where inventory grid ends
    local inventoryX = headersLayout.inventoryHeaderX
    local inventoryWidth = (panelLayout.panelX + panelLayout.panelWidth) - 40 - inventoryX
    local gridRows = gridLayout.gridRows
    local gridSlotSize = gridLayout.gridSlotSize
    local gridSpacing = gridLayout.gridSpacing
    local gridStartY = gridLayout.gridStartY
    local inventoryGridBottomY = gridStartY + (gridRows * (gridSlotSize + gridSpacing)) - gridSpacing

    -- Draw divider line
    local dividerY = snap(inventoryGridBottomY + 16)
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(inventoryX, dividerY, inventoryX + inventoryWidth, dividerY)

    -- Draw potion section
    local potionSectionY = snap(dividerY + 16)
    local potionIconSize = 32
    local potionSpacing = 16

    -- Health potion display
    local healthPotionX = inventoryX + potionSpacing
    local healthPotionY = potionSectionY

    -- Draw health potion icon box
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", healthPotionX, healthPotionY, potionIconSize, potionIconSize, 4, 4)
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", healthPotionX, healthPotionY, potionIconSize, potionIconSize, 4, 4)

    -- Draw health potion icon
    local healthPotionIcon = Resources.loadUIIcon("health_potion")
    if healthPotionIcon then
        local iconPadding = 6
        local iconInnerSize = potionIconSize - (iconPadding * 2)
        local iconX = healthPotionX + iconPadding
        local iconY = healthPotionY + iconPadding

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(healthPotionIcon, iconX, iconY, 0,
            iconInnerSize / healthPotionIcon:getWidth(),
            iconInnerSize / healthPotionIcon:getHeight())
    end

    -- Draw health potion count text
    local font = love.graphics.getFont()
    local textX = healthPotionX + potionIconSize + potionSpacing
    local textY = healthPotionY + potionIconSize / 2 - font:getHeight() / 2
    local healthText = string.format(
        "Health: %d / %d",
        player.potions.healthPotionCount,
        player.potions.maxHealthPotionCount
    )
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(healthText, textX, textY)

    -- Mana potion display
    local manaPotionX = healthPotionX + potionIconSize + potionSpacing + font:getWidth(healthText) + potionSpacing
    local manaPotionY = potionSectionY

    -- Draw mana potion icon box
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", manaPotionX, manaPotionY, potionIconSize, potionIconSize, 4, 4)
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", manaPotionX, manaPotionY, potionIconSize, potionIconSize, 4, 4)

    -- Draw mana potion icon
    local manaPotionIcon = Resources.loadUIIcon("mana_potion")
    if manaPotionIcon then
        local iconPadding = 6
        local iconInnerSize = potionIconSize - (iconPadding * 2)
        local iconX = manaPotionX + iconPadding
        local iconY = manaPotionY + iconPadding

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(manaPotionIcon, iconX, iconY, 0,
            iconInnerSize / manaPotionIcon:getWidth(),
            iconInnerSize / manaPotionIcon:getHeight())
    end

    -- Draw mana potion count text
    local manaTextX = manaPotionX + potionIconSize + potionSpacing
    local manaTextY = manaPotionY + potionIconSize / 2 - font:getHeight() / 2
    local manaText = string.format(
        "Mana: %d / %d",
        player.potions.manaPotionCount,
        player.potions.maxManaPotionCount
    )
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(manaText, manaTextX, manaTextY)
end

return renderInventoryPotions

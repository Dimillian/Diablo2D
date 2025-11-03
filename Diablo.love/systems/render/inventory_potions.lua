local Resources = require("modules.resources")
local InventoryLayout = require("systems.helpers.inventory_layout")

local renderInventoryPotions = {}

local function drawPotionEntry(x, y, iconName, label, count, max)
    local iconSize = 32

    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", x, y, iconSize, iconSize, 4, 4)

    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, iconSize, iconSize, 4, 4)

    local icon = Resources.loadUIIcon(iconName)
    if icon then
        local maxDimension = math.max(icon:getWidth(), icon:getHeight())
        local scale = iconSize / maxDimension
        local drawW = icon:getWidth() * scale
        local drawH = icon:getHeight() * scale
        local drawX = x + (iconSize - drawW) / 2
        local drawY = y + (iconSize - drawH) / 2
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(icon, drawX, drawY, 0, scale, scale)
    end

    local font = love.graphics.getFont()
    local textX = x + iconSize + 12
    local labelY = y - 4
    local countY = labelY + font:getHeight()

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(label, textX, labelY)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("%d / %d", count, max), textX, countY)
end

function renderInventoryPotions.draw(scene)
    local player = scene.world:getPlayer()
    if not player or not player.potions then
        return
    end

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

    local gridBottomY = scene.inventoryGridBottomY
    if not gridBottomY then
        gridBottomY = gridLayout.gridStartY +
            gridLayout.gridRows * (gridLayout.gridSlotSize + gridLayout.gridSpacing) -
            gridLayout.gridSpacing
    end

    local maxBottom = panelLayout.panelY + panelLayout.panelHeight - 80
    if gridBottomY > maxBottom then
        gridBottomY = maxBottom
    end

    local panelRight = panelLayout.panelX + panelLayout.panelWidth - 40
    local dividerY = gridBottomY + 16

    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(headersLayout.inventoryHeaderX, dividerY, panelRight, dividerY)

    local sectionY = dividerY + 20
    local sectionWidth = panelRight - headersLayout.inventoryHeaderX
    local columnWidth = sectionWidth / 2
    local iconXHealth = headersLayout.inventoryHeaderX
    local iconXMana = headersLayout.inventoryHeaderX + columnWidth

    drawPotionEntry(
        iconXHealth,
        sectionY,
        "health_potion",
        "Health Potions",
        player.potions.healthPotionCount or 0,
        player.potions.maxHealthPotionCount or 0
    )

    drawPotionEntry(
        iconXMana,
        sectionY,
        "mana_potion",
        "Mana Potions",
        player.potions.manaPotionCount or 0,
        player.potions.maxManaPotionCount or 0
    )
end

return renderInventoryPotions
